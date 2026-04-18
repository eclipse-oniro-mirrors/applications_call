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
import {
  AxisDependency,
  BarChart,
  BarChartModel,
  BarData,
  BarDataSet,
  BarEntry,
  ChartGesture,
  CustomUiInfo,
  IAxisValueFormatter,
  IDataSet,
  JArrayList,
  OnChartGestureListener,
  OnChartValueSelectedListener,
  Transformer,
  ViewPortHandler,
  XAxis,
  XAxisPosition,
  XAxisRenderer,
  YAxis,
  YAxisLabelPosition,
  Matrix,
  ChartTouchListener,
  AccessibilityTextHandler
} from '../feature/mpchart';
import { BusinessError } from '@ohos.base';
import { statistics } from '@kit.NetworkKit';
import { sim } from '@kit.TelephonyKit';
import {
  ABROAD_BUNDLE_NAME,
  ABROAD_OLD_BUNDLE_NAME,
  ABROAD_TOTAL_UID,
  DROI_BUNDLE_NAME,
  DROI_OLD_BUNDLE_NAME,
  getFlowText,
  DROI_UID,
  BAR_COUNT,
  DUARTION_DAY_30,
  DUARTION_HOUR_24,
  SearchMode
} from '../constants/CommonConstants';
import resourceManager from '@ohos.resourceManager';
import { LogUtil } from '../util/LogUtil';
import { ConfigurationConstant, UIExtensionContentSession } from '@kit.AbilityKit';
import { ChartColorCategory, getChartColor } from '../util/ChartColorModeUtil';
import { display, router } from '@kit.ArkUI';
import { chartVirtualNodeBuild, ChartSizeInterface } from './ChartVirtualNodeComponent';
import { AccessibilityUtils, ISOPENACCESSIBILITY } from '../util/AccessibilityUtils';
import { HashMap } from '@kit.ArkTS';
import Utils from '../feature/mpchart/utils/Utils';

const TAG: string = 'ChartComponent';
const VIRTUAL_NODEID: string = 'singleVirtualNode';

@Component
export struct ChartComponent {
  @Consume chartDate: number[];
  @Consume @Watch('onDataValuesChanged') dataValues: number[][];
  @Consume durationChoice: number;
  @State model: BarChartModel | undefined = undefined;
  @State @Watch('onMaxYValueChanged') maxY: number = 4;
  @Consume customUiInfo: CustomUiInfo;
  @StorageProp('currentColorMode') @Watch('onColorModeChange') currentColorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Consume @Watch('onScrollStatusChanged') isSingleAppScrolling: boolean;
  private rightAxis: YAxis | null = null;
  private leftAxis: YAxis | null = null;
  private xAxis: XAxis | null = null;
  private data: BarData | null = null;
  private unit: string = 'B';
  private dataSet: BarDataSet | null = null;
  private isBarChartVisible = true;
  @Consume session: UIExtensionContentSession;
  @State edgeSize: ChartSizeInterface = {
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
    firstNodeWidth: 0,
    lastNodeWidth: 0,
    nodeWidth: 0,
  };
  @State chartStr: string[] = ['', '', '', '', '', '', '', ''];
  // 是否启动无障碍
  @StorageProp(ISOPENACCESSIBILITY) @Watch('onAccessibilityStatusChanged') isOpenAccessibility: boolean = false;
  @StorageProp('foldStatus') @Watch('onFoldStatusChanged') foldStatus: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  private timeoutId: number = -1;
  private textSizeCache = new HashMap<string, TextMetrics>();

  onMaxYValueChanged() {
    if (this.model) {
      let axisRendererRight = this.model.getAxisRendererRight();
      let viewPortRightOffset: number = 22;
      if (axisRendererRight) {
        let maxWidth =
          Utils.getLabelTextSize(axisRendererRight.getPaintAxisLabels(), this.maxY.toString(), this.textSizeCache)
            .width + Utils.handleDataValues(5);
        viewPortRightOffset = Math.max(maxWidth, viewPortRightOffset);
      }
      this.model.setViewPortOffsets(12, 6.5, viewPortRightOffset, 15);
    }
  }

