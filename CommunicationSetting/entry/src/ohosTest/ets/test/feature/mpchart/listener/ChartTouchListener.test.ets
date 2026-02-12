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
  ChartGesture,
  ChartTouchListener,
  Matrix,
  OnChartGestureListener,
  ViewPortHandler
} from '../../../../../../main/ets/feature/mpchart';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';

export default function ChartTouchListenerTest() {
  describe('ChartTouchListenerTest', () => {
    let mocker: MockKit;
    let chartTouchListener = new ChartTouchListener(new BarChartModel(), new Matrix(), 0);
    let chart = chartTouchListener.chart;
    let finger: FingerInfo = {
      id: 0,
      globalX: 0,
      globalY: 0,
      localX: 0,
      localY: 0,
      displayX: 0,
      displayY: 0
    };
    let area: Area = {
      width: '',
      height: '',
      position: { x: 1, y: 1 },
      globalPosition: { x: 1, y: 1 }
    };
    let event: GestureEvent = {
      repeat: false,
      fingerList: [finger],
      offsetX: 0,
      offsetY: 0,
      angle: 0,
      speed: 0,
      scale: 0,
      pinchCenterX: 0,
      pinchCenterY: 0,
      velocityX: 0,
      velocityY: 0,
      velocity: 0,
      target: { area },
      timestamp: 0,
      source: SourceType.Unknown,
      pressure: 0,
      tiltX: 0,
      tiltY: 0,
      sourceTool: SourceTool.Unknown
    };
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
    let events: TouchEvent = {
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
    let l: OnChartGestureListener = {
      onChartGestureStart: (isTouchEvent: boolean, me: TouchEvent | GestureEvent,
        lastPerformedGesture: ChartGesture): void => {
        throw new Error('Function not implemented.');
      },
      onChartGestureEnd: (isTouchEvent: boolean, me: TouchEvent | GestureEvent,
        lastPerformedGesture: ChartGesture): void => {
        throw new Error('Function not implemented.');
      },
      onChartSingleTapped: (isTouchEvent: boolean, me: TouchEvent | GestureEvent): void => {
        throw new Error('Function not implemented.');
      },
      onChartTranslate: (isTouchEvent: boolean, me: TouchEvent | GestureEvent, dX: number, dY: number): void => {
        throw new Error('Function not implemented.');
      },
      onChartMove: (isTouchEvent: boolean, me: TouchEvent | GestureEvent): void => {
        throw new Error('Function not implemented.');
      },
      onChartOffsetChanged: (mViewPortHandler: ViewPortHandler): void => {
        throw new Error('Function not implemented.');
      }
    }
    beforeEach(() => {
      mocker = new MockKit();
    })

    it('performHighlight', 0, () => {
      let h: Highlight = new Highlight(1, 1, 1, 1, 1, 1, 1, 1);
      chartTouchListener.lastHighlighted = new Highlight(1, 1, 1, 1, 1, 1, 1, 1);
      chartTouchListener.performHighlight(h);
      expect(chartTouchListener.lastHighlighted).assertEqual(null);
      chartTouchListener.lastHighlighted = new Highlight(1, 2, 1, 1, 1, 1, 1, 2);
      chartTouchListener.performHighlight(h);
      expect(chartTouchListener.lastHighlighted).assertEqual(h);
    })

    it('performHighlightDrag', 0, () => {
      chartTouchListener.performHighlightDrag(true, event);
      expect(chartTouchListener.lastHighlighted?.mX).assertEqual(1);
      chartTouchListener.performHighlightDrag(false, events);
      expect(chartTouchListener.lastHighlighted?.mX).assertEqual(1);
    })

    it('onSingleTapUp', 0, () => {
      let h = new Highlight(1, 1, 1, 1, 1, 1, 1, 1);
      let getHighlightByTouchPoint: Function = mocker.mockFunc(chart, chart.getHighlightByTouchPoint);
      when(getHighlightByTouchPoint)(ArgumentMatchers.any).afterReturn(h);
      let getPerformHighlight = false;
      let performHighlight: Function = mocker.mockFunc(chartTouchListener, chartTouchListener.performHighlight);
      when(performHighlight)(ArgumentMatchers.any).afterAction(() => {
        getPerformHighlight = true
      });
      chartTouchListener.onSingleTapUp(true, events);
      expect(getPerformHighlight).assertTrue();
      when(getHighlightByTouchPoint)(ArgumentMatchers.any).afterReturn(null);
      when(performHighlight)(ArgumentMatchers.any).afterAction(() => {
        getPerformHighlight = false
      });
      chartTouchListener.onSingleTapUp(true, events);
      expect(getPerformHighlight).assertTrue();
      chartTouchListener.onSingleTapUp(false, event);
      expect(getPerformHighlight).assertTrue();
      mocker.clear(getHighlightByTouchPoint);
      mocker.clear(performHighlight);
    })

    it('actionDown', 0, () => {
      let isStartAction = false;
      let startAction: Function = mocker.mockFunc(chartTouchListener, chartTouchListener.startAction);
      when(startAction)(ArgumentMatchers.any).afterAction(() => isStartAction = true);
      chartTouchListener.actionDown(false, event);
      expect(isStartAction).assertTrue();

      let isStartActions = false;
      let startActions: Function = mocker.mockFunc(chartTouchListener, chartTouchListener.startAction);
      when(startActions)(ArgumentMatchers.any).afterAction(() => isStartActions = false);
      chartTouchListener.actionDown(true, events);
      expect(isStartActions).assertFalse();
      mocker.clear(startAction);
      mocker.clear(startActions);
    })

    it('actionMove', 0, () => {
      chartTouchListener.actionMove(false, event);
      chartTouchListener.touchMode = 1;
      let matrix = new Matrix();
      expect(chartTouchListener.matrix.data[4]).assertEqual(matrix.data[4]);
      chartTouchListener.actionMove(true, event);
      expect(chartTouchListener.matrix.data[4]).assertEqual(matrix.data[4]);
      chartTouchListener.touchMode = 0;
      chartTouchListener.dragTriggerDist = -1;
      let isFullyZoomedOut: Function = mocker.mockFunc(chart, chart.isFullyZoomedOut);
      when(isFullyZoomedOut)(ArgumentMatchers.any).afterReturn(true);
      chartTouchListener.actionMove(false, event);
      expect(chartTouchListener.lastGesture).assertEqual(1);
      chartTouchListener.touchStartPoint.x = 0;
      chartTouchListener.touchStartPoint.y = 0;
      let isFullyZoomedOuts: Function = mocker.mockFunc(chart, chart.isFullyZoomedOut);
      when(isFullyZoomedOuts)(ArgumentMatchers.any).afterReturn(false);
      chartTouchListener.actionMove(false, event);
      expect(chartTouchListener.lastGesture).assertEqual(1);
      chartTouchListener.touchStartPoint.y = -2;
      chartTouchListener.actionMove(false, event);
      expect(chartTouchListener.lastGesture).assertEqual(1);
      chartTouchListener.actionMove(false, events);
      expect(chartTouchListener.matrix.data[4]).assertEqual(matrix.data[4]);
      mocker.clear(isFullyZoomedOut);
      mocker.clear(isFullyZoomedOuts);
    })

    it('actionUp', 0, () => {
      chartTouchListener.actionUp(true, event);
      expect(chartTouchListener.touchMode).assertEqual(0);
    })

    it('performDrag', 0, () => {
      let onChartGestureListener: Function = mocker.mockFunc(chart, chart.getOnChartGestureListener);
      when(onChartGestureListener)(ArgumentMatchers.any).afterReturn(l);
      let onChartTranslate: Function = mocker.mockFunc(l, l.onChartTranslate);
      let chartTranslate = false;
      when(onChartTranslate)(ArgumentMatchers.any).afterAction(() => {
        chartTranslate = true
      });
      chartTouchListener.performDrag(true, event, 0, 0);
      expect(chartTranslate).assertTrue();
      mocker.clear(onChartGestureListener);
      mocker.clear(onChartTranslate);
    })

    it('getXyByEvent', 0, () => {
      let isTouchEventStr = JSON.stringify(chartTouchListener.getXyByEvent(true, events));
      expect(isTouchEventStr).assertEqual(JSON.stringify([0, 0]));
      let notTouchEventStr = JSON.stringify(chartTouchListener.getXyByEvent(false, event));
      expect(notTouchEventStr).assertEqual(JSON.stringify([0, 0]));
      let touchEvent: TouchEvent = JSON.parse(JSON.stringify(events));
      touchEvent.touches = [];
      expect(chartTouchListener.getXyByEvent(true, touchEvent)).assertEqual(undefined);
      let gestureEvent: GestureEvent = JSON.parse(JSON.stringify(event));
      gestureEvent.fingerList = [];
      expect(chartTouchListener.getXyByEvent(false, touchEvent)).assertEqual(undefined);
    })
  })
}