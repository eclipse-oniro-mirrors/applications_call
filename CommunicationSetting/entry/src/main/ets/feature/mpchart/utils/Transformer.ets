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
import MPPointD from '../utils/MPPointD'
import ViewPortHandler from './ViewPortHandler'
import Matrix from './Matrix'
import MyRect from '../data/Rect'

export default class Transformer {
  protected matrixValueToPx: Matrix = new Matrix();
  protected matrixOffset: Matrix = new Matrix();
  protected viewPortHandler: ViewPortHandler;
  private ptsBuffer: number[] = new Array<number>(2);

  constructor(viewPortHandler: ViewPortHandler) {
    this.viewPortHandler = viewPortHandler;
  }

  public prepareMatrixValuePx(xChartMin: number, deltaX: number, deltaY: number, yChartMin: number) {
    let scaleX: number = this.viewPortHandler.contentWidth() / deltaX;
    let scaleY: number = this.viewPortHandler.contentHeight() / deltaY;
    if (scaleX == Number.MAX_VALUE) {
      scaleX = 0;
    }
    if (scaleY == Number.MAX_VALUE) {
      scaleY = 0;
    }

    this.matrixValueToPx.reset();
    this.matrixValueToPx.postTranslate(-xChartMin, -yChartMin);
    this.matrixValueToPx.postScale(scaleX, -scaleY);
  }

  public prepareMatrixOffset(inverted: boolean) {
    this.matrixOffset.reset();
    if (!inverted) {
      this.matrixOffset.postTranslate(this.viewPortHandler.offsetLeft(),
        this.viewPortHandler.getChartHeight() - this.viewPortHandler.offsetBottom());
    } else {
      this.matrixOffset
        .setTranslate(this.viewPortHandler.offsetLeft(), -this.viewPortHandler.offsetTop());
      this.matrixOffset.postScale(1.0, -1.0);
    }
  }

  public pointValuesToPixel(pts: number[]) {
    this.matrixValueToPx.mapPoints(pts);
    this.viewPortHandler.getMatrixTouch().mapPoints(pts);
    this.matrixOffset.mapPoints(pts);
  }

  public rectToPixelPhase(r: MyRect, phaseY: number) {
    r.top *= phaseY;
    r.bottom *= phaseY;

    this.matrixValueToPx.mapRect(r);
    this.viewPortHandler.getMatrixTouch().mapRect(r);
    this.matrixOffset.mapRect(r);
  }

  public pixelsToValue(pixels: number[]) {
    let tmp: Matrix = new Matrix();
    tmp.reset();
    this.matrixOffset.invert(tmp);
    tmp.mapPoints(pixels);

    this.viewPortHandler.getMatrixTouch().invert(tmp);
    tmp.mapPoints(pixels);

    this.matrixValueToPx.invert(tmp);
    tmp.mapPoints(pixels);
  }

  public getValuesByTouchPoint(x: number, y: number, outputPoint?: MPPointD): MPPointD {
    let result: MPPointD = (outputPoint != null && outputPoint != undefined) ? outputPoint : MPPointD.getInstance(0, 0);
    this.ptsBuffer[0] = x;
    this.ptsBuffer[1] = y;
    this.pixelsToValue(this.ptsBuffer);
    result.x = this.ptsBuffer[0];
    result.y = this.ptsBuffer[1];
    return result;
  }

  public getPixelForValues(x: number, y: number): MPPointD {
    this.ptsBuffer[0] = x;
    this.ptsBuffer[1] = y;
    this.pointValuesToPixel(this.ptsBuffer);
    let xPx: number = this.ptsBuffer[0];
    let yPx: number = this.ptsBuffer[1];
    return MPPointD.getInstance(xPx, yPx);
  }
}