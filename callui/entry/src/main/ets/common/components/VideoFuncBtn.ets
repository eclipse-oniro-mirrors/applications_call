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
import LogUtils from '../utils/LogUtils';
import BottomViewModel from '../../viewmodel/BottomViewModel';
import * as DeviceTypeConst from '../constant/DeviceTypeConst';
import { curves } from '@kit.ArkUI';
import Utils from '../utils/utils';
import systemDateTime from '@ohos.systemDateTime';
import { StringUtil } from '../utils/StringUtil';
import VideoCameraStatus from '../struct/VideoCameraStatus';
import VideoCameraHelper from '../struct/VideoCameraHelper';
import { DefaultDistributeDeviceAddressData } from '../struct/TypeUtils';
import AudioDeviceManager from '../../model/audio/AudioDeviceManager';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { accessibility } from '@kit.AccessibilityKit';
import { SPEAKER_DELAY_SEND_DURATION, DELAY_SEND_DURATION } from '../constant/AccessibilityDelayConst';
import CallStateConst from '../constant/CallStateConst';
import { CALL_BUNDLE_NAME, EVENT_REQUEST_FOCUS_FOR_ACCESSIBILITY, EVENT_TRIGGER_ACTION } from '../utils/Constants';

const TAG = 'VideoFuncBtn';
const SPEAK_ON_ICONS_INDEX: number = 18;
const SPEAK_OFF_ICONS_INDEX: number = 35;
const PRESS_TIMER_DURATION: number = 80;
const SPEAK_ANIMATION_DURATION: number = 550;

@Component
export default struct VideoFuncBtn {
  @State btnType: string = '';
  @State iconDefaultUrl: string = '';
  @State iconDisableUrl: string = this.iconDefaultUrl;
  @State iconActiveUrl: string = this.iconDefaultUrl;
  @State iconTouchUrl: string = this.iconDefaultUrl;
  @State iconDisableFontColor: string = '';
  @State iconDefaultFontColor: string = '';
  @State iconActiveFontColor: string = '';
  @State iconTouchFontColor: string = '';
  @State speakerIconDefault: Resource = $r('app.media.ic_public_sound_louder');
  @Prop @Watch('iconClassName') isActive: boolean = false;
  @Prop @Watch('iconClassName') isDisable: boolean = false;
  @State iconText: Resource | string = $r('app.string.emptyStr');
  @State textColor: string = 'rgb(255, 255, 255)';
  @State mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  @StorageLink('currentAudioDeviceIcon')
  @Watch('updateAudioDeviceIcon') currentAudioDeviceIcon: Resource = $r('app.media.ic_public_sound_louder');
  @State defaultSpeakerIcon: Resource = $r('sys.symbol.speaker_wave_3_fill');
  @State defaultSpeakerIconFontColor: string = '#0A59F7';
  @State renderSymbolType: number = 0;
  @StorageProp('curBp') curBp: string = '';
  @State isPressed: boolean = false;
  @State lightIntensity: number = 0;
  @State lightBloom: number = 0;
  @State lightPositionZ: number = 65;
  @State illuminatedType: IlluminatedType = IlluminatedType.BORDER_CONTENT;
  @State handHpBgColor: ResourceColor = Color.Transparent;
  @State handHpBorderColor: ResourceColor = Color.Transparent;
  @State lightBgColor: ResourceColor = 'rgba(255, 255, 255, 0.15)';
  @Consume enableLight: boolean;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @Prop isShowKeyboard: boolean;
  @Consume frontCameraId: string;
  @Consume backCameraId: string;
  @State speakerReaderTxtStr: string = '';
  btnClick: Function = () => {
  };
  @StorageProp('speakerAnimationOn') speakerAnimationOn: boolean = false;
  @StorageProp('muteAnimationOn') muteAnimationOn: boolean = false;
  @State pressTimer: number = 0;
  @State deviceType: number = 0;
  @Link hasMultiDevice: boolean;
  @State btnOpactiy: number = 1;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  private btnBgColor: ResourceColor = 'rgba(255,255,255,0.2)';

