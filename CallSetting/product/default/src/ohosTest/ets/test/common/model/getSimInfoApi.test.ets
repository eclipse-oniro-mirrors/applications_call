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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import * as getSimInfoApi from '../../../../../main/ets/common/model/getSimInfoApi';
import sim from '@ohos.telephony.sim';
import { JSON } from '@kit.ArkTS';

export default function getSimInfoApiTest() {
  describe('getSimInfoApiTest', () => {
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
    it('getSimInfoApiTest_getSimStateCardOne', 0, () => {
      let result = JSON.stringify(getSimInfoApi.getSimStateCardOne(0));
      let state = JSON.stringify(sim.getSimState(0));
      expect(result).assertEqual(state);
    })
    it('getSimInfoApiTest_getSimStateCardTwo', 0, () => {
      let result = JSON.stringify(getSimInfoApi.getSimStateCardTwo(1));
      let state = JSON.stringify(sim.getSimState(1));
      expect(result).assertEqual(state);
    })
    it('getSimInfoApiTest_getSimCardOnePhoneNumber', 0, () => {
      let result = JSON.stringify(getSimInfoApi.getSimCardOnePhoneNumber());
      let number = JSON.stringify(sim.getShowNumber(0));
      expect(result).assertEqual(number);
    })
    it('getSimInfoApiTest_getSimCardTwoPhoneNumber', 0, () => {
      let result = JSON.stringify(getSimInfoApi.getSimCardTwoPhoneNumber());
      let number = JSON.stringify(sim.getShowNumber(1));
      expect(result).assertEqual(number);
    })
    it('getSimInfoApiTest_getSimCardActiveStatus', 0, () => {
      let result = JSON.stringify(sim.isSimActive(0));
      let isActive = JSON.stringify(getSimInfoApi.getSimCardActiveStatus(0));
      expect(result).assertEqual(isActive)
    })
    it('getSimInfoApiTest_getSimCardDefaultPhoneNumber', 0, () => {
      let result = JSON.stringify(getSimInfoApi.getSimCardDefaultPhoneNumber());
      let number = JSON.stringify(sim.getSimTelephoneNumber(0));
      expect(result).assertEqual(number)
    })
  })
}