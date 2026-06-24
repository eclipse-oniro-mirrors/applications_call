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
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { describe, it, expect } from '@ohos/hypium';
import { MobileViewData } from '../../../../../main/ets/viewModel/MobileDataViewModel/MobileViewData';
import { SimCardOneViewData } from '../../../../../main/ets/viewModel/MobileDataViewModel/SimCardOneViewData';
import { SimCardTwoViewData } from '../../../../../main/ets/viewModel/MobileDataViewModel/SimCardTwoViewData';
import { common } from '@kit.AbilityKit';
import { settings } from '@kit.BasicServicesKit';
import { GeneralViewEvent } from '../../../../../main/ets/viewModel/MobileDataViewModel/GeneralViewEvent';
import { CALL_SETTING_ABILITY_CONTEXT } from '../../../../../main/ets/common/constant/CallSettingsConstant';

export default function MobileViewDataTest() {
  describe('MobileViewDataTest', () => {

    it('MobileViewDataTest_getCellularDataStateSync', 0, () => {
      let mobileViewData = new MobileViewData();
      let r = mobileViewData.getCellularDataStateSync();
      expect(r == null).assertEqual(true);
    })
    it('MobileViewDataTest_getCellularDataState', 0, () => {
      let mobileViewData = new MobileViewData();
      let r = mobileViewData.getCellularDataState();
      expect(r == null).assertEqual(true);
    })
    it('MobileViewDataTest_initAirPlaneMode', 0, () => {
      let mobileViewData = new MobileViewData();
      let r = mobileViewData.initAirPlaneMode();
      expect(r == null).assertEqual(true);
    })
    it('MobileViewDataTest_updateSatelliteMode', 0, () => {
      let mobileViewData = new MobileViewData();
      mobileViewData.updateSatelliteMode();
      settings.setValueSync(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CALL_SETTING_ABILITY_CONTEXT), 'satellite_mode_switch', '1');
      mobileViewData.updateSatelliteMode();
      mobileViewData.getVSimStatus();
      expect(mobileViewData == null).assertEqual(false);
    })
    it('SimCardOneViewDataTest_updateSatelliteMode', 0, () => {
      let one = new SimCardOneViewData();
      let two = new SimCardTwoViewData();
      one.getSimStateDataCardOne();
      one.getSimCardOnePhoneNumber();
      one.setDisableSimCard();
      two.getSimStateDataCardTwo();
      two.getSimCardTwoPhoneNumber();
      two.setDisableSimCard();
    })
    it('SimCardOneViewDataTest_GeneralViewEvent', 0, () => {
      let generalViewEvent: GeneralViewEvent = new GeneralViewEvent();
      let viewData = new MobileViewData();
      generalViewEvent.onToggleClickEvent(false, viewData);

      viewData.isDataEnable = true;
      generalViewEvent.onToggleClickEvent(false, viewData);

      viewData.isDataEnable = false;
      generalViewEvent.onToggleClickEvent(true, viewData);
    })
  })
}