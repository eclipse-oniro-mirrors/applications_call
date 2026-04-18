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

import { FontFamily } from '../../data/Paint';
import { AxisDependency } from '../../components/YAxis';
import { Rounding } from '../../data/BarDataSet';
import BarEntry from '../../data/BarEntry';
import IAxisValueFormatter from '../../formatter/IAxisValueFormatter';
import MPPointF from '../../utils/MPPointF';
import { JArrayList } from '../../utils/JArrayList';

export default interface IDataSet {
  getHighLightColor(): number;

  isStacked(): boolean;

  getYMin(): number;

  getYMax(): number;

  getXMin(): number;

  getXMax(): number;

  getEntryCount(): number;

  getEntryForXValue(xValue: number, closestToY: number, rounding?: Rounding): BarEntry | null;

  getEntriesForXValue(xValue: number): JArrayList<BarEntry>;

  getEntryForIndex(index: number): BarEntry;

  getEntryIndex(xValue: number, closestToY: number, rounding: Rounding): number;

  getEntryIndexByEntry(e: BarEntry): number;

  getLabel(): string;

  getAxisDependency(): AxisDependency;

  setAxisDependency(dependency: AxisDependency): void;

  getColors(): JArrayList<Number>;

  getColor(index ?: number): number;

  isHighlightEnabled(): boolean;

  setHighlightEnabled(enabled: boolean): void;

  setValueFormatter(f: IAxisValueFormatter): void;

  getValueFormatter(): IAxisValueFormatter | null;

  needsFormatter(): boolean;

  setValueTextSize(size: number): void;

  getValueTextColor(index ?: number): number;

  getValueTypeface(): FontFamily;

  setDrawValues(enabled: boolean): void;

  isDrawValuesEnabled(): boolean;

  getIconsOffset(): MPPointF;
}
