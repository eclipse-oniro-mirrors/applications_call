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

import Chart from './ChartModel';
import BarDataProvider from '../interfaces/dataprovider/BarDataProvider';
import YAxis, { AxisDependency } from '../components/YAxis';
import YAxisRenderer from '../renderer/YAxisRenderer';
import XAxisRenderer from '../renderer/XAxisRenderer';
import Transformer from '../utils/Transformer';
import ChartHighlighter from '../highlight/ChartHighlighter';
import Utils from '../utils/Utils';
import MPPointD from '../utils/MPPointD';
import BarEntry from '../data/BarEntry';
import Highlight from '../highlight/Highlight';
import ChartTouchListener from '../listener/ChartTouchListener';
import IDataSet from '../interfaces/datasets/IDataSet';
import ViewPortHandler from '../utils/ViewPortHandler';
import MoveViewJob from '../jobs/MoveViewJob';
import { EventControl, EventType } from '../listener/EventControl';
import HashMap from '@ohos.util.HashMap';
import CanvasUtil from '../utils/CanvasUtil';
import { LogUtil } from '../utils/LogUtil';
import BarData from '../data/BarData';
import BarChartRenderer from '../renderer/BarChartRenderer';
import { XAxis } from '../components/XAxis';
import BarHighlighter from '../highlight/BarHighlighter';

export default class BarLineChartBaseModel extends Chart<BarData> implements BarDataProvider {
  public axisLeft: YAxis | null = null;
  public axisRight: YAxis | null = null;
  public leftAxisTransformer: Transformer | null = null;
  public rightAxisTransformer: Transformer | null = null;
  public axisRendererLeft: YAxisRenderer | null = null;
  public axisRendererRight: YAxisRenderer | null = null;
  public xAxisRenderer: XAxisRenderer | null = null;
  protected isHorizontalFlip: boolean = false;
  private touchListenerCount: number = 3;
  private textSizeCache = new HashMap<string, TextMetrics>();
  protected posForGetHighestVisibleX: MPPointD = MPPointD.getInstance(0, 0);
  protected posForGetLowestVisibleX: MPPointD = MPPointD.getInstance(0, 0);
  public context2D: CanvasRenderingContext2D | null = null;

  constructor() {
    super();
    this.init();
  }

  public invalidate(): void {
    if (this.context2D) {
      this.onDraw(this.context2D);
    }
  }

  public setContext2D(context2D: CanvasRenderingContext2D) {
    this.context2D = context2D;
  }

  public onChartSizeChanged(newWidth: number, newHeight: number) {
    this.onSizeChanged(newWidth, newHeight);
  }

  public getHorizontalFlip(): boolean {
    return this.isHorizontalFlip;
  }

  public get eventControl() {
    return new EventControl();
  }

  public init(): void {
    super.init();
    this.axisLeft = new YAxis(AxisDependency.LEFT);
    this.axisRight = new YAxis(AxisDependency.RIGHT);
    this.leftAxisTransformer = new Transformer(this.viewPortHandler);
    this.rightAxisTransformer = new Transformer(this.viewPortHandler);
    this.axisRendererLeft = new YAxisRenderer(this.viewPortHandler, this.axisLeft, this.leftAxisTransformer);
    this.axisRendererRight = new YAxisRenderer(this.viewPortHandler, this.axisRight, this.rightAxisTransformer);
    if (this.chartXAxis) {
      this.xAxisRenderer = new XAxisRenderer(this.viewPortHandler, this.chartXAxis, this.leftAxisTransformer);
    }
    this.setHighlighter(new ChartHighlighter(this));
    this.chartTouchListener = new ChartTouchListener(this, this.viewPortHandler.getMatrixTouch(),
      this.touchListenerCount) as ChartTouchListener;

    this.renderer = new BarChartRenderer(this, this.viewPortHandler);
    this.setHighlighter(new BarHighlighter(this));
    let xAxis: XAxis | null = this.getXAxis();
    if (xAxis) {
      xAxis.setSpaceMin(0.5);
      xAxis.setSpaceMax(0.5);
    }
  }

  public getHighlightByTouchPoint(x: number, y: number): Highlight | null {
    if (this.chartData == null) {
      LogUtil.error('mpChart: Can not select by touch. No data set.');
      return null;
    } else {
      let highLighter: ChartHighlighter<BarDataProvider> | null = this.getHighlighter();
      if (highLighter) {
        let h: Highlight | null = highLighter.getHighlight(x, y);
        if (h == null) {
          return h;
        }
        return new Highlight(h.getX(), h.getY(), h.getDataSetIndex(), 0, -1,
          h.getXPx(), h.getYPx(), h.getAxis());
      } else {
        return null;
      }
    }
  }

