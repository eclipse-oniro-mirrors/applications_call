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
  XAxis,
  XAxisPosition,
  YAxis,
  YAxisLabelPosition,
  ChartTouchListener,
  ViewPortHandler,
  Matrix,
  AccessibilityTextHandler
} from '../feature/mpchart';
import { BusinessError } from '@ohos.base';
import { statistics } from '@kit.NetworkKit';
import { sim } from '@kit.TelephonyKit';
import {
  ABROAD_BUNDLE_NAME,
  ABROAD_OLD_BUNDLE_NAME,
  ABROAD_TOTAL_UID,
  BAR_COUNT,
  DROI_BUNDLE_NAME,
  DROI_OLD_BUNDLE_NAME,
  DROI_UID,
  EMITTER_NOTICE_EVENT_ID,
  EMITTER_ON_FORGROUND_EVENT_ID,
  EMITTER_PRELOAD_CALLBACK_EVENT_ID,
  EMITTER_PRELOAD_TOTAL_CALLBACK_EVENT_ID,
  getFlowText,
  isRTL,
  SearchMode,
  SlotId,
  SlotIdMapSimIdInterface,
  TRAFFIC_CONTROL_PAGE_VISIBLE_STATUS
} from '../constants/CommonConstants';
import resourceManager from '@ohos.resourceManager';
import { LogUtil } from '../util/LogUtil';
import { ConfigurationConstant, UIExtensionContentSession } from '@kit.AbilityKit';
import { ChartColorCategory, getChartColor } from '../util/ChartColorModeUtil';
import { CustomXAxisRenderer, ValueFormatter } from './ChartComponent';
import {
  AllPackageUsageInterface,
  LIMIT_TRAFFIC_NOSET,
  PackageConfigurationInterface,
  PackageUsageStatus,
  START_DATE_NOSET,
  TrafficCommondInterface,
  TrafficDataCacheUtil,
  TrafficPackageUtil
} from '../util/TrafficPackageUtil';
import { FontScaleState } from '../util/fontScaleState';
import StringUtil from '../util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import { display, LengthMetrics, router } from '@kit.ArkUI';

import TrafficPackagePresenter from '../presenter/TrafficPackagePresenter';
import { emitter } from '@kit.BasicServicesKit';
import DotUtil from '../util/Dot/DotUtils';
import { TrafficDataStroageUtil } from '../util/TrafficPackagePreloadUtil';
import PageViewModel from '../viewmodel/PageViewModel';
import { HashMap, JSON } from '@kit.ArkTS';
import { chartVirtualNodeBuild, ChartSizeInterface } from './ChartVirtualNodeComponent';
import { AccessibilityUtils, ISOPENACCESSIBILITY } from '../util/AccessibilityUtils';
import Utils from '../feature/mpchart/utils/Utils';

const TAG: string = 'TrafficDetailPageComponent';
const VIRTUAL_NODEID: string = 'trafficVirtualNode';

