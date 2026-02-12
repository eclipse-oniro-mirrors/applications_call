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

import { JArrayList } from '../utils/JArrayList';
import { JList } from '../utils/JList';
import BarEntry from './BarEntry';
import Utils from '../utils/Utils';
import { LogUtil } from '../utils/LogUtil';
import { FontFamily } from './Paint';
import IDataSet from '../interfaces/datasets/IDataSet';
import { AxisDependency } from '../components/YAxis';
import IAxisValueFormatter from '../formatter/IAxisValueFormatter';
import DefaultValueFormatter from '../formatter/DefaultValueFormatter';
import MPPointF from '../utils/MPPointF';

export default class BarDataSet implements IDataSet {
  private entries: JArrayList<BarEntry> | null = new JArrayList<BarEntry>();
  protected yMax: number = -Number.MAX_VALUE;
  protected yMin: number = Number.MAX_VALUE;
  private colors: JArrayList<Number> = new JArrayList<Number>();
  private valueColors: JArrayList<Number> = new JArrayList<Number>();
  private label: string = 'DataSet';
  private axisDependency: AxisDependency = AxisDependency.LEFT;
  private highlightEnabled: boolean = true;
  private valueFormatter: IAxisValueFormatter | null = null;
  private valueTypeface: FontFamily = '';
  private drawValues: boolean = true;
  private iconsOffset: MPPointF = new MPPointF();
  protected valueTextSize: number = 8.0;
  protected xMax: number = -Number.MAX_VALUE;
  protected xMin: number = Number.MAX_VALUE;
  private stackSize: number = 1;
  private highLightColor: number = 0xffbb73;

  constructor(entries: JArrayList<BarEntry>, label: string) {
    this.colors = new JArrayList<number>();
    this.valueColors = new JArrayList<number>();
    this.colors.add(0x8ceaff);
    this.valueColors.add(0x000000);
    if (label != undefined) {
      this.label = label;
    } else {
      this.label = 'DataSet';
    }
    this.entries = entries;
    if (!this.entries || this.entries == null) {
      this.entries = new JArrayList<BarEntry>();
    }
    this.calcMinMax();
    this.highLightColor = 0x000000;
    this.calcStackSize(entries);
  }

  private calcStackSize(yVals: JList<BarEntry>): void {
    for (let i = 0; i < yVals.length(); i++) {
      let vals: number[] | null = yVals.get(i).getYVals();
      if (vals != null && vals.length > this.stackSize) {
        this.stackSize = vals.length;
      }
    }
  }

  public setHighLightColor(color: number): void {
    this.highLightColor = color;
  }
  public getHighLightColor(): number {
    return this.highLightColor;
  }

  public isStacked(): boolean {
    return this.stackSize > 1 ? true : false;
  }



  public calcMinMax(): void {
    this.yMax = -Number.MAX_VALUE;
    this.yMin = Number.MAX_VALUE;
    this.xMax = -Number.MAX_VALUE;
    this.xMin = Number.MAX_VALUE;
    if (!this.entries || this.entries == null || this.entries.isEmpty()) {
      return;
    }
    for (let e of this.entries.dataSource) {
      this.myCalcMinMax(e);
    }
  }

  public myCalcMinMax(e ?: BarEntry): void {
    if (!e) {
      return;
    }
    this.calcMinMaxX(e);
    this.myCalcMinMaxY(e);
  }

  public calcMinMaxY(fromX: number, toX: number): void {
    this.yMax = -Number.MAX_VALUE;
    this.yMin = Number.MAX_VALUE;
    if (!this.entries || this.entries == null || this.entries.isEmpty()) {
      return;
    }
    let indexFrom: number = this.getEntryIndex(fromX, Number.NaN, Rounding.DOWN);
    let indexTo: number = this.getEntryIndex(toX, Number.NaN, Rounding.UP);
    if (indexTo < indexFrom) {
      return;
    }
    for (let i: number = indexFrom; i <= indexTo; i++) {
      this.myCalcMinMaxY(this.entries.get(i));
    }
  }

  public serEntries(entries:JArrayList<BarEntry> | null) {
    this.entries = entries;
  }

  protected calcMinMaxX(e: BarEntry): void {
    if (e.getX() < this.xMin) {
      this.xMin = e.getX();
    }
    if (e.getX() > this.xMax) {
      this.xMax = e.getX();
    }
  }

  protected myCalcMinMaxY(e: BarEntry): void {
    if (e.getY() < this.yMin) {
      this.yMin = e.getY();
    }
    if (e.getY() > this.yMax) {
      this.yMax = e.getY();
    }
  }

  public getColors(): JArrayList<Number> {
    return this.colors;
  }

  public getColor(index?: number): number {
    if (index === undefined) {
      return this.colors.get(0)?.valueOf() ?? 0;
    }
    return this.colors.get(Math.floor(index) % this.colors.size())?.valueOf() ?? 0;
  }

  public setColorByColor(color: Number): void {
    this.resetColors();
    this.colors.add(color);
  }

  public resetColors(): void {
    if (this.colors == null) {
      this.colors = new JArrayList<Number>();
    }
    this.colors.clear();
  }

  public getLabel(): string {
    return this.label;
  }

  public setHighlightEnabled(enabled: boolean): void {
    this.highlightEnabled = enabled;
  }

  public isHighlightEnabled(): boolean {
    return this.highlightEnabled;
  }

  public setValueFormatter(f: IAxisValueFormatter): void {
    if (f == null) {
      return;
    } else {
      this.valueFormatter = f;
    }
  }

  public getValueFormatter(): IAxisValueFormatter | null {
    if (this.needsFormatter()) {
      return new DefaultValueFormatter(1);
    }
    return this.valueFormatter;
  }

