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

import { describe, it, expect } from '@ohos/hypium';
import DefaultCallData from '../../../../../main/ets/common/struct/TypeUtils';
import { ImsCallMode, VideoStateType } from '../../../../../main/ets/common/utils/VideoCallApi';
import {
  canMerge,
  canShowVideoCallUi,
  getActiveCallId,
  getFirstCallByState,
  getFirstCallByStateExcludeCall,
  getForegroundCall,
  getForegroundLiveCall,
  getOutgoingCall,
  getPrimaryIncomingCall,
  getSecondaryIncomingCall,
  getVideoCall,
  getWasConnectedCallCount,
  isActiveCall,
  isDisconnectCall,
  isIncomingCall,
  isIncomingVoiceSilencedCall,
  isOneWayVideo,
  isOutgoingCall,
  isSecondaryCallWaiting,
  isSilencedCall,
  isUpgradingToVideo,
  isVideoCall,
  isVoiceCall,
  setConferenceDisconnecting,
  setSystemBarEnable,
  shouldShowRbtView
} from '../../../../../main/ets/common/utils/CallListHelper';
import CallStateConst from '../../../../../main/ets/common/constant/CallStateConst';
import ConferenceConst from '../../../../../main/ets/common/constant/ConferenceConst';

let callData: DefaultCallData[] = [
  {
    videoState: VideoStateType.TYPE_VOICE,
    callState: CallStateConst.CALL_STATUS_ANSWER,
    accountId: 0,
    accountNumber: '',
    callId: 0,
    callType: CallStateConst.TYPE_IMS,
    conferenceState: 0,
    contactName: '',
    formatNumber: '123456789',
    isEcc: false,
    startTime: 0,
    numberLocation: '',
    contactCompany: '',
    contactCompanyPosition: '',
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
  }
]

let callData3: DefaultCallData[] = [
  {
    videoState: VideoStateType.TYPE_VOICE,
    callState: CallStateConst.CALL_STATUS_IDLE,
    accountId: 0,
    accountNumber: '',
    callId: 1,
    callType: CallStateConst.TYPE_IMS,
    conferenceState: 0,
    contactName: '',
    formatNumber: '123456789',
    isEcc: false,
    startTime: 0,
    numberLocation: '',
    contactCompany: '',
    contactCompanyPosition: '',
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
  },
  {
    videoState: VideoStateType.TYPE_VOICE,
    callState: CallStateConst.CALL_STATUS_IDLE,
    accountId: 0,
    accountNumber: '',
    callId: 0,
    callType: CallStateConst.TYPE_IMS,
    conferenceState: 0,
    contactName: '',
    formatNumber: '123456789',
    isEcc: false,
    startTime: 0,
    numberLocation: '',
    contactCompany: '',
    contactCompanyPosition: '',
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
  }
]

let callData4: DefaultCallData[] = [
  {
    videoState: VideoStateType.TYPE_VOICE,
    callState: CallStateConst.CALL_STATUS_ANSWER,
    accountId: 0,
    accountNumber: '',
    callId: 1,
    callType: CallStateConst.TYPE_IMS,
    conferenceState: 0,
    contactName: '',
    formatNumber: '123456789',
    isEcc: false,
    startTime: 0,
    numberLocation: '',
    contactCompany: '',
    contactCompanyPosition: '',
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
  },
  {
    videoState: VideoStateType.TYPE_VOICE,
    callState: CallStateConst.CALL_STATUS_ANSWER,
    accountId: 0,
    accountNumber: '',
    callId: 0,
    callType: CallStateConst.TYPE_IMS,
    conferenceState: 0,
    contactName: '',
    formatNumber: '123456789',
    isEcc: false,
    startTime: 0,
    numberLocation: '',
    contactCompany: '',
    contactCompanyPosition: '',
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
  },
  {
    videoState: VideoStateType.TYPE_VOICE,
    callState: CallStateConst.CALL_STATUS_ANSWER,
    accountId: 0,
    accountNumber: '',
    callId: 0,
    callType: CallStateConst.TYPE_IMS,
    conferenceState: 0,
    contactName: '',
    formatNumber: '123456789',
    isEcc: false,
    startTime: 0,
    numberLocation: '',
    contactCompany: '',
    contactCompanyPosition: '',
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
  }
]

let isVideoCall_test = () => {
  callData[0].videoState = VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
  expect(true).assertEqual(isVideoCall(callData[0].videoState));
}

let isIncomingCall_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_WAITING;
  expect(isIncomingCall(callData[0].callState)).assertTrue();
  callData[0].callState = CallStateConst.CALL_STATUS_ANSWER;
  expect(isIncomingCall(callData[0].callState)).assertFalse();
  expect(isIncomingCall(callData[0].callState, true)).assertTrue();
}

