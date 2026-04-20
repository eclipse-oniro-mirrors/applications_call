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
import {
  ItemRestriction,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem
} from '@ohos.arkui.advanced.SegmentButton';
import { AppInfo } from '../viewmodel/AppInfo';
import {
  Keys,
  NetworkType,
  SearchMode,
  SEARCH_TITLE_START_MARGIN,
  SEARCH_TITLE_START_MARGIN_PAD
} from '../constants/CommonConstants';
import { EmptyPage, WaitingPage } from '../pages/EmptyPage';
import AppInfoListPresenter from '../presenter/AppInfoListPresenter';
import PageViewModel from '../viewmodel/PageViewModel';
import StringUtil from '../util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import { isTablet } from '../util/DeviceUtil';
import { LogUtil } from '../util/LogUtil';
import { FontScaleState } from '../util/fontScaleState';
import { curves, LengthMetrics } from '@kit.ArkUI';
import { SearchInfo } from '../data/SearchData';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { AppInfoInterface } from '../viewmodel/type';
import VibrationUtils, { VibrationEffect } from '../util/VibrationUtils';
import { constructedImage } from '../view/constructedImage';
import dotCommon, { ToggleState } from '../util/Dot/DotCommon';
import DotUtil from '../util/Dot/DotUtils';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { AccessibilityUtils } from '../util/AccessibilityUtils';
import { TitleParams } from '../view/TitleParams';

// import { HdsNavDestination, HdsNavDestinationAttribute, HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';

const TAG: string = 'ConnectionPage';
const SEARCH_ID = 'ConnectionPageSearch';
const ANIM_DURATION: number = 150;
const CIRCLE_ANIM_DURATION: number = 30;
const SEARCH_BUTTON_ID = 'connectionSearchButton';
const SEARCH_BACK_BUTTON_ID = 'connectionSearchBackButton';

@Component
export struct ConnectionPageComponent {
  scroller: Scroller = new Scroller;
  @Consume('pageInfos') pageInfos: NavPathStack;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State connectionTabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
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
  //搜索功能参数
  @State changeValue: string = ''
  @State submitValue: string = ''
  @State searchMode: number = SearchMode.NOT_SEARCHING
  @State isSearchTitle: boolean = false;
  @State showApps: AppInfo[] = [];
  //开关功能参数
  @State connectionModeSelectedIndexes: number[] = [AppStorage.get<boolean>('showNetworkChoice') ? 0 : 1]
  @State isAllAccessMobile: boolean = false;
  @State isAllAccessWIFI: boolean = false;
  @State isLoadingFinish: boolean = false;
  //字母序参数
  @State isPop: boolean = false;
  @State selectedIndex: number = 0;
  @State alphabetIndex: number[] = new Array(27).fill(-1);
  @State tempIndex: number = 0;
  @State appInfoListPresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
  @State marginValue: number = 0;
  @State showSystemProcess: boolean = false;
  @State isShowCompatibleApp: boolean = false;
  @State loadCoverViewWithAnimate: boolean = true;
  @State isFirstLoadSearchMenu: boolean = false;
  @State allStateChange: boolean = false;
  @State singleStateChange: boolean = false;
  @State titleX: number | string = '40%';
  @State opacityVal: number = 0;
  @State circleOpacityVal: number = 0;
  public storage = LocalStorage.getShared();
  private listScroller: Scroller = new Scroller();
  private alphabet: string[] = ['#', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U',
    'V', 'W', 'X', 'Y', 'Z'];
  private appsLength: number = 0;
  private naviHeight: number = 0;
  controller: SearchController = new SearchController();
  private timeoutId: number = -1;
  private isBackFromSearchModel = false;

