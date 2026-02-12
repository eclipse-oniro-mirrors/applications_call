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

import BarBuffer from '../BarBuffer';
import BarData from '../data/BarData';
import BarEntry from '../data/BarEntry';
import Paint, { Style } from '../data/Paint';
import MyRect from '../data/Rect';
import IAxisValueFormatter from '../formatter/IAxisValueFormatter';
import Highlight from '../highlight/Highlight';
import BarDataProvider from '../interfaces/dataprovider/BarDataProvider';
import { JArrayList } from '../utils/JArrayList';
import MPPointF from '../utils/MPPointF';
import Transformer from '../utils/Transformer';
import Utils, { RoundCornerType } from '../utils/Utils';
import ViewPortHandler from '../utils/ViewPortHandler';
import DataRenderer from './DataRenderer';
import HashMap from '@ohos.util.HashMap';
import IDataSet from '../interfaces/datasets/IDataSet';

export default class BarChartRenderer extends DataRenderer {
  public chart: BarDataProvider | null = null;
  private barRect: MyRect = new MyRect();
  private topRadius: number = 4;
  private getHighLightAlpha: number = 120;
  private barBuffers: BarBuffer[] = [];
  private shadowPaint: Paint | null = null;
  private barBorderPaint: Paint | null = null;
  private textSizeCache = new HashMap<string, TextMetrics>();

  constructor(chart: BarDataProvider, viewPortHandler: ViewPortHandler) {
    super(viewPortHandler);
    this.chart = chart;
    this.highlightPaint = new Paint();
    this.highlightPaint.setStyle(Style.FILL);
    this.highlightPaint.setColor(Color.Black);
    this.highlightPaint.setGlobalAlpha(120 / 255);
    this.shadowPaint = new Paint();
    this.shadowPaint.setStyle(Style.FILL);
    this.barBorderPaint = new Paint();
    this.barBorderPaint.setStyle(Style.STROKE);
  }

  protected shouldDrawValues(dataSet: IDataSet): boolean {
    return dataSet.isDrawValuesEnabled();
  }

  protected isInBoundsX(e: BarEntry, dataSet: IDataSet): boolean {
    if (e == null) {
      return false;
    }
    let entryIndex = dataSet.getEntryIndexByEntry(e);
    if (entryIndex >= dataSet.getEntryCount()) {
      return false;
    } else {
      return true;
    }
  }

  public initBuffers(): void {
    if (!this.chart) {
      return;
    }
    let barData: BarData | null = this.chart.getBarData();
    if (barData) {
      this.barBuffers = new Array(barData.getDataSetCount());
      for (let i = 0; i < this.barBuffers.length; i++) {
        let dataSet: IDataSet | null = barData.getDataSetByIndex(i);
        if (dataSet) {
          this.barBuffers[i] = new BarBuffer(dataSet.isStacked());
        }
      }
    }
  }

  public drawData(c: CanvasRenderingContext2D): void {
    if (!this.chart) {
      return
    }
    let barData: BarData | null = this.chart.getBarData();
    if (barData) {
      for (let i = 0; i < barData.getDataSetCount(); i++) {
        let set: IDataSet | null = barData.getDataSetByIndex(i);
        if (set) {
          this.drawDataSet(c, set, i);
        }
      }
    }
  }

  protected drawDataSet(c: CanvasRenderingContext2D, dataSet: IDataSet, index: number): void {
    if (!this.chart) {
      return;
    }
    let trans: Transformer | null = this.chart.getTransformer(dataSet.getAxisDependency());
    if (this.barBorderPaint) {
      this.barBorderPaint.setColor(Color.Black);
      this.barBorderPaint.setStrokeWidth(Utils.handleDataValues(0));
    }
    let buffer: BarBuffer = this.barBuffers[index];
    if (buffer === null || buffer === undefined) {
      return;
    }
    buffer.setInverted(this.chart.isInverted(dataSet.getAxisDependency()));
    let barData: BarData | null = this.chart.getBarData();
    if (barData) {
      buffer.setBarWidth(barData.getBarWidth());
    }
    buffer.feed(dataSet);
    if (trans) {
      trans.pointValuesToPixel(buffer.buffer);
    }

    const isSingleColor: boolean = dataSet.getColors().size() == 1;
    const isInverted: boolean = this.chart.isInverted(dataSet.getAxisDependency());
    if (isSingleColor) {
      this.renderPaint.setColor(dataSet.getColor());
    }
    for (let j = 0, pos = 0; j < buffer.buffer.length; j += 4, pos++) {
      if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsLeft(buffer.buffer[j + 2])) {
        continue;
      }
      if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsRight(buffer.buffer[j])) {
        break;
      }
      if (!isSingleColor) {
        this.renderPaint.setColor(dataSet.getColor(pos));
      }

