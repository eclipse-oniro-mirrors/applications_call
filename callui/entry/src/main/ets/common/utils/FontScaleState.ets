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

import LogUtils from './LogUtils';
/**
 * 长辈关怀模式，不同组件支持的最大放大倍数
 */
export enum MaxScaleTypeEnum {
  DEFAULT = 0,
  BUTTON_TEXT = 1,
  DIALOG_TEXT = 2,
};

const TAG: string = 'FontScaleState';

export enum FontScale {
  Standard = 1,
  FirstGear = 1.15,
  SecondGear = 1.3,
  ThirdGear = 1.45,
  FourthGear = 1.75,
  FifthGear = 2,
  SixthGear = 2.25
}

export class FontScaleState {
  public static topAndBottomMarginOnScale = '0vp';
  // 合一编辑器最大放大倍率
  public static callMaxScale: number = 3.2;
  public static defaultMaxScale: number = 1;
  public static buttonMaxScale: number = 1.45;
  public static dialogTextMaxScale: number = 1.75;
  public static popTipsMaxScale: number = 2;
  public static bottomBtnTextMaxScale: number = 1.35;
  /**
   * 更新字体档数
   */
  public static updateAppFontGearSize(scale?: number): void {
    let fontScale: number = scale ?? 1;
    if (fontScale >= FontScale.Standard && fontScale < FontScale.FourthGear) {
      FontScaleState.topAndBottomMarginOnScale = '13vp';
    } else if (fontScale >= FontScale.FourthGear && fontScale < FontScale.FifthGear) {
      FontScaleState.topAndBottomMarginOnScale = '16vp';
    } else if (fontScale >= FontScale.FifthGear && fontScale < FontScale.SixthGear) {
      FontScaleState.topAndBottomMarginOnScale = '20vp';
    } else if (fontScale >= FontScale.SixthGear) {
      FontScaleState.topAndBottomMarginOnScale = '24vp';
    } else {
      FontScaleState.topAndBottomMarginOnScale = '13vp';
    }
    LogUtils.i(TAG, 'fontSizeScaleMargin = ' + FontScaleState.topAndBottomMarginOnScale);
    AppStorage.setOrCreate('fontSizeScaleMargin', FontScaleState.topAndBottomMarginOnScale);
  }

  /**
   * 系统fp字体扩大倍数
   */
  public fontSizeScale: number = 1;

  /**
   * 获取字体放大倍数（PopTips限制在2倍）
   */
  public getFontScaleForTips(): number {
    return Math.min(FontScaleState.popTipsMaxScale, this.fontSizeScale);
  }
}