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

import { window } from '@kit.ArkUI';
import { SATELLITE_SERVICE_CONTEXT } from '../common/constant/CallSettingsConstant';
import { NEW_FOLD_ALERT_DIALOG } from '../common/constant/SatelliteSearchConst';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';

type Window = window.Window | null;

/**
 * @file: NewFoldScreen Alert dialog manager
 */
const TAG = 'NewFoldScreenAlertDialogManager';

/**
 * class NewFoldScreenAlertDialogManager
 */
export default class NewFoldScreenAlertDialogManager {
  private static sAlertDialogManager: NewFoldScreenAlertDialogManager;
  public static IS_SHOW: boolean = false;
  private timeId = -1;

  /**
   * create satellite dialog manager
   *
   * @returns {Object} - NewFoldScreenAlertDialogManager object
   */
  public static getInstance(): NewFoldScreenAlertDialogManager {
    if (!NewFoldScreenAlertDialogManager.sAlertDialogManager) {
      NewFoldScreenAlertDialogManager.sAlertDialogManager = new NewFoldScreenAlertDialogManager()
    }
    return NewFoldScreenAlertDialogManager.sAlertDialogManager;
  }

  /**
   * Create new fold alert dialog window on Lock screen
   */
  public async createNewFoldAlertDialogWindow(): Promise<Window> {
    LogUtils.i(TAG, 'Create new fold alert dialog window.');
    let alertDialogWindow: Window = null;
    let config: window.Configuration = {
      name: NEW_FOLD_ALERT_DIALOG,
      windowType: window.WindowType.TYPE_SYSTEM_TOAST,
      ctx: CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)
    };
    try {
      alertDialogWindow = await window.createWindow(config);
      await alertDialogWindow.setUIContent('pages/AlertDialogPageNewFold');
      await alertDialogWindow.setWindowFocusable(false);
      await alertDialogWindow.setWindowTouchable(false);
      alertDialogWindow.setWindowBackgroundColor(Color.Transparent.toString())
      await alertDialogWindow.showWindow();
      NewFoldScreenAlertDialogManager.IS_SHOW = true;
      LogUtils.i(TAG, 'Succeeded in creating the new fold alert dialog window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to create the new fold alert dialog window, Cause: ' + JSON.stringify(err));
    }
    return alertDialogWindow;
  }

  /**
   * Close current new fold alert dialog window
   */
  public async closeNewFoldAlertDialogWindow(): Promise<void> {
    LogUtils.i(TAG, 'closeNewFoldAlertDialogWindow is called')
    if (!NewFoldScreenAlertDialogManager.IS_SHOW) {
      LogUtils.w(TAG, 'closeNewFoldAlertDialogWindow has closed')
      return;
    }
    let alertDialogWindow: Window = null;
    try {
      alertDialogWindow = window.findWindow(NEW_FOLD_ALERT_DIALOG);
      if (alertDialogWindow) {
        await alertDialogWindow.destroyWindow();
      }
      NewFoldScreenAlertDialogManager.IS_SHOW = false;
      if (this.timeId !== -1) {
        clearTimeout(this.timeId);
        this.timeId = -1;
        LogUtils.i(TAG, 'clear destroy new fold alert dialog window task');
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to close the alert dialog window, Cause: ' + JSON.stringify(err));
    }
  }

  /**
   * Close current new fold alert dialog window in delayTime
   */
  closeNewFoldAlertDialogWindowDelay(delayTime: number) {
    this.timeId = setTimeout(() => {
      this.closeNewFoldAlertDialogWindow();
    }, delayTime);
  }
}