  onFoldStatusChanged() {
    if (this.isOpenAccessibility) {
      AccessibilityUtils.sendAccessibilityEvent(VIRTUAL_NODEID);
      if (this.timeoutId !== -1) {
        clearTimeout(this.timeoutId);
      }
      // 展开折叠 柱状图重绘需要时间
      this.timeoutId = setTimeout(() => {
        this.handleChartOffsetForAccessibility();
      }, 350);
    }
  }

  onAccessibilityStatusChanged() {
    this.customUiInfo.showUi = false;
    if (this.isOpenAccessibility) {
      this.handleChartOffsetForAccessibility();
    }
  }

  /**
   * 计算柱形图最后一个虚拟焦点的宽度
   * @param offsetX  柱形图滑动偏移量
   * @param visibleIndex 柱形图滑动结束后第一条数据的下标值
   * @param oneGridWidth   柱形图单个显示区域的宽度
   */
  calculateLastVirtualNodeWidth(offsetX: number, visibleIndex: number, oneGridWidth: number): number {
    if (offsetX === 0 && visibleIndex !== 0) {
      return oneGridWidth;
    }
    if (offsetX !== 0) { // 未整除的情况下，柱形图单个显示区域的宽度和偏移量都是float需要考虑偏差
      if (offsetX < 1) {
        return oneGridWidth;
      } else if (Math.abs(oneGridWidth - offsetX) < 1) {
        return oneGridWidth;
      }
    }
    return offsetX;
  }

  handleChartOffsetForAccessibility() {
    if (this.model && this.isOpenAccessibility) {
      let listener = this.model.getOnTouchListener() as ChartTouchListener;
      if (listener === null) {
        return;
      }
      let matrix = listener.getMatrix()
      let transX = Math.abs(matrix.getValues()[Matrix.mXTrans]);
      let oneGridWidth = (this.model.getWidth() - this.edgeSize.left - this.edgeSize.right) / BAR_COUNT;
      let offsetX = transX % oneGridWidth;
      let visibleIndex = Math.floor(this.model.getLowestVisibleX());
      let lastNodeWidth = this.calculateLastVirtualNodeWidth(offsetX, visibleIndex, oneGridWidth);
      LogUtil.log(TAG,
        `handleChartOffsetForAccessibility index: ${visibleIndex}, width = ${offsetX}, nodeWidth = ${lastNodeWidth}`)
      this.edgeSize.lastNodeWidth = lastNodeWidth;
      this.edgeSize.firstNodeWidth = this.edgeSize.nodeWidth - this.edgeSize.lastNodeWidth;
      AccessibilityTextHandler.updateAccessibilityText({
        visibleIndex: visibleIndex,
        chartStr: this.chartStr,
        chartDate: this.chartDate,
        dataValues: this.dataValues,
        isHourDuration: this.durationChoice === DUARTION_DAY_30 ? false : true
      })
    }
  }

  onDataValuesChanged() {
    if (this.model) {
      this.model.clear();
      this.updateUnitAndYAxis();
      this.data = this.getNormalData();
      this.model.getAxisRight()?.setLabelCount(5, true);
      this.xAxis?.setAxisMaximum(this.dataValues.length);
      if (this.dataValues.length === DUARTION_HOUR_24) {
        this.xAxis?.setValueFormatter(new XDailyValueFormatter());
      } else {
        this.xAxis?.setValueFormatter(new XMonthValueFormatter());
      }
      this.model.setData(this.data);
      this.model.setVisibleXRangeMaximum(BAR_COUNT);
      this.model.setVisibleXRangeMinimum(BAR_COUNT);
      let currentData = this.dataValues.length;
      this.model.moveViewToX(currentData);
      this.model.notifyDataSetChanged();
      this.model.invalidate();
      LogUtil.info(TAG, 'refresh data ' + this.dataValues);
      this.onInitPopUp();
      this.handleChartOffsetForAccessibility();
    }
  }

  onScrollStatusChanged() {
    if (this.isSingleAppScrolling === true) {
      this.customUiInfo.showUi = false;
    }
  }

  onInitPopUp() {
    let maxIndex = this.dataValues.length - 1;
    let entryData = new BarEntry(maxIndex + 0.5, flowByUnit(this.dataValues[maxIndex][1], this.unit));
    this.calcCustomUiInfo(entryData);
  }

