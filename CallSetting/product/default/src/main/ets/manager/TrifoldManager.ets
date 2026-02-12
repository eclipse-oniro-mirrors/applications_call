/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { LogUtils } from '@ohos/common';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';

const TAG = 'TrifoldManager';


export class TrifoldManager {
  private static trifoldManager: TrifoldManager;

  public static getInstance(): TrifoldManager {
    if (!TrifoldManager.trifoldManager) {
      TrifoldManager.trifoldManager = new TrifoldManager();
    }
    return TrifoldManager.trifoldManager;
  }

  isTrifold(): boolean {
    let foldStatus: number = AppStorage.get('foldStatus') ?? 1;
    LogUtils.i(TAG, `this.foldDisplayMode value is ${foldStatus}`);
    return foldStatus === 11 || foldStatus === 21 || foldStatus === 13 || foldStatus === 23;
  }

  showCenter(): boolean {
    let foldStatus: number = AppStorage.get('foldStatus') ?? 1;
    LogUtils.i(TAG, `this.foldDisplayMode value is ${foldStatus}`);
    if (foldStatus === 11 || foldStatus === 21 || foldStatus === 13 || foldStatus === 23 || foldStatus === 1 ||
      foldStatus === 3) {
      return true;
    }
    return false
  }

  rection(orientation: display.Orientation) {
    LogUtils.i(TAG, `orientation value is ${orientation}`);
    if (this.isTrifold()) {
      if (orientation === display.Orientation.LANDSCAPE_INVERTED) {
        return display.Orientation.PORTRAIT;
      } else if (orientation === display.Orientation.LANDSCAPE) {
        return display.Orientation.PORTRAIT_INVERTED;
      } else if (orientation === display.Orientation.PORTRAIT) {
        return display.Orientation.LANDSCAPE;
      } else if (orientation === display.Orientation.PORTRAIT_INVERTED) {
        return display.Orientation.LANDSCAPE_INVERTED;
      }
    }
    if (ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen()) {
      try {
        return display.getDefaultDisplaySync().rotation;
      } catch (err) {
        LogUtils.e(TAG, `getDefaultDisplaySync err ${err?.code}`);
      }
    }
    return orientation;
  }

  isTripleFoldG(): boolean {
    if (!this.isTrifold()) {
      return false;
    }
    try {
      const foldStatus: display.FoldStatus = display.getFoldStatus();
      return foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_EXPANDED ||
        foldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED_WITH_SECOND_EXPANDED ||
        foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_HALF_FOLDED ||
        foldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED_WITH_SECOND_HALF_FOLDED;
    } catch (error) {
      LogUtils.e(TAG, `isTripleFoldG -> try error: ${error}`);
      return false;
    }
  }
}