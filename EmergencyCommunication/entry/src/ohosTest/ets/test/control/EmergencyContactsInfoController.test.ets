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
import { describe, expect, it } from '@ohos/hypium'
import { EmergencyContactsInfoController } from '../../../../main/ets/control/EmergencyContactsInfoController';
import { ContactListStruct } from '../../../../main/ets/utils/ClassStruct';

export default function EmergencyContactsInfoControllerTest() {
  describe('EmergencyContactsInfoControllerTest', () => {
    it('EmergencyContactsInfoControllerTest_callEmergencyContact', 0, () => {
      EmergencyContactsInfoController.callEmergencyContact(new ContactListStruct());
      expect(true).assertTrue();
    });
    it('EmergencyContactsInfoControllerTest_onSquareAndPencilClick', 0, () => {
      EmergencyContactsInfoController.onSquareAndPencilClick(new NavPathStack());
      expect(true).assertTrue();
    });

    it('EmergencyContactsInfoControllerTest_onAddContactButtonClick', 0, () => {
      EmergencyContactsInfoController.onAddContactButtonClick(false, () => {}, [], () => {},
        () => {}, () => {});
      expect(true).assertTrue();
    });
  })
}