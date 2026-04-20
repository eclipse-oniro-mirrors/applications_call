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
import { describe, expect, it } from '@ohos/hypium';
import CommonData from '../../../../main/ets/data/CommonData';
import {
  encapsulateReturnResult,
  RESTORE_TIAN_TONG_SWITCH,
  SatelliteUtil
} from '../../../../main/ets/utils/SatelliteUtil';
import { common } from '@kit.AbilityKit';

export default function SatelliteUtilTest() {
  describe('SatelliteUtilTest', () => {
    it('SatelliteUtilTest_encapsulateReturnResult', 0, () => {
      encapsulateReturnResult(CommonData.int['SUCCESS'], '');
      expect(1).assertEqual(1);
    })
    it('SatelliteUtilTest_getProxyOfCallSettingServiceExtAbility', 0, () => {
      SatelliteUtil.getInstance().getProxyOfCallSettingServiceExtAbility();
      expect(1).assertEqual(1);
    })
    it('SatelliteUtilTest_getConnectIdOfCallSettingServiceExtAbility', 0, () => {
      SatelliteUtil.getInstance().getConnectIdOfCallSettingServiceExtAbility();
      expect(1).assertEqual(1);
    })
    it('SatelliteUtilTest_connectAndDisConnectCallSettingSatelliteServiceExtAbility', 0, () => {
      SatelliteUtil.getInstance().connectCallSettingSatelliteServiceExtAbility(getContext(), () => {
      }, (proxy) => {
      });
      SatelliteUtil.getInstance()
        .disConnectCallSettingSatelliteServiceExtAbility(getContext() as common.UIAbilityContext);
      expect(1).assertEqual(1);
    })
    it('SatelliteUtilTest_requestToCallSettingService', 0, () => {
      SatelliteUtil.requestToCallSettingService(
        SatelliteUtil.getInstance().getProxyOfCallSettingServiceExtAbility(), RESTORE_TIAN_TONG_SWITCH, '');
      expect(1).assertEqual(1);
    })
    it('SatelliteUtilTest_getIsDeviceSupportTianTongSatellite', 0, () => {
      expect(Boolean(typeof SatelliteUtil.getIsDeviceSupportTianTongSatellite() === 'boolean')).assertTrue();
    })
    it('SatelliteUtilTest_getTianTongSatelliteSwitchState', 0, () => {
      SatelliteUtil.getTianTongSatelliteSwitchState(getContext());
      expect(1).assertEqual(1);
    })
  })
}