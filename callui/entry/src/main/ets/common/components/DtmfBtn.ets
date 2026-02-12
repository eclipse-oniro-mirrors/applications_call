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

import CallServiceProxy from '../../model/CallServiceProxy';
import LogUtils from '../utils/LogUtils';
import { AppBtnStyleData } from '../struct/TypeUtils';
import { curves } from '@kit.ArkUI';
import { AccessibilityUtil } from '../utils/AccessiblityUtil';

const TAG = 'DtmfBtn';

class DataListStruct {
  public value: string = '';
  public sign: string = '';
}

@Component
export default struct DtmfBtn {
  @State isVideoKeyBoard: boolean = false;
  @State subStr: string = '';
  @State isPressed: boolean = false;
  @Link textInput: string;
  @Link textInputValue: string;
  @StorageLink('curBp') curBp: string = '';
  private item?: DataListStruct;
  callId?: number;
  @State lightPositionZ: number = 85;
  @State lightIntensity: number = 0;
  @State lightBloom: number = 0;
  @State lightIntensityOffset: number = 0;
  @State lightBgColor: ResourceColor = 'rgba(255, 255, 255, 0.15)';
  @Consume lightUpdate: boolean;
  @Consume lightClipState: boolean;
  @Consume foldChange: boolean;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('appBtnStyle') appBtnStyle: AppBtnStyleData = {
    btnWidth: 64,
    rowsGap: 20
  };

  /**
   * Call and press the DTMF interface
   *
   * @param {Object} obj - Object
   */
  onBtnTouchStart(obj: DataListStruct) {
    LogUtils.i(TAG, `onBtnTouchStart, value: ${obj?.value}, sign: ${obj?.sign}`);
    CallServiceProxy.getInstance().startDTMF(this.callId, String(obj?.value));
  }

