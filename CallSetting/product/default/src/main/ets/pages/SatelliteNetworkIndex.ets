/**
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
  isPhone,
  isSupportCactus,
  isSupportDandelion,
  isSupportPalaceMuseum,
  isSupportSummerPalace,
  isSupportHyacinth
} from '../common/utils/Utils';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { LogUtils, ReportUtil, TitleBarLayout, TitleParams } from '@ohos/common/CommonIndex';
import { DynamicLoader } from '../common/control/DynamicLoader';
import { common } from '@kit.AbilityKit';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { curves, LengthMetrics, router } from '@kit.ArkUI';
import { isTablet } from '../common/utils/Utils';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { CARD_PAGE_MODE, NAVIGATION_MODE } from '../common/constant/CallSettingsConstant';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import HyacinthDataShareManager from '../manager/HyacinthDataShareManager';
// import { NavDestination,  HdsNavDestinationAttribute, NavigationTitleBarOptions } from '@kit.UIDesignKit';

interface RouterParams {
  isPrivacyNote: boolean
}

const TAG = 'SatelliteNetworkIndex';

/**
 * meetime service bundle name
 */
const MEETIME_SERVICE_BUNDLE_NAME = 'com.ohos.meetimeservice';

/**
 * meetime service extension name
 */
const MEETIME_SERVICE_EXTENSION_NAME = 'SmcServiceExtAbility';

/**
 * car satellite bundle name
 */
const CAR_SATELLITE_BUNDLE_NAME = 'com.ohos.carsatelliteassist';

/**
 * car satellite UI ability name
 */
const CAR_SATELLITE_UI_ABILITY_NAME = 'CallingMainUIAbility';

/**
 * car satellite enable setting key
 */
const CAR_SATELLITE_ENABLE_KEY = 'car_satellite_enable';

/**
 * car satellite enable setting value yes
 */
const CAR_SATELLITE_ENABLE_VALUE_YES = '1';

/**
 * car satellite enable setting value no
 */
const CAR_SATELLITE_ENABLE_VALUE_NO = '0';

/**
 * title animation duration
 */
const ANIM_DURATION: number = 150;

/**
 * title circle btn animation duration
 */
const CIRCLE_ANIM_DURATION: number = 30;

PersistentStorage.persistProp('hyacinthActivated', false);

@Entry
@Component
export struct SatelliteNetworkIndex {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @StorageProp('statusBarHeight') statusBarHeight: number = 38;
  public storage = LocalStorage.getShared();
  @Consume('session') session: UIExtensionContentSession;
  private isDivide: number = 1;
  private isNotDivide: number = 0;
  @StorageProp(NAVIGATION_MODE) navigationMode: NavigationMode = this.isNotDivide;
  @StorageLink('titleAnimationDuration') titleAnimationDuration?: number = undefined;
  @StorageProp('pageMode') pageMode: string = '';
  @BuilderParam satelliteCommunicationLoaderLoader: () => void;
  @BuilderParam beiDouSatelliteMessageLoaderLoader: () => void;
  @BuilderParam satelliteServiceUserAgreementLoader: (isPri: boolean) => void;
  @BuilderParam satelliteServicePrivacyStatementLoader: (isPri: boolean) => void;
  @BuilderParam beiDouSatelliteMessagePrivacyLoader: (isPri: boolean) => void;
  @BuilderParam beiDouSatelliteMessageUserAgreementLoader: (isPri: boolean) => void;
  @BuilderParam hyacinthActivateLoader: () => void;
  @BuilderParam hyacinthCommunicationLoader: () => void;
  @BuilderParam hyacinthPrivacyLoader: (isPri: boolean) => void;
  @BuilderParam hyacinthUserAgreementLoader: (isPri: boolean) => void;
  @State isFirst: boolean = true;
  @State titleX: number | string = '40%';
  @State opacityVal: number = 0;
  @State circleOpacityVal: number = 0;
  private isSupportSummerPalaceStatus: boolean = isSupportSummerPalace();
  private isSupportPalaceMuseumStatus: boolean = isSupportPalaceMuseum();
  private hyacinthDataShareManager: HyacinthDataShareManager = HyacinthDataShareManager.getInstance();
  private transitionType: NavigationSystemTransitionType =
    this.navigationMode === NavigationMode.Stack ? NavigationSystemTransitionType.TITLE :
    NavigationSystemTransitionType.NONE;