  onColorModeChange() {
    // 监听到深色模式改变时，重新修改坐标轴文本、坐标轴颜色、圆柱体颜色之后刷新柱形图
    this.xAxis?.setTextColor(getChartColor(ChartColorCategory.CATEGORY_CHARTTEXT));
    this.xAxis?.setGridColor(getChartColor(ChartColorCategory.CATEGORY_GRID));
    this.xAxis?.setAxisLineColor(getChartColor(ChartColorCategory.CATEGORY_AXISLINE));
    this.leftAxis?.setAxisLineColor(getChartColor(ChartColorCategory.CATEGORY_AXISLINE));
    this.rightAxis?.setGridColor(getChartColor(ChartColorCategory.CATEGORY_GRID));
    this.rightAxis?.setTextColor(getChartColor(ChartColorCategory.CATEGORY_CHARTTEXT));
    this.rightAxis?.setAxisLineColor(getChartColor(ChartColorCategory.CATEGORY_AXISLINE));
    this.dataSet?.setHighLightColor(getChartColor(ChartColorCategory.CATEGORY_COLUMNCHARTHIGHT));
    this.dataSet?.setColorByColor(getChartColor(ChartColorCategory.CATEGORY_COLUMNCHART));
    this.model?.invalidate();
  }

  refresh() {
    // Step1:必须：初始化图表配置构建类
    this.model = new BarChartModel();
    // Step2:配置图表指定样式，各部件间没有先后之分
    // 为图表添加数据选择的监听器
    this.model.setOnChartValueSelectedListener(this.valueSelectedListener);
    this.model.setOnChartGestureListener(this.chartGestureListener);
    // 设置图表Y轴信息
    this.setYaxis();
    // 设置X轴信息
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.BOTTOM);
      this.xAxis.setCenterAxisLabels(true);
      this.xAxis.setAxisMinimum(0);
      this.xAxis.setGranularity(1);
      this.xAxis.setTextSize(getSystemSize($r('sys.float.ohos_id_text_size_caption')));
      this.xAxis.setTextColor(getChartColor(ChartColorCategory.CATEGORY_CHARTTEXT));
      this.xAxis.setGridLineWidth(0.5);
      this.xAxis.enableGridDashedLine(1, 1, 0);
      this.xAxis.setGridColor(getChartColor(ChartColorCategory.CATEGORY_GRID));
      this.xAxis.setGridAlpha(255);
      this.xAxis.setAxisLineWidth(0.5);
      this.xAxis.setAxisLineColor(Color.Transparent);
    }
    this.model.updatePaintProperty();
    // 生成单一颜色数据
    this.data = this.getNormalData();
    // 将数据与图表配置类绑定
    this.model.setData(this.data);
    // 设置图表最大的X轴显示范围，如不设置，则默认显示全部数据
    this.model.setVisibleXRangeMaximum(BAR_COUNT);
    let handler = this.model.getViewPortHandler();
    this.model.setViewPortOffsets(12, 6.5, 22, 15);
    let getXAxis = this.model.getXAxis() as XAxis;
    let getTransformer = this.model.getTransformer(AxisDependency.RIGHT) as Transformer;
    this.model.setXAxisRenderer(new CustomXAxisRenderer(this.model.getViewPortHandler(), getXAxis, getTransformer));
  }

  // 图表数据初始化
  aboutToAppear() {
    LogUtil.info(TAG, 'about to appear : ' + this.dataValues);
    this.refresh();
  }

  aboutToDisappear(): void {
    LogUtil.info(TAG, 'about to disappear : ' + this.dataValues);
    if (this.timeoutId !== -1) {
      clearTimeout(this.timeoutId);
    }
  }

  // popup构造器定义弹框内容
  @Builder
  popupBuilder() {
    Row() {
      Text(this.getPopText(this.customUiInfo?.data?.getX() as number))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .direction(Direction.Ltr)
    }.height(45).padding({ left: 16, right: 16 })
  }

  @Builder
  customUi() {
    // 是否在图表content内
    if (this.customUiInfo.data) {
      Column() {
      }
      .width(0)
      .height(0)
      .margin({ left: this.customUiInfo.x })
      .bindPopup(this.customUiInfo.showUi, {
        builder: this.popupBuilder,
        offset: {
          y: this.customUiInfo.y
        },
        targetSpace: '8vp',
        enableArrow: true,
        radius: $r('sys.float.corner_radius_level10'),
        onStateChange: (e) => { // 返回当前的气泡状态
          if (!e.isVisible) {
            this.customUiInfo.showUi = false;
          }
        },
        placement: Placement.Top,
        popupColor: $r('sys.color.ohos_id_blur_style_component_ultra_thin_color'),
        mask: false,
        autoCancel: false,
        onWillDismiss: (
          (dismissPopupAction: DismissPopupAction) => {
            if (dismissPopupAction.reason == DismissReason.PRESS_BACK) {
              this.customUiInfo.showUi = false;
              this.onBackPress();
            }
          }
        )
      })
    }
  }

  onBackPress(): boolean | void {
    if (router.getParams()) {
      router.back()
      return true
    }
    if (this.session) {
      this.session.sendData({ 'action': 'pop' });
      return true
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      BarChart({
        model: this.model,
      }).onVisibleAreaChange([0.96, 1.0],
        (isExpanding: boolean, currentRatio: number) => {
          this.isBarChartVisible = (currentRatio >= 0.96);
        })
      // 自定义ui
      if (this.customUiInfo && this.customUiInfo.showUi) {
        this.customUi()
      }
    }
    .accessibilityVirtualNode(chartVirtualNodeBuild({
      chartStr: this.chartStr,
      edgeSize: this.edgeSize,
      nodeId: VIRTUAL_NODEID,
      searchMode: SearchMode.NOT_SEARCHING
    }))
    .width('100%')
    .height('100%')
    .direction(Direction.Ltr)
  }

  public calcCustomUiInfo(entryData: BarEntry) {
    if (this.isOpenAccessibility) {
      return;
    }
    if (!this.isBarChartVisible) {
      this.customUiInfo.showUi = false;
      return;
    }
    if (!this.customUiInfo) {
      return;
    }
    if (!this.model) {
      return;
    }
    if (entryData) {
      const vph = this.model.getViewPortHandler();
      const pos = this.model.getPixelForValues(entryData.getX(), entryData.getY(), AxisDependency.RIGHT);
      const isInbounds = vph.isInBounds(pos.x, pos.y);
      // 距离左侧距离
      const offsetLeft = pos.x - vph.offsetLeft();
      // 距离右侧
      const offsetRight = vph.getChartWidth() - pos.x - vph.offsetRight();
      this.customUiInfo.isInbounds = isInbounds;
      this.customUiInfo.x = pos.x;
      this.customUiInfo.y = pos.y;
      this.customUiInfo.offsetLeft = offsetLeft;
      this.customUiInfo.offsetRight = offsetRight;
      this.customUiInfo.data = entryData;
      if (this.model.getHighestVisibleX() > entryData.getX() && this.model.getLowestVisibleX() < entryData.getX()) {
        this.customUiInfo.showUi = true;
      }
    }
  }

  private getPopText(x: number): string {
    if (!x) {
      return '';
    }
    let indexY = Math.floor(x);
    if (!this.dataValues) {
      return '';
    }
    if (indexY >= this.dataValues.length) {
      return '';
    }
    try {
      let flow = this.dataValues[indexY][1];
      let text = getFlowText(flow);
      return text[0] + ' ' + text[1];
    } catch (e) {
      LogUtil.error(TAG, 'popup get flow error');
      return '';
    }
  }

  private setYaxis() {
    if (!this.model) {
      return;
    }
    this.leftAxis = this.model.getAxisLeft();
    if (this.leftAxis) {
      this.leftAxis.setDrawLabels(false);
      this.leftAxis.setAxisMinimum(0);
      // this replaces setStartAtZero(true)
      this.leftAxis.setLabelCount(5);
      this.leftAxis.setDrawGridLines(false);
      this.leftAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      this.leftAxis.setAxisLineWidth(0.5);
      this.leftAxis.setAxisLineColor(getChartColor(ChartColorCategory.CATEGORY_AXISLINE));
      this.leftAxis.setAxisMaximum(this.maxY);
    }
    this.rightAxis = this.model.getAxisRight();
    if (this.rightAxis) {
      this.rightAxis.setGranularity(1);
      this.rightAxis.setAxisMinimum(0); // this replaces setStartAtZero(true)
      this.rightAxis.setDrawLimitLinesBehindData(false);
      this.rightAxis.setValueFormatter(new ValueFormatter());
      this.rightAxis.setLabelCount(5);
      this.rightAxis.setGridLineWidth(0.5);
      this.rightAxis.setGridColor(getChartColor(ChartColorCategory.CATEGORY_GRID));
      this.rightAxis.setGridAlpha(255);
      this.rightAxis.setTextColor(getChartColor(ChartColorCategory.CATEGORY_CHARTTEXT));
      this.rightAxis.setTextSize(getSystemSize($r('sys.float.ohos_id_text_size_caption')));
      this.rightAxis.setAxisLineWidth(0.5);
      this.rightAxis.setAxisLineColor(getChartColor(ChartColorCategory.CATEGORY_AXISLINE));
      this.rightAxis.setAxisMaximum(this.maxY);
    }
  }

  // 构造数据选择监听器
  private valueSelectedListener: OnChartValueSelectedListener = {
    onValueSelected: (e: BarEntry) => {
      LogUtil.info(TAG, 'valueSelectedListener selected ');
      this.calcCustomUiInfo(e);
    },
    onNothingSelected: () => {
      this.customUiInfo.showUi = false;
      LogUtil.info(TAG, 'not selected ');
    }
  }

  private chartGestureListener: OnChartGestureListener = {
    onChartGestureStart: (isTouchEvent: boolean, me: TouchEvent | GestureEvent,
      lastPerformedGesture: ChartGesture): void => {
      AccessibilityUtils.sendAccessibilityEvent(VIRTUAL_NODEID);
    },
    onChartGestureEnd: (isTouchEvent: boolean, me: TouchEvent | GestureEvent,
      lastPerformedGesture: ChartGesture): void => {
      this.handleChartOffsetForAccessibility();
    },
    onChartSingleTapped: (isTouchEvent: boolean, me: TouchEvent | GestureEvent): void => {
    },
    onChartTranslate: (isTouchEvent: boolean, me: TouchEvent | GestureEvent, dX: number, dY: number): void => {
    },
    onChartMove: (isTouchEvent: boolean, me: TouchEvent | GestureEvent): void => {
      this.customUiInfo.showUi = false;
    },
    // 柱形图左右边距变化,更新虚拟焦点偏移量和宽度
    onChartOffsetChanged: (mViewPortHandler: ViewPortHandler): void => {
      this.edgeSize.top = mViewPortHandler.offsetTop();
      this.edgeSize.left = mViewPortHandler.offsetLeft();
      this.edgeSize.bottom = mViewPortHandler.offsetBottom();
      this.edgeSize.right = mViewPortHandler.offsetRight();
      if (this.model) {
        this.edgeSize.nodeWidth = (this.model.getWidth() - this.edgeSize.left - this.edgeSize.right) / BAR_COUNT;
      }
    }
  }

  private updateUnitAndYAxis() {
    let yAndUnit = getMaxYAndUnit(this.dataValues);
    let maxY = Math.ceil(Number(yAndUnit[0]) / 4) * 4;
    if (maxY !== 0) {
      this.maxY = maxY;
    }
    this.model?.getAxisRight()?.setAxisMaximum(this.maxY);
    this.model?.getAxisLeft()?.setAxisMaximum(this.maxY);
    this.unit = yAndUnit[1];
    LogUtil.info(TAG, 'update unit and max y: ' + this.maxY + ' unit ' + this.unit);
  }

  private getNormalData(): BarData {
    let values: JArrayList<BarEntry> = new JArrayList<BarEntry>();
    try {
      this.dataValues.forEach((value, index) => {
        values.add(new BarEntry(index + 0.5, flowByUnit(value[1], this.unit)));
      })
    } catch (e) {
      LogUtil.error(TAG, 'data value error' + e);
    }
    let dataSetList: JArrayList<IDataSet> = new JArrayList<IDataSet>();
    this.dataSet = new BarDataSet(values, 'DataSet');
    if (this.dataSet) {
      this.dataSet.setHighLightColor(getChartColor(ChartColorCategory.CATEGORY_COLUMNCHARTHIGHT));
      this.dataSet.setDrawValues(false);
      // 为柱体添加颜色信息
      this.dataSet.setColorByColor(getChartColor(ChartColorCategory.CATEGORY_COLUMNCHART));
      this.dataSet.setHighlightEnabled(true);
      this.dataSet.setAxisDependency(AxisDependency.RIGHT);
      dataSetList.add(this.dataSet);
    }
    let barData: BarData = new BarData(dataSetList);
    //设置柱状图宽度
    if (this.model?.getWidth()) {
      const oneGridWidth = this.model?.getWidth() / BAR_COUNT;
      this.edgeSize.nodeWidth = oneGridWidth;
      const barWidth = 8.0;
      barData.setBarWidth(barWidth / oneGridWidth);
    }
    //设置顶部圆角半径
    barData.setValueTextSize(12);
    barData.setHighlightEnabled(true);
    return barData;
  }
}

