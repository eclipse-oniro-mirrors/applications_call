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

import AxisRenderer from './AxisRenderer'
import { XAxis, XAxisPosition } from '../components/XAxis'
import ViewPortHandler from '../utils/ViewPortHandler'
import Transformer from '../utils/Transformer'
import Utils from '../utils/Utils'
import MPPointF from '../utils/MPPointF'
import MPPointD from '../utils/MPPointD'
import LimitLine from '../components/LimitLine'
import { JArrayList } from '../utils/JArrayList'
import MyRect from '../data/Rect'
import Paint, { Style } from '../data/Paint'
import HashMap from '@ohos.util.HashMap'

export enum XAxisLabelPosition {
  Left,
  Center,
  Right
}

export default class XAxisRenderer extends AxisRenderer {
  public xAxis: XAxis | null = null;
  protected textSizeCache = new HashMap<string, TextMetrics>();
  protected renderGridLinesBuffer: number[] = new Array(2);
  public limitLineSegmentsBuffer: number[] = new Array<number>(4);
  protected gridClippingRect: MyRect = new MyRect();
  protected renderLimitLinesBuffer = new Array<number>(2);
  protected limitLineClippingRect = new MyRect();

  constructor(viewPortHandler: ViewPortHandler, xAxis: XAxis, trans?: Transformer) {
    super(viewPortHandler, xAxis, trans);
    this.xAxis = xAxis;
    if (this.axisLabelPaint) {
      this.axisLabelPaint.setColor(Color.Black);
      this.axisLabelPaint.setTextAlign('center');
      this.axisLabelPaint.setTextSize(10);
    }
  }

  protected setupGridPaint() {
    if (this.gridPaint && this.axis && this.xAxis) {
      this.gridPaint.setGlobalAlpha(this.xAxis.getGridAlpha() / 255);
      this.gridPaint.setColor(this.xAxis.getGridColor());
      this.gridPaint.setStrokeWidth(this.xAxis.getGridLineWidth());
      let dashPathEffect = this.axis.getGridDashPathEffect();
      this.gridPaint.setDashPathEffect(dashPathEffect);
    }
  }

  public computeAxis(min: number, max: number, inverted: boolean) {
    if (this.viewPortHandler && this.trans && this.viewPortHandler.contentWidth() > 10 &&
      !this.viewPortHandler.isFullyZoomedOutX()) {
      let p1: MPPointD | undefined =
        this.trans?.getValuesByTouchPoint(this.viewPortHandler.contentLeft(), this.viewPortHandler.contentTop());
      let p2: MPPointD | undefined =
        this.trans?.getValuesByTouchPoint(this.viewPortHandler.contentRight(), this.viewPortHandler.contentTop());

      if (!!p1 && !!p2) {
        if (inverted) {
          min = p2.x;
          max = p1.x;
        } else {
          min = p1.x;
          max = p2.x;
        }
        MPPointD.recycleInstance(p1);
        MPPointD.recycleInstance(p2);
      }
    }
    this.computeAxisValues(min, max);
  }

  public updatePaintProperty() {
    if (this.axisLabelPaint && this.xAxis) {
      this.axisLabelPaint.setFontFamily(this.xAxis.getTypeface());
      this.axisLabelPaint.setTextSize(this.xAxis.getTextSize());
      this.axisLabelPaint.setColor(this.xAxis.getTextColor());
    }
  }

