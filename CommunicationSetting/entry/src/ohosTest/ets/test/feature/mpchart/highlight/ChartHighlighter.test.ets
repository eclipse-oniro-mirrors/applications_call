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
  BarChartModel,
  BarData,
  BarDataSet,
  BarEntry,
  IDataSet,
  JArrayList,
} from '../../../../../../main/ets/feature/mpchart';
import ChartHighlighter from '../../../../../../main/ets/feature/mpchart/highlight/ChartHighlighter';
import BarDataProvider from '../../../../../../main/ets/feature/mpchart/interfaces/dataprovider/BarDataProvider';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';

class SubChartHighlighter extends ChartHighlighter<BarDataProvider> {
  constructor(chart: BarDataProvider) {
    super(chart);
  }

  public getHighlightForXTest(xVal: number, x: number, y: number): Highlight | null {
    return this.getHighlightForX(xVal, x, y)
  }
}

export default function ChartHighlighterTest() {
  describe('ChartHighlighterTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('getHighlightForXTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      entry.setRanges(null);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let subChartHighlighter = new SubChartHighlighter(barChartMode);
      let result = subChartHighlighter.getHighlightForXTest(1, 1, 1);
      expect(result != null).assertTrue();
    })
    it('getHighlightForXTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      entry.setRanges(null);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      barDataSet.setAxisDependency(AxisDependency.RIGHT);
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let subChartHighlighter = new SubChartHighlighter(barChartMode);
      let result = subChartHighlighter.getHighlightForXTest(1, 1, 1);
      expect(result != null).assertTrue();
    })
    it('getHighlightForXTest03', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      entry.setRanges(null);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      barDataSet.setHighlightEnabled(false)
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let subChartHighlighter = new SubChartHighlighter(barChartMode);
      let result = subChartHighlighter.getHighlightForXTest(1, 1, 1);
      expect(result == null).assertTrue();
    })
    it('getHighlightForXTest04', 0, () => {
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
      let barDataSet4: BarDataSet = new BarDataSet(values2, 'DataSet');
      barDataSet2.setAxisDependency(AxisDependency.RIGHT);
      barDataSet3.setAxisDependency(AxisDependency.RIGHT);
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet1);
      dataSetList.add(barDataSet2);
      dataSetList.add(barDataSet3);
      dataSetList.add(barDataSet4);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let subChartHighlighter = new SubChartHighlighter(barChartMode);
      let result = subChartHighlighter.getHighlightForXTest(1, 1, 1);
      expect(result != null).assertTrue();
    })
  })
}