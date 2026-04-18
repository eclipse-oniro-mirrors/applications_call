/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import common from '@ohos.app.ability.common';
import rdb from '@ohos.data.relationalStore';
import { EmergencyInfoStruct, ContactListStruct } from '../utils/ClassStruct';
import { OldContactInfo } from './ResotreClassStructs';
import LogUtils from '../utils/HiLog';
import commonData from '../data/CommonData';
import { prefUtils } from './PrefUtils';
import * as Constants from './RestoreConstants';
import EmergencyContactsDataSource from '../data/EmergencyContactsDataSource';
import RestoreUtils from './RestoreUtils';
import { Utils } from '../utils/Utils';
import * as storageUtil from '../utils/DataStorageUtil';
import { DataStorageUtil } from '../utils/DataStorageUtil';

const TAG = 'ContactsDbHelper';

class ContactsRdbHelper {
  private rdbStoreHelper: rdb.RdbStore | undefined = undefined;
  private oldContactInfoLists: OldContactInfo[] = [];
  private emergencyContactsDataSource: EmergencyContactsDataSource = new EmergencyContactsDataSource();

  private async getRdbStoreHelper(context: common.Context, dbName: string): Promise<void> {
    try {
      const config: rdb.StoreConfig = {
        name: dbName,
        securityLevel: rdb.SecurityLevel.S1
      };
      this.rdbStoreHelper = await rdb.getRdbStore(context, config);
    } catch (error) {
      LogUtils.e(TAG, `[createDB] failed, error code:${error?.code}`);
      RestoreUtils.getInstance().appendErrorInfo(`getRdbStoreHelper err:${error?.code}-${error?.message};`);
    }
  }

  public async restoreContactsFromDb(context: common.Context): Promise<boolean> {
    if (!context) {
      LogUtils.e(TAG, 'restoreContactsFromDb get invalid context');
      RestoreUtils.getInstance().appendErrorInfo('restoreContactsFromDb get invalid context.');
      return false;
    }
    let oldContactsList: string | undefined = await prefUtils.getOldEmContactsUriList();
    if (!oldContactsList || '' === oldContactsList) {
      LogUtils.e(TAG, 'get old emergencyContact uri lists is empty');
      RestoreUtils.getInstance().appendErrorInfo('restoreContactsFromDb get empty old emergencyContact.');
      return false;
    }
    LogUtils.i(TAG, 'start restore contacts info from databases');

    let dataIds: number[] = [];
    oldContactsList.split(Constants.OLD_EM_URI_SEPARATOR).forEach((contactsUri: string) => {
      let dataIdString: string = contactsUri.replace(Constants.OLD_EM_URI_SCHEME_PREFIX, '');
      if ('' !== dataIdString) {
        let dataId = Number(dataIdString);
        LogUtils.i(TAG, `resolve old dataId:${dataId}`);
        dataIds.push(dataId);
        this.createOldContact(dataId);
      }
    });
    RestoreUtils.getInstance().appendResultInfo(`old contact len:${dataIds.length};`);
    await this.getRdbStoreHelper(context, Constants.OLD_DATABASE_NAME);
    if (this.rdbStoreHelper) {
      let rawIds = await this.queryContactIds(this.rdbStoreHelper, dataIds);
      RestoreUtils.getInstance().appendResultInfo(`queryContactIds len:${rawIds.length};`);
      await this.queryContactNames(this.rdbStoreHelper, rawIds);
    }
    return await this.transToNewEmergencyContacts(dataIds.length);
  }

  private async initEmergencyInfoDB(context: common.Context): Promise<undefined | rdb.RdbStore> {
    LogUtils.i(TAG, 'EmergencyInfo initDB start');
    try {
      const OLD_CONFIG: rdb.StoreConfig = {
        name: 'EmergencyInfo.db',
        securityLevel: rdb.SecurityLevel.S3,
        customDir:'rdbtmp',
        rootDir:context.databaseDir
      };
      this.rdbStoreHelper = await rdb.getRdbStore(context, OLD_CONFIG);
      LogUtils.i(TAG, 'EmergencyInfo initDB success');
      return this.rdbStoreHelper;
    } catch (error) {
      LogUtils.e(TAG, `EmergencyInfoDbHelper initDB failed:${error?.code} ${error?.message}`);
    }
    return undefined;
  }

