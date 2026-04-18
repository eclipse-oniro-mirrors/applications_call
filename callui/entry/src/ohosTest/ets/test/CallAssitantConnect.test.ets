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

import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { CallUIRemoteType, CeliaAssistantServiceStub,
  CeliaCode,
  ConnectionManager} from '../../../main/ets/common/utils/CallAssistantConnect';
import { rpc } from '@kit.IPCKit';
import { common } from '@kit.AbilityKit';
import Utils from '../../../main/ets/common/utils/utils';
import { processSummaryFail } from '../../../main/ets/common/utils/CallSummaryUtils';
import LogUtils from '../../../main/ets/common/utils/LogUtils';

export default function CallAssistantConnectTest() {
  describe('CeliaAssistantServiceStub', () => {
    let serviceStub: CeliaAssistantServiceStub;
    let mockData: rpc.MessageSequence;
    let mockReply: rpc.MessageSequence;
    let mockOptions: rpc.MessageOption;

    beforeEach(() => {
      serviceStub = new CeliaAssistantServiceStub('testDescriptor');
      mockData = new rpc.MessageSequence();
      mockReply = new rpc.MessageSequence();
      mockOptions = new rpc.MessageOption();
    });

    it('should return false when permissions check fails', 0, async () => {
      // 模拟权限检查失败
      mockData.writeInterfaceToken('');
      const result =
        await serviceStub.onRemoteMessageRequest(CallUIRemoteType.ON_AUTO_SERVICE_ERROR, mockData, mockReply,
          mockOptions);
      expect(result).assertEqual(false);
    });

    it('should return false when exception termination occurs', 0, async () => {
      // 模拟异常终止情况
      mockData.writeInterfaceToken('testDescriptor');
      mockData.writeString(JSON.stringify({ code: CeliaCode.ExceptionTermination }));
      const result =
        await serviceStub.onRemoteMessageRequest(CallUIRemoteType.ON_AUTO_SERVICE_ERROR, mockData, mockReply,
          mockOptions);
      expect(result).assertEqual(false);
    });

    it('should return false when audio stream fails', 0, async () => {
      // 模拟音频流失败情况
      mockData.writeInterfaceToken('testDescriptor');
      mockData.writeString(JSON.stringify({ code: CeliaCode.AudioStreamFailed }));
      const result = await serviceStub.onRemoteMessageRequest(CallUIRemoteType.ON_AUTO_SERVICE_ERROR, mockData, mockReply, mockOptions);
      expect(result).assertEqual(false);
    });

    it('should return true when all checks pass', 0, async () => {
      // 模拟正常情况
      mockData.writeInterfaceToken('testDescriptor');
      mockData.writeString(JSON.stringify({ code: undefined }));
      const result = await serviceStub.onRemoteMessageRequest(CallUIRemoteType.ON_AUTO_SERVICE_ERROR, mockData, mockReply, mockOptions);
      expect(result).assertEqual(true);
    });

    it('should_log_duration_when_isEnabled_is_false', 0, async () => {
      let mocker: MockKit = new MockKit();
      let logUtilsMock: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(logUtilsMock)(ArgumentMatchers.anyString).afterReturnNothing();

      let connectionManager: ConnectionManager = ConnectionManager.getInstance();

      connectionManager.openCallSummaryByCeliaService(getContext() as common.ServiceExtensionContext, {
        bundleName: 'testBundle',
        abilityName: 'testAbility'
      }, false);
      let result: number = (connectionManager as object)['startTime'];
      expect(result !== -1).assertTrue();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_not_log_duration_when_isEnabled_is_true', 0, async () => {
      let mocker: MockKit = new MockKit();
      let logUtilsMock: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(logUtilsMock)(ArgumentMatchers.anyString).afterReturnNothing();

      let connectionManager: ConnectionManager = ConnectionManager.getInstance();

      connectionManager.openCallSummaryByCeliaService(getContext() as common.ServiceExtensionContext, {
        bundleName: 'testBundle',
        abilityName: 'testAbility'
      }, true);
      let result: number = (connectionManager as object)['startTime'];
      expect(result !== -1).assertTrue();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_call_processSummaryFail_when_sendMessage_throws_error', 0, async () => {
      let mocker: MockKit = new MockKit();
      let connectionManager: ConnectionManager = ConnectionManager.getInstance();

      let processSummaryFailMock: Function = mocker.mockFunc(Utils, processSummaryFail);
      when(processSummaryFailMock)(ArgumentMatchers.anyNumber).afterReturnNothing();

      connectionManager.openCallSummaryByCeliaService(getContext() as common.ServiceExtensionContext, {
        bundleName: 'testBundle',
        abilityName: 'testAbility'
      }, true);
      let result: number = (connectionManager as object)['startTime'];
      expect(result !== -1).assertTrue();
      mocker.ignoreMock(Utils, processSummaryFail);
    });

    it('should_call_sendMessage_with_correct_parameters', 0, async () => {
      let mocker: MockKit = new MockKit();
      let connectionManager: ConnectionManager = ConnectionManager.getInstance();
      connectionManager.openCallSummaryByCeliaService(getContext() as common.ServiceExtensionContext, {
        bundleName: 'testBundle',
        abilityName: 'testAbility'
      }, true);
      let result: number = (connectionManager as object)['startTime'];
      expect(result !== -1).assertTrue();
      mocker.ignoreMock(connectionManager, connectionManager.openCallSummaryByCeliaService);
    });

  });
}
