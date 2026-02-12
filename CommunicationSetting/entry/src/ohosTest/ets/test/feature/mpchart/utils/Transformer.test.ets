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
import { Matrix, Transformer, ViewPortHandler } from '../../../../../../main/ets/feature/mpchart';
import MPPointD from '../../../../../../main/ets/feature/mpchart/utils/MPPointD';
import MyRect from '../../../../../../main/ets/feature/mpchart/data/Rect';

class transformerTest extends Transformer {
  constructor(viewHandler: ViewPortHandler) {
    super(viewHandler);
  }

  public getMatrixValueToPx(): Matrix {
    return this.matrixValueToPx;
  }

  public getMatrixOffset(): Matrix {
    return this.matrixOffset;
  }

  public getViewPortHandler(): ViewPortHandler {
    return this.viewPortHandler;
  }
}

class viewPortHandlerTest extends ViewPortHandler {
  public setContentRect(myRect: MyRect) {
    this.contentRect = myRect;
  }
}

export default function TransformerTest() {
  describe('TransformerTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('prepareMatrixValuePxTest01', 0, () => {
      let viewPortHandler: viewPortHandlerTest = new viewPortHandlerTest();
      viewPortHandler.setChartDimension(2, 2);
      let rect: MyRect = new MyRect(1, 1, 2, 2);
      viewPortHandler.setContentRect(rect);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      transformer.prepareMatrixValuePx(1, 0, 0, 1);
      let data: number[] = transformer.getMatrixValueToPx().getValues();
      expect(data[1]).assertEqual(0);
      expect(data[3]).assertEqual(0);
    })
    it('prepareMatrixValuePxTest02', 0, () => {
      let viewPortHandler: viewPortHandlerTest = new viewPortHandlerTest();
      viewPortHandler.setChartDimension(2, 2);
      let rect: MyRect = new MyRect(1, 1, 2, 2);
      viewPortHandler.setContentRect(rect);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      transformer.prepareMatrixValuePx(1, 1, 0, 1);
      let data: number[] = transformer.getMatrixValueToPx().getValues();
      expect(data[0]).assertEqual(1);
      expect(data[1]).assertEqual(0);
      expect(data[2]).assertEqual(-1);
      expect(data[3]).assertEqual(0);
    })
    it('prepareMatrixValuePxTest03', 0, () => {
      let viewPortHandler: viewPortHandlerTest = new viewPortHandlerTest();
      viewPortHandler.setChartDimension(2, 2);
      let rect: MyRect = new MyRect(1, 1, 2, 2);
      viewPortHandler.setContentRect(rect);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      transformer.prepareMatrixValuePx(1, 0, 1, 1);
      let data: number[] = transformer.getMatrixValueToPx().getValues();
      expect(data[1]).assertEqual(0);
      expect(data[3]).assertEqual(0);
      expect(data[4]).assertEqual(-1);
      expect(data[5]).assertEqual(1);
    })
    it('prepareMatrixValuePxTest04', 0, () => {
      let viewPortHandler: viewPortHandlerTest = new viewPortHandlerTest();
      viewPortHandler.setChartDimension(2, 2);
      let rect: MyRect = new MyRect(1, 1, 2, 2);
      viewPortHandler.setContentRect(rect);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      transformer.prepareMatrixValuePx(1, 1, 1, 1);
      let data: number[] = transformer.getMatrixValueToPx().getValues();
      expect(data[0]).assertEqual(1);
      expect(data[1]).assertEqual(0);
      expect(data[2]).assertEqual(-1);
      expect(data[3]).assertEqual(0);
      expect(data[4]).assertEqual(-1);
      expect(data[5]).assertEqual(1);
    })
    it('prepareMatrixValuePxTest05', 0, () => {
      let viewPortHandler: viewPortHandlerTest = new viewPortHandlerTest();
      viewPortHandler.setChartDimension(2, 2);
      let rect: MyRect = new MyRect(1, 1, 2, 2);
      let rect2: MyRect = new MyRect(2, 2, 0, 0, rect);
      viewPortHandler.setContentRect(rect2);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      transformer.prepareMatrixValuePx(1, 1, 1, 1);
      let data: number[] = transformer.getMatrixValueToPx().getValues();
      expect(data[0]).assertEqual(1);
      expect(data[1]).assertEqual(0);
      expect(data[2]).assertEqual(-1);
      expect(data[3]).assertEqual(0);
      expect(data[4]).assertEqual(-1);
      expect(data[5]).assertEqual(1);
    })
    it('prepareMatrixOffsetTest01', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(2, 2);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      transformer.prepareMatrixOffset(true);
      let data: number[] = transformer.getMatrixOffset().getValues();
      expect(data[0]).assertEqual(1);
      expect(data[1]).assertEqual(0);
      expect(data[2]).assertEqual(0);
      expect(data[3]).assertEqual(0);
      expect(data[4]).assertEqual(-1);
      expect(data[5]).assertEqual(0);
    })
    it('prepareMatrixOffsetTest02', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(2, 2);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      transformer.prepareMatrixOffset(false);
      let data: number[] = transformer.getMatrixOffset().getValues();
      expect(data[0]).assertEqual(1);
      expect(data[1]).assertEqual(0);
      expect(data[2]).assertEqual(0);
      expect(data[3]).assertEqual(0);
      expect(data[4]).assertEqual(1);
      expect(data[5]).assertEqual(2);
    })
    it('getValuesByTouchPointTest01', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(1, 1);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      let result: MPPointD = transformer.getValuesByTouchPoint(2, 2);
      expect(result.x).assertEqual(2);
      expect(result.y).assertEqual(2);
    })
    it('getValuesByTouchPointTest02', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(1, 1);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      let result: MPPointD = transformer.getValuesByTouchPoint(2, 2, undefined);
      expect(result.x).assertEqual(2);
      expect(result.y).assertEqual(2);
    })
    it('getValuesByTouchPointTest03', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(1, 1);
      let transformer: transformerTest = new transformerTest(viewPortHandler);
      let outputPoint: MPPointD = MPPointD.getInstance(4, 4);
      let result: MPPointD = transformer.getValuesByTouchPoint(1, 1, outputPoint);
      expect(result.x).assertEqual(1);
      expect(result.y).assertEqual(1);
    })
  })
}