let isActiveCall_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_ANSWER;
  expect(isActiveCall(callData[0].callState)).assertTrue();
  callData[0].callState = CallStateConst.CALL_STATUS_ACTIVE;
  expect(isActiveCall(callData[0].callState)).assertTrue();
  callData[0].callState = CallStateConst.CALL_STATUS_HOLDING;
  expect(isActiveCall(callData[0].callState)).assertTrue();
}

let getForegroundCall_test = () => {
  expect(getForegroundCall(callData)).not().assertNull();
  callData3[0].callState = CallStateConst.CALL_STATUS_INCOMING;
  let result = getForegroundCall(callData3);
  if (result) {
    expect(result.callState).assertEqual(4);
  }
  callData3[0].callState = CallStateConst.CALL_STATUS_DIALING;
  let result2 = getForegroundCall(callData3);
  if (result2) {
    expect(result2.callState).assertEqual(2);
  }
  callData3[0].callState = CallStateConst.CALL_STATUS_ANSWER;
  let result3 = getForegroundCall(callData3);
  if (result3) {
    expect(result3.callState).assertEqual(9);
  }
  callData3[0].callState = CallStateConst.CALL_STATUS_ACTIVE;
  callData3[1].callState = CallStateConst.CALL_STATUS_ACTIVE;
  let result4 = getForegroundCall(callData3);
  if (result4) {
    expect(result4.callState).assertEqual(0);
  }
  callData3[0].callState = CallStateConst.CALL_STATUS_HOLDING;
  callData3[1].callState = CallStateConst.CALL_STATUS_HOLDING;
  let result5 = getForegroundCall(callData3);
  if (result5) {
    expect(result5.callState).assertEqual(1);
  }
  callData3[0].callState = CallStateConst.CALL_STATUS_DISCONNECTING;
  callData3[1].callState = CallStateConst.CALL_STATUS_DISCONNECTED;
  let result6 = getForegroundCall(callData3);
  if (result6) {
    expect(result6.callState).assertEqual(7);
  } else {
    expect(true).assertTrue();
  }
}

let getPrimaryIncomingCall_test = () => {
  callData3[0].callState = CallStateConst.CALL_STATUS_INCOMING;
  let result = getPrimaryIncomingCall(callData3);
  if (result) {
    expect(result.callState).assertEqual(4);
  } else {
    expect(true).assertTrue();
  }
}

let getSecondaryIncomingCall_test = () => {
  let result = getSecondaryIncomingCall(callData);
  if (!result) {
    expect(getSecondaryIncomingCall(callData) === undefined).assertTrue();
  } else {
    expect(true).assertTrue();
  }
  callData3[0].callState = CallStateConst.CALL_STATUS_IDLE;
  callData3[1].callState = CallStateConst.CALL_STATUS_IDLE;
  let result2 = getSecondaryIncomingCall(callData3);
  if (!result2) {
    expect(result2 === undefined).assertTrue();
  } else {
    expect(true).assertTrue();
  }
  callData3[0].callState = CallStateConst.CALL_STATUS_INCOMING;
  callData3[1].callState = CallStateConst.CALL_STATUS_INCOMING;
  let result3 = getSecondaryIncomingCall(callData3);
  if (result3) {
    expect(result3.callState).assertEqual(4);
  } else {
    expect(result3 === undefined).assertTrue();
  }
}

let isOutgoingCall_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_DIALING;
  let result = isOutgoingCall(callData[0].callState);
  if (result) {
    expect(result).assertTrue();
  } else {
    expect(result).assertFalse();
  }
}

let getOutgoingCall_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_DIALING;
  let result = getOutgoingCall(callData);
  if (result) {
    expect(result.callState).assertEqual(2);
  } else {
    expect(true).assertTrue();
  }
}

let getFirstCallByState_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_DIALING;
  let result = getFirstCallByState(callData, CallStateConst.CALL_STATUS_DIALING);
  if (result) {
    expect(result.callState).assertEqual(2);
  } else {
    expect(true).assertTrue();
  }
}

let getFirstCallByStateExcludeCall_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_DIALING;
  let result = getFirstCallByStateExcludeCall(callData, CallStateConst.CALL_STATUS_DIALING, callData[0]);
  if (result) {
    expect(result.callState).assertEqual(CallStateConst.CALL_STATUS_DIALING);
  }
}

let getVideoCall_test = () => {
  callData[0].videoState = CallStateConst.VIDEO_STATE_VIDEO;
  let result = getVideoCall(callData);
  if (result) {
    expect(result.videoState === CallStateConst.VIDEO_STATE_VIDEO).assertTrue();
  } else {
    expect(true).assertTrue();
  }
}