  public getBarData(): BarData | null {
    return this.chartData;
  }

  public onDraw(context2D: CanvasRenderingContext2D): void {
    super.onDraw(context2D);
    if (!this.chartData || !this.renderer || !this.chartSizeCorrected) {
      return;
    }
    // 清空画布，防止图表堆叠
    CanvasUtil.clearCanvas(context2D);

    if (this.axisRendererLeft && this.axisLeft) {
      this.axisRendererLeft.computeAxis(this.axisLeft.axisMinimum, this.axisLeft.axisMaximum,
        this.axisLeft.isInverted());
    }
    if (this.axisRendererRight && this.axisRight) {
      this.axisRendererRight.computeAxis(this.axisRight.axisMinimum, this.axisRight.axisMaximum,
        this.axisRight.isInverted());
    }
    if (this.xAxisRenderer && this.chartXAxis) {
      this.xAxisRenderer.computeAxis(this.chartXAxis.axisMinimum, this.chartXAxis.axisMaximum, false);
    }

    // y轴延长线计算
    let extraLength = this.calcExtensionLine(this.axisRendererLeft);
    if (!extraLength) {
      extraLength = this.calcExtensionLine(this.axisRendererRight);
    }
    if (this.xAxisRenderer) {
      this.xAxisRenderer.renderAxisLine(context2D);
    }
    if (this.axisRendererLeft) {
      this.axisRendererLeft.renderAxisLine(context2D, extraLength);
    }
    if (this.axisRendererRight) {
      this.axisRendererRight.renderAxisLine(context2D, extraLength);
    }

    if (this.xAxisRenderer && this.chartXAxis) {
      this.xAxisRenderer.renderGridLines(context2D);
    }
    if (this.axisRendererLeft && this.axisLeft) {
      this.axisRendererLeft.renderGridLines(context2D);
    }
    if (this.axisRendererRight && this.axisRight) {
      this.axisRendererRight.renderGridLines(context2D);
    }

    if (this.xAxisRenderer && this.chartXAxis) {
      this.xAxisRenderer.renderCustomGridLines(context2D);
      this.chartXAxis.isDrawLimitLinesBehindDataEnabled() &&
      this.xAxisRenderer.renderLimitLines(context2D);
    }
    if (this.axisRendererLeft && this.axisLeft) {
      this.axisRendererLeft.renderCustomGridLines(context2D);
      this.axisLeft.isDrawLimitLinesBehindDataEnabled() &&
      this.axisRendererLeft.renderLimitLines(context2D, this.getHorizontalFlip());
    }
    if (this.axisRendererRight && this.axisRight) {
      this.axisRendererRight.renderCustomGridLines(context2D);
      this.axisRight.isDrawLimitLinesBehindDataEnabled() &&
      this.axisRendererRight.renderLimitLines(context2D, this.getHorizontalFlip());
    }
    context2D.save();

    let rect = this.viewPortHandler.getContentRect();
    context2D.beginPath();
    context2D.rect(rect.left, rect.top, rect.width(), rect.height());
    context2D.closePath();
    context2D.clip();
    this.renderer.drawData(context2D);
    if (this.valuesToHighlight() && this.indicesToHighlight) {
      this.renderer?.drawHighlighted(context2D, this.indicesToHighlight, false);
    }
    context2D.restore();

    if (this.xAxisRenderer && this.chartXAxis) {
      this.xAxisRenderer.renderLimitLines(context2D);
    }
    if (this.axisRendererLeft && this.axisLeft) {
      this.axisRendererLeft.renderLimitLines(context2D, this.getHorizontalFlip());
    }
    if (this.axisRendererRight && this.axisRight) {
      this.axisRendererRight.renderLimitLines(context2D, this.getHorizontalFlip());
    }
    if (this.xAxisRenderer) {
      this.xAxisRenderer.renderAxisLabels(context2D, this.getHorizontalFlip());
    }
    if (this.axisRendererLeft) {
      this.axisRendererLeft.renderAxisLabels(context2D, this.getHorizontalFlip(), true);
    }
    if (this.axisRendererRight) {
      this.axisRendererRight.renderAxisLabels(context2D, this.getHorizontalFlip(), false);
    }
    this.renderer.drawValues(context2D, this.getHorizontalFlip());
  }

