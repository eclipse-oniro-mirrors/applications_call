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

import AxisBase from '../components/AxisBase'
import Paint, { Style } from '../data/Paint'
import Utils from '../utils/Utils'
import Transformer from '../utils/Transformer'
import ViewPortHandler from '../utils/ViewPortHandler'
import MPPointD from '../utils/MPPointD'

export default abstract class AxisRenderer {
  protected axis: AxisBase;
  protected trans: Transformer | null = null;
  protected gridPaint: Paint = new Paint();
  protected axisLabelPaint: Paint = new Paint();
  protected axisLinePaint: Paint = new Paint();
  protected limitLinePaint: Paint = new Paint();
  protected viewPortHandler: ViewPortHandler | null = null;

  constructor(viewPortHandler: ViewPortHandler, axis: AxisBase, trans?: Transformer) {
    if (viewPortHandler) {
      this.viewPortHandler = viewPortHandler;
    }
    this.trans = trans ? trans : null;
    this.axis = axis;

    if (this.viewPortHandler != null) {
      this.axisLabelPaint = new Paint();

      this.gridPaint = new Paint();
      this.gridPaint.setColor(Color.Gray);
      this.gridPaint.setStrokeWidth(1);
      this.gridPaint.setStyle(Style.STROKE);
      this.gridPaint.setGlobalAlpha(90 / 255);

      this.axisLinePaint = new Paint();
      this.axisLinePaint.setColor(Color.Black)
      this.axisLinePaint.setStrokeWidth(1)
      this.axisLinePaint.setStyle(Style.STROKE)

      this.limitLinePaint = new Paint();
      this.limitLinePaint.setStyle(Style.STROKE)
    }
  }

  public getPaintAxisLabels(): Paint {
    return this.axisLabelPaint;
  }

  public getPaintAxisLine(): Paint {
    return this.axisLinePaint;
  }

  public getAxis(): AxisBase {
    return this.axis;
  }

  public getGridPaint(): Paint {
    return this.gridPaint;
  }

  public getLimitLinePaint(): Paint {
    return this.limitLinePaint;
  }

  public computeAxis(min: number, max: number, inverted: boolean) {
    if (this.trans && this.viewPortHandler != null && this.viewPortHandler.contentWidth() > 10 &&
      !this.viewPortHandler.isFullyZoomedOutY()) {
      let p1: MPPointD | undefined =
        this.trans.getValuesByTouchPoint(this.viewPortHandler.contentLeft(), this.viewPortHandler.contentTop());
      let p2: MPPointD | undefined =
        this.trans.getValuesByTouchPoint(this.viewPortHandler.contentLeft(), this.viewPortHandler.contentBottom());

      if (!!p1 && !!p2) {
        if (!inverted) {
          min = p2.y;
          max = p1.y;
        } else {
          min = p1.y;
          max = p2.y;
        }
        MPPointD.recycleInstance(p1);
        MPPointD.recycleInstance(p2);
      }
    }
    this.computeAxisValues(min, max);
  }

  protected computeAxisValues(min: number, max: number) {
    let yMin = min;
    let yMax = max;
    if (this.axis) {
      let labelCount = this.axis.getLabelCount();
      let range = Math.abs(yMax - yMin);
      if (labelCount == 0 || range <= 0 || range == Number.POSITIVE_INFINITY) {
        this.axis.entries = [];
        this.axis.centeredEntries = [];
        this.axis.entryCount = 0;
        return;
      }

      let rawInterval: number = range / labelCount;
      let interval: number = Utils.roundToNextSignificant(rawInterval);
      if (this.axis.isGranularityEnabled()) {
        interval = interval < this.axis.getGranularity() ? this.axis.getGranularity() : interval;
      }
      let intervalMagnitude = Utils.roundToNextSignificant(Math.pow(10, Math.floor(Math.log10(interval))));
      let intervalSigDigit = Math.floor((interval / intervalMagnitude));
      if (intervalSigDigit > 5) {
        interval = Math.floor(10.0 * intervalMagnitude) == 0.0 ? interval : Math.floor(10.0 * intervalMagnitude);
      }
      let n = this.axis.isCenterAxisLabelsEnabled() ? 1 : 0;
      if (this.axis.isForceLabelsEnabled()) {
        interval = range / (labelCount - 1);
        this.axis.entryCount = labelCount;
        if (this.axis.entries.length < labelCount) {
          this.axis.entries = new Array<number>(labelCount);
        }
        let v = min;
        for (let i = 0; i < labelCount; i++) {
          this.axis.entries[i] = v;
          v += interval;
        }
        n = labelCount;
      } else {
        let first = interval == 0.0 ? 0.0 : Math.ceil(yMin / interval) * interval;
        if (this.axis.isCenterAxisLabelsEnabled()) {
          first -= interval;
        }
        let last = interval == 0.0 ? 0.0 : Utils.nextUp(Math.floor(yMax / interval) * interval);
        let f: number = 0;
        let i: number = 0;
        if (interval != 0.0 && last != first) {
          for (f = first; f <= last; f += interval) {
            ++n;
          }
        } else if (last == first && n == 0) {
          n = 1;
        }
        this.axis.entryCount = n;
        if (this.axis.entries.length < n) {
          this.axis.entries = new Array<number>(n);
        }
        for (f = first, i = 0; i < n; f += interval, ++i) {
          // Fix for negative zero case (Where value == -0.0, and 0.0 == -0.0)
          if (f == 0.0) {
            f = 0.0;
          }
          this.axis.entries[i] = f;
        }
      }
      if (interval < 1) {
        this.axis.decimals = Math.floor(Math.ceil(-Math.log10(interval)));
      } else {
        this.axis.decimals = 0;
      }
      if (this.axis.isCenterAxisLabelsEnabled()) {
        if (this.axis.centeredEntries.length < n) {
          this.axis.centeredEntries = new Array<number>(n);
        }
        let offset: number = interval / 2;
        for (let i = 0; i < n; i++) {
          this.axis.centeredEntries[i] = this.axis.entries[i] + offset;
        }
      }
    }
  }

  public abstract renderAxisLabels(c: CanvasRenderingContext2D, isHorizontalFlip: boolean, isLeftAxis: boolean): void;

  public abstract renderGridLines(c: CanvasRenderingContext2D): void;

  public abstract renderAxisLine(c: CanvasRenderingContext2D, extraLine?: number): void;

  public abstract renderLimitLines(c: CanvasRenderingContext2D, isHorizontalFlip: boolean): void;
}
