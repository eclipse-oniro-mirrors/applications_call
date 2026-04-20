/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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
import { SATELLITE_DIALOG } from '../common/constant/SatelliteSearchConst';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { SATELLITE_SERVICE_CONTEXT } from '../common/constant/CallSettingsConstant';
import ServiceExtensionContext from '@ohos.app.ability.common';
import SatelliteSearchManager from './SatelliteSearchManager';
import { setFloatWindowKeepScreen } from '../common/utils/WindowUtils';

type Window = window.Window | null;

const TAG = 'SatelliteDialogManager';

/**
 * class SatelliteDialogManager
 */
export default class SatelliteDialogManager {

  private static sSatelliteDialogManager: SatelliteDialogManager;

  /**
   * create satellite dialog manager
   *
   * @returns {Object} - SatelliteDialogManager object
   */
  public static getInstance(): SatelliteDialogManager {
    if (!SatelliteDialogManager.sSatelliteDialogManager) {
      SatelliteDialogManager.sSatelliteDialogManager = new SatelliteDialogManager()
    }
    return SatelliteDialogManager.sSatelliteDialogManager;
  }

  public async createSatelliteDialog() {
    LogUtils.i(TAG, 'Create satellite satellite dialog window.');
    let dialogWindow: Window = null;
    let config: window.Configuration = {
      name: SATELLITE_DIALOG,
      windowType: SatelliteSearchManager.getInstance().getWindowType(),
      ctx: CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)
    };
    try {
      dialogWindow = await window.createWindow(config);
      setFloatWindowKeepScreen(dialogWindow, true, SATELLITE_DIALOG);
      const displayWidth = display.getDefaultDisplaySync().width;
      const displayHeight = display.getDefaultDisplaySync().height;
      await dialogWindow.resize(displayWidth, displayHeight);
      if (SatelliteSearchManager.getInstance().isTianTong()) {
        await dialogWindow.setUIContent('pages/SatelliteDialog');
      } else {
        await dialogWindow.setUIContent('pages/hyacinth/HyacinthDialog');
      }
      dialogWindow.setWindowFocusable(true);
      dialogWindow.setPreferredOrientation(window.Orientation.PORTRAIT);
      dialogWindow.setWindowTouchable(true);
      await dialogWindow.showWindow();
      LogUtils.i(TAG, 'Succeeded in creating the satellite dialog window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to create the satellite dialog window, Cause: ' + JSON.stringify(err));
    }
  }

  public async resizeDisplaySize() {
    try {
      const displayWidth = display.getDefaultDisplaySync().width;
      const displayHeight = display.getDefaultDisplaySync().height;
      let satelliteDialog: Window = null;
      satelliteDialog = window.findWindow(SATELLITE_DIALOG);
      LogUtils.i(TAG, 'resizeDisplaySize');
      if (satelliteDialog) {
        await satelliteDialog.resize(displayWidth, displayHeight);
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to close the satellite dialog window, Cause: ' + JSON.stringify(err))
    }
  }

  /**
   * Close current satellite dialog window
   */
  public async closeSatelliteDialog(): Promise<void> {
    let satelliteDialog: Window = null;
    try {
      satelliteDialog = window.findWindow(SATELLITE_DIALOG);
      if (satelliteDialog) {
        satelliteDialog.off('touchOutside');
        await satelliteDialog.destroyWindow();
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to close the satellite dialog Window, Cause: ' + JSON.stringify(err))
    }
  }

  /**
   * Find satellite dialog window by window name
   *
   * @returns satelliteDialogWindow
   */
  private findDialogWindow(): Window {
    let satelliteDialogWindow: Window = null;
    try {
      satelliteDialogWindow = window.findWindow(SATELLITE_DIALOG);
      LogUtils.i(TAG, 'Succeeded in finding the satellite dialog window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to find the satellite dialog window, Cause: ' + JSON.stringify(err));
    }
    return satelliteDialogWindow;
  }
}