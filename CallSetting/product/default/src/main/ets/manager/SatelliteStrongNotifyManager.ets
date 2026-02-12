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

import { display, window } from '@kit.ArkUI';
import { STRONG_NOTIFY } from '../common/constant/SatelliteSearchConst';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { SATELLITE_SERVICE_CONTEXT } from '../common/constant/CallSettingsConstant';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { isScreenLocked } from '../common/utils/DeviceTypeUtils';

type Window = window.Window | null;

const TAG = 'SatelliteStrongNotifyManager';
/**
 * class SatelliteStrongNotifyManager
 */
export default class SatelliteStrongNotifyManager {
  private static sSatelliteStrongNotifyManager: SatelliteStrongNotifyManager;

  /**
   * create satellite strong notify manager
   *
   * @returns {Object} - SatelliteStrongNotifyManager object
   */
  public static getInstance(): SatelliteStrongNotifyManager {
    if (!SatelliteStrongNotifyManager.sSatelliteStrongNotifyManager) {
      SatelliteStrongNotifyManager.sSatelliteStrongNotifyManager = new SatelliteStrongNotifyManager()
    }
    return SatelliteStrongNotifyManager.sSatelliteStrongNotifyManager;
  }

  public async createStrongNotify() {
    LogUtils.i(TAG, 'Create satellite strong notify window.');
    let strongNotifyWindow: Window = null;
    let isLock: boolean = isScreenLocked();
    LogUtils.i(TAG, 'isLock' + isLock);
    let configLock: window.Configuration = {
      name: STRONG_NOTIFY,
      windowType: window.WindowType.TYPE_SYSTEM_TOAST,
      ctx: CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)
    };
    let configUnLock: window.Configuration = {
      name: STRONG_NOTIFY,
      windowType: window.WindowType.TYPE_GLOBAL_SEARCH,
      ctx: CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)
    };
    try {
      if (isLock) {
        strongNotifyWindow = await window.createWindow(configLock);
      } else {
        strongNotifyWindow = await window.createWindow(configUnLock);
      }
      this.setStrongNotifyWakeUpScreen(strongNotifyWindow);
      const displayWidth = display.getDefaultDisplaySync().width;
      const displayHeight = display.getDefaultDisplaySync().height;
      await strongNotifyWindow.resize(displayWidth, displayHeight);
      await strongNotifyWindow.setUIContent('pages/SatelliteStrongNotify');
      strongNotifyWindow.setWindowFocusable(true);
      strongNotifyWindow.setPreferredOrientation(window.Orientation.PORTRAIT);
      strongNotifyWindow.setWindowTouchable(true);
      await strongNotifyWindow.showWindow();
      LogUtils.i(TAG, 'Succeeded in creating the satellite strong notify window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to create the satellite strong notify window, Cause: ' + JSON.stringify(err));
    }
  }

  public async closeStrongNotify(): Promise<void> {
    let strongNotifyWindow: Window = null;
    try {
      strongNotifyWindow = window.findWindow(STRONG_NOTIFY);
      if (strongNotifyWindow) {
        strongNotifyWindow.off('touchOutside');
        await strongNotifyWindow.destroyWindow();
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to close the satellite strong notify window, Cause: ' + JSON.stringify(err))
    }
  }

  public async setStrongNotifyWakeUpScreen(window: Window): Promise<void> {
    if (!window) {
      LogUtils.e(TAG, 'setStrongNotifyWakeUpScreen error for invalid SatelliteStrongNotifyWindow');
      return;
    }
    await window.setWakeUpScreen(true);
  }

  public async resizeDisplaySize() {
    try {
      const displayWidth = display.getDefaultDisplaySync().width;
      const displayHeight = display.getDefaultDisplaySync().height;
      let strongNotifyWindow: Window = null;
      strongNotifyWindow = window.findWindow(STRONG_NOTIFY);
      LogUtils.i(TAG, 'resizeDisplaySize');
      if (strongNotifyWindow) {
        await strongNotifyWindow.resize(displayWidth, displayHeight);
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to close the satellite strong notify window, Cause: ' + JSON.stringify(err))
    }
  }

  private findStrongNotifyWindow(): Window {
    let strongNotifyWindow: Window = null;
    try {
      strongNotifyWindow = window.findWindow(STRONG_NOTIFY);
      LogUtils.i(TAG, 'Succeeded in finding the satellite strong notify window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to find the satellite strong notify window, Cause: ' + JSON.stringify(err));
    }
    return strongNotifyWindow;
  }
}