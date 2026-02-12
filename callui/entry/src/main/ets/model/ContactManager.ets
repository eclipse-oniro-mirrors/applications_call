/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @file: Contact management
 */
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import LogUtils from '../common/utils/LogUtils';
import CallDataManager from './CallDataManager';
import DefaultCallData, { CallDataPatch, callDataPatcher } from '../common/struct/TypeUtils';
// import enhanced from '@hms.telephony.enhanced';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import Utils from '../common/utils/utils';
import { ContactsData } from '../common/utils/ContactsData';
import { taskpool } from '@kit.ArkTS';
import { TaskUtil } from '../common/utils/TaskUtil';
import { common, Context } from '@kit.AbilityKit';
import ContactDataUtils from './ContactDataUtils';

const TAG = 'ContactManager';

/**
 * get contact info
 *
 * @param { Object } callData -Object
 */
export async function getContactInfo(callData: DefaultCallData) {
  if (callData.contactName) {
    return callData;
  }
  return new Promise<DefaultCallData>((resolve) => {
    createQueryContactTask(callData, (data) => {
      if (!(data.contactName) && AppStorage.get<boolean>('isDistributeSink')) {
        data.contactName = callData.distributedContactName;
      }
      CallDataManager.getInstance().updateCallerInfo(data);
      resolve(callData);
    });
  })
}

export function createQueryContactTask(callData: DefaultCallData, callback: (callData: CallDataPatch) => void,
  leatherContext?: Context) {
  let context = leatherContext !== undefined ? leatherContext : Utils.getInstance().getContext();
  let canInUse = canIUse('SystemCapability.Telephony.TelephonyEnhanced');
  let task = new taskpool.Task(queryContactNameByNumber, callData, context, canInUse);
  TaskUtil.getInstance().executeTask(task, (data: object) => {
    let target = data as DefaultCallData
    const patch: CallDataPatch = callDataPatcher.createPatch({
      callId: callData.callId,
    });
    patch.contactName = target.contactName;
    patch.contactId = target.contactId;
    callDataPatcher.apply(callData, patch, 'createQueryContactTask callback');
    callback(patch);
    new ContactsData().reportIncomingOrOutgoingCallInfo(callData);
    if ((callData.contactId ?? -1) <= 0) {
      return;
    }
    queryEnhancedInformation(context, callData);
  })
}

export function queryEnhancedInformation(context: Context, callData: DefaultCallData) {
  let task = new taskpool.Task(queryContactEnhancedInfo, context, callData);
  task.onReceiveData(taskCache);
  TaskUtil.getInstance().executeTask(task, () => {});
}

function taskCache(enhancedInfo: DefaultCallData) {
  LogUtils.i('ContactManager', 'taskCache');
  const patch: CallDataPatch = callDataPatcher.createPatch({
    callId: enhancedInfo.callId,
  });
  patch.contactAvatar = enhancedInfo.contactAvatar;
  patch.contactSmallAvatar = enhancedInfo.contactSmallAvatar;
  patch.contactCompany = enhancedInfo.contactCompany;
  patch.contactCompanyPosition = enhancedInfo.contactCompanyPosition;
  patch.contactNote = enhancedInfo.contactNote;
  patch.contactAvatarColor = enhancedInfo.contactAvatarColor;
  CallDataManager.getInstance().updateCallerInfo(patch);
}