@Component
export struct TrafficDetailPageComponent {
  @Consume @Watch('onSegmentButtonIndexChanged') simSelectedIndexes: number[];
  @Provide trafficChartDate: number[] = [0, 0, 0, 0, 0, 0, 0, 0];
  @Provide dataValues: number[][] = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0]];
  @Provide startDate: number | undefined = undefined;
  @State flowText: string[] = ['0', 'B']
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State packageUsageStatus: PackageUsageStatus = PackageUsageStatus.PACKNONE;
  private isAddTotalUseObserver: boolean = false;
  private isAddUseDetailObserver: boolean = false;
  private requestTimes: number = 0;
  private flow: number = 0;
  @Provide isShowTotalFlow: boolean = false;
  private callback: () => void = () => {};
  @Consume @Watch('exitTrafficEvent') isExitTraffic: boolean;

  aboutToAppear(): void {
    LogUtil.info(TAG, 'about to appear');
    emitter.on({
      eventId: EMITTER_ON_FORGROUND_EVENT_ID,
      priority: emitter.EventPriority.HIGH
    }, () => {
      this.refreshChartData();
    })
    emitter.on({
      eventId: EMITTER_NOTICE_EVENT_ID,
      priority: emitter.EventPriority.HIGH
    }, (data: emitter.EventData) => {
      this.parseParams(data?.data?.params as SlotIdMapSimIdInterface);
    })
    if (TrafficDataStroageUtil.getInstance().isNeedPreload) {
      LogUtil.info(TAG, 'needPreload')
      this.preloadData();
    } else {
      LogUtil.info(TAG, 'getTrafficPackageUseData')
      this.getTrafficPackageUseData();
    }
  }

  preloadData() {
    TrafficDataStroageUtil.getInstance().isNeedPreload = false;
    let trafficTotalUse = TrafficDataStroageUtil.getInstance().getTrafficeTotalUseDetail();
    let trafficeUseDetail = TrafficDataStroageUtil.getInstance().getTrafficeUseDetail();
    if (trafficTotalUse) {
      this.updatePackageUsageStatus(trafficTotalUse.config, trafficTotalUse.usageInfo.totalFlow);
    } else {
      this.isAddTotalUseObserver = true;
      LogUtil.info(TAG, `add total detail observer`);
      emitter.on({
        eventId: EMITTER_PRELOAD_TOTAL_CALLBACK_EVENT_ID,
        priority: emitter.EventPriority.HIGH
      }, (data: emitter.EventData) => {
        this.handleTrafficTotalUseData(data.data as TrafficCommondInterface);
      })
    }
    if (trafficeUseDetail) {
      this.handleChartData(trafficeUseDetail);
    } else {
      this.isAddUseDetailObserver = true;
      LogUtil.info(TAG, `add use detail observer`);
      emitter.on({
        eventId: EMITTER_PRELOAD_CALLBACK_EVENT_ID,
        priority: emitter.EventPriority.HIGH
      }, (data: emitter.EventData) => {
        this.handleTrafficUseDetailData(data.data as TrafficCommondInterface);
      })
    }
  }

  handleTrafficUseDetailData(trafficeUseDetail: TrafficCommondInterface | undefined) {
    if (trafficeUseDetail) {
      this.handleChartData(trafficeUseDetail);
    }
  }

  handleTrafficTotalUseData(trafficTotalUse: TrafficCommondInterface | undefined) {
    if (trafficTotalUse) {
      this.updatePackageUsageStatus(trafficTotalUse.config, trafficTotalUse.usageInfo.totalFlow);
    }
  }

  aboutToDisappear(): void {
    LogUtil.info(TAG, 'about to disappear');
  }

  exitTrafficEvent() {
    LogUtil.info(TAG, `exitTrafficEvent`);
    if (this.isExitTraffic) {
      TrafficDataStroageUtil.getInstance().trafficeUseDetail = undefined;
      TrafficDataStroageUtil.getInstance().trafficeTotalUseDetail = undefined;
      TrafficDataStroageUtil.getInstance().isNeedPreload = true;
      emitter.off(EMITTER_NOTICE_EVENT_ID);
      emitter.off(EMITTER_ON_FORGROUND_EVENT_ID);
      if (this.isAddTotalUseObserver) {
        emitter.off(EMITTER_PRELOAD_TOTAL_CALLBACK_EVENT_ID);
      }
      if (this.isAddUseDetailObserver) {
        emitter.off(EMITTER_PRELOAD_CALLBACK_EVENT_ID);
      }
    }
  }

  parseParams(params: SlotIdMapSimIdInterface) {
    let slotId = params.slotId === SlotId.DEFAULT ? this.simSelectedIndexes[0] : params.slotId;
    let simId = params.simId;
    TrafficPackagePresenter.getInstance().clearCacheData(slotId, simId);
    if (slotId === this.simSelectedIndexes[0]) {
      this.getTrafficPackageUseData();
    }
  }

  handleChartData(data?: Object) {
    if (!data) {
      return;
    }
    let reslut = data as TrafficCommondInterface;
    TrafficDataCacheUtil.getInstance().cacheAllUsageInfoData(reslut.usageInfo);
    reslut.usageInfo.usage.sort(PageViewModel.traficeUseCompare);
    this.startDate = reslut.config.monthlyStartDate === START_DATE_NOSET ? undefined : reslut.config.monthlyStartDate;
    let dataValues: number[][] = [];
    let chartDate: number[] = [];
    reslut.usageInfo.usage.forEach((object) => {
      dataValues.push([object.day, object.flow]);
      chartDate.push(object.startDate);
    })
    this.trafficChartDate = chartDate;
    LogUtil.info(TAG, 'refreshData:' + JSON.stringify(dataValues));
    this.dataValues = dataValues;
    this.compareAndCalculateUsedTrafficValue(reslut.config, this.flow);
  }

  refreshChartData() {
    TrafficPackagePresenter.getInstance().clearAllCacheData();
    this.getTrafficPackageUseData();
  }

  getTrafficPackageUseData() {
    let slotId: number = this.simSelectedIndexes[0];
    if (TrafficPackagePresenter.getInstance().isLoadingSlotIdData(slotId)) {
      return;
    }
    LogUtil.info(TAG, 'getTrafficPackageUseData start')
    TrafficPackagePresenter.getInstance().setSlotIdStartLoadingStatus(slotId);
    TrafficPackagePresenter.getInstance().querySimId(slotId, (simId: number) => {
      LogUtil.info(TAG, 'getTrafficPackageUseData querySimId finish')
      TrafficPackagePresenter.getInstance().queryTrafficConfig(simId, (config: PackageConfigurationInterface) => {
        this.startDate = config.monthlyStartDate === START_DATE_NOSET ? undefined : config.monthlyStartDate;
        this.refreshData(slotId, simId, this.startDate);
      });
    });
  }

  onSegmentButtonIndexChanged(): void {
    LogUtil.info(TAG, 'onSegmentButtonIndexChanged: ' + `slotId = ${this.simSelectedIndexes[0]}`)
    let slotId: number = this.simSelectedIndexes[0];
    if (TrafficPackagePresenter.getInstance().isLoadingSlotIdData(slotId)) {
      return;
    }
    TrafficPackagePresenter.getInstance().querySimId(slotId, (simId: number) => {
      TrafficPackagePresenter.getInstance().queryTrafficConfig(simId, (config: PackageConfigurationInterface) => {
        this.startDate = config.monthlyStartDate === START_DATE_NOSET ? undefined : config.monthlyStartDate;
        this.refreshData(slotId, simId, this.startDate);
      })
    })
  }

  updatePackageUsageStatus(config: PackageConfigurationInterface, totalFlow: number) {
    this.startDate = config.monthlyStartDate === START_DATE_NOSET ? undefined : config.monthlyStartDate;
    if (config.unlimitedTrafficEnable || config.monthlyLimitedTraffic === LIMIT_TRAFFIC_NOSET) {
      this.packageUsageStatus = PackageUsageStatus.PACKNONE;
      this.flowText = getFlowText(totalFlow);
    } else {
      if (config.monthlyLimitedTraffic >= totalFlow) {
        this.packageUsageStatus = PackageUsageStatus.PACKNORMALUSAGE;
        this.flowText = getFlowText(config.monthlyLimitedTraffic - totalFlow);
      } else {
        this.packageUsageStatus = PackageUsageStatus.PACKOUTLIMIT;
        this.flowText = getFlowText(totalFlow - config.monthlyLimitedTraffic);
      }
    }
    DotUtil.getInstance().reportTotalTrafficDetails(totalFlow, this.startDate, this.packageUsageStatus, this.flowText);
  }

  private compareAndCalculateUsedTrafficValue(config: PackageConfigurationInterface, totalFlow: number) {
    let total: number = 0;
    this.dataValues.forEach((value) => {
      if (!value || value.length < 2) {
        return;
      }
      total += value[1];
    });
    this.flow = totalFlow > total ? totalFlow : total;
    this.updatePackageUsageStatus(config, this.flow);
    this.isShowTotalFlow = true;
  }

  refreshData(slotId: number, simId: number, startDay?: number) {
    TrafficPackageUtil.getTrafficPackageUsageDetails(simId, BAR_COUNT, startDay)
      .then((result: AllPackageUsageInterface) => {
        LogUtil.info(TAG, 'refreshData');
        if (this.simSelectedIndexes[0] !== slotId) {
          return;
        }
        this.refreshUI(result, simId);
        if (!this.isShowTotalFlow) {
          this.isShowTotalFlow = true;
        }
        TrafficPackagePresenter.getInstance().setSlotIdFinishLoadingStatus(slotId);
      })
  }

  refreshUI(packageUseDetail: AllPackageUsageInterface, simId: number) {
    let dataValues: number[][] = [];
    let chartDate: number[] = [];
    packageUseDetail.usage.forEach((object) => {
      dataValues.push([object.day, object.flow]);
      chartDate.push(object.startDate);
    })
    LogUtil.info(TAG, 'refreshData:' + JSON.stringify(dataValues));
    let totalFlow = packageUseDetail.totalFlow;
    TrafficPackagePresenter.getInstance().queryTrafficConfig(simId, (config: PackageConfigurationInterface) => {
      this.updatePackageUsageStatus(config, totalFlow);
    });
    this.trafficChartDate = chartDate;
    this.dataValues = dataValues;
  }

  @Builder
  flowAreaDetailInfo() {
    Column() {
      Column() {
        Row() {
          Text(this.flowText[0])
            .fontFamily('HarmonyHeiTi')
            .fontSize('30fp')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .constraintSize({ maxWidth: '80%' })
            .maxFontScale(1.75)
          Text(this.flowText[1])
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ left: 2, bottom: 5 });
        }
        .direction(Direction.Ltr)
        .alignItems(VerticalAlign.Bottom);
      }
      .margin({ top: '8vp', start: LengthMetrics.vp(4) })
      .constraintSize({ minHeight: '40vp' })
      .justifyContent(FlexAlign.Center)

      Text(this.fetchUseTrafficTitle(this.packageUsageStatus))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .margin({ bottom: 8, start: LengthMetrics.vp(4) })
    }
    .alignItems(HorizontalAlign.Start)
    .accessibilityGroup(true)
    .accessibilityText(StringUtil.convertResourceToString(this.fetchUseTrafficTitle(this.packageUsageStatus),
      getContext(this) as myCommon.UIAbilityContext) + ' ' + (this.flowText[0] + ' ' + this.flowText[1]))
    .padding({ left: 8, right: 8 })
    .visibility(this.isShowTotalFlow ? Visibility.Visible : Visibility.Hidden)
  }

  build() {
    Column() {
      this.flowAreaDetailInfo();
      TrafficChartComponent({ callback: this.callback })
        .height(172)
        .margin({ bottom: 16, right: 12 })
      Row() {
        Text($r('app.string.data_calculation_different_from_shown'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'));
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 12 })
      .padding({ left: 12, right: 12 })
    }
    .alignItems(HorizontalAlign.Start)
  }

  fetchUseTrafficTitle(packageUsageStatus: PackageUsageStatus): Resource {
    let title: Resource = $r('app.string.used_traffice');
    switch (packageUsageStatus) {
      case PackageUsageStatus.PACKNORMALUSAGE:
        title = $r('app.string.traffice_package_remain');
        break;
      case PackageUsageStatus.PACKOUTLIMIT:
        title = $r('app.string.traffice_package_out');
        break;
      case PackageUsageStatus.PACKNONE:
      default:
        title = $r('app.string.used_traffice');
        break;
    }
    return title;
  }
}

