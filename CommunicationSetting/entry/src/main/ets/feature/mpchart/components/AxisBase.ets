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

import { DashPathEffect } from '../data/Paint';
import Utils from '../utils/Utils';
import { JArrayList } from '../utils/JArrayList';
import DefaultAxisValueFormatter from '../formatter/DefaultAxisValueFormatter';
import IAxisValueFormatter from '../formatter/IAxisValueFormatter';
import ComponentBase from './ComponentBase';
import LimitLine from './LimitLine';

export default abstract class AxisBase extends ComponentBase {
  public axisValueFormatter: IAxisValueFormatter | null = null;
  private gridColor: number = Color.Gray;
  public gridAlpha: number = 90;
  private gridLineWidth: number = 1;
  private axisLineColor: number = Color.Gray;
  private axisLineWidth: number = 1;
  public entries: number[] = [];
  public centeredEntries: number[] = [];
  public entryCount: number = 0;
  public decimals: number = 0;
  public labelCount: number = 6;
  protected granularity: number = 1.0;
  protected granularityEnabled: boolean = false;
  public forceLabels: boolean = false;
  protected drawGridLines: boolean = true;
  protected drawLabels: boolean = true;
  protected centerAxisLabels: boolean = false;
  private gridDashPathEffect: DashPathEffect | null = null;
  protected limitLines: JArrayList<LimitLine>;
  protected gridLines: JArrayList<LimitLine>;
  public spaceMin: number = 0;
  protected spaceMax: number = 0;
  public customAxisMin: boolean = false;
  public customAxisMax: boolean = false;
  public axisMaximum: number = 0;
  public axisMinimum: number = 0;
  public axisRange: number = 0;
  public axisMinLabels: number = 2;
  public axisMaxLabels: number = 25;
  protected drawLimitLineBehindData: boolean = false;

  constructor() {
    super();
    this.textSize = Utils.handleDataValues(10);
    this.xOffset = Utils.handleDataValues(5);
    this.yOffset = Utils.handleDataValues(5);
    this.limitLines = new JArrayList<LimitLine>();
    this.gridLines = new JArrayList<LimitLine>();
  }

  public setDrawGridLines(enabled: boolean): void {
    this.drawGridLines = enabled;
  }

  public isDrawGridLinesEnabled(): boolean {
    return this.drawGridLines;
  }

  public setCenterAxisLabels(enabled: boolean): void {
    this.centerAxisLabels = enabled;
  }

  public isCenterAxisLabelsEnabled(): boolean {
    return this.centerAxisLabels && this.entryCount > 0;
  }

  public setGridColor(color: number): void {
    this.gridColor = color;
  }

  public setGridAlpha(alpha: number): void {
    if (alpha < 0) {
      alpha = 0;
    } else if (alpha > 255) {
      alpha = 255;
    }
    this.gridAlpha = alpha;
  }

  public getGridAlpha(): number {
    return this.gridAlpha;
  }

  public getGridColor(): number {
    return this.gridColor;
  }

  public setAxisLineWidth(width: number): void {
    this.axisLineWidth = Utils.handleDataValues(width);
  }

  public getAxisLineWidth(): number {
    return this.axisLineWidth;
  }

  public setGridLineWidth(width: number): void {
    this.gridLineWidth = Utils.handleDataValues(width);
  }

  public getGridLineWidth(): number {
    return this.gridLineWidth;
  }

  public setAxisLineColor(color: number): void {
    this.axisLineColor = color;
  }

  public getAxisLineColor(): number {
    return this.axisLineColor;
  }

  public setDrawLabels(enabled: boolean): void {
    this.drawLabels = enabled;
  }

  public isDrawLabelsEnabled(): boolean {
    return this.drawLabels;
  }

  public setLabelCount(count: number, force?: boolean): void {
    if (count > this.axisMaxLabels) {
      count = this.axisMaxLabels;
    }
    if (count < this.axisMinLabels) {
      count = this.axisMinLabels;
    }
    this.labelCount = count;
    this.forceLabels = false;
    if (force != null || force != undefined) {
      this.forceLabels = force;
    }
  }

  public isForceLabelsEnabled(): boolean {
    return this.forceLabels;
  }

  public getLabelCount(): number {
    return this.labelCount;
  }

  public isGranularityEnabled(): boolean {
    return this.granularityEnabled;
  }

  public getGranularity(): number {
    return this.granularity;
  }

  public setGranularity(granularity: number): void {
    this.granularity = granularity;
    this.granularityEnabled = true;
  }

  public getGridLines(): JArrayList<LimitLine> {
    return this.gridLines;
  }

  public getLimitLines(): JArrayList<LimitLine> {
    return this.limitLines;
  }

  public getFormattedLabel(index: number): string {
    if (index < 0 || index >= this.entries.length) {
      return '';
    } else {
      return this.getValueFormatter().getFormattedValue(this.entries[index]);
    }
  }

  public setValueFormatter(f: IAxisValueFormatter): void {
    if (!f || f == null) {
      this.axisValueFormatter = new DefaultAxisValueFormatter(this.decimals);
    } else {
      this.axisValueFormatter = f;
    }
  }

  public getValueFormatter(): IAxisValueFormatter {
    if (!this.axisValueFormatter ||
    (this.axisValueFormatter instanceof DefaultAxisValueFormatter &&
    (this.axisValueFormatter as DefaultAxisValueFormatter).getDecimalDigits() != this.decimals)) {
      this.axisValueFormatter = new DefaultAxisValueFormatter(this.decimals);
    }
    return this.axisValueFormatter;
  }

  public enableGridDashedLine(lineLength: number, spaceLength: number, phase: number): void {
    this.gridDashPathEffect = new DashPathEffect([lineLength, spaceLength], phase);
  }

  public getGridDashPathEffect(): DashPathEffect | null {
    return this.gridDashPathEffect;
  }

  public setAxisMinimum(min: number): void {
    this.customAxisMin = true;
    this.axisMinimum = min;
    this.axisRange = Math.abs(this.axisMaximum - min);
  }

  public setAxisMaximum(max: number): void {
    this.customAxisMax = true;
    this.axisMaximum = max;
    this.axisRange = Math.abs(max - this.axisMinimum);
  }

  public calculate(dataMin: number, dataMax: number): void {
    let min: number = this.customAxisMin ? this.axisMinimum : (dataMin - this.spaceMin);
    let max: number = this.customAxisMax ? this.axisMaximum : (dataMax + this.spaceMax);
    let range: number = Math.abs(max - min);
    if (range == 0) {
      max = max + 1;
      min = min - 1;
    }
    this.axisMinimum = min;
    this.axisMaximum = max;
    this.axisRange = Math.abs(max - min);
  }

  public setSpaceMin(mSpaceMin: number): void {
    this.spaceMin = mSpaceMin;
  }

  public setSpaceMax(mSpaceMax: number): void {
    this.spaceMax = mSpaceMax;
  }

  public isDrawLimitLinesBehindDataEnabled(): boolean {
    return this.drawLimitLineBehindData;
  }

  public setDrawLimitLinesBehindData(enabled: boolean): void {
    this.drawLimitLineBehindData = enabled;
  }
}