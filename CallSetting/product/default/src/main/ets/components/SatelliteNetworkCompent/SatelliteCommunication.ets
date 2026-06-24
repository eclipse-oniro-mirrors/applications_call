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

import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import SatelliteSubItem from './SatelliteSubItem';
import {
  LogUtils,
  ReportUtil,
  CallSettingGlobalContextHelper,
  SatelliteSimCardInfoStruct,
  TitleParams,
  TitleBarLayout,
} from '@ohos/common/CommonIndex';
import SatelliteToggleSelectedVM from '../../viewModel/SatelliteServiceSettingsVM';
import { isALNDevice, isTablet } from '../../common/utils/DeviceTypeUtils';
import { getPluralStringWithParam, getString } from '../../common/utils/Utils';
import { ParseXmlUtil, SpanNodeInfo } from '../../common/utils/ParseXmlUtil';
import { common } from '@kit.AbilityKit';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT } from '../../common/constant/CallSettingsConstant';
import { simIdFormat } from '../../common/utils/SimIdFormat';
import { LengthMetrics } from '@kit.ArkUI';
import { DynamicLoader } from '../../common/control/DynamicLoader';
import {
  addSatelliteToggleStateListener,
  removeSatelliteToggleStateListener,
  querySatellite
} from '../../common/utils/SateToggleStateManager';
import * as CallSettingsConstant from '../../common/constant/CallSettingsConstant';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';

interface privacyParamType {
  isPrivacyNote: boolean
}

const TAG = 'SatelliteCommunication';
const ONE: number = 1;
const TWO: number = 2;
const THREE: number = 3;
const FOUR: number = 4;
const FIVE: number = 5;

@Builder
export function SatelliteCommunicationLoader(): void {
  SatelliteCommunication();
}

