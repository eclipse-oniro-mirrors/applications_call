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
  Transformer,
  ViewPortHandler,
  XAxis,
  XAxisPosition,
  XAxisRenderer
} from '../../../../../../main/ets/feature/mpchart';
import LimitLine from '../../../../../../main/ets/feature/mpchart/components/LimitLine';
import { Style } from '../../../../../../main/ets/feature/mpchart/data/Paint';
import { XAxisLabelPosition } from '../../../../../../main/ets/feature/mpchart/renderer/XAxisRenderer';
import MPPointF from '../../../../../../main/ets/feature/mpchart/utils/MPPointF';

export default function XAxisRendererTest() {
  describe('XAxisRendererTest', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('ComputeAxis', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);

      let xAxis: XAxis = new XAxis();
      let trans: Transformer = new Transformer(viewPortHandler);
      let xAxisRenderer: XAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);

      let result = xAxisRenderer.getAxis();
      expect(result.entries.length).assertEqual(0);

      xAxisRenderer.computeAxis(1, 2, false);
      xAxisRenderer.computeAxis(1, 2, true);
      result = xAxisRenderer.getAxis();
      expect(result.entries.length).assertLarger(0);
    });

    it('RenderAxisLabels', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);

      let xAxis: XAxis = new XAxis();
      xAxis.setTextSize(9);
      let trans: Transformer = new Transformer(viewPortHandler);
      let xAxisRenderer: XAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      let c = new CanvasRenderingContext2D()
      let pointF: MPPointF = MPPointF.getInstance(0, 0);
      xAxisRenderer.drawXAxisValue(c, '123', 1, 2, xAxisRenderer.getPaintAxisLabels(), pointF, XAxisLabelPosition.Left,
        false);
      xAxisRenderer.drawXAxisValue(c, '123', 1, 2, xAxisRenderer.getPaintAxisLabels(), pointF, XAxisLabelPosition.Right,
        false);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(10);

      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(9);

      xAxis.setPosition(XAxisPosition.BOTTOM);
      xAxis.setTextSize(10);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(10);

      xAxis.setPosition(XAxisPosition.BOTH_SIDED);
      xAxis.setTextSize(11);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(11);

      xAxis.setPosition(XAxisPosition.TOP_INSIDE);
      xAxis.setTextSize(12);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(12);

      xAxis.setPosition(XAxisPosition.BOTTOM_INSIDE);
      xAxis.setTextSize(13);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(13);

      xAxis.setPosition(XAxisPosition.BOTTOM_INSIDE);
      xAxis.setTextSize(14);
      xAxis.setDrawLabels(false);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(10);
    });

    it('RenderAxisLine', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);

      let xAxis: XAxis = new XAxis();
      xAxis.setAxisLineWidth(9);
      xAxis.setPosition(XAxisPosition.TOP);
      let trans: Transformer = new Transformer(viewPortHandler);
      let c = new CanvasRenderingContext2D()
      let xAxisRenderer: XAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.renderAxisLine(c);
      let axisLinePaint = xAxisRenderer.getPaintAxisLine();
      expect(axisLinePaint.lineWidth).assertEqual(9);

      xAxis.setPosition(XAxisPosition.BOTTOM);
      xAxis.setAxisLineWidth(10);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.renderAxisLine(c);
      axisLinePaint = xAxisRenderer.getPaintAxisLine();
      expect(axisLinePaint.lineWidth).assertEqual(10);
    });

    it('DrawLabels', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);

      let xAxis: XAxis = new XAxis();
      xAxis.setTextSize(9);
      xAxis.setLabelCount(10);
      xAxis.setCenterAxisLabels(true);

      let xAxisRenderer: XAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis);
      xAxisRenderer.computeAxis(1, 2, false);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(10);

      let c = new CanvasRenderingContext2D()
      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(9);

      let trans: Transformer = new Transformer(viewPortHandler);
      xAxis.setCenterAxisLabels(false);
      xAxis.setTextSize(12);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.computeAxis(1, 2, false);
      xAxisRenderer.renderAxisLabels(c, false);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(12);

      xAxis.setCenterAxisLabels(false);
      xAxis.setTextSize(13);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.getPaintAxisLabels().setStyle(Style.STROKE);
      xAxisRenderer.computeAxis(1, 2, false);
      xAxisRenderer.renderAxisLabels(c, false);
      xAxisRenderer.renderAxisLabels(c, true);
      expect(xAxisRenderer.getPaintAxisLabels().fontSize).assertEqual(13);
    });

    it('RenderGridLines', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);

      let xAxis: XAxis = new XAxis();
      xAxis.setAxisLineWidth(9);
      xAxis.setPosition(XAxisPosition.TOP);
      xAxis.setDrawGridLines(false)
      let trans: Transformer = new Transformer(viewPortHandler);
      let c = new CanvasRenderingContext2D()

      let xAxisRenderer: XAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      expect(xAxisRenderer.getGridPaint().lineWidth).assertEqual(1);
      xAxisRenderer.computeAxis(1, 2, false);
      xAxisRenderer.renderGridLines(c);
      expect(xAxisRenderer.getGridPaint().lineWidth).assertEqual(1);

      xAxis.setDrawGridLines(true)
      xAxis.setGridLineWidth(10);
      xAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      xAxisRenderer.computeAxis(1, 2, false);
      xAxisRenderer.renderGridLines(c);
      expect(xAxisRenderer.getGridPaint().lineWidth).assertEqual(10);
    });

    it('RenderCustomGridLines', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);

      let xAxis: XAxis = new XAxis();
      xAxis.setAxisLineWidth(9);
      xAxis.setPosition(XAxisPosition.TOP);
      xAxis.setDrawGridLines(false)
      let trans: Transformer = new Transformer(viewPortHandler);
      let c = new CanvasRenderingContext2D()

      let xAxisRenderer: XAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      expect(xAxisRenderer.limitLineSegmentsBuffer[0]).assertUndefined();

      xAxisRenderer.renderCustomGridLines(c);
      expect(xAxisRenderer.limitLineSegmentsBuffer[0]).assertUndefined();

      xAxis.getGridLines().add(new LimitLine);
      xAxisRenderer.renderCustomGridLines(c);
      expect(xAxisRenderer.limitLineSegmentsBuffer[0]).assertEqual(0);
    });

    it('RenderLimitLines', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);

      let xAxis: XAxis = new XAxis();
      xAxis.setAxisLineWidth(9);
      xAxis.setPosition(XAxisPosition.TOP);
      xAxis.setDrawGridLines(false)
      let trans: Transformer = new Transformer(viewPortHandler);
      let c = new CanvasRenderingContext2D()

      let xAxisRenderer: XAxisRenderer = new XAxisRenderer(viewPortHandler, xAxis, trans);
      expect(xAxisRenderer.limitLineSegmentsBuffer[0]).assertUndefined();

      xAxisRenderer.renderLimitLines(c);
      expect(xAxisRenderer.limitLineSegmentsBuffer[0]).assertUndefined();

      xAxis.getLimitLines().add(new LimitLine);
      xAxisRenderer.renderLimitLines(c);
      expect(xAxisRenderer.limitLineSegmentsBuffer[0]).assertEqual(0);
    });
  });
}