  public async queryEmergencyInfoSubData(context: common.Context, tbName: string): Promise<void> {
    LogUtils.i(TAG, 'queryEmergencyInfoSubData start');
    let resultSet: rdb.ResultSet | undefined = undefined;
    try {
      let rdbStore = await this.initEmergencyInfoDB(context);
      if (rdbStore === undefined) {
        return;
      }
      let predicatesInfo = new rdb.RdbPredicates(tbName);
      resultSet = await rdbStore.query(predicatesInfo);
      if (resultSet.goToFirstRow()) {
        switch (tbName) {
          case 'comhuaweiemergencyemergencyinfobackupemergency_info_tb':
            await this.convertForEmergencyInfoSubData(resultSet);
            LogUtils.i(TAG, `convertForEmergencyInfoSubData success`);
            break;
          case 'comhuaweiemergencyemergencyinfobackupemergency_contact_tb':
            await this.convertForEmergencyContactSubData(resultSet);
            LogUtils.i(TAG, `convertForEmergencyContactSubData success`);
            break;
          case 'comhuaweiemergencyemergencyinfobackupauto_dial_sos_number_switch_tb':
            await this.convertForAutoDialSosNumberSwitchSubData(resultSet, context);
            LogUtils.i(TAG, `convertForAutoDialSosNumberSwitchSubData success`);
            break;
          case 'comhuaweiemergencyemergencyinfobackupauto_send_sos_sms_switch_tb':
            await this.convertForAutoSendSosSmsSwitchSubData(resultSet, context);
            LogUtils.i(TAG, `convertForAutoSendSosSmsSwitchSubData success`);
            break;
          default:
            break;
        }
      } else {
        LogUtils.i(TAG, 'queryEmergencyInfoSubData no found ...');
      }
      await rdbStore.close();
    } catch (err) {
      LogUtils.e(TAG, `queryEmergencyInfoSubData error:${err?.code} ${err?.message}`);
    } finally {
      resultSet?.close();
    }
  }

  public async queryEmergencyInfoData(keyName: string, emergencyInfo: EmergencyInfoStruct): Promise<boolean> {
    const getDataPromise = new Promise<boolean>((resolve) => {
      storageUtil.getEmergencyInfoData((data) => {
        let keys: string[] = Object.keys(data);
        if (keys.length === 0) {
          emergencyInfo.name = '';
          emergencyInfo.address = '';
          emergencyInfo.bloodType = '';
          emergencyInfo.allergicReaction = '';
          emergencyInfo.drug = '';
          emergencyInfo.isOrganDonor = '';
          emergencyInfo.drugStatusAndNotice = '';
        } else {
          emergencyInfo.name = data['name'] || '';
          emergencyInfo.address = data['address'] || '';
          emergencyInfo.bloodType = data['bloodType'] || '';
          emergencyInfo.allergicReaction = data['allergicReaction'] || '';
          emergencyInfo.drug = data['drug'] || '';
          emergencyInfo.isOrganDonor = data['isOrganDonor'] || '';
          emergencyInfo.drugStatusAndNotice = data['drugStatusAndNotice'] || '';
        }
        let result = false;
        switch (keyName) {
          case 'name':
            result = emergencyInfo.name !== '';
            break;
          case 'address':
            result = emergencyInfo.address !== '';
            break;
          case 'bloodType':
            result =  emergencyInfo.bloodType !== '';
            break;
          case 'allergicReaction':
            result =  emergencyInfo.allergicReaction !== '';
            break;
          case 'drug':
            result =  emergencyInfo.drug !== '';
            break;
          case 'isOrganDonor':
            result =  emergencyInfo.isOrganDonor !== '';
            break;
          case 'drugStatusAndNotice':
            result =  emergencyInfo.drugStatusAndNotice !== '';
            break;
          default:
            break;
        }
        resolve(result);
      });
    });

    const finalResult = await getDataPromise;
    LogUtils.i(TAG, `queryEmergencyInfoData finalResult:${finalResult}`);
    return finalResult;
  }

