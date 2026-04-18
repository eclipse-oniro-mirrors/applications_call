/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import LogUtils from './HiLog';
import {
  DEFAULT_FOLD_CONFIGURATION,
  FOLD_PRODUCT_TYPE_KEY,
  PRODUCT_TYPE_KEY
} from '../utils/Constants'


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
   * 大折（内折）
   */
  LARGE_FOLD = 1,
  /**
   * 小折叠（只有内折）
   */
  SMALL_FOLD = 2,
  /**
   * 外折
   */
  EXTERNAL_FOLD = 3,
  /**
   * 扩展新形态
   */
  EXPANDING_NEW_FORM = 4,
  /**
   * 三折叠
   */
  EXPANDING_NEW_FORM_THREE = 6,
}

export default class ScreenAdapterUtils {
  private static sScreenAdapterUtils: ScreenAdapterUtils;
  private fold2ScreenFormMap = new Map<number, number>([
    [0, 0],
    [1, 0],
    [2, 2],
    [3, 1],
    [4, 0]
  ]);
  public static sIsPsd: boolean = ScreenAdapterUtils.getProductType() === 'PSD';

  public static getInstance(): ScreenAdapterUtils {
    if (ScreenAdapterUtils.sScreenAdapterUtils == null) {
      ScreenAdapterUtils.sScreenAdapterUtils = new ScreenAdapterUtils();
    }
    return ScreenAdapterUtils.sScreenAdapterUtils;
  }

  public static getFoldablePhoneProductType(): number {
    try {
      const foldTypeConfiguration:ESObject = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE_KEY, DEFAULT_FOLD_CONFIGURATION);
      LogUtils.i(TAG, `get foldTypeConfiguration:${foldTypeConfiguration}`);
      const result:ESObject = foldTypeConfiguration.split(',');
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

  public isNewFoldPhoneExternalScreen(): boolean {
    LogUtils.i(TAG,
      `isNewFormFoldPhone:${ScreenAdapterUtils.isNewFormFoldPhone()},FoldStatus:${DisplayUtil.getScreenFoldStatus()}`);
    const result = ScreenAdapterUtils.isNewFormFoldPhone() &&
      DisplayUtil.getScreenFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
    LogUtils.i(TAG, `isNewFoldPhoneExternalScreen: ${result}`);
    return result;
  }

  /**
   * 判断是否为三折叠产品
   */
  private static isThreeFoldPhone(): boolean {
    return ScreenAdapterUtils.getFoldablePhoneProductType() === FoldPhoneTypeValue.EXPANDING_NEW_FORM_THREE;
  }

  /**
   * 判断三折叠产品并且处于折叠状态
   */
  public isThreeFoldPhoneExternalScreen(): boolean {
    LogUtils.i(TAG,
      `isThreeFoldPhone:${ScreenAdapterUtils.isThreeFoldPhone()},FoldStatus:${DisplayUtil.getScreenFoldStatus()}`);
    const result = ScreenAdapterUtils.isThreeFoldPhone() &&
      DisplayUtil.getScreenFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
    LogUtils.i(TAG, `isThreeFoldPhoneExternalScreen: ${result}`);
    return result;
  }

  /**
   * 获取屏幕形态，新形态展开40,半折叠41,完全折叠42
   */
  public getScreenForm(): number {
    let productType = ScreenAdapterUtils.getFoldablePhoneProductType();
    let screenForm = 0;
    switch (productType) {
      case -1:
      case 0:
        break;
      case 1:
      case 2:
      case 3:
      case 4:
        let fold = this.fold2ScreenFormMap.get(DisplayUtil.getScreenFoldStatus()) ?? 0;
        screenForm = Number(productType + '' + fold);
        break;
      case 6:
        let folding = DisplayUtil.getScreenFoldStatus();
        screenForm = Number(productType + '' + folding);
        break;
      default:
        break;
    }
    return screenForm;
  }

  /**
   * Check whether the device is small external device like LEM
   *
   * @returns { boolean } true means the device is external fold device like LEM.
   */
  public static isSmallExternalDeviceAndFoldStatus(): boolean {
    return ScreenAdapterUtils.getFoldablePhoneProductType() === FoldPhoneTypeValue.SMALL_FOLD &&
      DisplayUtil.getScreenFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
  }

  public static getProductType(): string {
    let prodType = '';
    try {
      prodType = systemParameterEnhance.getSync(PRODUCT_TYPE_KEY, '');
    } catch (err) {
      LogUtils.e(TAG, `get ${PRODUCT_TYPE_KEY} err:${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, `getProductType : ` + prodType);
    return prodType;
  }
}