@Component
struct TrafficChartComponent {
  @Consume trafficChartDate: number[];
  @Consume @Watch('onDataValuesOrAreaSizeChanged') dataValues: number[][];
  @State model: BarChartModel | undefined = undefined;
  @State @Watch('onMaxYValueChanged') maxY: number = 4;
  @State customUiInfo: CustomUiInfo = new CustomUiInfo(90, 50);
  @StorageProp('currentColorMode') @Watch('onColorModeChange') currentColorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Consume startDate?: number;
  private rightAxis: YAxis | null = null;
  private leftAxis: YAxis | null = null;
  private xAxis: XAxis | null = null;
  private data: BarData | null = null;
  private unit: string = 'B';
  private dataSet: BarDataSet | null = null;
  private currentDateIndex: number = -1;
  @StorageProp(TRAFFIC_CONTROL_PAGE_VISIBLE_STATUS) @Watch('onVisibleStatusChange') visibleStatus: boolean = false;
  @Consume @Watch('onScrollStatusChanged') isScrolling: boolean;
  @Consume @Watch('onSearchModeChanged') searchMode: number;
  @Consume session: UIExtensionContentSession;
  @Consume isDismissWhenClickAppListItem: boolean
  private isBarChartVisible = true;
  private barChartWidthUpdated: boolean = false;
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
  private callback: () => void = () => {};
  private timeoutId: number = -1;
  private textSizeCache = new HashMap<string, TextMetrics>();
  @Consume isExitTraffic: boolean;

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
      this.model.setViewPortOffsets(12, 6.5, viewPortRightOffset, isRTL() ? 20 : 15);
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

