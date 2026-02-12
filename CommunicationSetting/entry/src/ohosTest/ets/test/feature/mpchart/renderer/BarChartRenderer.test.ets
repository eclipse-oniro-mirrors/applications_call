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
  AxisDependency,
  BarData,
  BarDataSet,
  BarEntry,
  IDataSet,
  JArrayList,
  ViewPortHandler
} from '../../../../../../main/ets/feature/mpchart';
import BarLineChartBaseModel from '../../../../../../main/ets/feature/mpchart/charts/BarChartModel';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';
import BarChartRenderer from '../../../../../../main/ets/feature/mpchart/renderer/BarChartRenderer';

export default function BarChartRendererTest() {
  describe('BarChartRendererTest', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('InitBuffers_DrawData_barData_is_null', 0, () => {
      let model = new BarLineChartBaseModel();
      let barChartRenderer: BarChartRenderer = new BarChartRenderer(model, new ViewPortHandler());
      barChartRenderer.initBuffers();

      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      barChartRenderer.drawData(c);

      barChartRenderer.drawValues(c);

      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      barChartRenderer.drawHighlighted(context2D, []);

      const buffers = barChartRenderer.getBarBuffers();
      expect(buffers.length).assertEqual(0);
    });
    it('InitBuffers_barData_is_not_null_and_dataSets_is_null', 0, () => {
      let model = new BarLineChartBaseModel();
      model.setData(new BarData())
      let barChartRenderer: BarChartRenderer = new BarChartRenderer(model, new ViewPortHandler());
      barChartRenderer.initBuffers();

      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      barChartRenderer.drawData(c);

      barChartRenderer.drawValues(c);

      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      barChartRenderer.drawHighlighted(context2D, []);

      const buffers = barChartRenderer.getBarBuffers();
      expect(buffers.length).assertEqual(0);
    });

    it('InitBuffers_barData_is_not_null_and_dataSets_is_not_null', 0, () => {
      let barEntrys = new JArrayList<BarEntry>();
      let barDataSet = new BarDataSet(barEntrys, 'BarDataSet');
      let dataSets: JArrayList<IDataSet> = new JArrayList<BarDataSet>().add(barDataSet);
      let model = new BarLineChartBaseModel();
      model.setData(new BarData(dataSets));
      let barChartRenderer: BarChartRenderer = new BarChartRenderer(model, new ViewPortHandler());
      barChartRenderer.initBuffers();

      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      barChartRenderer.drawData(c);

      barChartRenderer.drawValues(c);

      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      barChartRenderer.drawHighlighted(context2D, []);

      const buffers = barChartRenderer.getBarBuffers();
      expect(buffers.length).assertLarger(0);
    });

    it('InitBuffers_barData_is_not_null_and_dataSets_is_not_null_barEntry_is_not_null', 0, () => {
      let barEntry = new BarEntry(12, 2);
      let barEntries = new JArrayList<BarEntry>().add(barEntry);
      let barDataSet = new BarDataSet(barEntries, 'BarDataSet');
      let dataSets: JArrayList<IDataSet> = new JArrayList<BarDataSet>().add(barDataSet);
      let barData: BarData = new BarData(dataSets);
      barData.setBarWidth(50);
      let model = new BarLineChartBaseModel();
      model.setData(barData);
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(40, 40);
      let barChartRenderer: BarChartRenderer = new BarChartRenderer(model, viewPortHandler);
      barChartRenderer.initBuffers();

      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      barChartRenderer.drawData(c);

      barChartRenderer.drawValues(c);

      barDataSet.getColors().add(Color.White);
      barChartRenderer.drawData(c);

      barChartRenderer.drawValues(c);

      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      barChartRenderer.drawHighlighted(context2D, []);

      let indices = [new Highlight(0, 0, 0, 0, 0, 0, 0, null)];
      barChartRenderer.drawHighlighted(context2D, indices);

      const buffers = barChartRenderer.getBarBuffers();
      expect(buffers.length).assertLarger(0);
    });
    it('InitBuffers_barData_is_not_null_and_dataSets_is_not_null_barEntry_is_not_null_y_is_array', 0, () => {
      let barEntry = new BarEntry(12, [23, 45]);
      let barEntries = new JArrayList<BarEntry>().add(barEntry);
      let barDataSet = new BarDataSet(barEntries, 'BarDataSet');
      let dataSets: JArrayList<IDataSet> = new JArrayList<BarDataSet>().add(barDataSet);
      let barData: BarData = new BarData(dataSets);
      barData.setBarWidth(50);
      let model = new BarLineChartBaseModel();
      model.setData(barData);
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(40, 40);
      let barChartRenderer: BarChartRenderer = new BarChartRenderer(model, viewPortHandler);
      barChartRenderer.initBuffers();

      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      barChartRenderer.drawData(c);

      barChartRenderer.drawValues(c);

      barDataSet.getColors().add(Color.White);
      barChartRenderer.drawData(c);

      barChartRenderer.drawValues(c);

      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      barChartRenderer.drawHighlighted(context2D, []);

      let indices = [new Highlight(0, 0, 0, 0, 0, 0, 0, null)];
      barChartRenderer.drawHighlighted(context2D, indices);

      indices = [new Highlight(0, 0, 0, 0, 0, 0, 0, AxisDependency.LEFT)];
      barChartRenderer.drawHighlighted(context2D, indices);

      const buffers = barChartRenderer.getBarBuffers();
      expect(buffers.length).assertLarger(0);
    });
  });
}