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
import display from '@ohos.display';
import window from '@ohos.window';
import { isTablet } from './DeviceTypeUtils';
import { LogUtils } from '@ohos/common/CommonIndex';
import { BusinessError } from '@ohos.base';
import { sim } from '@kit.TelephonyKit';
import ScreenAdapterUtils from './ScreenAdapterUtils';

const TAG = 'DisplayUtil';
// 屏幕高度除以宽度为0.8的设备,根据屏幕宽高比去适配UI
export const hDividedW08: number = 0.8;
// 屏幕高度除以宽度为1.3的设备
export const hDividedW13: number = 1.3;

export class DisplayUtil {
  /**
   * Check whether the device is foldable
   *
   * @returns { boolean } true means the device is foldable.
   */
  static isFoldable(): boolean {
    let ret: boolean = false;
    try {
      ret = display.isFoldable();
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to check is foldable or not. exp=' + JSON.stringify(exception));
    }
    if (ret === undefined || !ret) {
      LogUtils.i(TAG, 'Failed to check is foldable or not.');
      return false;
    }
    return true;
  }

  /**
   * Set the preferred orientation config of the window
   *
   * @param { window.Window } windowObj - The orientation config of the window
   */
  static setPreferredOrientation(windowObj: window.Window): void {
    if (!windowObj || isTablet()) {
      return;
    }
    try {
      let promise: Promise<void>;
      if (!DisplayUtil.isFoldable() || display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED ||
        ScreenAdapterUtils.isSmallFoldPhone()) {
        promise = windowObj.setPreferredOrientation(window.Orientation.PORTRAIT);
        LogUtils.i(TAG, 'setting the window orientation PORTRAIT');
      } else {
        promise = windowObj.setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED);
        LogUtils.i(TAG, 'setting the window orientation AUTO_ROTATION_RESTRICTED');
      }
      promise.then(() => {
        LogUtils.i(TAG, 'setting the window orientation Succeeded');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'set the window orientation Failed, Cause: ' + JSON.stringify(err));
      });
    } catch (err) {
      LogUtils.e(TAG, `setPreferredOrientation error: ${err?.code} ${err?.message}`);
    }
  }

  /**
   * get screen FoldStatus
   *
   * @returns {number} 1：折叠完全展开 2：折叠状态 3：完全展开和折叠之间 4：未知
   */
  static getScreenFoldStatus(): number {
    let status: number = 0;
    try {
      switch (display.getFoldStatus()) {
        case display.FoldStatus.FOLD_STATUS_EXPANDED:
          status = 1;
          break;
        case display.FoldStatus.FOLD_STATUS_FOLDED:
          status = 2;
          break;
        case display.FoldStatus.FOLD_STATUS_HALF_FOLDED:
          status = 3;
          break;
        case display.FoldStatus.FOLD_STATUS_UNKNOWN:
          status = 4;
          break;
        default:
          status = 0;
          break;
      }
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to obtain the fold status. Code: ' + JSON.stringify(exception));
    }
    return status;
  }

  /**
   * Is expanded status
   *
   * @returns true/false
   */
  static isExpandedStatus(): boolean {
    let result: boolean = false;
    if (!DisplayUtil.isFoldable()) {
      LogUtils.i(TAG, `The device is not foldable device, return.`)
      return result;
    }
    return DisplayUtil.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED;
  }

  /**
   * Is folded status
   *
   * @returns true/false
   */
  static isFoldedStatus(): boolean {
    let result: boolean = false;
    if (!DisplayUtil.isFoldable()) {
      LogUtils.i(TAG, `The device is not foldable device, return.`)
      return result;
    }
    return DisplayUtil.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
  }


  /**
   * Get fold status
   *
   * @returns fold status
   */
  static getFoldStatus(): display.FoldStatus {
    let result: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
    try {
      result = display.getFoldStatus();
    } catch (error) {
      const err = error as BusinessError;
      LogUtils.e(TAG, `getFoldStatus failed. code: ${err?.code}, message: ${err?.message}`);
    }
    LogUtils.i(TAG, `getFoldStatus result: ${result}`);
    return result;
  }

  static isWifiOnlyIpad(): boolean {
    if (isTablet() && sim.getMaxSimCount() === 0) {
      return true;
    }
    return false;
  }
}

