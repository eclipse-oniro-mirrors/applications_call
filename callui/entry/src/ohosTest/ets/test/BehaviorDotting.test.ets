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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import CallStateConst from '../../../main/ets/common/constant/CallStateConst';
import DefaultCallData, { NumberMarkInfo } from '../../../main/ets/common/struct/TypeUtils';
import { BehaviorDotting } from '../../../main/ets/common/utils/ReportUtils/BehaviorDotting'
import call from '@ohos.telephony.call';

export default function BehaviorDottingTest() {
  describe('BehaviorDottingTest', () => {
    let dot = BehaviorDotting.getInstance();
    it('BehaviorDotting_incomingCallDotting', 0, () => {
      BehaviorDotting.getInstance();
      let target: DefaultCallData = {
        accountId: 0,
        accountNumber: '',
        callId: 0,
        callState: 9,
        callType: 0,
        conferenceState: 0,
        contactName: '',
        formatNumber: '',
        isEcc: false,
        startTime: 0,
        videoState: 0,
        numberLocation: '',
        contactCompany: '',
        contactCompanyPosition: '',
        numberMarkInfo: new NumberMarkInfo
      };
      let callData: DefaultCallData = {
        accountId: 0,
        accountNumber: '',
        callId: 0,
        callState: 0,
        callType: 0,
        conferenceState: 0,
        contactName: '',
        formatNumber: '',
        isEcc: false,
        startTime: 0,
        videoState: call.VideoStateType.TYPE_VIDEO_BIDIRECTIONAL,
        numberLocation: '',
        contactCompany: '',
        contactCompanyPosition: '',
        numberMarkInfo: new NumberMarkInfo,
      }
      dot.incomingCallDotting(target, callData);
      dot.hungOutDotting(callData);
      dot.updatedCallTypeDotting(callData, '');
      callData.callDirection = CallStateConst.CALL_DIRECTION_INCOMING;
      callData.videoState = call.VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
      callData.contactName = 'test';
      dot.hungOutDotting(callData);
      target.callState = CallStateConst.CALL_STATUS_WAITING;
      dot.incomingCallDotting(target, callData);
      target.callState = CallStateConst.CALL_STATUS_ALERTING;
      dot.incomingCallDotting(target, callData);
      target.callState = CallStateConst.CALL_STATUS_INCOMING;
      dot.incomingCallDotting(target, callData);
      target.callState = CallStateConst.CALL_STATUS_DISCONNECTING;
      dot.incomingCallDotting(target, callData);
      callData.callState = 1;
      dot.updatedCallTypeDotting(callData, '');
      dot.hungOutDotting(callData);
      dot.incomingCallDotting(target, callData);
      expect(target.callState).assertEqual(7);
    })
  })
}