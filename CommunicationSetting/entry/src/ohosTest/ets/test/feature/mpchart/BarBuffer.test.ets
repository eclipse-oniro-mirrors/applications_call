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
import { DTGlobalContext } from '../../../testability/TestAbility';
import BarBuffer from '../../../../../main/ets/feature/mpchart/BarBuffer';
import { BarDataSet, BarEntry, JArrayList } from '../../../../../main/ets/feature/mpchart';

export default function BarBufferTest() {
  describe('BarBufferTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('setBarWidthTest01', 0, () => {
      let barBuffer: BarBuffer = new BarBuffer(true);
      expect(barBuffer.getBarWidth()).assertEqual(1);
    })
    it('setBarWidthTest02', 0, () => {
      let barBuffer: BarBuffer = new BarBuffer(true);
      barBuffer.setBarWidth(10);
      expect(barBuffer.getBarWidth()).assertEqual(10);
    })
    it('feedTest01', 0, () => {
      let barBuffer: BarBuffer = new BarBuffer(true);
      let entry: BarEntry = new BarEntry(1, 2);
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      let data: BarDataSet = new BarDataSet(values, bundleName);
      barBuffer.feed(data);
      expect(barBuffer.getIndex()).assertEqual(0);
    })
    it('feedTest02', 0, () => {
      let barBuffer: BarBuffer = new BarBuffer(true);
      let entry: BarEntry = new BarEntry(1, []);
      let entry2: BarEntry = new BarEntry();
      let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
      values.add(entry);
      values.add(entry2);
      let data: BarDataSet = new BarDataSet(values, bundleName);
      barBuffer.feed(data);
      expect(barBuffer.getIndex()).assertEqual(0);
    })
    it('feedBarTest01', 0, () => {
      let barEntry = new BarEntry(0, []);
      let barBuffer = new BarBuffer(true);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(0);
    })
    it('feedBarTest02', 0, () => {
      let barEntry = new BarEntry(1, []);
      let barBuffer = new BarBuffer(true);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(0);
    })
    it('feedBarTest03', 0, () => {
      let barEntry = new BarEntry(0, [0]);
      let barBuffer = new BarBuffer(true);
      barBuffer.setBarWidth(2);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(4);
      expect(barBuffer.buffer[0]).assertEqual(-1);
      expect(barBuffer.buffer[1]).assertEqual(0);
      expect(barBuffer.buffer[2]).assertEqual(1);
      expect(barBuffer.buffer[3]).assertEqual(0);
    })
    it('feedBarTest04', 0, () => {
      let barEntry = new BarEntry(0, [1]);
      let barBuffer = new BarBuffer(true);
      barBuffer.setBarWidth(2);
      barBuffer.setInverted(true);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(4);
      expect(barBuffer.buffer[0]).assertEqual(-1);
      expect(barBuffer.buffer[1]).assertEqual(0);
      expect(barBuffer.buffer[2]).assertEqual(1);
      expect(barBuffer.buffer[3]).assertEqual(0);
    });
    it('feedBarTest05', 0, () => {
      let barEntry = new BarEntry(0, [1, 1]);
      let barBuffer = new BarBuffer(true);
      barBuffer.setBarWidth(2);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(8);
      expect(barBuffer.buffer[0]).assertEqual(-1);
      expect(barBuffer.buffer[1]).assertEqual(0);
      expect(barBuffer.buffer[2]).assertEqual(1);
      expect(barBuffer.buffer[3]).assertEqual(0);
      expect(barBuffer.buffer[4]).assertEqual(-1);
      expect(barBuffer.buffer[5]).assertEqual(1);
      expect(barBuffer.buffer[6]).assertEqual(1);
      expect(barBuffer.buffer[7]).assertEqual(0);
    });
    it('feedBarTest06', 0, () => {
      let barEntry = new BarEntry(0, [2, 1]);
      let barBuffer = new BarBuffer(true);
      barBuffer.setBarWidth(2);
      barBuffer.setInverted(true);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(8);
      expect(barBuffer.buffer[0]).assertEqual(-1);
      expect(barBuffer.buffer[1]).assertEqual(0);
      expect(barBuffer.buffer[2]).assertEqual(1);
      expect(barBuffer.buffer[3]).assertEqual(0);
      expect(barBuffer.buffer[4]).assertEqual(-1);
      expect(barBuffer.buffer[5]).assertEqual(0);
      expect(barBuffer.buffer[6]).assertEqual(1);
      expect(barBuffer.buffer[7]).assertEqual(2);
    });
    it('feedBarTest07', 0, () => {
      let barEntry = new BarEntry(0, [-1, 1]);
      let barBuffer = new BarBuffer(true);
      barBuffer.setBarWidth(2);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(8);
      expect(barBuffer.buffer[0]).assertEqual(-1);
      expect(barBuffer.buffer[1]).assertEqual(0);
      expect(barBuffer.buffer[2]).assertEqual(1);
      expect(barBuffer.buffer[3]).assertEqual(-1);
      expect(barBuffer.buffer[4]).assertEqual(-1);
      expect(barBuffer.buffer[5]).assertEqual(0);
      expect(barBuffer.buffer[6]).assertEqual(1);
      expect(barBuffer.buffer[7]).assertEqual(0);
    });
    it('feedBarTest08', 0, () => {
      let barEntry = new BarEntry(0, [-1, 1]);
      let barBuffer = new BarBuffer(true);
      barBuffer.setBarWidth(2);
      barBuffer.setInverted(true);
      barBuffer.feedBar(barEntry);
      expect(barBuffer.buffer.length).assertEqual(8);
      expect(barBuffer.buffer[0]).assertEqual(-1);
      expect(barBuffer.buffer[1]).assertEqual(-1);
      expect(barBuffer.buffer[2]).assertEqual(1);
      expect(barBuffer.buffer[3]).assertEqual(0);
      expect(barBuffer.buffer[4]).assertEqual(-1);
      expect(barBuffer.buffer[5]).assertEqual(0);
      expect(barBuffer.buffer[6]).assertEqual(1);
      expect(barBuffer.buffer[7]).assertEqual(0);
    });
  })
}