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

import Highlight from '../highlight/Highlight';
import MPPointF from '../utils/MPPointF';
import Matrix from '../utils/Matrix';
import BarChartModel from '../charts/BarChartModel';
import Utils from '../utils/Utils';
import OnChartGestureListener from './OnChartGestureListener';
import IDataSet from '../interfaces/datasets/IDataSet';
import { AnimatorResult } from '@ohos.animator';

export enum ChartGesture {
  NONE, DRAG, SINGLE_TAP
}

export default class ChartTouchListener {
  public matrix: Matrix = new Matrix();
  private savedMatrix: Matrix = new Matrix();
  public touchStartPoint: MPPointF = MPPointF.getInstance(0, 0);
  private closestDataSetToTouch: IDataSet | null = null;
  private decelerationVelocity: MPPointF = MPPointF.getInstance(0, 0);
  public dragTriggerDist: number = 0.0;
  private animatorIsPlaying: boolean = false;
  private animatorResult: AnimatorResult | null = null;
  public lastGesture: ChartGesture = ChartGesture.NONE;
  protected static NONE: number = 0;
  protected static DRAG: number = 1;
  public touchMode: number = ChartTouchListener.NONE;
  public lastHighlighted: Highlight | null = null;
  public chart: BarChartModel;

  constructor(chart: BarChartModel, touchMatrix: Matrix, dragTriggerDistance: number) {
    this.chart = chart;
    this.matrix = touchMatrix;
    this.dragTriggerDist = Utils.handleDataValues(dragTriggerDistance);
  }

  public startAction(isTouchEvent: boolean, me: TouchEvent | GestureEvent) {
    let l: OnChartGestureListener | null = this.chart.getOnChartGestureListener();
    if (l != null) {
      l.onChartGestureStart(isTouchEvent, me, this.lastGesture);
    }
  }

  public endAction(isTouchEvent: boolean, me: TouchEvent | GestureEvent) {
    let l: OnChartGestureListener | null = this.chart.getOnChartGestureListener();
    if (l != null) {
      l.onChartGestureEnd(isTouchEvent, me, this.lastGesture);
    }
  }

  public setLastHighlighted(high?: Highlight) {
    this.lastHighlighted = high ? high : null;
  }

  public performHighlight(h: Highlight) {
    if (h == null || Utils.isHighLightEquals(h, this.lastHighlighted)) {
      this.chart.highlightValueForObject(null, true);
      this.lastHighlighted = null;
    } else {
      this.chart.highlightValueForObject(h, true);
      this.lastHighlighted = h;
    }
  }

  protected static distance(eventX: number, startX: number, eventY: number, startY: number): number {
    let dx: number = eventX - startX;
    let dy: number = eventY - startY;
    return Math.sqrt(dx * dx + dy * dy);
  }

  actionDown(isTouchEvent: boolean, event: TouchEvent | GestureEvent) {
    if (isTouchEvent) {
      if (!!this.animatorResult && this.animatorIsPlaying) {
        this.animatorResult.pause();
        this.animatorIsPlaying = false;
      }
      event = event as TouchEvent;
      if (!event.touches || event.touches.length == 0 || !event.touches[0]) {
        return;
      }
    } else {
      event = event as GestureEvent;
      if (!event.fingerList || event.fingerList.length == 0 || !event.fingerList[0]) {
        return;
      }
    }
    this.startAction(isTouchEvent, event);
    this.stopDeceleration();
    this.saveTouchStart(isTouchEvent, event);
  }

  actionMove(isTouchEvent: boolean, event: TouchEvent | GestureEvent) {
    if (!event) {
      return;
    }
    let l: OnChartGestureListener | null = this.chart.getOnChartGestureListener();
    l?.onChartMove(isTouchEvent, event);
    let xCoordinate: number = 0;
    let yCoordinate: number = 0;
    if (isTouchEvent) {
      event = event as TouchEvent;
      if (!event.touches || event.touches.length == 0 || !event.touches[0]) {
        return;
      }
      xCoordinate = event.touches[0].x;
      yCoordinate = event.touches[0].y;
    } else {
      event = event as GestureEvent;
      if (!event.fingerList || event.fingerList.length == 0 || !event.fingerList[0]) {
        return;
      }
      xCoordinate = event.fingerList[0].localX;
      yCoordinate = event.fingerList[0].localY;
    }
    if (!this.chart?.getViewPortHandler().isInBounds(xCoordinate, yCoordinate)) {
      this.chart.highlightValueForObject(null, true);
    }
    if (this.touchMode == ChartTouchListener.DRAG) {
      let x: number = xCoordinate - this.touchStartPoint.x;
      let y: number = 0;
      this.performDrag(isTouchEvent, event, x, y);
      this.matrix = this.chart.getViewPortHandler().refresh(this.matrix, this.chart);
    } else if (this.touchMode == 0 &&
      Math.abs(ChartTouchListener.distance(xCoordinate, this.touchStartPoint.x, yCoordinate, this.touchStartPoint.y)) >
      this.dragTriggerDist && this.chart?.getViewPortHandler().isInBounds(xCoordinate, yCoordinate)) {
      let shouldPan: boolean = !this.chart.isFullyZoomedOut();
      if (shouldPan) {
        let distanceX: number = Math.abs(xCoordinate - this.touchStartPoint.x);
        let distanceY: number = Math.abs(yCoordinate - this.touchStartPoint.y);
        if (distanceY <= distanceX) {
          this.lastGesture = ChartGesture.DRAG;
          this.touchMode = ChartTouchListener.DRAG;
        }
      } else {
        this.lastGesture = ChartGesture.DRAG;
        this.performHighlightDrag(isTouchEvent, event);
        return;
      }
      this.matrix = this.chart.getViewPortHandler().refresh(this.matrix, this.chart);
    }
  }

