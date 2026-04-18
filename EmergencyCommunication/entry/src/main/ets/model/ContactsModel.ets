/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { dataShare, dataSharePredicates, DataShareResultSet } from '@kit.ArkData';
import LogUtils from '../utils/HiLog';
import mmsTable from '../data/TableData';
import { BusinessError } from '@kit.BasicServicesKit';
import { DatabaseUri } from '../data/CommonData';
import CommonData from '../data/CommonData';

const TAG = 'ContactsModel';

export interface ContactDataType {
  contactId?: number
  name?: string
  phones: string[]
}

// query view_contact_data view
export async function queryInViewContactDataByContactIds(context: Context, contactIds: number[]) {
  LogUtils.i(TAG, 'queryInViewContactDataByContactIds');
  const dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initContactDB(context);
  if (!dataHelper) {
    return;
  }
  const dataBaseUri = DatabaseUri.URI_ROW_CONTACTS + DatabaseUri.CONTACT_DATA_URI;
  let condition: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
  condition.in(mmsTable.viewContactData.contactId, contactIds);
  condition.and().equalTo(mmsTable.viewContactData.isDeleted, 0); // Not Deleted contact
  condition.and().in(mmsTable.viewContactData.typeId,
    [CommonData.int.CONTACTS_PHONENUMBER, CommonData.int.CONTACTS_NAME]);
  const columns = [mmsTable.viewContactData.contactId, mmsTable.viewContactData.detailInfo,
    mmsTable.viewContactData.typeId];
  let resultSet: void | DataShareResultSet | null;
  try {
    resultSet = await dataHelper.query(dataBaseUri, condition, columns).catch((error: BusinessError) => {
      LogUtils.e(TAG, '[queryInViewContactDataByContactIds] query fail, BusinessError' + JSON.stringify(error));
    });
  } catch (e) {
    LogUtils.e(TAG, '[queryInViewContactDataByContactIds] query fail, catch' + JSON.stringify(e));
    resultSet = null;
  }
  if (!resultSet) {
    LogUtils.e(TAG, '[queryInViewContactDataByContactIds] query resultSet is empty');
    return;
  }
  let resultMap: Map<number, ContactDataType> | undefined = new Map<number, ContactDataType>();
  if (resultSet.rowCount > 0) {
    try {
      while (resultSet.goToNextRow()) {
        let contactId:ESObject = resultSet.getDouble(resultSet.getColumnIndex(mmsTable.viewContactData.contactId));
        let detailInfo:ESObject = resultSet.getString(resultSet.getColumnIndex(mmsTable.viewContactData.detailInfo));
        let typeId:ESObject = resultSet.getDouble(resultSet.getColumnIndex(mmsTable.viewContactData.typeId));
        if (!detailInfo) {
          continue;
        }
        if (resultMap.get(contactId)) {
          let replaces = resultMap.get(contactId) as ContactDataType;
          if (typeId === CommonData.int.CONTACTS_PHONENUMBER) {
            replaces.phones.push(detailInfo);
          }
          if (typeId === CommonData.int.CONTACTS_NAME) {
            replaces.name = detailInfo;
          }
          resultMap.set(contactId, replaces);
        } else {
          resultMap.set(contactId, {
            name: typeId === CommonData.int.CONTACTS_NAME ? detailInfo : '',
            phones: typeId === CommonData.int.CONTACTS_PHONENUMBER ? [detailInfo] : [],
          });
        }
      }
    } catch (e) {
      LogUtils.e(TAG, `[queryInViewContactDataByContactIds] data processing error: ${JSON.stringify(e)}`);
      resultMap = undefined;
    }
  }
  resultSet.close();
  return resultMap;
}