export class ChartDataManagement {
  getDateOrHours(date: Date, durationChoice: number) {
    if (durationChoice === DUARTION_DAY_30) {
      return date.getDate();
    }
    return date.getHours();
  }

  async getMonthOrDailyData(bundleName: string, uid: number, slotId: number, networkType: number,
    durationChoice: number, requestTimes: number): Promise<MonthOrDailyDataResult> {
    let today = new Date();
    let year = today.getFullYear();
    let month = today.getMonth();
    let first = durationChoice === DUARTION_DAY_30 ? new Date(year, month, today.getDate() - 29) :
      new Date(year, month, today.getDate(), today.getHours() - 23);
    let datesList: number[][] = [];
    let chartDate: number[] = [];
    for (let date = first; date <= today;
      durationChoice === DUARTION_DAY_30 ? date.setDate(date.getDate() + 1) : date.setHours(date.getHours() + 1)) {
      let start = new Date(date);
      let end = new Date(date);
      durationChoice === DUARTION_DAY_30 ? end.setDate(date.getDate() + 1) : end.setHours(end.getHours() + 1);
      let x = this.getDateOrHours(start, durationChoice);
      let y =
        await this.getYFlowBar(uid, slotId, networkType, Math.floor(start.getTime() / 1000),
          Math.floor(end.getTime() / 1000));
      if (bundleName === DROI_BUNDLE_NAME || bundleName === DROI_OLD_BUNDLE_NAME) {
        y += await this.getYFlowBar(DROI_UID, slotId, networkType, Math.floor(start.getTime() / 1000),
          Math.floor(end.getTime() / 1000));
      } else if (bundleName === ABROAD_BUNDLE_NAME || bundleName === ABROAD_OLD_BUNDLE_NAME) {
        y += await this.getYFlowBar(ABROAD_TOTAL_UID, slotId, networkType, Math.floor(start.getTime() / 1000),
          Math.floor(end.getTime() / 1000));
      }
      chartDate.push(start.getTime());
      datesList.push([x, y]);
    }
    return {
      networkType: networkType,
      requestTimes: requestTimes,
      datesList: datesList,
      chartDate: chartDate
    };
  }

