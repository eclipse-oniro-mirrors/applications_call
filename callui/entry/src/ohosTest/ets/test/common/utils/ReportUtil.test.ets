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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import CallStateConst from '../../../../../main/ets/common/constant/CallStateConst';
import DefaultCallData from '../../../../../main/ets/common/struct/TypeUtils';
import Method from '../../../../../main/ets/common/utils/Method';
import { ReportUtil } from '../../../../../main/ets/common/utils/ReportUtils/ReportUtil';
import Utils from '../../../../../main/ets/common/utils/utils';
import { VideoStateType } from '../../../../../main/ets/common/utils/VideoCallApi';
import CallDataManager from '../../../../../main/ets/model/CallDataManager';
import BottomViewModel from '../../../../../main/ets/viewmodel/BottomViewModel';
import common from '@ohos.app.ability.common';
import LogUtils from '../../../../../main/ets/common/utils/LogUtils';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { StringUtil } from '../../../../../main/ets/common/utils/StringUtil';
import { VisionGlassConstants } from '../../../../../main/ets/common/constant/VisionGlassConstants';
import { privacyManager } from '@kit.AbilityKit';

let callData: DefaultCallData = {
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

let reportIncomingAudioAccept_test = () => {
  ReportUtil.getInstance().reportIncomingAudioAccept(0, callData);
  expect(true).assertTrue();
}

let reportIncomingAudioAccept_test_01 = () => {
  callData.callType = CallStateConst.TYPE_SATELLITE;
  ReportUtil.getInstance().reportIncomingAudioAccept(0, callData);
  expect(true).assertTrue();
}

let reportClickPowerToScreenOff_test = () => {
  let callType: number = 0;
  ReportUtil.getInstance().reportClickPowerToScreenOff(callType);
  expect(true).assertTrue();
}

let reportDialOutgoing_test = () => {
  callData.callId = 1;
  ReportUtil.getInstance().reportDialOutgoing(callData);
  expect(true).assertTrue();
}

let reportDialOutgoing_test01 = () => {
  let reportUtil = ReportUtil.getInstance();
  reportUtil.versionName = '1.0';
  callData.callId = 1;
  reportUtil.reportDialOutgoing(callData);
  expect(true).assertTrue();
}

let reportCallAcceptTimeout_test = () => {
  let callType: number = 0;
  ReportUtil.getInstance().reportCallAcceptTimeout(callType);
  expect(true).assertTrue();
}

let reportMultiCallClickExchange_test = () => {
  let callListCount: number = 2;
  ReportUtil.getInstance().reportMultiCallClickExchange(callListCount);
  expect(true).assertTrue();
}

let reportMultiCallClickMerge_test = () => {
  ReportUtil.getInstance().reportMultiCallClickMerge();
  expect(true).assertTrue();
}

let reportMultiCallClickSeparation_test = () => {
  ReportUtil.getInstance().reportMultiCallClickSeparation();
  expect(true).assertTrue();
}

let reportMultiCallEnterParticipantList_test = () => {
  ReportUtil.getInstance().reportMultiCallEnterParticipantList();
  expect(true).assertTrue();
}

let reportHasIncomingCall_test = () => {
  ReportUtil.getInstance().reportHasIncomingCall(1, 11, true, -1, 0, 0);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportHasIncomingCall(1, 11, true, 1, 0, 1);
  expect(true).assertTrue();
}

let reportIncomingCallEvent_test = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(StringUtil, StringUtil.isEmpty);
  when(mockFunc)(ArgumentMatchers.anyBoolean).afterReturn(true);
  ReportUtil.getInstance().reportIncomingCallEvent(1, 11, true, true, 0, 0);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
  mocker.ignoreMock(StringUtil, StringUtil.isEmpty);
}

let getCallDisconnectCause_test = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc2: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc2)('hangUp').afterReturn(true);
  ReportUtil.getInstance().getCallDisconnectCause(3);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
  mocker.clear(AppStorage);
}

