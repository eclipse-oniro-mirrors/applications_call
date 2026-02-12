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

import MyRect from '../data/Rect';
import YAxis, { AxisDependency, YAxisLabelPosition } from '../components/YAxis';
import Paint, { Style } from '../data/Paint';
import Utils from '../utils/Utils';
import AxisRenderer from './AxisRenderer';
import LimitLine from '../components/LimitLine';
import { JArrayList } from '../utils/JArrayList';
import ViewPortHandler from '../utils/ViewPortHandler';
import Transformer from '../utils/Transformer';
import MPPointD from '../utils/MPPointD';
import HashMap from '@ohos.util.HashMap';

export default class YAxisRenderer extends AxisRenderer {
  protected yAxis: YAxis | null = null;
  protected zeroLinePaint: Paint = new Paint();
  private textSizeCache = new HashMap<string, TextMetrics>();
  protected gridClippingRect: MyRect = new MyRect();
  protected zeroLineClippingRect: MyRect = new MyRect();
  protected getTransformedPositionsBuffer: number[] = new Array<number>(2);
  protected renderLimitLinesBuffer: number[] = new Array<number>(2);
  protected limitLineClippingRect: MyRect = new MyRect();

  constructor(viewPortHandler: ViewPortHandler, yAxis: YAxis, trans?: Transformer) {
    super(viewPortHandler, yAxis, trans)
    this.yAxis = yAxis;

    if (viewPortHandler != null) {
      if (this.axisLabelPaint) {
        this.axisLabelPaint.setColor(Color.Black);
        this.axisLabelPaint.setTextSize(10);
      }
      this.zeroLinePaint = new Paint();
      this.zeroLinePaint.setColor(Color.Gray);
      this.zeroLinePaint.setStrokeWidth(1);
      this.zeroLinePaint.setStyle(Style.STROKE);
    }
  }

  public updatePaintProperty() {
    if (this.axisLinePaint && this.yAxis) {
      this.axisLabelPaint.setFontFamily(this.yAxis.getTypeface());
      this.axisLabelPaint.setTextSize(this.yAxis.getTextSize());
      this.axisLabelPaint.setColor(this.yAxis.getTextColor());
    }
  }

