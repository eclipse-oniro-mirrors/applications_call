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
  CallSettingGlobalContextHelper, TitleParams,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import { ParseXmlUtil, SpanNodeInfo } from '../../common/utils/ParseXmlUtil';
import { common } from '@kit.AbilityKit';
import { LengthMetrics } from '@kit.ArkUI';
import { DynamicLoader } from '../../common/control/DynamicLoader';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT } from '../../common/constant/CallSettingsConstant';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';

const TAG = 'HyacinthActivate';

PersistentStorage.persistProp('hyacinthActivated', false);

@Builder
export function HyacinthActivateLoader(): void {
  HyacinthActivate();
}

@Component
export struct HyacinthActivate {
  @Consume('pathInfos') pathInfos: NavPathStack;
  private satelliteCommunicationNotification: string = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.
  resourceManager.getStringSync($r('app.string.hyacinth_satellite_activate_text').id)
  spanNodeArray: SpanNodeInfo[] = [];

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    ParseXmlUtil.getInstance().parseXml(this.satelliteCommunicationNotification, this.spanNodeArray);
    ReportUtil.getInstance();
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Column()
            .height(24)
          Image($r('app.media.hyacinth_setting_image'))
            .width(288)
            .height(288)
            .draggable(false)
          Column()
            .height(24)
          Column() {
            Text($r('app.string.hyacinth_satellite_activate'))
              .textAlign(TextAlign.Center)
              .fontWeight(FontWeight.Bold)
              .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          }.margin({ bottom: 10 })

          Column() {
            Text() {
              ForEach(this.spanNodeArray, (item: SpanNodeInfo) => {
                if (item.textStyle === 'bold') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Medium)
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                } else {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                }
              })
            }.alignSelf(ItemAlign.Start)
            .width('100%')
          }.margin({ start: LengthMetrics.vp(16), end: LengthMetrics.vp(16) })
          .height('20%')
          .layoutWeight(1)

          Column() {
            Button($r('app.string.hyacinth_satellite_activate_immediatly'))
              .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .onClick(() => {
                LogUtils.i(TAG, 'Hyacinth service activated');
                ReportUtil.getInstance().reportHyacinthActivate();
                AppStorage.setOrCreate('hyacinthActivated', true);
                DynamicLoader.getInstance().callFunction('HyacinthCommunication').then(() => {
                  this.pathInfos.pushPathByName('HyacinthCommunication', '');
                })
              })
              .width('100%')
              .height(40)
          }.align(Alignment.Bottom)
          .margin({
            top: 5,
            bottom: 44,
            left: 16,
            right: 16
          })
        }
        .width('100%')
        .layoutWeight(1)
        .clip(false)
      }
    }
    .key('HyacinthActivate_Nav')
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.hyacinth_satellite_communications'),
    //   $r('sys.color.ohos_id_color_sub_background'), false, true))
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .title(this.myTitleBar)
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.hyacinth_satellite_communications'), $r('sys.color.ohos_id_color_sub_background'), false)
  }
}