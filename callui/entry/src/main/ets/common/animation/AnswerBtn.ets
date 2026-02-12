/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import IncomingComVM from '../../viewmodel/IncomingComVM';
import { getFirstCallByState, getFirstCallByStateExcludeCall } from '../utils/CallListHelper';
import CallStateConst from '../constant/CallStateConst';
import CallColumnUtils from '../utils/CallColumnUtils';
import { StringUtil } from '../utils/StringUtil';
import { AccessibilityUtil } from '../utils/AccessiblityUtil';
import { VOICE_BROADCAST_SWITCH } from '../../common/utils/Constants';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { AppFuncBtnStyleData } from '../struct/TypeUtils';
import image from '@ohos.multimedia.image';

const TAG = 'AnswerBtn';
const ICON_WIDTH = 68;
const incomingVideoIcon: Resource = $r(`sys.symbol.video_fill`);

@Component
export default struct AnswerBtn {
  @Link mIncomingVM: IncomingComVM;
  @State backgroundAlpha: number = 1;
  @State scaleX: number = 0.88;
  @State scaleY: number = 0.88;
  @State scaleTwoX: number = 1.2;
  @State scaleTwoY: number = 1.2;
  @State scaleThreeX: number = 1.4;
  @State scaleThreeY: number = 1.4;
  @State alphaThree: number = 0.08;
  @State isStopAnimation: boolean = false;
  @State incomingIcon: Resource = $r('sys.symbol.phone_fill');
  @State answerBackgroundColor: Resource = $r('sys.color.confirm');
  @State animationCount: number = 0;
  @Link isVideoCall: boolean;
  @Link isSatelliteCall: boolean;
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('onPageShow') @Watch('onPageStateChange') isOnPageShow: boolean = true;
  @StorageLink('screenOff') @Watch('onPageStateChange') isScreenOff: boolean = false;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @StorageLink(VOICE_BROADCAST_SWITCH) @Watch('onBroadcastSwitchChange') voiceBroadcastSwitch: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();
  @StorageProp('isHyacinthMode') isHyacinthMode: boolean = false;
  private isDisappear: boolean = false;
  private isRejected: boolean = false; // 是否已经点击拒接按钮