  aboutToAppear(): void {
    LogUtil.info(TAG, 'aboutToAppear');
    if (AppStorage.get<number>('naviIndicatorHeight')) {
      this.naviHeight = AppStorage.get<number>('naviIndicatorHeight') as number
    }
    const searchInfo = this.storage?.get<SearchInfo>(Keys.SEARCH_INFO);
    if (searchInfo?.isModeMobile() || searchInfo?.isModeWlan()) {
      this.connectionModeSelectedIndexes[0] = searchInfo.networkType;
    }
  }

  aboutToDisappear(): void {
    if (this.timeoutId !== -1) {
      clearTimeout(this.timeoutId);
    }
  }

  refresh(): void {
    let i = 1
    this.alphabetIndex = new Array(27).fill(-1);
    this.selectedIndex = 0;
    this.appInfoListPresenter.getAllApps(this.showSystemProcess, this.isShowCompatibleApp, (value: AppInfo[]) => {
      this.appInfoListPresenter.allLauncherAppList.refresh(value);
      if (this.searchMode === SearchMode.SearchingResult) {
        this.onChangeSearch(this.changeValue);
      }
      this.appsLength = value.length;
      let allAccessMobile = true;
      let allAccessWIFI = true;
      for (const app of value) {
        if (!app.mobileAccess) {
          allAccessMobile = false;
        }
        if (!app.wifiAccess) {
          allAccessWIFI = false;
        }
        let letter = PageViewModel.getFirstLetter(app.label)
        let indexL = this.alphabet.indexOf(letter)
        if (this.alphabetIndex[indexL] === -1) {
          this.alphabetIndex[indexL] = i
        }
        i++
      }
      this.isAllAccessMobile = allAccessMobile;
      this.isAllAccessWIFI = allAccessWIFI;
      this.isLoadingFinish = true;
    })
  }

  switchSystemProcessDisplayModel() {
    this.showSystemProcess = !this.showSystemProcess;
    this.isLoadingFinish = false;
    this.refresh();
  }

  switchCompatibilityAppDisplayMode() {
    this.isShowCompatibleApp = !this.isShowCompatibleApp;
    this.isLoadingFinish = false;
    this.refresh();
  }

  private backAnimate(): void {
    // title退场动画
    animateTo({ duration: 150, curve: Curve.Sharp }, () => {
      this.titleX = '40%';
      this.opacityVal = 0;
    });
    animateTo({ duration: CIRCLE_ANIM_DURATION, delay: 30, curve: Curve.Sharp }, () => {
      this.circleOpacityVal = 0;
    });
  }

  private generalVerticalMargin() {
    return 16 + this.naviHeight;
  }

