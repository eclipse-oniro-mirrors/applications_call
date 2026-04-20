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
import { describe, it, expect, MockKit, when } from '@ohos/hypium';
import { IntentSwitchAdaptor } from '../../../../../main/ets/insightintents/adapter/IntentSwitchAdaptor';

export default function IntentSwitchAdaptorTest() {
  describe('IntentSwitchAdaptorTest', () => {

    it('IntentSwitchAdaptorTest_getSettingSwitch', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(IntentSwitchAdaptor, IntentSwitchAdaptor.getSwitchStatus);
      when(mockFunc)('123').afterReturn(true);
      let result = await IntentSwitchAdaptor.getSettingSwitch('123', 'test');
      when(mockFunc)('123').afterReturn(false);
      await IntentSwitchAdaptor.getSettingSwitch('123', 'test');
      mocker.ignoreMock(IntentSwitchAdaptor, IntentSwitchAdaptor.getSwitchStatus);
      mocker.clearAll();
      expect(result.code).assertEqual(0);
    })
    it('IntentSwitchAdaptorTest_setSettingSwitch', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(IntentSwitchAdaptor, IntentSwitchAdaptor.getSwitchStatus);
      when(mockFunc)('123').afterReturn(true);
      let mockFunc1 = mocker.mockFunc(IntentSwitchAdaptor, IntentSwitchAdaptor.setSwitchOn);
      when(mockFunc1)('123').afterReturn(true);
      let mockFunc2 = mocker.mockFunc(IntentSwitchAdaptor, IntentSwitchAdaptor.setSwitchOff);
      when(mockFunc2)('123').afterReturn(true);
      let result = await IntentSwitchAdaptor.setSettingSwitch('123', 'test', 1);
      await IntentSwitchAdaptor.setSettingSwitch('123', 'test', 0)
      when(mockFunc2)('123').afterReturn(false);
      await IntentSwitchAdaptor.setSettingSwitch('123', 'test', 1)
      when(mockFunc)('123').afterReturn(false);
      await IntentSwitchAdaptor.setSettingSwitch('123', 'test', 0)
      await IntentSwitchAdaptor.setSettingSwitch('123', 'test', 1);
      when(mockFunc1)('123').afterReturn(false);
      await IntentSwitchAdaptor.setSettingSwitch('123', 'test', 0)
      await IntentSwitchAdaptor.setSettingSwitch('123', 'test', 2)
      mocker.ignoreMock(IntentSwitchAdaptor, IntentSwitchAdaptor.getSwitchStatus);
      mocker.clearAll();
      expect(result.code).assertEqual(0);
    })
  })
}