  showIncomingA(): void {
    animateTo({
      duration: 300, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.showIncomingB();
      }
    }, () => {
      this.scaleX = 1;
      this.scaleY = 1;
    })
  }

  showIncomingB(): void {
    animateTo({
      duration: 700, curve: Curve.FastOutSlowIn, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.scaleX = 0.88;
      this.scaleY = 0.88;
    })
  }

  circleTwoA(): void {
    animateTo({
      duration: 200, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleTwoB();
      }
    }, () => {
      this.scaleTwoX = 1.1;
      this.scaleTwoY = 1.1;
    })
  }

  circleTwoB(): void {
    animateTo({
      duration: 250, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleTwoC();
      }
    }, () => {
      this.scaleTwoX = 1.4;
      this.scaleTwoY = 1.4;
    })
  }

  circleTwoC(): void {
    animateTo({
      duration: 550, curve: Curve.FastOutSlowIn, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.scaleTwoX = 1.2;
      this.scaleTwoY = 1.2;
    })
  }

  circleThreeScaleA(): void {
    animateTo({
      duration: 250, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleThreeScaleB();
      }
    }, () => {
      this.scaleThreeX = 1.3;
      this.scaleThreeY = 1.3;
    })
  }

  circleThreeScaleB(): void {
    animateTo({
      duration: 383, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleThreeScaleC();
      }
    }, () => {
      this.scaleThreeX = 1.7;
      this.scaleThreeY = 1.7;
    })
  }

  circleThreeScaleC(): void {
    animateTo({
      duration: 367, curve: Curve.FastOutSlowIn, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.scaleThreeX = 1.4;
      this.scaleThreeY = 1.4;
    })
  }

  circleThreeAlphaA(): void {
    animateTo({
      duration: 283, delay: 350, curve: Curve.Sharp, onFinish: () => {
        this.circleThreeAlphaB();
      }
    }, () => {
      this.alphaThree = 0.11;
    })
  }

  circleThreeAlphaB(): void {
    animateTo({
      duration: 367, curve: Curve.Sharp, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.alphaThree = 0.08;
    })
  }

  /**
   * Handling interface call hangup and rejection
   */
  private onReject() {
    this.mIncomingVM.onReject();
  }

  startIncomingAnimation(): void {
    this.showIncomingA();
    this.circleTwoA();
    this.circleThreeScaleA();
    this.circleThreeAlphaA();
    this.animationCount = 0;
  }

  /**
   * Answer the phone interface
   */
  private onAnswer() {
    if (this.isDisappear) {
      return;
    }
    LogUtils.i(TAG, 'onAnswer :');
    let primaryIncomingCall = this.mIncomingVM.primaryIncomingCall;
    this.mIncomingVM.onAnswer(this.isVideoCall);
    // don't stop the animation state when other incoming call exists
    if (this.mIncomingVM.callList.length > 1) {
      const callData = getFirstCallByStateExcludeCall(this.mIncomingVM.callList, CallStateConst.CALL_STATUS_INCOMING,
        primaryIncomingCall);
      if (callData) {
        return;
      }
    }
    this.isStopAnimation = true;
  }

  private getMargin() {
    if (this.isApplyNewStyle) {
      return 0;
    }
    if (this.curBp === 'sm' || this.curBp === 'xs' || this.curBp === 'lg') {
      return 0;
    }
    return 48;
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, `aboutToAppear voiceBroadcastSwitch:${this.voiceBroadcastSwitch}`);
    this.onBroadcastSwitchChange();
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear.');
    this.isDisappear = true;
    this.isStopAnimation = true;
  }

  onBroadcastSwitchChange() {
    LogUtils.i(TAG, `onBroadcastSwitchChange voiceBroadcastSwitch:${this.voiceBroadcastSwitch}`);
    if (this.voiceBroadcastSwitch) {
      setTimeout(() => {
        AccessibilityUtil.requestFocusForAccessibility('callUI_answerBtn');
      }, 450);
    }
  }

  onPageStateChange() {
    if (!this.isOnPageShow || this.isScreenOff) {
      this.isStopAnimation = true;
      return;
    }
    this.onBroadcastSwitchChange();
    const callData = getFirstCallByState(this.mIncomingVM.callList, CallStateConst.CALL_STATUS_INCOMING);
    if (callData) {
      this.isStopAnimation = false;
      this.startIncomingAnimation();
    }
  }

  getBottomBtnWidth() {
    if (this.isApplyNewStyle) {
      return this.funcBtnStyle.btnWidth;
    }
    return ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnWidth(this.isNewFoldPhoneExternalScreen);
  }

  getBottomBtnSymbolWidth() {
    if (this.isApplyNewStyle) {
      return this.funcBtnStyle.innerIconWidth;
    }
    return ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnSymbolWidth(this.isNewFoldPhoneExternalScreen);
  }

  build() {
    Row({ space: CallColumnUtils.getInstance().getRowSpace(this.curBp) }) {
      Column() {
        Button() {
          Stack() {
            Circle()
              .width(this.getBottomBtnWidth())
              .height(this.getBottomBtnWidth())
              .borderRadius(this.isApplyNewStyle ? this.funcBtnStyle.btnWidth / 2 :
                this.isNewFoldPhoneExternalScreen ? '28vp' : '32vp')
              .fill('#e84026')
              .margin({ left: this.getMargin(), right: this.getMargin() })

            SymbolGlyph($r('sys.symbol.phone_down_fill'))
              .fontSize(this.getBottomBtnSymbolWidth())
              .fontColor(['#ffffff'])
              .align(Alignment.Center)
              .width(this.getBottomBtnSymbolWidth())
              .height(this.getBottomBtnSymbolWidth())
              .fontWeight(FontWeight.Medium)
              .opacity(1)
              .draggable(false)
          }
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 拒接操作限流
          if (this.isRejected) {
            LogUtils.i(TAG, 'onReject failed. already hangup.');
            return;
          }
          LogUtils.i(TAG, 'onReject start.');
          this.onReject();
          // 第一路已接通，第二路打入时需要限制挂断按钮重复点击
          if (this.mIncomingVM?.callList.length === 2 &&
            this.mIncomingVM?.callList[0]?.callState === CallStateConst.CALL_STATUS_ACTIVE) {
            this.isRejected = true;
          }
        })
        .accessibilityText(this.screenReaderStatus ? StringUtil.formatResourceToString($r('app.string.hangUp')) : '')
      }
      .margin({ left: this.getMargin(), right: this.getMargin() })
      .alignSelf(ItemAlign.Center)
      .layoutWeight(1)

      Column() {
        Stack() {
          if (!this.isStopAnimation &&
            getFirstCallByState(this.mIncomingVM.callList, CallStateConst.CALL_STATUS_INCOMING)) {
            this.animationAnswerBtn()
          } else {
            this.nomalAnswerBtn()
          }
        }
        .margin({ left: this.getMargin(), right: this.getMargin() })
        .alignSelf(ItemAlign.Center)
        .onAreaChange((oldValue: Area, newValue: Area) => {
          let startPoint: number = Number(newValue.position.x);
          let centerPoint: number = startPoint + ICON_WIDTH / 2;
          AppStorage.setOrCreate('incomingCenterPoint', centerPoint);
        })
        .onClick((event: ClickEvent) => {
          this.onAnswer();
        })
        .gesture(LongPressGesture().onActionEnd(() => {
          LogUtils.i(TAG, 'long press end.');
          this.onAnswer();
        }))
        .accessibilityLevel('yes')
        .accessibilityText(this.screenReaderStatus ? StringUtil.formatResourceToString($r('app.string.answer')) : '')
        .accessibilityDescription(this.screenReaderStatus ? StringUtil.formatResourceToString($r('app.string.one_finger_double_click')) : '')
        .id('callUI_answerBtn')
      }
      .layoutWeight(1)
      .onAppear(() => {
        if (getFirstCallByState(this.mIncomingVM.callList, CallStateConst.CALL_STATUS_INCOMING)) {
          this.startIncomingAnimation();
        }
      })
    }
  }

  @Builder
  nomalAnswerBtn() {
    Button({ type: ButtonType.Circle })
      .backgroundColor(this.answerBackgroundColor)
      .width(this.getBottomBtnWidth())
      .height(this.getBottomBtnWidth())
    if (this.isSatelliteCall) {
      if (this.isHyacinthMode){
        Image($r('app.media.hyacinth_answer_btn'))
          .width(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
          .height(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
          .draggable(false)
      } else {
        SymbolGlyph($r('sys.symbol.phone_badge_satellite_fill'))
          .width(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
          .height(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
          .fontColor(['#FFFFFF'])
          .fontSize(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
      }
    } else {
      SymbolGlyph(this.isVideoCall ? incomingVideoIcon : this.incomingIcon)
        .width(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
        .height(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
        .fontColor(['#FFFFFF'])
        .fontSize(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.answer_button_image_width'))
    }
  }

  @Builder
  animationAnswerBtn() {
    Button({ type: ButtonType.Circle })
      .backgroundColor(this.answerBackgroundColor)
      .width(this.getBottomBtnWidth())
      .height(this.getBottomBtnWidth())
      .scale({ x: this.scaleX, y: this.scaleY })

    Button({ type: ButtonType.Circle })
      .backgroundColor(this.answerBackgroundColor)
      .width(this.getBottomBtnWidth())
      .height(this.getBottomBtnWidth())
      .opacity(0.18)
      .scale({ x: this.scaleTwoX, y: this.scaleTwoY })

    Button({ type: ButtonType.Circle })
      .backgroundColor(this.answerBackgroundColor)
      .width(this.getBottomBtnWidth())
      .height(this.getBottomBtnWidth())
      .opacity(this.alphaThree)
      .scale({ x: this.scaleThreeX, y: this.scaleThreeY })
    if (this.isSatelliteCall) {
      if (this.isHyacinthMode) {
        Image($r('app.media.hyacinth_answer_btn'))
          .width(36)
          .height(36)
          .scale({ x: this.scaleX, y: this.scaleY })
          .opacity(this.backgroundAlpha)
          .draggable(false)
      } else {
        SymbolGlyph($r('sys.symbol.phone_badge_satellite_fill'))
          .fontColor(['#FFFFFF'])
          .fontSize($r('app.float.answer_button_image_width'))
          .width($r('app.float.answer_button_image_width'))
          .height($r('app.float.answer_button_image_width'))
          .scale({ x: this.scaleX, y: this.scaleY })
          .opacity(this.backgroundAlpha)
          .draggable(false);
      }
    } else {
      SymbolGlyph(this.isVideoCall ? incomingVideoIcon : this.incomingIcon)
        .fontColor(['#FFFFFF'])
        .fontSize($r('app.float.answer_button_image_width'))
        .width($r('app.float.answer_button_image_width'))
        .height($r('app.float.answer_button_image_width'))
        .scale({ x: this.scaleX, y: this.scaleY })
        .opacity(this.backgroundAlpha)
        .draggable(false)
    }
  }
}