  handleChartOffsetForAccessibility() {
    if (this.model && this.isOpenAccessibility) {
      let listener = this.model.getOnTouchListener();
      if (listener === null) {
        return;
      }
      let matrix = listener.getMatrix()
      let transX = Math.abs(matrix.getValues()[Matrix.mXTrans]);
      let oneGridWidth = (this.model.getWidth() - this.edgeSize.left - this.edgeSize.right) / BAR_COUNT;
      let width = transX % oneGridWidth;
      let visibleIndex = Math.floor(this.model.getLowestVisibleX());
      let nodeWidth = width;
      if (width !== 0) { // 未整除的情况下，柱形图单个数据的宽度和偏移量都是float需要考虑偏差
        if (width < 1) {
          nodeWidth = oneGridWidth;
        } else if (Math.abs(oneGridWidth - width) < 1) {
          nodeWidth = oneGridWidth;
        }
      } else {
        if (visibleIndex !== 0) {
          nodeWidth = oneGridWidth;
        }
      }
      LogUtil.info(TAG, `handleChartOffsetForAccessibility  index: ${visibleIndex}, width = ${width}, nodeWidth = ${nodeWidth}`)
      this.edgeSize.lastNodeWidth = nodeWidth;
      this.edgeSize.firstNodeWidth = this.edgeSize.nodeWidth - this.edgeSize.lastNodeWidth;
      AccessibilityTextHandler.updateAccessibilityText({
        visibleIndex: visibleIndex,
        chartStr: this.chartStr,
        chartDate: this.trafficChartDate,
        dataValues: this.dataValues,
        isHourDuration: false
      })
    }
  }