  build() {
    NavDestination() {
      // HdsNavDestination() {
      Column() {
        if (this.searchMode === SearchMode.SearchingResult) {
          this.searchResultPart()
        } else {
          this.normalPagePart()
        }
      }
      .width('100%')
      .height('100%')
    }
    .title(this.NavTitleBuilder)
    .menus(this.getNavMenus())
    .hideBackButton(false)
    .onShown(() => {
      LogUtil.info(TAG, 'on shown');
      this.isLoadingFinish = false;
      this.refresh();
    })
    .onBackPressed((): boolean => {
      return this.onBackClick();
    })
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))

    // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  getNavMenus(): Array<NavigationMenuItem> {
    // 如果是搜索模式，不显示右侧菜单
    if (this.isSearchTitle) {
      return [];
    }

    let menus: NavigationMenuItem[] = [
      {
        value: 'search',
        icon: $r('app.media.ic_public_search'),
        isEnabled: true,
        action: () => {
          this.changeValue = '';
          this.searchMode = SearchMode.IN_SEARCHING;
          this.isSearchTitle = true;
          LogUtil.info(TAG, 'searching');
          AccessibilityUtils.sendAccessibilityEvent(SEARCH_BACK_BUTTON_ID);
        }
      },
      {
        value: 'system_process',
        icon: $r('sys.symbol.dot_grid_2x2'),
        isEnabled: true,
        action: () => {
          this.switchSystemProcessDisplayModel();
          LogUtil.info(TAG, `show system processes? ${this.showSystemProcess}`);
        }
      }
    ];

    // 处理兼容应用的动态菜单项
    const showCompatible =
      systemParameterEnhance.getSync('const.netmanager.display_traffic_anco_list', 'false') === 'true';
    if (showCompatible) {
      menus.push({
        value: 'compatible_app',
        icon: $r('sys.symbol.dot_grid_2x2'),
        isEnabled: true,
        action: () => {
          this.switchCompatibilityAppDisplayMode();
          LogUtil.info(TAG, `show campatible apps? ${this.isShowCompatibleApp}`);
        }
      });
    }

    return menus;
  }

  // 统一的标题栏 Builder (替代 searchTitleParam 和 titleParam 的 title/style/bottomBuilder)
  @Builder
  NavTitleBuilder() {
    Column() {
      // --- 第一部分：主标题栏区域 (搜索框 OR 普通标题) ---
      Row() {
        if (this.isSearchTitle) {

          this.searchingTitle()


        } else {

          Text($r('app.string.network_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
      .width('100%')
      .height(56) // 标准高度
      .alignItems(VerticalAlign.Center)
      .padding({
        left: isTablet() ? 24 : 16,
        right: isTablet() ? 24 : 16
      })

      // --- 第二部分：底部扩展区域 (对应 content.bottomBuilder) ---
      // 原逻辑：AppStorage.get<boolean>('showNetworkChoice') ? ...
      if (AppStorage.get<boolean>('showNetworkChoice')) {
        Column() {
          this.bottomBuilder()
        }
        .width('100%')
        .height(56) // 保持原有逻辑的高度
      }
    }
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))

  }

  // private searchTitleParam(): HdsNavigationTitleBarOptions {
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
  //     padding:
  //     {
  //       start: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16),
  //       end: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16)
  //     },
  //     content:
  //     {
  //       title: undefined,
  //       stackBuilder: this.searchingTitle.bind(this),
  //       bottomBuilder: AppStorage.get<boolean>('showNetworkChoice') ? {
  //         builder: (): void => this.bottomBuilder(),
  //         height: 56,
  //       } : undefined,
  //       menu: undefined,
  //       backIcon: {
  //         label: $r('app.string.accessibility_back'),
  //         icon: $r('sys.symbol.chevron_backward'),
  //         isEnabled: true,
  //         action: this.onBackClick,
  //         componentId: SEARCH_BACK_BUTTON_ID
  //       }
  //     },
  //   };
  // }
  //
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
  //       bottomBuilder: AppStorage.get<boolean>('showNetworkChoice') ? {
  //         builder: (): void => this.bottomBuilder(),
  //         height: 56, // 要跟bottomBuilder中高度一致。也可以不一致，不一致的时候bottomBuilder默认在当前height的中间
  //       } : undefined,
  //       title: {
  //         mainTitle: $r('app.string.network_title')
  //       },
  //       menu: {
  //         maxCount: 2,
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
  //         }, {
  //           content: {
  //             label: this.showSystemProcess ? $r('app.string.hide_system_processes') :
  //             $r('app.string.show_system_processes'),
  //             icon: $r('sys.symbol.dot_grid_2x2'),
  //             isEnabled: true,
  //             action: () => {
  //               this.switchSystemProcessDisplayModel();
  //               LogUtil.info(TAG, `show system processes? ${this.showSystemProcess}`);
  //             }
  //           }
  //         },
  //           {
  //           content:
  //           (systemParameterEnhance.getSync('const.netmanager.display_traffic_anco_list', 'false') === 'true') ?
  //           {
  //             label: this.isShowCompatibleApp ? $r('app.string.hide_compatible_apps') :
  //             $r('app.string.show_compatible_apps'),
  //             icon: $r('sys.symbol.dot_grid_2x2'),
  //             isEnabled: true,
  //             action: () => {
  //               this.switchCompatibilityAppDisplayMode();
  //               LogUtil.info(TAG, `show campatible apps? ${this.isShowCompatibleApp}`);
  //             }
  //           } : undefined,
  //         }]
  //       }
  //     }
  //   };
  // }

  onBackClick = () => {
    if (this.searchMode === SearchMode.NOT_SEARCHING) {
      this.backAnimate();
      if (this.storage?.get<SearchInfo>(Keys.SEARCH_INFO)?.isNetworkAccess()) {
        let session: UIExtensionContentSession =
          this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession
        try {
          session?.sendData({ 'action': 'pop' })
        } catch (e) {
          LogUtil.info(TAG, `onBackClick error: ${e?.message}, code: ${e?.code}`)
        }
      } else {
        const popDestinationInfo = this.pageInfos.pop() // 弹出路由栈栈顶元素
        LogUtil.log(TAG, 'pop' + JSON.stringify(popDestinationInfo))
      }
    } else {
      this.searchMode = SearchMode.NOT_SEARCHING;
      this.isSearchTitle = false;
      AccessibilityUtils.sendAccessibilityEvent(SEARCH_BUTTON_ID);
    }
    return true
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
        .defaultFocus(true)
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
    .height(56)
  }

  onChangeSearch = (value: string) => {
    this.changeValue = value
    if (!value) {
      this.loadCoverViewWithAnimate = false;
      this.searchMode = SearchMode.IN_SEARCHING
      this.checkShouldFocus(this.isLoadingFinish);
      return
    }
    let actualApps = this.appInfoListPresenter.allLauncherAppList.getAllData();
    this.showApps = actualApps?.filter((data) => {
      return StringUtil.isIncluded(data.label, value);
    })
    this.searchMode = SearchMode.SearchingResult
    this.checkShouldFocus(this.isLoadingFinish);
  }

  private checkShouldFocus(shouldFocus: boolean) {
    if (shouldFocus) {
      focusControl.requestFocus(SEARCH_ID);
    }
  }

  @Builder
  searchResultShowList() {
    List({ scroller: this.scroller }) {
      ListItemGroup() {
        ForEach(this.showApps, (item: AppInfo, index: number) => {
          ListItem() {
            this.connectionItem({ appInfo: item, index: index }, false)
          }
          .width('100%')
        }, (item: number, index?: number) => index + JSON.stringify(item))
      }
      .borderRadius(20)
      .padding({
        top: 4,
        bottom: 4,
        left: 12,
        right: 12
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .divider({
        strokeWidth: '1px',
        startMargin: 64,
        color: $r('sys.color.ohos_id_color_list_separator')
      })
      .margin({
        bottom: this.generalVerticalMargin()
      })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .clip(false)
  }

  @Builder
  searchResultPart() {
    if (this.isLoadingFinish) {
      if (this.showApps?.length === 0) {
        EmptyPage({ paddingNum: this.generalVerticalMargin() })
      } else {
        Stack({ alignContent: Alignment.End }) {
          Column() {
            this.searchResultShowList()
          }
          .width('100%')
          .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16 });

          ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
            .margin({ top: 12, bottom: this.generalVerticalMargin() });
        }
        .margin({ top: 8 })
        .layoutWeight(1);
      }
    } else {
      WaitingPage({ paddingNum: this.generalVerticalMargin() });
    }
  }

  @Builder
  normalPagePart() {
    Stack() {
      Column() {
        this.showConnectionList()
      }
      .width('100%')
      .layoutWeight(1)

      if (this.searchMode === SearchMode.IN_SEARCHING) {
        Column() {
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('sys.color.background_secondary'))
        .visibility(this.searchMode === SearchMode.IN_SEARCHING ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.controller.stopEditing();
        })
        .transition(this.loadCoverViewWithAnimate ?
          TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.EaseInOut }) :
          TransitionEffect.IDENTITY)
        .onAppear(() => {
          this.loadCoverViewWithAnimate = true;
        })
      }
    }.alignContent(Alignment.TopStart)
    .layoutWeight(1)
    .accessibilityGroup(this.searchMode === SearchMode.NOT_SEARCHING ? false : true)
    .accessibilityLevel(this.searchMode === SearchMode.NOT_SEARCHING ? 'yes' : 'no')
  }

  @Builder
  bottomBuilder() {
    SegmentButton({
      options: this.connectionTabOptions,
      selectedIndexes: $connectionModeSelectedIndexes
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
  }

  @Builder
  showConnectionList() {
    if (this.isLoadingFinish) {
      Column() {
        this.ConnectionArea();
      }
      .layoutWeight(1)
      .padding({ start: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16), end: LengthMetrics.vp(24) })
      .margin({ top: 8 })
    } else {
      WaitingPage({ paddingNum: this.generalVerticalMargin() });
    }
  }

  @Builder
  connectionItem(item: AppInfoInterface, addDivider: boolean = true) {
    Column() {
      Row() {
        Row() {
          constructedImage({ appInfo: item.appInfo });
          Row() {
            Text(item.appInfo.label)
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Medium)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
          }.margin({ start: LengthMetrics.vp(16) })
          .width(`calc(100% - 78vp)`)
        }
        .width(`calc(100% - 36vp)`)
        .padding({
          top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '10vp'),
          bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '11vp'),
        })

        this.toggleBuilder(item.appInfo)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minHeight: 64 })

      if (item.index < this.appsLength - 1 && addDivider) {
        Divider()
          .color($r('sys.color.ohos_id_color_list_separator'))
          .height('1px')
          .margin({ start: LengthMetrics.vp(64) })
      }
    }
    .width('100%')
    .accessibilityGroup(true)
  }

  onAllAccessChange = (isOn: boolean) => {
    if (isOn) {
      for (const app of this.appInfoListPresenter.allLauncherAppList.getAllData()) {
        this.connectionModeSelectedIndexes[0] === 0 ? app.changeMobileAccess(isOn, app) :
          app.changeWifiAccess(isOn, app);
        this.appInfoListPresenter.refreshAccessByUid(app.uid, app.wifiAccess,
          app.mobileAccess);
      }
    } else {
      if (this.connectionModeSelectedIndexes[0] === 0 && this.isAllAccessMobile) {
        for (const app of this.appInfoListPresenter.allLauncherAppList.getAllData()) {
          app.changeMobileAccess(isOn, app);
          this.appInfoListPresenter.refreshAccessByUid(app.uid, app.wifiAccess,
            app.mobileAccess);
        }
      }
      if (this.connectionModeSelectedIndexes[0] === 1 && this.isAllAccessWIFI) {
        for (const app of this.appInfoListPresenter.allLauncherAppList.getAllData()) {
          app.changeWifiAccess(isOn, app);
          this.appInfoListPresenter.refreshAccessByUid(app.uid, app.wifiAccess,
            app.mobileAccess);
        }
      }
    }
    if (this.allStateChange) {
      this.dotAllAccessChange(isOn);
    }
    this.connectionModeSelectedIndexes[0] === 0 ? this.isAllAccessMobile = isOn : this.isAllAccessWIFI = isOn;
  }
  onChangeToggle = (isOn: boolean, appInfo: AppInfo) => {
    this.connectionModeSelectedIndexes[0] === 0 ? appInfo.changeMobileAccess(isOn, appInfo) :
      appInfo.changeWifiAccess(isOn, appInfo);
    this.appInfoListPresenter.refreshItemAccessByUid(appInfo.uid as number,
      appInfo.wifiAccess, appInfo.mobileAccess);
    let mobileCounter = 0;
    let wifiCounter = 0;
    for (const app of this.appInfoListPresenter.allLauncherAppList.getAllData()) {
      if (!app.mobileAccess) {
        break;
      }
      mobileCounter++;
    }
    this.isAllAccessMobile = (mobileCounter === this.appsLength);
    for (const app of this.appInfoListPresenter.allLauncherAppList.getAllData()) {
      if (!app.wifiAccess) {
        break;
      }
      wifiCounter++;
    }
    this.isAllAccessWIFI = (wifiCounter === this.appsLength);
  }

  @Builder
  toggleBuilder(appInfo: AppInfo) {
    Toggle({
      type: ToggleType.Switch,
      isOn: this.connectionModeSelectedIndexes[0] === 0 ?
        (this.isAllAccessMobile || appInfo.mobileAccess) :
        (this.isAllAccessWIFI || appInfo.wifiAccess)
    })
      .hoverEffect(HoverEffect.Auto)
      .enabled(this.connectionModeSelectedIndexes[0] === 0 ? !appInfo.mobilePolicyApp : !appInfo.wlanPolicyApp)
      .margin(0)
      .onChange(isOn => {
        this.onChangeToggle(isOn, appInfo)
        if (this.singleStateChange) {
          this.dotSingleAccessChange(isOn, appInfo);
        }
      })
      .onClick(() => {
        this.singleStateChange = true;
      })
      .accessibilityLevel(this.searchMode === SearchMode.IN_SEARCHING ? 'no' : 'yes')
  }

  private dotSingleAccessChange(isOn: boolean, appInfo: AppInfo) {
    if (this.connectionModeSelectedIndexes[0] === NetworkType.MOBILE) {
      //切换移动数据开关打点
      DotUtil.getInstance()
        .reportChangeMobileDataNetworkToggle(appInfo.bundleName, isOn ? ToggleState.OPEN : ToggleState.CLOSE);
    } else {
      //切换WLAN开关打点
      DotUtil.getInstance()
        .reportChangeWlanNetworkToggle(appInfo.bundleName, isOn ? ToggleState.OPEN : ToggleState.CLOSE);
    }
    this.singleStateChange = false;
  }

  @Builder
  ItemHead() {
    Column() {
      this.listHead()
      Divider()
        .color($r('sys.color.ohos_id_color_list_separator'))
        .height('1px')
    }
  }

  @Builder
  listHead() {
    Row() {
      Text($r('app.string.all'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({
          top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '10vp'),
          bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '11vp'),
        })

      Toggle({
        type: ToggleType.Switch,
        isOn: this.connectionModeSelectedIndexes[0] === 0 ? this.isAllAccessMobile : this.isAllAccessWIFI
      })
        .onChange(isOn => {
          this.onAllAccessChange(isOn)
        })
        .margin(0)
        .onClick(() => {
          this.allStateChange = true;
        })
        .accessibilityLevel(this.searchMode === SearchMode.IN_SEARCHING ? 'no' : 'yes')
    }
    .margin({ top: 4 })
    .width('100%')
    .constraintSize({ minHeight: 48 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .accessibilityGroup(true)
  }

  private dotAllAccessChange(isOn: boolean) {
    if (isOn) {
      //打开全部开关打点
      if (this.connectionModeSelectedIndexes[0] === NetworkType.MOBILE) {
        DotUtil.getInstance()
          .reportChangeMobileDataNetworkToggle(dotCommon.allBundleNames.TOGGLE_MOBILEDATA_ALL, ToggleState.OPEN);
      } else {
        DotUtil.getInstance()
          .reportChangeWlanNetworkToggle(dotCommon.allBundleNames.TOGGLE_WLAN_ALL, ToggleState.OPEN);
      }
    } else {
      if (this.connectionModeSelectedIndexes[0] === NetworkType.MOBILE && this.isAllAccessMobile) {
        //关闭全部移动数据开关打点
        DotUtil.getInstance()
          .reportChangeMobileDataNetworkToggle(dotCommon.allBundleNames.TOGGLE_MOBILEDATA_ALL, ToggleState.CLOSE);
      }
      if (this.connectionModeSelectedIndexes[0] === NetworkType.WLAN && this.isAllAccessWIFI) {
        //关闭全部WLAN开关打点
        DotUtil.getInstance()
          .reportChangeWlanNetworkToggle(dotCommon.allBundleNames.TOGGLE_WLAN_ALL, ToggleState.CLOSE);
      }
    }
    this.allStateChange = false;
  }

  @Builder
  ConnectionArea() {
    Row() {
      this.connectionAreaShowList()

      AlphabetIndexer({ arrayValue: this.alphabet, selected: this.selectedIndex })
        .selectedColor($r('sys.color.ohos_id_color_text_primary_activated'))// 选中项文本颜色
        .popupColor($r('sys.color.ohos_id_color_text_primary_activated'))// 弹出框文本颜色
        .usingPopup(this.isPop)// 是否显示弹出框
        .selectedFont({ weight: FontWeight.Medium })// 选中项字体样式
        .popupFont({ size: $r('sys.float.ohos_id_text_size_headline7'), weight: FontWeight.Medium })// 弹出框内容的字体样式
        .popupSelectedColor($r('sys.color.ohos_id_color_emphasize'))
        .popupPosition({ x: '48vp' })
        .alignStyle(IndexerAlign.Right)// 弹出框在索引条右侧弹出
        .onSelect((index: number) => {
          this.tempIndex = this.alphabetIndex[index];
          if (this.alphabetIndex[index] != -1) {
            this.listScroller.scrollToIndex(this.alphabetIndex[index] as number)
          }
          VibrationUtils.onceVibration(VibrationEffect.Light);
        })
        .onTouch((event) => {
          if (event?.type === TouchType.Down) {
            this.isPop = true;
          }
        })
        .margin({ top: 8 })
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
  }

  @Builder
  connectionAreaShowList() {
    Column() {
      List({ scroller: this.listScroller }) {
        ListItem() {
          this.ItemHead();
        }
        .padding({
          left: 12,
          right: 12
        })
        .border({ radius: { topLeft: 20, topRight: 20 } })
        .backgroundColor($r('sys.color.comp_background_list_card'));

        this.forEachShow()
      }
      .clip(false)
      .contentEndOffset(this.generalVerticalMargin())
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .onScrollIndex((firstIndex: number, last) => {
        let appIndex = firstIndex - 1;
        if (appIndex < 0 || appIndex >= this.appInfoListPresenter.allLauncherAppList.totalCount()) {
          return;
        }
        try {
          if (this.isPop && appIndex !== this.tempIndex - 1) {
            let letter =
              PageViewModel.getFirstLetter(this.appInfoListPresenter.allLauncherAppList.getData(this.tempIndex -
                1)?.appInfo?.label as string);
            this.selectedIndex = this.alphabet.indexOf(letter) as number;
            return;
          }
          let letter =
            PageViewModel.getFirstLetter(
              this.appInfoListPresenter.allLauncherAppList.getData(appIndex)?.appInfo?.label as string);
          this.selectedIndex = this.alphabet.indexOf(letter) as number;
        } catch (e) {
          LogUtil.error(TAG, 'scroll index error ' + e);
        }
      })
      .onScrollStart(() => {
        this.isPop = false;
      });
    }
  }

  @Builder
  forEachShow() {
    LazyForEach(this.appInfoListPresenter.allLauncherAppList, (item: AppInfoInterface) => {
      ListItem() {
        this.connectionItem(item);
      }
      .padding({
        left: 12,
        right: 12
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .width('100%')
      .border({
        radius: {
          bottomLeft: item.index === (this.appsLength - 1) ? 20 : 0,
          bottomRight: item.index === (this.appsLength - 1) ? 20 : 0
        }
      });
    }, (item: AppInfoInterface, index?: number) => index + JSON.stringify(item))
  }
}