@Component
export struct SatelliteCommunication {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State subId: number = 1;
  @State subTitle: Resource = $r('app.string.skycom_satellite_communications');
  @StorageLink('simCardInfoList') simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  @StorageLink('showName') showName: Resource | string = $r('app.string.satellite_service_no_sim_card');
  @StorageProp('currentLanguage') @Watch('replaceSpanNodeArray') currentLanguage: string = '';
  @State mSatelliteServiceSettingsVM: SatelliteToggleSelectedVM = SatelliteToggleSelectedVM.getInstance();
  @State controlSwitch: boolean = false;
  scroller: Scroller = new Scroller();
  private satelliteCommunicationNotification: string = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.resourceManager
    .getStringSync($r('app.string.satellite_short_notification_info').id)
  spanNodeArray: SpanNodeInfo[] = [];
  permissionDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.satellite_service_permission_usage_details'),
      contentBuilder: () => {
        this.permissionBuildContent();
      },
      buttons: [{
        value: $r('app.string.gotIt'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.permissionDialog.close();
        }
      }]
    }),
    autoCancel: false,
    showInSubWindow: true
  })

  SatelliteStateListener() {
    LogUtils.i(TAG, 'addSatelliteToggleStateListener');
    addSatelliteToggleStateListener(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT),
      (data: number) => {
        LogUtils.i(TAG, 'addSatelliteToggleStateListener:' + JSON.stringify(data));
        this.controlSwitch = data === 1 ? true : false;
      });

    querySatellite(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT),
      (data: number) => {
        LogUtils.i(TAG, 'querySatellite:' + JSON.stringify(data));
        this.controlSwitch = data === 1 ? true : false;
      });
  }

  @Builder
  permissionBuildContent(): void {
    Scroll(this.scroller) {
      Column() {
        Text($r('app.string.satellite_service_permission_count'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .align(Alignment.Start)
          .alignSelf(ItemAlign.Start)
          .lineHeight(19)

        Text($r('app.string.satellite_service_location'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .margin({ top: 14 })
          .align(Alignment.Start)

        Text($r('app.string.satellite_service_location_permission_descriptions'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.mSatelliteServiceSettingsVM.aboutToAppear();
    this.mSatelliteServiceSettingsVM.getActiveSimInfoCT(true);
    this.SatelliteStateListener();
    ParseXmlUtil.getInstance().parseXml(this.satelliteCommunicationNotification, this.spanNodeArray);
    ReportUtil.getInstance();
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  replaceSpanNodeArray(): void {
    let satelliteCommunicationNotification: string = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.resourceManager
      .getStringSync($r('app.string.satellite_short_notification_info').id);
    this.spanNodeArray = [];
    ParseXmlUtil.getInstance().parseXml(satelliteCommunicationNotification, this.spanNodeArray);
  }

  @Builder
  myTitleBar(){
    TitleBarLayout(getString($r('app.string.skycom_satellite_communications')),
      $r('sys.color.ohos_id_color_sub_background'), false)
  }

  build() {
    NavDestination() {
      Scroll(this.scroller) {
        Column() {
          Image($r('app.media.satellite_settings_image'))
            .width(288)
            .height(288)
            .draggable(false)
          Column()
            .height(24)

          SatelliteSubItem({
            subId: 1,
            title: $r('app.string.start_skycom_satellite_communications')
          })
            .margin({
              left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
            })

          Column()
            .height(12)

          Column() {
            Text($r('app.string.start_skycom_satellite_communications_sub1'))
              .textStyle()
            Text() {
              ForEach(this.spanNodeArray, (item: SpanNodeInfo) => {
                if (item.textStyle === 'bold') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                } else if (item.textStyle === 'userAgreements') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_hyperlink'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .onClick(() => {
                      DynamicLoader.getInstance().callFunction('SatelliteServiceUserAgreement').then(() => {
                        let param: privacyParamType = { isPrivacyNote: true };
                        this.pathInfos.pushPathByName('SatelliteServiceUserAgreement', param);
                        ReportUtil.getInstance().reportClickUserProtocol();
                      })
                    })
                } else if (item.textStyle === 'privacyStatement') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_hyperlink'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .onClick(() => {
                      DynamicLoader.getInstance().callFunction('SatelliteServicePrivacyStatement').then(() => {
                        let param: privacyParamType = { isPrivacyNote: false };
                        this.pathInfos.pushPathByName('SatelliteServicePrivacyStatement', param);
                        ReportUtil.getInstance().reportClickUserPrivacy();
                      });
                    })
                } else if (item.textStyle === 'permissionStatement') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_hyperlink'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .onClick(() => {
                      this.permissionDialog.open();
                      ReportUtil.getInstance().reportClickUserPermissions();
                    })
                } else {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                }
              })
            }
            .alignSelf(ItemAlign.Start)
            .margin({ top: 4 })

            Text($r('app.string.satellite_service_settings_details_descriptions3'))
              .textStyle()
              .margin({ top: 4 })
          }
          .margin({ start: LengthMetrics.vp(24), end: LengthMetrics.vp(32) })

          Column()
            .height(16)

          SatelliteSubItem({
            subId: 2,
            title: $r('app.string.satellite_service_select_sim')
          })
            .margin({
              left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
            })
            .enabled(this.simCardInfoList !== undefined && this.simCardInfoList.length === 2 && !this.controlSwitch)
            .opacity(!this.controlSwitch ? 1 : $r('sys.float.alpha_disable'))

          Column()
            .height(12)

          SatelliteSubItem({
            subId: 3,
            title: $r('app.string.frequently_asked_questions')
          })
            .margin({
              left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
            })

          Text($r('app.string.satellite_service_settings_explain'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .margin({ left: 28, right: 28, top: 28 })
            .alignSelf(ItemAlign.Start)
          Column() {
            Text() {
              Span($r('app.string.satellite_service_details_0', simIdFormat(ONE), isALNDevice() ?
              getPluralStringWithParam($r('app.plural.satellite_service_details_01'), FIVE) : ''))
            }
            .textStyle()

            Text($r('app.string.satellite_service_details_1_new', simIdFormat(TWO)))
              .textStyle()
            Text($r('app.string.satellite_service_details_2_new', simIdFormat(THREE)))
              .textStyle()
          }
          .margin({ start: LengthMetrics.vp(28), end: LengthMetrics.vp(32), top: 8 })
          .alignSelf(ItemAlign.Start)

          Column()
            .height(24)
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .clip(false)
    }
    .title(this.myTitleBar)
    // .titleBar(TitleParams.MiniTitleParams(getString($r('app.string.skycom_satellite_communications')),
    //   $r('sys.color.ohos_id_color_sub_background'), false, true))
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onWillDisappear(()=>{
      // Nav组件动效会导致aboutToDisappear延迟，需要使用onWillDisappear避免时序问题
      LogUtils.i(TAG, 'onWillDisappear');
      removeSatelliteToggleStateListener();
      this.showName = $r('app.string.satellite_service_no_sim_card');
    })
  }
}

@Extend(Text)
function textStyle() {
  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
  .fontFamily('HarmonyHeiTi')
  .fontWeight(FontWeight.Regular)
  .fontSize($r('sys.float.ohos_id_text_size_body3'))
  .alignSelf(ItemAlign.Start)
}
