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
import LogUtils from './LogUtils';

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
  /**
   * update font scale
   */
  public static updateAppFontGearSize(scale?: number): void {
    let fontScale: number = scale ?? 1;
    if (fontScale >= FontScale.Standard && fontScale < FontScale.FourthGear) {
      FontScaleState.topAndBottomMarginOnScale = '13vp';
    } else if (fontScale >= FontScale.FourthGear && fontScale < FontScale.FifthGear) {
      FontScaleState.topAndBottomMarginOnScale = '16vp';
    } else if (fontScale >= FontScale.FifthGear && fontScale < FontScale.SeventhGear) {
      FontScaleState.topAndBottomMarginOnScale = '20vp';
    } else if (fontScale >= FontScale.SeventhGear) {
      FontScaleState.topAndBottomMarginOnScale = '24vp';
    } else {
      FontScaleState.topAndBottomMarginOnScale = '13vp';
    }
    LogUtils.i(TAG, 'fontSizeScaleMargin = ' + FontScaleState.topAndBottomMarginOnScale);
    AppStorage.setOrCreate('fontSizeScaleMargin', FontScaleState.topAndBottomMarginOnScale);
  }
}