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

import { AxisDependency } from '../components/YAxis';
import { Rounding } from '../data/BarDataSet';
import BarEntry from '../data/BarEntry';
import BarDataProvider from '../interfaces/dataprovider/BarDataProvider';
import IDataSet from '../interfaces/datasets/IDataSet';
import MPPointD from '../utils/MPPointD';
import { JArrayList } from '../utils/JArrayList';
import Highlight from './Highlight';
import Transformer from '../utils/Transformer';
import ChartData from '../data/ChartData';

export default class ChartHighlighter<T extends BarDataProvider> {
  protected chart: T;
  protected highlightBuffer: JArrayList<Highlight> = new JArrayList<Highlight>();

  constructor(chart: T) {
    this.chart = chart;
  }

  public getHighlight(x: number, y: number): Highlight | null {
    let pos: MPPointD = this.getValsForTouch(x, y);
    let xVal: number = pos.x;
    MPPointD.recycleInstance(pos);
    let high: Highlight | null = this.getHighlightForX(xVal, x, y);
    return high;
  }

  protected getValsForTouch(x: number, y: number): MPPointD {
    let transformer: Transformer | null = this.chart.getTransformer(AxisDependency.LEFT);
    let pos: MPPointD = MPPointD.getInstance(0, 0);
    if (transformer) {
      pos = transformer.getValuesByTouchPoint(x, y);
    }
    return pos;
  }

  protected getHighlightForX(xVal: number, x: number, y: number): Highlight | null {
    let closestValues: JArrayList<Highlight> | null = this.getHighlightsAtXValue(xVal, x, y);
    if (!closestValues || closestValues.isEmpty()) {
      return null;
    }
    let leftAxisMinDist: number = this.getMinimumDistance(closestValues, y, AxisDependency.LEFT);
    let rightAxisMinDist: number = this.getMinimumDistance(closestValues, y, AxisDependency.RIGHT);
    let axis: AxisDependency = AxisDependency.LEFT;
    if (leftAxisMinDist == Number.MAX_VALUE) {
      axis = AxisDependency.RIGHT;
    } else if (rightAxisMinDist == Number.MAX_VALUE) {
      axis = AxisDependency.LEFT;
    } else {
      axis = leftAxisMinDist < rightAxisMinDist ? AxisDependency.LEFT : AxisDependency.RIGHT;
    }
    let detail: Highlight | null =
      this.getClosestHighlightByPixel(closestValues, x, y, axis, this.chart.getMaxHighlightDistance());
    return detail;
  }

  protected getMinimumDistance(closestValues: JArrayList<Highlight>, pos: number, axis: AxisDependency): number {
    let distance: number = Number.MAX_VALUE;
    for (let i: number = 0; i < closestValues.size(); i++) {
      let high: Highlight | null = closestValues.get(i);
      if (high && high.getAxis() == axis) {
        let tempDistance: number = Math.abs(this.getHighlightPos(high) - pos);
        if (tempDistance < distance) {
          distance = tempDistance;
        }
      }
    }
    return distance;
  }

  protected getHighlightPos(h: Highlight): number {
    return h.getYPx();
  }

  protected getHighlightsAtXValue(xVal: number, x: number, y: number): JArrayList<Highlight> | null {
    this.highlightBuffer.clear();
    let data: ChartData<IDataSet> | null = this.getData();
    if (data == null) {
      return this.highlightBuffer;
    }
    for (let i: number = 0, dataSetCount = data.getDataSetCount(); i < dataSetCount; i++) {
      let dataSet: IDataSet | null = data.getDataSetByIndex(i);
      if (dataSet && !dataSet.isHighlightEnabled()) {
        continue;
      }
      if (dataSet) {
        this.highlightBuffer.addAll(this.buildHighlights(dataSet, i, xVal, Rounding.CLOSEST));
      }
    }
    return this.highlightBuffer;
  }

  protected buildHighlights(set: IDataSet, dataSetIndex: number, xVal: number,
    rounding: Rounding): JArrayList<Highlight> {
    let highlights: JArrayList<Highlight> = new JArrayList<Highlight>();
    let entries: JArrayList<BarEntry> | null = set.getEntriesForXValue(xVal);
    if (entries) {
      if (entries.size() == 0) {
        let closest: BarEntry | null = set.getEntryForXValue(xVal, Number.NaN, rounding);
        if (closest != null) {
          entries = set.getEntriesForXValue(closest.getX());
        }
      }
      if (entries) {
        if (entries.size() == 0) {
          return highlights;
        }
        for (let e of entries.dataSource) {
          let axisObj: AxisDependency | null = set.getAxisDependency();
          if (axisObj !== null) {
            let transformer: Transformer | null = this.chart.getTransformer(axisObj);
            let pixels: MPPointD = MPPointD.getInstance(0, 0);
            if (transformer) {
              pixels = transformer.getPixelForValues(e.getX(), e.getY());
            }
            highlights.add(new Highlight(
              e.getX(), e.getY(),
              dataSetIndex, 0, 0, pixels.x, pixels.y, axisObj));
            MPPointD.recycleInstance(pixels);
          }
        }
      }
    }
    return highlights;
  }

  public getClosestHighlightByPixel(closestValues: JArrayList<Highlight>, x: number, y: number,
                                    axis: AxisDependency, minSelectionDistance: number): Highlight | null {

    let closest: Highlight | null = null;
    let distance: number = minSelectionDistance;
    for (let i: number = 0; i < closestValues.size(); i++) {
      let high: Highlight = closestValues.get(i);
      if (axis == null || high.getAxis() == axis) {
        let cDistance: number = 0;
        cDistance = this.getDistance(x, y, high.getXPx(), high.getYPx());
        if (cDistance < distance) {
          closest = high;
          distance = cDistance;
        }
      }
    }
    return closest;
  }

  protected getDistance(x1: number, y1: number, x2: number, y2: number): number {
    return Math.hypot(x1 - x2, y1 - y2);
  }

  protected getData(): ChartData<IDataSet> | null {
    return this.chart.getData();
  }
}