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
import { YAxis } from '../../../../../../main/ets/feature/mpchart';

export default function YAxisTest() {
  describe('YAxisTest', () => {
    it('constructor', 0, () => {
      let yAxis: YAxis = new YAxis();
      expect(yAxis.axisDependency).assertEqual(0);
      yAxis = new YAxis(1);
      expect(yAxis.axisDependency).assertEqual(1);
    })

    it('calculate', 0, () => {
      let yAxis: YAxis = new YAxis();
      yAxis.customAxisMin = true;
      yAxis.customAxisMax = true;
      yAxis.axisMinimum = 3;
      yAxis.axisMaximum = 23;
      yAxis.calculate(1, 2);
      expect(yAxis.axisRange).assertEqual(20);
      yAxis.calculate(1, 1);
      expect(yAxis.axisRange).assertEqual(20);
      yAxis.calculate(2, 1);
      expect(yAxis.axisRange).assertEqual(20);
      yAxis.calculate(2, -1);
      expect(yAxis.axisRange).assertEqual(20);
      yAxis.customAxisMin = false;
      yAxis.calculate(1, 2);
      expect(yAxis.axisRange).assertEqual(22.1);
      yAxis.calculate(1, 1);
      expect(yAxis.axisRange).assertEqual(23.2);
      yAxis.calculate(2, 1);
      expect(yAxis.axisRange).assertEqual(22.55);
      yAxis.calculate(2, -1);
      expect(yAxis.axisRange).assertEqual(24.55);
      yAxis.customAxisMax = false;
      yAxis.calculate(1, 11);
      expect(yAxis.axisRange).assertEqual(12);
      yAxis.calculate(0, 0);
      expect(yAxis.axisRange).assertEqual(2.4);
      yAxis.calculate(11, 1);
      expect(yAxis.axisRange).assertEqual(8);
      yAxis.customAxisMin = true;
      yAxis.calculate(1, 2);
      expect(yAxis.axisRange).assertEqual(7.9);
      yAxis.calculate(1, 1);
      expect(yAxis.axisRange).assertEqual(7.8);
      yAxis.calculate(2, 1);
      expect(yAxis.axisRange).assertEqual(6.9);
      yAxis.calculate(2, -1);
      expect(yAxis.axisRange).assertEqual(6.9);
    })
  })
}