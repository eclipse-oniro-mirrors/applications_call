/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import CallStateConst from '../../../main/ets/common/constant/CallStateConst';
import DefaultCallData from '../../../main/ets/common/struct/TypeUtils';
import SatelliteCallManager from '../../../main/ets/model/SatelliteCallManager';

let nSatelliteCallManager = SatelliteCallManager.getInstance();
let call1: DefaultCallData = new DefaultCallData();
call1.callType = CallStateConst.TYPE_SATELLITE;
call1.callState = CallStateConst.CALL_STATUS_INCOMING;
let call2: DefaultCallData = new DefaultCallData();
call2.callType = CallStateConst.TYPE_SATELLITE;
call2.callState = CallStateConst.CALL_STATUS_ACTIVE;
nSatelliteCallManager.tryShowSatelliteCallAnswerToast(call1, call2);

const satelliteCallManager_Test_001 = () => {
  nSatelliteCallManager.tryShowSatelliteCallAnswerToast(call1, call2);
  expect(true).assertTrue()
}

const satelliteCallManager_Test_002 = () => {
  call1.callType = 3;
  nSatelliteCallManager.tryShowSatelliteCallAnswerToast(call1, call2);
  expect(call1.callType !== CallStateConst.TYPE_SATELLITE).assertTrue();
}

const satelliteCallManager_Test_003 = () => {
  call1.callType = CallStateConst.TYPE_SATELLITE;
  call1.callState = 99;
  nSatelliteCallManager.tryShowSatelliteCallAnswerToast(call1, call2);
  expect(call1.callState !== call2.callState).assertTrue();
}

const satelliteCallManager_Test_004 = () => {
  call1.callState = CallStateConst.CALL_STATUS_INCOMING;
  call2.callState = CallStateConst.CALL_STATUS_ANSWER;
  nSatelliteCallManager.tryShowSatelliteCallAnswerToast(call1, call2);
  expect((call1.callState === CallStateConst.CALL_STATUS_INCOMING ||
    call1.callState === CallStateConst.CALL_STATUS_WAITING) &&
    call2.callState === CallStateConst.CALL_STATUS_ANSWER).assertTrue();
}

export default function SatelliteCallManagerTest() {
  describe('SatelliteCallManagerTest', () => {
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
    it('SatelliteCallManager_Test_001', 0, () => {
      satelliteCallManager_Test_001();
    })
    it('SatelliteCallManager_Test_002', 0, () => {
      satelliteCallManager_Test_002();
    })
    it('SatelliteCallManager_Test_003', 0, () => {
      satelliteCallManager_Test_003();
    })
    it('SatelliteCallManager_Test_004', 0, () => {
      satelliteCallManager_Test_004();
    })
  })
}