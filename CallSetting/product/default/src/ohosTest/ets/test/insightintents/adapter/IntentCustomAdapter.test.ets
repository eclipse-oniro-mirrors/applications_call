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
import {
  describe,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import { IntentCustomAdaptor } from '../../../../../main/ets/insightintents/adapter/IntentCustomAdapter';
import { IntentCodeConstants } from '../../../../../main/ets/insightintents/constant/IntentCodeConstant';
import { MobileDataUtil } from '../../../../../main/ets/insightintents/util/MobileDataUtil';

export default function IntentCustomAdapterTest() {
  describe('IntentCustomAdapterTest', () => {

    it('IntentCustomAdaptor_checkDateRoamingSwitch', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(MobileDataUtil, MobileDataUtil.checkCellularDataRoamingIsActive);
      when(mockFunc)(9).afterReturn(true);
      let mockFunc1 = mocker.mockFunc(MobileDataUtil, MobileDataUtil.isAirplaneActive);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(true);
      await IntentCustomAdaptor.checkDateRoamingSwitch(9);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(false);
      await IntentCustomAdaptor.checkDateRoamingSwitch(9);
      mocker.ignoreMock(MobileDataUtil, MobileDataUtil.checkCellularDataRoamingIsActive);
      mocker.ignoreMock(MobileDataUtil, MobileDataUtil.isAirplaneActive);
      mocker.clearAll();
    })
    it('IntentCustomAdaptor_getCellularDataRoamingEnabled', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(MobileDataUtil, MobileDataUtil.getCellularDataRoamingEnabled);
      when(mockFunc)(8).afterReturn(true);
      let mockFunc1 = mocker.mockFunc(MobileDataUtil, MobileDataUtil.enableCellularDataRoaming);
      when(mockFunc1)(8).afterReturn(true);
      let result = await IntentCustomAdaptor.setDataRoamingSwitch(8, 0);
      when(mockFunc)(8).afterReturn(false);
      await IntentCustomAdaptor.setDataRoamingSwitch(8, 0);
      when(mockFunc1)(8).afterReturn(false);
      await IntentCustomAdaptor.setDataRoamingSwitch(8, 0);
      when(mockFunc)(8).afterReturn(false);
      await IntentCustomAdaptor.setDataRoamingSwitch(8, 1);
      when(mockFunc)(8).afterReturn(true);
      await IntentCustomAdaptor.setDataRoamingSwitch(8, 1);
      let mockFunc2 = mocker.mockFunc(MobileDataUtil, MobileDataUtil.disableCellularDataRoaming);
      when(mockFunc2)(8).afterReturn(true);
      await IntentCustomAdaptor.setDataRoamingSwitch(8, 1);
      await IntentCustomAdaptor.setDataRoamingSwitch(8, 2);
      expect(result.code).assertEqual(IntentCodeConstants.DEFAULT_CODE_SUCCESS);
      mocker.ignoreMock(MobileDataUtil, MobileDataUtil.disableCellularDataRoaming);
      mocker.ignoreMock(MobileDataUtil, MobileDataUtil.getCellularDataRoamingEnabled);
      mocker.ignoreMock(MobileDataUtil, MobileDataUtil.enableCellularDataRoaming);
      mocker.clearAll();
    })
    it('IntentCustomAdaptor_getDataRoamingSwitch', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(MobileDataUtil, MobileDataUtil.getCellularDataRoamingEnabled);
      when(mockFunc)(9).afterReturn(true);
      await IntentCustomAdaptor.getDataRoamingSwitch(9);
      when(mockFunc)(9).afterReturn(false);
      let result = await IntentCustomAdaptor.getDataRoamingSwitch(9);
      expect(result.code).assertEqual(IntentCodeConstants.DEFAULT_CODE_SUCCESS);
      mocker.ignoreMock(MobileDataUtil, MobileDataUtil.getCellularDataRoamingEnabled);
      mocker.clearAll();
    })
  })
}