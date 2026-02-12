/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import {
  ItemRestriction,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem
} from '@ohos.arkui.advanced.SegmentButton';
import {
  DEFAULT_USERID,
  getFlowText,
  Keys,
  LoadingFinished,
  MAX_SIM_COUNT,
  NavEntryKey,
  NetworkType,
  SearchMode,
  SEARCH_TITLE_START_MARGIN,
  SEARCH_TITLE_START_MARGIN_PAD,
  START_REASON_FROM_SEARCH,
  TRAFFIC_CONTROL_PAGE_VISIBLE_STATUS
} from '../constants/CommonConstants';
import { AppRankItemComponent } from '../view/AppRankItemComponent';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import PageViewModel from '../viewmodel/PageViewModel';
import { ConnectionPageComponent } from '../pagesComponents/ConnectionPageComponent';
import { RankPageComponent, SysAndUninstallAppsInfo } from '../pagesComponents/RankPageComponent';
import { SysServicePageComponent } from '../pagesComponents/SysServicePageComponent';
import sim from '@ohos.telephony.sim';
import { EmptyPage, WaitingPage } from './EmptyPage';
import AppInfoListDataSource from '../viewmodel/AppInfoListDataSource';
import { AppInfoInterface } from '../viewmodel/type';
import AppInfoListPresenter, { AllAppInfoList } from '../presenter/AppInfoListPresenter';
import data from '@ohos.telephony.data';
import StringUtil from '../../ets/util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import radio from '@ohos.telephony.radio';
import { isTablet, IsWiFiOnly } from '../util/DeviceUtil';
import { LogUtil } from '../util/LogUtil';
import { FontScaleState } from '../util/fontScaleState';
import { OperationType, SubHeader } from '@ohos.arkui.advanced.SubHeader';
import { display, LengthMetrics, curves } from '@kit.ArkUI';
import { SearchInfo } from '../data/SearchData';
import { DisplayUtils } from '../util/DisplayUtils';
import { CommonListComponent } from '../view/CommonListComponent';
import DotUtil from '../util/Dot/DotUtils';
import { MoreSettingsPageComponent } from '../pagesComponents/MoreSettingsPageComponent';
import promptAction from '@ohos.promptAction';
import { TrafficDetailPageComponent } from '../pagesComponents/TrafficDetailPageComponent';
import TrafficPackagePresenter from '../presenter/TrafficPackagePresenter';
import { SimModel } from '../model/SimModel';
import { DataPlanPageComponent } from '../pagesComponents/DataPlanPageComponent';
import { UsageRemindersPageComponent } from '../pagesComponents/UsageRemindersPageComponent';
import TrafficController from '../Controller/TrafficController';
import { cardInfo, SimCradNameListener as SimCradListener } from '../util/SimCradNameListener';
import { SimCardInfo } from '../util/TrafficPackageUtil';
import { AppStorageUtils } from '../util/AppStorageUtils';
import ScreenAdapterUtils from '../util/ScreenAdapterUtils';
import { AccessibilityUtils } from '../util/AccessibilityUtils';
import CallColumnUtils from '../util/CallColumnUtils';
// import {
//   HdsNavigation,
//   HdsNavigationAttribute,
//   HdsNavigationTitleBarOptions,
//   HdsNavigationTitleMode
// } from '@kit.UIDesignKit';
import { TitleParams } from '../view/TitleParams';
import { TrafficDisplayComponent } from '../view/TrafficDisplayComponent';
import { TrafficDisplayViewModel } from '../viewmodel/TrafficDisplayViewModel';
import { tag } from '@kit.ConnectivityKit';
import { DisPlaySimCardInfo as DisPlaySimCard } from '../util/DisPlaySimCardInfo';

const SEARCH_ID = 'search'
const TAG: string = 'TrafficControlPage';
// 获取应用信息最小的时间间隔
const MIN_REQUEST_INTERVAL: number = 1000;
const ANIM_DURATION: number = 150;
const CIRCLE_ANIM_DURATION: number = 30;
const SEARCH_BUTTON_ID = 'searchButton';
const SEARCH_BACK_BUTTON_ID = 'searchBackButton';

