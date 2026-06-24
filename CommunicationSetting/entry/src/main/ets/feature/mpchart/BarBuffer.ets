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

import BarEntry from './data/BarEntry';
import IDataSet from './interfaces/datasets/IDataSet';

export default class BarBuffer {
  private containsStacks: boolean = false;
  private inverted: boolean = false;
  private barWidth: number = 1;
  private index: number = 0;
  public buffer: number[] = [];

  constructor(containsStacks: boolean) {
    this.index = 0;
    this.containsStacks = containsStacks;
  }

  public setBarWidth(barWidth: number): void {
    this.barWidth = barWidth;
  }

  public getBarWidth(): number {
    return this.barWidth;
  }

  public getIndex(): number {
    return this.index;
  }

  public setInverted(isInverted: boolean): void {
    this.inverted = isInverted;
  }

  protected addBar(left: number, top: number, right: number, bottom: number): void {
    this.buffer[this.index++] = left;
    this.buffer[this.index++] = top;
    this.buffer[this.index++] = right;
    this.buffer[this.index++] = bottom;
  }

  private getBar(x: number, y: number):void {
    let barWidthHalf: number = this.barWidth / 2;
    let left: number = x - barWidthHalf;
    let right: number = x + barWidthHalf;
    let bottom: number = 0;
    let top: number = 0;
    if (this.inverted) {
      bottom = y >= 0 ? y : 0;
      top = y <= 0 ? y : 0;
    } else {
      top = y >= 0 ? y : 0;
      bottom = y <= 0 ? y : 0;
    }
    this.addBar(left, top, right, bottom);
  }

  public feedBar(e: BarEntry): void {
    let x: number = e.getX();
    let y: number = e.getY();
    let values: number[] = e.getYVals() as number[];
    let posY: number = 0;
    let negY: number = -e.getNegativeSum();
    let yStart: number = 0;
    for (let k = 0; k < values.length; k++) {
      let value: number = values[k];
      if (value == 0.0 && (posY == 0.0 || negY == 0.0)) {
        y = value;
        yStart = y;
      } else if (value >= 0.0) {
        y = posY;
        yStart = posY + value;
        posY = yStart;
      } else {
        y = negY;
        yStart = negY + Math.abs(value);
        negY += Math.abs(value);
      }
      this.getBar(x, y);
    }
  }

  public feed(data: IDataSet): void {
    let size: number = data.getEntryCount();
    for (let i = 0; i < size; i++) {
      let e: BarEntry | null = data.getEntryForIndex(i);
      if (e === null) {
        continue;
      }
      let x: number = e.getX();
      let y: number = e.getY();
      let values: number[] | null = e.getYVals();
      if (!this.containsStacks || values === null) {
        this.getBar(x, y);
      } else {
        this.feedBar(e);
      }
    }
    this.index = 0;
  }
}
