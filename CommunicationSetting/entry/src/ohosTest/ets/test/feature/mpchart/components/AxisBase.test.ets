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
import { describe, expect, it } from '@ohos/hypium'
import { IAxisValueFormatter, XAxis } from '../../../../../../main/ets/feature/mpchart';
import DefaultAxisValueFormatter from '../../../../../../main/ets/feature/mpchart/formatter/DefaultAxisValueFormatter';

export default function AxisBaseTest() {
  describe('AxisBaseTest', () => {
    let xAxis: XAxis = new XAxis();

    it('setGridAlpha', 0, () => {
      xAxis.setGridAlpha(-1);
      expect(xAxis.gridAlpha).assertEqual(0);
      xAxis.setGridAlpha(256);
      expect(xAxis.gridAlpha).assertEqual(255);
      xAxis.setGridAlpha(100);
      expect(xAxis.gridAlpha).assertEqual(100);
    })

    it('setLabelCount', 0, () => {
      xAxis.axisMaxLabels = 10;
      xAxis.axisMinLabels = 2;
      xAxis.setLabelCount(1, false);
      expect(xAxis.labelCount).assertEqual(2);
      xAxis.setLabelCount(11, false);
      expect(xAxis.labelCount).assertEqual(10);
      expect(xAxis.forceLabels).assertFalse();
      xAxis.setLabelCount(1);
      expect(xAxis.forceLabels).assertFalse();
    })

    it('getFormattedLabel', 0, () => {
      expect(xAxis.getFormattedLabel(-1)).assertEqual('');
      xAxis.entries = [1];
      expect(xAxis.getFormattedLabel(0)).assertEqual('1');
    })

    it('setValueFormatter', 0, () => {
      let f: IAxisValueFormatter = new DefaultAxisValueFormatter(1);
      xAxis.setValueFormatter(f);
      expect(xAxis.axisValueFormatter).assertEqual(f);
    })

    it('calculate', 0, () => {
      xAxis.customAxisMin = true;
      xAxis.customAxisMax = true;
      xAxis.axisMinimum = 1;
      xAxis.axisMaximum = 2;
      xAxis.spaceMin = 1;
      xAxis.calculate(1, 2);
      expect(xAxis.axisRange).assertEqual(1);
      xAxis.customAxisMax = false;
      xAxis.calculate(1, 10);
      expect(xAxis.axisRange).assertEqual(9);
      xAxis.customAxisMin = false;
      xAxis.calculate(1, 10);
      expect(xAxis.axisRange).assertEqual(10);
      xAxis.customAxisMax = true;
      xAxis.calculate(1, 10);
      expect(xAxis.axisRange).assertEqual(10);
    })
  })
}