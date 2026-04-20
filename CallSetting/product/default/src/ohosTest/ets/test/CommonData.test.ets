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
import CommonData from '../../../main/ets/data/CommonData';

export default function CommonDataTest() {
  describe('CommonDataTest', () => {
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

    it('TestCommonData', 0, () => {
      if (CommonData.string) {
        expect(CommonData.string.CONTACT_BUNDLE_NAME).assertEqual('com.ohos.contacts');

        expect(CommonData.string.CONTACT_ABILITY_NAME).assertEqual('com.ohos.contacts.MainAbility');

        expect(CommonData.string.COMMON_ENTITIES).assertEqual('entity.system.home');

        expect(CommonData.string.MOBILE_SETTING_BUNDLE_NAME).assertEqual('com.ohos.callui');

        expect(CommonData.string.MOBILE_SETTING_ABILITY_NAME).assertEqual('com.ohos.mobiledatasettings.MainAbility');

        expect(CommonData.string.ERROR_CODE).assertEqual('8300003');

        expect(CommonData.string.REJECT_MESSAGE_PAGE_FLAG).assertEqual('rejectMessagePage');

        expect(CommonData.string.CALL_UI_BUNDLE_NAME).assertEqual('com.ohos.callui');

        expect(CommonData.string.CALL_UI_CALL_SETTING_ABILITU_NAME)
          .assertEqual('com.ohos.callui.IncomingCallRejectionSmsAbility');

        expect(CommonData.string.CONTACT_SPEED_DIAL_ABILITY_NAME).assertEqual('com.ohos.contacts.SpeedDialAbility');

        expect(CommonData.string.VOICE_MAIL_PAGE).assertEqual('voicemailPage');
      }
      if (CommonData.contactPage) {
        expect(CommonData.contactPage.PAGE_FLAG_SINGLE_CHOOSE).assertEqual('page_flag_single_choose');
        expect(CommonData.contactPage.PAGE_FLAG_EDIT_BEFORE_CALLING).assertEqual('page_flag_edit_before_calling');
      }
    })
  })
}