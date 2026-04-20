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
  getSimCardDefaultPhoneNumber,
  getSimCardPhoneNumber
} from '../../../../../main/ets/common/model/getSimTelephoneNumberApi';
import sim from '@ohos.telephony.sim';
import { JSON } from '@kit.ArkTS';
import { LogUtils } from '@ohos/common/CommonIndex';
import { BusinessError } from '@ohos.base';

const TAG = 'getSimTelephoneNumberApiTest'

export default function getSimTelephoneNumberApiTest() {
  describe('getSimTelephoneNumberApiTest', () => {
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
    it('getSimTelephoneNumberApiTest_getSimCardPhoneNumber', 0, async () => {
      if (sim.hasSimCardSync(0)) {
        let result = await getSimCardPhoneNumber(0);
        let number = await getNumber(0);
        expect(result).assertEqual(number);
      }
      if (sim.hasSimCardSync(1)) {
        let result = await getSimCardPhoneNumber(1);
        let number = await getNumber(1);
        expect(result).assertEqual(number);
      }
    })
    it('getSimTelephoneNumberApiTest_getSimCardDefaultPhoneNumber', 0, () => {
      let result = JSON.stringify(getSimCardDefaultPhoneNumber(0));
      let exp = JSON.stringify(sim.getSimTelephoneNumber(0));
      expect(result).assertEqual(exp);
      result = JSON.stringify(getSimCardDefaultPhoneNumber(1));
      expect(result).assertEqual(exp);
    })
  })
}

let getNumber = (slotId: number) => {
  return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
    try {
      sim.getShowNumber(slotId, (error, value) => {
        if (error) {
          LogUtils.e(TAG, 'getShowNumber error:' + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, 'getShowNumber success:' + 'The request is successful.');
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'getShowNumber catch:' + JSON.stringify(error));
      reject(error);
    }
  });
}