  public setNewFormatter(valueFormatter: IAxisValueFormatter | null) {
    this.valueFormatter = valueFormatter;
  }

  public needsFormatter(): boolean {
    return this.valueFormatter == null;
  }

  public setValueTextSize(size: number): void {
    this.valueTextSize = size;
  }

  public getValueTextColor(index?: number): number {
    if (!index) {
      index = 0
    }
    if (this.valueColors) {
      return this.valueColors.get(index % this.valueColors.size())?.valueOf() ?? 0;
    }
    return 0;
  }

  public getValueTypeface(): FontFamily {
    return this.valueTypeface;
  }

  public setDrawValues(enabled: boolean): void {
    this.drawValues = enabled;
  }

  public isDrawValuesEnabled(): boolean {
    return this.drawValues;
  }

  public getIconsOffset(): MPPointF {
    return this.iconsOffset;
  }

  public getAxisDependency(): AxisDependency {
    return this.axisDependency;
  }

  public setAxisDependency(dependency: AxisDependency): void {
    this.axisDependency = dependency;
  }

  public getEntryCount(): number {
    if (this.entries == null) {
      return 0;
    }
    return this.entries.size();
  }

  public getYMin(): number {
    return this.yMin;
  }

  public getYMax(): number {
    return this.yMax;
  }

  public getXMin(): number {
    return this.xMin;
  }

  public getXMax(): number {
    return this.xMax;
  }

  public getEntryIndexByEntry(e: BarEntry): number {
    if (this.entries == null) {
      return -1;
    }
    return this.entries.indexOf(e);
  }

  public getEntryForXValue(xValue: number, closestToY: number, rounding?: Rounding): BarEntry | null {
    let myRounding: Rounding
    if (rounding == null) {
      myRounding = Rounding.CLOSEST;
    } else {
      myRounding = rounding;
    }
    let index: number = this.getEntryIndex(xValue, closestToY, myRounding);
    if (index > -1) {
      if (this.entries) {
        return this.entries.get(index);
      }
    }
    return null;
  }

  public getEntryForIndex(index: number): BarEntry {
    return this.entries!.get(index);
  }

  private getClosest(xValue: number): number {
    let low: number = 0;
    let high: number = this.entries?.size() as number - 1;
    let closest: number = high;
    while (low < high) {
      let m: number = Math.floor((low + high) / 2);
      let xVal1: number = this.entries?.get(m).getX() as number;
      let xVal2: number = this.entries?.get(m + 1).getX() as number;
      let d1: number = xVal1 - xValue;
      let d2: number = xVal2 - xValue;
      if (typeof d1 !== 'number' || typeof d2 !== 'number' || isNaN(d1) || isNaN(d2)) {
        LogUtil.error(`Invalid values detected: d1 = ${d1}, d2 = ${d2}, xVal1 = ${xVal1}, xVal2 = ${xVal2},` +
          `xValue = ${xValue}, Indices: m = ${m}, low = ${low}, high = ${high}`);
        break;
      }
      let ad1: number = Math.abs(d1);
      let ad2: number = Math.abs(d2);
      if (ad2 < ad1) {
        low = m + 1;
      } else if (ad1 < ad2) {
        high = m;
      } else {
        if (d1 >= 0.0) {
          high = m;
        } else if (d1 < 0.0) {
          low = m + 1;
        }
      }
      closest = high;
    }
    return closest;
  }

  public getEntryIndex(xValue: number, closestToY: number, rounding: Rounding): number {
    if (!this.entries || this.entries.isEmpty()) {
      return -1;
    }
    let closest: number = this.getClosest(xValue);
    if (closest != -1) {
      let closestXValue: number = this.entries.get(closest).getX();
      if (rounding == Rounding.UP) {
        if (closestXValue < xValue && closest < this.entries.size() - 1) {
          ++closest;
        }
      } else if (rounding == Rounding.DOWN) {
        if (closestXValue > xValue && closest > 0) {
          --closest;
        }
      }
      if (!Number.isNaN(closestToY)) {
        while (closest > 0 && this.entries.get(closest - 1).getX() == closestXValue) {
          closest -= 1;
        }
        let closestYValue: number = this.entries.get(closest).getY();
        let closestYIndex: number = closest;
        while (true) {
          closest += 1;
          if (closest >= this.entries.size()) {
            break;
          }
          let value: BarEntry = this.entries.get(closest);
          if (value.getX() != closestXValue) {
            break;
          }
          if (Math.abs(value.getY() - closestToY) <= Math.abs(closestYValue - closestToY)) {
            closestYValue = closestToY;
            closestYIndex = closest;
          }
        }
        closest = closestYIndex;
      }
    }
    return closest;
  }

  public getEntriesForXValue(xValue: number): JArrayList<BarEntry> {
    let entries: JArrayList<BarEntry> = new JArrayList<BarEntry>();
    if (this.entries == null) {
      return entries;
    }
    let low: number = 0;
    let high: number = this.entries.size() - 1;
    while (low <= high) {
      let m: number = (high + low) / 2;
      m = Utils.parseInt(m);
      let entry: BarEntry = this.entries.get(m);
      if (entry && xValue == entry.getX()) {
        while (m > 0 && this.entries.get(m - 1).getX() == xValue) {
          m--;
        }
        high = this.entries.size();
        for (; m < high; m++) {
          if (this.entries != null) {
            entry = this.entries.get(m);
            if (entry.getX() == xValue) {
              entries.add(entry);
            } else {
              break;
            }
          }
        }
        break;
      } else {
        if (entry && xValue > entry.getX()) {
          low = m + 1;
        } else {
          high = m - 1;
        }
      }
    }
    return entries;
  }
}

export enum Rounding {
  UP,
  DOWN,
  CLOSEST,
}
