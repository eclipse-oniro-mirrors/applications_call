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
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG: string = 'FontScaleState';

export enum FontScale {
  Standard = 1,
  FirstGear = 1.15,
  SecondGear = 1.3,
  ThirdGear = 1.45,
  FourthGear = 1.75,
  FifthGear = 2,
  SixthGear = 2.25,
  SeventhGear = 3.2
}


export class FontScaleState {
  public static topAndBottomMarginOnScale = '0vp';
  public static twoLineTopMarginOnScal = '10vp';
  public static twoLineBottomMarginOnScal = '11vp';
  // 合一编辑器最大放大倍率
  public static buttonMaxScale: number = 1.45;
  public static popTipsMaxScale: number = 2;
  /**
   * 系统fp字体扩大倍数
   */
  public fontSizeScale: number = 1;

  /**
   * update font scale
   */
  public static updateAppFontGearSize(scale?: number): void {
    let fontScale: number = scale ?? 1;
    if (fontScale >= FontScale.Standard && fontScale < FontScale.FourthGear) {
      FontScaleState.topAndBottomMarginOnScale = '13vp';
      FontScaleState.twoLineTopMarginOnScal = '10vp';
      FontScaleState.twoLineBottomMarginOnScal = '11vp';
    } else if (fontScale >= FontScale.FourthGear && fontScale < FontScale.FifthGear) {
      FontScaleState.topAndBottomMarginOnScale = '16vp';
      FontScaleState.twoLineTopMarginOnScal = '16vp';
      FontScaleState.twoLineBottomMarginOnScal = '16vp';
    } else if (fontScale >= FontScale.FifthGear && fontScale < FontScale.SeventhGear) {
      FontScaleState.topAndBottomMarginOnScale = '20vp';
      FontScaleState.twoLineTopMarginOnScal = '20vp';
      FontScaleState.twoLineBottomMarginOnScal = '20vp';
    } else if (fontScale >= FontScale.SeventhGear) {
      FontScaleState.topAndBottomMarginOnScale = '24vp';
      FontScaleState.twoLineTopMarginOnScal = '24vp';
      FontScaleState.twoLineBottomMarginOnScal = '24vp';
    } else {
      FontScaleState.topAndBottomMarginOnScale = '13vp';
      FontScaleState.twoLineTopMarginOnScal = '10vp';
      FontScaleState.twoLineBottomMarginOnScal = '11vp';
    }
    LogUtils.i(TAG, 'updateAppFontGearSize' + FontScaleState.topAndBottomMarginOnScale);
    AppStorage.setOrCreate('fontSizeScale', fontScale);
    AppStorage.setOrCreate('fontSizeScaleMargin', FontScaleState.topAndBottomMarginOnScale);
    AppStorage.setOrCreate('topMarginOnScal', FontScaleState.twoLineTopMarginOnScal);
    AppStorage.setOrCreate('bottomMarginOnScal', FontScaleState.twoLineBottomMarginOnScal);
  }

  /**
   * 获取字体放大倍数（PopTips限制在2倍）
   */
  public getFontScaleForTips(): number {
    return Math.min(FontScaleState.popTipsMaxScale, this.fontSizeScale);
  }
}