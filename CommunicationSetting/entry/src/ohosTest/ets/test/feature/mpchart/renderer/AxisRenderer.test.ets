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
import { Matrix, Transformer, ViewPortHandler, XAxis } from '../../../../../../main/ets/feature/mpchart';
import AxisRenderer from '../../../../../../main/ets/feature/mpchart/renderer/AxisRenderer';

export default function AxisRendererTest() {
  describe('AxisRendererTest', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });


    it('ComputeAxis', 0, () => {
      let viewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);
      let matrix = viewPortHandler.getMatrixTouch();
      let values = matrix.getValues();
      values[Matrix.mYScale] = 2;
      matrix.setValues(values)
      viewPortHandler.limitTransAndScale(matrix, viewPortHandler.getContentRect());

      let xAxis: XAxis = new XAxis();
      let trans: Transformer = new Transformer(viewPortHandler);
      let renderer = new TestAxisRenderer(viewPortHandler, xAxis, trans);
      expect(renderer.getAxis().entries.length).assertEqual(0);
      renderer.computeAxis(1, 1, false);
      expect(renderer.getAxis().entryCount).assertEqual(0);

      xAxis.setCenterAxisLabels(true);
      xAxis.entryCount = 2;
      renderer.computeAxis(1, 1, true);
      expect(renderer.getAxis().entryCount).assertEqual(8);

      xAxis.setLabelCount(10, true);
      renderer.computeAxis(1, 1, false);
      expect(renderer.getAxis().getLabelCount()).assertEqual(10);

      xAxis.setLabelCount(0, true);
      xAxis.entries = [1, 2, 3];
      renderer.computeAxis(1, 1, false);
      expect(renderer.getAxis().getLabelCount()).assertEqual(2);

      xAxis.setGranularity(10);
      renderer.computeAxis(1, 1, false);
      expect(renderer.getAxis().isGranularityEnabled()).assertEqual(true);
    });
  });
}

class TestAxisRenderer extends AxisRenderer {
  public renderAxisLabels(c: CanvasRenderingContext2D, isHorizontalFlip: boolean, isLeftAxis: boolean): void {
    throw new Error('Method not implemented.');
  }

  public renderGridLines(c: CanvasRenderingContext2D): void {
    throw new Error('Method not implemented.');
  }

  public renderAxisLine(c: CanvasRenderingContext2D, extraLine?: number | undefined): void {
    throw new Error('Method not implemented.');
  }

  public renderLimitLines(c: CanvasRenderingContext2D, isHorizontalFlip: boolean): void {
    throw new Error('Method not implemented.');
  }
}