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
import {
  SimCardOneInfoStruct,
  SimCardTwoInfoStruct,
  SimCardInfoStruct,
  SatelliteSimCardInfoStruct
} from '@ohos/common/CommonIndex';

export default function SimCardInfoStructTest() {
  describe('SimCardInfoStructTest', () => {
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
    it('SimCardInfoStructTest_01', 0, () => {
      let simCardOneInfoStruct = new SimCardOneInfoStruct();
      simCardOneInfoStruct.setData(0,true,true,'12345678999','test');
      let simCardTwoInfoStruct = new SimCardTwoInfoStruct();
      let simCardInfoStruct = new SimCardInfoStruct();
      let result = simCardInfoStruct.setData(0,true,true,'12345678999','test')
      let satelliteSimCardInfoStruct = new SatelliteSimCardInfoStruct()
      expect(result == null).assertTrue()
    })
  })
}