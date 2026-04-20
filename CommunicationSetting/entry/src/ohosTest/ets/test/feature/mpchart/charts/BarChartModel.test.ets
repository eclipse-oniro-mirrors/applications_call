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
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium'
import {
  BarChartModel,
  BarData,
  Transformer,
  ViewPortHandler,
  XAxis,
  YAxis,
  ChartTouchListener,
  Matrix,
} from '../../../../../../main/ets/feature/mpchart';
import BarHighlighter from '../../../../../../main/ets/feature/mpchart/highlight/BarHighlighter';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';
import BarChartRenderer from '../../../../../../main/ets/feature/mpchart/renderer/BarChartRenderer';
import YAxisRenderer from '../../../../../../main/ets/feature/mpchart/renderer/YAxisRenderer';
import CanvasUtil from '../../../../../../main/ets/feature/mpchart/utils/CanvasUtil';

export default function BarChartModelTest() {
  describe('BarChartModelTest', () => {
    let barChartModel: BarChartModel = new BarChartModel();
    let mocker: MockKit;
    let touche: TouchObject = {
      type: TouchType.Down,
      id: 0,
      displayX: 0,
      displayY: 0,
      windowX: 0,
      windowY: 0,
      screenX: 0,
      screenY: 0,
      x: 0,
      y: 0
    }
    let area: Area = {
      width: '',
      height: '',
      position: { x: 1, y: 1 },
      globalPosition: { x: 1, y: 1 }
    };
    let event: TouchEvent = {
      type: TouchType.Down,
      touches: [touche],
      changedTouches: [],
      stopPropagation: (): void => {
        throw new Error('Function not implemented.');
      },
      getHistoricalPoints: (): HistoricalPoint[] => {
        throw new Error('Function not implemented.');
      },
      preventDefault: (): void => {
        throw new Error('Function not implemented.');
      },
      target: { area },
      timestamp: 0,
      source: SourceType.Unknown,
      pressure: 0,
      tiltX: 0,
      tiltY: 0,
      sourceTool: SourceTool.Unknown
    };

    beforeEach(() => {
      mocker = new MockKit();
    })

    it('getPixelForValues', 0, () => {
      let point = barChartModel.getPixelForValues(1, 1, 0);
      expect(point.x).assertEqual(1);
      barChartModel.leftAxisTransformer = null;
      let points = barChartModel.getPixelForValues(1, 1, 0)
      expect(points.x).assertEqual(1);
    })

    it('getHighlightByTouchPoint', 0, () => {
      barChartModel.chartData = null;
      expect(barChartModel.getHighlightByTouchPoint(1, 2)).assertEqual(null);
      barChartModel.chartData = new BarData();
      barChartModel.highlighter = null;
      expect(barChartModel.getHighlightByTouchPoint(1, 2)).assertEqual(null);
      barChartModel.highlighter = new BarHighlighter(barChartModel);
      barChartModel.getHighlightByTouchPoint(1, 2);
      expect(barChartModel.highlighter.getHighlight(1, 2)?.mX).assertEqual(undefined);
    })

    it('getLowestVisibleX', 0, () => {
      barChartModel.leftAxisTransformer = new Transformer(barChartModel.viewPortHandler);
      let valuesByTouchPoint = false;
      let leftAxisTransformer = barChartModel.leftAxisTransformer;
      let getValuesByTouchPoint: Function =
        mocker.mockFunc(leftAxisTransformer, leftAxisTransformer.getValuesByTouchPoint);
      when(getValuesByTouchPoint)(ArgumentMatchers.any).afterAction(() => valuesByTouchPoint = true);
      barChartModel.getLowestVisibleX();
      expect(valuesByTouchPoint).assertTrue();
      mocker.clear(getValuesByTouchPoint);
    })

    it('getHighestVisibleX', 0, () => {
      barChartModel.leftAxisTransformer = new Transformer(barChartModel.viewPortHandler);
      let valuesByTouchPoint = false;
      let leftAxisTransformer = barChartModel.leftAxisTransformer;
      let getValuesByTouchPoint: Function =
        mocker.mockFunc(leftAxisTransformer, leftAxisTransformer.getValuesByTouchPoint);
      when(getValuesByTouchPoint)(ArgumentMatchers.any).afterAction(() => valuesByTouchPoint = true);
      barChartModel.getHighestVisibleX();
      expect(valuesByTouchPoint).assertTrue();
      mocker.clear(getValuesByTouchPoint);
    })

    it('onDraw', 0, () => {
      barChartModel.chartData = new BarData();
      barChartModel.renderer = new BarChartRenderer(barChartModel, barChartModel.viewPortHandler);
      barChartModel.chartSizeCorrected = true;
      let clear = false;
      let clearCanvas: Function = mocker.mockFunc(CanvasUtil, CanvasUtil.clearCanvas);
      when(clearCanvas)(ArgumentMatchers.any).afterAction(() => clear = true);
      barChartModel.axisRendererLeft = null;
      barChartModel.axisRendererRight =
        new YAxisRenderer(new ViewPortHandler(), new YAxis(0), new Transformer(new ViewPortHandler()));
      barChartModel.axisLeft = new YAxis(0);
      barChartModel.indicesToHighlight = [new Highlight(1, 1, 2, 0, 0, 2, 2, null)];
      let valuesToHighlight: Function = mocker.mockFunc(barChartModel, barChartModel.valuesToHighlight);
      when(valuesToHighlight)(ArgumentMatchers.any).afterReturn(true);
      let renderer = barChartModel.renderer;
      let lighted = false;
      let drawHighlighted: Function = mocker.mockFunc(renderer, renderer.drawHighlighted);
      when(drawHighlighted)(ArgumentMatchers.any).afterAction(() => lighted = true);
      barChartModel.onDraw(new CanvasRenderingContext2D());
      expect(clear).assertTrue();
      expect(barChartModel.calcExtensionLine(barChartModel.axisRendererRight)).assertLarger(20);
      expect(lighted).assertTrue();
      mocker.clear(clearCanvas);
      mocker.clear(valuesToHighlight);
      mocker.clear(drawHighlighted);
    })

    it('calcExtensionLine', 0, () => {
      expect(barChartModel.calcExtensionLine(null)).assertEqual(0);
    })

    it('notifyDataSetChanged', 0, () => {
      barChartModel.renderer = new BarChartRenderer(barChartModel, barChartModel.viewPortHandler);
      let buffers = false;
      let renderer = barChartModel.renderer;
      let initBuffers: Function = mocker.mockFunc(renderer, renderer.initBuffers);
      when(initBuffers)(ArgumentMatchers.any).afterAction(() => buffers = true);
      barChartModel.notifyDataSetChanged();
      expect(buffers).assertTrue();
      barChartModel.chartData = null;
      barChartModel.notifyDataSetChanged();
      expect(buffers).assertTrue();
      mocker.clear(initBuffers);
    })

    it('calcMinMax', 0, () => {
      barChartModel.chartData = null;
      barChartModel.chartXAxis = new XAxis();
      let calculateXAxis = false;
      let chartXAxis = barChartModel.chartXAxis;
      let calculate: Function = mocker.mockFunc(chartXAxis, chartXAxis.calculate);
      when(calculate)(ArgumentMatchers.any).afterAction(() => calculateXAxis = true);
      barChartModel.calcMinMax();
      expect(calculateXAxis).assertFalse();
    })

    it('getTransformer', 0, () => {
      barChartModel.rightAxisTransformer = new Transformer(barChartModel.viewPortHandler);
      expect(barChartModel.getTransformer(1)).assertEqual(barChartModel.rightAxisTransformer);
    })

    it('onTouchEvent', 0, () => {
      barChartModel.chartTouchListener = new ChartTouchListener(barChartModel, new Matrix(), 0);
      barChartModel.chartData = new BarData();
      let events = JSON.parse(JSON.stringify(event)) as TouchEvent;
      let eventControl = barChartModel.eventControl;
      let eventIsDisable: Function = mocker.mockFunc(eventControl, eventControl.eventIsDisable);
      when(eventIsDisable)(ArgumentMatchers.any).afterReturn(false);
      let down = false;
      let chartTouchListener = barChartModel.chartTouchListener;
      let actionDown: Function = mocker.mockFunc(chartTouchListener, chartTouchListener.actionDown);
      when(actionDown)(ArgumentMatchers.any).afterAction(() => down = true);
      barChartModel.onTouchEvent(event);
      expect(down).assertTrue();
      events.type = TouchType.Move;
      let move = false;
      let actionMove: Function = mocker.mockFunc(chartTouchListener, chartTouchListener.actionMove);
      when(actionMove)(ArgumentMatchers.any).afterAction(() => move = true);
      barChartModel.onTouchEvent(events);
      expect(move).assertTrue();
      let up = false;
      events.type = TouchType.Up;
      let actionUp: Function = mocker.mockFunc(chartTouchListener, chartTouchListener.actionUp);
      when(actionUp)(ArgumentMatchers.any).afterAction(() => up = true);
      barChartModel.onTouchEvent(events);
      expect(up).assertTrue();
      events.touches = [touche, touche];
      barChartModel.onTouchEvent(events);
      expect(up).assertTrue();
      events.touches = [touche];
      barChartModel.chartTouchListener = null;
      barChartModel.onTouchEvent(events);
      expect(up).assertTrue();
      mocker.clear(eventIsDisable);
      mocker.clear(actionDown);
      mocker.clear(actionUp);
    })

    it('onSingleTapUp', 0, () => {
      let eventControl = barChartModel.eventControl;
      let eventIsDisable: Function = mocker.mockFunc(eventControl, eventControl.eventIsDisable);
      when(eventIsDisable)(ArgumentMatchers.any).afterReturn(false);
      barChartModel.chartTouchListener = new ChartTouchListener(barChartModel, new Matrix(), 0);
      let chartTouchListener = barChartModel.chartTouchListener;
      let singleTapUp = false;
      let onSingleTapUp: Function = mocker.mockFunc(chartTouchListener, chartTouchListener.onSingleTapUp);
      when(onSingleTapUp)(ArgumentMatchers.any).afterAction(() => singleTapUp = true);
      barChartModel.onSingleTapUp(true, event);
      expect(singleTapUp).assertTrue();
      mocker.clear(eventIsDisable);
      mocker.clear(onSingleTapUp);
    })

    it('setVisibleXRangeMaximum', 0, () => {
      barChartModel.chartXAxis = null;
      barChartModel.setVisibleXRangeMaximum(2);
      expect(barChartModel.viewPortHandler.minScaleX).assertEqual(1);
      barChartModel.chartXAxis = new XAxis();
      barChartModel.setVisibleXRangeMaximum(2);
      expect(barChartModel.viewPortHandler.minScaleX).assertEqual(1);
    })

    it('setVisibleXRangeMinimum', 0, () => {
      barChartModel.chartXAxis = null;
      barChartModel.setVisibleXRangeMinimum(2);
      expect(barChartModel.viewPortHandler.maxScaleX).assertEqual(1);
      barChartModel.chartXAxis = new XAxis();
      barChartModel.setVisibleXRangeMinimum(2);
      expect(Math.round(barChartModel.viewPortHandler.maxScaleX)).assertEqual(Number.MAX_VALUE);
    })

    it('moveViewToX', 0, () => {
      let transformer = false;
      let getTransformer: Function = mocker.mockFunc(barChartModel, barChartModel.getTransformer);
      when(getTransformer)(ArgumentMatchers.any).afterAction(() => transformer = true);
      barChartModel.moveViewToX(1);
      expect(transformer).assertTrue();
      mocker.clear(getTransformer);
    })

    it('getEntryByTouchPoint', 0, () => {
      barChartModel.chartData = null;
      expect(barChartModel.getEntryByTouchPoint(1, 1)).assertEqual(null);
      barChartModel.chartData = new BarData();
      let chartData = barChartModel.chartData;
      let getHighlightByTouchPoint: Function = mocker.mockFunc(barChartModel, barChartModel.getHighlightByTouchPoint);
      when(getHighlightByTouchPoint)(ArgumentMatchers.any).afterReturn(1);
      let getEntryForHighlight: Function = mocker.mockFunc(chartData, chartData.getEntryForHighlight);
      when(getEntryForHighlight)(ArgumentMatchers.any).afterReturn(1);
      expect(barChartModel.getEntryByTouchPoint(1, 1)).assertEqual(1);
      mocker.clear(getHighlightByTouchPoint);
      mocker.clear(getEntryForHighlight);
    })

    it('getDataSetByTouchPoint', 0, () => {
      barChartModel.chartData = new BarData();
      let chartData = barChartModel.chartData;
      let getHighlightByTouchPoint: Function = mocker.mockFunc(barChartModel, barChartModel.getHighlightByTouchPoint);
      when(getHighlightByTouchPoint)(ArgumentMatchers.any).afterReturn(new Highlight(1, 1, 2, 0, 0, 2, 2, null));
      let getDataSetByIndex: Function = mocker.mockFunc(chartData, chartData.getDataSetByIndex);
      when(getDataSetByIndex)(ArgumentMatchers.any).afterReturn(1);
      expect(barChartModel.getDataSetByTouchPoint(1, 1)).assertEqual(1);
      mocker.clear(getHighlightByTouchPoint);
      mocker.clear(getDataSetByIndex);
    })

    it('getAxis', 0, () => {
      barChartModel.axisLeft = new YAxis(0);
      barChartModel.axisRight = new YAxis(1);
      let leftResult = barChartModel.getAxis(0);
      let rightResult = barChartModel.getAxis(1);
      expect(JSON.stringify(leftResult)).assertEqual(JSON.stringify(new YAxis(0)));
      expect(JSON.stringify(rightResult)).assertEqual(JSON.stringify(new YAxis(1)));
    })

    it('isInverted', 0, () => {
      barChartModel.axisLeft = null;
      expect(barChartModel.isInverted(0)).assertFalse();
      barChartModel.axisLeft = new YAxis(0);
      expect(barChartModel.isInverted(0)).assertFalse();
    })

    it('isAnyAxisInverted', 0, () => {
      barChartModel.axisLeft = new YAxis(0);
      let axisLeft = barChartModel.axisLeft;
      let isInverted: Function = mocker.mockFunc(axisLeft, axisLeft.isInverted);
      when(isInverted)(ArgumentMatchers.any).afterReturn(true);
      expect(barChartModel.isAnyAxisInverted()).assertTrue();
      barChartModel.axisLeft = null;
      barChartModel.axisRight = new YAxis(0);
      let axisRight = barChartModel.axisRight;
      let inverted: Function = mocker.mockFunc(axisRight, axisRight.isInverted);
      when(inverted)(ArgumentMatchers.any).afterReturn(true);
      expect(barChartModel.isAnyAxisInverted()).assertTrue();
      mocker.clear(isInverted);
      mocker.clear(inverted);
    })

    it('invalidate', 0, () => {
      barChartModel.context2D = new CanvasRenderingContext2D();
      let draw = false;
      let onDraw: Function = mocker.mockFunc(barChartModel, barChartModel.onDraw);
      when(onDraw)(ArgumentMatchers.any).afterAction(() => draw = true);
      barChartModel.invalidate();
      expect(draw).assertTrue();
      mocker.clear(onDraw);
    })

    it('setViewPortOffsets', 0, () => {
      barChartModel.viewPortHandler = new ViewPortHandler();
      barChartModel.setViewPortOffsets(1, 1, 1, 1);
      expect(barChartModel.viewPortHandler.contentRect.left = 1).assertEqual(1);
    })

    it('calculateOffsets', 0, () => {
      barChartModel.viewPortHandler = new ViewPortHandler();
      let getOnChartGestureListener: Function = mocker.mockFunc(barChartModel, barChartModel.getOnChartGestureListener);
      when(getOnChartGestureListener)(ArgumentMatchers.any)
        .afterReturn({ onChartOffsetChanged: (mViewPortHandler: ViewPortHandler) => mViewPortHandler });
      expect(JSON.stringify(barChartModel.calculateOffsets())).assertEqual(undefined);
    })
  })
}