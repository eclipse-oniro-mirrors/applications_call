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
import { BANNER, DEFAULT_CONFIG, FULL_SCREEN } from '../../../../../main/ets/common/utils/Constants';
import { StringUtil } from '../../../../../main/ets/common/utils/StringUtil';
import Utils from '../../../../../main/ets/common/utils/utils';

export default function UtilsTest() {
  let emStr: string;

  describe('UtilsTest', () => {
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

    it('getCallNotifiesFromSettingsDataTest_01', 0, () => {
      Utils.getInstance().getCallNotifiesFromSettingsData((configData) => {
        expect([FULL_SCREEN, BANNER]).assertContain(configData);
      });
    })
    it('getCallNotifiesFromSettingsDataTest_02', 0, () => {
      Utils.getInstance().getCallNotifiesFromSettingsData((configData) => {
        expect(configData).assertEqual(DEFAULT_CONFIG)
      });
    })
    it('getAccessibilityTextOfTimeTest', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFormatPluralResourceToString: Function =
        mocker.mockFunc(StringUtil, StringUtil.formatPluralResourceToString);
      when(mockFormatPluralResourceToString)(ArgumentMatchers.any).afterReturn('.');
      let str = Utils.getInstance().getAccessibilityTextOfTime('10:10');
      str = Utils.getInstance().getAccessibilityTextOfTime('10:10:10');
      str = Utils.getInstance().getAccessibilityTextOfTime('00:00:00');
      str = Utils.getInstance().getAccessibilityTextOfTime('00:00');
      str = Utils.getInstance().getAccessibilityTextOfTime(emStr);
      expect(str).assertEqual('');
      mocker.clear(StringUtil);
    })
  })
}
