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
import CallManagerService from '../../../../main/ets/ServiceAbility/CallManagerService';
import common from '@ohos.app.ability.common';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import * as Constants from '../../../../main/ets/common/utils/Constants';
import { sleep } from '../Utils';
import CallStateConst from '../../../../main/ets/common/constant/CallStateConst';
import CallDataManager from '../../../../main/ets/model/CallDataManager';
import DefaultCallData, { VoipCallAttribute } from '../../../../main/ets/common/struct/TypeUtils';
import { CallEventUtil } from '../../../../main/ets/common/utils/CallEventUtil';
import commonEventManager from '@ohos.commonEventManager';
import call from '@ohos.telephony.call';
import Recording from '../../../../main/ets/common/utils/Recording';
import { CallListStruct } from '../../../../main/ets/common/struct/RecordingStruct';

const mCallManagerService = CallManagerService.getInstance();
const mCallDataManager = CallDataManager.getInstance();
const CallManagerServTest_init_01 = () => {
  let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
    .getValue<common.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
  mCallManagerService.addNotifiesSubscriber();
  expect(serviceContext !== null).assertTrue();
}

const CallManagerServTest_onAction_all = () => {
  mCallManagerService.onAction(CallStateConst.TEXT_INCOMING_CALL_REJECT, 10003);
  sleep(1000);
  mCallManagerService.onAction(CallStateConst.TEXT_INCOMING_CALL_REJECT, 10004);
  sleep(1000);
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(mCallDataManager, mCallDataManager.getForegroundCall);
  let callData = new DefaultCallData();
  when(mockFunc)(ArgumentMatchers.any).afterReturn(callData);
  let mockFunc1: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc1)('isSuperPrivacy').afterReturn(true);
  mCallManagerService.onAction(CallStateConst.TEXT_INCOMING_CALL_ANSWER_VIDEO, 10003);
  sleep(1000);
  mCallManagerService.onAction(CallStateConst.TEXT_IN_CALL_MUTE, 10003);
  sleep(1000);
  mCallManagerService.onAction(CallStateConst.TEXT_IN_CALL_UN_MUTE, 10003);
  sleep(1000);
  mCallManagerService.onAction(CallStateConst.TEXT_IN_CALL_AUDIO_SPEAKER, 10003);
  sleep(1000);
  mCallManagerService.onAction(CallStateConst.TEXT_IN_CALL_UN_HOLD_ON, 10003);
  sleep(1000);
  mCallManagerService.onAction('test', 10003);
  expect(callData !== undefined).assertTrue();
  mocker.clear(mCallDataManager);
  mocker.clear(AppStorage);
  mocker.clearAll();
}

const getCallData_Test_01 = () => {
  let callData = new DefaultCallData();
  callData.callState = CallStateConst.callStateObj.CALL_STATUS_ANSWER;
  sleep(1000);
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('hangUp').afterReturn(true);
  when(mockFunc)('recorderFirstInit').afterReturn(true);
  when(mockFunc)('recorderStatus').afterReturn(true);
  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  mCallManagerService.getCallData(callData);
  sleep(1000);
  expect(callData.callState === 4).assertTrue();

  callData.callState = CallStateConst.CALL_STATUS_ACTIVE;
  mCallManagerService.getCallData(callData);
  expect(callData.callState).assertEqual(0);

  callData.callState = CallStateConst.CALL_STATUS_ANSWER;
  callData.callType = CallStateConst.TYPE_VOIP;
  mCallManagerService.getCallData(callData);
  mCallManagerService.removeCoverModeChange();
  mCallManagerService.unsubscribe();
  expect(callData.callType).assertEqual(4);

  mocker.clear(AppStorage);
}

const getCallData_Test_02 = () => {
  let callData = new DefaultCallData();
  let mocker: MockKit = new MockKit();
  let mockFunc2: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc2)('recorderStatus').afterReturn(false);
  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  mCallManagerService.getCallData(callData);
  sleep(1000);
  expect(callData.callState === 4).assertTrue();
  mocker.clear(AppStorage);
}

