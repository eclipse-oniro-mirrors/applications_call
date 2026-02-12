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
import call from '@ohos.telephony.call';
import SubCallForwardData from '../../../main/ets/common/struct/SubCallForwardData';

export default function SubCallForwardDataTest() {
  describe('SubCallForwardDataTest', () => {
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

    it('TestSubCallForwardData_01', 0, () => {
      let displayName = $r('app.string.call_history_merging');
      let isEnable = false;
      let isFirst = false;
      let isLast = false;
      let forwardResult = undefined;
      let callForwardType = call.CallTransferType.TRANSFER_TYPE_UNCONDITIONAL;
      let data: SubCallForwardData = new SubCallForwardData(displayName, callForwardType, isEnable, forwardResult,
        isFirst, isLast);
      expect(data.displayName).assertEqual(displayName);

      expect(data.isEnable).assertEqual(isEnable);

      expect(data.isFirst).assertEqual(isFirst);

      expect(data.isLast).assertEqual(isLast);

      expect(data.forwardResult).assertEqual(forwardResult);

      expect(data.callForwardType).assertEqual(callForwardType);
    })

    it('TestSubCallForwardData_02', 0, () => {
      let displayName = $r('app.string.call_history_merging');
      let isEnable = false;
      let isFirst = false;
      let isLast = false;
      let forwardResult = undefined;
      let callForwardType = call.CallTransferType.TRANSFER_TYPE_BUSY;
      let data: SubCallForwardData = new SubCallForwardData(displayName, callForwardType, isEnable, forwardResult,
        isFirst, isLast);
      expect(data.displayName).assertEqual(displayName);

      expect(data.isEnable).assertEqual(isEnable);

      expect(data.isFirst).assertEqual(isFirst);

      expect(data.isLast).assertEqual(isLast);

      expect(data.forwardResult).assertEqual(forwardResult);

      expect(data.callForwardType).assertEqual(callForwardType);
    })

    it('TestSubCallForwardData_03', 0, () => {
      let displayName = $r('app.string.call_history_merging');
      let isEnable = undefined;
      let isFirst = undefined;
      let isLast = undefined;
      let forwardResult = undefined;
      let callForwardType = call.CallTransferType.TRANSFER_TYPE_NO_REPLY;
      let data: SubCallForwardData = new SubCallForwardData(displayName, callForwardType, isEnable, forwardResult,
        isFirst, isLast);
      expect(data.displayName).assertEqual(displayName);

      expect(data.isEnable).assertEqual(isEnable);

      expect(data.isFirst).assertEqual(isFirst);

      expect(data.isLast).assertEqual(isLast);

      expect(data.forwardResult).assertEqual(forwardResult);

      expect(data.callForwardType).assertEqual(callForwardType);
    })

    it('TestSubCallForwardData_04', 0, () => {
      let displayName = $r('app.string.call_history_merging');
      let isEnable = undefined;
      let isFirst = undefined;
      let isLast = undefined;
      let forwardResult = undefined;
      let callForwardType = call.CallTransferType.TRANSFER_TYPE_NOT_REACHABLE;
      let data: SubCallForwardData = new SubCallForwardData(displayName, callForwardType, isEnable, forwardResult,
        isFirst, isLast);
      expect(data.displayName).assertEqual(displayName);

      expect(data.isEnable).assertEqual(isEnable);

      expect(data.isFirst).assertEqual(isFirst);

      expect(data.isLast).assertEqual(isLast);

      expect(data.forwardResult).assertEqual(forwardResult);

      expect(data.callForwardType).assertEqual(callForwardType);
    })
  })
}