  public oldEmergencyInfoData2New(oldData: EmergencyInfoStruct, newData: EmergencyInfoStruct): void {
    LogUtils.i(TAG, `oldEmergencyInfoData2New start`);

    newData.name = newData.name !== '' ? newData.name : oldData.name;
    storageUtil.updateEmergencyInfo('name', newData.name || '');
    newData.address = newData.address !== '' ? newData.address : oldData.address;
    storageUtil.updateEmergencyInfo('address', newData.address || '');
    newData.bloodType = newData.bloodType !== '' ? newData.bloodType : oldData.bloodType;
    storageUtil.updateEmergencyInfo('bloodType', newData.bloodType || '');
    newData.allergicReaction = newData.allergicReaction !== '' ? newData.allergicReaction : oldData.allergicReaction;
    storageUtil.updateEmergencyInfo('allergicReaction', newData.allergicReaction || '');
    newData.drug = newData.drug !== '' ? newData.drug : oldData.drug;
    storageUtil.updateEmergencyInfo('drug', newData.drug || '');
    newData.isOrganDonor = newData.isOrganDonor !== '' ? newData.isOrganDonor : oldData.isOrganDonor;
    storageUtil.updateEmergencyInfo('isOrganDonor', newData.isOrganDonor || '');
    newData.drugStatusAndNotice =
      newData.drugStatusAndNotice !== '' ? newData.drugStatusAndNotice : oldData.drugStatusAndNotice;
    storageUtil.updateEmergencyInfo('drugStatusAndNotice', newData.drugStatusAndNotice || '');

    LogUtils.i(TAG, `oldEmergencyInfoData2New end`);
  }

  public oldEmergencyContact2New(oldData: ContactListStruct[], newData: ContactListStruct[]): void {
    LogUtils.i(TAG, `oldEmergencyContact2New start`);
    let tempList: ContactListStruct[] = [];
    let count = this.emergencyContactsDataSource.totalCount();
    LogUtils.i(TAG, `EmergencyContact count:${count}`);
    newData.forEach((data, index) => {
      LogUtils.i(TAG, `nweEmergencyContact index:${index + 1}`);
      data.label = data.value;
      data.nameRawContactId = undefined;
      tempList.push(data);
      count++;
    });

    oldData.forEach((data, index) => {
      LogUtils.i(TAG, `oldEmergencyContact index:${index + 1}`);
      LogUtils.i(TAG, `EmergencyContact count:${count}`);
      if (!this.isEmergencyContactRepeat(tempList, data.value) && count < Constants.EMERGENCY_CONTACT_MAX) {
        data.label = data.value;
        data.nameRawContactId = undefined;
        tempList.push(data);
        count++;
      }
    });

    DataStorageUtil.getInstance().updateEmergencyContacts(tempList, (result: boolean) => {
      if (result) {
        this.emergencyContactsDataSource.refresh(tempList);
        LogUtils.i(TAG, `oldEmergencyContact2New old success result:${result}`);
      }
    });
    LogUtils.i(TAG, `oldEmergencyContact2New end`);
  }

  public isEmergencyContactRepeat(tempList: ContactListStruct[], contactNumber: string): boolean {
    let flag = false;
    tempList.forEach((data, index) => {
      if (data.value === contactNumber) {
        flag = true;
      }
    });
    return flag;
  }

  private async convertForEmergencyInfoSubData(resultSet: rdb.ResultSet): Promise<void> {
    const emergencyKeyMap: Map<string, string> = new Map([
      ['name', 'name'],
      ['address', 'address'],
      ['blood_type', 'bloodType'],
      ['allergies', 'allergicReaction'],
      ['medications', 'drug'],
      ['medical_conditions', 'drugStatusAndNotice']
    ]);

    do {
      let key = resultSet.getString(resultSet.getColumnIndex('key'));
      const field = emergencyKeyMap.get(key);
      if (field) {
        let value = resultSet.getString(resultSet.getColumnIndex('value'));
        let emergencyInfo: EmergencyInfoStruct = { name: '', address: '', bloodType: '', allergicReaction: '',
          drug: '', isOrganDonor: '', drugStatusAndNotice: ''};
        let flag = await this.queryEmergencyInfoData(field, emergencyInfo);
        if (value === '' || flag) {
          LogUtils.i(TAG, `convertForEmergencyInfoSubData ${field} not need clone`);
          continue;
        }
        await storageUtil.updateEmergencyInfoSync(field, value);
        LogUtils.i(TAG, `convertForEmergencyInfoSubData save ${field} success`);
      } else {
        LogUtils.i(TAG, `convertForEmergencyInfoSubData key no need sync`);
      }
    } while (resultSet.goToNextRow());
    storageUtil.saveEmergencyInfo();

    return;
  }

