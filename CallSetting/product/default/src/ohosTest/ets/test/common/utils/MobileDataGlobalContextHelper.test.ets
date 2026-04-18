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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';

export default function MobileDataGlobalContextHelperTest() {
  describe('MobileDataGlobalContextHelperTest', () => {
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

    it('MobileDataGlobalContextHelperTest_getContext', 0, () => {
      let initialValue = MobileDataGlobalContextHelper.getContext();
      let comparisonValue = MobileDataGlobalContextHelper.getContext();
      expect(initialValue).assertEqual(comparisonValue);
    })

    it('MobileDataGlobalContextHelperTest_set_01', 0, () => {
      let value: Record<string, object> = {};
      MobileDataGlobalContextHelper.getContext().set(Constants.SETTINGS_ABILITY_CONTEXT, value);
      let res: object = MobileDataGlobalContextHelper.getContext().getValue(Constants.SETTINGS_ABILITY_CONTEXT);
      expect(res).assertEqual(value);
    })

    //undefined直接return
    it('MobileDataGlobalContextHelperTest_set_02', 0, () => {
      let value: Record<string, object> = {};
      MobileDataGlobalContextHelper.getContext().set('TEST01', value);
      let res: object = MobileDataGlobalContextHelper.getContext().getValue('TEST01');
      expect(res).assertEqual(undefined);
    })
  })
}