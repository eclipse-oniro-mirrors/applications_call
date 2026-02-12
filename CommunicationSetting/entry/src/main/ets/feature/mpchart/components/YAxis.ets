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

import AxisBase from './AxisBase';

export enum AxisDependency {
  LEFT, RIGHT
}

export enum YAxisLabelPosition {
  OUTSIDE_CHART, INSIDE_CHART
}

export default class YAxis extends AxisBase {
  private inverted: boolean = false;
  private zeroLineWidth: number = 1;
  private position: YAxisLabelPosition = YAxisLabelPosition.OUTSIDE_CHART;
  public axisDependency: AxisDependency;

  constructor(position?: AxisDependency) {
    super();
    if (!position) {
      this.axisDependency = AxisDependency.LEFT;
    } else {
      this.axisDependency = position;
    }
    this.yOffset = 0;
  }

  public getAxisDependency(): AxisDependency {
    return this.axisDependency;
  }

  public getLabelPosition(): YAxisLabelPosition {
    return this.position;
  }

  public setPosition(pos: YAxisLabelPosition): void {
    this.position = pos;
  }

  public isInverted(): boolean {
    return this.inverted;
  }

  public getZeroLineWidth(): number {
    return this.zeroLineWidth;
  }

  public calculate(dataMin: number, dataMax: number): void {
    let min: number = dataMin;
    let max: number = dataMax;
    if (min > max) {
      if (this.customAxisMax && this.customAxisMin) {
        let t: number = min;
        min = max;
        max = t;
      } else if (this.customAxisMax) {
        min = max < 0 ? max * 1.5 : max * 0.5;
      } else if (this.customAxisMin) {
        max = min < 0 ? min * 0.5 : min * 1.5;
      }
    }
    let range: number = Math.abs(max - min);
    if (range == 0) {
      max = max + 1;
      min = min - 1;
    }
    range = Math.abs(max - min);
    this.axisMinimum = this.customAxisMin ? this.axisMinimum : min - (range / 100) * 10;
    this.axisMaximum = this.customAxisMax ? this.axisMaximum : max + (range / 100) * 10;
    this.axisRange = Math.abs(this.axisMinimum - this.axisMaximum);
  }
}
