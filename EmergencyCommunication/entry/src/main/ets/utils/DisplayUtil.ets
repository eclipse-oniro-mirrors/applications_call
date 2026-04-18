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
import I18n from '@ohos.i18n';
import { isTablet } from './DeviceTypeUtils';
import LogUtils from './HiLog';
import { BusinessError } from '@ohos.base';
import ScreenAdapterUtils from './ScreenAdapterUtils';

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
        case 1:
          status = 1;
          break;
        case display.FoldStatus.FOLD_STATUS_FOLDED:
          status = 2;
          break;
        case display.FoldStatus.FOLD_STATUS_HALF_FOLDED:
        case display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_HALF_FOLDED:
        case display.FoldStatus.FOLD_STATUS_HALF_FOLDED_WITH_SECOND_HALF_FOLDED:
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

  static updateIsRtl() {
    try {
      let isRTL = I18n.isRTL(I18n.System.getSystemLocale());
      LogUtils.i(TAG, `updateIsRtl:${isRTL}`);
      AppStorage.setOrCreate('isRTL', isRTL);
    } catch (exception) {
      LogUtils.e(TAG, `updateIsRtl. error code: ${exception?.code}`);
    }
  }
}