  onSearchModeChanged() {
    if (this.searchMode === SearchMode.NOT_SEARCHING && this.isBarChartVisible) {
      this.onInitPopUp();
    } else {
      this.customUiInfo.showUi = false;
    }
  }

  onScrollStatusChanged() {
    if (this.isScrolling) {
      this.customUiInfo.showUi = false;
    } else if (this.isBarChartVisible) {
      this.onInitPopUp();
    }
  }

  onVisibleStatusChange() {
    if (this.visibleStatus === true && this.currentDateIndex !== -1 && this.isBarChartVisible) {
      this.onInitPopUp();
    } else {
      this.customUiInfo.showUi = false;
    }
  }

  onDataValuesOrAreaSizeChanged() {
    if (this.model) {
      this.model.clear();
      this.updateUnitAndYAxis();
      this.data = this.getNormalData();
      this.model.getAxisRight()?.setLabelCount(5, true);
      this.xAxis?.setAxisMaximum(this.dataValues.length);
      this.model.setData(this.data);
      this.model.setVisibleXRangeMaximum(BAR_COUNT);
      this.model.setVisibleXRangeMinimum(BAR_COUNT);
      let format = new XCurrentMonthValueFormatter();
      let yLabels = TrafficPackageUtil.getAllTrafficYLabels(BAR_COUNT, this.startDate);
      let currentDateStr = new Date().getDate().toString();
      for (let index = 0; index < yLabels.length; index++) {
        if (currentDateStr === yLabels[index] ||
          yLabels[index] === StringUtil.convertResourceToString($r('app.string.today'),
            getContext() as myCommon.UIAbilityContext)) {
          this.currentDateIndex = index;
          break;
        }
      }
      format.setYlabels(yLabels);
      this.xAxis?.setValueFormatter(format);
      let currentData = this.dataValues.length;
      this.model.moveViewToX(currentData);
      this.model.notifyDataSetChanged();
      this.model.invalidate();
      this.onInitPopUp();
      LogUtil.info(TAG, 'refresh data ' + this.dataValues);
      this.handleChartOffsetForAccessibility();
    }
  }

  onInitPopUp() {
    if (this.searchMode !== SearchMode.NOT_SEARCHING) {
      return;
    }
    if (this.currentDateIndex === -1 || this.currentDateIndex >= this.dataValues.length ||
      this.visibleStatus === false) {
      return;
    }
    LogUtil.info(TAG, `onInitPopUp currentIndex = ${this.currentDateIndex}`);
    let entryData =
      new BarEntry(this.currentDateIndex + 0.5, flowByUnit(this.dataValues[this.currentDateIndex][1], this.unit));
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
    this.model.setViewPortOffsets(12, 6.5, 22, isRTL() ? 20 : 15);
    let getXAxis = this.model.getXAxis() as XAxis;
    let getTransformer = this.model.getTransformer(AxisDependency.RIGHT) as Transformer;
    this.model.setXAxisRenderer(new CustomXAxisRenderer(this.model.getViewPortHandler(), getXAxis, getTransformer));
  }