  actionUp(isTouchEvent: boolean, event: TouchEvent | GestureEvent) {
    if (!event) {
      return;
    }
    this.touchMode = ChartTouchListener.NONE;
    this.endAction(isTouchEvent, event);
    this.saveTouchStart(isTouchEvent, event);
  }

  private saveTouchStart(isTouchEvent: boolean, event: TouchEvent | GestureEvent) {
    this.savedMatrix.set(this.matrix);
    if (isTouchEvent) {
      let touch = event as TouchEvent;
      if (!touch.touches || touch.touches.length == 0 || !touch.touches[0]) {
        return;
      }
      this.touchStartPoint.x = touch.touches[0].x;
      this.touchStartPoint.y = touch.touches[0].y;
    } else {
      let gesture = event as GestureEvent;
      if (!gesture.fingerList || gesture.fingerList.length == 0 || !gesture.fingerList[0]) {
        return;
      }
      this.touchStartPoint.x = gesture.fingerList[0].globalX;
      this.touchStartPoint.y = gesture.fingerList[0].globalY;
    }
    this.closestDataSetToTouch = this.chart.getDataSetByTouchPoint(this.touchStartPoint.x, this.touchStartPoint.y);
  }

  performDrag(isTouchEvent: boolean, event: TouchEvent | GestureEvent, distanceX: number, distanceY: number) {
    this.lastGesture = ChartGesture.DRAG;
    this.matrix.set(this.savedMatrix);
    let l: OnChartGestureListener | null = this.chart.getOnChartGestureListener();
    if ((this.closestDataSetToTouch == null && this.chart.isAnyAxisInverted()) ||
      (this.closestDataSetToTouch != null &&
      this.chart.isInverted(this.closestDataSetToTouch.getAxisDependency()))) {
      distanceY = -distanceY;
    }
    if (l != null) {
      l.onChartTranslate(isTouchEvent, event, distanceX, distanceY);
    }
    this.matrix.postTranslate(distanceX, distanceY);
  }

  performHighlightDrag(isTouchEvent: boolean, event: TouchEvent | GestureEvent) {
    let xCoordinate: number = 0;
    let yCoordinate: number = 0;
    if (isTouchEvent) {
      event = event as TouchEvent;
      if (!event.touches || event.touches.length == 0 || !event.touches[0]) {
        return;
      }
      xCoordinate = event.touches[0].x;
      yCoordinate = event.touches[0].y;
    } else {
      event = event as GestureEvent;
      if (!event.fingerList || event.fingerList.length == 0 || !event.fingerList[0]) {
        return;
      }
      xCoordinate = event.fingerList[0].localX;
      yCoordinate = event.fingerList[0].localY;
    }
    let h: Highlight | null = this.chart.getHighlightByTouchPoint(xCoordinate, yCoordinate);
    if (h != null && !h.equalTo(this.lastHighlighted)) {
      this.lastHighlighted = h;
      this.chart.highlightValueForObject(h, true);
    }
  }

  public getXyByEvent(isTouchEvent: boolean, e: TouchEvent | GestureEvent): [number, number] | undefined {
    let x: number = 0;
    let y: number = 0;
    if (isTouchEvent) {
      let touch = e as TouchEvent;
      if (!touch.touches || touch.touches.length == 0 || !touch.touches[0]) {
        return;
      }
      x = touch.touches[0].x;
      y = touch.touches[0].y;
    } else {
      let gesture = e as GestureEvent;
      if (!gesture.fingerList || gesture.fingerList.length == 0 || !gesture.fingerList[0]) {
        return;
      }
      x = gesture.fingerList[0].localX;
      y = gesture.fingerList[0].localY;
    }
    return [x, y]
  }

  public onSingleTapUp(isTouchEvent: boolean, e: TouchEvent | GestureEvent): void {
    if (!e) {
      return;
    }
    this.actionDown(isTouchEvent, e);
    this.lastGesture = ChartGesture.SINGLE_TAP;
    let l: OnChartGestureListener | null = this.chart.getOnChartGestureListener();
    if (l != null) {
      l.onChartSingleTapped(isTouchEvent, e);
    }
    this.chart.setLastGestureSingleTap();
    let x: number = 0;
    let y: number = 0;
    if (isTouchEvent) {
      let touch = e as TouchEvent;
      if (!touch.touches || touch.touches.length == 0 || !touch.touches[0]) {
        return;
      }
      x = touch.touches[0].x;
      y = touch.touches[0].y;
    } else {
      let gesture = e as GestureEvent;
      if (!gesture.fingerList || gesture.fingerList.length == 0 || !gesture.fingerList[0]) {
        return;
      }
      x = gesture.fingerList[0].localX;
      y = gesture.fingerList[0].localY;
    }
    let h: Highlight | null = this.chart.getHighlightByTouchPoint(x, y);
    if (h) {
      this.performHighlight(h);
    }
    this.actionUp(isTouchEvent, e);
  }

  public stopDeceleration() {
    this.decelerationVelocity.x = 0;
    this.decelerationVelocity.y = 0;
  }

  public getMatrix(): Matrix {
    return this.matrix;
  }
}