  private getMargin() {
    if (this.isApplyNewStyle) {
      return 0;
    }
    if (this.curBp === 'sm' || this.curBp === 'xs' || this.curBp === 'lg') {
      return 0;
    }
    if (this.item?.value === '1' || this.item?.value === '3' || this.item?.value === '4' ||
      this.item?.value === '6' || this.item?.value === '7' || this.item?.value === '9' ||
      this.item?.value === '*' || this.item?.value === '#') {
      return this.isVideoKeyBoard ? 0 : 20;
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

  private getTopSymbolFontColor(): ResourceColor[] {
    return this.isNewFoldPhoneExternalScreen ? [$r('sys.color.font_on_primary')] :
      this.isPressed && !this.isVideoKeyBoard ? ['#000000'] : ['#FFFFFF'];
  }

  private getTopTextFontColor(): ResourceColor {
    return this.isNewFoldPhoneExternalScreen || this.isVideoKeyBoard ? $r('sys.color.font_on_primary') :
      this.isPressed ? 'rgba(0, 0, 0, 1)' : $r('sys.color.font_on_primary');
  }

  private getBottomSymbolFontColor(): ResourceColor[] {
    return this.isNewFoldPhoneExternalScreen ? [$r('sys.color.font_on_secondary')] :
      this.isPressed && !this.isVideoKeyBoard ? ['#000000'] : ['#99FFFFFF'];
  }

  private getBottomTextFontColor(): ResourceColor {
    return this.isNewFoldPhoneExternalScreen ? $r('sys.color.font_on_secondary') :
      this.isVideoKeyBoard ? $r('sys.color.font_on_tertiary') : this.isPressed ?
        'rgba(0, 0, 0, 1)' : $r('sys.color.font_on_secondary');
  }

  private getBgColor(): ResourceColor {
    return this.isNewFoldPhoneExternalScreen || this.isVideoKeyBoard ?
      (this.isPressed ? '#26FFFFFF' : Color.Transparent) : this.lightBgColor;
  }

  private getBorderRadius(): Length | BorderRadiuses | LocalizedBorderRadiuses {
    return this.isNewFoldPhoneExternalScreen ? (this.isPressed ? 22 : 0) :
      this.isVideoKeyBoard ? (this.isPressed ? 30 : 0) : this.isApplyNewStyle ? this.appBtnStyle.btnWidth / 2 : 32;
  }

  private getRowHeight(): Length {
    if (this.isApplyNewStyle) {
      return this.appBtnStyle.btnWidth;
    }
    return this.isNewFoldPhoneExternalScreen ? $r('app.float.new_form_fold_phone_Dtmf_btn_height') : 64;
  }

  build() {
    Stack() {
      Stack({ alignContent: Alignment.Top }) {
        if (!this.isVideoKeyBoard) {
          Row()
            .width(this.getRowHeight())
            .height(this.getRowHeight())
            .borderRadius(this.isNewFoldPhoneExternalScreen ? 22 :
              this.isApplyNewStyle ? this.appBtnStyle.btnWidth / 2 : 32)
            .pointLight(this.isNewFoldPhoneExternalScreen ? {} : {
              lightSource: {
                intensity: this.lightIntensity,
                positionX: '50%',
                positionY: '50%',
                positionZ: this.foldChange ? 86 : this.lightPositionZ
              },
              illuminated: this.lightUpdate ? IlluminatedType.NONE : IlluminatedType.BORDER_CONTENT,
              bloom: this.lightBloom
            })
        }
        if (this.item?.value == '*') {
          SymbolGlyph($r('sys.symbol.staroflife'))
            .fontColor(this.getTopSymbolFontColor())
            .fontSize(this.getTopSymbolFontSize())
            .height(this.getTopSymbolHeight())
            .width(this.getTopSymbolHeight())
            .margin({
              top: this.isApplyNewStyle && this.appBtnStyle.dtmfTopMargin ? this.appBtnStyle.dtmfTopMargin :
                this.isNewFoldPhoneExternalScreen ? 6 : 15
            })
            .draggable(false)
        } else if (this.item?.value == '#') {
          SymbolGlyph($r('sys.symbol.hash'))
            .fontColor(this.getTopSymbolFontColor())
            .fontSize(this.getTopSymbolFontSize())
            .height(this.getTopSymbolHeight())
            .width(this.getTopSymbolHeight())
            .margin({
              top: this.isApplyNewStyle && this.appBtnStyle.dtmfTopMargin ? this.appBtnStyle.dtmfTopMargin :
                this.isNewFoldPhoneExternalScreen ? 6 : 15
            })
            .draggable(false)
        } else {
          Text(this.item?.value)
            .fontSize(this.getTopTextFontSize())
            .height(this.getTopTextHeight())
            .lineHeight(this.getTopTextLineHeight())
            .fontWeight(this.isNewFoldPhoneExternalScreen ? FontWeight.Medium :
              this.isVideoKeyBoard ? 600 : FontWeight.Bold)
            .fontColor(this.getTopTextFontColor())
            .margin({
              top: this.isApplyNewStyle && this.appBtnStyle.dtmfTopMargin ? this.appBtnStyle.dtmfTopMargin :
                this.isNewFoldPhoneExternalScreen ? 6 : this.isVideoKeyBoard ? 7 : 11
            })
            .draggable(false)
        }
        if (this.item?.value === '1') { // change words to image
          SymbolGlyph($r('sys.symbol.recordingtape'))
            .fontColor(this.getBottomSymbolFontColor())
            .fontSize(this.getBottomSymbolFontSize())
            .height(this.getBottomSymbolHeight())
            .margin({
              top: this.isApplyNewStyle && this.appBtnStyle.dtmfBottomTopGap ? this.appBtnStyle.dtmfBottomTopGap :
                this.isNewFoldPhoneExternalScreen ? 25 : this.isVideoKeyBoard ? 38 : 39
            })
            .draggable(false)
        } else if (this.item?.sign == '+') {
          if (this.isApplyNewStyle) {
            Text(this.item?.sign)
              .fontSize(this.appBtnStyle.dtmfBottomPlusSize)
              .height(this.appBtnStyle.dtmfBottomPlusLineHeight)
              .lineHeight(this.appBtnStyle.dtmfBottomPlusLineHeight)
              .fontWeight(this.appBtnStyle.dtmfBottomTextWeight)
              .fontColor(this.getBottomTextFontColor())
              .margin({ top: this.appBtnStyle.dtmfBottomTopGap })
          } else {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontColor(this.getBottomSymbolFontColor())
              .fontSize(this.isNewFoldPhoneExternalScreen ? '8vp' : '9vp')
              .height(this.isNewFoldPhoneExternalScreen ? 8 : 9)
              .width(this.isNewFoldPhoneExternalScreen ? 8 : 9)
              .margin({ top: this.isNewFoldPhoneExternalScreen ? 29 : 42 })
              .draggable(false)
          }
        } else {
          Text(this.item?.sign)
            .fontSize(this.getBottomTextFontSize())
            .height(this.getBottomTextHeight())
            .lineHeight(this.getBottomTextLineHeight())
            .fontWeight(FontWeight.Regular)
            .fontColor(this.getBottomTextFontColor())
            .margin({
              top: this.isApplyNewStyle && this.appBtnStyle.dtmfBottomTopGap ? this.appBtnStyle.dtmfBottomTopGap :
                this.isNewFoldPhoneExternalScreen ? 26 : 39
            })
        }
      }
      .width(this.getWidth())
      .height(this.getHeight())
      .margin({ left: this.getMargin(), right: this.getMargin() })
      .backgroundColor(this.getBgColor())
      .borderRadius(this.getBorderRadius())
      .backgroundEffect((this.isNewFoldPhoneExternalScreen || this.isVideoKeyBoard) ? null : {
        radius: 120,
        saturation: 1.1,
        brightness: 1.0,
        color: $r('app.color.active_false_color'),
      }, { disableSystemAdaptation: true })
      .pointLight(this.isVideoKeyBoard || this.isNewFoldPhoneExternalScreen ? {} : {
        lightSource: {
          intensity: this.lightIntensityOffset,
          positionX: this.getOffsetLeft(),
          positionY: '50%',
          positionZ: this.foldChange ? 86 : this.lightPositionZ
        }
      })
      .onTouch((event?: TouchEvent) => {
        switch (event?.type) {
          case TouchType.Down:
            this.touchDownFunc();
          // No break!
          case TouchType.Move:
            this.isPressed = true;
            break;
          case TouchType.Up:
          case TouchType.Cancel:
            this.touchUpFunc();
          default:
            this.isPressed = false;
            break;
        }
      })
      .onAccessibilityHover((isHover: boolean, event: AccessibilityHoverEvent) => {
        switch (event.type) {
          case AccessibilityHoverType.HOVER_EXIT:
            this.onClickFunction(false);
            break;
          default:
            break;
        }
      })
      .accessibilityText(this.screenReaderStatus ? this.item?.value : '')
      .accessibilityDescription($r('app.string.one_finger_double_click'))
      .accessibilityGroup(true)
      .onClick((event: ClickEvent) => {
        if (this.screenReaderStatus) {
          this.onClickFunction(true)
        }
      })
    }
    .width(this.getWidth())
    .height(this.getHeight())
    .borderRadius(this.isNewFoldPhoneExternalScreen ? 22 :
      this.isVideoKeyBoard ? 0 : this.isApplyNewStyle ? this.appBtnStyle.btnWidth / 2 : 32)
    .pointLight(this.isVideoKeyBoard || this.isNewFoldPhoneExternalScreen ? {} : {
      lightSource: {
        intensity: this.lightIntensityOffset,
        positionX: this.getOffsetRight(),
        positionY: '50%',
        positionZ: this.foldChange ? 86 : this.lightPositionZ
      }
    })
  }

  private getBottomSymbolHeight(): Length {
    return this.isApplyNewStyle && this.appBtnStyle.dtmfBottomSymbolTextLineHeight ?
    this.appBtnStyle.dtmfBottomSymbolTextLineHeight : 15;
  }

  private getBottomSymbolFontSize() {
    return this.isApplyNewStyle && this.appBtnStyle.dtmfBottomSymbolTextSize ?
    this.appBtnStyle.dtmfBottomSymbolTextSize : $r('app.float.call_dtmf_text_no_video_height');
  }

  private getBottomTextLineHeight() {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfBottomTextLineHeight) {
      return this.appBtnStyle.dtmfBottomTextLineHeight;
    }
    return this.isNewFoldPhoneExternalScreen ? '12vp' :
      this.isVideoKeyBoard ? $r('app.float.call_dtmf_text_video_line_height') :
      $r('app.float.call_dtmf_text_no_video_height');
  }

  private getBottomTextHeight(): Length {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfBottomTextLineHeight) {
      return this.appBtnStyle.dtmfBottomTextLineHeight;
    }
    return this.isNewFoldPhoneExternalScreen ? '12vp' :
      this.isVideoKeyBoard ? $r('app.float.call_dtmf_text_video_height') :
      $r('app.float.call_dtmf_text_no_video_height');
  }

