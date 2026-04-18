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
import Highlight from '../highlight/Highlight';
import IDataSet from '../interfaces/datasets/IDataSet';
import { JArrayList } from '../utils/JArrayList';
import BarEntry from './BarEntry';

export default class ChartData<T extends IDataSet> {
  protected yMax: number = -Number.MAX_VALUE;
  protected yMin: number = Number.MAX_VALUE;
  protected xMax: number = -Number.MAX_VALUE;
  protected xMin: number = Number.MAX_VALUE;
  protected leftAxisMax: number = -Number.MAX_VALUE;
  protected leftAxisMin: number = Number.MAX_VALUE;
  protected rightAxisMax = -Number.MAX_VALUE;
  protected rightAxisMin: number = Number.MAX_VALUE;
  protected dataSets: JArrayList<T> = new JArrayList<T>();

  constructor(dataSets?: JArrayList<T> | T[]) {
    if (dataSets) {
      if (dataSets instanceof JArrayList) {
        this.dataSets = dataSets;
      } else {
        this.dataSets = this.arrayToList(dataSets);
      }
      this.notifyDataChanged();
    } else {
      this.dataSets = new JArrayList<T>();
    }
  }
  private arrayToList(array: T[]): JArrayList<T> {
    let list = new JArrayList<T>();
    for (let i = 0; i < array.length; i++) {
      let data: T = array[i];
      list.add(data);
    }
    return list;
  }

  public notifyDataChanged(): void {
    this.calcMinMax();
  }

  private getLeft(): void {
    let firstLeft: T | null = this.getFirstLeft(this.dataSets);
    if (firstLeft) {
      this.leftAxisMax = firstLeft.getYMax();
      this.leftAxisMin = firstLeft.getYMin();
      for (let dataSet of this.dataSets.dataSource) {
        if (dataSet.getAxisDependency() == AxisDependency.LEFT) {
          if (dataSet.getYMin() < this.leftAxisMin) {
            this.leftAxisMin = dataSet.getYMin();
          }
          if (dataSet.getYMax() > this.leftAxisMax) {
            this.leftAxisMax = dataSet.getYMax();
          }
        }
      }
    }
  }

  private getRight(): void {
    let firstRight: T | null = this.getFirstRight(this.dataSets);
    if (firstRight) {
      this.rightAxisMax = firstRight.getYMax();
      this.rightAxisMin = firstRight.getYMin();
      for (let dataSet of this.dataSets.dataSource) {
        if (dataSet.getAxisDependency() == AxisDependency.RIGHT) {
          if (dataSet.getYMin() < this.rightAxisMin) {
            this.rightAxisMin = dataSet.getYMin();
          }
          if (dataSet.getYMax() > this.rightAxisMax) {
            this.rightAxisMax = dataSet.getYMax();
          }
        }
      }
    }
  }

  public calcMinMax() {
    if (this.dataSets == null) {
      return;
    }
    this.yMax = -Number.MAX_VALUE;
    this.yMin = Number.MAX_VALUE;
    this.xMax = -Number.MAX_VALUE;
    this.xMin = Number.MAX_VALUE;
    for (let dataSet of this.dataSets.dataSource) {
      this.calcMinMax1(dataSet);
    }
    this.leftAxisMax = -Number.MAX_VALUE;
    this.leftAxisMin = Number.MAX_VALUE;
    this.rightAxisMax = -Number.MAX_VALUE;
    this.rightAxisMin = Number.MAX_VALUE;
    this.getLeft();
    this.getRight();
  }

  protected getFirstLeft(sets: JArrayList<T>): T | null {
    for (let dataSet of sets.dataSource) {
      if (dataSet.getAxisDependency() == AxisDependency.LEFT) {
        return dataSet;
      }
    }
    return null;
  }

  public getFirstRight(sets: JArrayList<T>): T | null {
    for (let dataSet of sets.dataSource) {
      if (dataSet.getAxisDependency() == AxisDependency.RIGHT) {
        return dataSet;
      }
    }
    return null;
  }

  protected calcMinMax1(d: T): void {
    if (this.yMax < d.getYMax()) {
      this.yMax = d.getYMax();
    }
    if (this.yMin > d.getYMin()) {
      this.yMin = d.getYMin();
    }
    if (this.xMax < d.getXMax()) {
      this.xMax = d.getXMax();
    }
    if (this.xMin > d.getXMin()) {
      this.xMin = d.getXMin();
    }
    if (d.getAxisDependency() == AxisDependency.LEFT) {
      if (this.leftAxisMax < d.getYMax()) {
        this.leftAxisMax = d.getYMax();
      }
      if (this.leftAxisMin > d.getYMin()) {
        this.leftAxisMin = d.getYMin();
      }
    } else {
      if (this.rightAxisMax < d.getYMax()) {
        this.rightAxisMax = d.getYMax();
      }
      if (this.rightAxisMin > d.getYMin()) {
        this.rightAxisMin = d.getYMin();
      }
    }
  }

  public getDataSetCount(): number {
    if (this.dataSets == null) {
      return 0;
    }
    return this.dataSets.listSize;
  }

  public getYMin(axis ?: AxisDependency): number {
    if (axis == null) {
      return this.yMin;
    }
    if (axis == AxisDependency.LEFT) {
      if (this.leftAxisMin == Number.MAX_VALUE) {
        return this.rightAxisMin;
      } else {
        return this.leftAxisMin;
      }
    } else {
      if (this.rightAxisMin == Number.MAX_VALUE) {
        return this.leftAxisMin;
      } else {
        return this.rightAxisMin;
      }
    }
  }

  public getYMax(axis?: AxisDependency): number {
    if (axis == null) {
      return this.yMax;
    }
    if (axis == AxisDependency.LEFT) {
      if (this.leftAxisMax == -Number.MAX_VALUE) {
        return this.rightAxisMax;
      } else {
        return this.leftAxisMax;
      }
    } else {
      if (this.rightAxisMax == -Number.MAX_VALUE) {
        return this.leftAxisMax;
      } else {
        return this.rightAxisMax;
      }
    }
  }

  public getXMin(): number {
    return this.xMin;
  }

  public getXMax(): number {
    return this.xMax;
  }

  public getDataSets(): JArrayList<T> {
    return this.dataSets;
  }

  public getEntryForHighlight(highlight: Highlight): BarEntry | null {
    if (!this.dataSets) {
      return null;
    }
    if (highlight.getDataSetIndex() >= this.dataSets.size()) {
      return null;
    } else {
      return this.dataSets.get(highlight.getDataSetIndex()).getEntryForXValue(highlight.getX(), highlight.getY());
    }
  }

  public getDataSetByIndex(index: number): T | null {
    if (this.dataSets == null || index < 0 || index >= this.dataSets.size()) {
      return null;
    }
    return this.dataSets.get(index);
  }

  public setValueTextSize(size: number): void {
    if (this.dataSets) {
      for (let data of this.dataSets.dataSource) {
        data.setValueTextSize(size);
      }
    }
  }

  public setHighlightEnabled(enabled: boolean): void {
    if (this.dataSets) {
      for (let data of this.dataSets.dataSource) {
        data.setHighlightEnabled(enabled);
      }
    }
  }

  public getEntryCount(): number {
    let count: number = 0;
    if (this.dataSets) {
      for (let data of this.dataSets.dataSource) {
        count += data.getEntryCount();
      }
    }
    return count;
  }
}
