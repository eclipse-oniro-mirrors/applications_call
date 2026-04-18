/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

/**
 * @file: bottom button component
 */

import CallServiceProxy from '../../model/CallServiceProxy';
import LogUtils from '../utils/LogUtils';
import BottomViewModel from '../../viewmodel/BottomViewModel';
import DefaultCallData, { AppBtnStyleData, AppFuncBtnStyleData, AppWindowStyleData } from '../struct/TypeUtils';
import curves from '@ohos.curves';
import CallColumnUtils from '../utils/CallColumnUtils';
import { SelectDeviceContent } from './SelectDeviceContent';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import { isIncomingCall } from '../utils/CallListHelper';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import * as DeviceTypeConst from '../constant/DeviceTypeConst';
import { StringUtil } from '../utils/StringUtil';
import Utils from '../utils/utils';
import systemDateTime from '@ohos.systemDateTime';
import { HANG_UP_LTR_ANGLE, HANG_UP_RTL_ANGLE, SPEAKERPHONE_RTL_ANGLE } from '../utils/LanguageUtils';
import AudioDeviceManager from '../../model/audio/AudioDeviceManager';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { display, LengthMetrics } from '@kit.ArkUI';
import CallStateConst from '../constant/CallStateConst';
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import systemParameterEnhance from '@ohos.systemParameterEnhance';

const TAG = 'BottomBtn';

interface ImageList {
  type: string,
  img: Resource,
  index: number
}

@Component
export default struct BottomBtn {
  onItemTouch?: Function;
  @Link callData: DefaultCallData;
  @Link callList: Array<DefaultCallData>;
  @Link callListCount: number;
  @Link callState: number;
  private imageList: ImageList[] = [];
  @StorageLink('currentAudioDeviceIcon') @Watch('changeDeviceType') currentAudioDeviceIcon: Resource =
    $r('sys.symbol.speaker_wave_3_fill');
  @StorageLink('isShowVideoKeyBoard') isShowKeyboard: boolean = false;
  @StorageLink('speakerSelected') speakerSelected: boolean = false;
  @StorageLink('animationFinish') animationFinish: boolean = false;
  @StorageLink('isOnAnswerForMulti') isOnAnswerForMulti: boolean = false;
  @StorageLink('curBp') curBp: string = '';
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @Link @Watch('cancel') hasMultiDevice: boolean;
  @State mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  @State isDialogOpen: boolean = false;
  @State arrowLeft: number = 42;
  @State arrowTop: number = 0;
  @State btnOpactiy: number = 0.02;
  @State isAnimationStop: boolean = false;
  @State bagroundColor: Resource = $r('sys.color.warning');
  @State imageicon: Resource = $r('sys.symbol.phone_fill');
  @State translateX: number = 90.5;
  @State translateY: number = 0;
  @State angle: number = HANG_UP_RTL_ANGLE;
  @State iconOpacity: number = 1;
  @Link isAnswer: boolean;
  @State scaleX: number = 1;
  @State scaleY: number = 1;
  @State lightIntensity: number[] = [0];
  @State lightIntensityKeyboard: number = 0;
  @State lightIntensityHangUP: number = 0;
  @State lightIntensitySpeakerphone: number = 0;
  @State lightBloomKeyboard: number = 0;
  @State lightBloomHangUP: number = 0;
  @State lightBloomSpeakerphone: number = 0;
  @State lightIntensityOffset: number[] = [0];
  @State illuminatedTypeHangUP: IlluminatedType = IlluminatedType.BORDER_CONTENT;
  @State lightPositionZ: number = 90;
  @State hangUpBorderWidth: number = 1.5;
  @State isPressed: boolean = false;
  @State isPressedKeyboard: boolean = false;
  @State isPressedSpeaker: boolean = false;
  @State hangUpBgColor: ResourceColor = Color.Transparent;
  @State hangUpBorderColor: ResourceColor = Color.Transparent;
  @Consume lightUpdate: boolean;
  @Consume lightClipState: boolean;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @Consume foldChange: boolean;
  @State speakerAnimationOn: boolean = false;
  @State pressTimer: number = 0;
  @State deviceType: number = 0;
  touchStatusCallBack: (isTouchDown: boolean) => void = () => {
  };
  @StorageLink('isRTL') @Watch('isRTLChanged') isRTL: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isNewFoldPhoneInnerFullScreen') isNewFoldPhoneInnerFullScreen: boolean = false;
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('appWindow') appWindow: AppWindowStyleData = {
    maxWidth: undefined,
    maxHeight: undefined
  };
  @StorageLink('appBtnStyle') appBtnStyle: AppBtnStyleData = {
    btnWidth: 64,
    rowsGap: 20
  };
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();
  @StorageLink('btnBottomGap') btnBottomGap: number = 0;
  @StorageLink('btnLeftGap') btnLeftGap: number = 0;
  private moveDistanceX = 0;
  private moveDistanceY = 0;
  @State deviceSwitchCount: number = 0;
  private isMLR: boolean = systemParameterEnhance.getSync('const.build.product', '') === 'MLR';