@Concurrent
async function queryContactNameByNumber(callData: DefaultCallData, context: Context,
  canInUse: boolean): Promise<DefaultCallData> {
  const accountNumber = callData.accountNumber;
  LogUtils.i('ContactManager', `queryContactNameByNumber start query number: ${LogUtils.toSafeString(accountNumber)}`);
  const predicates = new dataSharePredicates.DataSharePredicates();
  predicates.equalTo(ContactsData.TYPE_ID, '5'); // type 5 means query number
  predicates.equalTo(ContactsData.IS_DELETED, 0);
  predicates.notEqualTo(ContactsData.MARK_MY_CARD, 1);
  predicates.orderByAsc(ContactsData.RAW_CONTACT_ID);
  let dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  let resultSet: DataShareResultSet | undefined = undefined
  try {
    dataShareHelper = await dataShare.createDataShareHelper(context, ContactsData.DB_BASE_URI);
    if (canInUse && accountNumber.length >= 7) {
      // when number length large than 7, use enhanced number match function
      LogUtils.i('ContactManager', 'getContactInfo use enhanced query');
      const value = accountNumber.slice(-7);
      predicates.beginWrap();
      predicates.endsWith(ContactsData.DETAIL_INFO, value).or().endsWith(ContactsData.FORMAT_PHONE_NUMBER, value);
      predicates.endWrap();
      resultSet = await dataShareHelper.query(ContactsData.DB_URI, predicates, ContactsData.COLUMNS);
      if (resultSet.rowCount > 0) {
        // const resultId : ESObject = await enhanced.getPreciselyMatchedIndex(resultSet, accountNumber);
        const resultId: number = 1
        LogUtils.i('ContactManager', 'getContactInfo use enhanced query matched index: ' + resultId);
        if (resultSet.goToRow(resultId)) {
          LogUtils.i('ContactManager', 'getContactInfo use enhanced query exits');
          callData.contactName = resultSet.getString(resultSet.getColumnIndex(ContactsData.CONTACT_NAME));
          LogUtils.i('ContactManager', `callId: ${callData.callId} contactName length: ${callData.contactName.length}`);
          callData.contactId = resultSet.getLong(resultSet.getColumnIndex(ContactsData.CONTACT_ID));
        }
      }
    } else {
      predicates.equalTo(ContactsData.DETAIL_INFO, accountNumber);
      resultSet = await dataShareHelper.query(ContactsData.DB_URI, predicates, ContactsData.COLUMNS);
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        LogUtils.i('ContactManager', 'getContactInfo use query exits');
        callData.contactName = resultSet.getString(resultSet.getColumnIndex(ContactsData.CONTACT_NAME));
        LogUtils.i('ContactManager', `callId: ${callData.callId} contactName length: ${callData.contactName.length}`);
        callData.contactId = resultSet.getLong(resultSet.getColumnIndex(ContactsData.CONTACT_ID));
      }
    }
  } catch (err) {
    LogUtils.e('ContactManager', `getContactInfo fail, promise: ${err}`);
  } finally {
    if (resultSet != undefined) {
      (resultSet as DataShareResultSet).close();
    }
    if (dataShareHelper != undefined) {
      (dataShareHelper as dataShare.DataShareHelper).close();
    }
  }
  LogUtils.i('ContactManager', 'queryContactNameByNumber end');
  return callData;
}

@Concurrent
async function queryContactEnhancedInfo(context: Context, callData: DefaultCallData): Promise<DefaultCallData> {
  const predicates = new dataSharePredicates.DataSharePredicates();
  predicates.in(ContactsData.TYPE_ID, ContactsData.CONTACT_TYPE);
  predicates.equalTo(ContactsData.CONTACT_ID, callData.contactId);
  LogUtils.i('ContactManager', 'updateContactEnhancedInfo start contact_id: ' + callData.contactId);
  let dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  let resultSet: DataShareResultSet | undefined = undefined
  try {
    dataShareHelper = await dataShare.createDataShareHelper(context, ContactsData.DB_BASE_URI);
    resultSet = await dataShareHelper.query(ContactsData.DB_URI, predicates, ContactsData.COLUMN_ENHANCED);
    LogUtils.i('ContactManager', 'updateContactEnhancedInfo result: ' + resultSet.rowCount);
    if (resultSet.rowCount > 0 && resultSet.goToFirstRow()) {
      do {
        await ContactDataUtils.dataParse(resultSet, callData, context);
      } while (resultSet.goToNextRow())
      LogUtils.i('ContactManager', 'updateContactEnhancedInfo successfully');
      taskpool.Task.sendData(callData);
      callData.contactAvatar?.release();
      callData.contactSmallAvatar?.release();
    }
  } catch (err) {
    LogUtils.e('ContactManager', `updateContactEnhancedInfo fail, promise: ${err}`);
  } finally {
    if (resultSet != undefined) {
      (resultSet as DataShareResultSet).close();
    }
    if (dataShareHelper != undefined) {
      (dataShareHelper as dataShare.DataShareHelper).close();
    }
  }
  LogUtils.i('ContactManager', 'updateContactEnhancedInfo end');
  return callData;
}