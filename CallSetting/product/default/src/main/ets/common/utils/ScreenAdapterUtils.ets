/*
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

import { display } from '@kit.ArkUI';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { DisplayUtil } from './DisplayUtil';
import { LogUtils, Constants } from '@ohos/common/CommonIndex';
import { isTablet } from './DeviceTypeUtils';
import Display from '@ohos.display';


const TAG = 'ScreenAdapterUtils';

export enum FoldPhoneTypeValue {
  /**
   * 无效值
   */
  INVALID_VALUE = -1,
  /**
   * 直板机
   */
  STRAIGHT = 0,
  /**
   * 大折（内折）: X5
   */
  LARGE_FOLD = 1,
  /**
   * 小折叠（只有内折）: pocket
   */
  SMALL_FOLD = 2,
  /**
   * 外折: XS2
   */
  EXTERNAL_FOLD = 3,
  /**
   * 扩展新形态
   */
  EXPANDING_NEW_FORM = 4,
  /**
   * 三折叠
   */
  TRIFOLD = 6,
}

/**
 * class SplitScreenManager
 */
export default class ScreenAdapterUtils {
  private static sScreenAdapterUtils: ScreenAdapterUtils;

  public static isNewFoldPhone: boolean = ScreenAdapterUtils.isNewFormFoldPhone();

  public static getInstance(): ScreenAdapterUtils {
    if (ScreenAdapterUtils.sScreenAdapterUtils == null) {
      ScreenAdapterUtils.sScreenAdapterUtils = new ScreenAdapterUtils();
    }
    return ScreenAdapterUtils.sScreenAdapterUtils;
  }

  public static getFoldablePhoneProductType(): number {
    let foldTypeConfiguration = '';
    try {
      foldTypeConfiguration = systemParameterEnhance.
        getSync(Constants.FOLD_PRODUCT_TYPE_KEY, Constants.DEFAULT_FOLD_CONFIGURATION);
      LogUtils.i(TAG, `get foldTypeConfiguration:${foldTypeConfiguration}`);
      const result = foldTypeConfiguration.split(',');
      if (Array.isArray(result) && result.length > 0) {
        const foldType = Number(result[0]);
        return foldType;
      }
    } catch (err) {
      LogUtils.e(TAG, `get foldTypeConfiguration err:${err?.code}`);
    }

    return FoldPhoneTypeValue.INVALID_VALUE;
  }

  /**
   * 判断是否为扩展折叠产品
   */
  public static isNewFormFoldPhone(): boolean {
    return ScreenAdapterUtils.getFoldablePhoneProductType() === FoldPhoneTypeValue.EXPANDING_NEW_FORM;
  }

  public static isSmallFoldPhone(): boolean {
    return ScreenAdapterUtils.getFoldablePhoneProductType() === FoldPhoneTypeValue.SMALL_FOLD;
  }

  public isNewFoldPhoneExternalScreen(): boolean {
    LogUtils.i(TAG,
      `isNewFormFoldPhone:${ScreenAdapterUtils.isNewFormFoldPhone()},FoldStatus:${DisplayUtil.getScreenFoldStatus()}`);
    const result = ScreenAdapterUtils.isNewFormFoldPhone() &&
      DisplayUtil.getScreenFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
    LogUtils.i(TAG, `isNewFoldPhoneExternalScreen: ${result}`);
    return result;
  }

  public isNewFoldPhoneInnerScreen() {
    const result = ScreenAdapterUtils.isNewFormFoldPhone() &&
      DisplayUtil.getScreenFoldStatus() !== display.FoldStatus.FOLD_STATUS_FOLDED;
    LogUtils.i(TAG, `isNewFoldPhoneInnerScreen: ${result}`);
    return result;
  }

  /**
   * 判断是否为三折叠产品
   */
  public static isTrifoldPhone(): boolean {
    return ScreenAdapterUtils.getFoldablePhoneProductType() === FoldPhoneTypeValue.TRIFOLD;
  }

  /**
   * 是否为设置分栏设备
   *
   * @returns true是，false不是
   */
  public static isSettingSplitProduct(): boolean {
    return isTablet() || ScreenAdapterUtils.isFoldButNotSmallFoldProduct();
  }

  /**
   * 是否为非小折叠的折叠机产品（非小内折）
   *
   * @returns true是，false不是
   */
  static isFoldButNotSmallFoldProduct(): boolean {
    return DisplayUtil.isFoldable() &&
      (!ScreenAdapterUtils.isSmallFoldPhone() && !ScreenAdapterUtils.isNewFormFoldPhone());
  }

  /**
   * 解除折叠屏监听
   */
  public static unRegisterFoldStatusChange(callback: (state: number) => void): void {
    if (!callback) {
      return;
    }
    try {
      Display.off('foldStatusChange', callback);
    } catch (err) {
      LogUtils.e(TAG, `unregister foldStatusChange: code: ${err?.code} message: ${err?.message}`);
    }
  }

  /**
   * 注册折叠屏监听
   */
  public static registerFoldStatusChange(callback: (state: number) => void): void {
    if (!callback) {
      return;
    }
    try {
      Display.on('foldStatusChange', callback);
    } catch (err) {
      LogUtils.e(TAG, `register foldStatusChange: code: ${err?.code} message: ${err?.message}`);
    }
  }
}