const getCallData_Test_03 = () => {
  let callData = new DefaultCallData();
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('recorderFirstInit').afterReturn(false);
  when(mockFunc)('recorderStatus').afterReturn(true);
  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  mCallManagerService.getCallData(callData);
  sleep(1000);
  expect(callData.callState === 4).assertTrue();
  mocker.clear(AppStorage);
}
const getCallData_Test_04 = () => {
  let callData = new DefaultCallData();
  let mocker: MockKit = new MockKit();
  let mockFunc1: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc1)('recorderFirstInit').afterReturn(true);
  callData.callState = CallStateConst.CALL_STATUS_WAITING;
  mCallManagerService.getCallData(callData);
  callData.callState = CallStateConst.CALL_STATUS_DIALING;
  mCallManagerService.getCallData(callData);
  sleep(1000);
  expect(callData.callState === 2).assertTrue();
  mocker.clear(AppStorage);
}

const getEventOptionsTest_01 = () => {
  let option = CallEventUtil.getEventOptions(CallEventUtil.EVENT_SUCCESS, '', '');
  expect(option.subscriberPermissions?.length ?? 0).assertEqual(1);
}

const getEventOptionsTest_02 = () => {
  let option = CallEventUtil.getEventOptions(CallEventUtil.EVENT_SUCCESS, '', '');
  expect(option.isOrdered).assertEqual(false);
  expect(option.isSticky).assertEqual(false);
}

const generateWantAgentTest_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.callType = CallStateConst.TYPE_VOIP;
  callData.voipCallAttribute = new VoipCallAttribute();
  callData.voipCallAttribute.extensionId = '1';
  let result: Want = CallManagerService.getInstance().generateWantAgent(callData);
  expect(result.abilityName).assertEqual(Constants.CALL_ABILITY_NAME_VOIP);
}

const generateWantAgentTest_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.callType = CallStateConst.TYPE_VOIP;
  callData.voipCallAttribute = new VoipCallAttribute();
  callData.voipCallAttribute.extensionId = '';
  callData.voipCallAttribute.abilityName = 'abilityName';
  let result: Want = CallManagerService.getInstance().generateWantAgent(callData);
  expect(result.abilityName).assertEqual('abilityName');
}

const handleCallVibration_01 = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc1: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc1)('hangup').afterReturn(false);
  let callData: DefaultCallData = new DefaultCallData();
  callData.callType = CallStateConst.CALL_STATUS_DISCONNECTED;
  let result = mCallManagerService.handleCallVibration(callData, 0, 6);
  expect(result == null).assertTrue();
  sleep(1000);
  result = mCallManagerService.handleCallVibration(callData, 2, 0);
  expect(result == null).assertTrue();
  mocker.clear(AppStorage);
}
let callManagerService = CallManagerService.getInstance()
let screenOnEventManagerTest_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.videoState = call.VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
  CallManagerService.getInstance().getCallData(callData);
  let mocker: MockKit = new MockKit();
  let mockFunc = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('onPageShow').afterReturn(true);
  when(mockFunc)('cameraState').afterReturn(0);
  let a = callManagerService.screenOnEventManager();
  mocker.ignoreMock(AppStorage, AppStorage.get);
  let mockFunc1 = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc1)('cameraState').afterReturn(1);
  callManagerService.screenOnEventManager();
  mocker.ignoreMock(AppStorage, AppStorage.get);
  callManagerService.screenOnEventManager();
  expect(a == null).assertTrue();
}
let screenOffEventManagerTest_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  CallManagerService.getInstance().getCallData(callData);
  let a = callManagerService.screenOffEventManager();
  expect(a == null).assertTrue();
}
let screenOffEventManagerTest_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  callData.videoState = call.VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
  CallManagerService.getInstance().getCallData(callData);
  let a = callManagerService.screenOffEventManager();
  expect(a == null).assertTrue();
}

let screenOffEventManagerTest_03 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.callState = CallStateConst.CALL_STATUS_INCOMING;
  callData.callType = CallStateConst.TYPE_VOIP;
  CallManagerService.getInstance().getCallData(callData);
  let a = callManagerService.screenOffEventManager();
  expect(a == null).assertTrue();
}