  async getYFlowBar(uid: number, slotId: number, networkType: number, startTime: number, endTime: number) {
    let simId = 0;
    if (networkType === 0) {
      await sim.getSimAccountInfo(slotId).then(accountInfo => {
        simId = accountInfo.simId;
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG, `get sim id failed, promise: err->${JSON.stringify(err)}`);
      })
    }
    let network: statistics.NetworkInfo = {
      type: networkType,
      startTime: startTime,
      endTime: endTime,
      simId: simId,
    };
    let yValue = 0;
    try {
      let data = await statistics.getTrafficStatsByUidNetwork(uid, network);
      data.forEach(value => {
        yValue += value.info.txBytes;
        yValue += value.info.rxBytes;
      })
    } catch (err) {
      LogUtil.error(TAG, `get app traffic bar failed error code: ${err?.code}, error message: ${err?.message}`);
    }
    return yValue;
  }
}

export interface MonthOrDailyDataResult {
  networkType: number;
  requestTimes: number;
  datesList: number[][];
  chartDate: number[];
}

function getMaxYAndUnit(data: number[][]) {
  if (!data) {
    return 'B';
  }
  let maxY = 0;
  data.forEach(value => {
    if (!value || value.length < 2) {
      return;
    }
    if (value[1] > maxY) {
      maxY = value[1];
    }
  })
  return getFlowText(maxY);
}

