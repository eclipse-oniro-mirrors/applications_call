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
import { LogUtils, disableCellularData, enableCellularData, ReportUtil } from '@ohos/common/CommonIndex';
import { BusinessError } from '@kit.BasicServicesKit';
import { MobileViewData } from './MobileViewData';

const TAG = 'GeneralViewEvent';

export class GeneralViewEvent {
  public mMobileViewData?: MobileViewData;

  initData(mobileViewData: MobileViewData) {
    this.mMobileViewData = mobileViewData;
  }
  
  onToggleClickEvent(isOn: boolean, mobileViewData: MobileViewData) {
    if (isOn === mobileViewData.isDataEnable) {
      return;
    }
    mobileViewData.isDataEnable = !mobileViewData.isDataEnable;
    LogUtils.i(TAG, 'mobile data switch changes enable:' + JSON.stringify(this.mMobileViewData?.isDataEnable));
    if (!mobileViewData.isDataEnable) {
      disableCellularData()?.then(() => {
        LogUtils.i(TAG, 'disableCellularData: success');
        ReportUtil.getInstance().reportSetMobileNetworkSwitch(0);
      }).catch((error: BusinessError) => {
        LogUtils.i(TAG, 'disableCellularData: error catch' + JSON.stringify(error));
      });
    } else {
      enableCellularData()?.then(() => {
        LogUtils.i(TAG, 'enableCellularData: success');
        ReportUtil.getInstance().reportSetMobileNetworkSwitch(1);
      }).catch((error: BusinessError) => {
        LogUtils.i(TAG, 'enableCellularData: error catch' + JSON.stringify(error));
      });
    }
  }
}