/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { ContactListStruct } from '../utils/ClassStruct';
import { DataStorageUtil } from '../utils/DataStorageUtil';
import LogUtils from '../utils/HiLog';
import { PermissionsUtils } from '../utils/PermissionsUtils';
import { HashMap } from '@kit.ArkTS';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { Permissions } from '@kit.AbilityKit';
import EmergencyWarningController from '../control/EmergencyWarningControl';
import {
  ContactDataType,
  queryInViewContactDataByContactIds,
  queryInViewContactDataByPhones
} from '../model/ContactsModel';

const TAG = 'ContactsService';

export class ContactsService {
  private static instance: ContactsService;

  private constructor() {
  }

  public static getInstance(): ContactsService {
    if (ContactsService.instance == null) {
      ContactsService.instance = new ContactsService();
    }
    return ContactsService.instance;
  }

  public async checkReadContactsPermission(): Promise<boolean> {
    const mapPermissionsToGrantStatus: HashMap<Permissions, abilityAccessCtrl.GrantStatus> =
      await PermissionsUtils.checkPermissionsReadContacts();
    if (!mapPermissionsToGrantStatus.isEmpty()) {
      let listOfNeedPermission: Permissions[] = [];
      for (const entry of mapPermissionsToGrantStatus.entries()) {
        if (entry[0] && entry[1] === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
          listOfNeedPermission.push(entry[0]);
        }
      }
      if (listOfNeedPermission.length === 0) {
        return true;
      } else {
        const authResults = await EmergencyWarningController.requestDeniedLocationPermissions(listOfNeedPermission,
          getContext());
        if (!authResults || authResults.length === 0) {
          return false;
        }
        if (authResults.every((v) => (v === 0))) {
          return true;
        } else {
          return false;
        }
      }
    } else {
      return false;
    }
  }

  public async syncAndGetEmergencyContact(context: Context) {
    try {
      const contacts = await this.syncAndGetEmergencyContactFromContactDatabase(context);
      return contacts;
    } catch (e) {
      LogUtils.e(TAG, 'syncAndGetEmergencyContact error: ' + JSON.stringify(e));
      return [];
    }
  }

  private syncContactsWithoutId = async (context: Context, contactsWithoutId: ContactListStruct[],
    phonesOfContactsWithoutId: string[]) => {
    const mapPhoneToContactId: Map<string, number> | undefined =
      await queryInViewContactDataByPhones(context, phonesOfContactsWithoutId);
    if (!mapPhoneToContactId) { //undefined is abnormal value, sync failed
      return Promise.reject('queryInViewContactDataByPhones failed');
    }

    let tempContactList: ContactListStruct[] = [];
    for (let contact of contactsWithoutId) {
      const id = mapPhoneToContactId.get(contact.value);
      if (typeof id === 'number' && !isNaN(id)) {
        contact.nameRawContactId = id;
        tempContactList.push(contact);
      }
    }
    return tempContactList;
  }
  private syncContactsWithId = async (context: Context, contactsWithId: ContactListStruct[],
    contactIds: number[]) => {
    const mapIdToContactData: Map<number, ContactDataType> | undefined =
      await queryInViewContactDataByContactIds(context, contactIds);

    if (!mapIdToContactData) { //undefined is abnormal value, sync failed
      return Promise.reject('queryInViewContactDataByContactIds failed');
    }

    let notDeletedContactsWithId: ContactListStruct[] = [];
    if (mapIdToContactData.size > 0) {
      for (let i = 0; i < contactsWithId.length; i++) {
        let contact = contactsWithId[i];
        const id = contact.nameRawContactId as number;
        const contactData = mapIdToContactData.get(id);
        if (!contactData) {
          continue;
        }
        contact.label = contactData.name || $r('app.string.emptyStr');

        if (contactData.phones.length > 0) {
          if (!contactData.phones.includes(contact.value)) {
            contact.value = contactData.phones[0];
          }
          notDeletedContactsWithId.push(contact);
        }
      }
    }
    return notDeletedContactsWithId;
  }

  private async syncAndGetEmergencyContactFromContactDatabase(context: Context) {
    LogUtils.i(TAG, 'syncAndGetEmergencyContactFromContactDatabase');
    // read old contacts from Preferences
    const dataStorageUtil = DataStorageUtil.getInstance();
    if (dataStorageUtil.contactsPreferences) {
      dataStorageUtil.removePreferencesFromCacheSync(context);
    }
    const oldContacts = dataStorageUtil.getEmergencyContactsSync(context) || [];
    if (oldContacts.length === 0) {
      return oldContacts;
    }

    const isHasReadContactsPermission = await this.checkReadContactsPermission();
    LogUtils.i(TAG, `isHasReadContactsPermission: ${isHasReadContactsPermission}`);
    if (!isHasReadContactsPermission) {
      return oldContacts;
    }

    let contactsWithId: ContactListStruct[] = [];
    let contactsWithoutId: ContactListStruct[] = [];
    let phonesOfContactsWithoutId: string[] = [];
    for (let contact of oldContacts) {
      if (!contact) {
        continue;
      }

      if (typeof contact.nameRawContactId === 'number' && !isNaN(contact.nameRawContactId)) {
        contactsWithId.push(contact);
      } else { // double system up to single system  data
        contactsWithoutId.push(contact);
        phonesOfContactsWithoutId.push(contact.value);
      }
    }

    LogUtils.i(TAG, `oldContacts num: ${oldContacts.length}, contactsWithId num: ${contactsWithId.length}, ` +
      `contactsWithoutId num: ${contactsWithoutId.length}`);

    let newContacts: ContactListStruct[] = [];
    if (contactsWithoutId.length > 0) {
      const result = await this.syncContactsWithoutId(context, contactsWithoutId,
        phonesOfContactsWithoutId).catch((e: string) => {
        LogUtils.e(TAG, 'syncContactsWithoutId error:' + e);
      });
      if (result) {
        contactsWithId.push(...result);
      } else {
        return oldContacts;
      }
    }

    if (contactsWithId.length > 0) {
      const result = await this.syncContactsWithId(context, contactsWithId,
        contactsWithId.map(v => (v.nameRawContactId as number)))
        .catch((e: string) => {
          LogUtils.e(TAG, 'syncContactsWithId error:' + e);
        })
      if (result) {
        newContacts.push(...result);
      } else {
        return oldContacts;
      }
    }

    LogUtils.i(TAG, 'Length of newContacts before deduplication: ' + newContacts.length);
    for (let i = 0; i < newContacts.length; i++) {
      for (let j = i + 1; j < newContacts.length; j++) {
        if (newContacts[i].nameRawContactId === newContacts[j].nameRawContactId &&
          newContacts[i].value === newContacts[j].value) {
          newContacts.splice(j, 1);
        }
      }
    }
    LogUtils.i(TAG, 'Length of newContacts after deduplication: ' + newContacts.length);

    DataStorageUtil.getInstance().updateEmergencyContacts(newContacts, undefined, context);
    return newContacts;
  }

  public syncAndGetEmergencyContactsFromDatabase = async (context: Context) => {
    LogUtils.i(TAG, 'syncAndGetEmergencyContactsFromDatabase');
    const dataStorageUtil = DataStorageUtil.getInstance();
    if (dataStorageUtil.contactsPreferences) {
      dataStorageUtil.removePreferencesFromCacheSync(context);
    }
    const contacts = await ContactsService.getInstance().syncAndGetEmergencyContact(context);
    DataStorageUtil.getInstance().updateEmergencyContacts(contacts, undefined, context);
    return contacts;
  }
}