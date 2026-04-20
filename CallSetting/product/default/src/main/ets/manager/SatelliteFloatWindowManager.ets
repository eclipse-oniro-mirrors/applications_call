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
import { window } from '@kit.ArkUI';
import { SATELLITE_SERVICE_CONTEXT } from '../common/constant/CallSettingsConstant';
import { SATELLITE_FLOAT_WINDOW } from '../common/constant/SatelliteSearchConst';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import display from '@ohos.display';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { hDividedW08, hDividedW13 } from '../common/utils/DisplayUtil';
import { isTablet } from '../common/utils/DeviceTypeUtils';
import { TrifoldManager } from './TrifoldManager';
import SatelliteSearchManager from './SatelliteSearchManager';
import { setFloatWindowKeepScreen } from '../common/utils/WindowUtils';

/**
 * @file: Satellite float window manager
 */
const TAG = 'SatelliteFloatWindowManager';

const DEFAULT_WINDOW_WIDTH = 328;

export const DEFAULT_WINDOW_HEIGHT = 144;

const DEFAULT_RADIUS = 16

type Window = window.Window | null;


/**
 * class SatelliteFloatWindowManager
 */
export default class SatelliteFloatWindowManager {

  private static sSatelliteFloatWindowManager: SatelliteFloatWindowManager;

  private topMovingDirection: number = 0;

  private leftMovingDirection: number = 0;

  private widthAspectRatio: number = 2.15;

  /**
   * create satellite float window manager
   *
   * @returns {Object} - SatelliteFloatWindowManager object
   */
  public static getInstance(): SatelliteFloatWindowManager {
    if (!SatelliteFloatWindowManager.sSatelliteFloatWindowManager) {
      SatelliteFloatWindowManager.sSatelliteFloatWindowManager = new SatelliteFloatWindowManager()
    }
    return SatelliteFloatWindowManager.sSatelliteFloatWindowManager;
  }

  /**
   * Create satellite float window
   */
  public async createFloatWindow() {
    LogUtils.i(TAG, 'Create satellite float window.');
    let floatWindow: Window = null;
    let config: window.Configuration = {
      name: SATELLITE_FLOAT_WINDOW,
      windowType: SatelliteSearchManager.getInstance().getWindowType(),
      ctx: CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)
    };
    try {
      floatWindow = await window.createWindow(config);
      setFloatWindowKeepScreen(floatWindow, true, SATELLITE_FLOAT_WINDOW);
      const displayWidth = display.getDefaultDisplaySync().width;
      const floatWindowHeight = vp2px(DEFAULT_WINDOW_HEIGHT);
      this.widthAspectRatio = displayWidth != 0 ? display.getDefaultDisplaySync().height / displayWidth : 2.15;
      const floatWindowWidth = this.getFlotWindowWidth(displayWidth);
      this.setFloatWindowSize(floatWindowWidth, floatWindowHeight);
      if (SatelliteSearchManager.getInstance().isTianTong()) {
        await floatWindow.setUIContent('pages/FloatWindow');
      } else {
        await floatWindow.setUIContent('pages/hyacinth/HyacinthFloatWindow');
      }
      floatWindow.setCornerRadius(vp2px(DEFAULT_RADIUS));
      floatWindow.setWindowFocusable(false);
      if (this.leftMovingDirection == 0 || this.topMovingDirection == 0 ||
      SatelliteSearchManager.getInstance().isHyacinth()) {
        this.leftMovingDirection = (displayWidth - floatWindowWidth) / 2;
        this.topMovingDirection = vp2px(176);
      }
      await floatWindow.moveWindowTo(this.leftMovingDirection, this.topMovingDirection);
      floatWindow.setWindowTouchable(true);
      await floatWindow.showWindow();
      LogUtils.i(TAG, 'Succeeded in creating the float window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to create the float window, Cause: ' + JSON.stringify(err));
    }
  }

  getFlotWindowWidth(displayWidth: number) : number {
    if (isTablet() || TrifoldManager.getInstance().isTrifold()) {
      return displayWidth * 749 / 1280;
    } else if (this.widthAspectRatio > hDividedW08 && this.widthAspectRatio <= hDividedW13) {
      if (SatelliteSearchManager.getInstance().isTianTong()) {
        return displayWidth - vp2px(32);
      }
      return (displayWidth - vp2px(32)) * 0.75;
    }
    return displayWidth * 328 / 360;
  }

  /**
   * Close current float window
   */
  public async closeFloatWindow(): Promise<void> {
    let floatWindow: Window = null;
    try {
      floatWindow = window.findWindow(SATELLITE_FLOAT_WINDOW);
      if (floatWindow) {
        await floatWindow.destroyWindow();
      }
    } catch (err) {
      LogUtils.i(TAG, 'Failed to close the float Window, Cause: ' + JSON.stringify(err))
    }
  }

  /**
   * Get float window left moving direction
   *
   * @returns leftMovingDirection
   */
  public getLeftMovingDirection() {
    return this.leftMovingDirection;
  }

  public getWidthAspectRatio() {
    return this.widthAspectRatio;
  }

  /**
   * Get float window top moving direction
   *
   * @returns topMovingDirection
   */
  public getTopMovingDirection() {
    return this.topMovingDirection;
  }

  /**
   * Set float window left moving direction
   *
   * @param leftMovingDirection
   */
  public setLeftMovingDirection(leftMovingDirection: number) {
    this.leftMovingDirection = leftMovingDirection
  }

  /**
   * Set float window top moving direction
   *
   * @param topMovingDirection
   */
  public setTopMovingDirection(topMovingDirection: number) {
    this.topMovingDirection = topMovingDirection
  }

  /**
   * Set float window screen size
   *
   * @param {number} window width
   * @param {number} window height
   */
  public async setFloatWindowSize(width: number = DEFAULT_WINDOW_WIDTH,
                                  height: number = DEFAULT_WINDOW_HEIGHT): Promise<void> {
    const floatWindow: Window = this.findFloatWindow();
    if (!floatWindow) {
      LogUtils.i(TAG, 'The float window does not exist.');
      return;
    }
    try {
      await floatWindow.resize(width, height);
      LogUtils.i(TAG, 'Succeeded in changing the float window size.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to change the float window size, Cause: ' + JSON.stringify(err));
    }
  }

  public async resizeDisplaySize() {
    try {
      const displayWidth = display.getDefaultDisplaySync().width;
      let floatWindow: Window = null;
      floatWindow = window.findWindow(SATELLITE_FLOAT_WINDOW);
      LogUtils.i(TAG, 'resizeDisplaySize');
      if (floatWindow) {
        await floatWindow.resize(this.getFlotWindowWidth(displayWidth), vp2px(DEFAULT_WINDOW_HEIGHT));
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to close the float window, Cause: ' + JSON.stringify(err))
    }
  }

  /**
   * Find float window by window name
   *
   * @returns floatWindow
   */
  private findFloatWindow(): Window {
    let floatWindow: Window = null;
    try {
      floatWindow = window.findWindow(SATELLITE_FLOAT_WINDOW);
      LogUtils.i(TAG, 'Succeeded in finding the float window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to find the float Window, Cause: ' + JSON.stringify(err));
    }
    return floatWindow;
  }
}