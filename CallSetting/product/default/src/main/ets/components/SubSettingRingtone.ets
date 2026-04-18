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

import common from '@ohos.app.ability.common';
import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import CallSettingVM from '../viewModel/CallSettingVM';
import { getRingToneAttrsArray, getRingToneName } from '../common/utils/CommonFunUtil';
import { getMaxSimCount } from '../model/RegisterSimStateApi';
import { systemSoundManager } from '@kit.AudioKit';
import { emitter } from '@kit.BasicServicesKit';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';

const SETTING_BUNDLE_NAME: string = 'com.ohos.settings'; // BundleName of setting app.
const SETTING_ABILITY_NAME: string = 'com.ohos.settings.MainAbility'; // ability name of setting app.
const SETTING_URI_NAME: string = 'ring_tone_settings'; // uri of setting app ringtone.
const MAX_SIM_COUNTS = 2;

const TAG = 'SubSettingRingtone';

@Component
export struct SubSettingRingtone {
  private isSimRingtone = CallSettingVM.getInstance().isGetInitSimRingtone();
  @State simRingtoneOne: string = this.isSimRingtone ? CallSettingVM.getInstance().simRingtoneOne : '';
  @State simRingtoneTwo: string = this.isSimRingtone ? CallSettingVM.getInstance().simRingtoneTwo : '';
  @State context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @StorageLink('pageUpdateFlag') @Watch('onPageShow') pageUpdateFlag: boolean = false;
  @Link airPlaneOn: boolean;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';
  @StorageProp('currentLanguage') @Watch('updateToneAttrsArrayToRefreshRingTone') currentLanguage: string = '';
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  // 接收 index 传过来的 simCardInfo
  @Prop simCardInfo: [boolean, string][]

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
  }
  @Styles
  normalStyles() {
    .backgroundColor(this.isFromExternal ? Color.Transparent : $r('sys.color.comp_background_primary'))
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.updateToneAttrsArrayToRefreshRingTone();
    if (this.isFromExternal) {
      emitter.on({ eventId: CallSettingsConstant.EMIT_GET_RINGTONE_EVENT_ID }, () => {
        this.updateToneAttrsArrayToRefreshRingTone();
      })
    }
    emitter.on({ eventId: CallSettingsConstant.EMIT_LANGUAGE_CHANGE_EVENT_ID }, () => {
      this.updateToneAttrsArrayToRefreshRingTone();
    })
  }

  onPageShow() {
    LogUtils.i(TAG, 'on page show');
    this.updateToneAttrsArrayToRefreshRingTone();
  }

  async getSimRingtone() {
    LogUtils.i(TAG, 'getSimRingtone');
    try {
      let card0RingToneName: string = await getRingToneName(this.context, 0,
        CallSettingVM.getInstance().toneAttrsArray);
      let card1RingToneName: string = await getRingToneName(this.context, 1,
        CallSettingVM.getInstance().toneAttrsArray);
      if (card0RingToneName && card1RingToneName) {
        this.simRingtoneOne = card0RingToneName;
        this.simRingtoneTwo = card1RingToneName;
      }
    } catch (err) {
      LogUtils.e(TAG, `getSimRingtone error, code:${err?.code} message:${err?.message}`);
    }
  }

  aboutToDisappear(): void {
    if (this.isFromExternal) {
      emitter.off(CallSettingsConstant.EMIT_GET_RINGTONE_EVENT_ID);
    }
    emitter.off(CallSettingsConstant.EMIT_LANGUAGE_CHANGE_EVENT_ID);
  }

  async updateToneAttrsArrayToRefreshRingTone() {
    LogUtils.i(TAG, 'updateToneAttrsArray');
    try {
      getRingToneAttrsArray(this.context, (ringtoneAttrsArr: systemSoundManager.ToneAttrsArray) => {
        if (ringtoneAttrsArr.length > 0) {
          CallSettingVM.getInstance().toneAttrsArray = ringtoneAttrsArr;
          this.getSimRingtone();
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `getRingToneAttrsArray error, code:${err?.code} message:${err?.message}`);
    }
  }

  jumpCallRingTonePage(context: common.UIAbilityContext): void {
    let want: Want = {
      'bundleName': SETTING_BUNDLE_NAME,
      'abilityName': SETTING_ABILITY_NAME,
      'uri': SETTING_URI_NAME,
    }
    context.startAbility(want).then((data) => {
      LogUtils.i(TAG, `msg:${data}`);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `start setting app failed, code: ${err?.code}`);
    });
  }

  build() {
    Column() {
      if (this.fontSizeScale >= 1.75) {
        this.fontSizeScaleBigBuilder();
      } else {
        Flex({
          direction: FlexDirection.Row,
          justifyContent: FlexAlign.SpaceBetween,
          alignItems: ItemAlign.Center
        }) {
          this.ringtoneContentBuilder();
        }
        .constraintSize({ minHeight: 48 })
        .width('100%')
        .borderRadius($r('sys.float.corner_radius_level8'))
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4'),
          top: this.fontSizeScale > 1 ? this.fontSizeScaleMargin : 5,
          bottom: this.fontSizeScale > 1 ? this.fontSizeScaleMargin : 5
        })
        .stateStyles({
          pressed: this.pressedStyles,
          normal: this.normalStyles
        })
      }
    }
    .constraintSize({ minHeight: 48 })
    .backgroundColor(this.isFromExternal ? Color.Transparent :
      $r('sys.color.comp_background_primary'))
    .borderRadius({
      bottomLeft: $r('app.float.radius_16'),
      bottomRight: $r('app.float.radius_16')
    })
    .padding({
      left: $r('sys.float.padding_level2'),
      right: $r('sys.float.padding_level2')
    })
    .opacity(!this.airPlaneOn ? 1 : $r('sys.float.alpha_disable'))
    .enabled(!this.airPlaneOn)
    .onClick(() => {
      this.jumpCallRingTonePage(this.context);
      ReportUtil.getInstance().reportClickIncomingRingTone(this.simRingtoneOne, this.simRingtoneTwo);
    })
  }

  @Builder
  fontSizeScaleBigBuilder() {
    Column() {
      this.ringtoneContentBuilder();
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
    .constraintSize({ minHeight: 48 })
    .width('100%')
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
      top: this.fontSizeScaleMargin,
      bottom: this.fontSizeScaleMargin
    })
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    })
  }

  @Builder
  ringtoneContentBuilder() {
    Text($r('app.string.phone_ring_tone'))
      .fontSize(16)
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .width(this.fontSizeScale >= 1.75 ? '100%' : '')
      .constraintSize({ minHeight: 21, maxWidth: this.fontSizeScale >= 1.75 ? '100%' : '30%' })
      .margin({ bottom: this.fontSizeScale >= 1.75 ? 2 : 0 })

    Row() {
      this.simRongContentBuilder()
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('app.float.wh_value_24'))
        .fontColor([$r('sys.color.icon_fourth')])
        .draggable(false);
    }
    .width(this.fontSizeScale >= 1.75 ? '100%' : '')
    .constraintSize({ maxWidth: this.fontSizeScale >= 1.75 ? '100%' : '70%' })
    .justifyContent(this.fontSizeScale >= 1.75 ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }

  @Builder
  simRongContentBuilder() {
    Column() {
      if (getMaxSimCount() === MAX_SIM_COUNTS) {
        Text(this.simRingtoneOne !== this.simRingtoneTwo ?
            this.simCardInfo[0][0] ? $r('app.string.phone_ring_Card1', this.simCardInfo[0][1], this.simRingtoneOne) :
            $r('app.string.phone_ring_Card3', this.simCardInfo[0][1], this.simRingtoneOne) : this.simRingtoneOne)
          .textAlign(this.fontSizeScale >= 1.75 ? TextAlign.Start : TextAlign.End)
          .ringToneStyle();

        if (this.simRingtoneOne !== this.simRingtoneTwo) {
          Text(this.simCardInfo[1][0] ? $r('app.string.phone_ring_Card2', this.simCardInfo[1][1], this.simRingtoneTwo) :
            $r('app.string.phone_ring_Card3', this.simCardInfo[1][1], this.simRingtoneTwo))
            .textAlign(this.fontSizeScale >= 1.75 ? TextAlign.Start : TextAlign.End)
            .ringToneStyle();
        }
      } else {
        Text(this.simRingtoneOne)
          .ringToneStyle()
          .textAlign(this.fontSizeScale >= 1.75 ? TextAlign.Start : TextAlign.End)
      }
    }
    .justifyContent(FlexAlign.End)
    .margin({ right: 4 })
    .width(this.fontSizeScale >= 1.75 ? 'calc(100% - 16vp)' : 'calc(70% - 32vp)')
  }
}

@Extend(Text)
function ringToneStyle() {
  .fontSize(14)
  .constraintSize({ minHeight: 18 })
  .fontColor($r('sys.color.font_secondary'))
  .fontWeight(FontWeight.Regular)
  .fontFamily('HarmonyHeiTi')
  .width('100%')
}