/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import commonController from '../common/control/CommonCtrol';
import { CallSettingGlobalContextHelper, ReportUtil } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import CallSettingVM from '../viewModel/CallSettingVM';

const TAG = 'SubRecordConfig';

@Component
export struct SubRecordConfig {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State commonController: commonController = commonController.getInstance();
  @LocalStorageLink('CallRecorderStatusText') getCallRecorderStatusText: Resource = $r('app.string.closed');
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';
  @Link airPlaneOn: boolean;
  @Link isDistributeSink: boolean;
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  aboutToAppear() {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
    this.commonController.queryForConfig(context, (configData) => {
      this.getCallRecorderStatusText = (!!configData.isOpen ? $r('app.string.opened') : $r('app.string.closed'));
    });
  }

  build() {
    Column() {
      if (this.fontSizeScale >= 1.75) {
        this.fontSizeScaleBigBuilder()
      } else {
        Flex({
          direction: this.fontSizeScale >= 1.75 ? FlexDirection.Column : FlexDirection.Row,
          justifyContent: FlexAlign.SpaceBetween,
          alignItems: this.fontSizeScale >= 1.75 ? ItemAlign.Start : ItemAlign.Center
        }) {
          this.contengBuilder()
        }
        .opacity((!this.airPlaneOn && !this.isDistributeSink) ? 1 : $r('sys.float.alpha_disable'))
        .enabled((!this.airPlaneOn && !this.isDistributeSink))
        .onClick(async () => {
          this.pathInfos.pushPathByName('RecorderConfig', $r('app.string.automatic_recording_of_calls'));
          ReportUtil.getInstance().reportClickAutoRecord();
        })
        .constraintSize({ minHeight: $r('app.float.wh_value_48') })
        .width('100%')
        .padding(this.fontSizeScale > 1.75 ? {
          top: this.fontSizeScaleMargin,
          bottom: this.fontSizeScaleMargin,
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        } : {
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        })
        .stateStyles({
          pressed: this.pressedStyles,
          normal: this.normalStyles
        })
        .borderRadius($r('app.float.radius_16'))
      }
    }
    .padding({
      left: $r('sys.float.padding_level2'),
      right: $r('sys.float.padding_level2')
    })
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .alignItems(HorizontalAlign.Center)
    .borderRadius(this.isFromExternal ? undefined : $r('app.float.radius_16'))
  }

  @Builder
  fontSizeScaleBigBuilder() {
    Column() {
      this.contengBuilder()
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
    .opacity((!this.airPlaneOn && !this.isDistributeSink) ? 1 : $r('sys.float.alpha_disable'))
    .enabled(!this.airPlaneOn && !this.isDistributeSink)
    .onClick(async () => {
      this.pathInfos.pushPathByName('RecorderConfig', $r('app.string.automatic_recording_of_calls'));
      ReportUtil.getInstance().reportClickAutoRecord();
    })
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .width('100%')
    .padding({
      top: this.fontSizeScaleMargin,
      bottom: this.fontSizeScaleMargin,
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    })
    .borderRadius($r('app.float.radius_16'))
  }

  @Builder
  contengBuilder() {
    if (this.fontSizeScale >= 1.75) {
      Text($r('app.string.automatic_recording_of_calls'))
        .textStyleExtend()
        .margin({ bottom: 2 })
        .constraintSize({ maxWidth: '100%' })
        .width('100%')
    } else {
      Text($r('app.string.automatic_recording_of_calls'))
        .textStyleExtend()
        .layoutWeight(1)
    }

    Row() {
      Text(this.getCallRecorderStatusText)
        .fontSize($r('sys.float.Subtitle_S'))
        .margin({ right: 4 })
        .fontColor($r('sys.color.font_secondary'))

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor([$r('sys.color.icon_fourth')])
        .fontSize('24vp')
        .draggable(false)
    }
    .constraintSize({ maxWidth: this.fontSizeScale >= 1.75 ? '100%' : 'auto' })
    .width(this.fontSizeScale >= 1.75 ? '100%' : 'auto')
    .justifyContent(this.fontSizeScale >= 1.75 ? FlexAlign.SpaceBetween : FlexAlign.End)
  }
}

@Extend(Text)
function textStyleExtend() {
  .fontSize($r('sys.float.Subtitle_M'))
  .fontColor($r('sys.color.font_primary'))
  .fontFamily('HarmonyHeiTi')
  .fontWeight(FontWeight.Medium)
  .constraintSize({ minHeight: $r('app.float.line_height_22') })
}