  /**
   * Button group picture change control
   *
   * @return {string} - return iconUrl
   */
  iconUrl() {
    if (this.isPressed) {
      return this.iconTouchUrl;
    }
    if (this.isDisable && this.iconDisableUrl) {
      LogUtils.d(TAG, 'iconUrl this.isDisable : ' + this.isDisable);
      if (this.btnType === 'videoMute' && this.isActive) {
        return this.iconActiveUrl;
      }
      return this.iconDisableUrl;
    }
    return this.isActive && this.iconDefaultUrl ? this.iconActiveUrl : this.iconDefaultUrl;
  }

  /**
   * Button group picture change control
   *
   * @return {string} - return iconFontColor
   */
  iconFontColor() {
    if (this.isPressed) {
      return this.iconTouchFontColor;
    }
    if (this.isDisable && this.iconDisableUrl) {
      if (this.btnType === 'videoMute' && this.isActive) {
        return this.iconActiveFontColor;
      }
      return this.iconDisableFontColor;
    }
    return this.isActive && this.iconDefaultUrl ? this.iconActiveFontColor : this.iconDefaultFontColor;
  }
  /**
   * update audio icon and text.
   */
  updateAudioDeviceIcon(): void {
    if (this.btnType === 'speaker') {
      let audioDevice = this.mBottomViewModel.getCurrentAudioDeviceType();
      this.deviceType = audioDevice;
      if (this.mBottomViewModel.isHaveMultiDevice && this.deviceType !== DeviceTypeConst.DEVICE_SPEAKER &&
      this.speakerAnimationOn) {
        AppStorage.setOrCreate('speakerAnimationOn', false);
      }
      this.speakerReaderTxtStr = this.getTypeSpeakerText();
      LogUtils.i(TAG, 'updateAudioDeviceIcon audioDevice : ' + audioDevice);
      switch (audioDevice) {
        case DeviceTypeConst.DEVICE_EARPIECE:
          if (this.mBottomViewModel.isHaveMultiDevice) {
            this.defaultSpeakerIcon = $r('sys.symbol.ear');
            this.defaultSpeakerIconFontColor = '#0A59F7';
          } else {
            this.defaultSpeakerIcon = $r('sys.symbol.speaker_wave_3_fill');
            this.defaultSpeakerIconFontColor = '#ffffff';
          }
          this.iconText = $r('app.string.phoneHandset');
          this.renderSymbolType = DeviceTypeConst.DEVICE_EARPIECE;
          break;
        case DeviceTypeConst.DEVICE_SPEAKER:
          this.defaultSpeakerIcon = $r('sys.symbol.speaker_wave_3_fill');
          this.defaultSpeakerIconFontColor = '#0A59F7';
          this.renderSymbolType = DeviceTypeConst.DEVICE_SPEAKER;
          this.iconText = $r('app.string.speaker');
          break;
        case DeviceTypeConst.DEVICE_WIRED_HEADSET:
          this.defaultSpeakerIcon = $r('sys.symbol.earphone_16640_fill');
          this.defaultSpeakerIconFontColor = '#0A59F7';
          this.renderSymbolType = DeviceTypeConst.DEVICE_WIRED_HEADSET;
          this.iconText = $r('app.string.wiredHeadset');
          break;
        case DeviceTypeConst.DEVICE_BLUETOOTH_SCO:
          this.defaultSpeakerIcon = this.currentAudioDeviceIcon;
          this.defaultSpeakerIconFontColor = '#0A59F7';
          this.renderSymbolType = DeviceTypeConst.DEVICE_BLUETOOTH_SCO;
          this.iconText = $r('app.string.blueetoothDevice');
          break;
        case DeviceTypeConst.DEVICE_DISTRIBUTED_AUTOMOTIVE:
          this.defaultSpeakerIcon = $r('sys.symbol.car');
          this.updateDistributedAutomotiveIcon();
          break;
        case DeviceTypeConst.DEVICE_DISTRIBUTED_PAD:
          this.defaultSpeakerIcon = this.currentAudioDeviceIcon;
          this.defaultSpeakerIconFontColor = '#0A59F7';
          this.renderSymbolType = DeviceTypeConst.DEVICE_DISTRIBUTED_PAD;
          this.updateDistributedAutomotiveIcon();
          break;
        case DeviceTypeConst.DEVICE_BLUETOOTH_HEARINGAID:
          this.renderSymbolType = DeviceTypeConst.DEVICE_BLUETOOTH_HEARINGAID;
          this.setCurrentDeviceProperty();
          break;
        case DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN:
          this.renderSymbolType = DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN;
          this.setCurrentDeviceProperty();
          break;
        default:
          this.defaultSpeakerIcon = $r('sys.symbol.speaker_wave_3_fill');
          this.defaultSpeakerIconFontColor = '#0A59F7';
          this.renderSymbolType = 0;
          this.iconText = $r('app.string.speaker');
      }
    }
  }

