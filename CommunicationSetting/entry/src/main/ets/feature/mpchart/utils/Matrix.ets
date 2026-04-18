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
import MyRect from '../data/Rect';

export default class Matrix {
  public static mXScale: number = 0;
  public static mXSkew: number = 1;
  public static mXTrans: number = 2;
  public static mYSkew: number = 3;
  public static mYScale: number = 4;
  public static mYTrans: number = 5;
  public data: number[] = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0];

  public reset() {
    this.data = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0];
  }

  public set(matrix: Matrix) {
    this.data[Matrix.mXScale] = matrix.getValues()[Matrix.mXScale]
    this.data[Matrix.mXSkew] = matrix.getValues()[Matrix.mXSkew]
    this.data[Matrix.mXTrans] = matrix.getValues()[Matrix.mXTrans]
    this.data[Matrix.mYSkew] = matrix.getValues()[Matrix.mYSkew]
    this.data[Matrix.mYScale] = matrix.getValues()[Matrix.mYScale]
    this.data[Matrix.mYTrans] = matrix.getValues()[Matrix.mYTrans]
  }

  public getValues(): number[] {
    return this.data;
  }

  public setValues(values: number[]) {
    this.data = values;
  }

  public postScale(scaleX: number, scaleY: number, centerX?: number, centerY?: number) {
    this.data[Matrix.mXScale] *= scaleX;
    this.data[Matrix.mYScale] *= scaleY;
    if (centerX != null && centerX != undefined) {
      this.data[Matrix.mXTrans] = scaleX * (this.data[Matrix.mXTrans] - centerX) + centerX;
    } else {
      this.data[Matrix.mXTrans] *= scaleX;
    }
    if (centerY != null && centerY != undefined) {
      this.data[Matrix.mYTrans] = scaleY * (this.data[Matrix.mYTrans] - centerY) + centerY;
    } else {
      this.data[Matrix.mYTrans] *= scaleY;
    }
  }

  public postTranslate(dx: number, dy: number) {
    if (!Number.isNaN(dx) && dx != undefined) {
      this.data[Matrix.mXTrans] += dx;
    }
    if (!Number.isNaN(dy) && dy != undefined) {
      this.data[Matrix.mYTrans] += dy;
    }
  }

  public setTranslate(dx: number, dy: number) {
    if (!Number.isNaN(dx) && dx != undefined) {
      this.data[Matrix.mXTrans] = dx;
    }
    if (!Number.isNaN(dy) && dy != undefined) {
      this.data[Matrix.mYTrans] = dy;
    }
    this.data[Matrix.mXScale] = 1
    this.data[Matrix.mYScale] = 1
  }

  public mapPoints(pts: number[]) {
    const len = pts.length;
    const xScale = this.data[Matrix.mXScale];
    const yScale = this.data[Matrix.mYScale];
    const xTrans = this.data[Matrix.mXTrans];
    const yTrans = this.data[Matrix.mYTrans];
    for (let i = 0; i < len; i += 2) {
      pts[i] = pts[i] * xScale + xTrans;
    }
    for (let i = 1; i < len; i += 2) {
      pts[i] = pts[i] * yScale + yTrans;
    }
  }

  public mapRect(rect: MyRect) {
    let translateX: number = this.data[Matrix.mXTrans];
    let translateY: number = this.data[Matrix.mYTrans];
    let scaleX: number = this.data[Matrix.mXScale];
    let scaleY: number = this.data[Matrix.mYScale];

    let yValue1: number = rect.top * scaleY + translateY;
    let yValue2: number = rect.bottom * scaleY + translateY;
    if (yValue1 < yValue2) {
      rect.set(rect.left * scaleX + translateX, yValue1, rect.right * scaleX + translateX, yValue2);
    } else {
      rect.set(rect.left * scaleX + translateX, yValue2, rect.right * scaleX + translateX, yValue1);
    }
  }

  public invert(matrix: Matrix) {
    let values: number[] = matrix.getValues();
    values[Matrix.mXScale] = 1 / (this.data[Matrix.mXScale])
    values[Matrix.mYScale] = 1 / (this.data[Matrix.mYScale])
    values[Matrix.mXTrans] = -this.data[Matrix.mXTrans] * values[Matrix.mXScale]
    values[Matrix.mYTrans] = -this.data[Matrix.mYTrans] * values[Matrix.mYScale]
    matrix.setValues(values);
    return matrix;
  }
}