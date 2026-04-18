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
import { LogUtil } from './LogUtil'
import { BusinessError } from '@kit.BasicServicesKit'
import { GlobalContext } from '../entryability/CommunicationSettingAbility'
import myCommon from '@ohos.app.ability.common';

const TAG = 'ChartColorModeUtil';

/**
 * 0：坐标轴文本颜色
 * 1：网格线颜色
 * 2：坐标轴的颜色
 * 3：柱形条选中高亮颜色
 * 4：柱形条颜色
 **/
export enum ChartColorCategory {
  CATEGORY_CHARTTEXT = 0,
  CATEGORY_GRID = 1,
  CATEGORY_AXISLINE = 2,
  CATEGORY_COLUMNCHARTHIGHT = 3,
  CATEGORY_COLUMNCHART = 4
}

/**
 * 获取柱形图颜色
 * @param category 要获取颜色设置的类别
 */
export function getChartColor(category: ChartColorCategory): number {
  let color: number = 0;
  switch (category) {
    case ChartColorCategory.CATEGORY_CHARTTEXT:
      color = getSystemColor($r('sys.color.font_tertiary'));
      break;
    case ChartColorCategory.CATEGORY_GRID:
      color = getSystemColor($r('sys.color.comp_background_secondary'));
      break;
    case ChartColorCategory.CATEGORY_AXISLINE:
      color = getSystemColor($r('sys.color.comp_background_secondary'));
      break;
    case ChartColorCategory.CATEGORY_COLUMNCHARTHIGHT:
      color = getSystemColor($r('sys.color.icon_emphasize'));
      break;
    case ChartColorCategory.CATEGORY_COLUMNCHART:
      color = getSystemColor($r('sys.color.icon_emphasize'));
      break;
  }
  return color;
}

export function getSystemColor(colorResource: Resource) {
  let color: number = 0;
  try {
    let context = (GlobalContext.getContext().getObject('rankPageContext') as myCommon.UIAbilityContext);
    color = context.resourceManager.getColorSync(colorResource.id);
  } catch (error) {
    let code = (error as BusinessError).code;
    let message = (error as BusinessError).message;
    LogUtil.error(TAG, `getColorSync failed, error code: ${code}, message: ${message}.`);
  }
  return color;
}
