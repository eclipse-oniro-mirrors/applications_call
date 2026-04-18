/**
 * Copyright (c) 2022-2023 Huawei Device Co., Ltd.
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
import Method from '../utils/Method';
import LogUtils from '../utils/LogUtils';
import systemDateTime from '@ohos.systemDateTime';
import { BusinessError } from '@ohos.base';
import { curves, promptAction } from '@kit.ArkUI';
import { StringUtil } from '../utils/StringUtil';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import accessibility from '@ohos.accessibility';
import { RECORDER_START_STATUS } from '../constant/CallRecorderConst';
import { AppWindowStyleData, AppBtnStyleData, AppFuncBtnStyleData } from '../struct/TypeUtils';
import { isTwoInOne } from '../utils/DeviceTypeUtils';
import { SystemMode } from '../utils/SystemMode';
import Utils from '../utils/utils';
// import { hdsEffect } from '@kit.UIDesignKit';

const TAG = 'FuncBtn';

@Component
export default struct FuncBtn {
  @State btnType: string = '';
  @State iconDefaultUrl: string = '';
  @State iconDisableUrl: string = this.iconDefaultUrl;
  @State iconActiveUrl: string = this.iconDefaultUrl;
  @State iconTouchUrl: string = this.iconDefaultUrl;
  @State iconDisableFontColor: string = '';
  @State iconDefaultFontColor: string = '';
  @State iconActiveFontColor: string = '';
  @State iconTouchFontColor: string = '';
  @State isActive: boolean = false;
  @Prop isDisable: boolean = false;
  @State isPenglai: boolean = false;
  @State isPressed: boolean = false;
  @State iconText: Resource = $r('app.string.recording');
  @State lightIntensity: number = 0;
  @State lightIntensityOffset: number = 0;
  @State lightPositionZ: number = 90;
  @State lightBloom: number = 0;
  @State lightBgColor: ResourceColor = 'rgba(255, 255, 255, 0.15)';
  @Prop @Watch('setFuncBtnWidth') textInButton: boolean = false;
  @Prop recordBtnText: string = '';
  btnClick: Function = (btnType: string) => {
  };
  @StorageProp('curBp') curBp: string = '';
  @Consume lightUpdate: boolean;
  @Consume lightClipState: boolean;
  @Consume foldChange: boolean;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') @Watch('setFuncBtnWidth') isNewFoldPhoneExternalScreen: boolean = false;
  @State funcBtnWidth: Length = $r('app.float.call_button_width');
  @State funcBtnHeight: Length = $r('app.float.call_button_width');
  @Prop isRecordAnimationActive: boolean;
  @State pressTimer: number = 0;
  @StorageLink('isApplyNewStyle') @Watch('applyNewStyleChange') isApplyNewStyle: boolean = false;
  @StorageLink('appWindow') appWindow: AppWindowStyleData = {
    maxWidth: undefined,
    maxHeight: undefined
  };
  @StorageLink('appBtnStyle') @Watch('applyNewStyleChange') appBtnStyle: AppBtnStyleData = {
    btnWidth: 64,
    rowsGap: 20
  };
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();
  @StorageLink('btnBottomGap') btnBottomGap: number = 0;
  @StorageLink('btnLeftGap') btnLeftGap: number = 0;
  @StorageLink('isOutdoorTravel') isOutdoorTravel: boolean = SystemMode.getInstance().isOutdoorTravel();
  // @State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();
  @State isSatelliteCall: boolean = false;
  private isIncoming: boolean = true;
  private recorderStartTime: number = -1;
  private activeBackGroudColor: ResourceColor = 'rgba(255, 255, 255, 0.9)';
  private isNotContacted: boolean = false;
  touchStatusCallBack: (isTouchDown: boolean) => void = () => {
  };

  recordIsActive(): boolean {
    return this.btnType === 'record' && this.isActive;
  }

  getBarrierFreeString(): string {
    if (!this.screenReaderStatus) {
      return '';
    }

    let str: string = StringUtil.formatResourceToString(this.iconText);
    if (this.btnType === 'add' || this.btnType === 'video' || this.btnType === 'msg' ||
      this.btnType === 'remind' || this.btnType === 'voiceCall' ||
      this.btnType === 'exchange' || this.btnType === 'merge') {
      return str;
    }

    if (this.btnType === 'contact') {
      return StringUtil.formatResourceToString($r('app.string.contactPerson'));
    }

    if (this.btnType === 'keep') {
      return !this.isActive ? StringUtil.formatResourceToString($r('app.string.keep')) :
      StringUtil.formatResourceToString($r('app.string.cancel_waiting'));
    }

    if (this.btnType === 'mute') {
      return !this.isActive ? StringUtil.formatResourceToString($r('app.string.call_mute_on')) :
      StringUtil.formatResourceToString($r('app.string.unmute'));
    }

    if (this.btnType === 'record') {
      return !this.isActive ? StringUtil.formatResourceToString($r('app.string.recording')) :
        StringUtil.formatResourceToString($r('app.string.recorded')) +
        Utils.getInstance().getAccessibilityTextOfTime(this.recordBtnText) + ' ' +
        StringUtil.formatResourceToString($r('app.string.call_turn_off_recording'));
    }
    return '';
  }

  /**
   * Button group picture change control
   *
   * @return {string} - return iconUrl
   */
  iconUrl() {
    if (this.isDisable && this.iconDisableUrl) {
      LogUtils.d(TAG, 'iconUrl this.isDisable : ' + this.isDisable);
      return this.iconDisableUrl;
    }
    if (this.isPenglai || this.disableCelia()) {
      return this.iconDisableUrl;
    }
    if (this.isPressed) {
      return this.iconTouchUrl;
    }
    if (this.btnType === 'exchange') {
      return this.iconDefaultUrl ? this.iconDefaultUrl : this.iconActiveUrl;
    }
    return this.isActive && this.iconDefaultUrl ? this.iconActiveUrl : this.iconDefaultUrl;
  }

  /**
   * Button group picture change control
   *
   * @return {string} - return iconFontColor
   */
  iconFontColor() {
    if (this.isDisable && this.iconDisableUrl) {
      return this.iconDisableFontColor;
    }
    if (this.isPenglai || this.disableCelia()) {
      return this.iconDisableFontColor;
    }
    if (this.isPressed) {
      return this.iconTouchFontColor;
    }
    if (this.btnType === 'exchange') {
      return this.iconDefaultUrl ? this.iconDefaultFontColor : this.iconActiveFontColor;
    }
    return this.isActive && this.iconDefaultUrl ? this.iconActiveFontColor : this.iconDefaultFontColor;
  }

  /**
   * Button group  change picture
   */
  changeBtn(type: string) {
    const btnName = ['record'];
    if (Method.includes(btnName, type)) {
      this.isActive = !this.isActive;
    }
  }

  private getMargin() {
    if (this.isApplyNewStyle) {
      return 0;
    }
    if (this.curBp === 'sm' || this.curBp === 'xs' || this.curBp === 'lg' || this.curBp === 'md') {
      return 0;
    }
    if (this.btnType === 'record' || this.btnType === 'video' || this.btnType === 'add' ||
      this.btnType === 'contact' || this.btnType === 'merge' || this.btnType === 'exchange' ||
      this.btnType === 'mute' || this.btnType === 'keep') {
      return 20;
    }
    if (this.btnType === 'msg' || this.btnType == 'remind') {
      return 40;
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

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    if (this.btnType === 'record') {
      systemDateTime.getRealActiveTime(false, (error: BusinessError, time: number) => {
        this.recorderStartTime = time;
        LogUtils.i(TAG, `aboutToAppear, recorderStartTime: ${this.recorderStartTime}`);
      });
    }
    this.setFuncBtnWidth();
    this.initPengLaiStatus();
  }

  private initPengLaiStatus() {
    if (!SystemMode.getInstance().isModePenglai()) {
      this.isPenglai = false;
      return;
    }
    if (['callAssistant','summarize', 'video', 'add', 'remind'].includes(this.btnType)) {
      this.isPenglai = true;
      return;
    }
    if (this.isSatelliteCall && this.btnType === 'msg') {
      this.isPenglai = true;
      return;
    }
  }

  private disableCelia(): boolean {
    if (this.isPenglai) {
      return true;
    }
    const validBtnTypes = ['callAssistant', 'summarize'];
    if (!validBtnTypes.includes(this.btnType)) {
      return false;
    }
    if (this.isOutdoorTravel) {
      return true;
    }
    return false;
  }

  imageFrameInfoArray(): ImageFrameInfo[] {
    let imageFrameInfoArray: ImageFrameInfo[] = [];
    const replacements: Record<string, number> = {
      '17': 15,
      '18': 14,
      '19': 13,
      '20': 12,
      '21': 11,
      '22': 10,
      '23': 9,
      '24': 8,
      '25': 7,
      '26': 6,
      '27': 5,
      '28': 4,
      '29': 3,
    };
    let imageNumber = 1;
    for (let i = 1; i < 30; i++) {
      imageNumber = i;
      if (replacements[i]) {
        imageNumber = replacements[i];
      }
      imageFrameInfoArray.push({ src: $r(`app.media.recording${imageNumber}`) });
    }
    return imageFrameInfoArray;
  }

  @Builder
  buildRecordAnim() {
    ImageAnimator()
      .images(this.imageFrameInfoArray())
      .width($r('app.float.wh_value_48'))
      .height($r('app.float.wh_value_48'))
      .duration(1000)
      .iterations(-1)
      .fillMode(FillMode.None)
      .state(this.isRecordAnimationActive ? AnimationStatus.Running : AnimationStatus.Paused)
  }

  lightOn() {
    this.lightUpdate = false;
    this.lightClipState = false;
    this.foldChange = false;
    this.lightBgColor = 'rgba(255, 255, 255, 0.3)';
    animateTo({
      duration: 333,
      delay: 0,
      curve: curves.cubicBezierCurve(0.0, 0.2, 0.2, 1),
    }, () => {
      if (this.curBp !== 'sm' && this.curBp !== 'xs') {
        this.lightIntensityOffset = 2;
      }
      this.lightIntensity = 6;
      this.lightBloom = 1;
    })
  }

  lightOff() {
    animateTo({
      duration: 200,
      delay: 0,
      curve: curves.cubicBezierCurve(0.0, 0.2, 0.2, 1),
    }, () => {
      this.lightIntensityOffset = 0;
      this.lightIntensity = 0;
      this.lightBloom = 0;
      this.lightBgColor = 'rgba(255, 255, 255, 0.15)';
    })
  }

  @Builder
  buildLight() {
    Row()
      .width(this.funcBtnWidth)
      .height(this.funcBtnHeight)
      .borderRadius(this.getBorderRadius())
      .pointLight(this.isNewFoldPhoneExternalScreen ? null : {
        lightSource: {
          intensity: this.lightIntensity,
          positionX: '50%',
          positionY: '50%',
          positionZ: this.foldChange ? 91 : this.lightPositionZ
        },
        illuminated: this.lightUpdate ? IlluminatedType.NONE : IlluminatedType.BORDER_CONTENT,
        bloom: this.lightBloom
      })
  }

  getAccessibilityFocus(customId: string, duration: number) {
    setTimeout(() => {
      let eventInfo: accessibility.EventInfo = ({
        type: 'requestFocusForAccessibility',
        bundleName: 'com.ohos.callui',
        triggerAction: 'click',
        customId: customId
      });
      accessibility.sendAccessibilityEvent(eventInfo).then(() => {
        LogUtils.i(TAG, `getAccessibilityFocus Succeeded in send event, eventInfo is ${JSON.stringify(eventInfo)}`)
      });
    }, duration);
  }

  build() {
    Column() {
      if (this.isIncoming) {
        SymbolGlyph($r(this.iconUrl()))
          .fontSize(this.isApplyNewStyle ? this.funcBtnStyle.incomingIconWidth : $r('app.float.wh_value_24'))
          .fontColor(this.disableCelia() ? ['rgba(255, 255, 255, 0.4)'] : ['#ffffff'])
          .width(this.isApplyNewStyle ? this.funcBtnStyle.incomingIconWidth : 24)
          .height(this.isApplyNewStyle ? this.funcBtnStyle.incomingIconWidth : 24)
          .draggable(false)
          .opacity(this.isPressed ? $r('sys.float.alpha_secondary') : 1)
          .margin({ left: this.getMargin(), right: this.getMargin() })
      } else {
        this.flexBuildFunction()
      }
      if (!this.textInButton) {
        Text(this.recordIsActive() ? this.recordBtnText : this.iconText)
          .fontColor(this.getBtnFontColor())
          .fontSize(this.isApplyNewStyle ? this.funcBtnStyle.outerTextSize : $r('app.float.call_card_body_m_font'))
          .height(this.isApplyNewStyle ? this.funcBtnStyle.outerTextHeight : $r('app.float.call_card_body_m_height'))
          .lineHeight(this.isApplyNewStyle ? this.funcBtnStyle.outerTextHeight :
            $r('app.float.call_card_body_m_height'))
          .opacity(this.isIncoming && this.isPressed ? $r('sys.float.alpha_secondary') : 1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .minFontSize(this.isNewFoldPhoneExternalScreen ? '9vp' : '14vp')
          .maxFontSize('14vp')
          .width(this.isApplyNewStyle && !this.isIncoming ? (this.funcBtnStyle.btnWidth + this.btnLeftGap - 8) : 'auto')
          .textAlign(this.isApplyNewStyle && !this.isIncoming ? TextAlign.Center : TextAlign.Start)
          .margin({
            top: this.isApplyNewStyle ? this.funcBtnStyle.btnLabelGap : this.isIncoming ?
              (this.isNewFoldPhoneExternalScreen ? $r('sys.float.padding_level1') : $r('sys.float.padding_level4')) :
              $r('sys.float.padding_level2'),
            bottom: this.isNewFoldPhoneExternalScreen && !this.isIncoming ? 2 : 0,
          });
      }
    }
    .enabled(!this.isDisable)
    .onTouch(async event => {
      this.onTouchFunction(event);
      if (this.pressTimer == 0) {
        this.pressTimer = await systemDateTime.getRealActiveTime(false);
      }
    })
    .onClick(async () => {
      if (this.isPenglai || this.disableCelia()) {
        promptAction.showToast({
          message: $r('app.string.not_support_toast'),
          duration: 2000
        });
        LogUtils.i(TAG, `mode is penglai show prmptAction then return`);
        return;
      }
      if (this.btnType === 'record') {
        this.getAccessibilityFocus(this.btnType, 500);
        let now: number = await systemDateTime.getRealActiveTime(false);
        let status: boolean = this.isActive;
        let recorderStatus = AppStorage.get<string>('recorderStatus');
        LogUtils.i(TAG, `recorderStatus: ${recorderStatus}`);
        if (now - this.recorderStartTime < 500 && recorderStatus === RECORDER_START_STATUS) {
          LogUtils.w(TAG, 'recorderStartTime less 500ms')
          return;
        } else if (!status) {
          this.recorderStartTime = now;
        }
      }
      if (this.btnType === 'keep') {
        this.getAccessibilityFocus(this.btnType, 1000);
      }
      this.changeBtn(this.btnType);
      this.btnClick(this.btnType);
    })
    .id(this.btnType)
    .accessibilityGroup(true)
    .accessibilityText(this.getBarrierFreeString())
    .accessibilityRole(AccessibilityRoleType.BUTTON)
  }

  private getBtnFontColor(): ResourceColor {
    if (this.isDisable) {
      return $r('sys.color.font_on_tertiary');
    }
    if (this.textInButton) {
      return this.isActive ? $r('sys.color.font_emphasize') : $r('sys.color.font_on_primary');
    } else {
      if (this.isPenglai) {
        return $r('sys.color.font_on_secondary');
      }
      return this.isIncoming ? $r('sys.color.font_on_primary') : $r('sys.color.font_on_secondary');
    }
  }

  @Builder
  flexBuildFunction() {
    Stack({ alignContent: Alignment.Center }) {
      if (isTwoInOne()) {
        Row()
          .width(this.funcBtnWidth)
          .height(this.funcBtnHeight)
          .borderRadius(this.getBorderRadius())
          .pointLight({
            lightSource: {
              intensity: this.lightIntensityOffset,
              positionX: this.getOffsetLeft(),
              positionY: '50%',
              positionZ: this.foldChange ? (this.lightPositionZ + 1) : this.lightPositionZ
            }
          });
      }
      Row()
        .width(this.funcBtnWidth)
        .height(this.funcBtnHeight)
        .borderRadius(this.getBorderRadius())
        .id('callUI_components_FuncBtn_StackRow_row_empty')
        .pointLight(this.isNewFoldPhoneExternalScreen ? null : {
          lightSource: {
            intensity: this.lightIntensity,
            positionX: '50%',
            positionY: '50%',
            positionZ: this.foldChange ? (this.lightPositionZ + 1) : this.lightPositionZ
          },
          illuminated: this.lightUpdate ? IlluminatedType.NONE : IlluminatedType.BORDER_CONTENT,
          bloom: this.lightBloom
        })
        .backgroundColor(this.isPressed && this.isNewFoldPhoneExternalScreen ? Color.White : null)
      Row() {
        this.builderAnimationIcon();
        if (this.textInButton) {
          Text(this.iconText)
            .margin({ left: 8 })
            .minFontSize(9)
            .maxFontSize(14)
            .maxLines(2)
            .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(this.getBtnFontColor())
            .opacity(this.isDisable ? 0.4 : 1)
            .flexShrink(1);
        }
      }.width('100%').justifyContent(FlexAlign.Center).padding(this.textInButton ? 16 : 0);
    }
    .pointLight(this.isNewFoldPhoneExternalScreen ? null : {
      lightSource: {
        intensity: this.lightIntensityOffset,
        positionX: this.getOffsetRight(),
        positionY: '50%',
        positionZ: this.foldChange ? (this.lightPositionZ + 1) : this.lightPositionZ
      }
    })
    .width(this.funcBtnWidth)
    .height(this.funcBtnHeight)
    .margin({ left: this.getMargin(), right: this.getMargin() })
    .borderRadius(this.getBorderRadius())
    .draggable(false)
    .backgroundEffect({
      radius: this.isActive ? 80 : 120,
      saturation: this.isActive ? 1.9 : 1.1,
      brightness: 1.0,
      color: this.isActive ? $r('app.color.active_true_color') : $r('app.color.active_false_color'),
    }, { disableSystemAdaptation: true })
    .backgroundColor(this.getBackgroundColor())
  }

  private getBackgroundColor(): ResourceColor {
    if (this.isNewFoldPhoneExternalScreen) {
      if (this.isActive) {
        return 'rgba(255, 255, 255, 0.9)';
      } else {
        return 'rgba(255, 255, 255, 0.15)';
      }
    }
    return this.isActive ? this.activeBackGroudColor : this.lightBgColor;
  }

  @Builder
  builderAnimationIcon() {
    if (this.recordIsActive()) {
      this.buildRecordAnim();
    } else if (this.btnType === 'newCall') {
      Image($r(this.iconUrl()))
        .width(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
        .height(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
        .draggable(false)
        .opacity(this.isDisable ? 0.4 : 1);
    } else {
      SymbolGlyph($r(this.iconUrl()))
        .fontSize(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r( 'app.float.funbtn_image_width'))
        .fontColor([this.iconFontColor()])
        .fontWeight(this.btnType == 'keep' ? FontWeight.Lighter : FontWeight.Medium)
        .width(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
        .height(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
        .draggable(false);
    }
  }

  private async onTouchFunction(event: TouchEvent) {
    this.handleTouch(event);
    switch (event?.type) {
      case TouchType.Down:
        this.lightOn();
      case TouchType.Move:
        let now: number = await systemDateTime.getRealActiveTime(false);
        if (this.pressTimer > 0 && now - this.pressTimer > 80) {
          this.isPressed = true;
        }
        break;
      case TouchType.Up:
      case TouchType.Cancel:
        this.lightOff();
      default:
        this.isPressed = false;
        this.pressTimer = 0;
        break;
    }
  }

  private handleTouch(event: TouchEvent) {
    switch (event.type) {
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

  setFuncBtnWidth() {
    this.funcBtnHeight = this.isApplyNewStyle ? this.appBtnStyle.btnWidth :
      ScreenAdapterUtils.getInstance().getFuncBtnWidth(this.isNewFoldPhoneExternalScreen);
    this.funcBtnWidth = this.textInButton ? '100%' : this.funcBtnHeight;
  }

  applyNewStyleChange() {
    this.setFuncBtnWidth();
    if (this.isApplyNewStyle) {
      this.lightPositionZ = 85;
    }
  }

  private getBorderRadius(): Length | BorderRadiuses | LocalizedBorderRadiuses {
    if (this.isApplyNewStyle) {
      return this.appBtnStyle.btnWidth / 2
    }
    return this.isNewFoldPhoneExternalScreen ? '28vp' : $r('sys.float.corner_radius_level16');
  }
}