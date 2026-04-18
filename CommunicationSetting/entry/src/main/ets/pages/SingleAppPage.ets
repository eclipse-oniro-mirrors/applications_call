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
import router from '@ohos.router';
import { AppInfo } from '../viewmodel/AppInfo';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { BusinessError } from '@ohos.base';
import {
  ItemRestriction,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem
} from '@ohos.arkui.advanced.SegmentButton';
import pageViewModel from '../viewmodel/PageViewModel';
import {
  UNKNOWN_BUNDLE_TYPE,
  ORI_APP_INDEX,
  getFlowText,
  DEFAULT_USERID,
  DUARTION_DAY_30
} from '../constants/CommonConstants';
import policy from '@ohos.net.policy';
import data from '@ohos.telephony.data';
import AppInfoListPresenter from '../presenter/AppInfoListPresenter';
import StringUtil from '../util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import { isTablet } from '../util/DeviceUtil';
import { LogUtil } from '../util/LogUtil';
import { FontScaleState } from '../util/fontScaleState';
import { LengthMetrics } from '@kit.ArkUI';
import { ChartComponent, ChartDataManagement, MonthOrDailyDataResult } from '../pagesComponents/ChartComponent';
import bundleManager from '@ohos.bundle.bundleManager';
import { JSON } from '@kit.ArkTS';
import { ToggleState } from '../util/Dot/DotCommon';
import DotUtil from '../util/Dot/DotUtils';
import { CustomUiInfo } from '../feature/mpchart';
// import { HdsNavigation, HdsNavigationAttribute, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { TitleParams } from '../view/TitleParams';

const NAVI_INDICATOR_HEIGHT = 0;
const TAG = 'SingleAppPage'
const DURATION_CHOICE = [DUARTION_DAY_30, 1]
const MOBILE_SELECTED_TEXT = [$r('app.string.last_30_days', '30'), $r('app.string.last_24_hours', '24')]
const WLAN_SELECTED_TEXT = [$r('app.string.last_30_days', '30'), $r('app.string.last_24_hours', '24')]