  public renderAxisLabels(c: CanvasRenderingContext2D, isHorizontalFlip: boolean, isLeftAxis: boolean): void {
    if (!this.yAxis) {
      return
    }
    if (!this.yAxis.isDrawLabelsEnabled()) {
      return;
    }
    let positions: number[] = this.getTransformedPositions();
    if (this.axisLabelPaint) {
      this.updatePaintProperty();
      let xOffset = this.yAxis.getXOffset();
      let yOffset =
        Utils.getLabelTextSize(this.axisLabelPaint, 'A', this.textSizeCache).height + this.yAxis.getYOffset();
      let dependency: AxisDependency = this.yAxis.getAxisDependency();
      let labelPosition: YAxisLabelPosition = this.yAxis.getLabelPosition();
      let xPos: number = 0;
      if (dependency == AxisDependency.LEFT) {
        if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
          if (this.axisLabelPaint) {
            this.axisLabelPaint.setTextAlign('right');
          }
          xPos = (this.viewPortHandler ? this.viewPortHandler.offsetLeft() : 0) - xOffset;
        } else {
          if (this.axisLabelPaint) {
            this.axisLabelPaint.setTextAlign('left');
          }
          if (this.viewPortHandler) {
            xPos = (this.viewPortHandler ? this.viewPortHandler.offsetLeft() : 0) + xOffset;
          }
        }
      } else {
        if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
          if (this.axisLabelPaint) {
            this.axisLabelPaint.setTextAlign('left');
          }
          if (this.viewPortHandler) {
            xPos = this.viewPortHandler.contentRight() + xOffset;
          }
        } else {
          if (this.axisLabelPaint) {
            this.axisLabelPaint.setTextAlign('right');
          }
          if (this.viewPortHandler) {
            xPos = this.viewPortHandler.contentRight() - xOffset;
          }
        }
      }
      this.drawYLabels(c, xPos, positions, yOffset, isHorizontalFlip, isLeftAxis);
    }
  }

  public renderAxisLine(c: CanvasRenderingContext2D, extraLength: number): void {
    if (!this.yAxis || !this.viewPortHandler) {
      return;
    }
    if (this.axisLinePaint) {
      this.axisLinePaint.setColor(this.yAxis.getAxisLineColor());
      this.axisLinePaint.setStrokeWidth(this.yAxis.getAxisLineWidth());
      Utils.resetContext2DWithoutFont(c, this.axisLinePaint);
      if (this.yAxis.getAxisDependency() == AxisDependency.LEFT) {
        c.beginPath();
        c.moveTo(this.viewPortHandler.contentLeft(), this.viewPortHandler.contentTop());
        c.lineTo(this.viewPortHandler.contentLeft(), this.viewPortHandler.contentBottom() + extraLength);
        c.closePath();
        c.stroke();
      } else {
        c.beginPath();
        c.moveTo(this.viewPortHandler.contentRight(), this.viewPortHandler.contentTop());
        c.lineTo(this.viewPortHandler.contentRight(), this.viewPortHandler.contentBottom() + extraLength);
        c.closePath();
        c.stroke();

      }
    }
  }

  protected drawYLabels(c: CanvasRenderingContext2D, fixedPosition: number, positions: number[], offset: number,
    isHorizontalFlip: boolean, isLeftAxis: boolean): void {
    if (!this.yAxis) {
      return;
    }
    const fromIndex = 0;
    const to = this.yAxis.entryCount;
    let xOffset: number = 0;
    if (isHorizontalFlip) {
      c.save();
      c.scale(-1, 1);
    }
    for (let i = fromIndex; i < to; i++) {
      let text: string = this.yAxis.getFormattedLabel(i);
      let originTextBaseLine: CanvasTextBaseline = this.axisLabelPaint.getTextBaseline();
      this.axisLabelPaint.setTextBaseline('middle');
      Utils.resetContext2DWithoutLine(c, this.axisLabelPaint);
      const xPosition = fixedPosition + xOffset;
      const textSize = Utils.getLabelTextSize(this.axisLabelPaint, text, this.textSizeCache);
      const textWidth = textSize.width;
      const textHeight = textSize.height;
      switch (this.axisLabelPaint.getStyle()) {
        case Style.STROKE:
          c.beginPath();
          if (isHorizontalFlip) {
            if (isLeftAxis) {
              c.strokeText(text, -xPosition + textWidth, positions[i * 2 + 1] + offset - textHeight);
            } else {
              c.strokeText(text, -xPosition - textWidth, positions[i * 2 + 1] + offset - textHeight);
            }
          } else {
            c.strokeText(text, xPosition, positions[i * 2 + 1] + offset - textHeight);
          }
          c.closePath();
          break;
        case Style.FILL_AND_STROKE:
        case Style.FILL:
        default:
          c.beginPath();
          if (isHorizontalFlip) {
            if (isLeftAxis) {
              c.fillText(text, -xPosition + textWidth, positions[i * 2 + 1] + offset - textHeight);
            } else {
              c.fillText(text, -xPosition - textWidth, positions[i * 2 + 1] + offset - textHeight);
            }
          } else {
            c.fillText(text, xPosition, positions[i * 2 + 1] + offset - textHeight);
          }
          c.closePath();
          break;
      }
      this.axisLabelPaint.setTextBaseline(originTextBaseLine);
    }
    if (isHorizontalFlip) {
      c.restore();
    }
  }

  public renderGridLines(c: CanvasRenderingContext2D): void {
    if (!this.yAxis) {
      return;
    }
    if (this.yAxis.isDrawGridLinesEnabled()) {
      c.save();
      c.beginPath();
      let contentRect = this.getGridClippingRect();
      c.rect(contentRect.left, contentRect.top, contentRect.right - contentRect.left,
        contentRect.bottom - contentRect.top);
      c.closePath();
      c.clip();

      let positions: number[] = this.getTransformedPositions();
      if (this.gridPaint) {
        this.gridPaint.setGlobalAlpha(this.yAxis.getGridAlpha() / 255);
        this.gridPaint.setColor(this.yAxis.getGridColor());
        this.gridPaint.setStrokeWidth(this.yAxis.getGridLineWidth());
        let dashEffect = this.yAxis.getGridDashPathEffect();
        this.gridPaint.setDashPathEffect(dashEffect);
      }
      if (positions) {
        for (let i = 0; i < positions.length; i += 2) {
          Utils.resetContext2DWithoutFont(c, this.gridPaint);
          c.beginPath();
          this.linePath(c, i, positions);
          c.closePath();
        }
      }
      c.restore();
    }
  }

  public getGridClippingRect(): MyRect {
    if (this.viewPortHandler) {
      this.gridClippingRect.set(this.viewPortHandler.getContentRect().left, this.viewPortHandler.getContentRect().top
        , this.viewPortHandler.getContentRect().right, this.viewPortHandler.getContentRect().bottom);
    }
    if (this.axis) {
      this.gridClippingRect.inset(0, -this.axis.getGridLineWidth(), 0, -this.axis.getGridLineWidth());
    }
    return this.gridClippingRect;
  }

  protected linePath(c: CanvasRenderingContext2D, i: number, positions: number[]): void {
    c.beginPath()
    c.moveTo(this.viewPortHandler ? this.viewPortHandler.offsetLeft() : 0, positions[i + 1]);
    c.lineTo(this.viewPortHandler ? this.viewPortHandler.contentRight() : 0, positions[i + 1]);
    c.stroke();
    c.closePath();
  }

  protected getTransformedPositions(): number[] {
    if (!this.yAxis) {
      return [];
    }
    if (this.getTransformedPositionsBuffer.length != this.yAxis.entryCount * 2) {
      this.getTransformedPositionsBuffer = new Array<number>(this.yAxis.entryCount * 2);
    }
    let positions: number[] = this.getTransformedPositionsBuffer;
    for (let i = 0; i < positions.length; i += 2) {
      positions[i + 1] = this.yAxis.entries[i / 2];
    }
    if (this.trans) {
      this.trans.pointValuesToPixel(positions);
    }
    return positions;
  }

  public renderLine(c: CanvasRenderingContext2D, l: LimitLine) {
    if (this.viewPortHandler) {
      this.limitLineClippingRect.set(this.viewPortHandler.getContentRect()
        .left, this.viewPortHandler.getContentRect().top,
        this.viewPortHandler.getContentRect().right, this.viewPortHandler.getContentRect().bottom);
    }
    this.limitLineClippingRect.inset(0, -l.getLineWidth(), 0, -l.getLineWidth());
    c.beginPath();
    c.rect(this.limitLineClippingRect.left, this.limitLineClippingRect.top, this.limitLineClippingRect.width(),
      this.limitLineClippingRect.height());
    c.closePath();
    c.clip();
    this.limitLinePaint.setStyle(Style.STROKE);
    this.limitLinePaint.setColor(l.getLineColor());
    this.limitLinePaint.setStrokeWidth(l.getLineWidth());
    let dashEffect = null;
    this.limitLinePaint.setDashPathEffect(dashEffect)
    this.renderLimitLinesBuffer[1] = 0;
    if (this.trans) {
      this.trans.pointValuesToPixel(this.renderLimitLinesBuffer);
    }
    Utils.resetContext2DWithoutFont(c, this.limitLinePaint);
    c.beginPath();
    c.moveTo(this.viewPortHandler ? this.viewPortHandler.contentLeft() : 0, this.renderLimitLinesBuffer[1]);
    c.lineTo(this.viewPortHandler ? this.viewPortHandler.contentRight() : 0, this.renderLimitLinesBuffer[1]);
    c.stroke();
    c.closePath();
  }

  public renderCustomGridLines(c: CanvasRenderingContext2D) {
    if (!this.yAxis) {
      return;
    }
    let gridLines = this.yAxis.getGridLines();
    if (!gridLines || gridLines.size() <= 0) {
      return;
    }

    for (let i = 0; i < gridLines.size(); i++) {
      c.save();
      let l: LimitLine = gridLines.get(i);
      this.renderLine(c, l)
      c.restore();
    }
  }

  public renderLimitLines(c: CanvasRenderingContext2D, isHorizontalFlip: boolean): void {
    if (!this.yAxis) {
      return;
    }
    let limitLines: JArrayList<LimitLine> = this.yAxis.getLimitLines();
    if (!limitLines || limitLines.size() <= 0) {
      return;
    }
    let pts: number[] = this.renderLimitLinesBuffer;
    pts[0] = 0;
    pts[1] = 0;
    for (let i = 0; i < limitLines.size(); i++) {
      let l: LimitLine = limitLines.get(i);
      c.save();
      this.renderLine(c, l)
      c.restore();
    }
  }
}