@Entry
@Component
struct TrafficControlPage {
  scroller: Scroller = new Scroller;
  public isWiFiOnly: boolean = IsWiFiOnly();
  public storage = LocalStorage.getShared();
  @Provide('pageInfos') pageInfos: NavPathStack = this.getNavPathStack();
  public rankOfThisMonth = AppStorage.get<boolean>('showNetworkChoice') ? $r('app.string.ranking_of_this_month') :
    $r('app.string.wlan_ranking_of_this_month');
  //搜索功能参数
  @State changeValue: string = '';
  @State submitValue: string = '';
  @Provide searchMode: number = SearchMode.NOT_SEARCHING;
  @State showApps: Array<AppInfo> = [];
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  // SegmentButton适老化需求需要限制放大两倍高度
  @State simCardOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: $r('app.string.sim_card_1', '') },
      { text: $r('app.string.sim_card_2', '') }] as ItemRestriction<SegmentButtonTextItem>,
    selectedFontSize: $r('sys.float.ohos_id_text_size_button2'),
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
    fontSize: $r('sys.float.ohos_id_text_size_button2'),
    fontColor: $r('sys.color.ohos_id_color_text_secondary'),
    backgroundColor: $r('sys.color.ohos_id_color_button_normal'),
    fontWeight: FontWeight.Medium
  });
  @State simCardNameTexts: ResourceStr[] = ['', ''];
  //SIM卡切换参数
  @Provide @Watch('onSegmentButtonIndexChanged') simSelectedIndexes: number[] =
    [data.getDefaultCellularDataSlotIdSync()];
  @State mPresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
  @State showSystem: boolean = false;
  @State showUninstalledApps: boolean = false;
  @Provide sysServiceString: string = '';
  @Provide uninstalledString: string = '';
  controller: SearchController = new SearchController();
  //流量统计参数
  @Provide modeSelectedIndexes: number[] = [AppStorage.get<boolean>('showNetworkChoice') ? 0 : 1];
  // 判断流量管理界面数据是否加载完成
  @Provide trafficLoadingFinished: number = LoadingFinished.NONE;
  @Provide totalCount: number = 0;
  @Provide uninstalledAppsFlows: string = '';
  @Provide uninstalledAppsFlowsNum: number = 0;
  @Provide sysServiceList: Map<number, number> = new Map<number, number>();
  @Provide showWlan: boolean = false;
  @Provide othersMobileInfo: SysAndUninstallAppsInfo = new SysAndUninstallAppsInfo();
  @Provide directShowMobilePage: boolean = true;
  @StorageProp('foldStatus') @Watch('onFoldStatusChanged') foldStatus: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  @State isShowBackIcon: boolean = true;
  private isFromSearch: boolean = this.storage?.get<string>('startReason') === START_REASON_FROM_SEARCH;
  @Provide session: UIExtensionContentSession =
    this.storage.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  private naviHeight: number = 0;
  @State loadCoverViewWithAnimate: boolean = true;
  @State isFirstLoadSearchMenu: boolean = false;
  @StorageProp('userID') userID: number = DEFAULT_USERID;
  @StorageProp('enableScroll') enableScroll: boolean = true;
  @Provide hasTwoSimCard: boolean = false;
  @Provide existSimCard: boolean = false;
  @Provide isScrolling: boolean = false;
  trafficController: TrafficController = new TrafficController()
  @Provide isDismissWhenClickAppListItem: boolean = false;
  private maxSimCount: number = 1;
  private simCardListener: SimCradListener = new SimCradListener();
  @StorageProp(AppStorageUtils.SIM_COUNT) @Watch('onSimCountChanged') simCount: number = 0;
  @State titleX: number | string = '40%';
  @State searchX: number | string = 100;
  @State opacityVal: number = 0;
  @State circleOpacityVal: number = 0;
  private getAppAppTrafficsDate?: Date;
  private backPressCallback: () => void = () => {
    this.onBackPress();
  }
  private isBackFromSearchModel = false;
  @State isSearchTitle: boolean = false;
  @State trafficDisplayViewModel: TrafficDisplayViewModel = new TrafficDisplayViewModel(this.simSelectedIndexes[0]);
  @Provide isExitTraffic: boolean = false;
  private disPlaySimCardInfo: DisPlaySimCard = new DisPlaySimCard();

  aboutToAppear() {
    LogUtil.info(TAG, 'aboutToAppear');
    this.simCardListener.refreshSimList();
    this.maxSimCount = this.simCardListener.getMaxSimCount();
    this.existSimCard = PageViewModel.existSimCard();
    this.hasTwoSimCard = PageViewModel.hasTwoSimCard();
    LogUtil.info(TAG, 'aboutToAppear hasTwoSimCard ' + this.hasTwoSimCard +'aboutToAppear maxSimCount ' + this.maxSimCount);
    if (this.maxSimCount === MAX_SIM_COUNT) {
      this.simCardListener.addSimCardStatusChangeListener((slotId: number, showName: ResourceStr, isError: boolean) => {
        LogUtil.info(TAG, `SimCardNameChangeListener ----------- ${slotId}---${showName}`)
        this.simCardOptions.buttons[slotId].text = showName;
        this.simCardNameTexts[slotId] = showName;
        this.simCardListener.refreshSimList();
        if (isError === false) {
          this.simStatusChanged(slotId);
        }
      })
      this.simCardListener.refreshSimList();
    }
    this.isShowBackIcon = !DisplayUtils.isSplit(getContext(this)) || !this.isFromSearch;
    if (AppStorage.get<number>('naviIndicatorHeight')) {
      this.naviHeight = AppStorage.get<number>('naviIndicatorHeight') as number;
    }
    const searchInfo = this.storage?.get<SearchInfo>(Keys.SEARCH_INFO);
    if (searchInfo) {
      if (searchInfo?.slotId !== undefined && !searchInfo?.isSlotIdDefault()) {
        this.simSelectedIndexes[0] = searchInfo?.slotId;
      }
      if (searchInfo?.networkType !== undefined && searchInfo?.isNetworkTypeValueAble()) {
        this.modeSelectedIndexes[0] = searchInfo?.networkType;
      }
    }
    let context = (getContext(this) as myCommon.UIAbilityContext);
    this.sysServiceString = StringUtil.convertResourceToString($r('app.string.system_and_service'), context);
    this.uninstalledString = StringUtil.convertResourceToString($r('app.string.category_uninstalled_apps'), context);
    if (this.hasTwoSimCard) {
      for (let i = 0; i < 2; i++) {
        sim.getShowName(i).then(showName => {
          let displayName = this.getDisplayName(showName, i, context);
          this.simCardOptions.buttons[i].text = displayName;
          this.simCardNameTexts[i] = displayName;
          LogUtil.info(TAG,
            `Display Info: displayName=${displayName}, buttonText=${this.simCardOptions.buttons[i].text}, simCardName=${this.simCardNameTexts[i]}`);
        }).catch((err: Error) => {
          LogUtil.error(TAG,
            `aboutToAppear slot id : ${i} , get sim card name failed, promise: err->errormsg: ${err?.message}`);
        });
      }
    }
    this.trafficController.showReminders();
  }

  aboutToDisappear(): void {
    LogUtil.info(TAG, 'aboutToDisappear');
    this.simCardListener.unregisterListenter();
  }

  onPageShow() {
    LogUtil.info(TAG, 'on page show');
    // 从后台进入如果不是当前界面 不刷新数据
    if (this.pageInfos.size() > 0 &&
      this.pageInfos.getAllPathName()[this.pageInfos.size() - 1] === NavEntryKey.CONNECTION_PAGE) {
      return;
    }
    //wlan排行界面返回不刷新
    if (!this.showWlan) {
      this.getAppTrafficsDataDetails();
    }
    this.simCardListener.refreshSimList();
  }

  private getAppTrafficsDataDetails() {
    this.trafficLoadingFinished =
      this.trafficLoadingFinished === LoadingFinished.NONE ? LoadingFinished.NONE : LoadingFinished.HIDDEN;
    this.getAppAppTrafficsDate = new Date();
    LogUtil.info(TAG, 'getAppTrafficsDataDetails start');
    this.mPresenter.getAllAppTraffics(this.modeSelectedIndexes[0], this.simSelectedIndexes[0],
      (data: AllAppInfoList) => {
        if (!data) {
          LogUtil.info(TAG, 'getAppTrafficsDataDetails getAllAppTraffics data is empty.');
          return;
        }
        if (data.slotId !== this.simSelectedIndexes[0]) {
          LogUtil.info(TAG,
            `result not match, current slotid: ${this.simSelectedIndexes[0]}, result slotid: ${data.slotId}`);
          return;
        }
        this.totalCount = data.appList.length;
        this.mPresenter.appListShow.refresh(data.appList);
        this.uninstalledAppsFlows = getFlowText(data.uninstalledAppsFlows)[0] + ' ' +
        getFlowText(data.uninstalledAppsFlows)[1];
        this.uninstalledAppsFlowsNum = data.uninstalledAppsFlows;
        this.sysServiceList = data.sysServiceList;
        if (!IsWiFiOnly()) {
          this.updateOtherMobileInfo();
        }
        this.trafficLoadingFinished = LoadingFinished.FINISHED;
        if (data.appList.length > 0) {
          DotUtil.getInstance().dotStatisticDetails(data.appList, IsWiFiOnly() ? NetworkType.WLAN : NetworkType.MOBILE);
        }
        if (this.sysServiceList.size > 0) {
          DotUtil.getInstance()
            .reportSystemAndServiceDataRankStatus(this.sysServiceList,
              IsWiFiOnly() ? NetworkType.WLAN : NetworkType.MOBILE);
        }
      });
  }

  private simStatusChanged(slotId?: number) {
    TrafficPackagePresenter.getInstance().clearAllCacheData();
    this.existSimCard = PageViewModel.existSimCard();
    this.hasTwoSimCard = PageViewModel.hasTwoSimCard();
    if (this.existSimCard) {
      LogUtil.info(TAG, `simStatusChanged2 simCount = ${this.hasTwoSimCard}`);
      this.trafficController.showReminders();
    } else {
      let slotCount = this.simCardNameTexts.length;
      for (let index = 0; index < slotCount; index++) {
        this.simCardNameTexts[index] = '';
      }
      LogUtil.info(TAG, 'simStatusChanged3');
      AppStorage.setOrCreate<boolean>('reminder1', false);
      AppStorage.setOrCreate<boolean>('reminder2', false);
    }
    let currentDate = new Date();
    // 防止网络变化时频繁请求应用信息
    if (this.getAppAppTrafficsDate === undefined ||
      (currentDate.getTime() - this.getAppAppTrafficsDate.getTime() > MIN_REQUEST_INTERVAL)) {
      this.simSelectedIndexes[0] = data.getDefaultCellularDataSlotIdSync();
      this.getAppTrafficsDataDetails();
      this.trafficDisplayViewModel.changeCurrentSlotId(this.simSelectedIndexes[0])
      this.trafficDisplayViewModel.fetchTrafficDisplayStatus();
    }
    this.simCardListener.refreshSimList();
  }

  // 滑动手势调用
  onBackPress(): boolean | void {
    this.backAnimate();
    if (this.searchMode === SearchMode.NOT_SEARCHING) {
      this.isExitTraffic = true;
      return;
    }
    AccessibilityUtils.sendAccessibilityEvent(SEARCH_BUTTON_ID);
    this.searchMode = SearchMode.NOT_SEARCHING;
    this.isSearchTitle = false;
    return true;
  }

  private backAnimate(): void {
    if (this.searchMode !== SearchMode.NOT_SEARCHING) {
      return;
    }
    // title退场动画
    animateTo({ duration: 150, curve: Curve.Sharp }, () => {
      this.titleX = '40%';
      this.searchX = 100;
      this.opacityVal = 0;
    });
    animateTo({ duration: CIRCLE_ANIM_DURATION, delay: 30, curve: Curve.Sharp }, () => {
      this.circleOpacityVal = 0;
    });
  }

  @Builder
  PageMap(name: string) {
    if (name === NavEntryKey.CONNECTION_PAGE) {
      ConnectionPageComponent()
    } else if (name === NavEntryKey.RANK_PAGE) {
      RankPageComponent()
    } else if (name === NavEntryKey.SYS_SERVICE_PAGE) {
      SysServicePageComponent()
    } else if (name === NavEntryKey.MORE_SETTINGS_PAGE) {
      // 不确定跳转名称是否正确传递
      MoreSettingsPageComponent({
        cardName: this.simCardNameTexts,
      })
    } else if (name === NavEntryKey.DATA_PLAN_PAGE) {
      DataPlanPageComponent()
    } else if (name === NavEntryKey.USAGE_REMINDERS_PAGE) {
      UsageRemindersPageComponent()
    }
  }

  build() {
    Navigation(this.pageInfos) {
      // HdsNavigation(this.pageInfos) {
      Column() {
        if (this.searchMode === SearchMode.SearchingResult) {
          this.searchResultPart()
        } else {
          this.normalPagePart()
        }
      }
    }
    .onNavBarStateChange(() => {
      // 从后台进入如果不是当前界面 不刷新数据
      let isVisible: boolean = this.pageInfos.size() === 0;
      AppStorage.setOrCreate(TRAFFIC_CONTROL_PAGE_VISIBLE_STATUS, isVisible);
    })
    .hideBackButton(!this.isShowBackIcon && this.searchMode === SearchMode.NOT_SEARCHING)
    .title(this.NavTitleBuilder())
    .titleMode(NavigationTitleMode.Mini)
    .width('100%')
    .layoutWeight(1)
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  // 统一的标题栏 Builder
  @Builder
  NavTitleBuilder() {
    Column() {
      // --- 第一部分：主标题栏区域 (56vp 高度) ---
      Row() {
        if (this.isSearchTitle) {

          this.searchingTitle()

        } else {

          Text($r('app.string.mobile_data_manage_entry')) // 注意确认文案是否正确
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1) // 标题占据左侧大部分空间

          // 2. 搜索入口按钮 (这里必须有，否则点不了搜索)
          Image($r('app.media.ic_public_search')) // 或者是 SymbolGlyph
            .width(24)
            .height(24)
            .fillColor($r('sys.color.ohos_id_color_primary'))
            .onClick(() => {
              // 触发状态切换，页面会自动重绘为上方 A 模式
              this.changeValue = '';
              this.isSearchTitle = true;
              this.searchMode = SearchMode.IN_SEARCHING;
            })
            .id(SEARCH_BUTTON_ID)
        }
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .padding({
        left: isTablet() ? 24 : 16,
        right: isTablet() ? 24 : 16
      })

    }
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  // private titleParam(): HdsNavigationTitleBarOptions {
  //   return {
  //     enableComponentSafeArea: true,
  //     style: {
  //       scrollEffectOpts: {
  //         enableScrollEffect: false
  //       },
  //       originalStyle: {
  //         backgroundStyle: {
  //           backgroundColor: $r('sys.color.ohos_id_color_sub_background')
  //         }
  //       }
  //     },
  //     avoidLayoutSafeArea: true,
  //     padding: {
  //       start: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16),
  //       end: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16)
  //     },
  //     content: {
  //       title: {
  //         mainTitle:$r('app.string.mobile_data_manage_entry'),
  //       },
  //       menu: {
  //         value: [
  //           {
  //             content: {
  //               label: $r('app.string.searching'),
  //               icon: $r('app.media.ic_public_search'),
  //               isEnabled: true,
  //               action: () => {
  //                 this.changeValue = '';
  //                 this.searchMode = SearchMode.IN_SEARCHING;
  //                 this.isSearchTitle = true;
  //                 AccessibilityUtils.sendAccessibilityEvent(SEARCH_BACK_BUTTON_ID);
  //               },
  //               componentId: SEARCH_BUTTON_ID
  //             }
  //           },
  //         ]
  //       },
  //       backIcon: {
  //         label: $r('app.string.accessibility_back'),
  //         icon: $r('sys.symbol.chevron_backward'),
  //         isEnabled: true,
  //         action: this.onBackClick
  //       }
  //     },
  //   };
  // }

  onBackClick = () => {
    this.backAnimate();
    if (this.searchMode === SearchMode.NOT_SEARCHING) {
      this.isExitTraffic = true;
      if (this.session) {
        this.session.sendData({ 'action': 'pop' });
      }
      return;
    }
    AccessibilityUtils.sendAccessibilityEvent(SEARCH_BUTTON_ID);
    this.searchMode = SearchMode.NOT_SEARCHING;
    this.isSearchTitle = false;
  }

  private onFoldStatusChanged() {
    if (this.foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED ||
      this.foldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
      // 新的竖折设备
      if (ScreenAdapterUtils.isNewFormFoldPhone()) {
        this.isShowBackIcon = true;
      } else {
        this.isShowBackIcon = !this.isFromSearch;
      }
    } else {
      this.isShowBackIcon = true;
    }
  }

  onSimCountChanged() {
    if (this.simCount === 0) {
      this.simStatusChanged();
    }
  }

  @Builder
  searchingTitle() {
    Row() {
      Search({ controller: this.controller, value: this.changeValue, placeholder: $r('app.string.searching') })
        .onAppear(() => {
          try {
            this.getUIContext().getFocusController().requestFocus(SEARCH_ID);
          } catch (e) {
            LogUtil.error(TAG, `search focus error: ${e?.message} code: ${e?.code}`);
          }
        })
        .onChange((value) => {
          this.onChangeSearch(value);
        })
        .maxLength(128)
        .id(SEARCH_ID)
        .margin({
          start: isTablet() ? LengthMetrics.vp(SEARCH_TITLE_START_MARGIN_PAD) :
            LengthMetrics.vp(SEARCH_TITLE_START_MARGIN),
          end: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16)
        })
        .caretStyle({ color: $r('sys.color.ohos_id_color_text_primary_activated') })
        .defaultFocus(true)
        .height(40)
        .placeholderFont({
          size: ($r('sys.float.Body_L')),
          weight: FontWeight.Regular
        })
        .textFont({ size: $r('sys.float.Body_L'), weight: 400 })
        .layoutWeight(1)
    }
    .height(56)
  }

  onChangeSearch = (value: string) => {
    this.changeValue = value;
    if (!value) {
      this.loadCoverViewWithAnimate = false;
      this.searchMode = SearchMode.IN_SEARCHING;
      return;
    }
    if (this.isWiFiOnly) {
      this.showSystem = StringUtil.isIncluded(this.sysServiceString, value) &&
        this.sysServiceList.size !== 0;
      this.showUninstalledApps =
        StringUtil.isIncluded(this.uninstalledString, value) && this.uninstalledAppsFlowsNum !== 0;
    }
    this.showApps = this.mPresenter.appListShow?.getAllData().filter((appInfo) => {
      return StringUtil.isIncluded(appInfo.label, value);
    })
    this.searchMode = SearchMode.SearchingResult;
  }

  @Builder
  resultListArea(item: AppInfo) {
    ListItem() {
      AppRankItemComponent({ appInfo: item, showNetworkType: true })
    }
    .onClick(() => {
      router.pushUrl({
        url: 'pages/SingleAppPage',
        params: {
          appInfo: item,
          slotId: this.simSelectedIndexes[0],
        }
      })
    })
    .width('100%')
  }

  @Builder
  searchResultPart() {
    if (this.showApps?.length === 0 && !this.showSystem && !this.showUninstalledApps) {
      EmptyPage({ paddingNum: 16 + this.naviHeight })
    } else {
      Stack({ alignContent: Alignment.End }) {
        this.searchResultShowList()
      }
      .margin({ top: $r('sys.float.padding_level8') })
      .layoutWeight(1);
    }
  }

  @Builder
  searchResultShowList() {
    Column() {
      List({ scroller: this.scroller }) {
        ListItemGroup() {
          ForEach(this.showApps, (item: AppInfo) => {
            this.resultListArea(item);
          }, (item: AppInfo, index?: number) => index + JSON.stringify(item));
        }
        .visibility(this.showApps.length > 0 ? Visibility.Visible : Visibility.None)
        .margin({
          bottom: this.isWiFiOnly && (this.showUninstalledApps || this.showSystem) ? 0 : 16 + this.naviHeight
        })
        .padding({
          top: 4,
          bottom: 4,
          left: 4,
          right: 4
        })
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .borderRadius('20vp')
        .divider({
          strokeWidth: '1px',
          startMargin: 72,
          endMargin: 8,
          color: $r('sys.color.ohos_id_color_list_separator')
        });

        if (this.showUninstalledApps) {
          ListItemGroup() {
            this.uninstalledApps({
              top: this.showApps.length > 0 ? 12 : 0,
              bottom: this.showSystem ? 0 : 16 + this.naviHeight
            })
          }
        }
        if (this.showSystem) {
          ListItemGroup() {
            // 系统与服务
            CommonListComponent({
              name: $r('app.string.system_and_service'),
              onClickCallBack: () => {
                this.handleCommonListClickEvent(NavEntryKey.SYS_SERVICE_PAGE);
              }
            })
          }
          .margin({
            top: this.totalCount > 0 || this.uninstalledAppsFlowsNum > 0 ? 12 : 0,
            bottom: 16 + this.naviHeight
          })
        }
      }
      .clip(false)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16 })

    ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
      .margin({ top: 12, bottom: 16 + this.naviHeight });
  }

  @Builder
  normalPagePart() {
    Scroll() {
      Stack() {
        this.normalPageShowList()

        if (this.searchMode === SearchMode.IN_SEARCHING) {
          Column() {
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('sys.color.background_secondary'))
          .transition(this.loadCoverViewWithAnimate ? TransitionEffect.OPACITY.animation({ duration: 200 }) :
            TransitionEffect.IDENTITY)
          .onClick(() => {
            this.controller.stopEditing();
          })
          .onAppear(() => {
            this.loadCoverViewWithAnimate = true;
          })
          .accessibilityLevel('no')
        }
      }
      .height('100%')
    }
    .align(Alignment.Top)
    .accessibilityGroup(this.searchMode === SearchMode.NOT_SEARCHING ? false : true)
    .accessibilityLevel(this.searchMode === SearchMode.NOT_SEARCHING ? 'yes' : 'no')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
  }

  @Builder
  normalPageShowList() {
    Column() {
      Stack({ alignContent: Alignment.End }) {
        Column() {
          this.contentUIBuild(this.mPresenter.appListShow);
        }
        .width('100%')
        .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16 });

        ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
          .margin({ top: 12, bottom: 16 + this.naviHeight });
      }
      .layoutWeight(1);
    }
    .margin({ top: $r('sys.float.padding_level8') })
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  headViewBuild() {
    Column() {
      this.cardHeadBuild();
      CommonListComponent({
        name: $r('app.string.network_title'),
        onClickCallBack: () => {
          this.handleCommonListClickEvent(NavEntryKey.CONNECTION_PAGE);
        }
      })
        .margin({ top: (this.existSimCard && !IsWiFiOnly()) ? 12 : 0 })
      // 更多设置入口
      Column() {
        TrafficDisplayComponent({ trafficDisplayViewModel: this.trafficDisplayViewModel })
        Divider()
          .strokeWidth('1px')
          .color($r('sys.color.ohos_id_color_list_separator'))
          .margin({
            start: LengthMetrics.resource($r('sys.float.padding_level6')),
            end: LengthMetrics.resource($r('sys.float.padding_level6'))
          })

        CommonListComponent({
          name: $r('app.string.more_data_usage_settings_title'),
          onClickCallBack: () => {
            this.handleCommonListClickEvent(NavEntryKey.MORE_SETTINGS_PAGE);
            DotUtil.getInstance().reportClickMoreTrafficSettings();
          },
          isInSerialList: true
        })
      }
      .padding({
        top: $r('sys.float.padding_level2'),
        bottom: $r('sys.float.padding_level2')
      })
        .margin({ top: 12 })
        .visibility(!IsWiFiOnly() && this.existSimCard ? Visibility.Visible : Visibility.None)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius($r('sys.float.corner_radius_level10'))

      this.rankSubHeader();
      if (this.trafficLoadingFinished === LoadingFinished.NONE) {
        WaitingPage({ paddingNum: 16 + this.naviHeight });
      }
    }
    .width('100%')
  }

  @Builder
  contentUIBuild(appList: AppInfoListDataSource) {
    List({ scroller: this.scroller }) {
      ListItemGroup() {
        this.headViewBuild();
      }

      ListItemGroup() {
        LazyForEach(appList, (item: AppInfoInterface) => {
          ListItem() {
            AppRankItemComponent({
              appInfo: item.appInfo,
              showNetworkType: true
            })
          }
          .constraintSize({ minHeight: 64 })
          .onClick(() => {
            this.isDismissWhenClickAppListItem = true;
            router.pushUrl({
              url: 'pages/SingleAppPage',
              params: {
                appInfo: item.appInfo,
                slotId: this.simSelectedIndexes[0],
              }
            })
          })
        }, (item: AppInfoInterface, index: number) => {
          return index.toString() + item.appInfo.uid?.toString() + item.appInfo.flow.toString() +
          item.appInfo.wifiAccess + item.appInfo.mobileAccess
        })
      }
      .borderRadius(20)
      .visibility(this.totalCount > 0 ? Visibility.Visible : Visibility.None)
      .padding({
        top: 4,
        bottom: 4,
        right: 4,
        left: 4
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .divider({
        strokeWidth: '1px',
        startMargin: 72,
        endMargin: 8,
        color: $r('sys.color.ohos_id_color_list_separator')
      })
      .margin({
        bottom: this.isWiFiOnly && this.sysServiceList.size + this.uninstalledAppsFlowsNum !== 0 ?
          0 : 16 + this.naviHeight
      })

      if (this.isWiFiOnly && this.uninstalledAppsFlowsNum !== 0) {
        ListItemGroup() {
          this.uninstalledApps({
            top: this.totalCount > 0 ? 12 : 0,
            bottom: this.sysServiceList.size === 0 ? 16 + this.naviHeight : 0
          })
        }
      }

      if (this.isWiFiOnly && this.sysServiceList.size !== 0) {
        ListItemGroup() {
          // 系统与服务
          CommonListComponent({
            name: $r('app.string.system_and_service'),
            onClickCallBack: () => {
              this.handleCommonListClickEvent(NavEntryKey.SYS_SERVICE_PAGE);
            }
          })
        }
        .margin({
          top: this.totalCount > 0 || this.uninstalledAppsFlowsNum > 0 ? 12 : 0,
          bottom: 16 + this.naviHeight
        })
      }
    }
    .clip(false)
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .onScrollFrameBegin((offset, state) => {
      return { offsetRemain: this.enableScroll ? offset : 0 }
    })
    .onScrollStart(() => {
      this.isScrolling = true;
    })
    .onScrollStop(() => {
      this.isScrolling = false;
    })
  }

  @Builder
  uninstalledApps(myMargin: Margin) {
    Column() {
      if (FontScaleState.isStandardGear(this.fontSizeScale)) {
        Row() {
          this.uninstalledContents()
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      } else {
        this.uninstalledContents()
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .margin({ top: myMargin.top, bottom: myMargin.bottom })
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 4, '13vp'),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 4, '14vp'),
      left: 12,
      right: 12
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius('20vp')
  }

  @Builder
  uninstalledContents() {
    Text($r('app.string.category_uninstalled_apps'))
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Medium)
      .fontSize($r('sys.float.ohos_id_text_size_body1'))
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
    Text(this.uninstalledAppsFlows)
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Regular)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .textAlign(TextAlign.Start)
  }

  @Builder
  cardHeadBuild() {
    if (this.existSimCard && !IsWiFiOnly()) {
      Column() {
        if (this.hasTwoSimCard) {
          SegmentButton({
            options: this.simCardOptions,
            selectedIndexes: $simSelectedIndexes
          })
            .constraintSize({ minHeight: 56 })
            .padding({ top: 12, left: 12, right: 12 })
            .width('100%')
        }
        TrafficDetailPageComponent({
          callback: this.backPressCallback
        })
          .margin({ top: this.hasTwoSimCard ? 16 : 12 })
      }
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius($r('sys.float.corner_radius_level10'))
    }
  }

  @Builder
  rankSubHeader() {
    SubHeader({
      secondaryTitle: this.rankOfThisMonth,
      operationType: OperationType.TEXT_ARROW,
      contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) },
      operationItem: AppStorage.get<boolean>('showNetworkChoice') ? [{
        value: $r('app.string.more'),
        action: () => {
          this.modeSelectedIndexes = [AppStorage.get<boolean>('showNetworkChoice') ? 0 : 1]
          this.pageInfos.pushPath({ name: NavEntryKey.RANK_PAGE })
          this.directShowMobilePage = false;
        }
      }] : []
    })
      .visibility(this.searchMode === SearchMode.NOT_SEARCHING ? Visibility.Visible : Visibility.Hidden)
  }

  onSegmentButtonIndexChanged() {
    this.trafficLoadingFinished = LoadingFinished.NONE;
    this.trafficDisplayViewModel.changeCurrentSlotId(this.simSelectedIndexes[0]);
    this.trafficDisplayViewModel.fetchTrafficDisplayStatus();
    this.mPresenter.getAllAppTraffics(0, this.simSelectedIndexes[0], (data: AllAppInfoList) => {
      if (!data) {
        LogUtil.info(TAG, 'onSegmentButtonIndexChanged getAllAppTraffics data is empty');
        return;
      }
      if (data.slotId !== this.simSelectedIndexes[0]) {
        LogUtil.info(TAG,
          `result not match, current slotid: ${this.simSelectedIndexes[0]}, result slotid: ${data.slotId}`);
        return;
      }
      this.totalCount = data.appList.length;
      this.mPresenter.appListShow.refresh(data.appList);
      this.uninstalledAppsFlows = getFlowText(data.uninstalledAppsFlows)[0] + ' ' +
      getFlowText(data.uninstalledAppsFlows)[1];
      this.uninstalledAppsFlowsNum = data.uninstalledAppsFlows;
      this.sysServiceList = data.sysServiceList;
      this.updateOtherMobileInfo();
      this.trafficLoadingFinished = LoadingFinished.FINISHED;
      if (data.appList.length > 0) {
        DotUtil.getInstance().dotStatisticDetails(data.appList, NetworkType.MOBILE);
      }
      if (this.sysServiceList.size > 0) {
        DotUtil.getInstance()
          .reportSystemAndServiceDataRankStatus(this.sysServiceList, NetworkType.MOBILE);
      }
      LogUtil.info(TAG, 'click two card slot id :' + this.simSelectedIndexes[0]);
    })
  }

  private updateOtherMobileInfo() {
    this.othersMobileInfo.listShow = this.mPresenter.appListShow;
    this.othersMobileInfo.sysServiceList = this.sysServiceList;
    this.othersMobileInfo.uninstalledAppsFlowsNum = this.uninstalledAppsFlowsNum;
    this.othersMobileInfo.uninstalledAppsFlows = this.uninstalledAppsFlows;
    this.othersMobileInfo.totalCount = this.totalCount;
  }

  private getNavPathStack(): NavPathStack {
    let stack = this.storage?.get<NavPathStack>(Keys.PAGE_INFOS);
    if (!stack) {
      stack = new NavPathStack();
    }
    return stack;
  }

  private getDisplayName(showName: string, slotId: number, context: myCommon.UIAbilityContext) {
    let operatorName = radio.getOperatorNameSync(slotId);
    LogUtil.info(TAG, `operatorName for slotId=${slotId} is: ${operatorName}`);
    return this.disPlaySimCardInfo.getNetWorkDisplayName(context, slotId, operatorName, showName);
  }

  private handleCommonListClickEvent(entryKey: NavEntryKey) {
    // 应用联网和套餐设置 只有主空间才允许操作
    if ((entryKey === NavEntryKey.MORE_SETTINGS_PAGE || entryKey === NavEntryKey.CONNECTION_PAGE) &&
      this.userID !== DEFAULT_USERID) {
      try {
        this.getUIContext().getPromptAction().showToast({
          message: $r('app.string.forbid_operation'),
          duration: 2000
        })
      } catch (e) {
        LogUtil.error(TAG, `push page failed, code: ${e?.code}, message: ${e?.message}`)
      }
      return;
    }
    this.pageInfos.pushPath({ name: entryKey })
  }

  getNaviPadding(direction: string): LengthMetrics {
    let margin = CallColumnUtils.getInstance().getNaviPaddingSpace(direction);
    return LengthMetrics.resource(margin);
  }
}

