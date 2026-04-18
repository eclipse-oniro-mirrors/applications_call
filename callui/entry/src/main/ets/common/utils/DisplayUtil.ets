/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import { DisplayUtilDT } from './DisplayUtilDT';
import LogUtils from './LogUtils';
import { isTablet } from './DeviceTypeUtils';
import { sim } from '@kit.TelephonyKit';

const TAG = 'DisplayUtil';

export class DisplayUtil {
  /**
   * Check whether the device is foldable
   *
   * @returns { boolean } true means the device is foldable.
   */
  static isFoldable(): boolean {
    let ret: boolean = false;
    try {
      ret = DisplayUtilDT.isFoldable();
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to check is foldable or not. exception =' + JSON.stringify(exception));
    }
    if (ret === undefined || !ret) {
      LogUtils.d(TAG, 'Failed to check is foldable or not.');
      return false;
    } else {
      LogUtils.d(TAG, 'Success to check is foldable or not.');
    }
    return true;
  }

  /**
   * get screen FoldStatus
   *
   * @returns { number } 1：折叠完全展开 2：折叠状态 3：完全展开和折叠之间 4：未知
   */
  static getScreenFoldStatus(): number {
    let status: number = 0;
    try {
      switch (DisplayUtilDT.getFoldStatus()) {
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

  static isWifiOnlyDevice(): boolean {
    if (isTablet() && sim.getMaxSimCount() === 0) {
      return true;
    }
    return false;
  }
}