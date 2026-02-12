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
import { BasicDataSource } from './BasicDataSource';
import { ContactListStruct } from '../utils/ClassStruct';
import LogUtils from '../utils/HiLog';
import { PreferencesListenerUtil } from '../emergencydatashareextability/PreferencesListenerUtil';

const TAG = 'EmergencyContactsDataSource';

export default class EmergencyContactsDataSource extends BasicDataSource {
  public emergencyContacts: ContactListStruct[] = [];

  public totalCount(): number {
    return this.emergencyContacts.length;
  }

  public getEmergencyContacts(): ContactListStruct[] {
    return this.emergencyContacts;
  }

  public getData(index: number): ContactListStruct {
    return this.emergencyContacts[index];
  }

  public refresh(emergencyContacts: ContactListStruct[], isAppear?: boolean): void {
    let emergencyContactsTmp: ContactListStruct[] = [];
    for (let i = 0; i < emergencyContacts.length; i++) {
      emergencyContacts[i].index = i;
      emergencyContactsTmp.push(ContactListStruct.getDeepCopy(emergencyContacts[i]));
    }
    this.emergencyContacts = emergencyContactsTmp;
    LogUtils.i(TAG, 'refresh emergencyContacts length: ' + this.emergencyContacts.length);
    this.notifyDataReload();
    // 发送联系人变更广播
    if (!isAppear) {
      const preferencesListenerUtil = PreferencesListenerUtil.getInstance();
      preferencesListenerUtil.sendPublicEvent();
    }
  }
}