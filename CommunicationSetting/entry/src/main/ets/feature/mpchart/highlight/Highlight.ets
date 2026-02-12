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

export default class Highlight {
  public mX: number = Number.NaN;
  private mY: number = Number.NaN;
  private xPx: number = 0;
  private yPx: number = 0;
  private dataIndex: number = -1;
  private dataSetIndex: number = 0;
  private stackIndex: number = -1;
  private axis: AxisDependency | null = null;
  private drawX: number = 0;
  private drawY: number = 0;

  constructor(x: number, y: number, dataSetIndex: number, dataIndex: number, stackIndex: number, xPx: number,
    yPx: number, axis: AxisDependency | null) {
    this.mX = x;
    if (y == null || y == undefined) {
      this.mY = Number.NaN
    } else {
      this.mY = y;
    }
    this.dataSetIndex = dataSetIndex ? dataSetIndex : 0;
    this.stackIndex = stackIndex ? stackIndex : 0;
    if (dataIndex == null || dataIndex == undefined) {
      this.dataIndex = -1;
    } else {
      this.dataIndex = dataIndex;
    }
    this.xPx = xPx ? xPx : 0;
    this.yPx = yPx ? yPx : 0;
    this.axis = axis == undefined ? null : axis;
  }

  public getX(): number {
    return this.mX;
  }

  public getY(): number {
    return this.mY;
  }

  public getXPx(): number {
    return this.xPx;
  }

  public getYPx(): number {
    return this.yPx;
  }

  public getDataSetIndex(): number {
    return this.dataSetIndex;
  }

  public getStackIndex(): number {
    return this.stackIndex;
  }

  public getAxis(): AxisDependency | null {
    return this.axis;
  }

  public setDraw(x: number, y: number): void {
    this.drawX = x;
    this.drawY = y;
  }

  public getDrawX(): number {
    return this.drawX;
  }

  public getDrawY(): number {
    return this.drawY;
  }

  public equalTo(h: Highlight | null): boolean {
    if (h == null) {
      return false;
    } else {
      if (this.dataSetIndex == h.dataSetIndex && this.mX == h.mX && this.stackIndex == h.stackIndex &&
        this.dataIndex == h.dataIndex) {
        return true;
      } else {
        return false;
      }
    }
  }
}
