/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import ServiceExtension from '@ohos.app.ability.ServiceExtensionAbility';
import { LogUtils, CallSettingGlobalContextHelper, ReportUtil } from '@ohos/common/CommonIndex';
import ServiceExtensionContext from '@ohos.app.ability.common';
import SatelliteSearchManager from '../manager/SatelliteSearchManager';
import { SATELLITE_SERVICE_CONTEXT } from '../common/constant/CallSettingsConstant';
import { Configuration } from '@ohos.app.ability.Configuration';
import { getPushString } from '../common/utils/Utils';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { NotificationPosition } from '../common/data/commonData';

const TAG = 'SatelliteService';

export default class SatelliteService extends ServiceExtension {

  public satelliteSearchManager?: SatelliteSearchManager;

  onCreate(want: Want): void {
    LogUtils.i(TAG, 'onCreate satellite service');
    if (getPushString((want.parameters?.callerName ?? '') as string) ===
    CallSettingsConstant.CLOSE_SATELLITE_NETWORK_BUTTON ||
      getPushString((want.parameters?.callerName ?? '') as string) ===
      CallSettingsConstant.IGNORE_NOTIFY_BUTTON) {
      // 点击忽略按钮或关闭卫星按钮调起此服务不执行后面操作
      LogUtils.i(TAG, 'onCreate satellite service, callerName is cellularNetworkNotify');
      return;
    }
    CallSettingGlobalContextHelper.getContext()
      .set<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT, this.context);
    this.satelliteSearchManager = SatelliteSearchManager.getInstance();
    this.satelliteSearchManager.startSatellite(want?.parameters?.satelliteType as number);
  }

  onRequest(want: Want, startId: number): void {
    LogUtils.i(TAG, 'onRequest satellite service');
    if (getPushString((want.parameters?.callerName ?? '') as string) ===
    CallSettingsConstant.CLOSE_SATELLITE_NETWORK_BUTTON) {
      // 点击关闭卫星按钮调起此服务关闭天通开关
      LogUtils.i(TAG, 'onRequest satellite service, callerName is close_satellite_network_button');
      SatelliteSearchManager.getInstance().satelliteSearchStarted = true;
      SatelliteSearchManager.getInstance().finishSatellite(false);
      ReportUtil.getInstance().reportCellularNetworkNotification(NotificationPosition.CLOSE_SATELLITE_NETWORK_BUTTON);
    } else if (getPushString((want.parameters?.callerName ?? '') as string) ===
    CallSettingsConstant.IGNORE_NOTIFY_BUTTON) {
      LogUtils.i(TAG, 'onRequest satellite service, callerName is ignore_notify_button');
      ReportUtil.getInstance().reportCellularNetworkNotification(NotificationPosition.IGNORE_NOTIFY_BUTTON);
    }
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy satellite service');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    this.satelliteSearchManager = SatelliteSearchManager.getInstance();
    let direction: number | undefined = newConfig.direction?.valueOf();
    if (direction !== undefined && this.satelliteSearchManager.getUIOrientation() !== direction) {
      LogUtils.i(TAG, 'orientation changes, need recreate dialog or floatWindow.');
      this.satelliteSearchManager.reCreateDialogOrFloatWindow(direction);
    }
  }
}