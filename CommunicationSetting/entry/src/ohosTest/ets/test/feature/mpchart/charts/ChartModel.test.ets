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
  AxisDependency,
  BarChartModel,
  BarData,
  BarEntry,
  ChartTouchListener,
  IDataSet,
  JArrayList,
  Matrix,
  OnChartValueSelectedListener,
  Transformer,
  ViewPortHandler,
  XAxis
} from '../../../../../../main/ets/feature/mpchart';
import Paint from '../../../../../../main/ets/feature/mpchart/data/Paint';

import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';
import MoveViewJob from '../../../../../../main/ets/feature/mpchart/jobs/MoveViewJob';
import CanvasUtil from '../../../../../../main/ets/feature/mpchart/utils/CanvasUtil';
import Utils from '../../../../../../main/ets/feature/mpchart/utils/Utils';
import { LogUtil } from '../../../../../../main/ets/util/LogUtil';

export default function ChartModelTest() {
  describe('ChartModelTest', () => {
    let barChartModel: BarChartModel = new BarChartModel();
    let mocker: MockKit;
    let highs = [new Highlight(1, 1, 2, 0, 0, 2, 2, null)];
    beforeEach(() => {
      mocker = new MockKit();
    })

    it('setData', 0, () => {
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      let barData: BarData = new BarData(dataSetList);
      let notifyDataChanged = false;
      let notifyDataSetChanged: Function = mocker.mockFunc(barChartModel, barChartModel.notifyDataSetChanged);
      when(notifyDataSetChanged)(ArgumentMatchers.any).afterAction(() => notifyDataChanged = true);
      barChartModel.setData(barData);
      expect(notifyDataChanged).assertTrue();
      barChartModel.setData(null);
      expect(notifyDataChanged).assertTrue();
      mocker.clear(notifyDataSetChanged);
    })

    it('clear', 0, () => {
      barChartModel.chartTouchListener = new ChartTouchListener(barChartModel, new Matrix(), 3);
      let validate = false;
      let invalidate: Function = mocker.mockFunc(barChartModel, barChartModel.invalidate);
      when(invalidate)(ArgumentMatchers.any).afterAction(() => validate = true);
      barChartModel.clear();
      expect(validate).assertTrue();
      mocker.clear(invalidate);
    })

    it('addViewportJob', 0, () => {
      let viewPortHandler = barChartModel.viewPortHandler;
      let hasChartDimension: Function = mocker.mockFunc(viewPortHandler, viewPortHandler.hasChartDimension);
      when(hasChartDimension)(ArgumentMatchers.any).afterReturn(false);
      let job: MoveViewJob =
        new MoveViewJob(new ViewPortHandler(), 1, 1, new Transformer(new ViewPortHandler()), barChartModel);
      let jobs = barChartModel.jobs;
      let isAdd = false;
      let add: Function = mocker.mockFunc(jobs, jobs.add);
      when(add)(ArgumentMatchers.any).afterAction(() => isAdd = true);
      barChartModel.addViewportJob(job);
      expect(isAdd).assertTrue();
      let isRun = false;
      when(hasChartDimension)(ArgumentMatchers.any).afterReturn(true);
      let run: Function = mocker.mockFunc(job, job.run);
      when(run)(ArgumentMatchers.any).afterAction(() => isRun = true);
      barChartModel.addViewportJob(job);
      expect(isRun).assertTrue();
      mocker.clear(hasChartDimension);
      mocker.clear(add);
      mocker.clear(run);
    })

    it('setupDefaultFormatter', 0, () => {
      barChartModel.chartData = null;
      barChartModel.setupDefaultFormatter(1, 2);
      expect(barChartModel.defaultValueFormatter.decimalDigits).assertEqual(2);
      let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
      barChartModel.chartData = new BarData(dataSetList);
      let chartData = barChartModel.chartData;
      let getEntryCount: Function = mocker.mockFunc(chartData, chartData.getEntryCount);
      when(getEntryCount)(ArgumentMatchers.any).afterReturn(3);
      barChartModel.setupDefaultFormatter(1, 2);
      expect(barChartModel.defaultValueFormatter.decimalDigits).assertEqual(2);
      mocker.clear(getEntryCount);
    })

    it('onDraw', 0, () => {
      let c: CanvasRenderingContext2D = new CanvasRenderingContext2D();
      barChartModel.chartData = null;
      barChartModel.chartSizeCorrected = true;
      barChartModel.infoPaint = new Paint();
      let str = false;
      let strIsEmpty: Function = mocker.mockFunc(barChartModel, barChartModel.strIsEmpty);
      when(strIsEmpty)(ArgumentMatchers.any).afterAction(() => {
        str = true
      });
      let infoPaint = barChartModel.infoPaint;
      let getTextAlign: Function = mocker.mockFunc(infoPaint, infoPaint.getTextAlign);
      when(getTextAlign)(ArgumentMatchers.any).afterReturn('start');
      barChartModel.onDraw(c);
      expect(str).assertTrue();
      expect(c.width).assertEqual(0);
      when(getTextAlign)(ArgumentMatchers.any).afterReturn('end');
      barChartModel.onDraw(c);
      expect(c.width).assertEqual(0);
      when(getTextAlign)(ArgumentMatchers.any).afterReturn('left');
      barChartModel.onDraw(c);
      expect(c.width).assertEqual(0)
      barChartModel.chartData = new BarData();
      barChartModel.offsetsCalculated = false;
      barChartModel.offsetsCalculated = true;
      barChartModel.onDraw(c);
      expect(barChartModel.offsetsCalculated).assertTrue();
      barChartModel.chartSizeCorrected = false;
      barChartModel.onDraw(c);
      expect(barChartModel.offsetsCalculated).assertTrue();
      mocker.clear(strIsEmpty);
      mocker.clear(getTextAlign);
    })

    it('valuesToHighlight', 0, () => {
      barChartModel.indicesToHighlight = highs;
      expect(barChartModel.valuesToHighlight()).assertTrue();
      barChartModel.indicesToHighlight = null;
      expect(barChartModel.valuesToHighlight()).assertFalse();
    })

    it('setLastHighlighted', 0, () => {
      barChartModel.chartTouchListener = new ChartTouchListener(barChartModel, new Matrix(), 3);
      barChartModel.setLastHighlighted(highs);
      let lastHighlighted = JSON.stringify(barChartModel.chartTouchListener.lastHighlighted);
      expect(lastHighlighted).assertEqual(JSON.stringify(highs[0]));
      barChartModel.setLastHighlighted([]);
      expect(barChartModel.chartTouchListener.lastHighlighted).assertEqual(null);
    })

    it('highlightValueForObject', 0, () => {
      barChartModel.highlightValueForObject(null);
      expect(barChartModel.indicesToHighlight).assertEqual(null);
      barChartModel.chartData = new BarData();
      let entryForHighlight = false;
      let getEntryForHighlight: Function =
        mocker.mockFunc(barChartModel.chartData, barChartModel.chartData.getEntryForHighlight);
      when(getEntryForHighlight)(ArgumentMatchers.any).afterAction(() => entryForHighlight = true);
      barChartModel.highlightValueForObject(highs[0]);
      expect(entryForHighlight).assertEqual(true);
      when(getEntryForHighlight)(ArgumentMatchers.any).afterReturn(null);
      barChartModel.highlightValueForObject(highs[0]);
      expect(barChartModel.indicesToHighlight).assertEqual(null);
      when(getEntryForHighlight)(ArgumentMatchers.any).afterReturn(1);
      let lastHighlighted = false;
      let setLastHighlighted: Function = mocker.mockFunc(barChartModel, barChartModel.setLastHighlighted);
      when(setLastHighlighted)(ArgumentMatchers.any).afterAction(() => lastHighlighted = true);
      barChartModel.selectionListener = {
        onValueSelected: (e: BarEntry) => {
        },
        onNothingSelected: () => {
        }
      } as OnChartValueSelectedListener;
      let valuesToHighlight: Function = mocker.mockFunc(barChartModel, barChartModel.valuesToHighlight);
      when(valuesToHighlight)(ArgumentMatchers.any).afterReturn(null);
      let nothingSelected = false;
      let onNothingSelected: Function =
        mocker.mockFunc(barChartModel.selectionListener, barChartModel.selectionListener.onNothingSelected);
      when(onNothingSelected)(ArgumentMatchers.any).afterAction(() => nothingSelected = true);
      barChartModel.highlightValueForObject(highs[0], true);
      expect(JSON.stringify(barChartModel.indicesToHighlight)).assertEqual(JSON.stringify(highs));
      expect(lastHighlighted).assertTrue();
      expect(nothingSelected).assertTrue();
      when(valuesToHighlight)(ArgumentMatchers.any).afterReturn(1);
      when(getEntryForHighlight)(ArgumentMatchers.any).afterReturn(1);
      let valueSelected = false;
      let onValueSelected: Function =
        mocker.mockFunc(barChartModel.selectionListener, barChartModel.selectionListener.onValueSelected);
      when(onValueSelected)(ArgumentMatchers.any).afterAction(() => valueSelected = true);
      barChartModel.highlightValueForObject(highs[0], true);
      expect(valueSelected).assertTrue();
      mocker.clear(getEntryForHighlight);
      mocker.clear(setLastHighlighted);
      mocker.clear(valuesToHighlight);
      mocker.clear(onNothingSelected);
      mocker.clear(onValueSelected);
    })

    it('onSizeChanged', 0, () => {
      let chartDimension = false;
      let setChartDimension: Function =
        mocker.mockFunc(barChartModel.viewPortHandler, barChartModel.viewPortHandler.setChartDimension);
      when(setChartDimension)(ArgumentMatchers.any).afterAction(() => chartDimension = true);
      barChartModel.onSizeChanged(1, 1);
      expect(chartDimension).assertTrue();
      mocker.clear(setChartDimension);
    })

    it('getHighlightByTouchPoint', 0, () => {
      barChartModel.chartData = null;
      let hghLight = barChartModel.getHighlightByTouchPoint(1, 1);
      expect(hghLight).assertEqual(null);
    })
  })
}