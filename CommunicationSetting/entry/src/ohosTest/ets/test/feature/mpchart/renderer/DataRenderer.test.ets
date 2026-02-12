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
import { afterEach, beforeEach, describe, expect, it } from '@ohos/hypium';
import {
  BarData,
  BarDataSet,
  BarEntry,
  IDataSet,
  JArrayList,
  ViewPortHandler
} from '../../../../../../main/ets/feature/mpchart';
import BarLineChartBaseModel from '../../../../../../main/ets/feature/mpchart/charts/BarChartModel';
import { Style } from '../../../../../../main/ets/feature/mpchart/data/Paint';
import DefaultValueFormatter from '../../../../../../main/ets/feature/mpchart/formatter/DefaultValueFormatter';
import BarChartRenderer from '../../../../../../main/ets/feature/mpchart/renderer/BarChartRenderer';

export default function DataRendererTest() {
  describe('DataRendererTest', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });


    it('DrawValue', 0, () => {
      let barEntry = new BarEntry(12, [23, 45]);
      let barEntrys = new JArrayList<BarEntry>().add(barEntry);
      let barDataSet = new BarDataSet(barEntrys, 'BarDataSet');
      let dataSets: JArrayList<IDataSet> = new JArrayList<BarDataSet>().add(barDataSet);
      let barData: BarData = new BarData(dataSets);
      barData.setBarWidth(50);
      let model = new BarLineChartBaseModel();
      model.setData(barData);
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(40, 40);
      let barChartRenderer: BarChartRenderer = new BarChartRenderer(model, viewPortHandler);
      barChartRenderer.initBuffers();

      barChartRenderer.valuePaint.setStyle(Style.STROKE);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      let defaultValueFormatter = new DefaultValueFormatter(12);
      barChartRenderer.drawValue(c, defaultValueFormatter, 10, 20, 30, Color.Blue, true);

      barChartRenderer.drawValue(c, defaultValueFormatter, 10, 20, 30, Color.Blue, false);

      barChartRenderer.valuePaint.setStyle(Style.FILL);
      barChartRenderer.drawValue(c, defaultValueFormatter, 10, 20, 30, Color.Blue, true);

      barChartRenderer.drawValue(c, defaultValueFormatter, 10, 20, 30, Color.Blue, false);

      const color = barChartRenderer.valuePaint.fillStyle;
      expect(color).assertEqual(Color.Blue);
    });

  });
}