let audioChangeTest = () => {
  mCallManagerService.registerAudioChange();
  let a = mCallManagerService.unRegisterAudioChange();
  expect(a == null).assertTrue();
}
let onActionTest = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.callType = 4;
  let callDataManager = CallDataManager.getInstance();
  let mocker: MockKit = new MockKit();
  let mockFunc = mocker.mockFunc(callDataManager, callDataManager.getForegroundCall);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(callData);
  let callServiceManager = CallManagerService.getInstance();
  if (callData.voipCallAttribute) {
    callData.voipCallAttribute.hasMicPermission = false
  }
  callServiceManager.onAction(CallStateConst.TEXT_INCOMING_CALL_ANSWER, 0);
  callServiceManager.onAction(CallStateConst.TEXT_INCOMING_CALL_ANSWER, 1);
  callServiceManager.onAction(CallStateConst.TEXT_INCOMING_CALL_ANSWER_VIDEO, 0);
  callServiceManager.onAction(CallStateConst.TEXT_IN_CALL_UN_MUTE, 0);
  callServiceManager.onAction(CallStateConst.TEXT_IN_CALL_AUDIO_SPEAKER, 0);
  callServiceManager.onAction(CallStateConst.TEXT_IN_CALL_UN_HOLD_ON, 0);
  let result = callServiceManager.onAction('test', 0);
  expect(result == null).assertTrue();
  mocker.ignoreMock(callDataManager, callDataManager.getForegroundCall);
  mocker.clearAll();
}
let autoRecordTest = () => {
  let callData = new DefaultCallData();
  callData.callType = CallStateConst.TYPE_VOIP;
  let callServiceManager = CallManagerService.getInstance();
  callServiceManager.autoRecord(callData, 1);
  callData.callType = 1;
  let mocker: MockKit = new MockKit();
  let mockFunc = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('in_callAssistant').afterReturn(true);
  callServiceManager.autoRecord(callData, 1);
  mocker.ignoreMock(AppStorage, AppStorage.get);
  callData.callState = CallStateConst.CALL_STATUS_ACTIVE;
  let mockFunc1 = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc1)('recorderFirstInit').afterReturn(false);
  let recording = Recording.getInstance();
  let mockFunc2 = mocker.mockFunc(recording, recording.recordingGetIsError);
  when(mockFunc2)(ArgumentMatchers.any)
    .afterReturn(new Promise<string>((resolve: Function, reject: Function) => {
      resolve(true);
    }));
  callServiceManager.autoRecord(callData, 1);
  when(mockFunc2)(ArgumentMatchers.any)
    .afterReturn(new Promise<string>((resolve: Function, reject: Function) => {
      resolve(false);
    }));
  callServiceManager.autoRecord(callData, 1);
  when(mockFunc1)('recorderFirstInit').afterReturn(true);
  callServiceManager.autoRecord(callData, 1);
  when(mockFunc1)('recorderStatus').afterReturn('disabled');
  callServiceManager.autoRecord(callData, 1);
  when(mockFunc1)('recorderStatus').afterReturn('start');
  callData.callState = CallStateConst.CALL_STATUS_HOLDING;
  callServiceManager.autoRecord(callData, 0);
  callData.callState = CallStateConst.CALL_STATUS_DISCONNECTED;
  callData.callId = -1;
  callServiceManager.autoRecord(callData, 0);
  callData.callState = CallStateConst.CALL_STATUS_ACTIVE;
  callServiceManager.autoRecord(callData, 0);
  callData.callId = 1;
  callServiceManager.autoRecord(callData, 0);
  expect(callData.callState).assertEqual(0);
  mocker.clear(AppStorage);
  mocker.clear(recording);
}
let autoStartRecordTest = () => {
  let callServiceManager = CallManagerService.getInstance();
  let callData = new DefaultCallData();
  let mocker: MockKit = new MockKit();
  let mockFunc = mocker.mockFunc(callServiceManager, callServiceManager.getCallCount);
  let callCountResult: CallListStruct = { callCount: 2, };
  when(mockFunc)(ArgumentMatchers.any).afterReturn(callCountResult);
  callServiceManager.autoStartRecord(callData, 3);
  callServiceManager.autoStartRecord(callData, 2);
  callServiceManager.autoStartRecord(callData, 4);
  callServiceManager.autoStartRecord(callData, 5);
  callCountResult.callCount = 0;
  when(mockFunc)(ArgumentMatchers.any).afterReturn(callCountResult);
  callServiceManager.autoStartRecord(callData, 5);
  let mockFunc1 = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc1)('recorderStatus').afterReturn('start');
  let result = callServiceManager.autoStartRecord(callData, 5);
  mocker.clear(AppStorage);
  mocker.clear(callServiceManager);
  expect(result == null).assertTrue();
}

