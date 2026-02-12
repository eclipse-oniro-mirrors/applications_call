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
import { describe, beforeAll, it, expect } from '@ohos/hypium'
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../../../testability/TestAbility';
import {
  AxisDependency,
  BarData,
  BarDataSet,
  BarEntry,
  IDataSet,
  JArrayList
} from '../../../../../../main/ets/feature/mpchart';
import ChartData from '../../../../../../main/ets/feature/mpchart/data/ChartData';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';

class BarDataTest extends ChartData<IDataSet> {
  constructor(dataSets?: JArrayList<IDataSet>) {
    super(dataSets as JArrayList<IDataSet>);
  }

  public setLeftAxisMin(leftAxisMin: number) {
    this.leftAxisMin = leftAxisMin;
  }

  public setRightAxisMin(rightAxisMin: number) {
    this.rightAxisMin = rightAxisMin;
  }

  public setLeftAxisMax(leftAxisMax: number) {
    this.leftAxisMax = leftAxisMax;
  }

  public setRightAxisMax(rightAxisMax: number) {
    this.rightAxisMax = rightAxisMax;
  }
}

export default function CharDataTest() {
  describe('CharDataTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('constructorTest01', 0, () => {
      let chartData: ChartData<IDataSet> = new ChartData();
      expect(chartData.getDataSetCount()).assertEqual(0);
    })
    it('constructorTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarData = new BarData(dataSetList);
      expect(chartData.getDataSetCount()).assertEqual(1);
    })
    it('constructorTest03', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: IDataSet[] = [];
      dataSetList.push(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      expect(chartData.getDataSetCount()).assertEqual(1);
    })
    it('calcMinMaxTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: IDataSet[] = [];
      dataSetList.push(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      chartData.calcMinMax();
      expect(chartData.getDataSetCount()).assertEqual(1);
      expect(chartData.getXMin()).assertEqual(0);
      expect(chartData.getYMin()).assertEqual(6);
      expect(chartData.getXMax()).assertEqual(0);
      expect(chartData.getYMax()).assertEqual(6);
    })
    it('calcMinMaxTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      barDataSet.setAxisDependency(AxisDependency.RIGHT);
      let dataSetList: IDataSet[] = [];
      dataSetList.push(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      chartData.calcMinMax();
      expect(chartData.getDataSetCount()).assertEqual(1);
      expect(chartData.getXMin()).assertEqual(1);
      expect(chartData.getYMin()).assertEqual(6);
      expect(chartData.getXMax()).assertEqual(1);
      expect(chartData.getYMax()).assertEqual(6);
    })
    it('calcMinMaxTest03', 0, () => {
      let values1: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values2: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values3: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let entry2: BarEntry = new BarEntry(2, [10]);
      values1.add(entry);
      values2.add(entry1);
      values3.add(entry2);
      let barDataSet1: BarDataSet = new BarDataSet(values1, 'DataSet');
      let barDataSet2: BarDataSet = new BarDataSet(values2, 'DataSet');
      let barDataSet3: BarDataSet = new BarDataSet(values3, 'DataSet');
      let dataSetList: IDataSet[] = [];
      dataSetList.push(barDataSet1);
      dataSetList.push(barDataSet2);
      dataSetList.push(barDataSet3);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      chartData.calcMinMax();
      expect(chartData.getDataSetCount()).assertEqual(3);
      expect(chartData.getXMin()).assertEqual(1);
      expect(chartData.getYMin()).assertEqual(1);
      expect(chartData.getXMax()).assertEqual(2);
      expect(chartData.getYMax()).assertEqual(10);
    })
    it('calcMinMaxTest04', 0, () => {
      let values1: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values2: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values3: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let entry2: BarEntry = new BarEntry(2, [10]);
      values1.add(entry);
      values2.add(entry1);
      values3.add(entry2);
      let barDataSet1: BarDataSet = new BarDataSet(values1, 'DataSet');
      let barDataSet2: BarDataSet = new BarDataSet(values2, 'DataSet');
      let barDataSet3: BarDataSet = new BarDataSet(values3, 'DataSet');
      barDataSet1.setAxisDependency(AxisDependency.RIGHT);
      barDataSet2.setAxisDependency(AxisDependency.RIGHT);
      barDataSet3.setAxisDependency(AxisDependency.RIGHT);
      let dataSetList: IDataSet[] = [];
      dataSetList.push(barDataSet1);
      dataSetList.push(barDataSet2);
      dataSetList.push(barDataSet3);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      chartData.calcMinMax();
      expect(chartData.getDataSetCount()).assertEqual(3);
      expect(chartData.getXMin()).assertEqual(1);
      expect(chartData.getYMin()).assertEqual(1);
      expect(chartData.getXMax()).assertEqual(2);
      expect(chartData.getYMax()).assertEqual(10);
    })
    it('getFirstRightTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      let result = chartData.getFirstRight(dataSetList);
      expect(result).assertNull();
    })
    it('getFirstRightTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      barDataSet.setAxisDependency(AxisDependency.RIGHT);
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      chartData.setValueTextSize(6);
      let result = chartData.getFirstRight(dataSetList);
      expect(result != null).assertEqual(true);
    })
    it('getYMinTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      chartData.setValueTextSize(6);
      let result = chartData.getYMin(AxisDependency.LEFT);
      expect(result).assertEqual(Number.MAX_VALUE);
    })
    it('getYMinTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      let result = chartData.getYMin(AxisDependency.RIGHT);
      expect(result).assertEqual(Number.MAX_VALUE);
    })
    it('getYMinTest03', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      chartData.setLeftAxisMin(1);
      let result = chartData.getYMin(AxisDependency.LEFT);
      expect(result).assertEqual(1);
    })
    it('getYMinTest04', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      chartData.setRightAxisMin(2);
      let result = chartData.getYMin(AxisDependency.RIGHT);
      expect(result).assertEqual(2);
    })
    it('getYMaxTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      let result = chartData.getYMax(AxisDependency.LEFT);
      expect(result).assertEqual(-Number.MAX_VALUE);
    })
    it('getYMaxTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      let result = chartData.getYMax(AxisDependency.RIGHT);
      expect(result).assertEqual(-Number.MAX_VALUE);
    })
    it('getYMaxTest03', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      chartData.setLeftAxisMax(3);
      let result = chartData.getYMax(AxisDependency.LEFT);
      expect(result).assertEqual(3);
    })
    it('getYMaxTest04', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      chartData.setLeftAxisMax(4);
      let result = chartData.getYMax(AxisDependency.RIGHT);
      expect(result).assertEqual(4);
    })
    it('getYMaxTest05', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      chartData.setRightAxisMax(4);
      let result = chartData.getYMax(AxisDependency.RIGHT);
      expect(result).assertEqual(4);
    })
    it('getEntryForHighlightTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      let stackedHigh: Highlight = new Highlight(
        entry.getX(), entry.getY(), 2, 0,
        0,
        0, 0,
        null
      );
      let result = chartData.getEntryForHighlight(stackedHigh);
      expect(result).assertNull();
    })
    it('getEntryForHighlightTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      let stackedHigh: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = chartData.getEntryForHighlight(stackedHigh);
      expect(result != null).assertTrue();
    })
    it('getDataSetByIndexTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      let result = chartData.getDataSetByIndex(-1);
      expect(result).assertNull();
    })
    it('getDataSetByIndexTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      let result = chartData.getDataSetByIndex(1);
      expect(result).assertNull();
    })
    it('getDataSetByIndexTest03', 0, () => {
      let values1: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values2: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values3: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let entry2: BarEntry = new BarEntry(2, [10]);
      values1.add(entry);
      values2.add(entry1);
      values3.add(entry2);
      let barDataSet1: BarDataSet = new BarDataSet(values1, 'DataSet');
      let barDataSet2: BarDataSet = new BarDataSet(values2, 'DataSet');
      let barDataSet3: BarDataSet = new BarDataSet(values3, 'DataSet');
      barDataSet1.setAxisDependency(AxisDependency.RIGHT);
      barDataSet2.setAxisDependency(AxisDependency.RIGHT);
      barDataSet3.setAxisDependency(AxisDependency.RIGHT);
      let dataSetList: IDataSet[] = [];
      dataSetList.push(barDataSet1);
      dataSetList.push(barDataSet2);
      dataSetList.push(barDataSet3);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      let result = chartData.getDataSetByIndex(1);
      expect(result != null).assertTrue();
      expect(result?.getEntryCount()).assertEqual(1);
    })
    it('setHighlightEnabledTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      let result = chartData.getDataSets().get(0).isHighlightEnabled();
      expect(result).assertTrue();
    })
    it('setHighlightEnabledTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      chartData.setHighlightEnabled(false);
      let result = chartData.getDataSets().get(0).isHighlightEnabled();
      expect(result).assertFalse();
    })
    it('getEntryCountTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let chartData: BarDataTest = new BarDataTest(dataSetList);
      let result = chartData.getEntryCount();
      expect(result).assertEqual(1);
    })
    it('getEntryCountTest02', 0, () => {
      let values1: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values2: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let values3: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let entry2: BarEntry = new BarEntry(2, [10]);
      values1.add(entry);
      values2.add(entry1);
      values3.add(entry2);
      let barDataSet1: BarDataSet = new BarDataSet(values1, 'DataSet');
      let barDataSet2: BarDataSet = new BarDataSet(values2, 'DataSet');
      let barDataSet3: BarDataSet = new BarDataSet(values3, 'DataSet');
      barDataSet1.setAxisDependency(AxisDependency.RIGHT);
      barDataSet2.setAxisDependency(AxisDependency.RIGHT);
      barDataSet3.setAxisDependency(AxisDependency.RIGHT);
      let dataSetList: IDataSet[] = [];
      dataSetList.push(barDataSet1);
      dataSetList.push(barDataSet2);
      dataSetList.push(barDataSet3);
      let chartData: ChartData<IDataSet> = new ChartData(dataSetList);
      let result = chartData.getEntryCount();
      expect(result).assertEqual(3);
    })
  })
}