function flowByUnit(value: number, unit: string) {
  switch (unit) {
    case 'B':
      return value;
    case 'KB':
      return value / 1024;
    case 'MB':
      return value / Math.pow(1024, 2);
    case 'GB':
      return value / Math.pow(1024, 3);
    case 'TB':
      return value / Math.pow(1024, 4);
    default:
      return value;
  }
}

export class ValueFormatter implements IAxisValueFormatter {
  getFormattedValue(value: number): string {
    return Math.round(value).toString();
  }
}

class XMonthValueFormatter implements IAxisValueFormatter {
  getFormattedValue(index: number): string {
    let currentDate = new Date();
    currentDate.setDate(currentDate.getDate() - 29 + index);
    let value = currentDate.getDate();
    return Math.round(value).toString();
  }
}

class XDailyValueFormatter implements IAxisValueFormatter {
  getFormattedValue(index: number): string {
    let currentDate = new Date();
    currentDate.setHours(currentDate.getHours() - 23 + index);
    let value = currentDate.getHours();
    return Math.round(value).toString();
  }
}

function getSystemSize(sizeResource: Resource) {
  let size = 12;
  try {
    size = resourceManager.getSystemResourceManager().getNumber(sizeResource);
  } catch (error) {
    let code = (error as BusinessError).code;
    let message = (error as BusinessError).message;
    LogUtil.error(TAG, `get number failed, error code: ${code}, message: ${message}.`);
  }
  return size;
}