  public renderAxisLabels(c: CanvasRenderingContext2D, isHorizontalFlip: boolean): void {
    if (!this.xAxis || !this.viewPortHandler) {
      return;
    }
    if (!this.xAxis.isDrawLabelsEnabled()) {
      return;
    }
    let yoffset = this.xAxis.getYOffset();
    this.updatePaintProperty();
    let pointF: MPPointF = MPPointF.getInstance(0, 0);
    if (this.xAxis.getPosition() == XAxisPosition.TOP) {
      pointF.x = 0.5;
      pointF.y = 1.0;
      this.drawLabels(c, this.viewPortHandler.contentTop() - yoffset, pointF, isHorizontalFlip);
    } else if (this.xAxis.getPosition() == XAxisPosition.TOP_INSIDE) {
      pointF.x = 0.5;
      pointF.y = 1.0;
      this.drawLabels(c, this.viewPortHandler.contentTop() + yoffset + this.xAxis.labelRotatedHeight, pointF,
        isHorizontalFlip);
    } else if (this.xAxis.getPosition() == XAxisPosition.BOTTOM) {
      pointF.x = 0.5;
      pointF.y = 0.0;
      this.drawLabels(c, this.viewPortHandler.contentBottom() + yoffset, pointF, isHorizontalFlip);
    } else if (this.xAxis.getPosition() == XAxisPosition.BOTTOM_INSIDE) {
      pointF.x = 0.5;
      pointF.y = 0.0;
      this.drawLabels(c, this.viewPortHandler.contentBottom() - yoffset - this.xAxis.labelRotatedHeight, pointF,
        isHorizontalFlip);
    } else {
      pointF.x = 0.5;
      pointF.y = 1.0;
      this.drawLabels(c, this.viewPortHandler.contentTop() - yoffset, pointF, isHorizontalFlip);
      pointF.x = 0.5;
      pointF.y = 0.0;
      this.drawLabels(c, this.viewPortHandler.contentBottom() + yoffset, pointF, isHorizontalFlip);
    }
    MPPointF.recycleInstance(pointF);
  }

  public renderAxisLine(c: CanvasRenderingContext2D): void {
    if (!this.axisLinePaint || !this.viewPortHandler || !this.xAxis) {
      return;
    }
    this.axisLinePaint.setColor(this.xAxis.getAxisLineColor());
    this.axisLinePaint.setStrokeWidth(this.xAxis.getAxisLineWidth());
    this.axisLinePaint.setDashPathEffect(null);

    Utils.resetContext2DWithoutFont(c, this.axisLinePaint);
    let left = this.viewPortHandler.contentLeft();
    let top = this.viewPortHandler.contentTop();
    let right = this.viewPortHandler.contentRight();
    let bottom = this.viewPortHandler.contentBottom();
    if (this.xAxis.getPosition() == XAxisPosition.TOP || this.xAxis.getPosition() == XAxisPosition.TOP_INSIDE ||
      this.xAxis.getPosition() == XAxisPosition.BOTH_SIDED) {
      c.beginPath();
      c.moveTo(left, top);
      c.lineTo(right, top);
      c.stroke();
      c.closePath();
    }
    if (this.xAxis.getPosition() == XAxisPosition.BOTTOM || this.xAxis.getPosition() == XAxisPosition.BOTTOM_INSIDE ||
      this.xAxis.getPosition() == XAxisPosition.BOTH_SIDED) {
      c.beginPath();
      c.moveTo(left, bottom)
      c.lineTo(right, bottom);
      c.stroke();
      c.closePath();
    }
  }

  protected drawLabels(c: CanvasRenderingContext2D, pos: number, anchor: MPPointF, isHorizontalFlip: boolean): void {
    if (!this.xAxis) {
      return;
    }
    let centeringEnabled = this.xAxis.isCenterAxisLabelsEnabled();
    let positions: number[] = new Array<number>(this.xAxis.entryCount * 2);
    let labelPosition = XAxisLabelPosition.Center;
    for (let i = 0; i < positions.length; i += 2) {
      if (centeringEnabled) {
        positions[i] = this.xAxis.centeredEntries[i / 2];
      } else {
        positions[i] = this.xAxis.entries[i / 2];
      }
    }
    if (this.trans) {
      this.trans.pointValuesToPixel(positions);
    }
    let xOffset = 0;
    for (let i = 0; i < positions.length; i += 2) {
      let x = positions[i] + xOffset;
      if (this.viewPortHandler && this.viewPortHandler.isInBoundsX(x)) {
        let label = this.xAxis.getValueFormatter().getFormattedValue(this.xAxis.entries[i / 2]);
        this.drawLabel(c, label, x, pos, anchor, labelPosition, isHorizontalFlip);
      }
    }
  }

