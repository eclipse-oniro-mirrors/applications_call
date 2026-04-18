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

import ChartHighlighter from '../highlight/ChartHighlighter';
import Highlight from '../highlight/Highlight';
import ViewPortHandler from '../utils/ViewPortHandler';
import { XAxis } from '../components/XAxis';
import Paint from '../data/Paint';
import DefaultValueFormatter from '../formatter/DefaultValueFormatter';
import IDataSet from '../interfaces/datasets/IDataSet';
import BarEntry from '../data/BarEntry';
import OnChartValueSelectedListener from '../listener/OnChartValueSelectedListener';
import ChartTouchListener from '../listener/ChartTouchListener';
import OnChartGestureListener from '../listener/OnChartGestureListener';
import DataRenderer from '../renderer/DataRenderer';
import Utils from '../utils/Utils';
import MPPointF from '../utils/MPPointF';
import ChartData from '../data/ChartData';
import BarDataProvider from '../interfaces/dataprovider/BarDataProvider';
import ChartInterface from '../interfaces/dataprovider/ChartInterface';
import { LogUtil } from '../utils/LogUtil';
import { JArrayList } from '../utils/JArrayList';
import MoveViewJob from '../jobs/MoveViewJob';
import CanvasUtil from '../utils/CanvasUtil';

export enum LastGesture {
  NONE, SINGLE_TAP, LONG_PRESS
}

export default abstract class ChartModel<T extends ChartData<IDataSet>> implements ChartInterface {
  public jobs: JArrayList<MoveViewJob> = new JArrayList<MoveViewJob>();
  public chartData: T | null = null;
  public defaultValueFormatter: DefaultValueFormatter = new DefaultValueFormatter(0);
  public infoPaint: Paint = new Paint();
  public chartXAxis: XAxis | null = null;
  public selectionListener: OnChartValueSelectedListener | null = null;
  public chartTouchListener: ChartTouchListener | null = null;
  public noDataText: string = 'No chart data available.';
  public gestureListener: OnChartGestureListener | null = null;
  public renderer: DataRenderer | null = null;
  public highlighter: ChartHighlighter<BarDataProvider> | null = null;
  public viewPortHandler: ViewPortHandler = new ViewPortHandler();
  protected width: number = Utils.handleDataValues(50);
  private height: number = Utils.handleDataValues(50);
  public offsetsCalculated: boolean = false;
  public chartSizeCorrected: boolean = false;
  public indicesToHighlight: Highlight[] | null = null;
  public maxHighlightDistance: number = 0;
  protected lastGesture = LastGesture.NONE;

  public init() {
    this.maxHighlightDistance = Utils.handleDataValues(500);
    this.chartXAxis = new XAxis();
    this.infoPaint = new Paint();
    this.infoPaint.setColor(Utils.rgb(247, 189, 51));
    this.infoPaint.setTextAlign('center');
    this.infoPaint.setTextSize(Utils.handleDataValues(12));
  }

  public setData(data: T | null) {
    this.chartData = data;
    this.offsetsCalculated = false;

    if (data === null) {
      return;
    }
    this.setupDefaultFormatter(data.getYMin(), data.getYMax());
    if (this.chartData) {
      const dataSets = this.chartData.getDataSets();
      for (let i = 0; i < dataSets.size(); i++) {
        const item = dataSets.get(i);
        if (item.needsFormatter() || item.getValueFormatter() === this.defaultValueFormatter) {
          item.setValueFormatter(this.defaultValueFormatter);
        }
      }
    }
    this.notifyDataSetChanged();
    this.invalidate();
  }

  public clear() {
    this.chartData = null;
    this.offsetsCalculated = false;
    this.indicesToHighlight = null;
    if (this.chartTouchListener) {
      this.chartTouchListener.setLastHighlighted();
    }
    this.invalidate();
  }

  public addViewportJob(job: MoveViewJob) {
    if (this.viewPortHandler.hasChartDimension()) {
      job.run();
    } else {
      this.jobs.add(job);
    }
  }

  public setupDefaultFormatter(min: number, max: number) {
    let reference: number = 0;
    if (this.chartData == null || this.chartData.getEntryCount() < 2) {
      reference = Math.max(Math.abs(min), Math.abs(max));
    } else {
      reference = Math.abs(max - min);
    }
    let digits: number = Utils.getDecimals(reference);
    this.defaultValueFormatter.setup(digits);
  }