export class CustomXAxisRenderer extends XAxisRenderer {
  private firstIn24 = 4;
  private firstIn30 = 4;
  private count24 = 0;
  private count30 = 0;

  constructor(viewPortHandler: ViewPortHandler, xAxis: XAxis, trans?: Transformer) {
    super(viewPortHandler, xAxis, trans);
  }

  public renderGridLines(c: CanvasRenderingContext2D): void {
    if (!this.axis || !this.xAxis || !this.xAxis.isDrawGridLinesEnabled()) {
      return;
    }
    c.save();
    c.beginPath();
    let clippingRect = this.getGridClippingRect();
    c.rect(clippingRect.left, clippingRect.top, clippingRect.width(), clippingRect.height());
    c.closePath();
    c.clip();

    if (this.renderGridLinesBuffer.length != this.axis.entryCount * 2) {
      this.renderGridLinesBuffer = new Array<number>(this.xAxis.entryCount * 2);
    }
    let positions: number[] = this.renderGridLinesBuffer;
    for (let i = 0; i < positions.length; i += 2) {
      positions[i] = this.xAxis.entries[i / 2];
      positions[i + 1] = this.xAxis.entries[i / 2];
    }
    if (this.trans) {
      this.trans.pointValuesToPixel(positions);
    }

    this.setupGridPaint();
    LogUtil.debug(TAG, 'position length' + positions.length + this.xAxis.axisMaximum);
    if (this.xAxis.axisMaximum === 31) {
      this.draw30(c, positions);
    } else {
      this.draw24(c, positions);
    }
    c.restore();
  }

  public draw30(c: CanvasRenderingContext2D, positions: number[]) {
    for (let i = this.firstIn30; i < positions.length - this.firstIn30; i += 2) {
      this.drawGridLine(c, positions[i], positions[i + 1]);
    }
    this.count30 += 1;
    if (this.count30 >= 3) {
      this.firstIn30 = 2;
    }
    this.resetFirstIn24();
  }

  public draw24(c: CanvasRenderingContext2D, positions: number[]) {
    for (let i = this.firstIn24; i < positions.length - this.firstIn24; i += 2) {
      this.drawGridLine(c, positions[i], positions[i + 1]);
    }
    this.count24 += 1;
    if (this.count24 >= 3) {
      this.firstIn24 = 2;
    }
    this.resetFirstIn30();
  }

  private resetFirstIn24() {
    this.firstIn24 = 4;
    this.count24 = 0;
  }

  private resetFirstIn30() {
    this.firstIn30 = 4;
    this.count30 = 0;
  }
}