  protected drawLabel(c: CanvasRenderingContext2D, formattedLabel: string, x: number, y: number, anchor: MPPointF,
    labelPosition: XAxisLabelPosition = XAxisLabelPosition.Center,
    isHorizontalFlip: boolean = false): void {
    this.drawXAxisValue(c, formattedLabel, x, y, this.axisLabelPaint, anchor, labelPosition,
      isHorizontalFlip);
  }

  public drawXAxisValue(c: CanvasRenderingContext2D, text: string, x: number, y: number, paint: Paint,
    anchor: MPPointF, labelPosition: XAxisLabelPosition = XAxisLabelPosition.Center,
    isHorizontalFlip: boolean = false): void {
    let drawOffsetX: number = 0.0;
    let drawOffsetY: number = 0.0;
    const textSize = Utils.getLabelTextSize(paint, text, this.textSizeCache);
    let lineHeight = textSize.height;
    let originalTextAlign: CanvasTextAlign = paint.getTextAlign();
    let originalTextBaseLine: CanvasTextBaseline = paint.getTextBaseline();

    paint.setTextAlign('left');
    paint.setTextBaseline('top');
    Utils.resetContext2DWithoutLine(c, paint);
    if (anchor.x != 0.0 || anchor.y != 0.0) {
      drawOffsetX -= textSize.width * anchor.x;
      drawOffsetY -= lineHeight * anchor.y;
    }
    drawOffsetX += x;
    if (labelPosition == XAxisLabelPosition.Right) {
      drawOffsetX += textSize.width * 0.5;
    } else if (labelPosition == XAxisLabelPosition.Left) {
      drawOffsetX -= textSize.width * 0.5;
    }
    drawOffsetY += y;
    if (isHorizontalFlip) {
      c.save();
      c.scale(-1, 1);
    }
    const horizontalFlipWidth = -drawOffsetX - Utils.getLabelTextSize(paint, text, this.textSizeCache).width;
    switch (paint.getStyle()) {
      case Style.STROKE:
        c.beginPath();
        if (isHorizontalFlip) {
          c.strokeText(text, horizontalFlipWidth, drawOffsetY);
        } else {
          c.strokeText(text, drawOffsetX, drawOffsetY);
        }
        c.closePath();
        break
      case Style.FILL_AND_STROKE:
      case Style.FILL:
      default:
        c.beginPath();
        if (isHorizontalFlip) {
          c.fillText(text, horizontalFlipWidth, drawOffsetY);
        } else {
          c.fillText(text, drawOffsetX, drawOffsetY);
        }
        c.closePath();
        break
    }
    if (isHorizontalFlip) {
      c.restore();
    }
    paint.setTextAlign(originalTextAlign);
    paint.setTextBaseline(originalTextBaseLine);
  }

  public renderGridLines(c: CanvasRenderingContext2D): void {
    if (!this.axis || !this.xAxis || !this.xAxis.isDrawGridLinesEnabled()) {
      return;
    }
    c.save();
    c.beginPath();
    let clippingRect = this.getGridClippingRect();
    c.rect(clippingRect.left, clippingRect.top, clippingRect.width(), clippingRect.height());
    c.closePath();
    c.clip();

    if (this.renderGridLinesBuffer.length != this.axis.entryCount * 2) {
      this.renderGridLinesBuffer = new Array<number>(this.xAxis.entryCount * 2);
    }
    let positions: number[] = this.renderGridLinesBuffer;

    for (let i = 0; i < positions.length; i += 2) {
      positions[i] = this.xAxis.entries[i / 2];
      positions[i + 1] = this.xAxis.entries[i / 2];
    }
    if (this.trans) {
      this.trans.pointValuesToPixel(positions);
    }

    this.setupGridPaint();

    for (let i = 0; i < positions.length; i += 2) {
      this.drawGridLine(c, positions[i], positions[i + 1]);
    }
    c.restore();
  }

