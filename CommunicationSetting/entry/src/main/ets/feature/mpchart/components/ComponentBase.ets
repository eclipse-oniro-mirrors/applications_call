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

import { FontFamily } from '../data/Paint';

export default abstract class ComponentBase {
  protected xOffset: number = 5;
  public yOffset: number = 5;
  protected typeface: FontFamily = '';
  public textSize: number = 10;
  protected textColor: string | number | CanvasGradient | CanvasPattern = Color.Black;

  public getXOffset(): number {
    return this.xOffset;
  }

  public getYOffset(): number {
    return this.yOffset;
  }

  public getTypeface(): FontFamily {
    return this.typeface;
  }

  public setTextSize(size: number): void {
    if (size > 48) {
      size = 48;
    }
    if (size < 6) {
      size = 6;
    }
    this.textSize = size;
  }

  public getTextSize(): number {
    return this.textSize;
  }

  public setTextColor(color: string | number | CanvasGradient | CanvasPattern): void {
    this.textColor = color;
  }

  public getTextColor(): string | number | CanvasGradient | CanvasPattern {
    return this.textColor;
  }
}