  calcExtensionLine(render: YAxisRenderer | null) {
    let extensionLength = 0;
    if (render) {
      if (this.chartXAxis) {
        extensionLength = this.chartXAxis.getYOffset() + this.chartXAxis.labelRotatedHeight / 2 +
        Utils.getLabelTextSize(render.getPaintAxisLine(), '0', this.textSizeCache).height;
      }
    }
    return extensionLength;
  }

  protected prepareValuePxMatrix(): void {
    if (this.rightAxisTransformer && this.chartXAxis && this.axisRight) {
      this.rightAxisTransformer.prepareMatrixValuePx(this.chartXAxis.axisMinimum, this.chartXAxis.axisRange,
        this.axisRight.axisRange, this.axisRight.axisMinimum);
    }
    if (this.leftAxisTransformer && this.chartXAxis && this.axisLeft) {
      this.leftAxisTransformer.prepareMatrixValuePx(this.chartXAxis.axisMinimum, this.chartXAxis.axisRange,
        this.axisLeft.axisRange, this.axisLeft.axisMinimum);
    }
  }

  protected prepareOffsetMatrix(): void {
    if (this.rightAxisTransformer && this.axisRight) {
      this.rightAxisTransformer.prepareMatrixOffset(this.axisRight.isInverted());
    }
    if (this.leftAxisTransformer && this.axisLeft) {
      this.leftAxisTransformer.prepareMatrixOffset(this.axisLeft.isInverted());
    }
  }

  public notifyDataSetChanged(): void {
    if (this.chartData == null) {
      return;
    }
    if (this.renderer != null) {
      this.renderer.initBuffers();
    }
    this.calcMinMax();
    if (this.axisRendererLeft && this.axisLeft) {
      this.axisRendererLeft.computeAxis(this.axisLeft.axisMinimum, this.axisLeft.axisMaximum,
        this.axisLeft.isInverted());
    }
    if (this.axisRendererRight && this.axisRight) {
      this.axisRendererRight.computeAxis(this.axisRight.axisMinimum, this.axisRight.axisMaximum,
        this.axisRight.isInverted());
    }
    if (this.xAxisRenderer && this.chartXAxis) {
      this.xAxisRenderer.computeAxis(this.chartXAxis.axisMinimum, this.chartXAxis.axisMaximum, false);
    }
    this.calculateOffsets();
  }

   calcMinMax(): void {
    if (!this.chartData) {
      return;
    }
    if (this.chartXAxis) {
      this.chartXAxis.calculate(this.chartData.getXMin(), this.chartData.getXMax());
    }
    if (this.axisLeft) {
      this.axisLeft.calculate(this.chartData.getYMin(AxisDependency.LEFT), this.chartData.getYMax(AxisDependency.LEFT));
    }
    if (this.axisRight) {
      this.axisRight.calculate(this.chartData.getYMin(AxisDependency.RIGHT),
        this.chartData.getYMax(AxisDependency.RIGHT));
    }
  }

  public calculateOffsets(): void {
    this.prepareOffsetMatrix();
    this.prepareValuePxMatrix();
    let chartGestureListener = this.getOnChartGestureListener();
    if (chartGestureListener) {
      chartGestureListener.onChartOffsetChanged(this.viewPortHandler);
    }
  }

  public getTransformer(which: AxisDependency): Transformer | null {
    if (which == AxisDependency.LEFT) {
      return this.leftAxisTransformer;
    } else {
      return this.rightAxisTransformer;
    }
  }

  public onTouchEvent(event: TouchEvent): void {
    if (event.touches.length >= 2) {
      return;
    }
    if (this.eventControl.eventIsDisable(EventType.SingleTap)) {
      return;
    }
    if (this.chartTouchListener == null || this.chartData == null) {
      return;
    }
    switch (event.type) {
      case TouchType.Down:
        this.chartTouchListener.actionDown(true, event);
        break;
      case TouchType.Move:
        this.chartTouchListener.actionMove(true, event);
        break;
      case TouchType.Up:
        this.chartTouchListener.actionUp(true, event);
        break;
      default:
        break;
    }
  }

  public onSingleTapUp(isTouchEvent: boolean, event: TouchEvent | GestureEvent): void {
    if (this.eventControl.eventIsDisable(EventType.SingleTap)) {
      return;
    }
    if (this.chartTouchListener) {
      this.chartTouchListener.onSingleTapUp(isTouchEvent, event);
    }
  }

  public calcPos(isTouchEvent: boolean, event: TouchEvent | GestureEvent) {
    return (this?.chartTouchListener as ChartTouchListener).getXyByEvent(isTouchEvent, event);
  }

  public setVisibleXRangeMaximum(maxXRange: number): void {
    let xScale: number = 1;
    if (this.chartXAxis) {
      xScale = this.chartXAxis.axisRange / (maxXRange);
    }
    this.viewPortHandler.setMinimumScaleX(xScale);
  }