  private async convertForEmergencyContactSubData(resultSet: rdb.ResultSet): Promise<void> {
    LogUtils.i(TAG, `convertForEmergencyContactSubData start`);
    const getContactsDataPromise = new Promise<void>((resolve) => {
      DataStorageUtil.getInstance().getEmergencyContacts((data) => {
        this.emergencyContactsDataSource.refresh(data, true);
        resolve();
      });
    });
    await getContactsDataPromise;

    const tempList: ContactListStruct[] = this.emergencyContactsDataSource.getEmergencyContacts();
    let key = resultSet.getString(resultSet.getColumnIndex('emergency_contact'));
    key = key.replace(/ /g, '');
    let numbers = key.split(',');
    let count = this.emergencyContactsDataSource.totalCount();
    numbers.forEach((number, index) => {
      LogUtils.i(TAG, `convertForEmergencyContactSubData index:${index + 1}`);
      if (!this.isEmergencyContactRepeat(tempList, number) && count < Constants.EMERGENCY_CONTACT_MAX) {
        const data: ContactListStruct = {
          value: number,
          label: number,
          id: new Date().getTime().toString(),
          type: commonData.int.COMMON_CONTACT_TYPE
        }
        tempList.push(data);
        count++;
        LogUtils.i(TAG, `convertForEmergencyContactSubData count:${count}`);
      }
    });
    DataStorageUtil.getInstance().updateEmergencyContacts(tempList, (result: boolean) => {
      if (result) {
        this.emergencyContactsDataSource.refresh(tempList);
        LogUtils.i(TAG, `convertForEmergencyContactSubData success result:${result}`);
      }
    });
  }

  private async convertForAutoSendSosSmsSwitchSubData(resultSet: rdb.ResultSet,
    context: common.Context): Promise<void> {
    const switchIsOn = '1';
    do {
      let key = resultSet.getString(resultSet.getColumnIndex('auto_send_sos_sms_switch'));
      Utils.setAutoSendSosSmsSwitch(context, key === switchIsOn);
      LogUtils.i(TAG, `convertForAutoSendSosSmsSwitchSubData success`);
    } while (resultSet.goToNextRow());
  }

  private async convertForAutoDialSosNumberSwitchSubData(resultSet: rdb.ResultSet,
    context: common.Context): Promise<void> {
    const switchIsOn = '1';
    do {
      let key = resultSet.getString(resultSet.getColumnIndex('auto_dial_sos_number_switch'));
      Utils.setAutoDialSosNumberSwitch(context, key === switchIsOn);
      LogUtils.i(TAG, `convertForAutoDialSosNumberSwitchSubData success`);
    } while (resultSet.goToNextRow());
  }

  private async queryContactIds(rdbStore: rdb.RdbStore, dataIds: number[]): Promise<Array<number>> {
    LogUtils.i(TAG, `[queryContactIds] start query dataIds:${JSON.stringify(dataIds)}`);
    let rawIds: number[] = [];
    try {
      let predicates = new rdb.RdbPredicates(Constants.OLD_DATA_TABLE_NAME);
      predicates.in(Constants.COL_DATA_ID, dataIds);
      let resultSet = await rdbStore.query(predicates, Constants.QUERY_OLD_DATA);
      if (!resultSet) {
        LogUtils.w(TAG, '[queryContactIds] no data found.');
        return Promise.resolve(rawIds);
      }
      if (!resultSet.goToFirstRow()) {
        LogUtils.w(TAG, '[queryContactIds] resultSet is empty');
        resultSet.close();
        return Promise.resolve(rawIds);
      }
      do {
        let contactId = resultSet.getLong(resultSet.getColumnIndex(Constants.COL_RAW_ID));
        let contactNumber = resultSet.getString(resultSet.getColumnIndex(Constants.COL_DATA1));
        let dataId = resultSet.getLong(resultSet.getColumnIndex(Constants.COL_DATA_ID));
        LogUtils.i(TAG, `[queryContactIds] cId:${contactId} number:${contactNumber?.length} dId:${dataId}`);
        rawIds.push(contactId);
        this.updateByDataId(dataId, contactId, contactNumber);
      } while (resultSet.goToNextRow());
      resultSet.close();
    } catch (error) {
      LogUtils.e(TAG, `[queryContactIds] error:${error?.code}`);
      RestoreUtils.getInstance().appendErrorInfo(`queryContactIds err:${error?.code}-${error?.message};`);
    }
    return Promise.resolve(rawIds);
  }

