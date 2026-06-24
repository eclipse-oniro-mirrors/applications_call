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
  BarChartModel,
  BarData,
  BarDataSet,
  BarEntry,
  IDataSet,
  JArrayList,
} from '../../../../../../main/ets/feature/mpchart';
import BarHighlighter from '../../../../../../main/ets/feature/mpchart/highlight/BarHighlighter';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';
import BarDataProvider from '../../../../../../main/ets/feature/mpchart/interfaces/dataprovider/BarDataProvider';
import Range from '../../../../../../main/ets/feature/mpchart/highlight/Range';

class SubBarHighlighter extends BarHighlighter {
  constructor(chart: BarDataProvider) {
    super(chart);
  }

  public getClosestStackTest(ranges: Range[], value: number): number {
    return this.getClosestStackIndex(ranges, value)
  }
}

export default function BarHighlighterTest() {
  describe('BarHighlighterTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('getHighlightTest01', 0, () => {
      let barChartMode = new BarChartModel();
      barChartMode.setData(null)
      let barHighlighter = new BarHighlighter(barChartMode)
      let result = barHighlighter.getHighlight(1, 1);
      expect(result).assertNull();
    })
    it('getHighlightTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let barHighlighter = new BarHighlighter(barChartMode)
      let result = barHighlighter.getHighlight(1, 1);
      expect(result != null).assertTrue();
    })
    it('getStackedHighlightTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let barHighlighter = new BarHighlighter(barChartMode);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = barHighlighter.getStackedHighlight(highLight, barDataSet, -1, -1);
      expect(result).assertNull();
    })
    it('getStackedHighlightTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, 1);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let barHighlighter = new BarHighlighter(barChartMode);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = barHighlighter.getStackedHighlight(highLight, barDataSet, -1, -1);
      expect(result == highLight).assertTrue();
    })
    it('getStackedHighlightTest03', 0, () => {
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
      let barHighlighter = new BarHighlighter(barChartMode);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = barHighlighter.getStackedHighlight(highLight, barDataSet, -1, -1);
      expect(result == null).assertTrue();
    })
    it('getStackedHighlightTest04', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let barHighlighter = new BarHighlighter(barChartMode);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = barHighlighter.getStackedHighlight(highLight, barDataSet, 3, 3);
      expect(result != null).assertTrue();
      expect(result != highLight).assertTrue();
    })
    it('getStackedHighlightTest05', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, 'DataSet');
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      dataSetList.add(barDataSet);
      let barData: BarData = new BarData(dataSetList)
      let barChartMode = new BarChartModel();
      barChartMode.setData(barData);
      let barHighlighter = new SubBarHighlighter(barChartMode);
      let result = barHighlighter.getClosestStackTest([], 0);
      expect(result).assertEqual(0);
    })
  })
}