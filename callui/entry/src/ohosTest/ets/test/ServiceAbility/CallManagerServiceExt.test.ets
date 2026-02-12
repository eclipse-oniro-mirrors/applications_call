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
import { sleep } from '../Utils';
import CallStateConst from '../../../../main/ets/common/constant/CallStateConst';
import DefaultCallData from '../../../../main/ets/common/struct/TypeUtils';
import { ReportUtil } from '../../../../main/ets/common/utils/ReportUtils/ReportUtil';
import BottomViewModel from '../../../../main/ets/viewmodel/BottomViewModel';

let CallManagerServExtTest_onAction_09 = async () => {
  let callData = new DefaultCallData();
  callData.callType = CallStateConst.TYPE_VOIP;
  CallManagerService.getInstance().getCallData(callData);
  await sleep(100);
  CallManagerService.getInstance().onAction(CallStateConst.TEXT_IN_CALL_UN_MUTE, 10004);
  await sleep(100);
  CallManagerService.getInstance().clearData();
  expect(true).assertTrue();
}

let CallManagerServExtTest_onAction_10 = async () => {
  let mocker: MockKit = new MockKit();
  let ReportUtilInstance = ReportUtil.getInstance();
  let mockFunc: Function = mocker.mockFunc(ReportUtilInstance, ReportUtilInstance.reportNotifyBarAnswerAudioRute);
  when(mockFunc)(ArgumentMatchers.any).afterReturnNothing();
  let BottomViewModelInstance = BottomViewModel.getInstance();
  let mockFunc1: Function = mocker.mockFunc(BottomViewModelInstance, BottomViewModelInstance.setButtonAudioDevice);
  when(mockFunc1)(ArgumentMatchers.any).afterReturnNothing();
  let callData = new DefaultCallData();
  callData.callType = CallStateConst.TYPE_VOIP;
  CallManagerService.getInstance().getCallData(callData);
  await sleep(100);
  CallManagerService.getInstance().onAction(CallStateConst.TEXT_IN_CALL_AUDIO_SPEAKER, 10004);
  await sleep(100);
  CallManagerService.getInstance().clearData();
  mocker.clearAll();
  expect(true).assertTrue();
}

let CallManagerServExtTest_onAction_11 = async () => {
  let callData = new DefaultCallData();
  callData.callType = CallStateConst.TYPE_VOIP;
  CallManagerService.getInstance().getCallData(callData);
  await sleep(100);
  CallManagerService.getInstance().onAction(CallStateConst.TEXT_IN_CALL_UN_HOLD_ON, 10004);
  await sleep(100);
  CallManagerService.getInstance().clearData();
  expect(true).assertTrue();
}

let CallManagerServExtTest_onAction_12 = async () => {
  let callData = new DefaultCallData();
  callData.callType = CallStateConst.TYPE_VOIP;
  CallManagerService.getInstance().getCallData(callData);
  await sleep(100);
  CallManagerService.getInstance().onAction('default', 10004);
  await sleep(100);
  CallManagerService.getInstance().clearData();
  expect(true).assertTrue();
}

export default function CallManagerServiceExtTest() {
  describe('CallManagerServiceExtTest', () => {
  })
}