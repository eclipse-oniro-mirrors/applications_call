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
  LogUtils,
  isCellularDataEnabled,
  isCellularDataEnabledSync,
  addAirPlaneModeListener,
  MobileDataGlobalContextHelper,
  Constants
} from '@ohos/common/CommonIndex';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
// import vsim from '@hms.telephony.vsim';

const TAG = 'MobileViewData';

@Observed
export class MobileViewData {
  public isDataEnable: boolean = false;
  public isAirPlaneMode: boolean = false;
  public isSatelliteMode: boolean = false;
  public isVSimMode: boolean = false;

  /**
   *   Sync Get mobile data on or off
   */
  getCellularDataStateSync() {
    try {
      this.isDataEnable = isCellularDataEnabledSync();
    } catch (error) {
      LogUtils.e(TAG, 'isCellularDataEnabled error catch' + JSON.stringify(error));
    }
  }

  /**
   * Get mobile data on or off
   */
  getCellularDataState() {
    isCellularDataEnabled()?.then((data: boolean) => {
      LogUtils.i(TAG, 'isCellularDataEnabled success: isON:' + JSON.stringify(data));
      this.isDataEnable = data;
    }).catch((error: BusinessError) => {
      LogUtils.i(TAG, 'isCellularDataEnabled error catch' + JSON.stringify(error));
    });
  }

  // init AirPlane Mode
  initAirPlaneMode() {
    LogUtils.i(TAG, 'initAirPlaneMode');
    addAirPlaneModeListener((data: number) => {
      LogUtils.i(TAG, `initAirPlaneMode callback : ${data === 1})`);
      this.isAirPlaneMode = data === 1;
    });
  }

  updateSatelliteMode() {
    let satelliteStatus = settings.getValueSync(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), 'satellite_mode_switch', '0');
    LogUtils.i(TAG, 'updateSatelliteMode satelliteStatus: ' + JSON.stringify(satelliteStatus));
    if (satelliteStatus && Number(satelliteStatus) === 1) {
      this.isSatelliteMode = true;
    } else {
      this.isSatelliteMode = false;
    }
  }

  // get VSim Mode
  getVSimStatus() {
    try {
      // this.isVSimMode = vsim.getVSimStatus()?.isVSimEnabled;
      LogUtils.i(TAG, `getVSimStatus isVSimMode: ${this.isVSimMode}`);
    } catch (err) {
      LogUtils.e(TAG, `getVSimStatus err = ${JSON.stringify(err)}`);
    }
  }
}