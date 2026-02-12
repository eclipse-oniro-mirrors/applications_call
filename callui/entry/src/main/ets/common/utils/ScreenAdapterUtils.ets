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
import LogUtils from './LogUtils';
import { DEFAULT_FOLD_CONFIGURATION, FOLD_PRODUCT_TYPE_KEY, } from '../utils/Constants'
import SplitScreenManager from '../../model/SplitScreenManager';


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

export default class ScreenAdapterUtils {
  private static sScreenAdapterUtils: ScreenAdapterUtils;
  private fold2ScreenFormMap = new Map<number, number>([
    [0, 0],
    [1, 0],
    [2, 2],
    [3, 1],
    [4, 0]
  ]);
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
      foldTypeConfiguration = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE_KEY, DEFAULT_FOLD_CONFIGURATION);
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

  /**
   * 判断是否为新三折叠产品
   */
  public static isNewThreeFoldPhone(): boolean {
    const foldTypeConfiguration = systemParameterEnhance.getSync('const.system.sensor_correction_enable', '');
    LogUtils.i(TAG, `get foldTypeNewThreeFold is: ${foldTypeConfiguration}`);
    return foldTypeConfiguration === '1';
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

  public getParticleLayoutBottomBtnWidth(isNewFoldPhoneExternalScreen: boolean): Resource {
    return isNewFoldPhoneExternalScreen ? $r('app.float.new_form_fold_phone_particle_layout_hangup_btn_width') :
    $r('app.float.call_button_width');
  }

  public getParticleLayoutBottomBtnSymbolWidth(isNewFoldPhoneExternalScreen: boolean): Resource {
    return isNewFoldPhoneExternalScreen ? $r('app.float.new_form_fold_phone_particle_layout_hangup_symbol_width') :
    $r('app.float.answer_button_image_width');
  }

  public getFuncBtnWidth(isNewFoldPhoneExternalScreen: boolean): Resource {
    return isNewFoldPhoneExternalScreen ? $r('app.float.new_form_fold_phone_func_btn_width') :
    $r('app.float.call_button_width');
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
      default:
        break;
    }
    return screenForm;
  }

  /**
   * 判断是否为三折叠产品
   */
  public static isTrifoldPhone(): boolean {
    return ScreenAdapterUtils.getFoldablePhoneProductType() === FoldPhoneTypeValue.TRIFOLD;
  }

  /**
   * 判断新折叠是否需要把视频画面铺满全屏
   * @param screenAspectRatio 屏幕宽高比
   * @param isVideoRbt 是否视频彩铃画面
   * @returns 是否铺满全屏
   */
  public static isNeedExpandXComponentToFullScreen(screenAspectRatio: number, isVideoRbt: boolean): boolean {
    try {
      let isNeedExpandXComponentToFullScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneInnerScreen() &&
        screenAspectRatio > 0 && screenAspectRatio < 1 && isVideoRbt &&
        !SplitScreenManager.getInstance().isSplitScreenStatus();
      return isNeedExpandXComponentToFullScreen;
    } catch (err) {
      LogUtils.e(TAG, `isNeedExpandXComponentToFullScreen err:${err?.code}`);
      return false;
    }
  }

}