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

import { describe, it, expect } from '@ohos/hypium';
import {
  getDeviceTypeInfo,
  isTablet,
  isALNDevice,
  isPC,
  getDataShareValue,
  isDevicePortrait,
  isSplit
} from '../../../../../main/ets/common/utils/DeviceTypeUtils';
import { common } from '@kit.AbilityKit';
import { CallSettingGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';
const USER_SET_DPI_VALUE: string = 'user_set_dpi_value';
const CALL_SETTING_SATELLITE_ABILITY_CONTEXT = 'callSettingsSatelliteAbilityContext';

export default function DeviceTypeUtilTest() {
  describe('DeviceTypeUtilTest', () => {
    it('callsetting_testDeviceType', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      const deviceTypeInfo = getDeviceTypeInfo();
      const isTablet = deviceTypeInfo === 'tablet';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(isTablet || !isTablet).assertEqual(true);
    });
    it('callsetting_isTablet', 0, () => {
      let result = isTablet();
      expect(result || !result).assertEqual(true);
    });
    it('callsetting_isALNDevice', 0, () => {
      let result = isALNDevice();
      expect(result || !result).assertEqual(true);
    });
    it('callsetting_isPC', 0, () => {
      let result = isPC();
      expect(result || !result).assertEqual(true);
    });
    it('callsetting_getDataShareValue', 0, () => {
      let context = {} as common.Context;
      let result = getDataShareValue(context, USER_SET_DPI_VALUE, '');
      expect(result).assertEqual('');
      context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(Constants.SETTINGS_ABILITY_CONTEXT);
      result = getDataShareValue(context, USER_SET_DPI_VALUE, '').toString();
      expect(result).assertEqual('');
    });
    it('callsetting_isDevicePortrait', 0, () => {
      let result = isDevicePortrait();
      expect(result || !result).assertEqual(true);
    });
    it('callsetting_isSplit', 0, () => {
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)
      let result = isSplit(context);
      expect(result || !result).assertEqual(true);
    });
  });
}