  private setCurrentDeviceProperty(): void {
    this.defaultSpeakerIcon = this.currentAudioDeviceIcon;
    this.defaultSpeakerIconFontColor = '#0A59F7';
    this.iconText = this.mBottomViewModel.currentAudioDevice.deviceName;
  }

  private updateDistributedAutomotiveIcon(): void {
    const address = this.mBottomViewModel.getCurrentAudioDeviceAddress();
    try {
      const data: DefaultDistributeDeviceAddressData = JSON.parse(address);
      if (data && data.devName) {
        this.iconText = data.devName;
      }
    } catch (err) {
      LogUtils.e(TAG, `parse address error: ${err.code}, message is ${err.message}`);
    }
  }

  getBarrierFreeString(): string {
    let videoCameraInfo: VideoCameraStatus | undefined = VideoCameraHelper.getInstance().getVideCameraInfo();
    if (!this.screenReaderStatus) {
      return '';
    }
    if (this.btnType === 'keyBoard') {
      return !this.isShowKeyboard ? StringUtil.formatResourceToString($r('app.string.show_dialpad')) :
      StringUtil.formatResourceToString($r('app.string.hide_dialpad'));
    }
    if (this.btnType === 'videoMute') {
      return !this.isActive ? StringUtil.formatResourceToString($r('app.string.call_mute_on')) :
      StringUtil.formatResourceToString($r('app.string.unmute'));
    }
    if (this.btnType === 'hangUp') {
      return StringUtil.formatResourceToString($r('app.string.hanging_up_video_call'));
    }
    if (this.btnType === 'switchCamera') {
      if (videoCameraInfo === undefined || videoCameraInfo?.currentCameraId === '' ||
        videoCameraInfo.currentCameraId === this.frontCameraId) {
        return StringUtil.formatResourceToString($r('app.string.switch_rear_camera'));
      } else {
        return StringUtil.formatResourceToString($r('app.string.switch_front_camera'));
      }
    }
    if (this.btnType === 'tureOffMyVideo') {
      return this.isActive ? StringUtil.formatResourceToString($r('app.string.ture_on_camera')) :
      StringUtil.formatResourceToString($r('app.string.turn_off_camera'));
    }
    return '';
  }

