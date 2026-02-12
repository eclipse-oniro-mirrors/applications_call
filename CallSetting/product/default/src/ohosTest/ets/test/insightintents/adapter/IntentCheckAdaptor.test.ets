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
import SatelliteUtils from '../../../../../main/ets/common/utils/SatelliteUtils';
import { StringUtil } from '../../../../../main/ets/common/utils/StringUtil';
import { IntentCheckAdaptor } from '../../../../../main/ets/insightintents/adapter/IntentCheckAdaptor';
import { MobileDataUtil } from '../../../../../main/ets/insightintents/util/MobileDataUtil';

export default function IntentCheckAdaptorTest() {
  describe('IntentCheckAdaptorTest', () => {

    it('IntentCheckAdaptorTest_checkSettingPageIsExist', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(SatelliteUtils, SatelliteUtils.isSupportSkycomSatellite);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      let mockFunc2 = mocker.mockFunc(SatelliteUtils, SatelliteUtils.isSupportBeidouSatellite);
      when(mockFunc2)(ArgumentMatchers.any).afterReturn(true);
      await IntentCheckAdaptor.checkSettingPageIsExist('mobile_data_settings_entry');
      when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
      let result = await IntentCheckAdaptor.checkSettingPageIsExist('satellite_network_entry');
      let mockFunc3 = mocker.mockFunc(StringUtil, StringUtil.isEmpty);
      when(mockFunc3)('empty').afterReturn(true);
      await IntentCheckAdaptor.checkSettingPageIsExist('empty');
      expect(result).assertEqual(true);
      mocker.ignoreMock(SatelliteUtils, SatelliteUtils.isSupportSkycomSatellite);
      mocker.ignoreMock(SatelliteUtils, SatelliteUtils.isSupportBeidouSatellite);
      mocker.ignoreMock(StringUtil, StringUtil.isEmpty);
      mocker.clearAll();
    })
    it('IntentCheckAdaptorTest_checkSettingPage', 0, async () => {
      let result = await IntentCheckAdaptor.checkSettingPage('123', 'com.test');
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(IntentCheckAdaptor, IntentCheckAdaptor.checkSettingPageIsExist);
      when(mockFunc)('123').afterReturn(true);
      await IntentCheckAdaptor.checkSettingPage('123', 'com.test');
      let mockFunc1 = mocker.mockFunc(StringUtil, StringUtil.isEmpty);
      when(mockFunc1)('com.test').afterReturn(true);
      await IntentCheckAdaptor.checkSettingPage('123', 'com.test');
      expect(result.code).assertEqual(0);
      mocker.ignoreMock(StringUtil, StringUtil.isEmpty);
      mocker.ignoreMock(IntentCheckAdaptor, IntentCheckAdaptor.checkSettingPageIsExist);
      mocker.clearAll();
    })
    it('IntentCheckAdaptorTest_checkSettingItem', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(IntentCheckAdaptor, IntentCheckAdaptor.checkSwitchStatusIsActive);
      when(mockFunc)('123').afterReturn(true);
      let mockFunc1 = mocker.mockFunc(MobileDataUtil, MobileDataUtil.isAirplaneActive);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(false);
      let result = await IntentCheckAdaptor.checkSettingItem('123', 'com.test');
      let mockFunc2 = mocker.mockFunc(StringUtil, StringUtil.isEmpty);
      when(mockFunc2)(ArgumentMatchers.any).afterReturn(false);
      await IntentCheckAdaptor.checkSettingItem('123', 'com.test');
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(true);
      await IntentCheckAdaptor.checkSettingItem('123', 'com.test');
      when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
      await IntentCheckAdaptor.checkSettingItem('123', 'com.test');
      expect(result.code).assertEqual(0);
      mocker.ignoreMock(StringUtil, StringUtil.isEmpty);
      mocker.ignoreMock(IntentCheckAdaptor, IntentCheckAdaptor.checkSwitchStatusIsActive);
      mocker.ignoreMock(MobileDataUtil, MobileDataUtil.isAirplaneActive);
      mocker.clearAll();
    })

  })
}