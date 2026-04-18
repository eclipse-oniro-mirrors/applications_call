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
import HashMap from '@ohos.util.HashMap';
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import Utils from '../../../../../../main/ets/feature/mpchart/utils/Utils';
import { LogUtil } from '../../../../../../main/ets/util/LogUtil';
import json from '@ohos.util.json';
import assertNaN from '@ohos/hypium/src/main/module/assert/assertNaN';
import Paint, { DashPathEffect, Style } from '../../../../../../main/ets/feature/mpchart/data/Paint';
import { BarEntry } from '../../../../../../main/ets/feature/mpchart';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';

export default function UtilsTest() {
  describe('UtilsTest', () => {
    let bundleName = 'com.ohos.communicationsetting';
    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('should_return_0_when_number_is_MAX_VALUE', 0, () => {
      const result = Utils.roundToNextSignificant(Number.MAX_VALUE);
      expect(result).assertEqual(0);
    });
    it('should_return_0_when_number_is_NaN', 0, () => {
      const result = Utils.roundToNextSignificant(NaN);
      expect(result).assertEqual(0);
    });
    it('should_return_0_when_number_is_0', 0, () => {
      const result = Utils.roundToNextSignificant(0.0);
      expect(result).assertEqual(0);
    });
    it('should_return_rounded_number_when_number_is_positive', 0, () => {
      const result = Utils.roundToNextSignificant(1234.5678);
      expect(result).assertEqual(1000);
    });
    it('should_return_rounded_number_when_number_is_negative', 0, () => {
      const result = Utils.roundToNextSignificant(-1234.5678);
      expect(result).assertEqual(-1000);
    });
    it('should_return_rounded_number_when_number_is_close_to_power_of_10', 0, () => {
      const result = Utils.roundToNextSignificant(9.87654321);
      expect(result).assertEqual(10);
    });
    it('should_return_rounded_number_when_number_is_close_to_power_of_10_but_not_exactly', 0, () => {
      const result = Utils.roundToNextSignificant(9.876543211);
      expect(result).assertEqual(10);
    });
    it('should_return_rounded_number_when_number_is_close_to_power_of_10_but_negative', 0, () => {
      const result = Utils.roundToNextSignificant(-9.87654321);
      expect(result).assertEqual(-10);
    });
    it('should_return_rounded_number_when_number_is_close_to_power_of_10_but_negative_and_not_exactly', 0, () => {
      const result = Utils.roundToNextSignificant(-9.876543211);
      expect(result).assertEqual(-10);
    });
    it('should_return_0_when_number_is_MAX_VALUE_getDecimals', 0, () => {
      let number: number = Number.MAX_VALUE;
      const result = Utils.getDecimals(number);
      expect(result).assertEqual(Infinity);
    });
    it('should_return_correct_number_when_number_is_not_MAX_VALUE', 0, () => {
      let number: number = 1234.5678;
      const result = Utils.getDecimals(number);
      expect(result).assertEqual(-1);
    });
    it('should_return_0_when_number_is_0_getDecimals', 0, () => {
      let number: number = 0;
      const result = Utils.getDecimals(number);
      expect(result).assertEqual(Infinity);
    });
    it('should_return_0_when_number_is_negative_and_greater_than_0', 0, () => {
      let number: number = -1234.5678;
      const result = Utils.getDecimals(number);
      assertNaN(result);
    });
    it('should_return_0_when_number_is_positive_and_less_than_1', 0, () => {
      let number: number = 0.0001;
      const result = Utils.getDecimals(number);
      expect(result).assertEqual(6);
    });
    it('should_return_0_when_number_is_negative_and_less_than_0', 0, () => {
      let number: number = -0.0001;
      const result = Utils.getDecimals(number);
      assertNaN(result);
    });
    it('should_return_MAX_VALUE_when_d_is_MAX_VALUE', 0, () => {
      const result = Utils.nextUp(Number.MAX_VALUE);
      expect(result).assertEqual(Number.MAX_VALUE);
    });
    it('should_return_d_plus_epsilon_when_d_is_not_MAX_VALUE', 0, () => {
      const result = Utils.nextUp(10.0);
      expect(result).assertEqual(10.000000001);
    });
    it('getLabelTextSizeTest01', 0, () => {
      let paint: Paint = new Paint();
      let textSizeCache = new HashMap<string, TextMetrics>();
      const textSize: TextMetrics = Utils.offCanvasContext2d.measureText('24');
      let textString = bundleName + paint.font;
      textSizeCache.set(textString, textSize);
      const result = Utils.getLabelTextSize(paint, bundleName, textSizeCache);
      expect(result).assertEqual(textSize);
    });
    it('getLabelTextSizeTest02', 0, () => {
      let paint: Paint = new Paint();
      let textSizeCache = new HashMap<string, TextMetrics>();
      const textSize: TextMetrics = Utils.offCanvasContext2d.measureText('24');
      let textString = bundleName;
      textSizeCache.set(textString, textSize);
      const result = Utils.getLabelTextSize(paint, bundleName, textSizeCache);
      expect(result == textSize).assertFalse();
    });
    it('resetContext2DWithoutFontTest01', 0, () => {
      let paint: Paint = new Paint();
      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      Utils.resetContext2DWithoutFont(context2D, paint);
      expect(context2D.getLineDash().length).assertEqual(0);
    });
    it('resetContext2DWithoutFontTest02', 0, () => {
      let paint: Paint = new Paint();
      paint.setDashPathEffect(new DashPathEffect([1, 1], 1));
      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      Utils.resetContext2DWithoutFont(context2D, paint);
      expect(context2D.lineDashOffset).assertEqual(undefined);
    });
    it('resetContext2DWithoutFontTest03', 0, () => {
      let paint: Paint = new Paint();
      paint.styleType = Style.FILL;
      paint.setDashPathEffect(new DashPathEffect([1, 1], 1));
      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      Utils.resetContext2DWithoutFont(context2D, paint);
      expect(context2D.lineDashOffset).assertEqual(undefined);
    });
    it('resetContext2DWithoutFontTest04', 0, () => {
      let paint: Paint = new Paint();
      paint.styleType = 4;
      paint.setDashPathEffect(new DashPathEffect([1, 1], 1));
      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      Utils.resetContext2DWithoutFont(context2D, paint);
      expect(context2D.lineDashOffset).assertEqual(undefined);
    });
    it('resetContext2DWithoutFontTest05', 0, () => {
      let paint: Paint = new Paint();
      paint.globalAlpha = undefined;
      paint.styleType = Style.STROKE;
      paint.setDashPathEffect(new DashPathEffect([1, 1], 1));
      let setRender = new RenderingContextSettings(true);
      let context2D = new CanvasRenderingContext2D(setRender);
      Utils.resetContext2DWithoutFont(context2D, paint);
      expect(context2D.lineDashOffset).assertEqual(undefined);
    });
    it('parseIntTest01', 0, () => {
      let result = Utils.parseInt(2345);
      expect(result).assertEqual(2345);
    });
    it('parseIntTest02', 0, () => {
      let result = Utils.parseInt(123.456);
      expect(result).assertEqual(123);
    });
    it('isHighLightEqualsTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let highLight2: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        2,
        1, 1,
        null
      );
      let result = Utils.isHighLightEquals(highLight, highLight2);
      expect(result).assertFalse();
    });
    it('isHighLightEqualsTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let highLight2: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = Utils.isHighLightEquals(highLight, highLight2);
      expect(result).assertTrue();
    });
    it('isHighLightEqualsTest03', 0, () => {
      let result = Utils.isHighLightEquals(null, null);
      expect(result).assertTrue();
    });
    it('isHighLightEqualsTest04', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = Utils.isHighLightEquals(highLight, null);
      expect(result).assertFalse();
    });
    it('isHighLightEqualsTest05', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let highLight2: Highlight = new Highlight(
        4, entry.getY(), 0, 0,
        2,
        1, 1,
        null
      );
      let result = Utils.isHighLightEquals(highLight, highLight2);
      expect(result).assertFalse();
    });
  });
}