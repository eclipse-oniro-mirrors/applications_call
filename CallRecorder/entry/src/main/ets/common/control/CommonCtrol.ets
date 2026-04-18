/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import {
  ContactDataStruct,
  RecordConfigDataStruct,
  RecordConfigContactDataStruct,
  ContactsDataStruct
} from '../struct/RecorderSettingStruct';
import { GlobalContextHelper } from '../../common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { Constant } from '../../common/constant/Constant';
import LogUtils from '../utils/LogUtils';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { RecordLog } from '../../common/struct/RecorderStruct';
import image from '@ohos.multimedia.image';
import HashMap from '@ohos.util.HashMap';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { formatPhoneNum } from '../../common/utils/CommonUtil';
import { relationalStore } from '@kit.ArkData';
import RecordDatabaseHelper from '../utils/DatabaseHelper';
import CallRecorderSingleConstant from '../constant/CallRecorderSingleConstant';
// import enhanced from '@hms.telephony.enhanced';
import { CallSettingConstant } from '../constant/CallSettingConstant';
import contact from '@ohos.contact';
import { MigrationConstant } from '../constant/MigrationConstant';

const TAG = 'RecordingSettingCommonCtrol';

const RECORD_LOG_URI: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_LOG;
const RECORD_CONFIG_URI: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;

export default class CommonController {
  private static sInstance: CommonController;
  public recordLogDataHelper: dataShare.DataShareHelper | undefined;
  public migrationRecordDataHelper: dataShare.DataShareHelper | undefined;

  static getInstance() {
    if (CommonController.sInstance == null) {
      CommonController.sInstance = new CommonController();
    }
    return CommonController.sInstance;
  }

  private dealPickerData(contactsList: contact.Contact[]) {
    LogUtils.i(TAG, 'dealPickerData enter, length: ' + contactsList.length);
    const contactsResultList: ContactDataStruct[] = [];
    const contactsKeyList: string[] = [];
    for (let i = 0; i < contactsList.length; i++) {
      const numberList = contactsList[i].phoneNumbers;
      if (numberList) {
        for (let j = 0; j < numberList.length; j++) {
          const phoneNumber = numberList[j].phoneNumber;
          if (contactsKeyList.indexOf(phoneNumber) === -1) {
            contactsResultList.push({
              telephone: phoneNumber, contactName: contactsList[i].name?.fullName ?? ''
            });
            contactsKeyList.push(phoneNumber);
          }
        }
      }
    }
    return contactsResultList;
  }

