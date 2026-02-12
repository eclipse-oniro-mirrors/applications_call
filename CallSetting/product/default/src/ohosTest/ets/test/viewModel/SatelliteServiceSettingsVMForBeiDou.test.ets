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
import SatelliteServiceSettingsVMForBeiDou from '../../../../main/ets/viewModel/SatelliteServiceSettingsVMForBeiDou';
import { sim } from '@kit.TelephonyKit';
import { SatelliteSimCardInfoStruct } from '@ohos/common';
import {
  SATELLITE_TOAST_AIRPLANE_CODE,
  SATELLITE_TOAST_OFF_CODE
} from '../../../../main/ets/common/constant/SatelliteSearchConst';

export default function SatelliteServiceSettingsVMForBeiDouTest() {
  describe('SatelliteServiceSettingsVMForBeiDouTest', () => {
    it('SatelliteServiceSettingsVMForBeiDouTest_01', 0, () => {
      SatelliteServiceSettingsVMForBeiDou.getInstance();
      SatelliteServiceSettingsVMForBeiDou.getInstance().aboutToAppear();
      SatelliteServiceSettingsVMForBeiDou.getInstance().initSimCardName();
      SatelliteServiceSettingsVMForBeiDou.getInstance().getActiveSimInfoCT(true);
      SatelliteServiceSettingsVMForBeiDou.getInstance().getActiveSimInfoCT(false);
      let iccAccountInfo: sim.IccAccountInfo = {
        simId: 0,
        slotIndex: 0,
        isEsim: false,
        isActive: false,
        iccId: '',
        showName: '',
        showNumber: '',
        simLabelIndex: 0,
        operatorName: ''
      }
      let simIccInfoArr = new Array<sim.IccAccountInfo>();
      simIccInfoArr.push(iccAccountInfo);
      SatelliteServiceSettingsVMForBeiDou.getInstance().updateSimInfoList(simIccInfoArr);
      SatelliteServiceSettingsVMForBeiDou.getInstance().checkHasPreferences();
      SatelliteServiceSettingsVMForBeiDou.getInstance().updateShowNumber(iccAccountInfo);
      SatelliteServiceSettingsVMForBeiDou.getInstance().checkIMSI(iccAccountInfo);
      SatelliteServiceSettingsVMForBeiDou.getInstance().handleSimCardInfo();
      SatelliteServiceSettingsVMForBeiDou.getInstance().registerData();
      SatelliteServiceSettingsVMForBeiDou.getInstance().registerSimSateChange();
      SatelliteServiceSettingsVMForBeiDou.getInstance().addSimStateAcitveChangeListener((arg: boolean) => {
      });
      SatelliteServiceSettingsVMForBeiDou.getInstance().getSimListChange();
      SatelliteServiceSettingsVMForBeiDou.getInstance().jumpPhoneWidget();
      SatelliteServiceSettingsVMForBeiDou.getInstance().subscribeSatelliteToastEvent();
      (SatelliteServiceSettingsVMForBeiDou.getInstance() as object)['showSatelliteToast'](SATELLITE_TOAST_OFF_CODE);
      (SatelliteServiceSettingsVMForBeiDou.getInstance() as object)['showSatelliteToast'](SATELLITE_TOAST_AIRPLANE_CODE);
      SatelliteServiceSettingsVMForBeiDou.getInstance().unSubscribeSatelliteToastEvent();
      SatelliteServiceSettingsVMForBeiDou.getInstance().unRegisterData();
    })

    it('SatelliteServiceSettingsVMTest_02', 0, () => {
      let sate = SatelliteServiceSettingsVMForBeiDou.getInstance();
      let info = new SatelliteSimCardInfoStruct();
      info.slotId = 1;
      let info1 = new SatelliteSimCardInfoStruct();
      info1.slotId = 2;
      let item: sim.IccAccountInfo = {
        simId: 0,
        slotIndex: 0,
        isEsim: false,
        isActive: false,
        iccId: '',
        showName: '',
        showNumber: '',
        simLabelIndex: 0,
        operatorName: ''
      }
      sate.simCardInfoList.push(info);
      sate.handleSimCardInfo();
      sate.simCardInfoList.push(info1);
      sate.handleSimCardInfo();
      info1.slotId = 0;
      sate.handleSimCardInfo();
      sate.simStateChange(info1, item, '');
      sate.isStartSatelliteService = false;
      sate.simActiveState = (arg: boolean) => {
        return arg
      };
      sate.getSimListChange();
      (sate as object)["isSimActive"] = false;
      sate.getSimListChange();
      sate.isStartSatelliteService = true;
      sate.getSimListChange();
      expect(item.simId === 0).assertTrue();
    })
    it('SatelliteServiceSettingsVMTest_03', 0, () => {
      let info = new SatelliteSimCardInfoStruct();
      let info1 = new SatelliteSimCardInfoStruct();
      let list: SatelliteSimCardInfoStruct[] = [info, info1];
      info.iMsi = '890987';
      info1.iMsi = '890987';
      let sate1 = new SatelliteServiceSettingsVMForBeiDou();
      sate1.simCardInfoList = list;
      sate1.handleSimCardInfo();
      sate1.checkHasPreferences();
      expect(info.iMsi === '890987');
    })
  })
}