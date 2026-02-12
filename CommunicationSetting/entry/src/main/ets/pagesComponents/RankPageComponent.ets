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
import {
  ItemRestriction,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem
} from '@ohos.arkui.advanced.SegmentButton';
import {
  getFlowText,
  Keys,
  LoadingFinished,
  NavEntryKey,
  NetworkType,
  SearchMode,
  SEARCH_TITLE_START_MARGIN,
  SEARCH_TITLE_START_MARGIN_PAD,
} from '../constants/CommonConstants';
import { AppInfo } from '../viewmodel/AppInfo';
import { AppRankItemComponent } from '../view/AppRankItemComponent';
import { EmptyAPPRank, EmptyPage, WaitingPage } from '../pages/EmptyPage';
import AppInfoListPresenter, { AllAppInfoList } from '../presenter/AppInfoListPresenter';
import StringUtil from '../util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import { isTablet } from '../util/DeviceUtil';
import AppInfoListDataSource from '../viewmodel/AppInfoListDataSource';
import { AppInfoInterface } from '../viewmodel/type';
import { LogUtil } from '../util/LogUtil';
import { FontScaleState } from '../util/fontScaleState';
import { LengthMetrics } from '@kit.ArkUI';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { SearchInfo } from '../data/SearchData';
import { CommonListComponent } from '../view/CommonListComponent';
import DotUtil from '../util/Dot/DotUtils';
import { AccessibilityUtils } from '../util/AccessibilityUtils';
// import { HdsNavDestination, HdsNavDestinationAttribute, HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';
import { TitleParams } from '../view/TitleParams';

const SEARCH_ID = 'RankSearch'
const TAG = 'RankPage'
const SEARCH_BUTTON_ID = 'rankSearchButton';
const SEARCH_BACK_BUTTON_ID = 'rankSearchBackButton';

export class SysAndUninstallAppsInfo {
  public listShow: AppInfoListDataSource = new AppInfoListDataSource();
  public sysServiceList: Map<number, number> = new Map<number, number>();
  public uninstalledAppsFlowsNum: number = 0;
  public uninstalledAppsFlows: string = '';
  public totalCount: number = 0;
}

