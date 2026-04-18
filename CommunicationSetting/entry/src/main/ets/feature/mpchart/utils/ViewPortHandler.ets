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
import MyRect from '../data/Rect'
import Matrix from '../utils/Matrix'
import Chart from '../charts/ChartModel'
import BarEntry from '../data/BarEntry'
import IDataSet from '../interfaces/datasets/IDataSet'
import ChartData from '../data/ChartData'

export default class ViewPortHandler {
  public matrixTouch: Matrix = new Matrix();
  public contentRect = new MyRect();
  protected chartWidth: number = 0.0;
  protected chartHeight: number = 0.0;
  private minScaleY: number = 1.0;
  public minScaleX: number = 1.0;
  public maxScaleX: number = Number.MAX_VALUE;
  private scaleX: number = 1.0;
  private scaleY: number = 1.0;
  private transX: number = 0.0;
  private transY: number = 0.0;
  protected centerViewPortMatrixBuffer: Matrix = new Matrix();
  protected matrixBuffer: number[] = new Array<number>(9);

  public setChartDimension(width: number, height: number) {
    let offsetLeft = this.offsetLeft();
    let offsetTop = this.offsetTop();
    let offsetRight = this.offsetRight();
    let offsetBottom = this.offsetBottom();
    this.chartHeight = height;
    this.chartWidth = width;
    this.restrainViewPort(offsetLeft, offsetTop, offsetRight, offsetBottom);
  }

  public hasChartDimension(): boolean {
    if (this.chartHeight > 0 && this.chartWidth > 0) {
      return true;
    } else {
      return false;
    }
  }

  public restrainViewPort(offsetLeft: number, offsetTop: number, offsetRight: number, offsetBottom: number) {
    this.contentRect.set(offsetLeft, offsetTop, this.chartWidth - offsetRight, this.chartHeight - offsetBottom);
  }

  public offsetLeft(): number {
    return this.contentRect.left;
  }

  public offsetRight(): number {
    return this.chartWidth - this.contentRect.right;
  }

  public offsetTop(): number {
    return this.contentRect.top;
  }

  public offsetBottom(): number {
    return this.chartHeight - this.contentRect.bottom;
  }

  public contentTop(): number {
    return this.contentRect.top;
  }

  public contentLeft(): number {
    return this.contentRect.left;
  }

  public contentRight(): number {
    return this.contentRect.right;
  }

  public contentBottom(): number {
    return this.contentRect.bottom;
  }

  public contentWidth(): number {
    return this.contentRect.width();
  }

  public contentHeight(): number {
    return this.contentRect.height();
  }

  public getContentRect(): MyRect {
    return this.contentRect;
  }

  public getChartHeight(): number {
    return this.chartHeight;
  }

  public getChartWidth(): number {
    return this.chartWidth;
  }



  public centerViewPort(transformedPts: number[], view: Chart<ChartData<IDataSet>>) {
    let save: Matrix = this.centerViewPortMatrixBuffer;
    save.reset();
    save.set(this.matrixTouch);

    const x: number = transformedPts[0] - this.offsetLeft();
    const y: number = transformedPts[1] - this.offsetTop();

    save.postTranslate(-x, -y);

    this.refresh(save, view);
  }

  public refresh(newMatrix: Matrix, chart: Chart<ChartData<IDataSet>>): Matrix {
    this.matrixTouch.set(newMatrix);
    this.limitTransAndScale(this.matrixTouch, this.contentRect);
    chart.invalidate();
    newMatrix.set(this.matrixTouch);
    return newMatrix;
  }

  private getMatrix(): void {
    this.matrixBuffer[Matrix.mXTrans] = this.transX;
    this.matrixBuffer[Matrix.mXScale] = this.scaleX;
    this.matrixBuffer[Matrix.mYTrans] = this.transY;
    this.matrixBuffer[Matrix.mYScale] = this.scaleY;
  }

  public limitTransAndScale(matrix: Matrix, content: MyRect) {
    this.matrixBuffer = matrix.getValues();
    let curTransX: number = this.matrixBuffer[Matrix.mXTrans];
    let curScaleX: number = this.matrixBuffer[Matrix.mXScale];
    let curTransY: number = this.matrixBuffer[Matrix.mYTrans];
    let curScaleY: number = this.matrixBuffer[Matrix.mYScale];
    this.scaleX = Math.min(Math.max(this.minScaleX, curScaleX), this.maxScaleX);
    this.scaleY = Math.min(Math.max(this.minScaleY, curScaleY), Number.MAX_VALUE);
    let width: number = 0;
    let height: number = 0;
    if (content != null) {
      width = content.width();
      height = content.height();
    }
    let maxTransX: number = -width * (this.scaleX - 1);
    this.transX = Math.min(Math.max(curTransX, maxTransX), 0);
    let maxTransY: number = height * (this.scaleY - 1);
    this.transY = Math.max(Math.min(curTransY, maxTransY), -0);
    this.getMatrix();
    matrix.setValues(this.matrixBuffer);
  }

  public setMinimumScaleX(xScale: number) {
    if (xScale < 1) {
      xScale = 1;
    }
    this.minScaleX = xScale;
    this.limitTransAndScale(this.matrixTouch, this.contentRect);
  }

  public setMaximumScaleX(xScale: number) {
    if (xScale == 0.0) {
      xScale = Number.MAX_VALUE;
    }
    this.maxScaleX = xScale;
    this.limitTransAndScale(this.matrixTouch, this.contentRect);
  }

  public getMatrixTouch(): Matrix {
    return this.matrixTouch;
  }

  public isInBoundsX(x: number): boolean {
    return this.isInBoundsLeft(x) && this.isInBoundsRight(x);
  }

  public isInBoundsY(y: number) {
    return (this.contentRect.top <= y) && (this.contentRect.bottom >= y);
  }

  public isInBounds(x: number, y: number): boolean {
    return this.isInBoundsX(x) && this.isInBoundsY(y);
  }

  public isInBoundsLeft(x: number): boolean {
    return this.contentRect.left <= x + 1;
  }

  public isInBoundsRight(x: number): boolean {
    return this.contentRect.right >= x - 1;
  }

  public getScaleX(): number {
    return this.scaleX;
  }

  public isFullyZoomedOut(): boolean {
    return this.isFullyZoomedOutX() && this.isFullyZoomedOutY();
  }

  public isFullyZoomedOutY(): boolean {
    return !(this.scaleY > this.minScaleY || this.minScaleY > 1);
  }

  public isFullyZoomedOutX(): boolean {
    return !(this.scaleX > this.minScaleX || this.minScaleX > 1);
  }
}
