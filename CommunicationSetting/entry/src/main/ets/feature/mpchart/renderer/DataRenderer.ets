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

import Highlight from '../highlight/Highlight';
import Paint, { Style } from '../data/Paint';
import ViewPortHandler from '../utils/ViewPortHandler';
import ChartInterface from '../interfaces/dataprovider/ChartInterface';
import Utils from '../utils/Utils';
import { IAxisValueFormatter } from '..';

export default abstract class DataRenderer {
  protected renderPaint: Paint = new Paint();
  protected highlightPaint: Paint = new Paint();
  public valuePaint: Paint = new Paint();
  private getMaxVisibleCount = 40;
  protected viewPortHandler: ViewPortHandler | null = null;

  constructor( viewPortHandler: ViewPortHandler) {
    if (viewPortHandler) {
      this.viewPortHandler = viewPortHandler;
    }
    this.renderPaint = new Paint();
    this.renderPaint.setStyle(Style.FILL);

    this.valuePaint = new Paint();
    this.valuePaint.setColor('#3F3F3F');
    this.valuePaint.setTextAlign('center');
    this.valuePaint.setTextSize(9);

    this.highlightPaint = new Paint();
    this.highlightPaint.setStyle(Style.STROKE);
    this.highlightPaint.setStrokeWidth(2);
    this.highlightPaint.setColor('#FFBB73');
  }

  protected isDrawingValuesAllowed(chart: ChartInterface): boolean {
    let chartData = chart.getData();
    if (this.viewPortHandler && chartData) {
      return chartData.getEntryCount() < this.getMaxVisibleCount * this.viewPortHandler.getScaleX();
    }
    return false;
  }

  public drawValue(c: CanvasRenderingContext2D, formatter: IAxisValueFormatter, value: number, x: number, y: number,
    color: number, isHorizontalFlip: boolean = false): void {
    if (isHorizontalFlip) {
      c.save();
      c.scale(-1, 1);
    }
    this.valuePaint.setColor(color);
    Utils.resetContext2DWithoutLine(c, this.valuePaint);
    switch (this.valuePaint.getStyle()) {
      case Style.STROKE:
        c.beginPath();
        if (this.viewPortHandler) {
          if (isHorizontalFlip) {
            c.strokeText(formatter.getFormattedValue(value), -x, y);
          } else {
            c.strokeText(formatter.getFormattedValue(value), x, y);
          }
        }
        c.closePath();
        break;
      case Style.FILL:
      case Style.FILL_AND_STROKE:
      default:
        c.beginPath();
        if (this.viewPortHandler) {
          if (isHorizontalFlip) {
            c.fillText(formatter.getFormattedValue(value), -x, y);
          } else {
            c.fillText(formatter.getFormattedValue(value), x, y);
          }
        }
        c.closePath();
        break;
    }
    if (isHorizontalFlip) {
      c.restore();
    }
  }

  public abstract initBuffers();

  public abstract drawData(c: CanvasRenderingContext2D): void;

  public abstract drawValues(c: CanvasRenderingContext2D, isHorizontalFlip?: boolean): void;

  public abstract drawHighlighted(c: CanvasRenderingContext2D, indices: Highlight[], isDraw?:boolean): void;
}