  async loadPage(key: string): Promise<void> {
    try {
      if (key === 'SatelliteCommunication') {
        let pageObj = await import('../components/SatelliteNetworkCompent/SatelliteCommunication');
        this.satelliteCommunicationLoaderLoader = pageObj.SatelliteCommunicationLoader;
      } else if (key === 'SatelliteServiceUserAgreement') {
        let pageObj = await import('../components/SatelliteNetworkCompent/OnLineSatelliteServicePrivacy');
        this.satelliteServiceUserAgreementLoader = pageObj.OnLineSatelliteServicePrivacyLoader;
      } else if (key === 'SatelliteServicePrivacyStatement') {
        let pageObj = await import('../components/SatelliteNetworkCompent/OnLineSatelliteServicePrivacy');
        this.satelliteServicePrivacyStatementLoader = pageObj.OnLineSatelliteServicePrivacyLoader;
      } else if (key === 'BeiDouSatelliteMessage') {
        let pageObj = await import('../components/SatelliteNetworkCompent/BeiDouSatelliteMessage');
        this.beiDouSatelliteMessageLoaderLoader = pageObj.BeiDouSatelliteMessageLoader;
      } else if (key === 'BeiDouSatelliteMessagePrivacyStatement') {
        let pageObj = await import('../components/SatelliteNetworkCompent/BeiDouSatelliteMessagePrivacy');
        this.beiDouSatelliteMessagePrivacyLoader = pageObj.BeiDouSatelliteMessagePrivacyLoader;
      } else if (key === 'BeiDouSatelliteMessageUserAgreement') {
        let pageObj = await import('../components/SatelliteNetworkCompent/BeiDouSatelliteMessagePrivacy');
        this.beiDouSatelliteMessageUserAgreementLoader = pageObj.BeiDouSatelliteMessagePrivacyLoader;
      } else if (key === 'HyacinthActivate'){
        let pageObj = await import('../components/SatelliteNetworkCompent/HyacinthActivate');
        this.hyacinthActivateLoader = pageObj.HyacinthActivateLoader;
      } else if (key === 'HyacinthCommunication') {
        let pageObj = await import('../components/SatelliteNetworkCompent/HyacinthCommunication');
        this.hyacinthCommunicationLoader = pageObj.HyacinthCommunicationLoader;
      } else if (key === 'HyacinthPrivacyStatement') {
        let pageObj = await import('../components/SatelliteNetworkCompent/HyacinthPrivacy');
        this.hyacinthPrivacyLoader = pageObj.HyacinthPrivacyLoader;
      } else if (key === 'HyacinthUserAgreement') {
        let pageObj = await import('../components/SatelliteNetworkCompent/HyacinthPrivacy');
        this.hyacinthUserAgreementLoader = pageObj.HyacinthPrivacyLoader;
      }
      if (this.isFirst) {
        this.isFirst = false;
      }
    } catch (err) {
      LogUtils.e(TAG, 'loadPage import error');
    }
  }

  @Builder
  myRouter(name: string) {
    if (name === 'SatelliteCommunication') {
      this.satelliteCommunicationLoaderLoader();
    } else if (name === 'SatelliteServiceUserAgreement') {
      this.satelliteServiceUserAgreementLoader(true);
    } else if (name === 'SatelliteServicePrivacyStatement') {
      this.satelliteServicePrivacyStatementLoader(false);
    } else if (name === 'BeiDouSatelliteMessage') {
      this.beiDouSatelliteMessageLoaderLoader();
    } else if (name === 'BeiDouSatelliteMessagePrivacyStatement') {
      this.beiDouSatelliteMessagePrivacyLoader(false);
    } else if (name === 'BeiDouSatelliteMessageUserAgreement') {
      this.beiDouSatelliteMessageUserAgreementLoader(true);
    } else if (name === 'HyacinthActivate') {
      this.hyacinthActivateLoader();
    } else if (name === 'HyacinthCommunication') {
      this.hyacinthCommunicationLoader();
    } else if (name === 'HyacinthPrivacyStatement') {
      this.hyacinthPrivacyLoader(false);
    } else if (name === 'HyacinthUserAgreement') {
      this.hyacinthUserAgreementLoader(true);
    }
  }