@Component
export struct RankPageComponent {
  @Consume('pageInfos') pageInfos: NavPathStack;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State rankTabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: $r('app.string.mobile_data') },
      { text: $r('app.string.wlan') }] as ItemRestriction<SegmentButtonTextItem>,
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
  @Consume @Watch('onSegmentButtonIndexChanged') modeSelectedIndexes: number[];
  @Provide showNetworkText: boolean = false;
  //搜索功能参数
  @State changeValue: string = '';
  @State submitValue: string = '';
  @State searchMode: number = SearchMode.NOT_SEARCHING;
  @State isSearchTitle: boolean = false;
  @State showApps: Array<AppInfo> = [];
  @State mPresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
  @State showSystem: boolean = false;
  @State showUninstalledApps: boolean = false;
  @Watch('wlanInfoLoadingFinished') @State wlanLoadingFinished: number = LoadingFinished.NONE;
  @Consume totalCount: number;
  @Consume simSelectedIndexes: number[];
  @Consume uninstalledAppsFlows: string;
  @Consume uninstalledAppsFlowsNum: number;
  @Consume sysServiceString: string;
  @Consume uninstalledString: string;
  @Consume sysServiceList: Map<number, number>;
  @Consume othersMobileInfo: SysAndUninstallAppsInfo;
  // 切换界面时，当数据加载完毕后，showWlan随之变换，与实时数据modeSelectedIndexes不同
  @Consume showWlan: boolean;
  @Consume directShowMobilePage: boolean;
  @State fromSearch: boolean = false;
  @Watch('searchPageLoading') @Consume trafficLoadingFinished: number;
  @State backClick: boolean = false;
  @State loadCoverViewWithAnimate: boolean = true;
  scroller: Scroller = new Scroller;
  private naviHeight: number = 0;
  private othersWlanInfo: SysAndUninstallAppsInfo = new SysAndUninstallAppsInfo();
  private storage = LocalStorage.getShared();
  controller: SearchController = new SearchController();
  private isBackFromSearchModel = false;

  aboutToAppear() {
    const searchInfo = this.storage?.get<SearchInfo>(Keys.SEARCH_INFO);
    if (searchInfo?.isDataRankings()) {
      this.fromSearch = true;
      if (searchInfo?.networkType !== undefined && searchInfo?.isNetworkTypeValueAble()) {
        this.modeSelectedIndexes[0] = searchInfo?.networkType;
      }
    }
    if (AppStorage.get<number>('naviIndicatorHeight')) {
      this.naviHeight = AppStorage.get<number>('naviIndicatorHeight') as number;
    }
    LogUtil.info(TAG, `showWlan: ${this.showWlan}, trafficLoadingFinished: ${this.trafficLoadingFinished},
     modeSelectedIndexes[0]: ${this.modeSelectedIndexes[0]}`);
  }

  build() {
    NavDestination() {
      // HdsNavDestination() {
        if (this.searchMode === SearchMode.SearchingResult) {
        this.searchResultPart()
      } else {
        this.normalPagePart()
      }
    }
    .title(this.NavTitleBuilder)
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .onBackPressed((): boolean => {
      return this.onBackClick();
    })
    .onShown(() => {
      if (this.directShowMobilePage && !this.showWlan) {
        return;
      }
      this.mPresenter.getAllAppTraffics(1, this.simSelectedIndexes[0], (data: AllAppInfoList) => {
        if (!data) {
          LogUtil.info(TAG, 'onShown getAllAppTraffics data is empty.');
          return;
        }
        if (data.slotId !== this.simSelectedIndexes[0]) {
          LogUtil.info(TAG,
            `result not match, current slotid: ${this.simSelectedIndexes[0]}, result slotid: ${data.slotId}`);
          return;
        }
        this.othersWlanInfo.listShow.refresh(data.appList);
        this.othersWlanInfo.totalCount = data.appList.length;
        this.othersWlanInfo.uninstalledAppsFlows = getFlowText(data.uninstalledAppsFlows)[0] + ' ' +
        getFlowText(data.uninstalledAppsFlows)[1];
        this.othersWlanInfo.uninstalledAppsFlowsNum = data.uninstalledAppsFlows;
        this.othersWlanInfo.sysServiceList = data.sysServiceList;
        this.wlanLoadingFinished = LoadingFinished.FINISHED;
        if (data.appList.length > 0 && this.showWlan) {
          DotUtil.getInstance().dotStatisticDetails(data.appList, NetworkType.WLAN);
        }
        if (this.othersWlanInfo.sysServiceList.size > 0 && this.showWlan) {
          DotUtil.getInstance()
            .reportSystemAndServiceDataRankStatus(this.othersWlanInfo.sysServiceList, NetworkType.WLAN);
        }
      })
    })
    .onHidden(() => {
      this.directShowMobilePage = true;
      this.wlanLoadingFinished = LoadingFinished.HIDDEN;
    })
  }
  @Builder
  NavTitleBuilder() {
    Column() {
      Row() {
        if (this.isSearchTitle) {
         this.searchingTitle()
        } else {
          Text($r('app.string.traffic_ranking'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Image($r('app.media.ic_public_search'))
            .width(24)
            .height(24)
            .fillColor($r('sys.color.ohos_id_color_primary'))
            .onClick(() => {
              // 切换到搜索模式
              this.changeValue = '';
              this.searchMode = SearchMode.IN_SEARCHING;
              this.isSearchTitle = true;
              LogUtil.info(TAG, 'searching');
              AccessibilityUtils.sendAccessibilityEvent(SEARCH_BACK_BUTTON_ID);
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

      if (!this.isSearchTitle) {
        Column() {
          this.bottomBuilder()
        }
        .width('100%')
        .height(56) // 保持原高度
        .justifyContent(FlexAlign.Center)
      }
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
  //       bottomBuilder: {
  //         builder: (): void => this.bottomBuilder(),
  //         height: 56, // 要跟bottomBuilder中高度一致。也可以不一致，不一致的时候bottomBuilder默认在当前height的中间
  //       },
  //       title: {
  //         mainTitle: $r('app.string.traffic_ranking')
  //       },
  //       menu: {
  //         value: [{
  //           content: {
  //             label: $r('app.string.searching'),
  //             icon: $r('app.media.ic_public_search'),
  //             isEnabled: true,
  //             action: () => {
  //               this.changeValue = '';
  //               this.searchMode = SearchMode.IN_SEARCHING;
  //               this.isSearchTitle = true;
  //               LogUtil.info(TAG, 'searching');
  //               AccessibilityUtils.sendAccessibilityEvent(SEARCH_BACK_BUTTON_ID);
  //             },
  //             componentId: SEARCH_BUTTON_ID
  //           },
  //         }]
  //       }
  //     }
  //   };
  // }

  searchPageLoading() {
    if (this.fromSearch && this.directShowMobilePage && !this.showWlan &&
      this.trafficLoadingFinished === LoadingFinished.FINISHED) {
      this.mPresenter.getAllAppTraffics(1, this.simSelectedIndexes[0], (data: AllAppInfoList) => {
        if (!data) {
          LogUtil.info(TAG, 'searchPageLoading getAllAppTraffics data is empty.');
          return;
        }
        if (data.slotId !== this.simSelectedIndexes[0]) {
          LogUtil.info(TAG,
            `result not match, current slotid: ${this.simSelectedIndexes[0]}, result slotid: ${data.slotId}`);
          return;
        }
        this.othersWlanInfo.listShow.refresh(data.appList);
        this.othersWlanInfo.totalCount = data.appList.length;
        this.othersWlanInfo.uninstalledAppsFlows = getFlowText(data.uninstalledAppsFlows)[0] + ' ' +
        getFlowText(data.uninstalledAppsFlows)[1];
        this.othersWlanInfo.uninstalledAppsFlowsNum = data.uninstalledAppsFlows;
        this.othersWlanInfo.sysServiceList = data.sysServiceList;
        this.wlanLoadingFinished = LoadingFinished.FINISHED;
      })
    }
  }

  @Builder
  searchResultPart() {
    if (this.showApps?.length === 0 && !this.showSystem && !this.showUninstalledApps) {
      EmptyPage({ paddingNum: 16 + this.naviHeight });
    } else {
      Stack({ alignContent: Alignment.End }) {
        this.searchResultShowList();
      }
      .margin({ top: 16 })
      .layoutWeight(1);
    }
  }

  @Builder
  normalPagePart() {
    Stack() {
      Column() {
        // 当前所处的移动数据 或者 WLAN界面未加载出数据
        if ((!this.showWlan && this.trafficLoadingFinished === LoadingFinished.NONE &&
          this.modeSelectedIndexes[0] === NetworkType.MOBILE) ||
          (!this.showWlan && this.wlanLoadingFinished === LoadingFinished.NONE &&
            this.modeSelectedIndexes[0] === NetworkType.WLAN)) {
          WaitingPage();
        } else {
          if (this.totalCount + this.sysServiceList.size > 0) {
            this.showNormalPageList()
          } else {
            EmptyAPPRank({ paddingNum: 16 + this.naviHeight });
          }
        }
      }
      .margin({ top: 8 })
      .width('100%');

      if (this.searchMode === SearchMode.IN_SEARCHING) {
        Column() {
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
        .visibility(this.searchMode === SearchMode.IN_SEARCHING ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.controller.stopEditing();
        })
        .transition(this.loadCoverViewWithAnimate ? TransitionEffect.OPACITY.animation({ duration: 200 }) :
        TransitionEffect.IDENTITY)
        .onAppear(() => {
          this.loadCoverViewWithAnimate = true;
        })
        .accessibilityLevel('no')
      }
    }.alignContent(Alignment.Top)
    .layoutWeight(1)
    .accessibilityGroup(this.searchMode === SearchMode.NOT_SEARCHING ? false : true)
    .accessibilityLevel(this.searchMode === SearchMode.NOT_SEARCHING ? 'yes' : 'no')
  }

  @Builder
  bottomBuilder() {
    SegmentButton({
      options: this.rankTabOptions,
      selectedIndexes: $modeSelectedIndexes
    })
      .constraintSize({ minHeight: 56 })
      .padding({
        top: 8,
        bottom: 8,
        left: isTablet() ? 24 : 16,
        right: isTablet() ? 24 : 16
      })
      .defaultFocus(false)
      .focusable(false)
      .visibility(AppStorage.get<boolean>('showNetworkChoice') ? Visibility.Visible : Visibility.None)
  }

  @Builder
  showNormalPageList() {
    Stack({ alignContent: Alignment.End }) {
      Column() {
        if (this.showWlan && this.wlanLoadingFinished !== LoadingFinished.NONE) {
          this.getAppList(this.othersWlanInfo.listShow);
        } else {
          this.getAppList(this.othersMobileInfo.listShow);
        }
      }
      .width('100%')
      .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16 });

      ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .margin({ top: 12, bottom: 16 + this.naviHeight });
    }
    .layoutWeight(1)
  }

  // 防止第一次快速切换未获得数据&后台返回更新
  wlanInfoLoadingFinished() {
    if (this.modeSelectedIndexes[0] !== 0 && this.wlanLoadingFinished !== LoadingFinished.NONE &&
      this.totalCount !== this.othersWlanInfo.totalCount) {
      this.updateOthersWlanInfo();
    }
  }

  onSegmentButtonIndexChanged() {
    if (this.modeSelectedIndexes[0] !== 0 && this.wlanLoadingFinished !== LoadingFinished.NONE) {
      this.updateOthersWlanInfo();
    } else {
      this.sysServiceList = this.othersMobileInfo.sysServiceList;
      this.uninstalledAppsFlows = this.othersMobileInfo.uninstalledAppsFlows;
      this.uninstalledAppsFlowsNum = this.othersMobileInfo.uninstalledAppsFlowsNum;
      this.totalCount = this.othersMobileInfo.totalCount;
      if (this.totalCount > 0 && !(this.backClick && this.fromSearch)) {
        let data = this.othersMobileInfo.listShow.getAllData();
        DotUtil.getInstance().dotStatisticDetails(data, NetworkType.MOBILE);
      }
      this.showWlan = false;
      if (this.sysServiceList.size > 0) {
        DotUtil.getInstance()
          .reportSystemAndServiceDataRankStatus(this.sysServiceList, NetworkType.MOBILE);
      }
    }
  }

  private updateOthersWlanInfo() {
    this.sysServiceList = this.othersWlanInfo.sysServiceList;
    this.uninstalledAppsFlows = this.othersWlanInfo.uninstalledAppsFlows;
    this.uninstalledAppsFlowsNum = this.othersWlanInfo.uninstalledAppsFlowsNum;
    this.totalCount = this.othersWlanInfo.totalCount;
    if (this.totalCount > 0 && !(this.backClick && this.fromSearch)) {
      let data = this.othersWlanInfo.listShow.getAllData();
      DotUtil.getInstance().dotStatisticDetails(data, NetworkType.WLAN);
    }
    this.showWlan = true;
    if (this.sysServiceList.size > 0) {
      DotUtil.getInstance()
        .reportSystemAndServiceDataRankStatus(this.sysServiceList, NetworkType.WLAN);
    }
  }

  @Builder
  backButton(id: string): void {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .width(24)
        .height(24)
        .draggable(false)
        .fontSize('24vp')
        .fontColor([$r('sys.color.ohos_id_color_primary')])
    }
    .id(id)
    .draggable(false)
    .width('40vp')
    .height('40vp')
    .backgroundColor($r('sys.color.ohos_id_color_text_field_sub_bg'))
    .onClick(() => {
      this.isBackFromSearchModel = this.searchMode === SearchMode.NOT_SEARCHING ? false : true;
      this.onBackClick();
    })
    .accessibilityText($r('app.string.accessibility_back'))
  }

  onBackClick = () => {
    if (this.searchMode === SearchMode.NOT_SEARCHING) {
      this.backClick = true;
      this.modeSelectedIndexes = [0];
      if (this.storage?.get<SearchInfo>(Keys.SEARCH_INFO)?.isDataRankings()) {
        let session: UIExtensionContentSession =
          this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession
        session?.sendData({ 'action': 'pop' })
        return true;
      }
      if (this.modeSelectedIndexes[0] !== 0) {
        this.showWlan = false;
      }
      const popDestinationInfo = this.pageInfos.pop(); // 弹出路由栈栈顶元素
      LogUtil.log(TAG, 'pop' + JSON.stringify(popDestinationInfo));
    } else {
      this.searchMode = SearchMode.NOT_SEARCHING;
      this.isSearchTitle = false;
      AccessibilityUtils.sendAccessibilityEvent(SEARCH_BUTTON_ID);
    }
    return true;
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
          AccessibilityUtils.sendAccessibilityEvent(SEARCH_BACK_BUTTON_ID);
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
        .height(40)
        .accessibilityText(StringUtil.convertResourceToString($r('app.string.searching'),
          getContext(this) as myCommon.UIAbilityContext))
        .placeholderFont({
          size: ($r('sys.float.Body_L')),
          weight: FontWeight.Regular
        })
        .textFont({ size: $r('sys.float.Body_L'), weight: 400 })
        .layoutWeight(1)
    }
  }

  onChangeSearch = (value: string) => {
    this.changeValue = value;
    if (!value) {
      this.loadCoverViewWithAnimate = false;
      this.searchMode = SearchMode.IN_SEARCHING;
      focusControl.requestFocus(SEARCH_ID);
      return;
    }
    let actualAPP: AppInfo[] = [];
    if (!this.showWlan) {
      actualAPP = this.othersMobileInfo.listShow.getAllData();
    } else {
      actualAPP = this.othersWlanInfo.listShow.getAllData();
    }
    this.submitValue = value;
    this.showSystem = StringUtil.isIncluded(this.sysServiceString, value) && this.sysServiceList.size !== 0;
    this.showUninstalledApps =
      StringUtil.isIncluded(this.uninstalledString, value) && this.uninstalledAppsFlowsNum !== 0;
    this.showApps = actualAPP?.filter((data) => {
      return StringUtil.isIncluded(data.label, value);
    })
    this.searchMode = SearchMode.SearchingResult;
    focusControl.requestFocus(SEARCH_ID);
  }

  @Builder
  resultArea(item: AppInfo) {
    ListItem() {
      AppRankItemComponent({ appInfo: item, showNetworkType: false })
    }
    .width('100%')
    .onClick(() => {
      router.pushUrl({
        url: 'pages/SingleAppPage',
        params: {
          appInfo: item,
          slotId: this.simSelectedIndexes[0],
          networkType: this.modeSelectedIndexes[0]
        }
      })
    })
  }

  @Builder
  searchResultShowList() {
    Column() {
      List({ scroller: this.scroller }) {
        ListItemGroup() {
          ForEach(this.showApps, (item: AppInfo) => {
            this.resultArea(item)
          }, (item: AppInfo, index?: number) => index + JSON.stringify(item))
        }
        .padding({
          top: 4,
          bottom: 4,
          left: 4,
          right: 4
        })
        .visibility(this.showApps.length > 0 ? Visibility.Visible : Visibility.None)
        .margin({
          bottom: !this.showUninstalledApps && !this.showSystem ? 16 + this.naviHeight : 0
        })
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .borderRadius('20vp')
        .divider({
          strokeWidth: '1px',
          startMargin: 72,
          endMargin: 8,
          color: $r('sys.color.ohos_id_color_list_separator')
        })

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
                this.pageInfos.pushPath({ name: NavEntryKey.SYS_SERVICE_PAGE })
              }
            })
          }
          .margin({
            top: this.showApps.length > 0 || this.showUninstalledApps ? 12 : 0,
            bottom: 16 + this.naviHeight
          })
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .clip(false)
    }
    .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16 })

    ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
      .margin({ top: 12, bottom: 16 + this.naviHeight });
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
  getAppList(appList: AppInfoListDataSource) {
    List({ scroller: this.scroller }) {
      ListItemGroup() {
        LazyForEach(appList, (item: AppInfoInterface) => {
          ListItem() {
            AppRankItemComponent({ appInfo: item.appInfo, showNetworkType: false })
          }
          .padding({ bottom: (FontScaleState.isStandardGear(this.fontSizeScale) ? 0 : 0.5) })
          .width('100%')
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SingleAppPage',
              params: {
                appInfo: item.appInfo,
                slotId: this.simSelectedIndexes[0],
                networkType: this.modeSelectedIndexes[0]
              }
            })
          })
        }, (item: AppInfoInterface) => {
          return item.appInfo.uid?.toString() +
          item.appInfo.flow.toString() + item.appInfo.wifiAccess + item.appInfo.mobileAccess
        })
      }
      .borderRadius(20)
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
        bottom: this.sysServiceList.size + this.uninstalledAppsFlowsNum === 0 ?
          16 + this.naviHeight : 0
      })
      .visibility(this.totalCount > 0 ? Visibility.Visible : Visibility.None)

      if (this.uninstalledAppsFlowsNum !== 0) {
        ListItemGroup() {
          this.uninstalledApps({
            top: this.totalCount > 0 ? 12 : 0,
            bottom: this.sysServiceList.size === 0 ? 16 + this.naviHeight : 0
          })
        }
      }
      if (this.sysServiceList.size !== 0) {
        ListItemGroup() {
          // 系统与服务
          CommonListComponent({
            name: $r('app.string.system_and_service'),
            onClickCallBack: () => {
              this.pageInfos.pushPath({ name: NavEntryKey.SYS_SERVICE_PAGE })
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
}
