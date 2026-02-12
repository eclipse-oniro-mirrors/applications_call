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
import { describe, it, expect } from '@ohos/hypium';
import { CallFaultEventUtil } from '../../../main/ets/common/utils/ReportUtils/CallFaultEventUtil';
import DefaultCallData from '../../../main/ets/common/struct/TypeUtils';
import CallStateConst from '../../../main/ets/common/constant/CallStateConst';
import { BusinessError } from '@kit.BasicServicesKit';

const mCallFaultEventUtil = new CallFaultEventUtil();
const CallFaultEventUtilTest_test_01 = () => {
  const callData: DefaultCallData = {callType: CallStateConst.TYPE_VOIP} as DefaultCallData;
  mCallFaultEventUtil.startCallFullScreen(callData);
  expect(callData.callType === 4).assertTrue();
};

const CallFaultEventUtilTest_test_02 = () => {
  const callData: DefaultCallData = {callType: CallStateConst.TYPE_SATELLITE} as DefaultCallData;
  mCallFaultEventUtil.startCallFullScreen(callData);
  expect(callData.callType === 5).assertTrue();
};

const CallFaultEventUtilTest_test_03 = () => {
  const errorBusiness: BusinessError = {} as BusinessError;
  const callData: DefaultCallData = {} as DefaultCallData;
  mCallFaultEventUtil.reportTimeOutNoInterface(callData);
  mCallFaultEventUtil.onPageFinishCallEvent();
  mCallFaultEventUtil.cancelNotificationCallFaultEvent(errorBusiness);
  mCallFaultEventUtil.disconnectedFinishCallEventFault();
  mCallFaultEventUtil.cancelNotificationCallFaultEvent(errorBusiness);
  mCallFaultEventUtil.reportTimeOutNoInterface(callData);
  mCallFaultEventUtil.finishBannerNotificationCallEventFault(callData,400);
  mCallFaultEventUtil.startCallBannerNotification();
  mCallFaultEventUtil.finishBannerNotificationCallEventFault(callData,400);
  mCallFaultEventUtil.reportOnDestroy();
  mCallFaultEventUtil.disconnectedFinishCallEventFault();
  expect(callData.startTime === -1).assertFalse();
};

export default function CallFaultEventUtilTest() {
  describe('CallFaultEventUtilTest', () => {
    it('CallFaultEventUtilTest_test_01', 0, () => {
      CallFaultEventUtilTest_test_01();
      CallFaultEventUtilTest_test_02();
      CallFaultEventUtilTest_test_03();
    })
  })
}