  public setVisibleXRangeMinimum(minXRange: number): void {
    let xScale: number = 1;
    if (this.chartXAxis) {
      xScale = this.chartXAxis.axisRange / (minXRange);
    }
    this.viewPortHandler.setMaximumScaleX(xScale);
  }

  public moveViewToX(xValue: number): void {
    if (this.viewPortHandler) {
      let transformer: Transformer | null = this.getTransformer(AxisDependency.LEFT)
      if (transformer) {
        let job: MoveViewJob = MoveViewJob.getInstance(this.viewPortHandler, xValue, 0, transformer, this);
        this.addViewportJob(job);
      }
    }
  }

  public setViewPortOffsets(left: number, top: number, right: number, bottom: number): void {
    this.viewPortHandler.restrainViewPort(left, top, right, bottom);
    this.prepareOffsetMatrix();
    this.prepareValuePxMatrix();
  }

  public getPixelForValues(x: number, y: number, axis: AxisDependency): MPPointD {
    let transformer: Transformer | null = this.getTransformer(axis);
    if (!transformer) {
      transformer = new Transformer(new ViewPortHandler());
    }
    return transformer.getPixelForValues(x, y);
  }

  public getEntryByTouchPoint(x: number, y: number): BarEntry | null {
    let h: Highlight | null = this.getHighlightByTouchPoint(x, y);
    if (h != null && this.chartData) {
      return this.chartData.getEntryForHighlight(h);
    }
    return null;
  }

  public getDataSetByTouchPoint(x: number, y: number): IDataSet | null {
    let h: Highlight | null = this.getHighlightByTouchPoint(x, y);
    if (h != null && this.chartData) {
      return this.chartData.getDataSetByIndex(h.getDataSetIndex()) as IDataSet;
    }
    return null;
  }

  public getLowestVisibleX(): number {
    let transformer: Transformer | null = this.getTransformer(AxisDependency.LEFT);
    if (transformer) {
      transformer.getValuesByTouchPoint(this.viewPortHandler.contentLeft(),
        this.viewPortHandler.contentBottom(), this.posForGetLowestVisibleX);
    }
    let result: number = this.posForGetLowestVisibleX.x;
    if (this.chartXAxis) {
      result = Math.max(this.chartXAxis.axisMinimum, this.posForGetLowestVisibleX.x);
    }
    return result;
  }

  public getHighestVisibleX(): number {
    let transformer: Transformer | null = this.getTransformer(AxisDependency.LEFT);
    if (transformer) {
      transformer.getValuesByTouchPoint(this.viewPortHandler.contentRight(),
        this.viewPortHandler.contentBottom(), this.posForGetHighestVisibleX);
    }
    let result: number = this.posForGetHighestVisibleX.x;
    if (this.chartXAxis) {
      result = Math.min(this.chartXAxis.axisMaximum, this.posForGetHighestVisibleX.x);
    }
    return result;
  }

  public isFullyZoomedOut(): boolean {
    return this.viewPortHandler.isFullyZoomedOut();
  }

  public getAxisLeft(): YAxis | null {
    return this.axisLeft;
  }

  public getAxisRight(): YAxis | null {
    return this.axisRight;
  }

  public getAxis(axis: AxisDependency): YAxis | null {
    if (axis == AxisDependency.LEFT) {
      return this.axisLeft;
    } else {
      return this.axisRight;
    }
  }

  public isInverted(axis: AxisDependency): boolean {
    let axisObj = this.getAxis(axis);
    if (axisObj) {
      return axisObj.isInverted();
    }
    return false;
  }

  public setXAxisRenderer(xAxisRenderer: XAxisRenderer): void {
    this.xAxisRenderer = xAxisRenderer;
  }

  public isAnyAxisInverted(): boolean {
    if (this.axisLeft && this.axisLeft.isInverted()) {
      return true;
    }
    if (this.axisRight && this.axisRight.isInverted()) {
      return true;
    }
    return false;
  }

  public onSizeChanged(w: number, h: number): void {
    super.onSizeChanged(w, h);
    this.viewPortHandler.refresh(this.viewPortHandler.getMatrixTouch(), this);
  }

  public getAxisRendererRight(): YAxisRenderer | null {
    return this.axisRendererRight;
  }

  public updatePaintProperty() {
    this.axisRendererRight?.updatePaintProperty();
    this.axisRendererLeft?.updatePaintProperty();
  }

  getWidth(): number {
    return this.width
  }
}
