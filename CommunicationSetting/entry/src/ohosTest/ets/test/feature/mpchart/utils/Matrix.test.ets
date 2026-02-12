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
import { describe, beforeAll, it, expect } from '@ohos/hypium'
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../../../testability/TestAbility';
import { Matrix } from '../../../../../../main/ets/feature/mpchart';
import MyRect from '../../../../../../main/ets/feature/mpchart/data/Rect';

export default function MatrixTest() {
  describe('MatrixTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('postScaleTest01', 0, () => {
      let data: number[] = [1, 1, 1, 1, 1, 1];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      matrix.postScale(2, 3);
      expect(matrix.getValues()[Matrix.mXSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mXTrans]).assertEqual(2);
      expect(matrix.getValues()[Matrix.mYSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mYTrans]).assertEqual(3);
      expect(matrix.getValues()[Matrix.mXScale]).assertEqual(2);
      expect(matrix.getValues()[Matrix.mYScale]).assertEqual(3);
    })
    it('postScaleTest02', 0, () => {
      let data: number[] = [1, 1, 1, 1, 1, 1];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      matrix.postScale(2, 3, 4, undefined);
      expect(matrix.getValues()[Matrix.mXSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mXTrans]).assertEqual(-2);
      expect(matrix.getValues()[Matrix.mYSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mYTrans]).assertEqual(3);
      expect(matrix.getValues()[Matrix.mXScale]).assertEqual(2);
      expect(matrix.getValues()[Matrix.mYScale]).assertEqual(3);
    })
    it('postScaleTest03', 0, () => {
      let data: number[] = [1, 1, 1, 1, 1, 1];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      matrix.postScale(2, 3, undefined, 4);
      expect(matrix.getValues()[Matrix.mXSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mXTrans]).assertEqual(2);
      expect(matrix.getValues()[Matrix.mYSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mYTrans]).assertEqual(-5);
      expect(matrix.getValues()[Matrix.mXScale]).assertEqual(2);
      expect(matrix.getValues()[Matrix.mYScale]).assertEqual(3);
    })
    it('postTranslateTest01', 0, () => {
      let data: number[] = [1, 1, 1, 1, 1, 1];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      matrix.postTranslate(2, 3);
      expect(matrix.getValues()[Matrix.mXSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mXTrans]).assertEqual(3);
      expect(matrix.getValues()[Matrix.mYSkew]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mYTrans]).assertEqual(4);
      expect(matrix.getValues()[Matrix.mXScale]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mYScale]).assertEqual(1);
    })
    it('setTranslateTest01', 0, () => {
      let data: number[] = [0, 0, 0, 0, 0, 0];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      matrix.setTranslate(2, 3);
      expect(matrix.getValues()[Matrix.mXSkew]).assertEqual(0);
      expect(matrix.getValues()[Matrix.mXTrans]).assertEqual(2);
      expect(matrix.getValues()[Matrix.mYSkew]).assertEqual(0);
      expect(matrix.getValues()[Matrix.mYTrans]).assertEqual(3);
      expect(matrix.getValues()[Matrix.mXScale]).assertEqual(1);
      expect(matrix.getValues()[Matrix.mYScale]).assertEqual(1);
    })
    it('setTranslateTest02', 0, () => {
      let data: number[] = [2, 2, 2, 2, 2, 2];
      let matrix1: Matrix = new Matrix();
      let matrix2: Matrix = new Matrix();
      matrix2.setValues(data);
      matrix1.set(matrix2);
      expect(matrix1.getValues()[Matrix.mXSkew]).assertEqual(2);
      expect(matrix1.getValues()[Matrix.mXTrans]).assertEqual(2);
      expect(matrix1.getValues()[Matrix.mYSkew]).assertEqual(2);
      expect(matrix1.getValues()[Matrix.mYTrans]).assertEqual(2);
      expect(matrix1.getValues()[Matrix.mXScale]).assertEqual(2);
      expect(matrix1.getValues()[Matrix.mYScale]).assertEqual(2);
    })
    it('mapRectTest01', 0, () => {
      let data: number[] = [1, 2, 3, 4, 5, 6];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      let myRect: MyRect = new MyRect(0, 0, 0, 0)
      matrix.mapRect(myRect);
      expect(myRect.left).assertEqual(3);
      expect(myRect.top).assertEqual(6);
      expect(myRect.right).assertEqual(3);
      expect(myRect.bottom).assertEqual(6);
    })
    it('mapRectTest02', 0, () => {
      let data: number[] = [6, 5, 4, 3, 2, 1];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      let myRect: MyRect = new MyRect(0, 0, 0, 0)
      matrix.mapRect(myRect);
      expect(myRect.left).assertEqual(4);
      expect(myRect.top).assertEqual(1);
      expect(myRect.right).assertEqual(4);
      expect(myRect.bottom).assertEqual(1);
    })
    it('mapRectTest03', 0, () => {
      let data: number[] = [1, 2, 3, 4, 5, 6];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      let myRect: MyRect = new MyRect(0, 0, 0, 1)
      matrix.mapRect(myRect);
      expect(myRect.left).assertEqual(3);
      expect(myRect.top).assertEqual(6);
      expect(myRect.right).assertEqual(3);
      expect(myRect.bottom).assertEqual(11);
    })
    it('mapPointsTest01', 0, () => {
      let data: number[] = [1, 2, 3, 4, 5, 6];
      let matrix: Matrix = new Matrix();
      matrix.setValues(data);
      let pts: number[] = [0, 0, 0, 0]
      matrix.mapPoints(pts);
      expect(pts[0]).assertEqual(3);
      expect(pts[1]).assertEqual(6);
      expect(pts[2]).assertEqual(3);
      expect(pts[3]).assertEqual(6);
    })
  })
}