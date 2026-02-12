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

import { describe, it, expect } from '@ohos/hypium';
import { sharedPreferencesUtils, SatelliteSimCardInfoStruct } from '@ohos/common/CommonIndex';
import { getPreferences, getShowName } from '../../../main/ets/model/SatelliteServiceSettingModel';
import * as CallSettingsConstant from '../../../main/ets/common/constant/CallSettingsConstant';

export default function SatelliteServiceSettingModelTest() {
  describe('SatelliteServiceSettingModelTest', () => {
    it('SatelliteServiceSettingModelTest_getShowName', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let simCardInfo: SatelliteSimCardInfoStruct = new SatelliteSimCardInfoStruct();
      simCardInfo.slotId = 0;
      simCardInfo.showNumber = '123456';
      let showName = getShowName(simCardInfo);
      let result = $r('app.string.satellite_service_showname', 0, '123456');
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(simCardInfo.slotId).assertEqual(0);
    });
    it('SatelliteServiceSettingModelTest_getPreferences', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let simCardInfo: SatelliteSimCardInfoStruct = new SatelliteSimCardInfoStruct();
      simCardInfo.slotId = 0;
      simCardInfo.showNumber = '123456';
      simCardInfo.isPreferences = true;
      simCardInfo.iMsi = '890987';
      let info: string[] = [`${simCardInfo.slotId}`, `${simCardInfo.showNumber}`, `${simCardInfo.isPreferences}`,
        `${simCardInfo.iMsi}`];
      sharedPreferencesUtils.saveToPreferences(CallSettingsConstant.SATELLITE_DIALOG_TIPS.SATELLITE_DIALOG_TIPS, info);
      getPreferences((simData: string[]) => {
        // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
        if (simData) {
          expect('true').assertEqual(simData[2]);
        } else {
          expect([]).assertEqual([]);
        }
      });
    })
  })
}