  public getGridClippingRect(): MyRect {
    if (this.viewPortHandler) {
      this.gridClippingRect.set(this.viewPortHandler.getContentRect().left, this.viewPortHandler.getContentRect().top
        , this.viewPortHandler.getContentRect().right, this.viewPortHandler.getContentRect().bottom);
    }
    if (this.axis) {
      this.gridClippingRect.inset(-this.axis.getGridLineWidth(), 0, -this.axis.getGridLineWidth(), 0);
    }
    return this.gridClippingRect;
  }

  protected drawGridLine(c: CanvasRenderingContext2D, x: number, y: number): void {
    Utils.resetContext2DWithoutFont(c, this.gridPaint);
    c.beginPath();
    c.moveTo(x, (this.viewPortHandler ? this.viewPortHandler.contentBottom() : 0));
    c.lineTo(x, (this.viewPortHandler ? this.viewPortHandler.contentTop() : 0));
    c.stroke();
    c.closePath();
  }

  private renderLinesInner(c: CanvasRenderingContext2D, lines: JArrayList<LimitLine>) {
    if (!this.xAxis || !this.axis) {
      return;
    }
    if (!lines || lines.size() <= 0) {
      return;
    }
    let position = this.renderLimitLinesBuffer;
    position[0] = 0;
    position[1] = 0;
    for (let i = 0; i < lines.size(); i++) {
      let l: LimitLine = lines.get(i);
      c.save();
      if (this.viewPortHandler) {
        this.limitLineClippingRect.set(this.viewPortHandler.getContentRect()
          .left, this.viewPortHandler.getContentRect().top
          , this.viewPortHandler.getContentRect().right, this.viewPortHandler.getContentRect().bottom);
      }

      c.beginPath();
      c.rect(this.limitLineClippingRect.left, this.limitLineClippingRect.top, this.limitLineClippingRect.width(),
        this.limitLineClippingRect.height());
      c.closePath();
      c.clip();
      if (this.axis) {
        this.gridClippingRect.inset(-this.axis.getGridLineWidth(), 0, -this.axis.getGridLineWidth(), 0);
      }

      position[0] = 0;
      position[1] = 0;
      if (this.trans) {
        this.trans.pointValuesToPixel(position);
      }
      this.renderLimitLineLine(c, l, position)
      c.restore();
    }
  }

  public renderCustomGridLines(c: CanvasRenderingContext2D) {
    let gridLines = this.xAxis?.getGridLines();
    gridLines && this.renderLinesInner(c, gridLines);
  }

  public renderLimitLines(c: CanvasRenderingContext2D): void {
    let limitLines = this.xAxis?.getLimitLines();
    limitLines && this.renderLinesInner(c, limitLines);
  }

  public renderLimitLineLine(c: CanvasRenderingContext2D, limitLine: LimitLine, position: number[]): void {
    this.limitLineSegmentsBuffer[0] = position[0];
    this.limitLineSegmentsBuffer[1] = this.viewPortHandler ? this.viewPortHandler.contentTop() : 0;
    this.limitLineSegmentsBuffer[2] = position[0];
    this.limitLineSegmentsBuffer[3] = this.viewPortHandler ? this.viewPortHandler.contentBottom() : 0;
    if (this.limitLinePaint) {
      this.limitLinePaint.setStyle(Style.STROKE);
      this.limitLinePaint.setColor(limitLine.getLineColor());
      this.limitLinePaint.setStrokeWidth(limitLine.getLineWidth());
      Utils.resetContext2DWithoutFont(c, this.limitLinePaint)
      c.beginPath();
      c.moveTo(this.limitLineSegmentsBuffer[0], this.limitLineSegmentsBuffer[1]);
      c.lineTo(this.limitLineSegmentsBuffer[2], this.limitLineSegmentsBuffer[3]);
      c.stroke();
      c.closePath();
    }
  }
}