let btnclickAgentTest = () => {
  let callId:number = 1 ;
  let btnType: string = "test";
  let callServiceManager = CallManagerService.getInstance();
  let result = callServiceManager.btnclickAgent(callId,btnType);
  expect(result == null).assertTrue();
}

let getMapObjTest = () => {
  let callServiceManager = CallManagerService.getInstance();
  callServiceManager.getMapObj(CallStateConst.TEXT_INCOMING_CALL_REJECT, 1);
  callServiceManager.getMapObj(CallStateConst.TEXT_INCOMING_CALL_ANSWER, 1);
  callServiceManager.getMapObj(CallStateConst.TEXT_IN_CALL_HANG_UP, 1);
  let result = callServiceManager.getMapObj('test', 1);
  expect(result == null).assertTrue();
}

let updateAudioForVoipCallTest = () => {
  let callData: DefaultCallData = new DefaultCallData();
  let callServiceManager = CallManagerService.getInstance();
  let result = callServiceManager.updateAudioForVoipCall(callData);
  expect(result == null).assertTrue();
}

let getForegroundVoipCallTest = () => {
  let callServiceManager = CallManagerService.getInstance();
  let result = callServiceManager.getForegroundVoipCall();
  expect(result == null).assertFalse();
}

let updateBannerNotificationTest = () => {
  let callServiceManager = CallManagerService.getInstance();
  let result = callServiceManager.updateBannerNotification(false);
  expect(result == null).assertTrue();
}

export default function CallManagerService_Test() {
  describe('CallManagerServTest', () => {
    it('CallManagerServTest_test_init', 0, () => {
      CallManagerServTest_init_01();
      CallManagerServTest_onAction_all();
      getCallData_Test_01();
      getCallData_Test_02();
      getCallData_Test_03();
      getCallData_Test_04();
    })
    it('getEventOptionsTest_01', 0, () => {
      getEventOptionsTest_01();
    })
    it('getEventOptionsTest_02', 0, () => {
      getEventOptionsTest_02();
    })
    it('generateWantAgentTest_01', 0, () => {
      generateWantAgentTest_01();
    })
    it('generateWantAgentTest_02', 0, () => {
      generateWantAgentTest_02();
    })
    it('handleCallVibration_01', 0, async () => {
      handleCallVibration_01();
    })
    it('screenOnEventManagerTest_02', 0, () => {
      screenOnEventManagerTest_02();
    })
    it('screenOffEventManagerTest_01', 0, () => {
      screenOffEventManagerTest_01();
    })
    it('screenOffEventManagerTest_02', 0, () => {
      screenOffEventManagerTest_02();
    })
    it('screenOffEventManagerTest_03', 0, () => {
      screenOffEventManagerTest_03();
    })
    it('audioChangeTset', 0, () => {
      audioChangeTest();
    })
    it('onActionTest', 0, () => {
      onActionTest();
    })
    it('autoRecordTest', 0, () => {
      autoRecordTest();
    })
    it('autoStartRecordTest', 0, () => {
      autoStartRecordTest();
    })
    it('btnclickAgentTest', 0, () => {
      btnclickAgentTest();
    })
    it('getMapObjTest', 0, () => {
      getMapObjTest();
    })
    it('updateAudioForVoipCallTest', 0, () => {
      updateAudioForVoipCallTest();
    })
    it('getForegroundVoipCallTest', 0, () => {
      getForegroundVoipCallTest();
    })
    it('updateBannerNotificationTest', 0, () => {
      updateBannerNotificationTest();
    })
    it('addRegisterListenerTest', 0, () => {
      let callData: DefaultCallData = new DefaultCallData();
      mCallManagerService.addCoverModeChange();
      expect(callData.accountId).assertEqual(-1)
    })
    it('init', 0, () => {
      let callData: DefaultCallData = new DefaultCallData();
      let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
        .getValue<common.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
      mCallManagerService.init(serviceContext);
      expect(callData.accountId).assertEqual(-1)
    })
  })
}