  // 图表数据初始化
  aboutToAppear() {
    LogUtil.info(TAG, 'about to appear');
    this.refresh();
  }

  aboutToDisappear(): void {
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
        onWillDismiss: ((dismissPopupAction: DismissPopupAction) => {
          if (dismissPopupAction.reason == DismissReason.PRESS_BACK) {
            this.customUiInfo.showUi = false;
            if (!this.isDismissWhenClickAppListItem) {
              this.callback();
              this.onBackPress();
            }
          }
          this.isDismissWhenClickAppListItem = false;
        })
      })
    }
  }

  onBackPress(): boolean | void {
    this.isExitTraffic = true;
    if (router.getParams()) {
      router.back()
      return true;
    }
    if (this.session) {
      this.session.sendData({ 'action': 'pop' });
      return true;
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      BarChart({
        model: this.model,
      }).onVisibleAreaChange([0.96, 1.0],
        (isExpanding: boolean, currentRatio: number) => {
          this.isBarChartVisible = (currentRatio >= 0.96);
          this.onVisibleStatusChange();
          if (currentRatio === 1) {
            if (!this.barChartWidthUpdated) {
              this.onDataValuesOrAreaSizeChanged();
              this.barChartWidthUpdated = true;
            }
          }
        })
        .onAreaChange((oldValue: Area, newValue: Area) => {
          if (oldValue.width === newValue.width && oldValue.height === oldValue.height) {
            return;
          }
          LogUtil.info(TAG, `onAreaChange change, oldValue: ${JSON.stringify(oldValue)}, newValue: ${JSON.stringify(newValue)}`)
          this.onDataValuesOrAreaSizeChanged();
        })
      if (this.customUiInfo && this.customUiInfo.showUi) {
        this.customUi()
      }
    }
    .width('100%')
    .height('100%')
    .direction(Direction.Ltr)
    .accessibilityVirtualNode(chartVirtualNodeBuild({
      chartStr: this.chartStr,
      edgeSize: this.edgeSize,
      nodeId: VIRTUAL_NODEID,
      searchMode: this.searchMode
    }))
  }

  public calcCustomUiInfo(entryData: BarEntry) {
    // 无障碍模式下展示气泡会影响焦点的切换
    if (this.isOpenAccessibility) {
      return;
    }
    if (!this.isBarChartVisible) {
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
      let roundX = Number(entryData.getX().toFixed(2));
      let roundY = Number(entryData.getY().toFixed(2));
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
    if (x < 0) {
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
      this.leftAxis.setAxisMinimum(0); // this replaces setStartAtZero(true)
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
      this.currentDateIndex = Math.floor(e.getX());
      this.calcCustomUiInfo(e);
    },
    onNothingSelected: () => {
      this.customUiInfo.showUi = false;
      LogUtil.info(TAG, 'not selected ');
    }
  }
  private chartGestureListener: OnChartGestureListener = {
    onChartGestureStart: (): void => {
      AccessibilityUtils.sendAccessibilityEvent(VIRTUAL_NODEID);
    },
    onChartGestureEnd: (): void => {
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
    if (durationChoice === 30) {
      return date.getDate();
    }
    return date.getHours();
  }

  async getMonthOrDailyData(bundleName: string, uid: number, slotId: number, networkType: number,
    durationChoice: number) {
    let today = new Date();
    let year = today.getFullYear();
    let month = today.getMonth();
    let first = durationChoice === 30 ? new Date(year, month, today.getDate() - 29) :
      new Date(year, month, today.getDate(), today.getHours() - 23);
    let datesList: number[][] = [];
    for (let date = first; date <= today;
      durationChoice === 30 ? date.setDate(date.getDate() + 1) : date.setHours(date.getHours() + 1)) {
      let start = new Date(date);
      let end = new Date(date);
      durationChoice === 30 ? end.setDate(date.getDate() + 1) : end.setHours(end.getHours() + 1);
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
      datesList.push([x, y]);
    }
    return datesList;
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

class XCurrentMonthValueFormatter implements IAxisValueFormatter {
  private yLabels: string[] = [];

  setYlabels(yLabels: string[]): void {
    this.yLabels = yLabels;
  }

  getFormattedValue(index: number): string {
    if (index < this.yLabels.length) {
      return this.yLabels[index];
    } else {
      return Math.round(index).toString();
    }
  }
}

