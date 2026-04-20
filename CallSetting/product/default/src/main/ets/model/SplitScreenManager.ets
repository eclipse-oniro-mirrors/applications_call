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

import window from '@ohos.window';
import { LogUtils } from '@ohos/common/CommonIndex';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { isTablet } from '../common/utils/DeviceTypeUtils';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { isPhone, isTwoInOne } from '../common/utils/Utils';
import { TrifoldManager } from '../manager/TrifoldManager';
import { display } from '@kit.ArkUI';

const TAG = 'SplitScreenManager';
const ONE_HALF = 1 / 2;
const ONE_THREE = 1 / 3;
const TWO_THREE = 2 / 3;

export enum SplitScreenType {
  DEFAULT = 0,
  SMALL = 1,
  MEDIUM = 2,
  BIG = 3
}

/**
 * class SplitScreenManager
 */
export default class SplitScreenManager {
  private static splitScreenManager: SplitScreenManager;
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  private windowStatusType = window.WindowStatusType.UNDEFINED;
  private isTabletDevice: null | boolean = null;
  public isPhoneDevice: null | boolean = null;
  public orientation = display.Orientation.PORTRAIT;

  public fullScreenHeight: number = 0;
  public fullScreenWidth: number = 0;

  /**
   * create splite screen manager
   *
   * @returns {Object} - SplitScreenManager object
   */
  public static getInstance(): SplitScreenManager {
    if (!SplitScreenManager.splitScreenManager) {
      SplitScreenManager.splitScreenManager = new SplitScreenManager();
    }
    return SplitScreenManager.splitScreenManager;
  }

  getWindowWidth(): number {
    return this.screenWidth;
  }

  isTablet(): boolean {
    if (this.isTabletDevice === null) {
      this.isTabletDevice = isTablet();
    }
    return this.isTabletDevice;
  }

  updateWindowStatusType(type: WindowStatusType) {
    LogUtils.i(TAG, 'updateWindowStatusType ' + type);
    this.windowStatusType = type;
  }

  updateScreenSize(width: number, height: number) {
    LogUtils.i(TAG, `updateScreenSize width：${width}`);
    this.screenWidth = width;
    this.screenHeight = height;
    let displayInfo = CallColumnUtils.getInstance().display;
    if (displayInfo !== undefined) {
      this.fullScreenWidth = displayInfo.width;
      this.fullScreenHeight = displayInfo.height;
      this.orientation = displayInfo.orientation;
    }

    let splitScreenType: SplitScreenType = this.getSplitScreenType();
    AppStorage.setOrCreate('SplitScreenType', splitScreenType);
    AppStorage.setOrCreate('SplitScreenHeight', this.screenHeight);
    if (splitScreenType > SplitScreenType.DEFAULT && ScreenAdapterUtils.isNewFoldPhone && !this.isLandscape()) {
      // 新折叠竖屏分屏模式-仅内屏支持,外屏不支持分屏
      AppStorage.setOrCreate('newFoldSplitPortraitScreenType', splitScreenType);
      LogUtils.i(TAG, `newFoldSplitPortraitScreenType splitScreenType:${splitScreenType}`);
    } else {
      AppStorage.setOrCreate('newFoldSplitPortraitScreenType', SplitScreenType.DEFAULT);
      LogUtils.i(TAG, `newFoldSplitPortraitScreenType DEFAULT`);
    }
  }

  isSpliteStatus(): boolean {
    if (this.windowStatusType == window.WindowStatusType.SPLIT_SCREEN) {
      return true;
    }
    return false;
  }

  isTableSplitScreen(): boolean {
    if (this.isTablet() &&
      this.windowStatusType == window.WindowStatusType.SPLIT_SCREEN) {
      return true;
    }
    return false;
  }

  public isPhone(): boolean {
    if (this.isPhoneDevice === null) {
      this.isPhoneDevice = isPhone();
    }
    return this.isPhoneDevice;
  }

  public isLandscape(): boolean {
    LogUtils.i(TAG, `isLandscape ${this.orientation}`);
    if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
      TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
      return true;
    }
    return false;
  }

  isIncomingSpliteScreenMedium(height?: number): boolean {
    LogUtils.i(TAG, `isIncomingSpliteScreenMedium height: ${height}`);
    let type = this.getSplitScreenType();
    if (this.isPhone() && DisplayUtil.isFoldable() && this.isLandscape() && type === SplitScreenType.MEDIUM) {
      LogUtils.i(TAG, `isIncomingSpliteScreenMedium type: ${type}`);
      return true;
    }
    return false;
  }

  getSplitScreenType(): SplitScreenType {
    if (this.fullScreenWidth <= 0 || this.fullScreenHeight <= 0) {
      return SplitScreenType.DEFAULT;
    }
    // full screen
    if (this.screenWidth === this.fullScreenWidth &&
      this.screenHeight === this.fullScreenHeight) {
      LogUtils.i(TAG, `getSplitScreenType DEFAULT`);
      return SplitScreenType.DEFAULT;
    }
    if (this.windowStatusType == window.WindowStatusType.SPLIT_SCREEN && !isTwoInOne()) {
      // newFormFoldPhone
      if (ScreenAdapterUtils.isNewFoldPhone) {
        LogUtils.i(TAG, `getSplitScreenType isNewFormFoldPhone`);
        return this.getIphoneSplitScreenType();
      }
      // tablet
      if (this.isTablet()) {
        LogUtils.i(TAG, `getSplitScreenType tablet`);
        return this.getIpadSplitScreenType();
      }
      // foldable expanded
      if (DisplayUtil.isFoldable()) {
        LogUtils.i(TAG, `getSplitScreenType foldable`);
        return this.getFoldableSplitScreenType();
      }
      // landscape
      LogUtils.i(TAG, `getSplitScreenType landscape`);
      return this.getIphoneSplitScreenType();
    }
    LogUtils.i(TAG, `getSplitScreenType no SPLIT_SCREEN`);
    return SplitScreenType.DEFAULT;
  }

  // Foldable
  public getFoldableSplitScreenType(): SplitScreenType {
    if (this.fullScreenHeight <= 0) {
      return SplitScreenType.DEFAULT;
    }
    return this.calculateSplitScreenType();
  }


  // Tablet
  public getIpadSplitScreenType(): SplitScreenType {
    return this.calculateSplitScreenType();
  }

  // iphone
  public getIphoneSplitScreenType(): SplitScreenType {
    if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
      TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
      return SplitScreenType.MEDIUM;
    }
    return this.calculateSplitScreenType();
  }

  // Calculate screen-to-body ratio
  public calculateSplitScreenType(): SplitScreenType {
    if (this.fullScreenHeight <= 0) {
      return SplitScreenType.DEFAULT;
    }
    let scale = this.screenHeight / this.fullScreenHeight;
    if (scale < ONE_THREE && scale > 0) {
      return SplitScreenType.SMALL;
    } else if (scale < ONE_HALF && scale > ONE_THREE) {
      return SplitScreenType.MEDIUM;
    } else if (scale < TWO_THREE && scale > ONE_HALF) {
      return SplitScreenType.BIG;
    } else {
      return SplitScreenType.DEFAULT;
    }
  }
}
