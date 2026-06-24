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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { SosSettingsController } from '../../../../main/ets/control/SosSettingsController'

export default function SosSettingsControllerTest() {
  describe('SosSettingsControllerTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('SosSettingsControllerTest_checkAutoSendSOSMessagePermission', 0, async () => {
      let sos = SosSettingsController.getInstance();
      let r = await sos.checkAutoSendSOSMessagePermission();
      expect(r).assertEqual(true);
    })
    it('SosSettingsControllerTest_getNoSOSContactsDialogPrimaryTitle', 0, async () => {
      let value = $r('app.string.unable_auto_dial_dialog_title').id;
      let r = SosSettingsController.getNoSOSContactsDialogPrimaryTitle(true, true, 'autoSendSMS', null);
      r = SosSettingsController.getNoSOSContactsDialogPrimaryTitle(false, false, 'inherit', null);
      r = SosSettingsController.getNoSOSContactsDialogPrimaryTitle(false, false, 'autoSendSMS', null);
      r = SosSettingsController.getNoSOSContactsDialogPrimaryTitle(false, false, 'autoDialNumber', null);
      expect(r.id).assertEqual(value);
    })
    it('SosSettingsControllerTest_handleJumpToSosSettingsPage', 0, async () => {
      let parm: NavPathStack = new NavPathStack();
      let sos = SosSettingsController.getInstance();
      let r = sos.handleJumpToSosSettingsPage('SosEmergencyHelpSettings', parm);
      r = sos.handleJumpToSosSettingsPage('EmergencyWarningsSettings', parm);
      try {
        r = sos.handleJumpToSosSettingsPage('inherit', parm);
      } catch (e) {
      }
      expect(r === null).assertEqual(false);
    })
  })
}