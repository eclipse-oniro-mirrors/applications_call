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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import { formatResourceToString } from '../../../../../main/ets/common/utils/formatResourceToString';
import { MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';

export default function formatResourceToStringTest() {
  describe('formatResourceToStringTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // function $r(value: string, ...params: any[]): Resource;
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

    it('formatResourceToStringTest_02', 0, () => {
      let resource = $r('app.string.APN_Not_set');
      let result = formatResourceToString(resource);
      let context = MobileDataGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
      let res = context.resourceManager.getStringSync(resource);
    })
  })
}