  private updateByDataId(dataId: number, contactId: number, contactNumber: string) {
    this.oldContactInfoLists.forEach((contact: OldContactInfo) => {
      if (contact.id === dataId) {
        contact.rawContactId = contactId;
        contact.phoneNumber = contactNumber;
      }
    });
  }

  private async queryContactNames(rdbStore: rdb.RdbStore, predicatesData: number[]): Promise<void> {
    LogUtils.i(TAG, '[queryContactNames] start query rawIds:' + JSON.stringify(predicatesData));
    try {
      let predicates = new rdb.RdbPredicates(Constants.OLD_DATA_TABLE_NAME);
      predicates.in(Constants.COL_RAW_ID, predicatesData);
      predicates.equalTo(Constants.COL_MIMETYPE, Constants.MIMETYPE_NAME);
      let resultSet = await rdbStore.query(predicates, Constants.QUERY_OLD_DATA);
      if (!resultSet) {
        LogUtils.w(TAG, '[queryContactNames] no data found.');
        return;
      }
      if (!resultSet.goToFirstRow()) {
        LogUtils.w(TAG, '[queryContactNames] resultSet is empty');
        resultSet.close();
        return;
      }
      do {
        let contactId = resultSet.getLong(resultSet.getColumnIndex(Constants.COL_RAW_ID));
        let contactName = resultSet.getString(resultSet.getColumnIndex(Constants.COL_DATA1));
        LogUtils.i(TAG, `[queryContactNames] get cId:${contactId} contactName:${contactName?.length}`);
        this.updateByContactId(contactId, contactName);
      } while (resultSet.goToNextRow());
      resultSet.close();
    } catch (error) {
      LogUtils.e(TAG, `[queryContactNames] error:${error?.code} ` + JSON.stringify(error));
      RestoreUtils.getInstance().appendErrorInfo(`queryContactNames err:${error?.code}-${error?.message};`);
    }
  }

  private updateByContactId(contactId: number, contactName: string) {
    if (!contactName || contactName === '') {
      LogUtils.w(TAG, `updateByContactId name:${contactName} is invalid`);
      return;
    }
    this.oldContactInfoLists.forEach((contact: OldContactInfo) => {
      if (contact.rawContactId === contactId) {
        contact.phoneName = contactName;
      }
    });
  }

  private createOldContact(dataId: number): void {
    let contact: OldContactInfo = new OldContactInfo();
    contact.id = dataId;
    this.oldContactInfoLists.push(contact);
  }

  private async transToNewEmergencyContacts(oldUriLen: number): Promise<boolean> {
    let newEmergencyContactList: ContactListStruct[] = [];
    let newContactIndex = -1;
    this.oldContactInfoLists.forEach((oldInfo: OldContactInfo) => {
      if (oldInfo.phoneNumber !== '') {
        if (oldInfo.phoneName === '') {
          LogUtils.i(TAG, 'get one empty name contact, use number as name');
          oldInfo.phoneName = oldInfo.phoneNumber;
        }
        newContactIndex++;
        let contact: ContactListStruct = {
          value: oldInfo.phoneNumber.replace(new RegExp(' ', 'g'), ''),
          label: oldInfo.phoneName,
          id: new Date().getTime().toString(),
          type: commonData.int.COMMON_CONTACT_TYPE,
          index: newContactIndex
        };
        newEmergencyContactList.push(contact);
      } else {
        LogUtils.i(TAG, 'get one empty number contact');
        RestoreUtils.getInstance().appendResultInfo(`get empty number contact;`);
      }
    });
    let contactsString = JSON.stringify(newEmergencyContactList);
    LogUtils.i(TAG, `final oldUriLen:${oldUriLen} newLen:${newContactIndex + 1}`);
    if (newContactIndex !== -1) {
      await prefUtils.saveToPref(Constants.NEW_EMERGENCY_CONTACTS_KEY, contactsString,
        Constants.NEW_EM_CONTACTS_PREF_NAME);
      let dataSource = new EmergencyContactsDataSource();
      dataSource.refresh([]);
      dataSource.refresh(newEmergencyContactList);
    }
    RestoreUtils.getInstance().appendResultInfo(`final get:${newEmergencyContactList.length} old:${oldUriLen};`);
    return true;
  }
}

export const contactsRdbHelper: ContactsRdbHelper = new ContactsRdbHelper();