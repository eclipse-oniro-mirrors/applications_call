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
import Paint, { Style } from '../data/Paint'
import Highlight from '../highlight/Highlight'
import HashMap from '@ohos.util.HashMap'

export default abstract class Utils {
  public static offCanvasContext2d: OffscreenCanvasRenderingContext2D =
    new OffscreenCanvasRenderingContext2D(500, 500, new RenderingContextSettings(true));

  public static handleDataValues(dp: number): number {
    return dp;
  }

  public static getLabelTextSize(paint: Paint, text: string, textSizeCache: HashMap<string, TextMetrics>): TextMetrics {
    const font = paint.font;
    const textSizeTemp = textSizeCache.get(text + font);
    if (textSizeTemp) {
      return textSizeTemp;
    } else {
      Utils.offCanvasContext2d.font = paint.font;
      if (text === undefined || text === null) {
        text = '';
      }
      const textSize: TextMetrics = Utils.offCanvasContext2d.measureText(text);
      textSizeCache.set(text + font, textSize);
      return textSize;
    }
  }

  public static roundToNextSignificant(number: number): number {
    if (number == Number.MAX_VALUE || Number.isNaN(number) || number == 0.0) {
      return 0;
    }
    const d: number = Math.ceil(Math.log10(number < 0 ? -number : number));
    const pw: number = 1 - Math.floor(d);
    const magnitude: number = Math.pow(10, pw);
    const shifted: number = Math.round(number * magnitude);
    return shifted / magnitude;
  }

  public static getDecimals(number: number): number {
    let i: number = Utils.roundToNextSignificant(number);
    if (i == Number.MAX_VALUE) {
      return 0;
    }
    return Math.floor(Math.ceil(-Math.log10(i)) + 2);
  }

  public static nextUp(d: number): number {
    if (d == Number.MAX_VALUE) {
      return d;
    } else {
      d += 0.0;
      return d += 0.000000001;
    }
  }

  public static resetContext2DWithoutLine(context2D: CanvasRenderer, paint: Paint) {
    Utils.resetContext2DColorAndAlpha(context2D, paint);
    context2D.font = paint.font;
    context2D.textAlign = paint.textAlign;
    context2D.textBaseline = paint.textBaseline;
  }

  public static resetContext2DWithoutFont(context2D: CanvasRenderer, paint: Paint) {
    Utils.resetContext2DColorAndAlpha(context2D, paint);
    context2D.lineWidth = paint.lineWidth;
    let dashEffect = paint.getDashPathEffect();
    if (dashEffect) {
      context2D.setLineDash(dashEffect.dash);
      context2D.lineDashOffset = dashEffect.offset;
    } else {
      context2D.setLineDash([]);
    }
  }

  public static resetContext2DColorAndAlpha(context2D: CanvasRenderer, paint: Paint) {
    switch (paint.styleType) {
      case Style.FILL:
        context2D.fillStyle = paint.fillStyle;
        break;
      case Style.STROKE:
        context2D.strokeStyle = paint.strokeStyle;
        break;
      case Style.FILL_AND_STROKE:
      default:
        context2D.fillStyle = paint.fillStyle;
        context2D.strokeStyle = paint.strokeStyle;
        break;
    }
    if (paint.globalAlpha !== undefined) {
      context2D.globalAlpha = paint.globalAlpha;
    } else {
      context2D.globalAlpha = 1;
    }
  }

  public static parseInt(num: number): number {
    let stringNum = String(num);
    if (stringNum.includes('.')) {
      let numArr = stringNum.split('.');
      return Number(numArr[0]);
    }
    return num;
  }

  public static isHighLightEquals(highLight1: Highlight | null, highLight2: Highlight | null): boolean {
    if (highLight1 == undefined && highLight2 == undefined) {
      return true;
    }
    if (highLight1 == null && highLight2 == null) {
      return true;
    }
    if (highLight1 && highLight2) {
      return highLight1.getX() == highLight2.getX() && highLight1.getY() == highLight2.getY() &&
        highLight1.getStackIndex() == highLight2.getStackIndex();
    } else {
      return false;
    }
  }

  public static fillRoundedRect(c: CanvasRenderingContext2D, left: number, top: number, width: number, height: number,
    radius: number, cornerType: RoundCornerType = 'up') {
    if (width == 0 || height == 0) {
      return;
    }
    if (width > height && radius >= width / 2) {
      switch (cornerType) {
        case 'down':
          c.moveTo(left, top);
          c.arc(left + width / 2, top, width / 2, 0, Math.PI, false);
          c.lineTo(left, top);
          break;
        case 'both':
          c.arc(left + width / 2, top + height / 2, width / 2, 0, Math.PI * 2);
          break;
        case 'up':
          c.moveTo(left, top + height);
          c.arc(left + width / 2, top + height, width / 2, 0, Math.PI, true);
          c.lineTo(left, top + height);
          break;
      }
      return;
    }
    // 避免宽度或高度小于 radius 时绘制异常，需要比较 width 和 height 最小值
    const min = Math.min(width, height)
    if (radius > min / 2) {
      radius = min / 2;
    }
    switch (cornerType) {
      case 'down':
        c.moveTo(left, top)
        c.lineTo(left + width, top)
        c.arcTo(left + width, top + height, left, top + height, radius)
        c.lineTo(left + radius, top + height)
        c.arcTo(left, top + height, left, top, radius)
        break
      case 'both':
        c.moveTo(left + radius, top);
        c.arcTo(left + width, top, left + width, top + height, radius);
        c.arcTo(left + width, top + height, left, top + height, radius)
        c.arcTo(left, top + height, left, top, radius)
        c.arcTo(left, top, left + radius, top, radius)
        break
      case 'up':
      default:
        c.moveTo(left + radius, top);
        c.arcTo(left + width, top, left + width, top + height, radius);
        c.lineTo(left + width, top + height);
        c.lineTo(left, top + height);
        c.arcTo(left, top, left + width, top, radius);
        break
    }
  }

  public static drawRect(isDrawRounded: boolean, c: CanvasRenderingContext2D, paint: Paint, left: number, top: number,
    right: number, bottom: number, radius: number, isFill: boolean, cornerType: RoundCornerType = 'up'): void {
    if (left - right == 0 || top - bottom == 0) {
      return;
    }
    Utils.resetContext2DWithoutFont(c, paint);
    c.beginPath();
    if (isDrawRounded && radius != 0) {
      Utils.fillRoundedRect(c, left, top, right - left, bottom - top, radius, cornerType);
    } else {
      c.rect(left, top, right - left, bottom - top);
    }
    if (isFill) {
      c.fill();
    } else {
      c.stroke();
    }
    c.closePath();
  }
  public static rgb(r: number, g: number, b: number): number {
    return (r << 16) | (g << 8) | b;
  }
}

export type RoundCornerType = 'up' | 'down' | 'both'
