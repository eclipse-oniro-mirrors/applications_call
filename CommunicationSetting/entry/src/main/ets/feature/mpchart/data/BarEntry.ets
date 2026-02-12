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

import Range from '../highlight/Range';

export default class BarEntry {
  private yVals: number[] | null = null;
  private ranges: Range[] | null = null;
  private negativeSum: number = 0.0;
  private positiveSum: number = 0.0;
  private x: number = 0.0;
  private y: number = 0;

  public getX(): number {
    return this.x;
  }

  public getY(): number {
    return this.y;
  }

  constructor(x?: number, y?: number | number[]) {
    if (y) {
      let yValue = Array.isArray(y) ? BarEntry.calcSum(y) : y;
      this.y = yValue;
    }
    this.x = x ? x : 0;
    if (Array.isArray(y)) {
      this.yVals = y;
      this.calcPosNegSum();
      this.calcRanges();
    }
  }

  public getYVals(): number[] | null {
    return this.yVals;
  }

  public getRanges(): Range[] | null {
    return this.ranges;
  }

  public setRanges(ranges: Range[] | null) {
    this.ranges = ranges;
  }

  public isStacked(): boolean {
    return !!this.yVals;
  }

  public getPositiveSum(): number {
    return this.positiveSum;
  }

  public getNegativeSum(): number {
    return this.negativeSum;
  }

  private calcPosNegSum(): void {
    if (this.yVals == null) {
      this.negativeSum = 0;
      this.positiveSum = 0;
      return;
    }
    let sumNeg: number = 0;
    let sumPos: number = 0;
    for (let f of this.yVals) {
      if (f <= 0) {
        sumNeg += Math.abs(f);
      } else {
        sumPos += f;
      }
    }
    this.negativeSum = sumNeg;
    this.positiveSum = sumPos;
  }

  public static calcSum(vals: number[]): number {
    if (vals == null) {
      return 0;
    }
    let sum: number = 0;
    for (let f of vals) {
      sum += f;
    }
    return sum;
  }

  protected calcRanges(): void {
    let values: number[] | null = this.getYVals();
    if (values == null || values.length == 0) {
      return;
    }
    this.ranges = new Array(values.length);
    let negRemain: number = -this.getNegativeSum();
    let posRemain: number = 0;
    for (let i = 0; i < this.ranges.length; i++) {
      let value: number = values[i];
      if (value < 0) {
        this.ranges[i] = new Range(negRemain, negRemain - value);
        negRemain -= value;
      } else {
        this.ranges[i] = new Range(posRemain, posRemain + value);
        posRemain += value;
      }
    }
  }
}
