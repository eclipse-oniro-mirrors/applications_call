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
import { describe, it, expect, MockKit, when } from '@ohos/hypium';
import CallStateConst from '../../../main/ets/common/constant/CallStateConst';
import { remindObj } from '../../../main/ets/common/dialog/RemindObj';
import DefaultCallData from '../../../main/ets/common/struct/TypeUtils';
import { VideoStateType } from '../../../main/ets/common/utils/VideoCallApi';
import CallServiceProxy from '../../../main/ets/model/CallServiceProxy';
import IncomingComVM from '../../../main/ets/viewmodel/IncomingComVM';

let IncomingComVMTest_getRemindList = () => {
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.getRemindList();
  expect(mIncomingVM.remindList.length).assertEqual(3)
}

let IncomingComVMTest_hasSecondaryIncoming = () => {
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  let hasSecondary = mIncomingVM.hasSecondaryIncoming();
  expect(hasSecondary).assertEqual(false);
}

let IncomingComVMTest_getDsdaConflictsLabel_callList_0 = () => {
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.callList = [];
  let label = mIncomingVM.getDsdaConflictsLabel();
  expect(label != undefined).assertEqual(true);
}

let IncomingComVMTest_getDsdaConflictsLabel_callList_1_simCount_undefined = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall: DefaultCallData = new DefaultCallData();
  let testActiveCall: DefaultCallData = new DefaultCallData();
  let list: Array<DefaultCallData> = [testIncomingCall, testActiveCall];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.callList = list;
  AppStorage.delete('simCount');
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  AppStorage.setOrCreate('simCount', 1);
  let label2 = mIncomingVM.getDsdaConflictsLabel();
  expect(label2 != undefined).assertEqual(true);
  AppStorage.setOrCreate('simCount', 2);
  let label3 = mIncomingVM.getDsdaConflictsLabel();
  expect(label3 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_callList_Incoming = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall: DefaultCallData = new DefaultCallData();
  testIncomingCall.callState = 4;
  let testActiveCall: DefaultCallData = new DefaultCallData();
  testActiveCall.callState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall, testActiveCall];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  mIncomingVM.primaryIncomingCall = testActiveCall;
  let label2 = mIncomingVM.getDsdaConflictsLabel();
  expect(label2 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_callList_Outgoing_actualCallCount1 = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall: DefaultCallData = new DefaultCallData();
  testIncomingCall.callState = 4;
  let testOutgoingCall: DefaultCallData = new DefaultCallData();
  testOutgoingCall.callState = 2;
  testOutgoingCall.videoState = VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
  let testActiveCall: DefaultCallData = new DefaultCallData();
  testActiveCall.callState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall, testOutgoingCall];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_callList_Outgoing_actualCallCount2 = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let testOutgoingCall1: DefaultCallData = new DefaultCallData();
  testOutgoingCall1.callId = 26;
  testOutgoingCall1.callState = 2;
  testOutgoingCall1.conferenceState = 0;
  testOutgoingCall1.videoState = VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
  let testOutgoingCall2: DefaultCallData = new DefaultCallData();
  testOutgoingCall2.callId = 27;
  testOutgoingCall2.callState = 2;
  testOutgoingCall2.conferenceState = 0;
  testOutgoingCall2.videoState = VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testActiveCall2: DefaultCallData = new DefaultCallData();
  testActiveCall2.callId = 29;
  testActiveCall2.callState = 0;
  testActiveCall2.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1, testIncomingCall2,
    testOutgoingCall1, testOutgoingCall2, testActiveCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testOutgoingCall1;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_onAnswer_ing_no_video = () => {
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testAnswerCall1: DefaultCallData = new DefaultCallData();
  testAnswerCall1.callId = 24;
  testAnswerCall1.callState = 9;
  testAnswerCall1.conferenceState = 0;
  let list: Array<DefaultCallData> = [testAnswerCall1, testActiveCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.callList = list;
  mIncomingVM.onAnswer(false);
  expect(mIncomingVM.callList.length).assertEqual(2);
}

let IncomingComVMTest_onAnswer_no_video_callList_2 = () => {
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1, testActiveCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.callList = list;
  mIncomingVM.onAnswer(false);
  expect(mIncomingVM.callList.length).assertEqual(2);
}

let IncomingComVMTest_onAnswer_video_callList_1 = () => {
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.callList = list;
  mIncomingVM.onAnswer(true);
  expect(mIncomingVM.callList.length).assertEqual(1);
}

let IncomingComVMTest_onAnswer_no_video_callList_1 = () => {
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  testIncomingCall1.videoState = VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
  testIncomingCall1.crsType = 2;
  let list: Array<DefaultCallData> = [testIncomingCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall1;
  mIncomingVM.callList = list;
  mIncomingVM.onAnswer(false);
  expect(mIncomingVM.callList.length).assertEqual(1);
}

let IncomingComVMTest_onReject_IncomingCall = () => {
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  let list: Array<DefaultCallData> = [testIncomingCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall1;
  mIncomingVM.callList = list;
  mIncomingVM.onReject();
  expect(mIncomingVM.callList.length).assertEqual(1);
}

let IncomingComVMTest_onReject_WaitingCall_Call_2 = () => {
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let waitingCal: DefaultCallData = new DefaultCallData();
  waitingCal.callId = 25;
  waitingCal.callState = 5;
  let list: Array<DefaultCallData> = [waitingCal, testActiveCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = waitingCal;
  mIncomingVM.callList = list;
  mIncomingVM.onReject();
  expect(mIncomingVM.callList.length).assertEqual(2);
}

let IncomingComVMTest_onReject_WaitingCall_Call_1 = () => {
  let waitingCal: DefaultCallData = new DefaultCallData();
  waitingCal.callId = 25;
  waitingCal.callState = 5;
  let list: Array<DefaultCallData> = [waitingCal];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = waitingCal;
  mIncomingVM.callList = list;
  mIncomingVM.onReject();
  expect(mIncomingVM.callList.length).assertEqual(1);
}

let IncomingComVMTest_getDsdaConflictsLabel_TwoWayCall = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1, testIncomingCall2];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall1;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_TwoWayCall_Secondary_Undefined = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  testIncomingCall1.videoState = 3;
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  testIncomingCall2.crsType = 2;
  let list: Array<DefaultCallData> = [testIncomingCall1, testIncomingCall2];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall1;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testActiveCall2: DefaultCallData = new DefaultCallData();
  testActiveCall2.callId = 29;
  testActiveCall2.callState = 0;
  testActiveCall2.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1, testIncomingCall2, testActiveCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall1;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_VideoCall = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 24;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  testIncomingCall1.videoState = 3;
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testActiveCall2: DefaultCallData = new DefaultCallData();
  testActiveCall2.callId = 29;
  testActiveCall2.callState = 0;
  testActiveCall2.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1, testIncomingCall2, testActiveCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall1;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_OutgoingCall = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testOutgoingCall1: DefaultCallData = new DefaultCallData();
  testOutgoingCall1.callId = 26;
  testOutgoingCall1.callState = 2;
  testOutgoingCall1.conferenceState = 0;
  testOutgoingCall1.videoState = 3;
  let list: Array<DefaultCallData> = [testIncomingCall2, testActiveCall1, testOutgoingCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall2;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_GetVideoCall = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  testActiveCall1.videoState = 3;
  let list: Array<DefaultCallData> = [testIncomingCall2, testActiveCall1];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall2;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_Count4 = () => {
  let simCount: number | undefined = AppStorage.get('simCount');
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 26;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testActiveCall2: DefaultCallData = new DefaultCallData();
  testActiveCall2.callId = 29;
  testActiveCall2.callState = 0;
  testActiveCall2.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1, testIncomingCall2, testActiveCall1, testActiveCall2];
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  mIncomingVM.primaryIncomingCall = testIncomingCall2;
  mIncomingVM.callList = list;
  AppStorage.setOrCreate('simCount', 2);
  let label1 = mIncomingVM.getDsdaConflictsLabel();
  expect(label1 != undefined).assertEqual(true);
  if (simCount === undefined) {
    AppStorage.delete('simCount');
  } else {
    AppStorage.setOrCreate('simCount', simCount);
  }
}

let IncomingComVMTest_aboutToAppear = () => {
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  let result = mIncomingVM.aboutToAppear();
  expect(result === null).assertFalse();
}

let sendRemindTest = () => {
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  let obj: remindObj = {
    id: 0,
    msg: $r('app.string.module_test_desc'),
    value: 0
  };
  let result =mIncomingVM.sendRemind(obj);
  expect(result == null).assertTrue();
}

let IncomingComVMTest_initData = () => {
  let mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  let callData:DefaultCallData = new DefaultCallData();
  let testIncomingCall1: DefaultCallData = new DefaultCallData();
  testIncomingCall1.callId = 26;
  testIncomingCall1.callState = 4;
  testIncomingCall1.conferenceState = 0;
  let testIncomingCall2: DefaultCallData = new DefaultCallData();
  testIncomingCall2.callId = 25;
  testIncomingCall2.callState = 4;
  testIncomingCall2.conferenceState = 0;
  let testActiveCall1: DefaultCallData = new DefaultCallData();
  testActiveCall1.callId = 28;
  testActiveCall1.callState = 0;
  testActiveCall1.conferenceState = 0;
  let testActiveCall2: DefaultCallData = new DefaultCallData();
  testActiveCall2.callId = 29;
  testActiveCall2.callState = 0;
  testActiveCall2.conferenceState = 0;
  let list: Array<DefaultCallData> = [testIncomingCall1, testIncomingCall2, testActiveCall1, testActiveCall2];
  let result = mIncomingVM.initData(callData,list);
  expect(result === null).assertFalse();
}

export default function IncomingComVMTest() {
  describe('IncomingComVMTest', () => {
    it('getRemindList', 0, () => {
      IncomingComVMTest_getRemindList();
    })
    it('hasSecondaryIncoming', 0, () => {
      IncomingComVMTest_hasSecondaryIncoming();
    })
    it('getDsdaConflictsLabel_callList_0', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_callList_0();
    })
    it('getDsdaConflictsLabel_callList_1_simCount_undefined', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_callList_1_simCount_undefined();
    })
    it('getDsdaConflictsLabel_callList_Incoming', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_callList_Incoming();
    })
    it('getDsdaConflictsLabel_callList_Outgoing_actualCallCount1', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_callList_Outgoing_actualCallCount1();
    })
    it('getDsdaConflictsLabel_callList_Outgoing_actualCallCount2', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_callList_Outgoing_actualCallCount2();
    })
    it('onAnswer_ing_no_video', 0, () => {
      IncomingComVMTest_onAnswer_ing_no_video();
    })
    it('onAnswer_no_video_callList_2', 0, () => {
      IncomingComVMTest_onAnswer_no_video_callList_2();
    })
    it('onAnswer_video_callList_1', 0, () => {
      IncomingComVMTest_onAnswer_video_callList_1();
    })
    it('onAnswer_no_video_callList_1', 0, () => {
      IncomingComVMTest_onAnswer_no_video_callList_1();
    })
    it('onReject_IncomingCall', 0, () => {
      IncomingComVMTest_onReject_IncomingCall();
    })
    it('onReject_WaitingCall_Call_2', 0, () => {
      IncomingComVMTest_onReject_WaitingCall_Call_2();
    })
    it('onReject_WaitingCall_Call_1', 0, () => {
      IncomingComVMTest_onReject_WaitingCall_Call_1();
    })
  })
}

export function IncomingComVMTest2() {
  describe('IncomingComVMTest2', () => {
    it('getDsdaConflictsLabel_TwoWayCall', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_TwoWayCall();
    })
    it('getDsdaConflictsLabel_TwoWayCall_Secondary_Undefined', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_TwoWayCall_Secondary_Undefined();
    })
    it('getDsdaConflictsLabel_ThreeWayCall', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall();
    })
    it('getDsdaConflictsLabel_ThreeWayCall_OutgoingCall', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_OutgoingCall();
    })
    it('getDsdaConflictsLabel_ThreeWayCall_VideoCall', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_VideoCall();
    })
    it('getDsdaConflictsLabel_ThreeWayCall_GetVideoCall', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_GetVideoCall();
    })
    it('getDsdaConflictsLabel_ThreeWayCall_Count4', 0, () => {
      IncomingComVMTest_getDsdaConflictsLabel_ThreeWayCall_Count4();
    })
    it('getDsdaConflictsLabel_aboutToAppear', 0, () => {
      IncomingComVMTest_aboutToAppear();
    })
    it('getDsdaConflictsLabel_initData', 0, () => {
      IncomingComVMTest_initData();
    })

    it('sendRemind', 0, () => {
      sendRemindTest();
    })




  })
}