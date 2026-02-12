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
import { DEFAULT_FOLD_CONFIGURATION, FOLD_PRODUCT_TYPE_KEY } from '../constants/CommonConstants';
import { DisplayUtils } from './DisplayUtils';
import { LogUtil } from './LogUtil';


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
  public static getFoldablePhoneProductType(): number {
    let foldTypeConfiguration = '';
    try {
      foldTypeConfiguration = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE_KEY, DEFAULT_FOLD_CONFIGURATION);
      LogUtil.info(TAG, `get foldTypeConfiguration:${foldTypeConfiguration}`);
      const result = foldTypeConfiguration.split(',');
      if (Array.isArray(result) && result.length > 0) {
        const foldType = Number(result[0]);
        return foldType;
      }
    } catch (err) {
      LogUtil.error(TAG, `get foldTypeConfiguration err:${err?.code}`);
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
}