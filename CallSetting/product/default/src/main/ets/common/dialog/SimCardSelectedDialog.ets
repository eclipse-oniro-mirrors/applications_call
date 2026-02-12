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

import { SelectDialog } from '@ohos.arkui.advanced.Dialog';
import { getShowNameByContext } from '../../model/SatelliteServiceSettingModel';
import { LogUtils, Constants, ReportUtil, SatelliteSimCardInfoStruct,
  CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { SatelliteType } from '../constant/SatelliteSearchConst';
import { common } from '@kit.AbilityKit';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT } from '../constant/CallSettingsConstant';

const TAG = 'SimCardSelectedDialog'

@CustomDialog
export default struct SimCardSelectedDialog {
  simCardSelectedDialog: CustomDialogController;
  @Link controlSwitch: boolean;
  @Link isSimActiveChange: boolean;
  @Link simCardInfoList: SatelliteSimCardInfoStruct[];
  accept: (simInfo: SatelliteSimCardInfoStruct) => void =
    (simInfo: SatelliteSimCardInfoStruct) => {
    };
  private satelliteType: SatelliteType = SatelliteType.TIAN_TONG;
  @State simId: number = 0;
  @State showNumber: Resource = $r('app.string.satellite_service_no_phone_number');
  @State simInfo: SatelliteSimCardInfoStruct = new SatelliteSimCardInfoStruct();
  @State confirmColor: Resource = $r('sys.color.ohos_id_color_text_primary_activated');
  @State selectedIndex: number = -1;
  private content: ResourceStr = $r('app.string.satellite_service_select_sim_card');

  getSelectedIndex() {
    let simInfo = this.simCardInfoList.find((simInfo: SatelliteSimCardInfoStruct) => {
      if (this.satelliteType === SatelliteType.HYACINTH) {
        return simInfo.isHyacinthChecked;
      } else {
        return simInfo.isChecked;
      }
    });
    LogUtils.i(TAG, 'setSelectedAciton getSelectedIndex:' + JSON.stringify(simInfo?.slotId));
    if (simInfo !== undefined) {
      this.selectedIndex = simInfo.slotId;
    }
  }

  setSelectedAciton(id: number) {
    this.selectedIndex = id;
    LogUtils.i(TAG, 'setSelectedAciton : ' + JSON.stringify(this.selectedIndex) + '   ' + JSON.stringify(id));
    if (this.satelliteType === SatelliteType.HYACINTH) {
      this.simCardInfoList[0].isHyacinthChecked = id === 0;
      this.simCardInfoList[1].isHyacinthChecked = id === 1;
    } else {
      this.simCardInfoList[0].isChecked = id === 0;
      this.simCardInfoList[1].isChecked = id === 1;
    }
    this.simCardInfoList[id].isPreferences = true;
    if (!this.isSimActiveChange) {
      this.controlSwitch = true;
    }
    this.simCardSelectedDialog?.close();
    this.accept(this.simCardInfoList[id]);
  }

  aboutToAppear(): void {
    this.getSelectedIndex();
  }

  cancel() {
    if (!this.isSimActiveChange) {
      this.controlSwitch = false;
    }
    this.simCardSelectedDialog?.close();
  }

  build() {
    SelectDialog({
      controller: this.simCardSelectedDialog,
      title: $r('app.string.satellite_service_select_sim'),
      content: this.content,
      confirm: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.cancel();
          ReportUtil.getInstance().reportSatelliteCallSelectSimCardAlert(Constants.UE_CLICK_ALERT_CANCEL);
        }
      },
      selectedIndex: this.selectedIndex,
      radioContent: [
        {
          title: getShowNameByContext(CallSettingGlobalContextHelper.getContext()
            .getValue<common.Context>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT), this.simCardInfoList[0]),
          action: () => {
            this.selectedIndex = -1;
            LogUtils.i(TAG, 'setSelectedAciton one: ');
            this.setSelectedAciton(0);
            ReportUtil.getInstance().reportSatelliteCallSelectSimCardAlert(Constants.UE_SELECT_SIM1);
          },
        },
        {
          title: getShowNameByContext(CallSettingGlobalContextHelper.getContext()
            .getValue<common.Context>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT), this.simCardInfoList[1]),
          action: () => {
            this.selectedIndex = -1;
            LogUtils.i(TAG, 'setSelectedAciton two: ');
            this.setSelectedAciton(1);
            ReportUtil.getInstance().reportSatelliteCallSelectSimCardAlert(Constants.UE_SELECT_SIM2);
          }
        }
      ]
    })
  }
}