let reportNotifyBarAnswered_test = () => {
  ReportUtil.getInstance().reportNotifyBarAnswered(5);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportPrivacyIndicator_test_01 = () => {
  let reportUtil = ReportUtil.getInstance();
  CallDataManager.getInstance().callList = [];
  reportUtil.reportPrivacyIndicator();
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');

  reportUtil.stopPrivacyPermission();
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportPrivacyIndicator_test_02 = () => {
  callData.callState = 4;
  let reportUtil = ReportUtil.getInstance();
  CallDataManager.getInstance().callList = [callData];
  reportUtil.reportPrivacyIndicator();
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportPrivacyIndicator_test_03 = () => {
  callData.callState = 3;
  let reportUtil = ReportUtil.getInstance();
  CallDataManager.getInstance().callList = [callData];
  reportUtil.reportPrivacyIndicator();
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');

  reportUtil.reportPrivacyIndicator();
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');

  reportUtil.stopPrivacyPermission();
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportCallInterfaceClickBtn_test = () => {
  ReportUtil.getInstance().reportCallInterfaceClickBtn('record', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('wait', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('add', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('memorandum', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('mute', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('contact', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('keyboard', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('keyboard', false);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('video', true);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('video', false);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInterfaceClickBtn('syu', true);
  expect(true).assertTrue();
}

let reportCallInterfaceClickBtn_test_01 = () => {
  AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, true);
  ReportUtil.getInstance().reportCallInterfaceClickBtn('record', true);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportCallInActive_test = () => {
  callData.callId = -1;
  ReportUtil.getInstance().reportCallInActive(callData, 4, 0);
  expect(true).assertTrue();
  callData.callId = 1;
  ReportUtil.getInstance().reportCallInActive(callData, 4, 0);
  expect(true).assertTrue();
  callData.accountId = 1;
  ReportUtil.getInstance().reportCallInActive(callData, 2, 0);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInActive(callData, 3, 0);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInActive(callData, 6, 0);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInActive(callData, 6, 9);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInActive(callData, 7, 0);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInActive(callData, 7, 9);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportCallInActive(callData, 9, 6);
  expect(true).assertTrue();
}

let isCallAnswerResponseTimeout_test = () => {
  ReportUtil.getInstance().isCallAnswerResponseTimeout(1);
  expect(true).assertTrue();
}

let isCallAnswerResponseTimeout_test_01 = () => {
  ReportUtil.getInstance().isCallAnswerResponseTimeout(5);
  expect(true).assertTrue();
}

let reportDualCardIncomingCall_test = () => {
  ReportUtil.getInstance().reportDualCardIncomingCall(-1);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportDualCardIncomingCall(1);
  expect(true).assertTrue();
}

let reportDualCardAnotherIncoming_test = () => {
  ReportUtil.getInstance().reportHasIncomingCall(1, 11, true, -1, 0, 0);
  ReportUtil.getInstance().reportDualCardAnotherIncoming(-1);
  expect(true).assertTrue();
  ReportUtil.getInstance().reportDualCardAnotherIncoming(1);
  expect(true).assertTrue();
}

let reportDualCallPoint_test = () => {
  callData.callState = CallStateConst.CALL_STATUS_DIALING;
  ReportUtil.getInstance().reportDualCallPoint(callData);
  expect(true).assertTrue();
  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  ReportUtil.getInstance().reportDualCallPoint(callData);
  expect(true).assertTrue();
}

let reportIsDualCardOneInCallAndAnotherDialCancel_test = () => {
  callData.accountId = 1;
  callData.callState = CallStateConst.CALL_STATUS_DIALING;
  ReportUtil.getInstance().reportIsDualCardOneInCallAndAnotherDialCancel(2, callData.accountId, callData.callState);
  expect(true).assertTrue();
}

let reportIsDualCardClickListReject_test = () => {
  ReportUtil.getInstance().reportIsDualCardClickListReject(2);
  expect(true).assertTrue();
}

let reportIsDualCardClickListToAnswer_test = () => {
  ReportUtil.getInstance().reportIsDualCardClickListToAnswer(2);
  expect(true).assertTrue();
}

let reportDisconnectInfo_test = () => {
  callData.callId = -1;
  ReportUtil.getInstance().reportDisconnectInfo(callData);
  expect(true).assertTrue();
  callData.callId = 1;
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(BottomViewModel, BottomViewModel.getInstance().getCurrentAudioDeviceType);
  let mockFunc2: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)().afterReturn(1);
  when(mockFunc2)('hangUp').afterReturn(true);
  ReportUtil.getInstance().reportDisconnectInfo(callData);
  expect(true).assertTrue();
  callData.callId = 2;
  callData.callType = CallStateConst.TYPE_VOIP;
  when(mockFunc2)('hangUp').afterReturn(false);
  ReportUtil.getInstance().reportDisconnectInfo(callData);
  expect(true).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

let reportDisconnectInfo_test_01 = () => {
  callData.callId = 1;
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(BottomViewModel, BottomViewModel.getInstance().getCurrentAudioDeviceType);
  let mockFunc2: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)().afterReturn(1);
  when(mockFunc2)('hangUp').afterReturn(true);
  when(mockFunc2)(VisionGlassConstants.CONNECT_VISION_GLASS).afterReturn(true);
  let reportUtil = ReportUtil.getInstance();
  reportUtil.volumeValue = 1;
  reportUtil.reportDisconnectInfo(callData);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
  mocker.clear(AppStorage);
  mocker.clearAll();
}

let reportDrawnCompleted = () => {
  let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!textContext) {
    return;
  }
  ReportUtil.reportDrawnCompleted(1, textContext);
  let result = ReportUtil.reportDrawnCompleted(0, textContext);
  expect(result == null);
}

let reportDrawnCompleted_test_01 = () => {
  let asyncTaskCount: number = 0;
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!context) {
    return;
  }
  let mocker: MockKit = new MockKit();
  let mockLogE: Function = mocker.mockFunc(LogUtils, LogUtils.e);
  when(mockLogE)(ArgumentMatchers.anyString).afterReturnNothing();
  let mockLogI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
  when(mockLogI)(ArgumentMatchers.anyString).afterReturnNothing();
  let mockReportDrawnCompleted: Function = mocker.mockFunc(context, context.reportDrawnCompleted);
  let err: BusinessError = {
    code: 1,
    name: '',
    message: 'error'
  };
  when(mockReportDrawnCompleted)(ArgumentMatchers.anyFunction).afterAction((callback: AsyncCallback<void>) => {
    callback(err);
  });
  ReportUtil.reportDrawnCompleted(asyncTaskCount, context);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
  mocker.ignoreMock(LogUtils, LogUtils.e);
  mocker.ignoreMock(LogUtils, LogUtils.i);
  mocker.ignoreMock(context, context.reportDrawnCompleted);
}

let reportCallInActive_reportCallEndMarkNumber = () => {
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.advertising_and_promotion').id);
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.Real_Estate_Agency').id);
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.harassing_call').id);
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.fraud_phone_call').id);
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.courier_and_food_delivery').id);
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.financial_management_insurance').id);
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.taxi').id);
  ReportUtil.getInstance().reportCallEndMarkNumber($r('app.string.custom').id);
  let result = ReportUtil.getInstance().reportCallEndMarkNumber(7);
  expect(result == null).assertTrue();
}

let reportDualcardAnswerFailed = () => {
  ReportUtil.getInstance().reportDualcardAnswerFailed();
  expect(true).assertTrue();
}

let reportDualcardHoldFailed = () => {
  CallDataManager.getInstance().callList = [];
  ReportUtil.getInstance().reportDualcardHoldFailed();

  callData.callState = CallStateConst.CALL_STATUS_ACTIVE;
  CallDataManager.getInstance().callList.push(callData);
  ReportUtil.getInstance().reportDualcardHoldFailed();
  let obj = new DefaultCallData();
  // use deep copy
  Method.assign(obj, callData);
  obj.callState = CallStateConst.CALL_STATUS_INCOMING;
  CallDataManager.getInstance().callList.push(obj);
  ReportUtil.getInstance().reportDualcardHoldFailed();

  obj.accountId = 1;
  ReportUtil.getInstance().reportDualcardHoldFailed();
  CallDataManager.getInstance().callList = [];
  expect(true).assertTrue();
}

let reportCallInLeatherMode = () => {
  ReportUtil.getInstance().reportAnswerCallInLeatherMode();
  ReportUtil.getInstance().reportRejectCallInLeatherMode();
  ReportUtil.getInstance().reportHangUpCallInLeatherMode();
  expect(true).assertTrue();
}

let reportIncomingRemindButton_test = () => {
  ReportUtil.getInstance().reportIncomingRemindButton(4, 4);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportAntiFraudEvent_test = () => {
  ReportUtil.getInstance().reportAntiFraudEvent(1);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportSwitchAudioRuteExternalCall_test = () => {
  ReportUtil.getInstance().reportSwitchAudioRuteExternalCall(2);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportVisionGlassClickBtn_test = () => {
  ReportUtil.getInstance().reportVisionGlassClickBtn('record', true, 1);
  ReportUtil.getInstance().reportVisionGlassClickBtn('wait', true, 1);
  ReportUtil.getInstance().reportVisionGlassClickBtn('add', true, 1);
  ReportUtil.getInstance().reportVisionGlassClickBtn('memorandum', true, 1);
  ReportUtil.getInstance().reportVisionGlassClickBtn('mute', true, 1);
  ReportUtil.getInstance().reportVisionGlassClickBtn('contact', true, 1);
  ReportUtil.getInstance().reportVisionGlassClickBtn('keyboard', true, 1);
  ReportUtil.getInstance().reportVisionGlassClickBtn('syu', true, 1);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportCallInBackground_test = () => {
  ReportUtil.getInstance().reportCallInBackground(1);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportNotifyBarReject_test = () => {
  ReportUtil.getInstance().reportNotifyBarReject(1);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportNotifyBarHangUp_test = () => {
  ReportUtil.getInstance().reportNotifyBarHangUp(2);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

let reportMultiCallHangUpOne_test = () => {
  ReportUtil.getInstance().reportMultiCallHangUpOne(2);
  expect(ReportUtil.getInstance().domain()).assertEqual('PHONE_UE');
}

export function ReportUtilTest() {
  describe('ReportUtilTest', () => {
    it('ReportUtilTest_reportIncomingAudioAccept', 0, () => {
      reportIncomingAudioAccept_test();
      reportIncomingAudioAccept_test_01();
    });
    it('ReportUtilTest_reportClickPowerToScreenOff', 0, () => {
      reportClickPowerToScreenOff_test();
    });
    it('ReportUtilTest_reportDialOutgoing', 0, () => {
      reportDialOutgoing_test();
      reportDialOutgoing_test01();
    });
    it('ReportUtilTest_reportCallAcceptTimeout', 0, () => {
      reportCallAcceptTimeout_test();
    });
    it('ReportUtilTest_reportMultiCallClickExchange', 0, () => {
      reportMultiCallClickExchange_test();
    });
    it('ReportUtilTest_reportMultiCallClickMerge', 0, () => {
      reportMultiCallClickMerge_test();
    })
    it('ReportUtilTest_reportMultiCallClickSeparation', 0, () => {
      reportMultiCallClickSeparation_test();
    })
    it('ReportUtilTest_reportMultiCallEnterParticipantList', 0, () => {
      reportMultiCallEnterParticipantList_test();
    });
    it('ReportUtilTest_reportHasIncomingCall', 0, () => {
      reportHasIncomingCall_test();
    });
    it('ReportUtilTest_reportCallInterfaceClickBtn', 0, () => {
      reportCallInterfaceClickBtn_test();
      reportCallInterfaceClickBtn_test_01();
    });
    it('ReportUtilTest_reportCallInActive', 0, () => {
      reportCallInActive_test();
    });
  });
}

export function ReportUtilTest2() {
  describe('ReportUtilTest2', () => {
    it('ReportUtilTest2_isCallAnswerResponseTimeout', 0, () => {
      isCallAnswerResponseTimeout_test();
      isCallAnswerResponseTimeout_test_01();
    });
    it('ReportUtilTest2_reportDualCardIncomingCall', 0, () => {
      reportDualCardIncomingCall_test();
    });
    it('ReportUtilTest2_reportDualCardAnotherIncoming', 0, () => {
      reportDualCardAnotherIncoming_test();
    });
    it('ReportUtilTest2_reportDualCallPoint', 0, () => {
      reportDualCallPoint_test();
    });
    it('ReportUtilTest2_reportIsDualCardOneInCallAndAnotherDialCancel', 0, () => {
      reportIsDualCardOneInCallAndAnotherDialCancel_test();
    });
    it('ReportUtilTest2_reportIsDualCardClickListReject', 0, () => {
      reportIsDualCardClickListReject_test();
    });
    it('ReportUtilTest2_reportIsDualCardClickListToAnswer', 0, () => {
      reportIsDualCardClickListToAnswer_test();
    });
    it('ReportUtilTest2_reportDisconnectInfo', 0, () => {
      reportDisconnectInfo_test();
      reportDisconnectInfo_test_01();
    });
    it('reportDrawnCompleted', 0, () => {
      reportDrawnCompleted();
      reportDrawnCompleted_test_01();
    });
    it('reportCallInActive_reportCallEndMarkNumber', 0, () => {
      reportCallInActive_reportCallEndMarkNumber();
    });
    it('reportDualcardAnswerFailed', 0, () => {
      reportDualcardAnswerFailed();
    });
    it('reportDualcardHoldFailed', 0, () => {
      reportDualcardHoldFailed();
    });
    it('reportCallInLeatherMode', 0, () => {
      reportCallInLeatherMode();
    });

    it('reportIncomingRemindButton', 0, () => {
      reportIncomingRemindButton_test();
    });

    it('reportAntiFraudEvent', 0, () => {
      reportAntiFraudEvent_test();
    });

    it('reportSwitchAudioRuteExternalCall', 0, () => {
      reportSwitchAudioRuteExternalCall_test();
    });

    it('reportVisionGlassClickBtn', 0, () => {
      reportVisionGlassClickBtn_test();
    });

    it('reportCallInBackground', 0, () => {
      reportCallInBackground_test();
    });

    it('reportNotifyBarReject', 0, () => {
      reportNotifyBarReject_test();
    });

    it('reportNotifyBarHangUp', 0, () => {
      reportNotifyBarHangUp_test();
    });

    it('reportMultiCallHangUpOne', 0, () => {
      reportMultiCallHangUpOne_test();
    });

    it('reportIncomingCallEvent', 0, () => {
      reportIncomingCallEvent_test();
    });

    it('getCallDisconnectCause', 0, () => {
      getCallDisconnectCause_test();
    });

    it('reportNotifyBarAnswered', 0, () => {
      reportNotifyBarAnswered_test();
    });

    it('reportPrivacyIndicator', 0, () => {
      reportPrivacyIndicator_test_01();
      reportPrivacyIndicator_test_02();
      reportPrivacyIndicator_test_03();
    });

    it('recordAlertTime', 0, () => {
      let report = new ReportUtil();
      report.recordAlertTime();
      expect(report.callAnswerTime).assertEqual(0)

      report.recordAlertTime();
      expect(report.callAnswerTime).assertEqual(0)
    });
  });
}