// query view_contact_data view
export async function queryInViewContactDataByPhones(context: Context, phones: string[]) {
  LogUtils.i(TAG, 'queryInViewContactDataByPhones');
  const dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initContactDB(context);
  if (!dataHelper) {
    return;
  }
  const dataBaseUri = DatabaseUri.URI_ROW_CONTACTS + DatabaseUri.CONTACT_DATA_URI;
  let condition: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
  condition.in(mmsTable.viewContactData.detailInfo, phones);
  condition.and().equalTo(mmsTable.viewContactData.isDeleted, 0); // Not Deleted contact
  condition.and().equalTo(mmsTable.viewContactData.typeId, CommonData.int.CONTACTS_PHONENUMBER);
  const columns = [mmsTable.viewContactData.contactId, mmsTable.viewContactData.detailInfo];
  let resultSet: void | DataShareResultSet | null;
  try {
    resultSet = await dataHelper.query(dataBaseUri, condition, columns).catch((error: BusinessError) => {
      LogUtils.e(TAG, '[queryInViewContactDataByPhones] query fail, BusinessError' + JSON.stringify(error));
    });
  } catch (e) {
    LogUtils.e(TAG, '[queryInViewContactDataByPhones] query fail, catch' + JSON.stringify(e));
    resultSet = null;
  }
  if (!resultSet) {
    LogUtils.e(TAG, '[queryInViewContactDataByPhones] query resultSet is empty');
    return;
  }
  let mapPhoneToContactId: Map<string, number> | undefined = new Map<string, number>();
  if (resultSet.rowCount > 0) {
    try {
      while (resultSet.goToNextRow()) {
        const contactId:ESObject = resultSet.getDouble(resultSet.getColumnIndex(mmsTable.viewContactData.contactId));
        const phone:ESObject = resultSet.getString(resultSet.getColumnIndex(mmsTable.viewContactData.detailInfo));
        if (!phone) {
          continue;
        }

        if (mapPhoneToContactId.get(phone) === undefined) {
          mapPhoneToContactId.set(phone, contactId);
        }
      }
    } catch (e) {
      LogUtils.e(TAG, `[queryInViewContactDataByPhones] data processing error: ${JSON.stringify(e)}`);
      mapPhoneToContactId = undefined;
    }
  }
  resultSet.close();
  return mapPhoneToContactId;
}

export class DataShareHelper {
  private static TAG = 'DataShareHelper';
  private static instance: DataShareHelper;
  private contactDbHelper?: dataShare.DataShareHelper;
  private callSettingDbHelper?: dataShare.DataShareHelper;

  public static getInstance(): DataShareHelper {
    if (DataShareHelper.instance == null) {
      DataShareHelper.instance = new DataShareHelper();
    }
    return DataShareHelper.instance;
  }

  public async initContactDB(context: Context): Promise<dataShare.DataShareHelper | undefined> {
    if (!context) {
      LogUtils.e(DataShareHelper.TAG, 'initContactDB context is empty');
      return undefined;
    }
    if (this.contactDbHelper) {
      LogUtils.i(DataShareHelper.TAG, 'initContactDB already init, return.');
      return Promise.resolve(this.contactDbHelper);
    }
    try {
      this.contactDbHelper =
        await dataShare.createDataShareHelper(context, DatabaseUri.URI_ROW_CONTACTS);
    } catch (error) {
      LogUtils.e(DataShareHelper.TAG, 'initContactDB failed , error msg:' + JSON.stringify(error));
    }
    if (this.contactDbHelper) {
      LogUtils.i(DataShareHelper.TAG, 'initContactDB first init,success.');
      return Promise.resolve(this.contactDbHelper);
    }
    return undefined;
  }

  public async initTianTongSatelliteDBHelper(context: Context): Promise<dataShare.DataShareHelper | undefined> {
    if (!context) {
      LogUtils.e(DataShareHelper.TAG, 'initTianTongSatelliteDBHelper context is empty');
      return undefined;
    }
    if (this.callSettingDbHelper) {
      LogUtils.i(DataShareHelper.TAG, 'initTianTongSatelliteDBHelper already init, return.');
      return Promise.resolve(this.callSettingDbHelper);
    }
    try {
      this.callSettingDbHelper = await dataShare.createDataShareHelper(context, DatabaseUri.SETTING_SATELLITE_URI);
    } catch (e) {
      LogUtils.e(DataShareHelper.TAG, `initTianTongSatelliteDBHelper failed , error msg: ${e?.code} ${e?.message}`);
    }
    if (this.callSettingDbHelper) {
      LogUtils.i(DataShareHelper.TAG, 'initTianTongSatelliteDBHelper first init, success.');
      return Promise.resolve(this.callSettingDbHelper);
    }
    return undefined;
  }

  public getCallSettingDbHelper = () => {
    return this.callSettingDbHelper;
  }
}