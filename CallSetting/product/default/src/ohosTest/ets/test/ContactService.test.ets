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
import common from '../../../main/ets/data/CommonData';
import ContactService from '../../../main/ets/service/ContactService';
import commonData from '../../../main/ets/data/CommonData';

export default function ContactServiceTest() {
  describe('ContactServiceTest', () => {
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

    it('TestContactService', 0, () => {
      let actionData: Record<string, string> = {
        'pageFlag': commonData.contactPage.PAGE_FLAG_EDIT_BEFORE_CALLING,
        'phoneNumber': '950800'
      };
      let newStr: Record<string, Object> = {
        'bundleName': common.string.CONTACT_BUNDLE_NAME,
        'abilityName': common.string.CONTACT_ABILITY_NAME,
        'parameters': actionData,
        'entities': [
        common.string.COMMON_ENTITIES
        ]
      };
      let str = ContactService.getPhoneNumberParam(actionData);
      expect(str['parameters']).assertEqual(newStr['parameters']);
    })
  })
}