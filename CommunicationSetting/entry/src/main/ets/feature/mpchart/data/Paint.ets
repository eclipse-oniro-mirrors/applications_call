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

export default class Paint {
  public styleType: Style = Style.FILL_AND_STROKE;
  public globalAlpha: number | undefined = undefined;
  public fillStyle: string | number | CanvasGradient | CanvasPattern = Color.White;
  public strokeStyle: string | number | CanvasGradient | CanvasPattern = Color.Black;
  public lineWidth: number = 1;
  public fontStyle: FontStyleType = 'normal';
  public fontWeight: FontWeightType = 'normal';
  public fontSize: number = 14;
  public fontSizeUnit: FontSizeUnit = 'vp';
  public fontFamily: FontFamily = '';
  public font: string = 'normal normal 14vp '
  public textAlign: CanvasTextAlign = 'left';
  public textBaseline: CanvasTextBaseline = 'alphabetic';
  public dashPathEffect: DashPathEffect | null = null;


  public setColor(color: string | number | CanvasGradient | CanvasPattern) {
    this.fillStyle = color;
    this.strokeStyle = color;
  }

  public setStyle(styleType: Style) {
    this.styleType = styleType;
  }

  public getStyle(): Style {
    return this.styleType;
  }

  public setGlobalAlpha(alpha: number) {
    this.globalAlpha = alpha;
  }

  public setStrokeWidth(lineWidth: number) {
    this.lineWidth = lineWidth;
  }

  public setTextSize(textSize: number, textSizeUnit?: FontSizeUnit): void {
    this.fontSize = textSize;
    if (textSizeUnit) {
      this.fontSizeUnit = textSizeUnit;
    }
    this.font =
      this.fontStyle + ' ' + this.fontWeight + ' ' + this.fontSize + this.fontSizeUnit + ' ' + this.fontFamily;
  }

  public setFontFamily(fontFamily: FontFamily): void {
    this.fontFamily = fontFamily;
    this.font =
      this.fontStyle + ' ' + this.fontWeight + ' ' + this.fontSize + this.fontSizeUnit + ' ' + this.fontFamily;
  }

  public setTextAlign(textAlign: CanvasTextAlign) {
    this.textAlign = textAlign;
  }

  public getTextAlign(): CanvasTextAlign {
    return this.textAlign;
  }

  public setTextBaseline(textBaseline: CanvasTextBaseline) {
    this.textBaseline = textBaseline;
  }

  public getTextBaseline(): CanvasTextBaseline {
    return this.textBaseline;
  }

  public setDashPathEffect(dashEffect: DashPathEffect | null) {
    this.dashPathEffect = dashEffect;
  }

  public getDashPathEffect(): DashPathEffect | null {
    return this.dashPathEffect;
  }
}

export enum Style {
  FILL,
  STROKE,
  FILL_AND_STROKE
}

export type FontStyleType = 'normal' | 'italic';

export type FontWeightType = 'normal' | 'bold' | 'bolder' | 'lighter' | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900;

export type FontSizeUnit = 'px' | 'vp';

export type FontFamily = 'sans-serif' | 'serif' | 'monospace' | '';

export class DashPathEffect {
  public dash: number[];
  public offset: number

  constructor(dash: number[], offset: number) {
    this.dash = dash;
    this.offset = offset;
  }
}