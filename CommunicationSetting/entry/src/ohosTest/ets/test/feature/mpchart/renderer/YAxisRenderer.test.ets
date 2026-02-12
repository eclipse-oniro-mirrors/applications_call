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
  Transformer,
  ViewPortHandler,
  YAxis,
  YAxisLabelPosition
} from '../../../../../../main/ets/feature/mpchart';
import LimitLine from '../../../../../../main/ets/feature/mpchart/components/LimitLine';
import { Style } from '../../../../../../main/ets/feature/mpchart/data/Paint';
import YAxisRenderer from '../../../../../../main/ets/feature/mpchart/renderer/YAxisRenderer';

export default function YAxisRendererTest() {
  describe('renderAxisLine_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });


    it('RenderAxisLabels', 0, () => {
      let yAxis: YAxis = new YAxis();
      yAxis.setDrawLabels(false);
      yAxis.setTextColor(Color.Brown);
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxisRenderer.renderAxisLabels(c, true, true);
      expect(yAxisRenderer.getPaintAxisLabels().fillStyle).assertEqual(Color.Black);

      yAxis.setDrawLabels(true);
      yAxis.setTextColor(Color.Blue);
      yAxisRenderer.renderAxisLabels(c, true, true);
      yAxisRenderer.renderAxisLabels(c, true, false);
      yAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      yAxisRenderer.renderAxisLabels(c, false, false);
      yAxisRenderer.renderAxisLabels(c, false, true);
      expect(yAxisRenderer.getPaintAxisLabels().fillStyle).assertEqual(Color.Blue);

      yAxis = new YAxis(AxisDependency.RIGHT);
      yAxis.setTextColor(Color.Pink);
      yAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      yAxisRenderer.renderAxisLabels(c, true, true);
      yAxisRenderer.renderAxisLabels(c, true, false);
      yAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      yAxisRenderer.renderAxisLabels(c, false, false);
      yAxisRenderer.renderAxisLabels(c, false, true);
      expect(yAxisRenderer.getPaintAxisLabels().fillStyle).assertEqual(Color.Pink);
    });

    it('DrawYLabels', 0, () => {
      let yAxis: YAxis = new YAxis();
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxis.setDrawLabels(true);
      yAxis.setTextColor(Color.Red);
      yAxis.entryCount = 2;
      yAxisRenderer.renderAxisLabels(c, true, true);
      yAxisRenderer.renderAxisLabels(c, true, false);
      yAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      yAxisRenderer.renderAxisLabels(c, false, false);
      yAxisRenderer.renderAxisLabels(c, false, true);
      expect(yAxisRenderer.getPaintAxisLabels().fillStyle).assertEqual(Color.Red);

      yAxis = new YAxis(AxisDependency.RIGHT);
      yAxis.setDrawLabels(true);
      yAxis.setTextColor(Color.Green);
      yAxis.entryCount = 2;
      yAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      yAxisRenderer.getPaintAxisLabels().setStyle(Style.STROKE);
      yAxisRenderer.renderAxisLabels(c, true, true);
      yAxisRenderer.renderAxisLabels(c, true, false);
      yAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      yAxisRenderer.renderAxisLabels(c, false, false);
      yAxisRenderer.renderAxisLabels(c, false, true);
      expect(yAxisRenderer.getPaintAxisLabels().fillStyle).assertEqual(Color.Green);
    });

    it('RenderAxisLine', 0, () => {
      let yAxis: YAxis = new YAxis();
      yAxis.setAxisLineColor(Color.Yellow);
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      yAxisRenderer.renderAxisLine(c, 0);
      expect(yAxisRenderer.getPaintAxisLine().fillStyle).assertEqual(Color.Yellow);

      yAxis = new YAxis(AxisDependency.RIGHT);
      yAxis.setAxisLineColor(Color.Gray);
      yAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      yAxisRenderer.renderAxisLine(c, 0);
      expect(yAxisRenderer.getPaintAxisLine().fillStyle).assertEqual(Color.Gray);
    });

    it('RenderGridLines_trans_is_null', 0, () => {
      let yAxis: YAxis = new YAxis();
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxis.setGridColor(Color.White);
      yAxis.setDrawLabels(false);
      yAxisRenderer.renderGridLines(c);

      yAxis.setDrawLabels(true);
      yAxisRenderer.renderGridLines(c);

      yAxis.entryCount = 1;
      yAxisRenderer.renderGridLines(c);
      expect(yAxisRenderer.getGridPaint().fillStyle).assertEqual(Color.White);
    });
    it('RenderGridLines_trans_is_not_null', 0, () => {
      let yAxis: YAxis = new YAxis();
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let trans: Transformer = new Transformer(viewPortHandler);
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis, trans);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxis.setGridColor(Color.White);
      yAxis.setDrawLabels(false);
      yAxisRenderer.renderGridLines(c);

      yAxis.setDrawLabels(true);
      yAxisRenderer.renderGridLines(c);

      yAxis.entryCount = 1;
      yAxisRenderer.renderGridLines(c);
      expect(yAxisRenderer.getGridPaint().fillStyle).assertEqual(Color.White);
    });

    it('RenderLine_trans_is_null', 0, () => {
      let yAxis: YAxis = new YAxis();
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxisRenderer.renderLine(c, new LimitLine());
      expect(yAxisRenderer.getLimitLinePaint().styleType).assertEqual(Style.STROKE);
    });
    it('RenderLine_trans_is_not_null', 0, () => {
      let yAxis: YAxis = new YAxis();
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let trans: Transformer = new Transformer(viewPortHandler);
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis, trans);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxisRenderer.renderLine(c, new LimitLine());
      expect(yAxisRenderer.getLimitLinePaint().styleType).assertEqual(Style.STROKE);
    });

    it('RenderCustomGridLines', 0, () => {
      let yAxis: YAxis = new YAxis();
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let trans: Transformer = new Transformer(viewPortHandler);
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis, trans);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxisRenderer.renderCustomGridLines(c);

      yAxis.getGridLines().add(new LimitLine());

      yAxisRenderer.renderCustomGridLines(c);

      expect(yAxisRenderer.getLimitLinePaint().styleType).assertEqual(Style.STROKE);
    });

    it('RenderLimitLines', 0, () => {
      let yAxis: YAxis = new YAxis();
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let trans: Transformer = new Transformer(viewPortHandler);
      let yAxisRenderer: YAxisRenderer = new YAxisRenderer(viewPortHandler, yAxis, trans);
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();

      yAxisRenderer.renderLimitLines(c, false);

      yAxis.getLimitLines().add(new LimitLine());
      yAxisRenderer.renderLimitLines(c, false);
      yAxisRenderer.renderLimitLines(c, true);

      expect(yAxisRenderer.getLimitLinePaint().styleType).assertEqual(Style.STROKE);
    });
  });
}