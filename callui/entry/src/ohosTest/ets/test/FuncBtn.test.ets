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
import CallTypeConst from '../../../main/ets/common/constant/CallTypeConst';
import DefaultCallData from '../../../main/ets/common/struct/TypeUtils';
import { isActiveCall, isOutgoingCall } from '../../../main/ets/common/utils/CallListHelper';
import { VideoStateType } from '../../../main/ets/common/utils/VideoCallApi';

export default function FuncBtnTest() {
  describe('FuncBtnTest', () => {
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
    it('isCsCall', 0, () => {
      let callData: DefaultCallData = {
        videoState: VideoStateType.TYPE_VIDEO_BIDIRECTIONAL,
        callState: CallStateConst.CALL_STATUS_ACTIVE,
        accountId: 0,
        accountNumber: '',
        callId: 0,
        callType: CallTypeConst.CALL_TYPE_CS,
        conferenceState: 0,
        contactName: '',
        formatNumber: '',
        isEcc: false,
        startTime: 0,
        numberLocation: '',
        contactCompany: '',
        contactCompanyPosition: '',
        numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
      };
      let isCsCall = callData.callType === CallTypeConst.CALL_TYPE_CS;
      let isForegroundCallHolding = isActiveCall(callData.callState);
      let hasOutgoingCall = isOutgoingCall(callData.callState);
      let isDisabled = isCsCall || hasOutgoingCall || isForegroundCallHolding;
      expect(isDisabled).assertTrue()
    })
  })
}