let isOneWayVideo_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_ACTIVE;
  callData[0].videoState = VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
  expect(isOneWayVideo(callData[0])).assertTrue();
  callData[0].videoState = VideoStateType.TYPE_VIDEO_SEND_ONLY;
  expect(isOneWayVideo(callData[0])).assertTrue();
}

let isVoiceCall_test = () => {
  callData[0].videoState = VideoStateType.TYPE_VOICE;
  expect(isVoiceCall(callData[0])).assertTrue();
}

let getActiveCallId_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_ACTIVE;
  expect(getActiveCallId(callData) === 0).assertTrue();
}

let shouldShowRbtView_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_INCOMING;
  callData[0].crsType = 2;
  expect(shouldShowRbtView(callData[0])).assertTrue();
  callData[0].callState = CallStateConst.CALL_STATUS_DIALING;
  callData[0].imsCallMode = ImsCallMode.CALL_MODE_RECEIVE_ONLY;
  expect(shouldShowRbtView(callData[0])).assertTrue();
}

let canShowVideoCallUi_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_INCOMING;
  expect(canShowVideoCallUi(callData[0].callState, callData[0].videoState, callData[0].isHoldVideoUx)).assertFalse();
  callData[0].videoState = VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
  callData[0].callState = CallStateConst.CALL_STATUS_DIALING;
  expect(canShowVideoCallUi(callData[0].callState, callData[0].videoState, callData[0].isHoldVideoUx)).assertTrue();
  callData[0].videoState = VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
  callData[0].callState = CallStateConst.CALL_STATUS_ACTIVE;
  expect(canShowVideoCallUi(callData[0].callState, callData[0].videoState, callData[0].isHoldVideoUx)).assertTrue();
}

let isUpgradingToVideo_test = () => {
  callData[0].callState = CallStateConst.CALL_STATUS_DIALING;
  expect(isUpgradingToVideo(callData[0])).assertFalse();
  callData[0].callState = CallStateConst.CALL_STATUS_ACTIVE;
  callData[0].videoState = VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
  callData[0].imsCallMode = ImsCallMode.CALL_MODE_AUDIO_ONLY;
  expect(isUpgradingToVideo(callData[0])).assertTrue();
}

let isSecondaryCallWaiting_test = () => {
  let result = isSecondaryCallWaiting(callData);
  expect(result).assertFalse();
  callData4[0].callState = CallStateConst.CALL_STATUS_IDLE;
  callData4[1].callState = CallStateConst.CALL_STATUS_IDLE;
  callData4[2].callState = CallStateConst.CALL_STATUS_IDLE;
  let result2 = isSecondaryCallWaiting(callData4);
  expect(result2).assertFalse();
  let result3 = isSecondaryCallWaiting(callData4, callData4[0]);
  expect(result3).assertFalse();
  callData4[1].accountId = 1;
  callData4[2].accountId = 1;
  callData4[1].callState = CallStateConst.CALL_STATUS_ACTIVE;
  callData4[2].callState = CallStateConst.CALL_STATUS_WAITING;
  let result4 = isSecondaryCallWaiting(callData4, callData4[0]);
  expect(result4).assertTrue();
}

let canMerge_test = () => {
  let result = canMerge(callData);
  expect(result).assertFalse();
  callData3[1].conferenceState = ConferenceConst.TEL_CONFERENCE_ACTIVE;
  callData3[0].callState = CallStateConst.CALL_STATUS_INCOMING;
  let result2 = canMerge(callData3);
  expect(result2).assertFalse();
  callData3[0].callState = CallStateConst.CALL_STATUS_ALERTING;
  callData3[1].callState = CallStateConst.CALL_STATUS_DIALING;
  let result3 = canMerge(callData3);
  expect(result3).assertFalse();
  callData3[0].callState = CallStateConst.CALL_STATUS_ACTIVE;
  callData3[1].callState = CallStateConst.CALL_STATUS_ACTIVE;
  let result4 = canMerge(callData3);
  expect(result4).assertFalse();
  callData3[1].callState = CallStateConst.CALL_STATUS_HOLDING;
  let result5 = canMerge(callData3);
  expect(result5).assertTrue();
}

let getWasConnectedCallCount_test = () => {
  callData3[0].callState = CallStateConst.CALL_STATUS_DIALING;
  callData3[1].callState = CallStateConst.CALL_STATUS_ACTIVE;
  callData3[1].conferenceState = ConferenceConst.TEL_CONFERENCE_ACTIVE;
  let result = getWasConnectedCallCount(callData3);
  expect(result).assertEqual(1);
}