  async jumpToContactForResult(callback: (data: ContactDataStruct[]) => void) {
    LogUtils.i(TAG, 'jumpToContactForResult');
    let contactsResultList: ContactDataStruct[] = [];
    try {
      const contactsList = await contact.selectContacts({
        isMultiSelect: true
      });
      if (contactsList) {
        contactsResultList = this.dealPickerData(contactsList);
      }
      callback(contactsResultList);
    } catch (err) {
      callback(contactsResultList);
      LogUtils.e(TAG, `jumpToContactForResult error code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async getPhotoDisplayNameDataHelper(phoneNumberList: string[] = [], dataHelper: dataShare.DataShareHelper) {
    let resultColumns = [
      'display_name',
      'detail_info',
      'type_id',
      'contact_id'
    ];
    let condition = new dataSharePredicates.DataSharePredicates();
    condition.equalTo('type_id', 5);
    condition.and();
    condition.equalTo('is_deleted', '0');
    condition.and();
    condition.in('detail_info', phoneNumberList);
    let resultSet: DataShareResultSet | undefined = undefined;
    let contactsDataResult: ContactsDataStruct[] = [];
    let matchedNumberList: string[] = [];
    try {
      resultSet = await dataHelper.query(Constant.CONTACT_URI, condition, resultColumns);
      while (resultSet?.goToNextRow()) {
        const displayName = resultSet.getString(resultSet.getColumnIndex('display_name'));
        const detailInfo = resultSet.getString(resultSet.getColumnIndex('detail_info'));
        matchedNumberList.push(detailInfo);
        const typeId = resultSet.getLong(resultSet.getColumnIndex('type_id'));
        const contactId = resultSet.getLong(resultSet.getColumnIndex('contact_id'));
        contactsDataResult.push({
          displayName: displayName,
          detailInfo: detailInfo,
          typeId: typeId,
          contactId: contactId
        });
      }
      LogUtils.i(TAG, 'getPhotoDisplayNameData over');
    } catch (err) {
      LogUtils.e(TAG, `getPhotoDisplayNameDataHelper error code: ${err?.code}, msg: ${err?.message}`);
    }
    resultSet?.close();
    await this.queryNoEqualsNumByNumberMatch(phoneNumberList, matchedNumberList, dataHelper, contactsDataResult);
    return contactsDataResult;
  }

  async queryNoEqualsNumByNumberMatch(phoneNumberList: string[], matchedNumberList: string[],
    dataHelper: dataShare.DataShareHelper, contactsDataResult: ContactsDataStruct[]) {
    const totalCount = phoneNumberList.length;
    const matchedCount = matchedNumberList.length;
    LogUtils.e(TAG, `queryNoEqualsNumByNumberMatch total:${totalCount} matched:${matchedCount}`);
    if (totalCount === matchedCount) {
      return;
    }

    let notMatchedNumberList: string[] = [];
    phoneNumberList.forEach((number) => {
      if (matchedNumberList.indexOf(number) < 0) {
        notMatchedNumberList.push(number);
      }
    });

    let len = notMatchedNumberList.length;
    LogUtils.e(TAG, `notMatchedNumberList total:${len}`);
    for (let i = 0; i < len; i++) {
      let number = notMatchedNumberList[i];
      await this.fillNumberMatchResult(number, dataHelper, contactsDataResult);
    }
  }

  async fillNumberMatchResult(number: string, dataHelper: dataShare.DataShareHelper, finalList: ContactsDataStruct[]) {
    LogUtils.e(TAG, 'fillNumberMatchResult');
    let queryResult = await this.queryContactNumberMatchResultSet(dataHelper, number);
    if (queryResult) {
      try {
        let name = queryResult.getString(queryResult.getColumnIndex('display_name'));
        let contactId = queryResult.getLong(queryResult.getColumnIndex('contact_id'));
        finalList.push({
          displayName: name,
          detailInfo: number,
          typeId: 5,
          contactId: contactId
        });
      } catch (err) {
        LogUtils.e(TAG, `fillNumberMatchResult error code:${err?.code}, msg: ${err?.message}`);
      }
      queryResult.close();
    }
  }

  async getQueryParams(dataHelper: dataShare.DataShareHelper, callNumber: string): Promise<DataShareResultSet> {
    let condition = new dataSharePredicates.DataSharePredicates();
    if (callNumber.length >= 7) {
      let queryNum = callNumber.slice(-7);
      condition.endsWith('detail_info', queryNum);
    } else {
      condition.equalTo('detail_info', callNumber);
    }
    condition.and();
    condition.equalTo('type_id', '5');
    condition.and();
    condition.equalTo('is_deleted', '0');
    let resultSet = await dataHelper.query(Constant.CONTACT_URI, condition, Constant.COLUMNS);
    LogUtils.i(TAG, `queryContactByNum result count:${resultSet.rowCount}`);
    return resultSet;
  }

  async queryContactNumberMatchResultSet(dataHelper: dataShare.DataShareHelper,
    number: string): Promise<DataShareResultSet | undefined> {
    LogUtils.i(TAG, `queryContactNumberMatchResultSet len:${number.length}`);
    try {
      let resultSet = await this.getQueryParams(dataHelper, number);
      // let numMatchIndex = await enhanced.getPreciselyMatchedIndex(resultSet, number);
      // if (resultSet.goToRow(numMatchIndex)) {
      //   LogUtils.i(TAG, 'queryContactNumberMatchResultSet matched');
      //   return resultSet;
      // } else {
      //   resultSet.close();
      // }
    } catch (err) {
      LogUtils.e(TAG, `queryContactNumberMatchResultSet error code:${err?.code}, msg: ${err?.message}`);
    }
    return undefined;
  }

  getPhotoDetailInfo(contactsDataResult: ContactsDataStruct[], checkStatus: boolean) {
    let configContactResult: RecordConfigContactDataStruct[] = [];
    for (let i = 0; i < contactsDataResult.length; i++) {
      let name: string = contactsDataResult[i].displayName === contactsDataResult[i].detailInfo ?
        '' : contactsDataResult[i].displayName;
      if (!name) {
        name = contactsDataResult[i].contactId !== -1 ? formatPhoneNum(contactsDataResult[i].detailInfo) : name;
      }
      configContactResult.push(
        {
          phoneNumber: contactsDataResult[i].detailInfo,
          id: contactsDataResult[i].contactId,
          isImageDefault: true,
          name: name,
          image: $r('app.media.ic_user'),
          isChecked: checkStatus,
          // 新增时间戳字段,用于在lazyforeach中作为唯一标识,用于触发dom刷新
          timestamp: new Date().getTime()
        }
      );
    }
    return configContactResult;
  }

  async queryForContactsInfoForPhoto(contactData: RecordConfigContactDataStruct[], callbackSource:
    (data: RecordConfigContactDataStruct[]) => void, checkStatus: boolean) {
    LogUtils.i(TAG, 'queryForContactsInfoForPhoto');
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    try {
      let phoneNumberList: string[] = [];
      for (let i = 0; i < contactData.length; i++) {
        phoneNumberList.push(contactData[i].phoneNumber);
      }
      let contactUri: string = Constant.CONTACT_URI;
      let dataHelper: dataShare.DataShareHelper = await dataShare.createDataShareHelper(context, contactUri);
      await this.queryForContactsInfoForPhotoExt(phoneNumberList, dataHelper, checkStatus, callbackSource, contactData);
    } catch (error) {
      callbackSource(contactData);
      let err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `queryForContactsInfoForPhoto failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async queryForContactsInfoForPhotoExt(phoneNumberList: string[], dataHelper: dataShare.DataShareHelper,
    checkStatus: boolean, callbackSource: (data: RecordConfigContactDataStruct[]) => void,
    contactData: RecordConfigContactDataStruct[]) {
    // For CodeCheck.
    try {
      await this.queryForContactsInfoForPhotoExtra(phoneNumberList, dataHelper, checkStatus, callbackSource);
    } catch (error) {
      callbackSource(contactData);
      let err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `queryForContactsInfoForPhoto query failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async queryForContactsInfoForPhotoExtra(phoneNumberList: string[], dataHelper: dataShare.DataShareHelper,
    checkStatus: boolean, callbackSource: (data: RecordConfigContactDataStruct[]) => void) {
    let contactsDataResult: ContactsDataStruct[] = await this.getPhotoDisplayNameDataHelper(phoneNumberList,
      dataHelper);
    let contactIdList: number[] = [];
    let phoneNumberIndex: number = -1;
    let repeatNumberIndex: number = -1;
    let repeatNumberList: string[] = [];
    let repeatContactId = -1;
    let currentPhoneNumber: string | undefined = '';
    for (let i = contactsDataResult.length - 1; i >= 0; i--) {
      currentPhoneNumber = contactsDataResult[i].detailInfo;
      repeatNumberIndex = repeatNumberList.indexOf(currentPhoneNumber);
      if (repeatNumberIndex > -1) {
        contactsDataResult.splice(i, 1);
      } else {
        repeatNumberList.push(currentPhoneNumber);
        repeatContactId = contactsDataResult[i].contactId;
        if (contactIdList.indexOf(repeatContactId) === -1) {
          contactIdList.push(repeatContactId);
        }
        phoneNumberIndex = phoneNumberList.indexOf(currentPhoneNumber);
        phoneNumberList.splice(phoneNumberIndex, 1);
      }
    }
    for (let j = 0; j < phoneNumberList.length; j++) {
      contactsDataResult.push({
        displayName: phoneNumberList[j],
        detailInfo: phoneNumberList[j],
        typeId: 5,
        contactId: -1
      });
    }
    LogUtils.i(TAG, 'contactsDataResult' + contactsDataResult.length);
    let configContactResult: RecordConfigContactDataStruct[] = this.getPhotoDetailInfo(contactsDataResult, checkStatus);
    LogUtils.i(TAG, 'configContactResult' + configContactResult.length);
    callbackSource(configContactResult);
  }

  async getPixelMap(blobData: Uint8Array) {
    let imageSource: image.ImageSource = image.createImageSource(blobData.buffer);
    if (imageSource !== undefined) {
      let pixelMap = await imageSource.createPixelMap({
        desiredSize: {
          height: 128, width: 128
        }
      });
      imageSource.release().catch((error: BusinessError) => {
        LogUtils.e('UserPhoto  ', 'release ImageSource error' + error.code);
      })
      return pixelMap;
    } else {
      return undefined;
    }
  }

  async queryForConfigContactLength(callback: (data: number) => void) {
    let uri = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let condition = new dataSharePredicates.DataSharePredicates();
    let dataHelper = await dataShare.createDataShareHelper(context, uri);
    const columns = ['id'];
    dataHelper.query(uri, condition, columns, (err, resultSet) => {
      let rowCountResult = 0;
      if (resultSet?.rowCount) {
        rowCountResult = resultSet.rowCount;
      }
      resultSet?.close();
      callback(rowCountResult);
    });
  }

  async queryForConfigContact(checkStatus: boolean, callback: (data: RecordConfigContactDataStruct[]) => void,
    limit?: number, offset?: number) {
    LogUtils.i(TAG, 'queryForConfigContact');
    let uri = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let condition = new dataSharePredicates.DataSharePredicates();
    if (limit) {
      condition.limit(limit, offset);
    }
    const columns: string[] = ['phone_number', 'name', 'id'];
    let temp: RecordConfigContactDataStruct[] = [];
    try {
      let dataHelper = await dataShare.createDataShareHelper(context, uri);
      dataHelper.query(uri, condition, columns, async (err, resultSet) => {
        LogUtils.i(TAG, `queryForConfigContact rowCount: ${resultSet?.rowCount}`);
        try {
          if (resultSet?.rowCount === 0) {
            callback(temp);
            return;
          }
          while (resultSet?.goToNextRow()) {
            const phoneNumber = resultSet.getString(resultSet.getColumnIndex('phone_number'));
            const name = resultSet.getString(resultSet.getColumnIndex('name'));
            temp.push({
              phoneNumber: phoneNumber,
              name: name,
              image: $r('app.media.ic_user'),
              isImageDefault: true,
              isChecked: checkStatus,
              // 新增时间戳字段,用于在lazyforeach中作为唯一标识,用于触发dom刷新
              timestamp: new Date().getTime()
            });
            if (err) {
              LogUtils.e(TAG, `updateIsOpen failed, code: ${err?.code}, msg: ${err?.message}`);
              resultSet?.close();
              return;
            }
          }
          resultSet?.close();
          await this.queryForContactsInfoForPhoto(temp, callback, checkStatus);
        } catch (err) {
          LogUtils.e(TAG, `queryForConfig callback failed, code: ${err?.code}, msg: ${err?.message}`);
          resultSet?.close();
          callback(temp);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `queryForConfig query failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async updateObject(object: string, callback: (data: number) => void) {
    let uri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns: ValuesBucket = {
      object: object
    };
    let dataHelper = await dataShare.createDataShareHelper(context, uri);
    try {
      dataHelper.update(uri, condition, columns, (err, rows) => {
        if (err) {
          LogUtils.e(TAG, `updateObject failed, code: ${err?.code}, msg: ${err?.message}`);
          callback(0);
          return;
        }
        callback(rows);
      });
    } catch (err) {
      callback(0);
      LogUtils.e(TAG, `updateObject update failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async updateIsOpen(isOpen: number, callback: (data: number) => void) {
    let uri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns: ValuesBucket = {
      is_open: isOpen
    };
    let dataHelper = await dataShare.createDataShareHelper(context, uri);
    try {
      dataHelper.update(uri, condition, columns, (err, rows) => {
        if (err) {
          LogUtils.e(TAG, `updateIsOpen failed, code: ${err?.code}, msg: ${err?.message}`);
          return;
        }
        callback(rows);
      });
    } catch (err) {
      callback(0);
      LogUtils.e(TAG, `updateIsOpen update failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async queryForConfig(callback: (data: RecordConfigDataStruct) => void) {
    LogUtils.i(TAG, 'queryForConfig');
    let uri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    LogUtils.i(TAG, 'queryForConfig condition');
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns = ['is_open', 'object'];
    try {
      let dataHelper = await dataShare.createDataShareHelper(context, uri);
      dataHelper.query(uri, condition, columns, (err, resultSet) => {
        let result: RecordConfigDataStruct = {};
        if (resultSet?.goToNextRow()) {
          const isOpen = resultSet.getLong(resultSet.getColumnIndex('is_open'));
          const object = resultSet.getString(resultSet.getColumnIndex('object'));
          if (err) {
            LogUtils.e(TAG, `queryForConfig failed, code: ${err?.code}, msg: ${err?.message}`);
            return;
          }
          result = {
            isOpen: isOpen, object: object
          }
        }
        resultSet?.close();
        callback(result);
      });
    } catch (err) {
      LogUtils.e(TAG, `queryForConfig query failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async createForConfig(isOpen: boolean, callback: (result: number) => void) {
    LogUtils.i(TAG, 'createForConfig');
    let uri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    try {
      let dataHelper = await dataShare.createDataShareHelper(context, uri);
      dataHelper.insert(uri, {
        'is_open': isOpen ? CallSettingConstant.OPEN_RECORDING_STATUS : CallSettingConstant.CLOSE_RECORDING_STATUS,
        'object': CallSettingConstant.RECORDING_WAY_ALL_NUMBER
      }).then((result) => {
        callback(result);
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `createForConfig query failed, code: ${err?.code}, msg: ${err?.message}`);
        callback(0);
      });
    } catch (err) {
      LogUtils.e(TAG, `createForConfig query failed, error code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async queryForRecordLog(context: Context): Promise<HashMap<string, number>> {
    LogUtils.i(TAG, 'queryForRecordLog');
    let resultData: HashMap<string, number> = new HashMap<string, number>();
    const columns = ['id', 'display_name', 'recorder_added'];
    try {
      let rdbStore = await RecordDatabaseHelper.getInstance().getDualWriteRdbStore(context);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertRecordInfoForClone get rdbStore failed`);
        return resultData;
      }
      let predicatesInfo = new relationalStore.RdbPredicates(CallRecorderSingleConstant.RECORD_LOG_TB_NAME);
      let resultSet = await rdbStore.query(predicatesInfo, columns);
      if (resultSet === undefined || !resultSet.goToFirstRow()) {
        LogUtils.w(TAG, 'query no RecordLog found from SingleFrame.');
        resultSet?.close();
        return Promise.resolve(resultData);
      }
      do {
        let key: string = resultSet.getString(resultSet.getColumnIndex('display_name'));
        let value: number = resultSet.getLong(resultSet.getColumnIndex('id'));
        let recorderAdded: number = resultSet.getLong(resultSet.getColumnIndex('recorder_added'));
        resultData.set(key + '_' + recorderAdded, value);
      } while (resultSet.goToNextRow());
      resultSet?.close();
    } catch (err) {
      LogUtils.e(TAG, `queryForRecordLog query failed, code: ${err?.code}, msg: ${err?.message}`);
    }
    return Promise.resolve(resultData);
  }

  async queryNewContactNums(context: Context): Promise<string[]> {
    LogUtils.i(TAG, 'queryNewContactNums');
    let resultData: string[] = [];
    try {
      let rdbStore = await RecordDatabaseHelper.getInstance().getDualWriteRdbStore(context);
      if (!rdbStore) {
        LogUtils.e(TAG, `queryNewContactNums get rdbStore failed`);
        return resultData;
      }
      let predicatesInfo = new relationalStore.RdbPredicates(CallRecorderSingleConstant.RECORD_CONTACT_TB_NAME);
      let resultSet = await rdbStore.query(predicatesInfo, ['phone_number']);
      if (resultSet && resultSet.goToFirstRow()) {
        do {
          let number: string = resultSet.getString(resultSet.getColumnIndex('phone_number'));
          resultData.push(number);
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
    } catch (err) {
      LogUtils.e(TAG, `queryNewContactNums query failed, code: ${err?.code}, msg: ${err?.message}`);
    }
    return resultData;
  }

  async insertConfigContact(params: ValuesBucket, callback: (data: number) => void) {
    LogUtils.i(TAG, 'insertConfigContact');
    let uri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let dataHelper = await dataShare.createDataShareHelper(context, uri);
    try {
      dataHelper.insert(uri, params, (err, rows) => {
        if (err) {
          LogUtils.e(TAG, `insertConfigContact failed, code: ${err?.code}, msg: ${err?.message}`);
          return;
        }
        callback(rows);
      });
    } catch (err) {
      LogUtils.e(TAG, `insertConfigContact insert failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async batchInsertConfigFilter(contactData: ContactDataStruct[], dataList: RecordConfigContactDataStruct[],
    callback: (data: Array<ValuesBucket>) => void) {
    LogUtils.i(TAG, 'batchInsertConfigFilter');
    let temp: ValuesBucket[] = [];
    let staticNumberDataUseTempArray = dataList.map((item) => {
      return item.phoneNumber;
    });
    for (let i = 0; i < contactData.length; i++) {
      if (staticNumberDataUseTempArray.indexOf(contactData[i].telephone) === -1) {
        temp.push({
          phone_number: contactData[i].telephone,
          name: contactData[i].contactName
        });
      }
    }
    callback(temp);
  }

  async batchInsertConfigContact(params: Array<ValuesBucket>, callback: (data: number) => void) {
    LogUtils.i(TAG, 'batchInsertConfigContact');
    let uri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let dataHelper = await dataShare.createDataShareHelper(context, uri);
    try {
      dataHelper.batchInsert(uri, params, (err, rows) => {
        if (err) {
          LogUtils.e(TAG, `insertConfigContact failed, code: ${err?.code}, msg: ${err?.message}`);
          return;
        }
        callback(rows);
      });
    } catch (err) {
      LogUtils.e(TAG, `batchInsertConfigContact insert failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async deleteConfigContact(params: string[], callback: () => void) {
    LogUtils.i(TAG, 'batchInsertConfigContact');
    let uri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let condition = new dataSharePredicates.DataSharePredicates();
    if (params.length) {
      condition.in('phone_number', params);
    }
    let dataHelper = await dataShare.createDataShareHelper(context, uri);
    try {
      dataHelper.delete(uri, condition, (err, resultSet) => {
        callback();
        if (err) {
          LogUtils.e(TAG, `deleteConfigContact failed, code: ${err?.code}, msg: ${err?.message}`);
          return;
        }
      });
    } catch (err) {
      callback();
      LogUtils.e(TAG, `deleteConfigContact failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async insertRecorderLog(context: Context, recLog: RecordLog) {
    LogUtils.i(TAG, 'insertRecorderLog');
    let dataHelper = await this.getRecordLogDataHelper(context);
    let promise = dataHelper.insert(RECORD_LOG_URI, {
      file_path: recLog.filePath,
      recorder_added: recLog.recorderAdded as number,
      duration: recLog.duration,
      display_name: recLog.displayName,
      date_added: recLog.dateAdded,
      title: '',
      phone_number: recLog.phoneNumber
    });
    await promise.then((rowId: number) => {
      LogUtils.i(TAG, `Insert is successful, rowId = ${rowId}`);
      return rowId;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `insertRecorderLog insert failed, code: ${err?.code}, msg: ${err?.message}`);
    });
  }

  async batchInsertRecordInfo(context: Context, recLog: RecordLog, callList: string[], callTimeList: number[],
    isRecordMeeting: boolean = true) {
    LogUtils.i(TAG, 'batchInsertRecordInfo');
    let dataHelper = await this.getRecordLogDataHelper(context);
    let insertList: ValuesBucket[] = [];
    let insertRow: ValuesBucket = {};
    for (let i = (isRecordMeeting ? (callList.length - 1) : 0); i < callList.length; i++) {
      insertRow = {
        file_path: recLog.filePath,
        recorder_added: recLog.recorderAdded as number,
        duration: recLog.duration,
        display_name: recLog.displayName,
        date_added: callTimeList[i],
        title: '',
        phone_number: callList[i]
      };
      LogUtils.i(TAG, `batchInsertRecordInfo date added:${callTimeList[i]}`);
      insertList.push(insertRow);
    }
    let promise = dataHelper.batchInsert(RECORD_LOG_URI, insertList);
    promise.then((count: number) => {
      LogUtils.i(TAG, `batchInsert is successful, count = ${count}`);
      dataHelper.notifyChange(RECORD_LOG_URI).then(() => {
        LogUtils.i(TAG, `batchInsert notifyChange successful`);
      }).catch((err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, `batchInsert notifyChange ${count} fail, code: ${err?.code}, msg: ${err?.message}`);
        }
      });
      return count;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `batchInsertRecordInfo insert failed, code: ${err?.code}, msg: ${err?.message}`);
    });
  }

  async updateRecordLog(context: Context, recLog: RecordLog, displayName: string, targetFilePath: string) {
    LogUtils.i(TAG, 'updateRecordLog');
    let dataHelper = await this.getRecordLogDataHelper(context);
    let predicates = new dataSharePredicates.DataSharePredicates()
      .equalTo(MigrationConstant.COLUMN_DISPLAY_NAME, recLog.displayName);
    let valueBucket: ValuesBucket = {
      file_path: targetFilePath,
      display_name: displayName
    };
    let retPromise = dataHelper.update(RECORD_LOG_URI, predicates, valueBucket);
    retPromise.then((rowId: number) => {
      LogUtils.i(TAG, `Update is successful, rowId = ${rowId}`);
      dataHelper.notifyChange(RECORD_LOG_URI).then(() => {
        LogUtils.i(TAG, `updateRecordLog notifyChange successful`);
      }).catch((err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, `updateRecordLog notifyChange ${rowId} fail, code: ${err?.code}, msg: ${err?.message}`);
        }
      });
      return rowId;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `updateRecordLog failed, code: ${err?.code}, msg: ${err?.message}`);
    });
  }

  async batchInsertRecordInfoForClone(context: Context, recLogValue: ValuesBucket[]) {
    let recordSize = recLogValue?.length ?? 0;
    if (recordSize === 0) {
      LogUtils.w(TAG, 'batchInsertRecordInfoForClone insert empty');
      return;
    }
    LogUtils.i(TAG, 'batchInsertRecordInfoForClone size:' + recordSize);
    try {
      let rdbStore = await RecordDatabaseHelper.getInstance().getDualWriteRdbStore(context);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertRecordInfoForClone get rdbStore failed`);
        return 0;
      }
      let rowId = await rdbStore.batchInsert(CallRecorderSingleConstant.RECORD_LOG_TB_NAME, recLogValue);
      LogUtils.i(TAG, `batchInsert for clone is successful, rowId = ${rowId}`);
      return rowId;
    } catch (err) {
      LogUtils.e(TAG, `batchInsertRecordInfoForClone insert failed, code: ${err?.code}, msg: ${err?.message}`);
      return 0;
    }
  }

  async batchInsertConfigContactForClone(context: Context, params: ValuesBucket[], callback: (data: number) => void) {
    let contactSize = params?.length ?? 0;
    if (contactSize === 0) {
      LogUtils.w(TAG, 'batchInsertConfigContactForClone insert empty');
      return;
    }
    LogUtils.i(TAG, 'batchInsertConfigContactForClone size:' + contactSize);
    let uri: string = CallRecorderSingleConstant.RECORD_CONTACT_TB_NAME;
    try {
      let dataHelper = await RecordDatabaseHelper.getInstance().getDualWriteRdbStore(context);
      if (!dataHelper) {
        LogUtils.e(TAG, `batchInsertConfigContactForClone get rdbStore failed`);
        return;
      }
      let insertRows = await dataHelper.batchInsert(uri, params);
      LogUtils.e(TAG, `insertConfigContactForClone insertRows:${insertRows}`);
      callback(insertRows);
    } catch (err) {
      LogUtils.e(TAG, `batchInsertConfigContactForClone insert failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async updateIsOpenForClone(context: Context, recordConfigResult: ValuesBucket, callback: (data: number) => void) {
    let configSize = 0;
    Object.keys(recordConfigResult).forEach((key) => {
      configSize++;
    });
    if (configSize === 0) {
      LogUtils.w(TAG, 'updateIsOpenForClone update config empty');
      return;
    }
    LogUtils.i(TAG, `updateIsOpenForClone recordConfigResult:` + JSON.stringify(recordConfigResult));
    try {
      let dataHelper = await RecordDatabaseHelper.getInstance().getDualWriteRdbStore(context);
      if (!dataHelper) {
        LogUtils.e(TAG, `batchInsertConfigContactForClone get rdbStore failed`);
        return;
      }
      let predicates = new relationalStore.RdbPredicates(CallRecorderSingleConstant.RECORD_CONFIG_TB_NAME);
      let updateRows = await dataHelper.update(recordConfigResult, predicates);
      LogUtils.i(TAG, `updateIsOpen updateRows:${updateRows}`);
      callback(updateRows);
    } catch (err) {
      LogUtils.e(TAG, `updateIsOpen update failed, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async notifyRecordLogChange(context: Context) {
    LogUtils.i(TAG, 'notifyRecordLogChange');
    try {
      let dataShareHelper = await this.getRecordLogDataHelper(context)
      await dataShareHelper.notifyChange(RECORD_LOG_URI);
    } catch (err) {
      LogUtils.e(TAG, `notifyRecordLogChange code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  // get Record Log Data
  async getRecordLogDataHelper(context: Context): Promise<dataShare.DataShareHelper> {
    LogUtils.i(TAG, 'getRecordLogDataHelper');
    if (this.recordLogDataHelper === undefined) {
      this.recordLogDataHelper = await dataShare.createDataShareHelper(context, RECORD_LOG_URI);
    }
    return this.recordLogDataHelper;
  }

  async updateErrorTime(context: Context) {
    let dataHelper: dataShare.DataShareHelper = await dataShare.createDataShareHelper(context, RECORD_CONFIG_URI);
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns: ValuesBucket = {
      error_time: new Date().getTime()
    };
    dataHelper.update(RECORD_CONFIG_URI, condition, columns, (err, rowId) => {
      if (err) {
        LogUtils.e(TAG, `updateErrorTime failed, code: ${err?.code}, msg: ${err?.message}`);
        return;
      }
      LogUtils.i(TAG, `updateErrorTime success,rows:` + rowId);
      dataHelper.notifyChange(RECORD_CONFIG_URI);
    });
  }

  async getPhoto(contactId: number): Promise<image.PixelMap | undefined> {
    LogUtils.i(TAG, 'getPhoto');
    let context =
      GlobalContextHelper.getContext().getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    try {
      let contactUri: string = Constant.CONTACT_URI;
      let dataHelper: dataShare.DataShareHelper = await dataShare.createDataShareHelper(context, contactUri);
      let resultImageColumns = [
        'blob_data'
      ]
      let condition = new dataSharePredicates.DataSharePredicates();
      condition.equalTo('type_id', 8)
        .and()
        .equalTo('is_deleted', '0')
        .and()
        .equalTo('contact_id', contactId);
      let resultImageSet = await dataHelper.query(Constant.CONTACT_URI, condition, resultImageColumns);
      if (resultImageSet?.goToFirstRow()) {
        const blobDataImage = resultImageSet.getBlob(resultImageSet.getColumnIndex('blob_data'));
        LogUtils.i(TAG, `getPhoto blobDataImage length: ${blobDataImage?.length}`);
        return await this.getPixelMap(blobDataImage);
      }
      return;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `getPhoto failed, code: ${err?.code}, msg: ${err?.message}.`);
      return;
    }
  }
}

