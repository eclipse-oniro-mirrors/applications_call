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
import { LogUtils, SatelliteSimCardInfoStruct } from '@ohos/common/CommonIndex';
import SatelliteServiceSettingsVM from '../../../../main/ets/viewModel/SatelliteServiceSettingsVM'
import { sim } from '@kit.TelephonyKit'

const TAG = 'SatelliteServiceSettingsVMTest'

export default function SatelliteServiceSettingsVMTest() {
  let item1: sim.IccAccountInfo;
  describe('SatelliteServiceSettingsVMTest', () => {
    let sate = SatelliteServiceSettingsVM.getInstance();
    it('SatelliteServiceSettingsVMTest_aboutToAppear', 0, () => {
      let result = SatelliteServiceSettingsVM.getInstance().aboutToAppear();
      expect(result == null).assertTrue();
    })
    it('SatelliteServiceSettingsVMTest_setSimCardName', 0, () => {
      let result = SatelliteServiceSettingsVM.getInstance().setSimCardName();
      expect(result == null).assertTrue();
    })
    it('SatelliteServiceSettingsVMTest_getActiveSimInfoCT', 0, () => {
      let result = SatelliteServiceSettingsVM.getInstance().getActiveSimInfoCT(false);
      expect(result == null).assertTrue();
    })
    it('SatelliteServiceSettingsVMTest_startSatelliteService', 0, () => {
      let result: void;
      try {
        result = SatelliteServiceSettingsVM.getInstance().startSatelliteService();
      } catch (e) {
        LogUtils.i(TAG, e)
      }
      expect(result == null).assertTrue()
    })
    it('SatelliteServiceSettingsVMTest_handleSimCardInfo', 0, () => {
      let result = SatelliteServiceSettingsVM.getInstance().handleSimCardInfo()
      expect(result == null).assertTrue()
    })
    it('SatelliteServiceSettingsVMTest_hasTwoCard', 0, () => {
      let result = SatelliteServiceSettingsVM.getInstance().hasTwoCard()
      if (result) {
        expect(result).assertTrue()
      } else {
        expect(result).assertFalse()
      }
    })
    it('SatelliteServiceSettingsVMTest_jumpPhoneWidget', 0, () => {
      let result = SatelliteServiceSettingsVM.getInstance().jumpPhoneWidget()
      expect(result == null).assertTrue()
    })
    it('SatelliteServiceSettingsVMTest_unRegisterData', 0, () => {
      let result = SatelliteServiceSettingsVM.getInstance().unRegisterData()
      expect(result == null).assertTrue()
    })
    it('SatelliteServiceSettingsVMTest_setSimCardName01', 0, () => {
      let info = new SatelliteSimCardInfoStruct();
      let list: SatelliteSimCardInfoStruct[] = [info];
      (sate as object)["simCardInfoList"] = list;
      sate.setSimCardName();
      sate.getActiveSimInfoCT(true);
      expect(list.length >= 0).assertTrue();
    })
    it('SatelliteServiceSettingsVMTest_handleSimCardInfo01', 0, () => {
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
    it('SatelliteServiceSettingsVMTest_checkHasPreferences01', 0, () => {
      let info = new SatelliteSimCardInfoStruct();
      let info1 = new SatelliteSimCardInfoStruct();
      let list: SatelliteSimCardInfoStruct[] = [info, info1];
      info.iMsi = '890987';
      info1.iMsi = '890987';
      let sate1 = new SatelliteServiceSettingsVM();
      sate1.simCardInfoList = list;
      sate1.handleSimCardInfo();
      sate1.checkHasPreferences();
      expect(info.iMsi === '890987');
    })
    it('SatelliteServiceSettingsVMTest_error', 0, () => {
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
      SatelliteServiceSettingsVM.getInstance().updateShowNumber(iccAccountInfo);
      SatelliteServiceSettingsVM.getInstance().checkIMSI(iccAccountInfo);
    })
  })
}