  public onDraw(c: CanvasRenderingContext2D): void {
    if (!this.chartSizeCorrected) {
      return;
    }
    if (this.chartData == null) {
      CanvasUtil.clearCanvas(c);
      let hasText: boolean = !this.strIsEmpty(this.noDataText);
      if (hasText) {
        let pt: MPPointF = MPPointF.getInstance(this.width / 2, this.height / 2);
        if (!pt) {
          return;
        }
        Utils.resetContext2DWithoutLine(c, this.infoPaint);
        if (this.infoPaint) {
          switch (this.infoPaint.getTextAlign()) {
            case 'start':
              pt.x = 0;
              c.strokeText(this.noDataText, pt.x, pt.y);
              break;
            case 'end':
              pt.x *= 2.0;
              c.strokeText(this.noDataText, pt.x, pt.y);
              break;
            default:
              c.strokeText(this.noDataText, pt.x, pt.y);
              break;
          }
        }
        MPPointF.recycleInstance(pt);
        return;
      }
    }
    if (!this.offsetsCalculated && this.chartSizeCorrected) {
      this.calculateOffsets();
      this.offsetsCalculated = true;
    }
  }

  public strIsEmpty(str: string): boolean {
    return str == null || str.length == 0;
  }

  public setLastGestureSingleTap() {
    this.lastGesture = LastGesture.SINGLE_TAP;
  }

  public getMaxHighlightDistance(): number {
    return this.maxHighlightDistance;
  }

  public valuesToHighlight(): boolean {
    return this.indicesToHighlight == null || this.indicesToHighlight.length <= 0 ||
      this.indicesToHighlight[0] == null ? false : true;
  }

  public setLastHighlighted(highs: Highlight[]) {
    if (this.chartTouchListener) {
      if (highs == null || highs.length <= 0 || highs[0] == null) {
        this.chartTouchListener.setLastHighlighted();
      } else {
        this.chartTouchListener.setLastHighlighted(highs[0]);
      }
    }
  }

  public highlightValueForObject(high: Highlight | null, callListener?: boolean) {
    if (callListener == null || callListener == undefined) {
      callListener = false;
    }
    let e: BarEntry | null = null;
    if (high == null) {
      this.indicesToHighlight = null;
    } else {
      if (this.chartData) {
        e = this.chartData.getEntryForHighlight(high);
        if (e == null) {
          this.indicesToHighlight = null;
          high = null;
        } else {
          this.indicesToHighlight = [high];
        }
      }
    }
    if (this.indicesToHighlight) {
      this.setLastHighlighted(this.indicesToHighlight);
    }
    if (callListener && this.selectionListener != null) {
      let isHighLight = this.valuesToHighlight();
      if (!isHighLight) {
        this.selectionListener.onNothingSelected();
      } else {
        if (this.selectionListener && e) {
          this.selectionListener.onValueSelected(e);
        }
      }
    }
    this.invalidate();
  }

  public getHighlightByTouchPoint(x: number, y: number): Highlight | null {
    if (this.chartData == null) {
      LogUtil.error('mpchart: Can not select by touch. No data set.')
      return null;
    } else {
      let hghLighter = this.getHighlighter();
      if (hghLighter) {
        return hghLighter.getHighlight(x, y);
      } else {
        return null;
      }
    }
  }

  public getXAxis(): XAxis | null {
    return this.chartXAxis;
  }

  public setOnChartValueSelectedListener(l: OnChartValueSelectedListener) {
    this.selectionListener = l;
  }

  public setOnChartGestureListener(l: OnChartGestureListener): void {
    this.gestureListener = l;
  }

  public getOnChartGestureListener(): OnChartGestureListener | null {
    return this.gestureListener;
  }

  public setOnTouchListener(l: ChartTouchListener) {
    this.chartTouchListener = l;
  }

  public getOnTouchListener(): ChartTouchListener | null {
    return this.chartTouchListener;
  }

  public getWidth(): number {
    return this.width
  }

  public getData(): T | null {
    return this.chartData;
  }

  public getViewPortHandler(): ViewPortHandler {
    return this.viewPortHandler;
  }

  public getHighlighter(): ChartHighlighter<BarDataProvider> | null {
    return this.highlighter;
  }

  public setHighlighter(highlighter: ChartHighlighter<BarDataProvider>) {
    this.highlighter = highlighter;
  }

  public onSizeChanged(w: number, h: number): void {
    this.chartSizeCorrected = true;
    this.width = w;
    this.height = h;
    if (w > 0 && h > 0 && w < 10000 && h < 10000) {
      this.viewPortHandler.setChartDimension(w, h);
    }
    this.notifyDataSetChanged();
    let jobs = this.jobs;
    let length = jobs.length();
    for (let i = 0; i < length; i++) {
      jobs.get(i).run();
    }
    jobs.clear();
  }

  public clearJobs() {
    const length = this.jobs.length();
    for (let i = 0; i < length; i++) {
      MoveViewJob.recycleInstance(this.jobs.get(i));
    }
  }

  public abstract notifyDataSetChanged();

  protected abstract calculateOffsets();

  protected abstract calcMinMax();

  public abstract invalidate();

  public abstract setContext2D(context2d: CanvasRenderingContext2D);

  public abstract onChartSizeChanged(newWidth: number, newHeight: number);
}