  private getBottomTextFontSize() {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfBottomTextSize) {
      return this.appBtnStyle.dtmfBottomTextSize;
    }
    return this.isNewFoldPhoneExternalScreen ? '9vp' : $r('app.float.call_dtmf_text_font');
  }

  private getTopTextLineHeight() {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfTopTextSize) {
      return this.appBtnStyle.dtmfTopTextSize;
    }
    return this.isNewFoldPhoneExternalScreen ? '20vp' :
      this.isVideoKeyBoard ? $r('app.float.call_dtmf_video_text_height') :
      $r('app.float.call_dtmf_no_video_text_heigth');
  }

  private getTopTextHeight(): Length {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfTopTextSize) {
      return this.appBtnStyle.dtmfTopTextSize;
    }
    return this.isNewFoldPhoneExternalScreen ? '20vp' :
      this.isVideoKeyBoard ? $r('app.float.call_dtmf_video_text_height') :
      $r('app.float.call_dtmf_no_video_text_heigth');
  }

  private getTopTextFontSize() {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfTopTextSize) {
      return this.appBtnStyle.dtmfTopTextSize;
    }
    return this.isNewFoldPhoneExternalScreen ? '20vp' :
      this.isVideoKeyBoard ? $r('app.float.call_dtmf_video_text_font') :
      $r('app.float.call_dtmf_no_video_text_font');
  }

  private getTopSymbolHeight(): Length {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfTopSymbolTextLineHeight) {
      return this.appBtnStyle.dtmfTopSymbolTextLineHeight;
    }
    return this.isNewFoldPhoneExternalScreen ? 20 : this.isVideoKeyBoard ? 17 : 24;
  }

  private getTopSymbolFontSize() {
    if (this.isApplyNewStyle && this.appBtnStyle.dtmfTopSymbolTextSize) {
      return this.appBtnStyle.dtmfTopSymbolTextSize;
    }
    return this.isNewFoldPhoneExternalScreen ? '20vp' :
      this.isVideoKeyBoard ? '17vp' : $r('app.float.call_dtmf_add_text_line_height');
  }

  private getHeight(): Length {
    if (this.isApplyNewStyle) {
      return this.appBtnStyle.btnWidth;
    }
    return this.isNewFoldPhoneExternalScreen ? 44 : this.isVideoKeyBoard ? 60 : 64;
  }

  private getWidth(): Length {
    if (this.isApplyNewStyle) {
      return this.appBtnStyle.btnWidth;
    }
    return this.isNewFoldPhoneExternalScreen ? 44 : this.isVideoKeyBoard ? (this.isPressed ? 60 : '100%') : 64;
  }

  private onClickFunction(isDoubleClick:boolean) {
    LogUtils.i(TAG, 'onClickFunction');
    if (isDoubleClick) {
      let keyboardNum = this.item?.value || '';
      AccessibilityUtil.announceForAccessibilityNotInterrupt(keyboardNum);
    }
    this.textInput = this.textInput + this.item?.value;
    if (this.textInput.length > 19) {
      this.subStr = this.textInput.substr(this.textInput.length - 19, this.textInput.length - 1);
      this.textInputValue = this.subStr;
    } else {
      this.textInputValue = this.textInput;
    }
    AppStorage.setOrCreate('TextInputValue', this.textInputValue);
    AppStorage.setOrCreate('TextInput', this.textInput);
    if (this.item !== undefined) {
      this.onBtnTouchStart(this.item);
    }
  }

  private touchUpFunc() {
    CallServiceProxy.getInstance().stopDTMF(this.callId);
    if (!this.isVideoKeyBoard) {
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
  }

  private touchDownFunc() {
    this.onClickFunction(false);
    if (!this.isVideoKeyBoard) {
      this.lightBgColor = 'rgba(255, 255, 255, 0.5)';
      this.lightClipState = false;
      this.lightUpdate = false;
      this.foldChange = false;
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
  }
}