let isIncomingVoiceSilencedCall_test = () => {
  let result = isIncomingVoiceSilencedCall(callData[0]);
  expect(result).assertFalse();
}

let isSilencedCall_test = () => {
  let result = isSilencedCall(callData[0]);
  expect(result).assertFalse();
}

let isDisconnectCall_test = () => {
  let result = isDisconnectCall(callData[0]);
  expect(result).assertFalse();
}

let getForegroundLiveCall_test = () => {
  let result = getForegroundLiveCall([]);
  expect(result === undefined).assertTrue();
}

let getForegroundLiveCall2_test = () => {
  let result = getForegroundLiveCall(callData);
  expect(result !== undefined).assertTrue();
}

let setConferenceDisconnecting_test = () => {
  let result = setConferenceDisconnecting(callData);
  expect(result === null).assertFalse();
}

let setSystemBarEnable_test = () => {
  let result = setSystemBarEnable(true);
  expect(result === null).assertFalse();
}

let setSystemBarEnable2_test = () => {
  let result = setSystemBarEnable(false);
  expect(result === null).assertFalse();
}

export function CallListHelperTest() {
  describe('CallListHelperTest', () => {
    it('CallListHelperTest_isVideoCall', 0, () => {
      isVideoCall_test();
    });
    it('CallListHelperTest_isIncomingCall', 0, () => {
      isIncomingCall_test();
    });
    it('CallListHelperTest_isActiveCall', 0, () => {
      isActiveCall_test();
    });
    it('CallListHelperTest_getForegroundCall', 0, () => {
      getForegroundCall_test();
    });
    it('CallListHelperTest_getPrimaryIncomingCall', 0, () => {
      getPrimaryIncomingCall_test();
    });
    it('CallListHelperTest_getSecondaryIncomingCall', 0, () => {
      getSecondaryIncomingCall_test();
    });
    it('CallListHelperTest_isOutgoingCall', 0, () => {
      isOutgoingCall_test();
    });
    it('CallListHelperTest_getOutgoingCall', 0, () => {
      getOutgoingCall_test();
    });
    it('CallListHelperTest_getFirstCallByState', 0, () => {
      getFirstCallByState_test();
    })
    it('CallListHelperTest_getFirstCallByStateExcludeCall', 0, () => {
      getFirstCallByStateExcludeCall_test();
    })
    it('CallListHelperTest_getVideoCall', 0, () => {
      getVideoCall_test();
    })
    it('CallListHelperTest_isOneWayVideo', 0, () => {
      isOneWayVideo_test();
    })
    it('CallListHelperTest_isVoiceCall', 0, () => {
      isVoiceCall_test();
    });
  })
}

export function CallListHelperTest2() {
  describe('CallListHelperTest2', () => {
    it('CallListHelperTest2_getActiveCallId', 0, () => {
      getActiveCallId_test();
    });
    it('CallListHelperTest2_shouldShowRbtView', 0, () => {
      shouldShowRbtView_test();
    });
    it('CallListHelperTest2_canShowVideoCallUi', 0, () => {
      canShowVideoCallUi_test();
    });
    it('CallListHelperTest2_isUpgradingToVideo', 0, () => {
      isUpgradingToVideo_test();
    });
    it('CallListHelperTest2_isSecondaryCallWaiting', 0, () => {
      isSecondaryCallWaiting_test();
    });
    it('CallListHelperTest2_canMerge', 0, () => {
      canMerge_test();
    });
    it('CallListHelperTest2_getWasConnectedCallCount', 0, () => {
      getWasConnectedCallCount_test();
    });
    it('CallListHelperTest2_isIncomingVoiceSilencedCall', 0, () => {
      isIncomingVoiceSilencedCall_test();
    });
    it('CallListHelperTest2_isSilencedCall', 0, () => {
      isSilencedCall_test();
    });
    it('CallListHelperTest2_isDisconnectCall', 0, () => {
      isDisconnectCall_test();
    });
    it('CallListHelperTest2_getForegroundLiveCall', 0, () => {
      getForegroundLiveCall_test();
    });
    it('CallListHelperTest2_getForegroundLiveCall2', 0, () => {
      getForegroundLiveCall2_test();
    });
    it('CallListHelperTest2_setConferenceDisconnecting', 0, () => {
      setConferenceDisconnecting_test();
    });
    it('CallListHelperTest2_setSystemBarEnable', 0, () => {
      setSystemBarEnable_test();
    });
    it('CallListHelperTest2_setSystemBarEnable2', 0, () => {
      setSystemBarEnable2_test();
    });
  })
}
