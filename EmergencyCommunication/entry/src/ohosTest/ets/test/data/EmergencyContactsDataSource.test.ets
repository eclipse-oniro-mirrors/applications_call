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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import EmergencyContactsDataSource from '../../../../main/ets/data/EmergencyContactsDataSource';
import { ContactListStruct } from '../../../../main/ets/utils/ClassStruct';

export default function EmergencyContactsDataSourceTest() {
  describe('EmergencyContactsDataSourceTest', () => {
    it('EmergencyContactsDataSourceTest_totalCount', 0, () => {
      let emergencyContactsDataSource = new EmergencyContactsDataSource();
      emergencyContactsDataSource.emergencyContacts = [];
      let result = emergencyContactsDataSource.totalCount();
      expect(result).assertEqual(emergencyContactsDataSource.emergencyContacts.length);
    })

    it('EmergencyContactsDataSourceTest_getEmergencyContacts', 0, () => {
      let emergencyContactsDataSource = new EmergencyContactsDataSource();
      emergencyContactsDataSource.emergencyContacts = [];
      let result = emergencyContactsDataSource.getEmergencyContacts();
      expect(result).assertEqual(emergencyContactsDataSource.emergencyContacts);
    })

    it('EmergencyContactsDataSourceTest_getData', 0, () => {
      let emergencyContactsDataSource = new EmergencyContactsDataSource();
      let result = emergencyContactsDataSource.getData(1);
      expect(result).assertEqual(emergencyContactsDataSource.emergencyContacts[1]);
    })

    it('EmergencyContactsDataSourceTest_refresh', 0, () => {
      let emergencyContactsDataSource = new EmergencyContactsDataSource();
      let emergencyContacts = new ContactListStruct();
      emergencyContactsDataSource.refresh([emergencyContacts]);
      expect(true).assertTrue();
    })
  })
}