  @Builder
  primaryTitle(notificationResource: Resource, titleContent: Resource) {
    Row() {
      Row() {
        Image(notificationResource)
          .width(40)
          .height(40)
          .draggable(false)

        Text(titleContent)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .margin({
            left: 16,
            top: 17,
            bottom: 18,
            right: 8
          })
          .layoutWeight(1)
      }
      .layoutWeight(1)

      Image($r('app.media.ic_public_arrow_right'))
        .fillColor($r('sys.color.ohos_id_color_fourth'))
        .matchTextDirection(true)
        .height($r('app.float.wh_value_24'))
        .width($r('app.float.wh_value_12'))
        .draggable(false);
    }
    .stateStyles({
      normal: this.normalStyles,
      pressed: this.pressedStyles
    })
    .padding({
      left: 12,
      right: 12,
      top: 4,
      bottom: 4
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
  }

  private startSmcServiceExtAbility(): void {
    let want: Want = {
      bundleName: MEETIME_SERVICE_BUNDLE_NAME,
      abilityName: MEETIME_SERVICE_EXTENSION_NAME
    };
    try {
      let context = getContext(this) as common.UIAbilityContext;
      if (!context) {
        LogUtils.e(TAG, 'startSmcServiceExtAbility context is invalid.');
        return;
      }
      context.startAbility(want).then(() => {
        LogUtils.i(TAG, `startSmcServiceExtAbility success.`);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `startSmcServiceExtAbility failed, code: ${error?.code}, message: ${error?.message}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `startSmcServiceExtAbility error, message: ${err?.message}`);
    }
  }

  private startCarSatelliteAbility(): void {
    const want: Want = {
      bundleName: CAR_SATELLITE_BUNDLE_NAME,
      abilityName: CAR_SATELLITE_UI_ABILITY_NAME,
    };
    try {
      const context: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      if (!context) {
        LogUtils.e(TAG, 'startCarSatelliteAbility context is invalid.');
        return;
      }
      context.startAbility(want).then(() => {
        LogUtils.i(TAG, 'startCarSatelliteAbility: start success');
      }).catch((e: BusinessError) => {
        LogUtils.w(TAG, 'startCarSatelliteAbility: start error=' + e?.code);
      });
    } catch (err) {
      LogUtils.e(TAG, `startCarSatelliteAbility error, message: ${err}`);
    }
  }

  private isCarSatelliteEnable(): boolean {
    try {
      let value: string = settings.getValueSync(
        getContext(this), CAR_SATELLITE_ENABLE_KEY, CAR_SATELLITE_ENABLE_VALUE_NO);
      return value === CAR_SATELLITE_ENABLE_VALUE_YES;
    } catch (err) {
      LogUtils.e(TAG, `isCarSatelliteEnable error, message: ${err}`);
    }
    return false;
  }

  @Builder
  subSetings(notificationResource: Resource, titleContent: Resource, subTitle: Resource, onClick?: Function) {
    Column() {
      Column() {
        this.primaryTitle(notificationResource, titleContent);
      }
      .backgroundColor($r('sys.color.ohos_fa_list_card_bg'))
      .borderRadius($r('sys.float.corner_radius_level10'))
      .onClick(() => {
        if (onClick) {
          onClick();
        }
      })

      Text(subTitle)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .margin({ top: 8, left: 12, right: 12 })
        .textAlign(TextAlign.Start)
        .align(Alignment.Start)
        .lineHeight(19)
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
      right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
    })
    .margin({ bottom: $r('app.float.margin_16') })
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius(16)
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .opacity(1)
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  @Styles
  titleStyle() {
    .size({ height: '100%', width: '100%' })
    .padding({
      start: LengthMetrics.vp(isTablet() ? 24 : this.isDivideAndFirst() || DisplayUtil.getFoldStatus() === 1 ? 16 : 0)
    })
  }

  @Builder
  beiDouSubSetings() {
    Column() {
      Column() {
        if (this.isSupportSummerPalaceStatus) {
          Row() {
            this.primaryTitle($r('app.media.meetime_satellite_icon'), $r('app.string.beidou_satellite_message'));
          }
          .margin({top: 4, right: 4})
          .onClick(() => {
            DynamicLoader.getInstance().callFunction('BeiDouSatelliteMessage').then(() => {
              this.pathInfos.pushPathByName('BeiDouSatelliteMessage', '');
            })
          })
        }
        if (this.isSupportSummerPalaceStatus && this.isSupportPalaceMuseumStatus) {
          Row() {
            Row()
              .width(40)

            Divider()
              .color($r('sys.color.comp_divider'))
              .lineCap(LineCapStyle.Butt)
              .padding({
                left: $r('sys.float.padding_level8')
              })
              .margin({ right: 40 })
          }
          .padding({
            left: 12,
            right: 12
          })
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
        }

        if (this.isSupportPalaceMuseumStatus) {
          Row() {
            this.primaryTitle($r('app.media.meetime_satellite_icon'), $r('app.string.meetime_network_title'));
          }
          .margin({right: 4, bottom: 4})
          .onClick(() => {
            this.startSmcServiceExtAbility();
          })
        }
      }
      .backgroundColor($r('sys.color.ohos_fa_list_card_bg'))
      .borderRadius($r('sys.float.corner_radius_level10'))

      Text($r('app.string.meetime_network_descriptions'))
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .margin({ top: 8, left: 12, right: 12 })
        .textAlign(TextAlign.Start)
        .align(Alignment.Start)
        .lineHeight(19)
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
      right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
    })
    .margin({ bottom: $r('app.float.margin_16') })
  }

  @Builder
  satelliteSubSetings() {
    Column() {
      Column() {
        if (isSupportCactus() || isSupportDandelion()) {
          Row() {
            this.primaryTitle($r('app.media.satellite_icon'), $r('app.string.skycom_satellite_communications'));
          }
          .margin({top: 4, right: 4})
          .onClick(() => {
            DynamicLoader.getInstance().callFunction('SatelliteCommunication').then(() => {
              this.pathInfos.pushPathByName('SatelliteCommunication', '');
            })
          })
        }
        if (isSupportHyacinth()) {
          Row() {
            Row()
              .width(40)

            Divider()
              .color($r('sys.color.comp_divider'))
              .lineCap(LineCapStyle.Butt)
              .padding({
                left: $r('sys.float.padding_level8')
              })
              .margin({ right: 40 })
          }
          .padding({
            left: 12,
            right: 12
          })
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
        }

        if (isSupportHyacinth()) {
          Row() {
            this.primaryTitle($r('app.media.hyacinth_index_icon'), $r('app.string.hyacinth_satellite_communications'));
          }
          .margin({right: 4, bottom: 4})
          .onClick(() => {
            ReportUtil.getInstance().reportHyacinthEntrance();
            if (AppStorage.get('hyacinthActivated') as boolean) {
              DynamicLoader.getInstance().callFunction('HyacinthCommunication').then(() => {
                this.pathInfos.pushPathByName('HyacinthCommunication', '');
              })
            } else {
              DynamicLoader.getInstance().callFunction('HyacinthActivate').then(() => {
                this.pathInfos.pushPathByName('HyacinthActivate', '');
              })
            }
          })
        }
      }
      .backgroundColor($r('sys.color.ohos_fa_list_card_bg'))
      .borderRadius($r('sys.float.corner_radius_level10'))

      Text($r('app.string.satellite_service_network_description'))
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .margin({ top: 8, left: 12, right: 12 })
        .textAlign(TextAlign.Start)
        .align(Alignment.Start)
        .lineHeight(19)
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
      right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
    })
    .margin({ bottom: $r('app.float.margin_16') })
  }

  aboutToAppear(): void {
    DynamicLoader.getInstance().register(async (str: string): Promise<void> => {
      return await this.loadPage(str);
    });
    ReportUtil.getInstance();
    ReportUtil.getInstance().satelliteUseStartTime = new Date().valueOf();
    let satelliteServiceUri = AppStorage.get<string>('satelliteServiceUri');
    if (satelliteServiceUri !== null) {
      if (satelliteServiceUri === 'SatelliteNetworkExtensionAbility') {
        DynamicLoader.getInstance().callFunction('SatelliteCommunication').then(() => {
          this.pathInfos.pushPathByName('SatelliteCommunication', '');
        })
      } else if (satelliteServiceUri === 'HyacinthExtensionAbility'){
        DynamicLoader.getInstance().callFunction('HyacinthCommunication').then(() => {
          this.pathInfos.pushPathByName('HyacinthCommunication', '');
        })
      } else if (satelliteServiceUri === 'SatelliteCommunication') {
        DynamicLoader.getInstance().callFunction('SatelliteCommunication').then(() => {
          this.pathInfos.pushPathByName('SatelliteCommunication', '');
        })
      }
      AppStorage.delete('satelliteServiceUri');
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, `aboutToDisappear`);
    this.hyacinthDataShareManager.removeHyacinthDataShareListener();
  }

  @Builder
  CustomSettingsNavBar() {
    Row() {
      if (this.isDivideAndFirst()) {
        this.backButton();
      }
      // normal title
      Text($r('app.string.satellite_network'))
        .fontWeight(FontWeight.Bold)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({ start: LengthMetrics.vp(8) })
        .maxLines(2)
        .maxFontSize(this.isDivideAndFirst() || (isPhone() && DisplayUtil.getScreenFoldStatus() !== 1) ?
          $r('sys.float.ohos_id_text_size_headline8') : $r('app.float.radius_24'))
        .minFontSize($r('app.float.font_14'))
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .opacity(this.isDivideAndFirst() ? this.opacityVal : 1)
        .constraintSize({
          maxWidth: 'calc(100% - 48vp - 48vp)',
          maxHeight: `100%`
        })
    }
    .titleStyle()
    .alignItems(VerticalAlign.Center)
    .translate({ x: this.isDivideAndFirst() ? this.titleX : 0 })
  }

  @Builder
  backButton(): void {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .width(24)
        .height(24)
        .draggable(false)
        .fontSize('24vp')
        .fontColor([$r('sys.color.ohos_id_color_primary')])
    }
    .id('backButton')
    .draggable(false)
    .width('40vp')
    .height('40vp')
    .backgroundColor($r('sys.color.ohos_id_color_text_field_sub_bg'))
    .onClick(() => {
      this.onBackPress();
    })
    .opacity(this.circleOpacityVal)
    .accessibilityText($r('app.string.InfoEdit_back'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Column() {
          }
          .height(16)
          .width('100%')

          if (isSupportCactus() || isSupportDandelion() || isSupportHyacinth()) {
            this.satelliteSubSetings();
          }
          if (isSupportPalaceMuseum() || isSupportSummerPalace()) {
            this.beiDouSubSetings();
          }
          if (this.isCarSatelliteEnable()) {
            this.subSetings($r('app.media.satellite_icon'), $r('app.string.car_satellite_title'),
              $r('app.string.car_satellite_tips'), this.startCarSatelliteAbility);
          }
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
      }
      .align(Alignment.Top)
      .height('100%')
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .clip(false)
    }
    .hideTitleBar(false)
    .title(this.myTitleBar)
    // .titleBar(this.titleParam())
    .hideBackButton(this.navigationMode === this.isDivide)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onShown(() => {
      this.transitionType = NavigationSystemTransitionType.DEFAULT;
    })
    .onBackPressed(() => {
      this.transitionType = NavigationSystemTransitionType.TITLE;
      if (this.navigationMode !== NavigationMode.Split) {
        this.onBackInSettings();
      }
      return false;
    })
    .systemTransition(this.transitionType)
  }

  // private titleParam(): NavigationTitleBarOptions {
  //   return {
  //     avoidLayoutSafeArea: true,
  //     enableComponentSafeArea: true,
  //     content: {
  //       title: {
  //         mainTitle: $r('app.string.satellite_network'),
  //       },
  //     },
  //     // animationDuration: this.titleAnimationDuration
  //   };
  // }

  @Builder
  myTitleBar() {
    TitleBarLayout($r('app.string.satellite_network'),$r("sys.color.background_secondary"),false,this.titleAnimationDuration)
  }

  getNaviPadding(direction: string): LengthMetrics {
    let margin = CallColumnUtils.getInstance().getNaviPaddingSpace(direction);
    return LengthMetrics.resource(margin);
  }

  onBackPress(): boolean | void {
    if (this.pathInfos.size() === 0) {
      if (this.pageMode === CARD_PAGE_MODE) {
        router.back();
        return;
      }
      if (this.navigationMode !== this.isDivide) {
        this.backAnimate();
        this.session?.sendData({ 'action': 'pop' });
      }
    } else {
      this.pathInfos.pop()
    }
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

  private isDivideAndFirst(): boolean {
    return (this.navigationMode !== this.isDivide) && this.isFirst;
  }

  /**
   * 外界宿主设置执行Pop动作
   */
  onBackInSettings(): void {
    LogUtils.i(TAG, 'onBackInSettings');
    // 兼容蓬莱模式
    if (this.pageMode === CARD_PAGE_MODE) {
      router.back();
      return;
    }
    const intent: Record<string, Object> = { 'action': 'pop' };
    try {
      LocalStorage.getShared()?.get<UIExtensionContentSession>('ExtensionContentSession')?.sendData(intent);
    } catch (e) {
      LogUtils.e(TAG, `onBack catch err. code:${e?.code} message:${e?.message}`);
    }
  }
}