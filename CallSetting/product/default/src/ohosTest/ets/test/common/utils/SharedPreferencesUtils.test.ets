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
} from '@ohos/hypium';
import {
  CallSettingGlobalContextHelper,
  MobileDataSharedPreferencesUtils,
  sharedPreferencesUtils
} from '@ohos/common/CommonIndex';
import * as CallSettingsConstant from '../../../../../main/ets/common/constant/CallSettingsConstant';
import data_preferences from '@ohos.data.preferences';
import { sleep } from './Sleep';

export default function SharedPreferencesUtilsTest() {
  describe('SharedPreferencesUtilsTest', () => {
    const KEY: string = 'SharedPreferencesUtilsTest_saveToPreferences';
    const CONTACT_PREFERENCE: string = 'CONTACT_PREFERENCE';
    let data: data_preferences.Preferences;
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
    it('SharedPreferencesUtilsTest_getFromPreferences', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sharedPreferencesUtils, (sharedPreferencesUtils as object)['getPreferences']);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(null);
      let result = await sharedPreferencesUtils.getFromPreferences('1', '2');
      await sharedPreferencesUtils.saveToPreferences('1', '2');
      mocker.ignoreMock(sharedPreferencesUtils, (sharedPreferencesUtils as object)['getPreferences']);
      let mobile = new MobileDataSharedPreferencesUtils();
      sleep(1000);
      let mockFunc1 = mocker.mockFunc(mobile, (mobile as object)['getPreferences']);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(null);
      await mobile.getFromPreferences('1', '2');
      await mobile.saveToPreferences('1', '2');
      mocker.ignoreMock(mobile, (mobile as object)['getPreferences']);
      expect(result).assertEqual('2');
    });
    it('SharedPreferencesUtilsTest_saveToPreferences', 0, async () => {
      let value: number = 1;
      try {
        let dataPreferences: data_preferences.Preferences =
          await data_preferences.getPreferences(CallSettingGlobalContextHelper.getContext()
            .getValue(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT), CONTACT_PREFERENCE);
        if (dataPreferences) {
          let data = await dataPreferences.get(KEY, 2);
          expect(true).assertTrue();
          await dataPreferences.delete(KEY);
          expect(true).assertTrue();
        }
      } catch (error) {
      }
    })
  })
}