      const radius = barData ? this.topRadius : 0;
      //顶部的矩形才需要绘制圆角
      let isDrawRounded =
        radius != 0 &&
          (j + 4 >= buffer.buffer.length || (j + 4 < buffer.buffer.length && buffer.buffer[j] != buffer.buffer[j + 4]));
      // 圆角位置：同时受 值 和 图表是否 inverted 影响
      let cornerType: RoundCornerType = 'up'
      if (dataSet.getEntryForIndex(pos) != null) {
        if (isInverted) {
          cornerType = dataSet.getEntryForIndex(pos).getY() > 0 ? 'down' : 'up'
        } else {
          cornerType = dataSet.getEntryForIndex(pos).getY() > 0 ? 'up' : 'down'
        }
      }
      Utils.drawRect(isDrawRounded, c, this.renderPaint, buffer.buffer[j], buffer.buffer[j + 1],
        buffer.buffer[j + 2], buffer.buffer[j + 3], radius, true, cornerType);
    }
  }

  protected prepareBarHighlight(x: number, y1: number, y2: number, barWidthHalf: number, trans: Transformer): void {
    let left: number = x - barWidthHalf;
    let right: number = x + barWidthHalf;
    let top: number = y1;
    let bottom: number = y2;
    this.barRect.set(left, top, right, bottom);
    if (trans) {
      trans.rectToPixelPhase(this.barRect, 1);
    }
  }

  private getTransformed(transformed: number[], vals: number[], positiveY: number, negativeY: number): void {
    for (let k = 0, index = 0; k < transformed.length; k += 2, index++) {
      let val: number = vals[index];
      let y: number = 0;
      if (val == 0.0 && (positiveY == 0.0 || negativeY == 0.0)) {
        y = val;
      } else if (val >= 0.0) {
        positiveY += val;
        y = positiveY;
      } else {
        y = negativeY;
        negativeY -= val;
      }
      transformed[k + 1] = y;
    }
  }

  public drawValues(c: CanvasRenderingContext2D): void {
    if (!this.chart || !this.chart.getBarData()) {
      return;
    }
    if (this.isDrawingValuesAllowed(this.chart)) {
      let barData: BarData | null = this.chart.getBarData();
      if (!barData) {
        return;
      }
      let dataSets: JArrayList<IDataSet> = barData.getDataSets();
      const valueOffsetPlus: number = 0;
      let posOffset: number = 0;
      let negOffset: number = 0;
      for (let i = 0; i < barData.getDataSetCount(); i++) {
        let dataSet: IDataSet = dataSets.get(i);
        if (!this.shouldDrawValues(dataSet)) {
          continue;
        }
        this.valuePaint.setFontFamily(dataSet.getValueTypeface() !);
        let isInverted: boolean = this.chart.isInverted(dataSet.getAxisDependency());
        let valueTextHeight: number = Utils.getLabelTextSize(this.valuePaint, '8', this.textSizeCache).height;
        posOffset = valueTextHeight + valueOffsetPlus;
        negOffset = -valueOffsetPlus;
        if (isInverted) {
          posOffset = -posOffset - valueTextHeight;
          negOffset = -negOffset - valueTextHeight;
        }

        let buffer: BarBuffer = this.barBuffers[i];
        let iconsOffset: MPPointF = MPPointF.getInstance(0, 0, dataSet.getIconsOffset());
        iconsOffset.x = Utils.handleDataValues(iconsOffset.x);
        iconsOffset.y = Utils.handleDataValues(iconsOffset.y);
        if (!dataSet.isStacked()) {
          for (let j = 0; j < buffer.buffer.length; j += 4) {
            let x: number = (buffer.buffer[j] + buffer.buffer[j + 2]) / 2;
            if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsRight(x)) {
              break;
            }
            if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsY(buffer.buffer[j + 1]) ||
              !this.viewPortHandler.isInBoundsLeft(x)) {
              continue;
            }
            let entry: BarEntry = dataSet.getEntryForIndex(j / 4);
            let val: number = entry.getY();
            if (dataSet.isDrawValuesEnabled()) {
              let valueFormatter: IAxisValueFormatter | null = dataSet.getValueFormatter();
              if (valueFormatter) {
                this.drawValue(c, valueFormatter, val, x,
                    val >= 0 ? (buffer.buffer[j + 1] + posOffset) : (buffer.buffer[j + 3] + negOffset),
                  dataSet.getValueTextColor(j / 4));
              }
            }
          }
        } else {
          let trans: Transformer | null = this.chart.getTransformer(dataSet.getAxisDependency());
          let bufferIndex: number = 0;
          let index: number = 0;
          while (index < dataSet.getEntryCount()) {
            let entry: BarEntry = dataSet.getEntryForIndex(index);
            let vals: number[] | null = entry.getYVals();
            let x: number = (buffer.buffer[bufferIndex] + buffer.buffer[bufferIndex + 2]) / 2;
            let color: number = dataSet.getValueTextColor(index);
            if (vals == null) {
              if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsRight(x)) {
                break;
              }
              if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsY(buffer.buffer[bufferIndex + 1]) ||
                !this.viewPortHandler.isInBoundsLeft(x)) {
                continue;
              }
              if (dataSet.isDrawValuesEnabled()) {
                let valueFormatter: IAxisValueFormatter | null = dataSet.getValueFormatter();
                if (valueFormatter) {
                  this.drawValue(c, valueFormatter, entry.getY(), x,
                    buffer.buffer[bufferIndex + 1] + (entry.getY() >= 0 ? posOffset : negOffset), color);
                }
              }
            } else {
              let transformed: number[] = new Array<number>(vals.length * 2);
              let posY: number = 0;
              let negY: number = -entry.getNegativeSum();
              this.getTransformed(transformed, vals, posY, negY);
              if (trans) {
                trans.pointValuesToPixel(transformed);
              }
              for (let k = 0; k < transformed.length; k += 2) {
                const val: number = vals[k / 2];
                const drawBelow: boolean = val < 0.0;
                let y: number = transformed[k + 1] + (drawBelow ? negOffset : posOffset);
                if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsRight(x)) {
                  break;
                }
                if (!this.viewPortHandler || !this.viewPortHandler.isInBoundsY(y) ||
                  !this.viewPortHandler.isInBoundsLeft(x)) {
                  continue;
                }
                if (dataSet.isDrawValuesEnabled()) {
                  let valueFormatter: IAxisValueFormatter | null = dataSet.getValueFormatter();
                  if (valueFormatter) {
                    this.drawValue(c,
                      valueFormatter,
                      vals[k / 2],
                      x,
                      y,
                      color);
                  }
                }
              }
            }
            bufferIndex = vals == null ? bufferIndex + 4 : bufferIndex + 4 * vals.length;
            index++;
          }
        }
        MPPointF.recycleInstance(iconsOffset);
      }
    }
  }

  public drawHighlighted(c: CanvasRenderingContext2D, indices: Highlight[]): void {
    if (!this.chart) {
      return;
    }
    let barData: BarData | null = this.chart.getBarData();
    if (!barData) {
      return;
    }
    for (let i = 0; i < indices.length; i++) {
      let high: Highlight = indices[i];
      let set: IDataSet | null = barData.getDataSetByIndex(high.getDataSetIndex());
      if (set == null || !set.isHighlightEnabled()) {
        continue;
      }
      let e: BarEntry | null = set.getEntryForXValue(high.getX(), high.getY());
      if (!e) {
        continue;
      }
      if (!this.isInBoundsX(e, set)) {
        continue;
      }
      let trans: Transformer | null = this.chart.getTransformer(set.getAxisDependency());
      let highLightColor: number = set.getHighLightColor();
      if (highLightColor == 0) {
        highLightColor = Color.Black;
      }
      this.highlightPaint.setColor(highLightColor);
      this.highlightPaint.setGlobalAlpha(this.getHighLightAlpha / 255);
      let isStack: boolean = (high.getStackIndex() >= 0 && e.isStacked()) ? true : false;
      let y1: number = 0;
      let y2: number = 0;
      let drawRadius: boolean = false;
      let radius = this.topRadius;
      if (isStack) {
        y1 = e.getPositiveSum();
        y2 = -e.getNegativeSum();
      } else {
        if (radius != 0) {
          drawRadius = true;
        }
        y1 = e.getY();
        y2 = 0.0;
      }
      if (trans) {
        this.prepareBarHighlight(e.getX(), y1, y2, barData.getBarWidth() / 2, trans);
      }
      // 圆角位置
      let cornerType: RoundCornerType = 'up';
      // 当前图表是否反向
      let isInverted: boolean = this.chart.isInverted(set.getAxisDependency());
      if (isInverted) {
        cornerType = e.getY() > 0 ? 'down' : 'up';
      } else {
        cornerType = e.getY() > 0 ? 'up' : 'down';
      }
      high.setDraw(this.barRect.centerX(), this.barRect.top);
      Utils.drawRect(drawRadius, c, this.highlightPaint, this.barRect.left, this.barRect.top,
        this.barRect.right, this.barRect.bottom, radius, true, cornerType);
    }
  }

  public getBarBuffers(): BarBuffer[] {
    return this.barBuffers;
  }
}
