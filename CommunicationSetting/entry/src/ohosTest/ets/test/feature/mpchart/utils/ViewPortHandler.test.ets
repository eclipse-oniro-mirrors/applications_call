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
import { BarChartModel, Matrix, ViewPortHandler } from '../../../../../../main/ets/feature/mpchart';

export default function ViewPortHandlerTest() {
  describe('ViewPortHandlerTest', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('SetChartDimension', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      expect(viewPortHandler.getChartWidth()).assertEqual(100);
      expect(viewPortHandler.getChartHeight()).assertEqual(200);
      expect(viewPortHandler.contentLeft()).assertEqual(0);
      expect(viewPortHandler.contentTop()).assertEqual(0);
      expect(viewPortHandler.contentRight()).assertEqual(100);
      expect(viewPortHandler.contentBottom()).assertEqual(200);
      expect(viewPortHandler.contentWidth()).assertEqual(100);
      expect(viewPortHandler.contentHeight()).assertEqual(200);
      const contentRect = viewPortHandler.getContentRect();
      expect(contentRect.left).assertEqual(0);
      expect(contentRect.top).assertEqual(0);
      expect(contentRect.right).assertEqual(100);
      expect(contentRect.bottom).assertEqual(200);
    });

    it('HasChartDimension', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let result = viewPortHandler.hasChartDimension();
      expect(result).assertEqual(false);
      viewPortHandler.setChartDimension(100, 200);
      result = viewPortHandler.hasChartDimension();
      expect(result).assertEqual(true);
    });

    it('CenterViewPort', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      let transformedPts: number[] = [1, 2];
      let view: BarChartModel = new BarChartModel();

      viewPortHandler.setMinimumScaleX(0.5);
      viewPortHandler.setMaximumScaleX(0);
      viewPortHandler.centerViewPort(transformedPts, view);
      expect(viewPortHandler.getScaleX()).assertEqual(1);
      expect(viewPortHandler.matrixTouch.getValues()[0]).assertEqual(1);

      viewPortHandler.setMinimumScaleX(2);
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.centerViewPort(transformedPts, view);
      expect(viewPortHandler.getScaleX()).assertEqual(2);
      expect(viewPortHandler.matrixTouch.getValues()[0]).assertEqual(2);
    });

    it('IsInBoundsX', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      let isInBoundsX = viewPortHandler.isInBoundsX(50);
      expect(isInBoundsX).assertEqual(true);
      isInBoundsX = viewPortHandler.isInBoundsX(150);
      expect(isInBoundsX).assertEqual(false);
    });

    it('IsInBoundsY', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      let isInBoundsY = viewPortHandler.isInBoundsY(100);
      expect(isInBoundsY).assertEqual(true);
      isInBoundsY = viewPortHandler.isInBoundsY(250);
      expect(isInBoundsY).assertEqual(false);
    });

    it('IsInBounds', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setChartDimension(100, 200);
      let isInBounds = viewPortHandler.isInBounds(50, 100);
      expect(isInBounds).assertEqual(true);
      isInBounds = viewPortHandler.isInBounds(150, 250);
      expect(isInBounds).assertEqual(false);
    });

    it('IsFullyZoomedOut', 0, () => {
      let viewPortHandler: ViewPortHandler = new ViewPortHandler();
      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(1);
      let isFullyZoomedOutX = viewPortHandler.isFullyZoomedOutX();
      expect(isFullyZoomedOutX).assertEqual(true);
      let isFullyZoomed = viewPortHandler.isFullyZoomedOut();
      expect(isFullyZoomed).assertEqual(true);

      viewPortHandler.setMaximumScaleX(2);
      viewPortHandler.setMinimumScaleX(2);
      isFullyZoomedOutX = viewPortHandler.isFullyZoomedOutX();
      expect(isFullyZoomedOutX).assertEqual(false);
      isFullyZoomed = viewPortHandler.isFullyZoomedOut();
      expect(isFullyZoomed).assertEqual(false);

      let isFullyZoomedOutY = viewPortHandler.isFullyZoomedOutY();
      expect(isFullyZoomedOutY).assertEqual(true);
      isFullyZoomed = viewPortHandler.isFullyZoomedOut();
      expect(isFullyZoomed).assertEqual(false);

      let matrix = viewPortHandler.getMatrixTouch();
      let values = matrix.getValues();
      values[Matrix.mYScale] = 2;
      matrix.setValues(values)
      viewPortHandler.limitTransAndScale(matrix, viewPortHandler.getContentRect());
      isFullyZoomedOutY = viewPortHandler.isFullyZoomedOutY();
      expect(isFullyZoomedOutY).assertEqual(false);
      isFullyZoomed = viewPortHandler.isFullyZoomedOut();
      expect(isFullyZoomed).assertEqual(false);
    });
  });
}