  private isRTLChanged() {
    this.angle = this.isRTL ? HANG_UP_RTL_ANGLE : HANG_UP_LTR_ANGLE
  }

  @Builder
  selectDevice() {
    SelectDeviceContent({ dialogController: this.dialogController, switchCount: this.deviceSwitchCount });
  }

  dialogController?: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.select_device'),
      contentBuilder: () => {
        this.selectDevice();
      },
      contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
      buttons: [
        {
          value: $r('app.string.cancel'),
          action: () => {
            this.dialogController?.close();
            this.cancel();
          }
        }
      ]
    }),
    autoCancel: true,
    customStyle: false,
  })

  public aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.getImageList();
    this.mBottomViewModel.aboutToAppear();
    this.deviceType = this.mBottomViewModel.currentAudioDevice.deviceType;
    LogUtils.i(TAG, `this.deviceType:${this.deviceType}`);
  }

  cancel() {
    LogUtils.i(TAG, `cancel dialog:${!this.mBottomViewModel.isHaveMultiDevice}`);
    if (!this.mBottomViewModel.isHaveMultiDevice) {
      this.dialogController?.close();
    }
  }

  itemSize() {
    if (this.mBottomViewModel.isHaveMultiDevice) {
      if (JSON.stringify(this.currentAudioDeviceIcon) === JSON.stringify($r('sys.symbol.speaker_wave_3_fill')) ||
        JSON.stringify(this.currentAudioDeviceIcon) ===
        JSON.stringify($r('sys.symbol.earphone_16640_fill'))) {
        this.arrowTop = 0;
        this.arrowLeft = 42;
      } else {
        this.arrowTop = -3;
        this.arrowLeft = 36;
      }
    }
  }

  changeDeviceType() {
    LogUtils.i(TAG, `changeDeviceType: { id: ${this.currentAudioDeviceIcon.id} type: ${this.currentAudioDeviceIcon.type} }`);
    this.itemSize();
    this.deviceType = this.mBottomViewModel.currentAudioDevice.deviceType;
    if (this.mBottomViewModel.isHaveMultiDevice && this.deviceType !== DeviceTypeConst.DEVICE_SPEAKER &&
    this.speakerAnimationOn) {
      this.speakerAnimationOn = false;
    }
  }

  /**
   * get Image List
   */
  private getImageList() {
    let keyboard: ImageList = {
      type: 'keyboard',
      img: $r('sys.symbol.dial'),
      index: 0
    }

    let hangUP: ImageList = {
      type: 'hangUP',
      img: $r('sys.symbol.phone_down_fill'),
      index: 1
    }

    let speakerphone: ImageList = {
      type: 'speakerphone',
      img: $r('sys.symbol.ear'),
      index: 2
    }

    this.imageList = [
      keyboard,
      hangUP,
      speakerphone
    ]
  }

  /**
   * this method is to call the hangup interface
   */
  onHangUp() {
    LogUtils.i(TAG, 'onHangUp this.callData.callId : ' + this.callData.callId);
    if (Utils.getInstance().isConferenceCall(this.callData)) {
      CallServiceProxy.getInstance()?.getMainCallId(this.callData.callId, (mainId: number) => {
        this.mBottomViewModel.hangUpCall(mainId, this.callListCount);
      });
    } else {
      this.mBottomViewModel.hangUpCall(this.callData.callId, this.callList.length);
    }
    ReportUtil.getInstance()
      .reportIsDualCardOneInCallAndAnotherDialCancel(this.callList.length, this.callData.accountId,
        this.callData.callState);
  }

  /**
   * Image size
   */
  imgSizes(type: string) {
    if (type == 'keyboard') {
      if (this.isApplyNewStyle) {
        return this.funcBtnStyle.innerIconWidth;
      }
      return $r('app.float.funbtn_image_width');
    }
    if (type == 'speakerphone') {
      if (this.isApplyNewStyle) {
        return this.funcBtnStyle.innerIconWidth;
      }
      return $r('app.float.funbtn_image_width');
    }
    if (type == 'hangUP') {
      if (this.isApplyNewStyle) {
        return this.appBtnStyle.btnWidth;
      }
      return $r('app.float.call_button_width');
    }
    return 0;
  }

  /**
   * Button Event
   */
  onImgClick(type: string) {
    if (type === 'hangUP') {
      this.onHangUp();
    } else {
      if (this.callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
        LogUtils.w(TAG, `onImgClick call is disconnected ${type}`);
        return;
      }
      if (type === 'speakerphone') {
        this.handleClickCallBack();
        this.onSpeakerButtonClicked();
      } else if (type === 'keyboard' && this.onItemTouch !== undefined) {
        this.onItemTouch();
        this.handleClickCallBack();
        if (this.screenReaderStatus) {
          this.getAccessibilityFocus(this.postExecutionBroadcast(type));
        }
      }
    }
  }

  onSpeakerButtonClicked() {
    if (this.mBottomViewModel.isHaveMultiDevice) {
      LogUtils.i(TAG, 'onSpeakerButtonClicked dialogController.open');
      this.dialogController?.open();
      return;
    } else {
      this.mBottomViewModel.setButtonAudioDevice(this.callData.callId, this.callData.callType);
      this.dialogController?.close();
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.dialogController?.close();
    this.dialogController = undefined;
  }

  startAlpahAnimation(): void {
    animateTo({
      duration: 230,
      delay: 50,
      curve: Curve.Sharp,
      onFinish: () => {
        this.isAnimationStop = true;
      }
    }, () => {
      this.btnOpactiy = 1;
    })
  }

  startTranslateAnimation(): void {
    animateTo({
      duration: 280, curve: Curve.FastOutSlowIn, onFinish: () => {
        AppStorage.setOrCreate('isOnAnswerForMulti', false);
      }
    }, () => {
      this.translateX = 0;
      this.translateY = 0;
      this.angle = this.isRTL ? HANG_UP_RTL_ANGLE : HANG_UP_LTR_ANGLE
    })
  }

  backgroundColorAnimation(): void {
    animateTo({
      duration: 280, curve: Curve.Sharp, onFinish: () => {
        LogUtils.i(TAG, 'onFinish: backgroundGreen');
        this.bagroundColor = $r('sys.color.warning');
      }
    }, () => {
      this.bagroundColor = $r('sys.color.warning');
    })
  }

  getBarrierFreeString(currentAudioDeviceIcon: Resource): string {
    LogUtils.i(TAG, 'getBarrierFreeString ' + JSON.stringify(currentAudioDeviceIcon));
    if (!this.screenReaderStatus) {
      return '';
    }
    if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_SPEAKER) {
      return this.mBottomViewModel.isHaveMultiDevice ? StringUtil.formatResourceToString($r('app.string.switching_audio_channels')) :
      StringUtil.formatResourceToString($r('app.string.accessibility_change_phoneset'));
    } else if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_EARPIECE) {
      return this.mBottomViewModel.isHaveMultiDevice ?
      StringUtil.formatResourceToString($r('app.string.switching_audio_channels')) :
      StringUtil.formatResourceToString($r('app.string.accessibility_change_speaker'));
    } else if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_WIRED_HEADSET) {
      return StringUtil.formatResourceToString($r('app.string.wired_headset_selected'));
    } else if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_SCO) {
      return StringUtil.formatResourceToString($r('app.string.blueetooth_device_selected'));
    } else if (this.mBottomViewModel.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_HEARINGAID){
      return StringUtil.formatResourceToString($r('app.string.hearing_aids_device_selected'));
    } else {
      return '';
    }
  }

  getBarrierOtherTypeFreeString(type: string): string {
    if (!this.screenReaderStatus) {
      return '';
    }
    if (type === 'hangUP') {
      return StringUtil.formatResourceToString($r('app.string.hanging_up_voice_call'));
    } else if (type === 'keyboard') {
      return !this.isShowKeyboard ? StringUtil.formatResourceToString($r('app.string.show_dialpad')) :
      StringUtil.formatResourceToString($r('app.string.hide_dialpad'));
    }
    return '';
  }

  onInit(): void {
    this.translateX = 0;
    this.angle = this.isRTL ? HANG_UP_RTL_ANGLE : HANG_UP_LTR_ANGLE
    this.bagroundColor = $r('sys.color.warning');
  }

  private getMargin(type: string) {
    if (this.isApplyNewStyle) {
      return 0;
    }
    if (this.curBp === 'xs' || this.curBp === 'sm' || this.curBp === 'lg') {
      return 0;
    }
    if (type === 'keyboard' || type === 'speakerphone') {
      return 20;
    }
    return 0;
  }

  private getOffsetLeft() {
    if (this.curBp === 'md') {
      return '-90%';
    } else if (this.curBp === 'lg') {
      if (this.isApplyNewStyle) {
        return '-100%';
      }
      return '-150%';
    }
    return '50%';
  }

  private getOffsetRight() {
    if (this.curBp === 'md') {
      return '190%';
    } else if (this.curBp === 'lg') {
      if (this.isApplyNewStyle) {
        return '200%';
      }
      return '250%';
    }
    return '50%';
  }

  lightTouchHp(type: TouchType) {
    this.hangUpBorderColor = '#fffd7a64';
    if (type === TouchType.Down) {
      this.lightUpdate = false;
      this.foldChange = false;
      this.illuminatedTypeHangUP = IlluminatedType.NONE;
      this.lightIntensityHangUP = 6;
      this.lightBloomHangUP = 1;
      this.hangUpBgColor = '#40ffffff';
    } else if (type === TouchType.Up) {
      this.illuminatedTypeHangUP = IlluminatedType.BORDER_CONTENT;
      this.lightIntensityHangUP = 0;
      this.hangUpBgColor = Color.Transparent;
      this.lightBloomHangUP = 0;
      this.hangUpBorderColor = Color.Transparent;
    }
  }

  lightOnAnimate(itemType: string, index: number) {
    animateTo({
      duration: 333,
      delay: 0,
      curve: curves.cubicBezierCurve(0.0, 0.2, 0.2, 1),
    }, () => {
      if (this.curBp !== 'sm' && this.curBp !== 'xs') {
        this.lightIntensityOffset[index] = 2;
      }
      if (itemType === 'speakerphone') {
        this.lightIntensitySpeakerphone = 6;
        this.lightBloomSpeakerphone = 1;
      } else if (itemType === 'keyboard') {
        this.lightIntensityKeyboard = 6;
        this.lightBloomKeyboard = 1;
      }
    })
  }

  lightOffAnimate(itemType: string, index: number) {
    animateTo({
      duration: 200,
      delay: 0,
      curve: curves.cubicBezierCurve(0.0, 0.2, 0.2, 1),
    }, () => {
      if (this.curBp !== 'sm' && this.curBp !== 'xs') {
        this.lightIntensityOffset[index] = 0;
      }
      if (itemType === 'speakerphone') {
        this.lightIntensitySpeakerphone = 0;
        this.lightBloomSpeakerphone = 0;
      } else if (itemType === 'keyboard') {
        this.lightIntensityKeyboard = 0;
        this.lightBloomKeyboard = 0;
      }
    })
  }

  private lightTouch(event: TouchEvent | undefined, itemType: string, index: number) {
    switch (event?.type) {
      case TouchType.Down:
        if (itemType === 'speakerphone' && this.pressTimer === 0) {
          this.pressTimer = systemDateTime.getTime(false);
        }
        this.lightClipState = true;
        this.lightUpdate = false;
        this.foldChange = false;
        if (itemType === 'keyboard') {
          this.isPressedKeyboard = true;
        }
        this.lightOnAnimate(itemType, index);
        break;
      case TouchType.Move:
        if (itemType === 'speakerphone') {
          let now: number = systemDateTime.getTime(false);
          this.isPressedSpeaker = (this.pressTimer > 0 && now - this.pressTimer > 80)
        }
        break;
      case TouchType.Up:
      case TouchType.Cancel:
        if (itemType === 'keyboard') {
          this.isPressedKeyboard = false;
        } else if (itemType === 'speakerphone') {
          this.isPressedSpeaker = false;
        }
        this.lightOffAnimate(itemType, index);
      default:
        this.pressTimer = 0;
        break;
    }
  }

  private getOffsetLight(index: number, isLeft: boolean): PointLightStyle {
    let lightSource: LightSource = {
      intensity: this.lightIntensityOffset[index],
      positionX: isLeft ? this.getOffsetLeft() : this.getOffsetRight(),
      positionY: '50%',
      positionZ: this.lightPositionZ
    }
    let lightStyle: PointLightStyle = {
      lightSource: lightSource
    }
    return lightStyle;
  }

  private handleClickCallBack() {
    this.touchStatusCallBack(false);
  }

  private asyncHandleTouch(type: TouchType | undefined) {
    if (type === undefined) {
      return;
    }
    this.handleTouch(type);
  }

  private handleTouch(type: TouchType) {
    switch (type) {
      case TouchType.Down:
        this.touchStatusCallBack(true);
        break;
      case TouchType.Up:
      case TouchType.Cancel:
        this.touchStatusCallBack(false);
        break;
      default:
        break;
    }
  }

  @Builder
  currentAudioDeviceIconLogic(item: ImageList){
    SymbolGlyph(this.currentAudioDeviceIcon)
      .width(this.imgSizes(item.type))
      .height(this.imgSizes(item.type))
      .opacity(this.btnOpactiy)
      .draggable(false)
      .fontColor(AudioDeviceManager.getInstance()
        .isHeadsetOrSco(this.mBottomViewModel.currentAudioDevice.deviceType) ? ['#0A59f7', '#0A59f7'] :
        ((this.isPressedSpeaker || this.speakerSelected) ? ['#0A59F7'] : ['#FFFFFF']))
      .renderingStrategy(AudioDeviceManager.getInstance()
        .isHeadsetOrSco(this.mBottomViewModel.currentAudioDevice.deviceType) ?
      SymbolRenderingStrategy.MULTIPLE_OPACITY : SymbolRenderingStrategy.SINGLE)
      .fontSize(this.imgSizes(item.type))
      .fontWeight(FontWeight.Medium)
    if (item.type === 'speakerphone' && this.hasMultiDevice) {
      SymbolGlyph($r('sys.symbol.small_triangle_arrow_down_right_fill'))
        .fontSize(20)
        .fontWeight(FontWeight.Regular)
        .fontColor([$r('app.color.white')])
        .draggable(false)
        .position({ end: LengthMetrics.px(0), bottom: LengthMetrics.px(0) })
        .opacity(this.btnOpactiy)
    }
  }

  conditionOne(): boolean {
    LogUtils.i(TAG, `match conditionOne:{id:${this.currentAudioDeviceIcon.id} type:${this.currentAudioDeviceIcon.type}}`);
    return this.deviceType === DeviceTypeConst.DEVICE_SPEAKER && !this.speakerAnimationOn &&
      !this.hasMultiDevice;
  }

  showSpeakTouch(): boolean {
    let res = this.isPressedSpeaker && !this.hasMultiDevice;
    LogUtils.i(TAG, `showSpeakTouchIcon: ${res} { id: ${this.currentAudioDeviceIcon.id} type: ${this.currentAudioDeviceIcon.type} }`);
    return res;
  }

  @Builder
  buildFlexSpeakerIcon(item: ImageList) {
    if (this.conditionOne()) {
      this.buildSpeakerAnimOn();
    } else if (this.deviceType === DeviceTypeConst.DEVICE_EARPIECE &&
      !this.hasMultiDevice && this.speakerAnimationOn) {
      this.buildSpeakerAnimOff();
    } else {
      this.currentAudioDeviceIconLogic(item);
    }
  }

  @Builder
  buildSpeakerPhone(item: ImageList) {
    Stack() {
      Row()
        .width(this.getBottomBtnWidth())
        .height(this.getBottomBtnWidth())
        .borderRadius(this.getBottomBtnBorderRadius())
        .pointLight(this.isNewFoldPhoneExternalScreen ? null : {
          lightSource: {
            intensity: this.lightIntensitySpeakerphone,
            positionX: '50%',
            positionY: '50%',
            positionZ: this.foldChange ? 91 : this.lightPositionZ
          },
          illuminated: this.lightUpdate ? IlluminatedType.NONE : IlluminatedType.BORDER_CONTENT,
          bloom: this.lightBloomSpeakerphone
        })
        .backgroundColor(this.isPressedSpeaker && this.isNewFoldPhoneExternalScreen ? Color.White : null)
      this.buildFlexSpeakerIcon(item)
    }
    .pointLight(this.isNewFoldPhoneExternalScreen ? null : this.getOffsetLight(item.index, true))
  }

  @Builder
  buildKeyboard(item: ImageList) {
    Stack() {
      Row()
        .width(this.getBottomBtnWidth())
        .height(this.getBottomBtnWidth())
        .borderRadius(this.getBottomBtnBorderRadius())
        .pointLight(this.isNewFoldPhoneExternalScreen ? null : {
          lightSource: {
            intensity: this.lightIntensityKeyboard,
            positionX: '50%',
            positionY: '50%',
            positionZ: this.foldChange ? 91 : this.lightPositionZ
          },
          illuminated: this.lightUpdate ? IlluminatedType.NONE : IlluminatedType.BORDER_CONTENT,
          bloom: this.lightBloomKeyboard
        })
        .backgroundColor(this.isPressedKeyboard && this.isNewFoldPhoneExternalScreen ? Color.White : null)
      SymbolGlyph(this.isPressedKeyboard ? $r('sys.symbol.dial') : item.img)
        .fontColor(this.isPressedKeyboard ? ['rgba(0,0,0,0.9)'] : ['#FFFFFF'])
        .fontSize(this.imgSizes(item.type))
        .fontWeight(FontWeight.Medium)
        .width(this.imgSizes(item.type))
        .height(this.imgSizes(item.type))
        .scale({ x: this.scaleX, y: this.scaleY })
        .animation({ curve: curves.interpolatingSpring(10, 1, 410, 38) })
        .opacity(!SplitScreenManager.getInstance().callBottomKeyboardBtnEnable(this.splitScreenType) ?
          0.4 : this.btnOpactiy)
        .draggable(false)
        .onTouch((event?: TouchEvent) => {
          this.onKeyboardTouch(item, event);
        })
    }
    .pointLight(this.isNewFoldPhoneExternalScreen ? null : this.getOffsetLight(item.index, true))
  }

  onKeyboardTouch(item: ImageList, event?: TouchEvent) {
    if (event?.type === TouchType.Down) {
      this.scaleX = 0.9;
      this.scaleY = 0.9;
    } else if (event?.type === TouchType.Up) {
      this.scaleX = 1;
      this.scaleY = 1;
    }
  }

  @Builder
  buildHangUp(item: ImageList) {
    Stack() {
      Stack() {
        Circle()
          .width(this.getBottomBtnWidth())
          .height(this.getBottomBtnWidth())
          .borderRadius(this.getBottomBtnBorderRadius())
          .foregroundColor(this.hangUpBgColor)
          .backgroundColor(this.bagroundColor)
          .border({
            width: Utils.getInstance().getIs2DProduct() || this.isNewFoldPhoneExternalScreen ? 0 : 1.5,
            color: this.hangUpBorderColor
          })

        SymbolGlyph(this.imageicon)
          .fontSize($r('app.float.funbtn_image_width'))
          .fontColor(['#ffffff'])
          .width($r('app.float.funbtn_image_width'))
          .height($r('app.float.funbtn_image_width'))
          .fontWeight(FontWeight.Medium)
          .rotate({ angle: this.angle })
          .opacity(this.iconOpacity)
          .draggable(false)
      }
      .width('100%')
      .height('100%')
      .borderRadius(this.getBottomBtnBorderRadius())
      .translate({ x: this.translateX, y: this.translateY })
      .visibility(this.animationFinish || (!isIncomingCall(this.callData.callState) && !this.isAnswer) ?
      Visibility.Visible : Visibility.Hidden)
      .pointLight(this.isNewFoldPhoneExternalScreen ? null : {
        lightSource: {
          intensity: this.lightIntensityHangUP,
          positionX: '50%',
          positionY: '50%',
          positionZ: this.foldChange ? 91 : this.lightPositionZ
        },
        illuminated: this.lightUpdate ? IlluminatedType.NONE : this.illuminatedTypeHangUP,
        bloom: this.lightBloomHangUP
      })
      .onTouch((event?: TouchEvent) => {
        if (!event) {
          return;
        }
        this.lightTouchHp(event?.type);
        this.handleTouch(event?.type);
      })
    }
    .pointLight(this.isNewFoldPhoneExternalScreen ? null : this.getOffsetLight(item.index, true))
  }

  @Builder
  newGridItem(item: ImageList) {
    GridItem() {
      Stack() {
        Column() {
          this.flexBuildFunction(item);
        }
        .gesture(PanGesture({ distance: 0 })
          .onActionStart((event: GestureEvent) => {
            if (event && event.fingerList && event.fingerList.length > 0) {
              let fingerInfo = event.fingerList[0];
              if (fingerInfo !== null && fingerInfo !== undefined) {
                this.moveDistanceX = fingerInfo.localX;
                this.moveDistanceY = fingerInfo.localY;
              }
            } else {
              LogUtils.i(TAG, `event message Incomplete`);
            }
          })
          .onActionEnd((event: GestureEvent) => {
            let moveXisInArea: boolean = ((this.moveDistanceX + event.offsetX) > 0) &&
              ((this.moveDistanceX + event?.offsetX) < (this.isNewFoldPhoneExternalScreen ? 54 : 64));
            let moveYisInArea: boolean = ((this.moveDistanceY + event.offsetY) > 0) &&
              ((this.moveDistanceY + event?.offsetY) < (this.isNewFoldPhoneExternalScreen ? 54 : 64));
            LogUtils.i(TAG, `moveXisInArea value: ${moveXisInArea} moveYisInArea value : ${moveYisInArea}`)
            if (moveXisInArea && moveYisInArea) {
              this.onImgClick(item.type);
            }
          })
        )
      }
      .width(this.getBottomBtnWidth())
      .height(this.getBottomBtnWidth())
      .backgroundEffect(item.type === 'hangUP' ? null : (item.type === 'speakerphone' && this.speakerSelected) ?
        {
          radius: 80,
          saturation: 1.9,
          brightness: 1.0,
          color: $r('app.color.active_true_color')
        } :
        {
          radius: 120,
          saturation: 1.1,
          brightness: 1.0,
          color: $r('app.color.active_false_color')
        }, { disableSystemAdaptation: true })
      .backgroundColor(item.type === 'hangUP' ? null : (item.type === 'speakerphone' && this.speakerSelected) ?
        'rgba(255, 255, 255, 0.9)' : 'rgba(255, 255, 255, 0.15)')
      .borderRadius(this.getBottomBtnBorderRadius())
      .opacity(this.btnOpactiy)
      .pointLight(this.isNewFoldPhoneExternalScreen ? null : this.getOffsetLight(item.index, false))
      .onTouch((event?: TouchEvent) => {
        if (item.type !== 'hangUP') {
          if (this.callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
            return;
          }
          this.lightTouch(event, item.type, item.index);
          this.asyncHandleTouch(event?.type);
        }
      })
      .onClick(() => {
        this.onImgClick(item.type);
      })
      .accessibilityGroup(true)
      .margin({ left: this.getMargin(item.type), right: this.getMargin(item.type) })
      .accessibilityText(item.type === 'speakerphone' ? this.getBarrierFreeString(this.currentAudioDeviceIcon) :
      this.getBarrierOtherTypeFreeString(item.type))
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .enabled(item.type === 'keyboard' ?
      SplitScreenManager.getInstance().callBottomKeyboardBtnEnable(this.splitScreenType) : true)
    }
    .align(Alignment.Center)
  }

  getAccessibilityFocus(textAccess: string) {
    let eventInfo: accessibility.EventInfo = ({
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.callui',
      triggerAction: 'click',
      textAnnouncedForAccessibility: textAccess,
    });
    accessibility.sendAccessibilityEvent(eventInfo).then(() => {
      LogUtils.i(TAG, `Succeeded in send event,eventInfo is ${eventInfo}`);
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, `failed to send event , Code is ${err.code}, message is ${err.message}`);
    });
  }

  postExecutionBroadcast(type: string): string {
    if (!this.screenReaderStatus) {
      return '';
    }
    if (type === 'keyboard') {
      return !this.isShowKeyboard ? StringUtil.formatResourceToString($r('app.string.hide_dialpad')) :
      StringUtil.formatResourceToString($r('app.string.show_dialpad'));
    } else if (type === 'speakerphone') {
      return this.getBarrierFreeString(this.currentAudioDeviceIcon);
    }
    return '';
  }

  @Builder
  flexBuildFunction(item: ImageList) {
    if (item.type === 'speakerphone') {
      this.buildSpeakerPhone(item);
    } else if (item.type === 'keyboard') {
      this.buildKeyboard(item);
    } else if (item.type === 'hangUP') {
      this.buildHangUp(item);
    }
  }

  speakerImgArrOn() {
    let arr: ImageFrameInfo[] = [];
    for (let i = 1; i < 18; i++) {
      let name = `app.media.speaker${i}`;
      arr.push({ src: $r(name) });
    }
    return arr;
  }

  @Builder
  buildSpeakerAnimOn() {
    ImageAnimator()
      .images(
        this.speakerImgArrOn()
      )
      .width($r('app.float.call_button_width'))
      .height($r('app.float.call_button_width'))
      .duration(550)
      .iterations(1)
      .fillMode(FillMode.Forwards)
      .state(AnimationStatus.Running)
      .onFinish(() => {
        this.speakerAnimationOn = true;
      })
      .rotate({ angle: this.isRTL ? SPEAKERPHONE_RTL_ANGLE : 0 })
  }

  speakerImgArrOff() {
    let arr: ImageFrameInfo[] = [];
    for (let i = 18; i < 35; i++) {
      let name = `app.media.speaker${i}`;
      arr.push({ src: $r(name) });
    }
    return arr;
  }

  getColumnsGap() {
    if (this.isApplyNewStyle) {
      return this.btnLeftGap;
    }
    if (this.isNewFoldPhoneInnerFullScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return $r('app.float.new_form_foldphone_func_btn_columns_gap');
    }
    return CallColumnUtils.getInstance()
      .getItemSpace(this.curBp, this.isNewFoldPhoneExternalScreen)
  }

  getGridRowMarginLeft() {
    if (this.isApplyNewStyle) {
      return 0;
    }
    if (this.isNewFoldPhoneExternalScreen) {
      return $r('sys.float.padding_level11');
    }
    if (this.isNewFoldPhoneInnerFullScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return $r('app.float.new_form_foldphone_func_btn_margin_space');
    }
    return CallColumnUtils.getInstance().getKeyBordMarginSpace(this.curBp);
  }

  getGridRowMarginTop() {
    try {
      if (this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) {
        return $r('sys.float.padding_level8');
      }
      if (display.getDefaultDisplaySync().orientation === display.Orientation.LANDSCAPE_INVERTED && this.isMLR &&
        !this.isShowKeyboard) {
        return $r('sys.float.padding_level2');
      }
      return 0;
    } catch (error) {
      LogUtils.e(TAG, 'Error in getGridRowMarginTop' + error?.code)
      return 0;
    }
  }

  @Builder
  buildSpeakerAnimOff() {
    ImageAnimator()
      .images(
        this.speakerImgArrOff()
      )
      .width($r('app.float.call_button_width'))
      .height($r('app.float.call_button_width'))
      .duration(550)
      .iterations(1)
      .fillMode(FillMode.Forwards)
      .state(AnimationStatus.Running)
      .onFinish(() => {
        this.speakerAnimationOn = false;
      })
      .rotate({ angle: this.isRTL ? SPEAKERPHONE_RTL_ANGLE : 0 })
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({
        span: {
          xs: 2,
          sm: 4,
          md: this.isApplyNewStyle ? 8 : 6,
          lg: this.isApplyNewStyle ? 12 : 8
        },
        offset: { md: this.isApplyNewStyle ? 0 : 1,
          lg: this.isApplyNewStyle ? 0 : 2
        }
      }) {
        Grid() {
          ForEach(this.imageList, (item: ImageList,) => {
            this.newGridItem(item)
          })
        }
        .clip(false)
        .width(this.isApplyNewStyle ? (this.appBtnStyle.btnWidth * 3 + this.btnLeftGap * 2) : 'auto')
        .columnsGap(this.getColumnsGap())
        .height(this.isApplyNewStyle ? this.appBtnStyle.btnWidth : ScreenAdapterUtils.getInstance()
          .getFuncBtnWidth(this.isNewFoldPhoneExternalScreen)) // Height of the call answer button
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr')
      }
    }
    .margin({
      left: this.getGridRowMarginLeft(),
      right: this.getGridRowMarginLeft(),
      top: this.getGridRowMarginTop()
    })
    .id('callui_BottomBtn_GridRow')
    .onAppear(() => {
      this.buildOnApperFunc();
    })
  }

  private buildOnApperFunc() {
    if (this.isOnAnswerForMulti) {
      let centerPoint: number | undefined = AppStorage.get('incomingCenterPoint');
      if (centerPoint !== undefined) {
        this.translateX = centerPoint;
      }
      this.bagroundColor = $r('sys.color.confirm');
      this.iconOpacity = 1;
      this.startTranslateAnimation();
      this.startAlpahAnimation();
      this.backgroundColorAnimation();
    } else if (this.isAnswer) {
      this.startAlpahAnimation();
      this.onInit();
    } else {
      this.onInit();
      this.btnOpactiy = 1;
    }
  }

  getBottomBtnWidth() {
    if (this.isApplyNewStyle) {
      return this.appBtnStyle.btnWidth;
    }
    return ScreenAdapterUtils.getInstance().getFuncBtnWidth(this.isNewFoldPhoneExternalScreen);
  }

  getBottomBtnBorderRadius() {
    if (this.isApplyNewStyle) {
      return this.appBtnStyle.btnWidth / 2;
    }
    return this.isNewFoldPhoneExternalScreen ? '28vp' : '32vp';
  }
}
