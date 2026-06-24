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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium'
import { ContactsService } from '../../../../main/ets/service/ContactsService'
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import { common, Context } from '@kit.AbilityKit';
import { EMERGENCY_CALL_ABILITY_CONTEXT } from '../../../../main/ets/utils/Constants';
import { DataStorageUtil } from '../../../../main/ets/utils/DataStorageUtil';
import { sleep } from '../utils/Sleep';
import { ContactListStruct } from '../../../../main/ets/utils/ClassStruct';

let contact = ContactsService.getInstance();
let mocker: MockKit = new MockKit();
let context: Context;

export default function ContactsServiceTest() {
  describe('ContactsServiceTest', () => {
    beforeAll(() => {
      context = EmergencyGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(EMERGENCY_CALL_ABILITY_CONTEXT);
    })

    it('ContactsServiceTest_checkReadContactsPermission', 0, async () => {
      ContactsService.getInstance();
      let cont = new ContactListStruct();
      let cont1 = new ContactListStruct();
      cont.nameRawContactId = 1;
      let arr: ContactListStruct[] = [cont, cont1];
      await contact.checkReadContactsPermission();
      await (contact as object)['syncAndGetEmergencyContactFromContactDatabase'](context);
      await contact.syncAndGetEmergencyContactsFromDatabase(context);
      sleep(1000);
      let mockFunc =
        mocker.mockFunc(DataStorageUtil.getInstance(), DataStorageUtil.getInstance().getEmergencyContactsSync);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(arr);
      await (contact as object)['syncAndGetEmergencyContactFromContactDatabase'](context);
      expect(arr.length >= 0).assertTrue();
      mocker.ignoreMock(DataStorageUtil.getInstance(), DataStorageUtil.getInstance().getEmergencyContactsSync);
    })
  })
}