  getTypeSpeakerText(): string {
    if (!this.screenReaderStatus) {
      return '';
    }
    if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_SPEAKER) {
      return this.mBottomViewModel.isHaveMultiDevice ? StringUtil.formatResourceToString($r('app.string.switching_audio_channels')) :
      StringUtil.formatResourceToString($r('app.string.speaker'));
    } else if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_EARPIECE) {
      return this.mBottomViewModel.isHaveMultiDevice ?
      StringUtil.formatResourceToString($r('app.string.switching_audio_channels')) :
      StringUtil.formatResourceToString($r('app.string.phoneHandset'));
    } else if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_WIRED_HEADSET) {
      return StringUtil.formatResourceToString($r('app.string.wired_headset_selected'));
    } else if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_SCO) {
      return StringUtil.formatResourceToString($r('app.string.blueetooth_device_selected'));
    } else {
      return '';
    }
  }

  /**
   * Button group style display
   *
   * @return {string} - Button group style display
   */
  iconClassName(): string {
    if (this.isDisable) {
      this.textColor = 'rgb(255, 255, 255, 0.4)';
      return 'disable';
    }
    if (this.isActive) {
      this.textColor = 'rgb(255, 255, 255, 0.4)';
      return 'enable';
    }
    this.textColor = 'rgb(255, 255, 255)';
    return 'default';
  }

  aboutToAppear() {
    this.iconClassName();
    this.updateAudioDeviceIcon();
  }

  async lightTouchHp(type: TouchType) {
    if (type === TouchType.Down) {
      this.enableLight = true;
      this.isPressed = true;
      this.handHpBgColor = '#3effffff';
      this.handHpBorderColor = '#fffc745e';
      this.lightBgColor = 'rgba(255, 255, 255, 0.5)';
      this.illuminatedType = (this.btnType === 'hangUp' ? IlluminatedType.NONE : IlluminatedType.BORDER_CONTENT);
      animateTo({
        duration: 333,
        delay: 0,
        curve: curves.cubicBezierCurve(0.0, 0.2, 0.2, 1),
      }, () => {
        if (this.curBp === 'sm' || this.curBp === 'xs') {
          this.lightIntensity = 6;
        } else if (this.curBp === 'md') {
          this.lightIntensity = 10;
          this.lightPositionZ = 82;
        }
        this.lightBloom = 0.8;
      })
      if (this.btnType === 'speaker' || this.btnType === 'videoMute') {
        this.pressTimer = await systemDateTime.getRealActiveTime(false);
      } else {
        this.isPressed = true;
      }
    } else if (type === TouchType.Move) {
      if (this.btnType === 'speaker' || this.btnType === 'videoMute') {
        let now: number = await systemDateTime.getRealActiveTime(false);
        if (this.pressTimer > 0 && now - this.pressTimer > PRESS_TIMER_DURATION) {
          this.isPressed = true;
        }
      }
    } else if (type === TouchType.Up) {
      this.isPressed = false;
      this.pressTimer = 0;
      this.illuminatedType = IlluminatedType.BORDER_CONTENT;
      this.lightIntensity = this.btnType === 'hangUp' ? 0 : this.lightIntensity;
      animateTo({
        duration: 200,
        delay: 0,
        curve: curves.cubicBezierCurve(0.0, 0.2, 0.2, 1),
      }, () => {
        this.lightIntensity = 0;
        this.lightBloom = 0;
        this.handHpBorderColor = Color.Transparent;
        this.handHpBgColor = Color.Transparent;
        this.lightBgColor = 'rgba(255, 255, 255, 0.15)';
      })
    }
  }

  speakerImgArrOn() {
    let arr: ImageFrameInfo[] = [];
    for (let i: number = 1; i < SPEAK_ON_ICONS_INDEX; i++) {
      let name = `app.media.speaker${i}`;
      arr.push({ src: $r(name) });
    }
    return arr;
  }

  speakerImgArrOff() {
    let arr: ImageFrameInfo[] = [];
    for (let i: number = SPEAK_ON_ICONS_INDEX; i < SPEAK_OFF_ICONS_INDEX; i++) {
      let name = `app.media.speaker${i}`;
      arr.push({ src: $r(name) });
    }
    return arr;
  }

  getButtonWidth() {
    return this.isNewFoldPhoneExternalScreen ? 48 : 56;
  }

  getButtonBorderRadius() {
    return this.isNewFoldPhoneExternalScreen ? 24 : 28;
  }

  getSpeakerPhoneSymbolFontSize() {
    return this.isNewFoldPhoneExternalScreen ? '24vp' : $r('app.float.funbtn_image_width');
  }

  getSymbolGlyphFontSize() {
    return this.isNewFoldPhoneExternalScreen ? '24vp' : $r('app.float.wh_answer_btn_32');
  }

  delaySendAccessibilityEvent(typeId: string) {
    if (!this.screenReaderStatus) {
      return;
    }
    setTimeout(() => {
      let eventInfo: accessibility.EventInfo = ({
        type: EVENT_REQUEST_FOCUS_FOR_ACCESSIBILITY,
        bundleName: CALL_BUNDLE_NAME,
        triggerAction: EVENT_TRIGGER_ACTION,
        customId: typeId
      });
      accessibility.sendAccessibilityEvent(eventInfo).then(() => {
      });
    }, this.btnType === CallStateConst.TEXT_IN_CALL_AUDIO_SPEAKER ? SPEAKER_DELAY_SEND_DURATION : DELAY_SEND_DURATION);
  }

  @Builder
  buildSpeakerAnimOn() {
    ImageAnimator()
      .images(
        this.speakerImgArrOn()
      )
      .width(ScreenAdapterUtils.getInstance().getFuncBtnWidth(this.isNewFoldPhoneExternalScreen))
      .height(ScreenAdapterUtils.getInstance().getFuncBtnWidth(this.isNewFoldPhoneExternalScreen))
      .duration(SPEAK_ANIMATION_DURATION)
      .iterations(1)
      .fillMode(FillMode.Forwards)
      .state(AnimationStatus.Running)
      .onFinish(() => {
        AppStorage.setOrCreate('speakerAnimationOn', true);
      })
  }

  @Builder
  buildSpeakerAnimOff() {
    ImageAnimator()
      .images(
        this.speakerImgArrOff()
      )
      .width($r('app.float.call_button_width'))
      .height($r('app.float.call_button_width'))
      .duration(SPEAK_ANIMATION_DURATION)
      .iterations(1)
      .fillMode(FillMode.Forwards)
      .state(AnimationStatus.Running)
      .onFinish(() => {
        AppStorage.setOrCreate('speakerAnimationOn', false);
      })
  }

  @Builder
  buildSpeakerPhone() {
    if (this.deviceType === DeviceTypeConst.DEVICE_SPEAKER && !this.speakerAnimationOn) {
      this.buildSpeakerAnimOn();
    } else if (this.deviceType === DeviceTypeConst.DEVICE_EARPIECE && !this.mBottomViewModel.isHaveMultiDevice &&
    this.speakerAnimationOn) {
      this.buildSpeakerAnimOff();
    } else {
      SymbolGlyph(this.defaultSpeakerIcon)
        .fontSize(this.getSpeakerPhoneSymbolFontSize())
        .fontColor(this.renderSymbolType === DeviceTypeConst.DEVICE_WIRED_HEADSET ?
          [this.defaultSpeakerIconFontColor, '#0A59f7'] :
          [this.isPressed ? '#0A59f7' : this.defaultSpeakerIconFontColor])
        .fontWeight(FontWeight.Medium)
        .renderingStrategy(AudioDeviceManager.getInstance().isHeadsetOrSco(this.renderSymbolType) ?
        SymbolRenderingStrategy.MULTIPLE_OPACITY : SymbolRenderingStrategy.SINGLE)
        .width(this.getSpeakerPhoneSymbolFontSize())
        .height(this.getSpeakerPhoneSymbolFontSize())
        .id(this.isPressed ? 'callUI_components_VideoFuncBtn_public_sound_louder' :
          'callUI_components_VideoFuncBtn_defaultSpeakerIcon');
    }

    if (this.hasMultiDevice) {
      SymbolGlyph($r('sys.symbol.small_triangle_arrow_down_right_fill'))
        .fontSize(20)
        .draggable(false)
        .fontWeight(FontWeight.Regular)
        .fontColor([$r('app.color.white')])
        .margin({
          left: this.isNewFoldPhoneExternalScreen ? 38 : 45,
          top: this.isNewFoldPhoneExternalScreen ? 28 : 36
        })
        .opacity(this.btnOpactiy)
    }
  }

  @Builder
  buildSwitchCameraPhone() {
    SymbolGlyph($r(this.iconUrl()))
      .fontSize(this.getSymbolGlyphFontSize())
      .fontColor([this.isActive ? '#0A59F7' : this.iconFontColor()])
      .opacity(this.isDisable ? 0.4 : 1)
      .width(this.getSymbolGlyphFontSize())
      .height(this.getSymbolGlyphFontSize())
      .draggable(false)
  }

  @Builder
  buildMutePhone() {
    SymbolGlyph($r(this.iconUrl()))
      .fontSize($r('app.float.funbtn_image_width'))
      .fontColor([this.iconFontColor()])
      .width($r('app.float.funbtn_image_width'))
      .height($r('app.float.funbtn_image_width'))
      .id('callUI_components_VideoFuncBtn_muteIcon');
  }

  @Builder
  VideoBtn(color: EdgeColors | ResourceColor, width: Length | EdgeWidths, bgColor: ResourceColor) {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center
    }) {
      this.callImageShow(bgColor)
    }
  }

  @Builder
  callImageShow(bgColor: ResourceColor) {
    Stack() {
      Row()
        .width(this.getButtonWidth())
        .height(this.getButtonWidth())
        .borderRadius(this.getButtonBorderRadius())
        .backgroundColor(this.btnType === 'hangUp' ? $r('sys.color.warning') : Color.Transparent)
        .pointLight(this.isNewFoldPhoneExternalScreen ? null : {
          lightSource: {
            intensity: this.lightIntensity,
            positionX: '50%',
            positionY: '50%',
            positionZ: this.lightPositionZ
          },
          illuminated: this.enableLight ? this.illuminatedType : IlluminatedType.NONE,
          bloom: this.lightBloom
        });

      if (!Utils.getInstance().getIs2DProduct() && this.btnType === 'hangUp') {
        Button({type: ButtonType.Circle})
          .width(this.getButtonWidth())
          .height(this.getButtonWidth())
          .backgroundColor(this.handHpBgColor)
      }
      if (this.btnType === 'speaker') {
        this.buildSpeakerPhone();
      } else if (this.btnType === 'videoMute') {
        this.buildMutePhone();
      } else if (this.btnType === 'switchCamera') {
        this.buildSwitchCameraPhone();
      } else if (this.btnType === 'newCall') {
        Image($r(this.iconUrl()))
          .width(this.getSymbolGlyphFontSize())
          .height(this.getSymbolGlyphFontSize())
          .draggable(false)
          .opacity(this.isDisable ? 0.4 : 1);
      } else {
        SymbolGlyph($r(this.iconUrl()))
          .fontSize(this.getSymbolGlyphFontSize())
          .fontColor([this.iconFontColor()])
          .fontWeight(FontWeight.Medium)
          .opacity(this.isDisable ? 0.4 : 1)
          .width(this.getSymbolGlyphFontSize())
          .height(this.getSymbolGlyphFontSize())
          .draggable(false)
          .id('callUI_components_VideoFuncBtn_iconUrl');
      }
    }
    .width(this.getButtonWidth())
    .height(this.getButtonWidth())
    .borderRadius(this.getButtonBorderRadius())
    .border({
      width: Utils.getInstance().getIs2DProduct() ? 0 :
        this.btnType === 'hangUp' && !this.isNewFoldPhoneExternalScreen ? (this.isPressed ? 1.5 : 0) : 0,
      color: this.handHpBorderColor
    })
    .backgroundColor(this.isPressed ? (this.btnType === 'hangUp' ? $r('sys.color.warning') : `rgba(255,255,255,1.0)`) : bgColor)
  }

  build() {
    Column() {
      this.VideoBtn(this.btnType === 'handUp' ? $r('sys.color.warning') : $r('sys.color.icon_on_primary'),
        this.btnType === 'hangUp' ? 0 : 1,
        this.isActive ? 'rgba(255, 255, 255, 1)' : this.btnType === 'hangUp' ? Color.Transparent : this.btnBgColor)
      Text(this.iconText)
        .fontColor(this.isDisable ? $r('sys.color.font_on_tertiary') : $r('sys.color.font_on_secondary'))
        .fontSize($r('app.float.call_video_card_body_s_font'))
        .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
        .lineHeight($r('app.float.call_video_card_body_s_height'))
        .margin({ top: $r('sys.float.padding_level2') })
        .textOverflow({ overflow: TextOverflow.None })
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(this.isNewFoldPhoneExternalScreen ? 68 : 76)
    .enabled(!this.isDisable)
    .onTouch((event?: TouchEvent) => {
      if (!event) {
        return
      }
      this.lightTouchHp(event?.type);
    })
    .onClick(() => {
      this.btnClick();
      this.delaySendAccessibilityEvent(this.btnType);
    })
    .id(this.btnType)
    .accessibilityText(this.btnType === 'speaker' ? this.speakerReaderTxtStr : this.getBarrierFreeString())
    .accessibilityRole(AccessibilityRoleType.BUTTON)
  }
}