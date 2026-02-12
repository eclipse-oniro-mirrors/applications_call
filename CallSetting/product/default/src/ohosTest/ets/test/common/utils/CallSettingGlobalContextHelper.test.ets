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
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import * as CallSettingsConstant from '../../../../../main/ets/common/constant/CallSettingsConstant';

export default function CallSettingGlobalContextHelperTest() {
  describe('CallSettingGlobalContextHelperTest', () => {
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

    it('TestCallSettingGlobalContextHelper_01', 0, () => {
      let value: Record<string, object> = {};
      value = CallSettingGlobalContextHelper.getContext().getValue(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
      let obj: Record<string, object> = {};
      CallSettingGlobalContextHelper.getContext().set(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT,
        obj);
      let res: object = CallSettingGlobalContextHelper.getContext()
        .getValue(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
      expect(res).assertEqual(obj);
      CallSettingGlobalContextHelper.getContext().set(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT,
        value);
    })

    it('TestCallSettingGlobalContextHelper_02', 0, () => {
      let value: Record<string, object> = {};
      CallSettingGlobalContextHelper.getContext().set('SettingContext', value);
      let res: object = CallSettingGlobalContextHelper.getContext().getValue('SettingContext');
      expect(res).assertEqual(undefined);
    })

    it('TestCallSettingGlobalContextHelper_03', 0, () => {
      let value: Record<string, object> = {};
      CallSettingGlobalContextHelper.getContext().set(CallSettingsConstant.PRIVACY_STATEMENT_ABILITY_CONTEXT,
        value);
      let res: object = CallSettingGlobalContextHelper.getContext()
        .getValue(CallSettingsConstant.PRIVACY_STATEMENT_ABILITY_CONTEXT);
      expect(res).assertEqual(undefined);
    })
  })
}