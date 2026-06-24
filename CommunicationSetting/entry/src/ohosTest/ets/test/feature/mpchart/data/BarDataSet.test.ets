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
import { BarDataSet, BarEntry, JArrayList } from '../../../../../../main/ets/feature/mpchart';
import DefaultValueFormatter from '../../../../../../main/ets/feature/mpchart/formatter/DefaultValueFormatter';
import { Rounding } from '../../../../../../main/ets/feature/mpchart/data/BarDataSet';

class DefaultValueFormatterTest extends DefaultValueFormatter {
  public decimalDigits: number = 0;

  constructor(digits: number) {
    super(digits);
  }
}

export default function BarDataSetTest() {
  describe('BarDataSetTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('calcStackSize01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry2: BarEntry = new BarEntry();
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      expect(barDataSet.isStacked()).assertTrue();
    })
    it('calcStackSize02', 0, () => {
      let entry: BarEntry = new BarEntry();
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      expect(barDataSet.isStacked()).assertFalse();
    })
    it('calcMinMaxTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.calcMinMax();
      expect(barDataSet.getXMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getYMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getXMax()).assertEqual(-Number.MAX_VALUE);
      expect(barDataSet.getYMax()).assertEqual(-Number.MAX_VALUE);
    })
    it('calcMinMaxTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.serEntries(null);
      barDataSet.calcMinMax();
      expect(barDataSet.getXMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getYMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getXMax()).assertEqual(-Number.MAX_VALUE);
      expect(barDataSet.getYMax()).assertEqual(-Number.MAX_VALUE);
    })
    it('myCalcMinMaxTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.myCalcMinMax();
      expect(barDataSet.getXMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getYMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getXMax()).assertEqual(-Number.MAX_VALUE);
      expect(barDataSet.getYMax()).assertEqual(-Number.MAX_VALUE);
    })
    it('myCalcMinMaxTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.myCalcMinMax(entry);
      expect(barDataSet.getXMin()).assertEqual(1);
      expect(barDataSet.getYMin()).assertEqual(6);
      expect(barDataSet.getXMax()).assertEqual(1);
      expect(barDataSet.getYMax()).assertEqual(6);
    })
    it('calcMinMaxYTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.serEntries(null);
      barDataSet.calcMinMaxY(1, 1);
      expect(barDataSet.getYMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getYMax()).assertEqual(-Number.MAX_VALUE);
    })
    it('calcMinMaxYTest03', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1, 1]);
      let entry2: BarEntry = new BarEntry();
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.calcMinMaxY(0, 1);
      expect(barDataSet.getYMin()).assertEqual(Number.MAX_VALUE);
      expect(barDataSet.getYMax()).assertEqual(-Number.MAX_VALUE);
    })
    it('calcMinMaxYTest04', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1, 1]);
      let entry2: BarEntry = new BarEntry();
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.calcMinMaxY(0, 2);
      expect(barDataSet.getYMin()).assertEqual(0);
      expect(barDataSet.getYMax()).assertEqual(0);
    })
    it('getColorTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getColor();
      expect(result).assertEqual(0x8ceaff);
    })
    it('getColorTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.setColorByColor(0x8ceafc)
      let result = barDataSet.getColor(0);
      expect(result).assertEqual(0x8ceafc);
    })
    it('setValueFormatterTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let defaultValueFormatter: DefaultValueFormatterTest = new DefaultValueFormatterTest(4);
      barDataSet.setValueFormatter(defaultValueFormatter);
      expect(barDataSet.getValueFormatter() != null).assertTrue();
    })
    it('setValueFormatterTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let defaultValueFormatter: DefaultValueFormatterTest = new DefaultValueFormatterTest(4);
      barDataSet.setValueFormatter(defaultValueFormatter);
      barDataSet.setNewFormatter(null);
      expect(barDataSet.getValueFormatter() != null).assertTrue();
    })
    it('getValueTextColorTest01', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getValueTextColor();
      expect(result).assertEqual(0x000000);
    })
    it('getValueTextColorTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getValueTextColor(0);
      expect(result).assertEqual(0x000000);
    })
    it('getEntryCountTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryCount();
      expect(result).assertEqual(2);
    })
    it('getEntryCountTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.serEntries(null);
      let result = barDataSet.getEntryCount();
      expect(result).assertEqual(0);
    })
    it('getEntryIndexByEntryTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryIndexByEntry(entry1);
      expect(result).assertEqual(1);
    })
    it('getEntryIndexByEntryTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.serEntries(null);
      let result = barDataSet.getEntryIndexByEntry(entry);
      expect(result).assertEqual(-1);
    })
    it('getEntryIndexTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.serEntries(null);
      let result = barDataSet.getEntryIndex(1, 1, Rounding.DOWN);
      expect(result).assertEqual(-1);
    })
    it('getEntryIndexTest02', 0, () => {
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryIndex(1, 1, Rounding.DOWN);
      expect(result).assertEqual(-1);
    })
    it('getEntryIndexTest03', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryIndex(1, 1, Rounding.DOWN);
      expect(result).assertEqual(1);
    })
    it('getEntryIndexTest04', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryIndex(1, 1, Rounding.UP);
      expect(result).assertEqual(1);
    })
    it('getEntryIndexTest05', 0, () => {
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryIndex(1, 1, Rounding.UP);
      expect(result).assertEqual(1);
    })
    it('getEntryIndexTest06', 0, () => {
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let entry2: BarEntry = new BarEntry(2, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryIndex(0, 1, Rounding.UP);
      expect(result).assertEqual(0);
    })
    it('getEntryIndexTest07', 0, () => {
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryForXValue(0, 1);
      expect(result?.getYVals()?.[0]).assertEqual(1);
      expect(result?.getYVals()?.[1]).assertEqual(2);
      expect(result?.getYVals()?.[2]).assertEqual(3);
    })
    it('getEntryIndexTest08', 0, () => {
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.serEntries(null);
      let result = barDataSet.getEntryForXValue(0, 1, Rounding.UP);
      expect(result).assertNull();
    })
    it('getEntryIndexTest09', 0, () => {
      let entry: BarEntry = new BarEntry(0, [5, 4, 3]);
      let entry1: BarEntry = new BarEntry(5, [1]);
      let entry2: BarEntry = new BarEntry(10, [1, 0]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry1);
      values.add(entry);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryForXValue(2, 0, Rounding.DOWN);
      expect(result?.getYVals()?.[0]).assertEqual(5);
      expect(result?.getYVals()?.[1]).assertEqual(4);
      expect(result?.getYVals()?.[2]).assertEqual(3);
    })
    it('getEntryIndexTest10', 0, () => {
      let entry: BarEntry = new BarEntry(1, [5, 4, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let entry2: BarEntry = new BarEntry(1, [1, 0]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry1);
      values.add(entry);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntryForXValue(1, 1, Rounding.DOWN);
      expect(result?.getYVals()?.[0]).assertEqual(1);
      expect(result?.getYVals()?.[1]).assertEqual(0);
    })
    it('getEntriesForXValueTest01', 0, () => {
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      barDataSet.serEntries(null);
      let result = barDataSet.getEntriesForXValue(0);
      expect(result.size()).assertEqual(0);
    })
    it('getEntriesForXValueTest02', 0, () => {
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(5, [1]);
      let entry2: BarEntry = new BarEntry(10, [1, 0]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      values.add(entry);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntriesForXValue(0);
      expect(result.size()).assertEqual(1);
    })
    it('getEntriesForXValueTest03', 0, () => {
      let entry: BarEntry = new BarEntry(0, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(5, [1]);
      let entry2: BarEntry = new BarEntry(10, [1, 0]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      values.add(entry);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntriesForXValue(1);
      expect(result.size()).assertEqual(0);
    })
    it('getEntriesForXValueTest04', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2, 3]);
      let entry1: BarEntry = new BarEntry(1, [1]);
      let entry2: BarEntry = new BarEntry(1, [1, 0]);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry1);
      values.add(entry);
      values.add(entry2);
      let barDataSet: BarDataSet = new BarDataSet(values, '');
      let result = barDataSet.getEntriesForXValue(1);
      expect(result.size()).assertEqual(4);
    })
  })
}
