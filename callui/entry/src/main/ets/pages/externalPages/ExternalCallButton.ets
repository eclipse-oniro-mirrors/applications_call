/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import ExternalParticleLayout from './ExternalParticleLayout';
import * as Constants from '../../common/utils/Constants';
import DefaultCallData from '../../common/struct/TypeUtils';
import { isIncomingCall, isIncomingVoiceSilencedCall } from '../../common/utils/CallListHelper';
import { ExternalIconResource, IconTypes } from '../../model/ExternalResourceManager';
import { ExternalCallModel } from '../../model/ExternalCallModel';
import { ExternalAudioManagerDialog } from './ExternalAudioManagerDialog';
import { ExternalExpandTipsDialog } from './ExternalExpandTipsDialog';
import { ExternalAnimation } from '../../common/animation/ExternalAnimation';
import LogUtils from '../../common/utils/LogUtils';
import * as DeviceTypeConst from '../../common/constant/DeviceTypeConst';
import { StringUtil } from '../../common/utils/StringUtil';
import BottomViewModel from '../../viewmodel/BottomViewModel';

const TAG = 'ExternalCallButton';
const INVALID_ID = -1;

@Component
export default struct ExternalCallButton {
  @StorageProp(Constants.CALL_DATA) @Watch('refreshingData') callData: DefaultCallData = new DefaultCallData();
  @StorageProp(Constants.IS_MULTI_DEVICE) isMultiDevice: boolean = false;
  @StorageProp(Constants.EXTERNAL_LEFT_ICON) leftIconRes: ExternalIconResource = {
    iconRes: $r('app.string.emptyStr'),
    iconColor: '#FFFFFF',
    isClickable: false,
    opacity: Constants.OP_FULL,
    id: INVALID_ID
  };
  @StorageProp(Constants.EXTERNAL_RIGHT_ICON) rightIconRes: ExternalIconResource = {
    iconRes: $r('app.string.emptyStr'),
    iconColor: '#FFFFFF',
    isClickable: false,
    opacity: Constants.OP_FULL,
    id: INVALID_ID
  };
  @StorageProp(Constants.EXTERNAL_BOTTOM_ICON) bottomIconRes: ExternalIconResource = {
    iconRes: $r('app.string.emptyStr'),
    iconColor: '#FFFFFF',
    isClickable: false,
    opacity: Constants.OP_FULL,
    id: INVALID_ID
  };
  @State scrollX: number = 0;
  @State scrollXLockCon: number = 0;
  @State scaleLeftX: number = Constants.FULL_SCALE;
  @State scaleLeftY: number = Constants.FULL_SCALE;
  @State scaleRightX: number = Constants.FULL_SCALE;
  @State scaleRightY: number = Constants.FULL_SCALE;
  @State scaleButtonX: number = Constants.FULL_SCALE;
  @State scaleButtonY: number = Constants.FULL_SCALE;
  @State touchDown: boolean = false;
  @State callState: number = -1;
  @State isIncomingVoiceSilencedCall: boolean = false;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  private isPsd: boolean = ExternalCallModel.sIsPsd;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.refreshingData();
    ExternalCallModel.getInstance().setVideoTipsDialog(this.videoTipsDialog);
  }

  getLeftBarrierFreeString(): string {
    if (!this.screenReaderStatus) {
      return '';
    }
    if (this.leftIconRes.id == IconTypes.SET_MUTE_WHITE) {
      return StringUtil.formatResourceToString($r('app.string.call_mute_on'));
    } else if (this.leftIconRes.id == IconTypes.CANCEL_MUTE_WHITE) {
      return StringUtil.formatResourceToString($r('app.string.unmute'));
    } else {
      return '';
    }
  }

  getRightBarrierFreeString(): string {
    if (!this.screenReaderStatus) {
      return '';
    }
    if (this.isMultiDevice) {
      let deviceType = BottomViewModel.getInstance().currentAudioDevice.deviceType;
      if (deviceType == DeviceTypeConst.DEVICE_SPEAKER) {
        return StringUtil.formatResourceToString($r('app.string.switching_audio_channels'))
      } else if (deviceType == DeviceTypeConst.DEVICE_WIRED_HEADSET) {
        return StringUtil.formatResourceToString($r('app.string.wired_headset_selected'));
      } else if (deviceType == DeviceTypeConst.DEVICE_BLUETOOTH_SCO) {
        return StringUtil.formatResourceToString($r('app.string.blueetooth_device_selected'));
      } else {
        return '';
      }
    } else {
      return StringUtil.formatResourceToString($r('app.string.speaker'));
    }
  }

  refreshingData(): void {
    this.callState = this.callData.callState;
    this.isIncomingVoiceSilencedCall = isIncomingVoiceSilencedCall(this.callData);
  }

  audioDeviceController: CustomDialogController = new CustomDialogController({
    builder: ExternalAudioManagerDialog(),
    autoCancel: true,
    customStyle: true
  })
  expandDialogController: CustomDialogController = new CustomDialogController({
    builder: ExternalExpandTipsDialog({
      textRes: $r('app.string.open_phone_to_use_handset')
    }),
    autoCancel: true,
    customStyle: true
  })
  videoTipsDialog: CustomDialogController = new CustomDialogController({
    builder: ExternalExpandTipsDialog({
      textRes: $r('app.string.open_phone_for_video_call')
    }),
    autoCancel: true,
    customStyle: true
  })

  @Builder
  private initAllIcons() {
    this.initLeftIcons();
    this.initRightIcons();
    this.initBottomIcons();
  }

  @Builder
  private initLeftIcons() {
    if (this.leftIconRes.iconRes !== $r('app.string.emptyStr')) {
      SymbolGlyph(this.leftIconRes.iconRes)
        .symbolExtend(this.isPsd)
        .fontColor([this.leftIconRes.iconColor])
        .opacity(this.leftIconRes.opacity)
        .enabled(this.leftIconRes.isClickable)
        .margin(this.isPsd ? { top: '31.5vp', left: isIncomingCall(this.callState) ? '12vp' : '16vp'} :
          { top: '29.75vp', left: isIncomingCall(this.callState) ? '12vp' : '22.5vp'})
        .scale({ x: this.scaleLeftX, y: this.scaleLeftY })
        .id('left')
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          left: { anchor: '__container__', align: HorizontalAlign.Start }
        })
        .onClick(() => {
          ExternalCallModel.onLeftMethod();
        })
        .accessibilityGroup(true)
        .accessibilityLevel('yes')
        .accessibilityRole(AccessibilityRoleType.SYMBOL_GLYPH)
        .accessibilityText(this.getLeftBarrierFreeString())
    }
  }

  @Builder
  private initRightIcons() {
    if (this.rightIconRes.iconRes !== $r('app.string.emptyStr')) {
      Row() {
        SymbolGlyph(this.rightIconRes.iconRes)
          .attributeModifier(new AudioDeviceColorModifier())
          .fontColor([this.rightIconRes.iconColor])
          .symbolExtend(this.isPsd)
          .opacity(this.rightIconRes.opacity)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .visibility((!isIncomingCall(this.callState) && this.isMultiDevice) ? Visibility.Visible :
          Visibility.None)
          .fontColor([this.rightIconRes.iconColor])
          .margin({ left: '4vp' })
          .opacity(this.isPsd ? 0.6 : this.rightIconRes.opacity)
          .fontSize(this.isPsd ? '16vp' : '24vp')
      }
      .enabled(this.rightIconRes.isClickable)
      .size( this.isPsd ? {height: 28, width: isIncomingCall(this.callState) ? '28vp' : '40vp'} : {
        height: 32, width: isIncomingCall(this.callState) ? '32vp' : '48vp' })
      .margin(this.isPsd ? { top: '31.5vp', right: isIncomingCall(this.callState) ? '12vp' : '4vp' } :
        { top: '29.75vp', right: isIncomingCall(this.callState) ? '12vp' : '6vp' })
      .scale({ x: this.scaleRightX, y: this.scaleRightY })
      .id('right')
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })
      .onClick(() => {
        ExternalCallModel.handleAudioPressed(this.audioDeviceController, this.expandDialogController
          , this.isMultiDevice);
      })
      .accessibilityGroup(true)
      .accessibilityLevel('yes')
      .accessibilityRole(AccessibilityRoleType.SYMBOL_GLYPH)
      .accessibilityText(this.getRightBarrierFreeString())
    }
  }

  @Builder
  private initBottomIcons() {
    if (this.bottomIconRes.iconRes !== $r('app.string.emptyStr')) {
      SymbolGlyph(this.bottomIconRes.iconRes)
        .enabled(this.bottomIconRes.isClickable)
        .fontColor([this.bottomIconRes.iconColor])
        .fontSize(this.isPsd ? '28vp' : '32vp')
        .draggable(false)
        .opacity(this.bottomIconRes.opacity)
        .margin({ bottom: '12vp'})
        .scale({ x: this.scaleButtonX, y: this.scaleButtonY })
        .id('bottom')
        .visibility(this.isIncomingVoiceSilencedCall ? Visibility.None : Visibility.Visible)
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
    }
  }

  @Builder
  private slideTips() {
    Text($r('app.string.slide_to_answer'))
      .fontSize(this.isPsd ? '14vp' : '16vp')
      .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
      .height(this.isPsd ? '19vp' : '21.5vp')
      .maxLines(1)
      .lineHeight(this.isPsd ? '16vp' : '21.5vp')
      .textAlign(TextAlign.Center)
      .id('slideTips')
      .visibility(this.isIncomingVoiceSilencedCall ? Visibility.Visible : Visibility.None)
      .margin({ bottom: this.isPsd ? '25vp' : '28vp' })
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      })
  }

  build() {
    Stack() {
      ExternalAnimation({
        touchDown: this.touchDown
      })
      RelativeContainer() {
        this.initAllIcons();
        ExternalParticleLayout({
          touchDown: this.touchDown,
          scaleLeftX: this.scaleLeftX,
          scaleLeftY: this.scaleLeftY,
          scaleRightX: this.scaleRightX,
          scaleRightY: this.scaleRightY,
          scaleButtonX: this.scaleButtonX,
          scaleButtonY: this.scaleButtonY
        })
          .alignRules({
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
            top: { anchor: '__container__', align: VerticalAlign.Top }
          })
          .id('image')
        this.slideTips();
      }
    }
    .height(this.isPsd ? '146.5vp' : '158.75vp')
    .width('100%')
  }
}

@Extend(SymbolGlyph)
function symbolExtend(isPsd?: boolean) {
  .fontSize(isPsd ? '28vp' : '32vp')
  .draggable(false)
}

class AudioDeviceColorModifier implements AttributeModifier<SymbolGlyphAttribute> {
  private rightIconRes: ExternalIconResource = AppStorage.get(Constants.EXTERNAL_RIGHT_ICON) as ExternalIconResource;
  private isAudioDevice: boolean = this.rightIconRes.id === IconTypes.AUDIO_DEVICE_WHITE ||
    this.rightIconRes.id === IconTypes.AUDIO_DEVICE_GREY;

  applyNormalAttribute(instance: SymbolGlyphAttribute): void {
    if (this.isAudioDevice) {
      instance.fontColor(['#FFFFFF']);
    } else {
      instance.fontColor(['#64BB5C']);
    }
  }
}
