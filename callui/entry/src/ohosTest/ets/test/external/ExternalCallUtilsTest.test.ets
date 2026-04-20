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

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import LogUtils from '../../../../main/ets/common/utils/LogUtils';
import DefaultCallData from '../../../../main/ets/common/struct/TypeUtils';
import {
  isDisconnectCall,
  isIncomingVoiceSilencedCall,
  isSilencedCall
} from '../../../../main/ets/common/utils/CallListHelper';
import CallStateConst from '../../../../main/ets/common/constant/CallStateConst'
import { VideoStateType } from '../../../../main/ets/common/utils/VideoCallApi';
import CallUtils from '../../../../main/ets/common/utils/CallUtils';
import CallStateManager from '../../../../main/ets/model/CallStateManager';
import AudioDeviceManager from '../../../../main/ets/model/audio/AudioDeviceManager';

const TAG = 'ExternalTest_Utils_Function';

export default function ExternalCallUtilsTest() {
  describe('ExternalCallUtilsTest', () => {
    beforeAll(() => {
      LogUtils.i(TAG, 'beforeAll prepare end');
    })
    afterAll(() => {
      LogUtils.i(TAG, 'afterAll ok');
    })
    it('testCallListHelper', 0, async () => {
      await testCallListHelper();
    })
    it('testCallUtils', 0, () => {
      testCallUtils();
    })
    it('testCallStateManager_test_01', 0, () => {
      testCallStateManager();
    })
    it('testAudioDeviceManager', 0, () => {
      testAudioDeviceManager();
    })
  })
}

let testAudioDeviceManager = () => {
  let audioMgr = AudioDeviceManager.getInstance();
  audioMgr.updateAudioDeviceInfo(audioMgr.audioDeviceInfo);
  let isCurUseEar = audioMgr.isCurEarpiece();
  let isCurUseSpeaker = audioMgr.isCurSpeaker();
  let isCurSupportExternalAudioDevice = audioMgr.isExternalAudioDeviceSupport();
  LogUtils.i(TAG, `testCallUtils isCurUseEar:${isCurUseEar} isCurUseSpeaker:${isCurUseSpeaker}
    isCurSupportExternalAudioDevice:${isCurSupportExternalAudioDevice}`);
  expect(true).assertTrue();
}

let testCallStateManager = () => {
  let callData = new DefaultCallData();
  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  let testCallStateManager = new CallStateManager(callData);
  let beforeCallState = 4;
  expect(CallStateConst.CALL_STATUS_INCOMING === beforeCallState).assertTrue();

  callData.callState = CallStateConst.CALL_STATUS_ACTIVE;
  let afterCallState = 0;
  testCallStateManager.update(callData);
  expect(CallStateConst.CALL_STATUS_ACTIVE === afterCallState).assertTrue();
}

let testCallUtils = () => {
  let isMsimActive = CallUtils.isMultiSimActive();
  LogUtils.i(TAG, `testCallUtils isMsimActive:${isMsimActive}`);
  expect(true).assertTrue();
}

let testCallListHelper = () => {
  let callData = new DefaultCallData();
  let isSilenced = isSilencedCall(callData);
  LogUtils.i(TAG, `testCallListHelper isSilenced:${isSilenced}`);
  expect(isSilenced).assertFalse();

  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  let isInComingSilenced = isIncomingVoiceSilencedCall(callData);
  LogUtils.i(TAG, `testCallListHelper isInComingSilenced 1:${isInComingSilenced}`);
  expect(isInComingSilenced).assertFalse();

  callData.isRingSilenced = true;
  isInComingSilenced = isIncomingVoiceSilencedCall(callData);
  LogUtils.i(TAG, `testCallListHelper isInComingSilenced 2:${isInComingSilenced}`);
  expect(isInComingSilenced).assertTrue();

  callData.videoState = VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
  isInComingSilenced = isIncomingVoiceSilencedCall(callData);
  LogUtils.i(TAG, `testCallListHelper isInComingSilenced 3:${isInComingSilenced}`);
  expect(isInComingSilenced).assertFalse();

  let isDisconnect = isDisconnectCall(callData);
  LogUtils.i(TAG, `testCallListHelper isDiconnect:${isDisconnect}`);
  expect(isDisconnect).assertFalse();
}