@Entry
@Component
struct SingleAppPage {
  @Provide appInfo: AppInfo = new AppInfo('', -1, 0, 0);
  @Provide chartDate: number[] = [0, 0, 0, 0, 0, 0, 0];
  @Provide dataValues: number[][] = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0]];
  private mobileDataValues?: number[][];
  private wifiDataValues?: number[][];
  private mobileChartDate?: number[];
  private wifiChartDate?: number[];
  private scroller: Scroller = new Scroller;
  public storage = LocalStorage.getShared();
  @State @Watch('onSegmentButtonIndexChanged') selectedIndexes: number[] =
    [AppStorage.get<boolean>('showNetworkChoice') ? 0 : 1]
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @StorageProp('naviIndicatorHeight') naviIndicatorHeight: number = NAVI_INDICATOR_HEIGHT;
  // SegmentButton适老化需求需要限制放大两倍高度
  @State singleAppTabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: $r('app.string.mobile_data') }, {
      text: $r('app.string.wlan')
    }] as ItemRestriction<SegmentButtonTextItem>,
    selectedFontSize: FontScaleState.isSmallerSixGear(this.fontSizeScale) ?
    $r('sys.float.ohos_id_text_size_button2') : '28vp',
    selectedFontColor: $r('sys.color.ohos_id_color_text_primary'),
    selectedBackgroundColor: $r('sys.color.ohos_id_color_foreground_contrary_disable'),
    textPadding: {
      top: FontScaleState.isStandardGear(this.fontSizeScale) ? 0 : 1.5 * Math.min(FontScaleState.fontScale, 2),
      bottom: FontScaleState.isStandardGear(this.fontSizeScale) ? 0 : 1.5 * Math.min(FontScaleState.fontScale, 2)
    },
    buttonPadding: {
      top: FontScaleState.isStandardGear(this.fontSizeScale) ? 10 : 8,
      bottom: FontScaleState.isStandardGear(this.fontSizeScale) ? 10 : 8,
      right: FontScaleState.isStandardGear(this.fontSizeScale) ? 8 : 16,
      left: FontScaleState.isStandardGear(this.fontSizeScale) ? 8 : 16
    },
    fontSize: FontScaleState.isSmallerSixGear(this.fontSizeScale) ? $r('sys.float.ohos_id_text_size_button2') : '28vp',
    fontColor: $r('sys.color.ohos_id_color_text_secondary'),
    backgroundColor: $r('sys.color.ohos_id_color_button_normal'),
    fontWeight: FontWeight.Medium
  })
  @State mobileSelectedText: Resource = MOBILE_SELECTED_TEXT[0]
  @State wlanSelectedText: Resource = WLAN_SELECTED_TEXT[0]
  @State flow: number = 0
  @State flowText: string[] = ['0', 'B']
  @State mPresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
  @State is30: Boolean = true;
  @State mobileDuration: number = DURATION_CHOICE[0]
  @State wlanDuration: number = DURATION_CHOICE[0]
  @Provide durationChoice: number = DURATION_CHOICE[0];
  @State allowRefresh: boolean = false;
  @State showConnectionPart: boolean = false;
  @State isHover: boolean = false;
  @Provide isSingleAppScrolling: boolean = false;
  private slotId: number = data.getDefaultCellularDataSlotIdSync()
  @Provide session: UIExtensionContentSession = this.storage?.
  get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  private requestTimes = 0;
  @Provide isShowTotalFlow: boolean = false;
  @Provide customUiInfo: CustomUiInfo = new CustomUiInfo(90, 50);
  @StorageProp('userID') userID: number = DEFAULT_USERID;

  refresh(): void {
    if (this.appInfo.isHotSpot()) {
      this.showConnectionPart = true;
    } else {
      policy.getNetworkAccessPolicy(this.appInfo.uid)
        .then((data: policy.NetworkAccessPolicy) => {
          this.appInfo.wifiAccess = data.allowWiFi as boolean;
          this.appInfo.mobileAccess = data.allowCellular as boolean;
          this.appInfo.wlanPolicyApp = false;
          this.appInfo.mobilePolicyApp = false;
          if (data.alwaysAllowWiFi !== undefined) {
            this.appInfo.wlanPolicyApp = data.alwaysAllowWiFi as boolean;
          }
          if (data.alwaysAllowCellular !== undefined) {
            this.appInfo.mobilePolicyApp = data.alwaysAllowCellular as boolean;
          }
          let anomalousPolicy: number = 0;
          if (this.appInfo.wlanPolicyApp && !this.appInfo.wifiAccess) {
            this.appInfo.wifiAccess = true;
            anomalousPolicy += 1;
          }
          if (this.appInfo.mobilePolicyApp && !this.appInfo.mobileAccess) {
            this.appInfo.mobileAccess = true;
            anomalousPolicy += 1;
          }
          if (anomalousPolicy > 0) {
            let accessPolicy: policy.NetworkAccessPolicy = {
              allowWiFi: this.appInfo.wifiAccess,
              allowCellular: this.appInfo.mobileAccess,
            }
            try {
              policy.setNetworkAccessPolicy(this.appInfo.uid, accessPolicy, false)
            } catch (e) {
              LogUtil.error(TAG, `policy error: ${e?.message} code: ${e?.code}`);
            }
          }
        })
        .catch((error: BusinessError) => {
          LogUtil.error(TAG, `get policy error: ${error.message} code: ${error.code}`);
        })
        .finally(() => {
          this.showConnectionPart = true;
        })
    }
    let duration = this.selectedIndexes[0] === 0 ? this.mobileDuration : this.wlanDuration;
    this.getMonthOrDailyData(this.appInfo.bundleName, this.appInfo.uid, this.slotId,
      this.selectedIndexes[0], duration);
  }

  private getMonthOrDailyData(bundleName: string, uid: number, slotId: number, networkType: number,
    durationChoice: number) {
    try {
      this.requestTimes++;
      this.isShowTotalFlow = false;
      this.dataValues = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0]];
      if (networkType === 0 && this.mobileDataValues !== null && typeof this.mobileDataValues !== 'undefined' &&
        typeof this.mobileChartDate !== 'undefined') {
        this.handGetMonthOrDailyDataResult({
          networkType: 0,
          requestTimes: this.requestTimes,
          datesList: this.mobileDataValues,
          chartDate: this.mobileChartDate
        });
        return;
      }
      if (networkType === 1 && this.wifiDataValues !== null && typeof this.wifiDataValues !== 'undefined' &&
        typeof this.wifiChartDate !== 'undefined') {
        this.handGetMonthOrDailyDataResult({
          networkType: 1,
          requestTimes: this.requestTimes,
          datesList: this.wifiDataValues,
          chartDate: this.wifiChartDate
        });
        return;
      }
      this.customUiInfo.showUi = false;
      pageViewModel.getAppFlow(bundleName, networkType, uid, durationChoice, slotId, this.requestTimes).then(value => {
        this.allowRefresh = true;
        this.handGetMonthOrDailyDataResult(value);
      });
    } catch (e) {
      LogUtil.error(TAG, `chart data error${JSON.stringify(e)}`);
    }
  }

  private handGetMonthOrDailyDataResult(result: MonthOrDailyDataResult) {
    if (this.requestTimes !== result.requestTimes) {
      return;
    }
    if (result.networkType === 0) {
      this.mobileDataValues = result.datesList;
      this.mobileChartDate = result.chartDate;
    } else {
      this.wifiDataValues = result.datesList;
      this.wifiChartDate = result.chartDate;
    }
    this.chartDate = result.chartDate;
    this.dataValues = result.datesList;
    this.compareAndCalculateUsedTrafficValue();
    this.isShowTotalFlow = true;
  }

  getAppInfomation() {
    // 流量管理入口
    if (router.getParams()) {
      let param = router.getParams() as Record<string, Object>;
      let app = param['appInfo'] as AppInfo;
      this.appInfo = new AppInfo(app.bundleName, app.uid, app.appIndex, app.bundleType);
      this.appInfo.isCompatibleApp = app.isCompatibleApp;
      this.appInfo.getApplicationInfo();
      if (this.appInfo.isMainSpace()) {
        this.appInfo.label = StringUtil.resource2String($r('app.string.owner_of_device'), getContext(this));
      }
      this.slotId = param['slotId'] as number;
      try {
        let networkType = param['networkType'] as number | undefined;
        if (networkType) {
          this.selectedIndexes = [networkType === 0 ? 0 : 1];
        }
      } catch (e) {
        LogUtil.error(TAG, `getAppInfomation networkType fail, error message: ${e?.message}, code: ${e?.code}`)
      }
      this.refresh();
      return;
    }
    // 应用与元服务入口
    try {
      let bundleName = AppStorage.get('bundleName') as string;
      let uid = AppStorage.get('uid') as number;
      let appIndex = ORI_APP_INDEX;
      let isCompatibleApp = false;
      try {
        let bundleInfo =
          bundleManager.getBundleInfoSync(bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
            this.userID);
        isCompatibleApp = bundleInfo.appInfo.codePath === '1';
      } catch (error) {
        LogUtil.error(TAG,
          `getBundleInfoSync failed, error code: ${error?.code}, uid: ${uid},
            message: ${error?.message}`);
        isCompatibleApp = false;
      }
      if (isCompatibleApp) {
        this.handleParamFromSettingModule(bundleName, uid, appIndex, isCompatibleApp);
      } else {
        try {
          bundleManager.getAppCloneIdentity(uid).then((res: bundleManager.AppCloneIdentity) => {
            appIndex = Number(res.appIndex);
            this.handleParamFromSettingModule(bundleName, uid, appIndex, isCompatibleApp);
          }).catch((err: BusinessError) => {
            LogUtil.error(TAG,
              `getAppCloneIdentity failed, error code: ${err.code}, message: ${err.message}.`);
          });
        } catch (err) {
          LogUtil.error(TAG,
            `getAppInfomation getAppCloneIdentity failed, error code: ${err.code}, message: ${err.message}.`);
        }
      }
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(TAG, `not enter by settings: ${message}`);
    }
  }

  handleParamFromSettingModule(bundleName: string, uid: number, appIndex: number, isCompatibleApp: boolean) {
    this.appInfo = new AppInfo(bundleName, uid, appIndex, UNKNOWN_BUNDLE_TYPE);
    this.appInfo.isCompatibleApp = isCompatibleApp;
    this.appInfo.getApplicationInfo();
    this.refresh();
  }


  onPageShow(): void {
    if (this.allowRefresh) {
      LogUtil.info(TAG, 'on page show ');
      this.refresh();
    }
  }

  aboutToAppear(): void {
    LogUtil.info(TAG, 'about to appear ');
    this.getAppInfomation();
  }

  onMobileDurationSelect = (index: number) => {
    this.mobileDuration = DURATION_CHOICE[index];
    this.durationChoice = this.mobileDuration;
    this.mobileDataValues = undefined;
    this.getMonthOrDailyData(this.appInfo.bundleName, this.appInfo.uid, this.slotId,
      this.selectedIndexes[0], DURATION_CHOICE[index]);
    this.mobileSelectedText = MOBILE_SELECTED_TEXT[index];
    LogUtil.info(TAG, 'Select:' + index)
  }
  onWlanDurationSelect = (index: number) => {
    this.wlanDuration = DURATION_CHOICE[index]
    this.durationChoice = this.wlanDuration;
    this.wifiDataValues = undefined;
    this.getMonthOrDailyData(this.appInfo.bundleName, this.appInfo.uid, this.slotId,
      this.selectedIndexes[0], DURATION_CHOICE[index]);
    this.wlanSelectedText = WLAN_SELECTED_TEXT[index];
    LogUtil.info(TAG, 'Select:' + index)
  }

  @Builder
  flowArea() {
    Column() {
      Row() {
        if (this.mobileDuration === DURATION_CHOICE[0]) {
          this.buttonShowType($r('app.string.last_30_days', '30'));
        } else {
          this.buttonShowType($r('app.string.last_24_hours', '24'));
        }
        Image($r('app.media.v'))
          .margin({ start: LengthMetrics.vp(8) })
          .height('16vp')
          .width('8vp')
          .fillColor($r('sys.color.ohos_id_color_secondary'))
          .draggable(false)
      }
      .accessibilityGroup(true, { accessibilityPreferred: true })
      .accessibilityRole(AccessibilityRoleType.SELECT)
      .padding({
        top: 4,
        bottom: 4,
        right: 8,
        left: 8
      })
      .onHover((hover: boolean) => {
        this.isHover = hover;
      })
      .stateStyles({
        normal: this.normalStyle,
        pressed: this.pressedStyle
      })
      .constraintSize({ minHeight: '28vp' })
      .bindMenu(this.MobileMenu)
      // 容器绘制焦点框前提：1、容器内部没有可获焦子节点 2、容器配置有onClick或是单指单击的Tap手势
      .onClick(() => {})
      .focusable(true)
      .visibility(this.selectedIndexes[0] === 0 ? Visibility.Visible : Visibility.None)

      Row() {
        if (this.wlanDuration === DURATION_CHOICE[0]) {
          this.buttonShowType($r('app.string.last_30_days', '30'));
        } else {
          this.buttonShowType($r('app.string.last_24_hours', '24'));
        }
        Image($r('app.media.v'))
          .margin({ start: LengthMetrics.vp(8) })
          .height('16vp')
          .width('8vp')
          .fillColor($r('sys.color.ohos_id_color_secondary'))
          .draggable(false)
      }
      .accessibilityGroup(true, { accessibilityPreferred: true })
      .accessibilityRole(AccessibilityRoleType.SELECT)
      .padding({
        top: 4,
        bottom: 4,
        right: 8,
        left: 8
      })
      .onHover((hover: boolean) => {
        this.isHover = hover;
      })
      .stateStyles({
        normal: this.normalStyle,
        pressed: this.pressedStyle
      })
      .alignItems(VerticalAlign.Center)
      .bindMenu(this.WlanMenu)
      .constraintSize({ minHeight: '28vp' })
      .visibility(this.selectedIndexes[0] === 1 ? Visibility.Visible : Visibility.None)
      // 容器绘制焦点框前提：1、容器内部没有可获焦子节点 2、容器配置有onClick或是单指单击的Tap手势
      .onClick(() => {})
      .focusable(true)
    }
    .justifyContent(FlexAlign.Center)
    .padding({
      top: AppStorage.get<boolean>('showNetworkChoice') ? 0 : 8,
    })

    this.flowAreaDetailInfo()
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
      .constraintSize({ minHeight: '40vp' })
      .margin({ top: '8vp' })
      .justifyContent(FlexAlign.Center)

      Text($r('app.string.flow_used'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .margin({ bottom: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .accessibilityGroup(true)
    .accessibilityText(StringUtil.convertResourceToString($r('app.string.flow_used'),
      getContext(this) as myCommon.UIAbilityContext) + ' ' + (this.flowText[0] + ' ' + this.flowText[1]))
    .padding({ left: 8, right: 8 })
    .visibility(this.isShowTotalFlow ? Visibility.Visible : Visibility.Hidden)
  }

  @Styles
  normalStyle(){
    .backgroundColor(this.getColor())
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  @Styles
  pressedStyle(){
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  private getColor(): ResourceColor | string {
    if (this.isHover) {
      return $r('sys.color.ohos_id_color_hover');
    }
    return '#00000000';
  }

  @Builder
  buttonShowType(buttonText: Resource) {
    Text(buttonText)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontWeight(FontWeight.Regular)
      .fontFamily('HarmonyHeiTi')
  }

  @Builder
  MobileMenu() {
    Menu() {
      MenuItem({
        content: $r('app.string.last_30_days', '30'),
        endIcon: this.mobileDuration === DURATION_CHOICE[0] ? $r('app.media.check_mark') : ''
      })
        .selected(this.mobileDuration === DURATION_CHOICE[0])
        .onClick(() => {
          this.onMobileDurationSelect(0)
        })
      MenuItem({
        content: $r('app.string.last_24_hours', '24'),
        endIcon: this.mobileDuration === DURATION_CHOICE[1] ? $r('app.media.check_mark') : ''
      })
        .selected(this.mobileDuration === DURATION_CHOICE[1])
        .onClick(() => {
          this.onMobileDurationSelect(1)
        })
    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      startMargin: LengthMetrics.px(16),
      endMargin: LengthMetrics.px(16),
      color: $r('sys.color.comp_divider')
    })
    .radius('20vp')
    .width('224vp')
    .font({
      size: $r('sys.float.ohos_id_text_size_body1'),
      weight: FontWeight.Medium, family: 'HarmonyHeiTi'
    })
    .fontColor($r('sys.color.ohos_id_color_text_primary'))
  }

  @Builder
  WlanMenu() {
    Menu() {
      MenuItem({
        content: $r('app.string.last_30_days', '30'),
        endIcon: this.wlanDuration === DURATION_CHOICE[0] ? $r('app.media.check_mark') : ''
      })
        .selected(this.wlanDuration === DURATION_CHOICE[0])
        .onClick(() => {
          this.onWlanDurationSelect(0)
        })
      MenuItem({
        content: $r('app.string.last_24_hours', '24'),
        endIcon: this.wlanDuration === DURATION_CHOICE[1] ? $r('app.media.check_mark') : ''
      })
        .selected(this.wlanDuration === DURATION_CHOICE[1])
        .onClick(() => {
          this.onWlanDurationSelect(1)
        })
    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      startMargin: LengthMetrics.px(16),
      endMargin: LengthMetrics.px(16),
      color: $r('sys.color.comp_divider')
    })
    .radius('20vp')
    .width('224vp')
    .font({ size: $r('sys.float.ohos_id_text_size_body1'), weight: FontWeight.Medium, family: 'HarmonyHeiTi' })
    .fontColor($r('sys.color.ohos_id_color_text_primary'))
  }

  @Builder
  navigationArea() {
    Column() {
      SegmentButton({
        options: this.singleAppTabOptions,
        selectedIndexes: $selectedIndexes
      })
        .constraintSize({ minHeight: 56 })
        .focusable(false)
        .defaultFocus(false)
        .width('100%')
        .margin({ bottom: 8 })
        .padding({
          top: 8,
          bottom: 8,
          left: 12,
          right: 12
        })
        .visibility(AppStorage.get<boolean>('showNetworkChoice') ? Visibility.Visible : Visibility.None);
      Column() {
        this.flowArea();
      }
      .padding({ left: 4, right: 4 })
      .alignItems(HorizontalAlign.Start);

      Column() {
        this.chartArea();
      };
    }
    .alignItems(HorizontalAlign.Start)
    .margin({ top: $r('sys.float.padding_level8'), bottom: 12 })
    .padding({
      top: 4,
      bottom: 4
    })
    .borderRadius('20vp')
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_list_card'))

    if (this.showConnectionPart) {
      this.connection()
    }
  }

  @Builder
  chartArea() {
    ChartComponent()
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
    .margin({ bottom: 8 })
    .padding({ left: 12, right: 12 })
  }

  build() {
    // HdsNavigation() {
      Navigation() {
        this.navigationAreaLayout();
      }
      .title(TitleParams.MiniTitleParams(this.appInfo.label, $r('sys.color.ohos_id_color_sub_background')))
      .titleMode(NavigationTitleMode.Mini)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .hideBackButton(true)
      .mode(NavigationMode.Stack)
      .width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  @Builder
  navigationAreaLayout() {
    Stack({alignContent: Alignment.End}) {
      Scroll() {
        Column() {
          this.navigationArea()
        }
        .margin({ bottom: 16 + this.naviIndicatorHeight })
      }
      .clip(false)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .height('100%')
      .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16 })
      .onWillScroll(() => {
        this.isSingleAppScrolling = true;
      })
      .onScrollStop(() => {
        this.isSingleAppScrolling = false;
      })
      ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .margin({ top: 8, bottom: 16 + 28 });
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

  @Builder
  connection() {
    List() {
      if (AppStorage.get<boolean>('showNetworkChoice')) {
        ListItem() {
          this.allowToOpenMobile()
        }
        .accessibilityGroup(true)
      }

      ListItem() {
        this.allowToOpenWLAN()
      }
      .accessibilityGroup(true)
    }
    .width('100%')
    .padding({
      top: 4,
      bottom: 4,
      left: $r('sys.float.padding_level3'),
      right: $r('sys.float.padding_level3'),
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius('20vp')
    .divider({
      strokeWidth: '1px',
      color: $r('sys.color.ohos_id_color_list_separator')
    })
  }

  @Builder
  allowToOpenMobile() {
    Row() {
      Row() {
        Text($r('app.string.mobile_data'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
      }
      .width(`calc(100% - 44vp)`)
      .margin({ end: LengthMetrics.vp(8) })
      Toggle({ type: ToggleType.Switch, isOn: this.appInfo.mobileAccess })
        .hoverEffect(HoverEffect.None)
        .onChange(isOn => {
          this.appInfo.changeMobileAccess(isOn, this.appInfo);
          this.mPresenter.refreshAccessByUid(this.appInfo.uid, this.appInfo.wifiAccess, this.appInfo.mobileAccess);
          //切换移动数据开关打点
          DotUtil.getInstance()
            .reportChangeMobileDataNetworkToggle(this.appInfo.bundleName, isOn ? ToggleState.OPEN : ToggleState.CLOSE);
        })
        .margin(0)
        .enabled(!this.appInfo.mobilePolicyApp && !this.appInfo.isPrivateOrMainSpace())
        .accessibilityLevel('yes')
    }
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13vp'),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '14vp'),
      left: $r('sys.float.padding_level3'),
      right: $r('sys.float.padding_level3'),
    })
    .constraintSize({ minHeight: 48 })
    .width('100%')
  }

  @Builder
  allowToOpenWLAN() {
    Row() {
      Row() {
        Text($r('app.string.wlan'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
      }
      .width(`calc(100% - 44vp)`)
      .margin({ end: LengthMetrics.vp(8) })
      Toggle({ type: ToggleType.Switch, isOn: this.appInfo.wifiAccess })
        .hoverEffect(HoverEffect.None)
        .onChange(isOn => {
          this.appInfo.changeWifiAccess(isOn, this.appInfo);
          this.mPresenter.refreshAccessByUid(this.appInfo.uid, this.appInfo.wifiAccess, this.appInfo.mobileAccess);
          //切换WLAN开关打点
          DotUtil.getInstance()
            .reportChangeWlanNetworkToggle(this.appInfo.bundleName, isOn ? ToggleState.OPEN : ToggleState.CLOSE);
        })
        .margin(0)
        .enabled(!this.appInfo.wlanPolicyApp && !this.appInfo.isPrivateOrMainSpace())
        .accessibilityLevel('yes')
    }
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13vp'),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '14vp'),
      left: $r('sys.float.padding_level3'),
      right: $r('sys.float.padding_level3'),
    })
    .constraintSize({ minHeight: 48 })
    .width('100%')
  }

  onSegmentButtonIndexChanged() {
    let duration = this.selectedIndexes[0] === 0 ? this.mobileDuration : this.wlanDuration
    this.durationChoice = duration;
    this.getMonthOrDailyData(this.appInfo.bundleName, this.appInfo.uid ? this.appInfo.uid : 0, this.slotId,
      this.selectedIndexes[0], duration);
  }

  private compareAndCalculateUsedTrafficValue() {
    let totalFlow: number = 0;
    this.dataValues.forEach((value) => {
      if (!value || value.length < 2) {
        return;
      }
      totalFlow += value[1];
    });
    this.flow = totalFlow;
    this.flowText = getFlowText(this.flow);
  }
}