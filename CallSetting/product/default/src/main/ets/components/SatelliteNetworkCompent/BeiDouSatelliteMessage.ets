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
  LogUtils,
  ReportUtil,
  SatelliteSimCardInfoStruct,
  CallSettingGlobalContextHelper,
  TitleParams,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import SatelliteToggleSelectedVM from '../../viewModel/SatelliteServiceSettingsVMForBeiDou';
import { getString } from '../../common/utils/Utils';
import { ParseXmlUtil, SpanNodeInfo } from '../../common/utils/ParseXmlUtil';
import { common } from '@kit.AbilityKit';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT } from '../../common/constant/CallSettingsConstant';
import { simIdFormat } from '../../common/utils/SimIdFormat';
import { LengthMetrics } from '@kit.ArkUI';
import { DynamicLoader } from '../../common/control/DynamicLoader';
import BeiDouSatelliteSubItem from './BeiDouSatelliteSubItem';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';

interface privacyParamType {
  isPrivacyNote: boolean
}

const TAG = 'BeiDouSatelliteMessage';
const ONE: number = 1;
const TWO: number = 2;
const THREE: number = 3;

@Builder
export function BeiDouSatelliteMessageLoader(): void {
  BeiDouSatelliteMessage();
}

@Component
export struct BeiDouSatelliteMessage {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State subId: number = 1;
  @State subTitle: Resource = $r('app.string.beidou_satellite_message');
  @StorageLink('simCardInfoListForBeiDou') simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  @StorageProp('currentLanguage') @Watch('replaceSpanNodeArray') currentLanguage: string = '';
  @State mSatelliteServiceSettingsVM: SatelliteToggleSelectedVM = SatelliteToggleSelectedVM.getInstance();
  private satelliteCommunicationNotification: string = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.resourceManager
    .getStringSync($r('app.string.beidou_satellite_short_notification').id)
  spanNodeArray: SpanNodeInfo[] = [];
  scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.mSatelliteServiceSettingsVM.aboutToAppear();
    this.mSatelliteServiceSettingsVM.getActiveSimInfoCT(true);
    ParseXmlUtil.getInstance().parseXml(this.satelliteCommunicationNotification, this.spanNodeArray);
    ReportUtil.getInstance();
  }

  replaceSpanNodeArray(): void {
    let satelliteCommunicationNotification: string = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.resourceManager
      .getStringSync($r('app.string.beidou_satellite_short_notification').id);
    this.spanNodeArray = [];
    ParseXmlUtil.getInstance().parseXml(satelliteCommunicationNotification, this.spanNodeArray);
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Scroll(this.scroller) {
          Column() {
            Image($r('app.media.beidou_satellite_message_settings'))
              .width(288)
              .height(288)
              .draggable(false)
            Column()
              .height(24)
            BeiDouSatelliteSubItem({
              subId: 1,
              title: $r('app.string.start_beidou_satellite_message')
            })
            Column()
              .height(12)

            Column() {
              Text() {
                ForEach(this.spanNodeArray, (item: SpanNodeInfo) => {
                  if (item.textStyle === 'bold') {
                    Span(item.content)
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .fontFamily('HarmonyHeiTi')
                      .fontWeight(FontWeight.Medium)
                      .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  } else if (item.textStyle === 'userAgreements') {
                    Span(item.content)
                      .fontColor($r('sys.color.ohos_id_color_text_hyperlink'))
                      .fontFamily('HarmonyHeiTi')
                      .fontWeight(FontWeight.Regular)
                      .fontSize($r('sys.float.ohos_id_text_size_body3'))
                      .onClick(() => {
                        DynamicLoader.getInstance().callFunction('BeiDouSatelliteMessageUserAgreement').then(() => {
                          let param: privacyParamType = { isPrivacyNote: true };
                          this.pathInfos.pushPathByName('BeiDouSatelliteMessageUserAgreement', param);
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
                        console.log('tmbtmb---privacyStatement')
                        DynamicLoader.getInstance().callFunction('BeiDouSatelliteMessagePrivacyStatement').then(() => {
                          let param: privacyParamType = { isPrivacyNote: false };
                          this.pathInfos.pushPathByName('BeiDouSatelliteMessagePrivacyStatement', param);
                          ReportUtil.getInstance().reportClickUserPrivacy();
                        });
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
              .textAlign(TextAlign.Start)
              .alignSelf(ItemAlign.Start)
              .margin({ top: 4 })

            }
            .margin({ start: LengthMetrics.vp(24), end: LengthMetrics.vp(32) })

            Column()
              .height(16)

            BeiDouSatelliteSubItem({
              subId: 2,
              title: $r('app.string.satellite_service_select_sim')
            })

            Column()
              .height(12)

            BeiDouSatelliteSubItem({
              subId: 3,
              title: $r('app.string.frequently_asked_questions')
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
                Span($r('app.string.beidou_satellite_message_service_details_0', simIdFormat(ONE)))
                  .textStyle()
                Span('\n')
                Span($r('app.string.beidou_satellite_message_service_details_1', simIdFormat(TWO)))
                  .textStyle()
                Span('\n')
                Span($r('app.string.beidou_satellite_message_service_details_2', simIdFormat(THREE)))
                  .textStyle()
              }
              .textAlign(TextAlign.Start)
            }
            .margin({ start: LengthMetrics.vp(28), end: LengthMetrics.vp(32), top: 8 })
            .alignSelf(ItemAlign.Start)

            Column()
              .height(24)
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .margin({ bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed') })
        .edgeEffect(EdgeEffect.Spring)
        .clip(false)

        //搜索索引条
        ScrollBar({
          scroller: this.scroller,
          direction: ScrollBarDirection.Vertical,
          state: BarState.Auto
        }).margin({ bottom: 32 }).position({ right: 0 })
      }
    }
    // .titleBar(TitleParams.MiniTitleParams(getString($r('app.string.beidou_satellite_message')),
    //   $r('sys.color.ohos_id_color_sub_background'), false, true))
    .title(this.myTitleBar)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
  @Builder
  myTitleBar(){
    TitleBarLayout(getString($r('app.string.beidou_satellite_message')),
      $r('sys.color.ohos_id_color_sub_background'), false)
  }
}

@Extend(Span)
function textStyle() {
  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
  .fontFamily('HarmonyHeiTi')
  .fontWeight(FontWeight.Regular)
  .fontSize($r('sys.float.ohos_id_text_size_body3'))
  .alignSelf(ItemAlign.Start)
}
