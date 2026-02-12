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
import { LogUtils } from "@ohos/common"
import SystemModeUtils from "@ohos/common/src/main/ets/utils/SystemModeUtils"
import { afterAll, beforeAll, afterEach, beforeEach, describe, expect, it, MockKit, when } from "@ohos/hypium"

export default function SystemModeUtilsTest() {
  describe('SystemModeUtilsTest', () => {
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

    it('SystemModeGetTest', 0, () => {
      let sInstance: SystemModeUtils = SystemModeUtils.getInstance();
      const result = sInstance.get();
      expect(result.isEnabled).assertEqual(false);
      expect(result.name).assertEqual('');
    });

    it('SystemModeIsEnablePenglaiTest',  0, () => {
      const result = SystemModeUtils.getInstance().isEnablePenglai();
      expect(result).assertEqual(false);
    });

    it('SystemModeGetNameTest', 0, () => {
      let sInstance: SystemModeUtils = SystemModeUtils.getInstance();
      const result = sInstance.getName();
      expect(result).assertEqual('');
    });

    it('SystemModeIsEnableTest', 0, () => {
      let sInstance: SystemModeUtils = SystemModeUtils.getInstance();
      let result = sInstance.isEnable('PENGLAI');
      expect(result).assertEqual(false);
    });
  })
}