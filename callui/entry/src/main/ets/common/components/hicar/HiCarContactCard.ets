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
 * @file: Header information display component
 */
import curves from '@ohos.curves';
import observer from '@ohos.arkui.observer';
import LogUtils from '../../utils/LogUtils';
import callStateConst from '../../constant/CallStateConst';
import CallStateConst from '../../constant/CallStateConst';
import ConferenceConst from '../../constant/ConferenceConst';
import DefaultCallData, { getSimIcon } from '../../struct/TypeUtils';
import CallTimeListStruct from '../../struct/CallTimeListStruct';
import { StringUtil } from '../../utils/StringUtil';
import { isIncomingCall } from '../../utils/CallListHelper';
import CallColumnUtils from '../../utils/CallColumnUtils';
import { getCallLabelPrimary, getCallLabelSecondary, getFormatCallLabelPrimary } from '../../utils/CallLabelUtils';
import { ScreenInfo } from '../../struct/CallUiDataStruct';
import HiCarConferenceTitle from './HiCarConferenceTitle';
import Utils from '../../utils/utils';
import { IMS_DOMAIN } from '../../utils/Constants';
import CallUtils from '../../utils/CallUtils';
import { NewCallIcon } from '../NewCallIcon';

const TAG = 'HiCarContactCard';

@Component
export default struct HiCarContactCard {
  private conferenceModeTranslate: string = '-20';
  private timeTmp: string = '00:00';
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @StorageLink('AccountNumber') accountNumber: string = '';
  @StorageLink('simOperatorNameFirst') simOperatorNameFirst: string = '';
  @StorageLink('simOperatorNameSecond') simOperatorNameSecond: string = '';
  @StorageLink('onAnswer') onAnswer: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('windowSizeChangeMd') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @StorageProp('navigationHeight') navigationHeight: number = 0;
  @State callStateText: string = '';
  @State dialing: string = '.';
  @State satelliteDialingTips: Resource | string = '';
  @State conferenceMemberStr: string = '';
  @State conferenceMemberCountNumber: number = 0;
  @State showMarquee: boolean = false;
  @State marqueeLoop: number = -1;
  @State callStateScore: boolean = false;
  @Prop isShowKeyboard: boolean = false;
  @Prop translateName: string = '';
  @Prop translateTime: string = '';
  @Prop contactAppear: boolean = false;
  @Prop textAreaTop: string | Resource;
  @Link @Watch('callListChange') callList: Array<DefaultCallData>;
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link showConferenceDetail: boolean;
  @Link isShowSim: boolean;
  @Link callState: number;
  @Link callId: number;
  @Link accountId: number;
  @Link callType: number;
  @Link contactAvatar?: PixelMap | null;
  @Link conferenceState: number;
  @Consume isConferenceMode: boolean;
  @State callLabelPrimary: Resource | string = '';
  @State callLabelSecondary: string = '';
  @State showNewCall: boolean = false;

  /**
   * checkIsInConferenceHold
   *
   * @return checkIsInConferenceHold
   */
  private checkIsInConferenceHold(): boolean {
    let isInConferenceHold: boolean = false;
    if (this.isConferenceMode && this.conferenceState) {
      for (let i = 0; i < this.callList.length; i++) {
        if (this.callList[i].conferenceState && this.callList[i].callState === CallStateConst.CALL_STATUS_HOLDING) {
          isInConferenceHold = true;
          break;
        }
      }
    }
    return isInConferenceHold;
  }

  /**
   * when call list data change
   *
   * @return {void}
   */
  private callListChange(): void {
    let isConferenceMode = false;
    let conferenceStr = '';
    const isInConferenceHold: boolean = this.checkIsInConferenceHold();
    this.callStateScore = isInConferenceHold;
    const SYMBOL_COMMA = StringUtil.formatResourceToString($r('app.string.symbol_comma'))
    for (let i = 0; i < this.callList.length; i++) {
      let curCallData = this.callList[i];
      if (i !== 0) {
        conferenceStr += SYMBOL_COMMA;
      }
      conferenceStr += getFormatCallLabelPrimary(curCallData, false);
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        isConferenceMode = true;
      }
    }
    this.conferenceMemberStr = conferenceStr;
    if (this.callList.length > 1) {
      this.isConferenceMode = isConferenceMode;
    } else {
      this.isConferenceMode = false;
    }
    this.conferenceMemberCountNumber = this.callList.length;
    if (!this.isConferenceMode) {
      this.showConferenceDetail = this.isConferenceMode;
    } else {
      this.marqueeLoop = 0;
      this.showMarquee = false;
      this.marqueeLoop = -1;
    }
  }

  /**
   * Whether to display the time
   *
   * @return {boolean} - return success true fail false
   */
  private isShowTime(): boolean {
    if (this.onAnswer) {
      return true;
    }
    if (this.callState === callStateConst.CALL_STATUS_ACTIVE ||
      this.callState === callStateConst.CALL_STATUS_ANSWER) {
      return true;
    }
    if (this.callList.length === 1 && this.isConferenceMode) {
      return true;
    }
    return false;
  }

  private textContentTop(): string | Resource {
    if (this.contactAvatar && !this.isShowKeyboard && !this.isConferenceMode) {
      return this.textAreaTop;
    }
    return '';
  }

  @Builder
  buildPrimaryContent() {
    Column() {
      if (this.isShowKeyboard && this.textInput.length !== 0) {
        Scroll() {
          Text(this.textInputValue)
            .fontSize($r('sys.float.ohos_id_text_size_headline6'))
            .lineHeight($r('sys.float.ohos_id_text_size_headline6'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_on_primary'))
            .id('callUI_components_HiCarContactCard_scrollText_textInputValue')
            .onTouch((event?: TouchEvent) => {
              if (event?.type === TouchType.Move) {
                this.textInputValue = this.textInput;
              }
            })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .translate({ y: this.translateName })
      } else {
        if (this.isConferenceMode) {
          Column() {
            HiCarConferenceTitle()
              .translate({ y: this.translateName })
            Stack() {
              Row() {
                Marquee({ start: true, src: this.conferenceMemberStr, loop: this.marqueeLoop })
                  .width('85%')
                  .fontSize($r('app.float.call_card_body_m_font'))
                  .fontColor($r('sys.color.font_on_primary'))
                  .fontWeight(FontWeight.Regular)
                  .id('callUI_components_HiCarContactCard_rowMarquee_marqueeLoop')
                  .onStart(() => {
                    this.showMarquee = true
                  })

                Text(StringUtil.formatPluralResourceToString($r('app.plural.conference_member_number'),
                  this.conferenceMemberCountNumber))
                  .maxLines(1)
                  .fontSize($r('app.float.call_card_body_m_font'))
                  .fontColor($r('sys.color.font_on_primary'))
                  .fontWeight(FontWeight.Regular)
                  .textAlign(TextAlign.Center)
                  .height($r('app.float.call_card_body_m_height'))
                  .lineHeight($r('app.float.call_card_body_m_line_height'))
                  .id('callUI_components_HiCarContactCard_rowText_member_str')
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .visibility(this.showMarquee ? Visibility.Visible : Visibility.Hidden)

              Row() {
                Text(this.conferenceMemberStr)
                  .maxLines(1)
                  .fontSize($r('app.float.call_card_body_m_font'))
                  .fontColor($r('sys.color.font_on_primary'))
                  .fontWeight(FontWeight.Regular)
                  .textAlign(TextAlign.Center)
                  .height($r('app.float.call_card_body_m_height'))
                  .lineHeight($r('app.float.call_card_body_m_line_height'))
                  .id('callUI_components_HiCarContactCard_rowText_conferenceMemberStr')

                Text(StringUtil.formatPluralResourceToString($r('app.plural.conference_member_number'),
                  this.conferenceMemberCountNumber))
                  .maxLines(1)
                  .fontSize($r('app.float.call_card_body_m_font'))
                  .fontColor($r('sys.color.font_on_primary'))
                  .fontWeight(FontWeight.Regular)
                  .textAlign(TextAlign.Center)
                  .height($r('app.float.call_card_body_m_height'))
                  .lineHeight($r('app.float.call_card_body_m_line_height'))
                  .id('callUI_components_HiCarContactCard_rowText_conferenceMemberCountStr')
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .visibility(!this.showMarquee ? Visibility.Visible : Visibility.Hidden)
            }
          }
          .width('100%')
          .translate({ y: this.translateTime })
          .animation({
            curve: this.isShowKeyboard ?
            curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
          })
        } else {
          Row() {
            Text(this.callLabelPrimary)
              .fontSize($r('sys.float.ohos_id_text_size_headline6'))
              .lineHeight($r('sys.float.ohos_id_text_size_headline6'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_on_primary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .id('callUI_components_HiCarContactCard_rowText_switchTextRender')
          }
          .translate({ y: this.translateName })
          .animation({
            curve: this.isShowKeyboard ?
            curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
          })
        }
      }
    }
    .margin({ bottom: 2 })
  }

  @Builder
  buildSecondaryContent() {
    Row() {
      if (this.callType === CallStateConst.TYPE_SATELLITE && isIncomingCall(this.callState) &&
        !this.isShowSim) {
        Image($r('app.media.ic_satellite_call'))
          .margin({ right: 4 })
          .width(14)
          .height(14)
          .draggable(false)
          .id('callUI_components_HiCarContactCard_rowImage_satellite_call')
          .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : this.translateTime })
          .animation({
            curve: this.isShowKeyboard ?
            curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
          })
          .align(Alignment.Center)
      }
      Text(this.callLabelSecondary)
        .fontSize(16)
        .height(21)
        .lineHeight(21)
        .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
        .transition(
          TransitionEffect.opacity(this.contactAppear ? 1 : 0)
            .animation({ duration: 100, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }))
        .visibility((!this.isShowKeyboard && !this.isConferenceMode) ? Visibility.Visible : Visibility.Hidden)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .id('callUI_components_HiCarContactCard_rowText_getCallLabelSecondary')
    }
    .height(21)
    .margin({ bottom: 2 })
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  buildCallStateContent() {
    Row() {
      if (this.callType === CallStateConst.TYPE_SATELLITE && !isIncomingCall(this.callState)) {
        Image($r('app.media.ic_satellite_call'))
          .margin({ right: 4 })
          .width(14)
          .height(14)
          .draggable(false)
          .id('callUI_components_HiCarContactCard_rowImage_callType_satellite_call')
          .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : this.translateTime })
          .animation({
            curve: this.isShowKeyboard ?
            curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
          })
      } else {
        this.buildShowSim()
      }
      if (this.callState === 1 || this.callStateScore) {
        Text($r('app.string.callHold'))
          .textExtend()
          .fontWeight(FontWeight.Medium)
          .id('callUI_components_HiCarContactCard_Text_callHold')
          .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : this.translateTime })
          .animation({
            curve: this.isShowKeyboard ?
            curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
          })
      }

      if (this.callState === 2) {
        this.buildDialingContent()
      }

      if (this.callState === 3) {
        this.buildAlertingContent()
      }

      if (this.isShowTime() && !this.callStateScore) {
        this.buildShowTimeContent()
      }

      if (this.callState === 6 || this.callState === 7) {
        Text(CallStateConst.callStateTextArray[this.callState])
          .textExtend()
          .translate({ y: this.translateTime })
          .id('callUI_components_HiCarContactCard_Row_If_Text_callState')
      }
    }
  }

  @Builder
  buildShowSim() {
    if (this.isShowSim) {
      if (this.callType === CallStateConst.TYPE_SATELLITE) {
        Image($r('app.media.ic_satellite_call'))
          .margin({ right: 4 })
          .width(14)
          .height(14)
          .draggable(false)
          .id('callUI_components_HiCarContactCard_rowImage_isShowSim_callType_satellite_call')
          .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : this.translateTime })
          .animation({
            curve: this.isShowKeyboard ?
            curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
          })
      } else {
        SymbolGlyph(getSimIcon(this.accountId))
          .fontColor(['#99FFFFFF'])
          .fontSize(12)
          .width(12)
          .height(12)
          .margin({ right: $r('sys.float.padding_level2') })
          .draggable(false)
          .id('callUI_components_HiCarContactCard_rowImage_isShowSim_getSimIcon_accountId')
          .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : this.translateTime })
          .animation({
            curve: this.isShowKeyboard ?
            curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
          })
      }
      if (isIncomingCall(this.callState)) {
        Text(this.accountId == 1 ? this.simOperatorNameSecond : this.simOperatorNameFirst)
          .textExtend()
          .id(this.accountId == 1 ?
            'callUI_components_HiCarContactCard_isIncomingCall_callData_simOperatorNameSecond' :
            'callUI_components_HiCarContactCard_isIncomingCall_callData_simOperatorNameFirst')
      }
    }
  }

  @Builder
  buildDialingContent() {
    if (this.callType === CallStateConst.TYPE_SATELLITE) {
      Row() {
        Text($r('app.string.satellite_dialing'))
          .textExtend()
          .align(Alignment.Start)
          .id('callUI_components_HiCarContactCard_Text_satellite_dialing')
        Text(this.dialing)
          .fontSize($r('app.float.call_card_body_m_font'))
          .height($r('app.float.call_card_body_m_height'))
          .lineHeight($r('app.float.call_card_body_m_height'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
          .id('callUI_components_HiCarContactCard_Text_dialing_this')
      }
      .width(182)
      .translate({ y: this.translateTime })
      .animation({
        curve: this.isShowKeyboard ?
        curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
      })
    } else {
      Row() {
        Text($r('app.string.dialing'))
          .textExtend()
          .align(Alignment.Start)
          .id('callUI_components_HiCarContactCard_Text_dialing_else')
        Text(this.dialing)
          .fontSize($r('app.float.call_card_body_m_font'))
          .height($r('app.float.call_card_body_m_height'))
          .lineHeight($r('app.float.call_card_body_m_height'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
          .id('callUI_components_HiCarContactCard_Text_dialing_else_this')
      }
      .width(70)
      .translate({ y: this.translateTime })
      .animation({
        curve: this.isShowKeyboard ?
        curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
      })
    }
  }

  @Builder
  buildAlertingContent() {
    Text($r('app.string.partyIsRinging'))
      .textExtend()
      .id('callUI_components_HiCarContactCard_Text_partyIsRinging')
      .translate({ y: this.translateTime })
      .animation({
        curve: this.isShowKeyboard ?
        curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
      })
  }

  @Builder
  buildShowTimeContent() {
    Row() {
      if (CallUtils.getImsDomain(this.callData) === IMS_DOMAIN.IMS_DOMAIN_VOWIFI) {
        Image($r('app.media.vowifi'))
          .margin({ right: $r('sys.float.padding_level2') })
          .width(22)
          .height(12)
          .draggable(false)
          .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : 0 })
      } else if (this.callType === CallStateConst.TYPE_IMS) {
        NewCallIcon({
          isHDMode: this.showNewCall,
          iconColor: '#99FFFFFF',
        })
          .margin({ right: $r('sys.float.padding_level2') })
          .id('callUI_components_HiCarContactCard_Row_Image_public_phone_HD')
          .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : 0 })
      }

      Text(this.callTimeList[0] === undefined ? this.timeTmp : this.callTimeList[0]?.callTime)
        .textExtend()
        .id(this.callTimeList[0] === undefined ? 'callUI_components_HiCarContactCard_Row_Text_timeTmp' :
          'callUI_components_HiCarContactCard_Row_Text_callTime')
        .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : 0 })
        .fontFeature('\'ss01\' on')
    }
    .translate({ y: this.translateTime })
    .animation({
      curve: this.isShowKeyboard ?
      curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
    })
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.refreshingData();
    this.callListChange();
    let timer: number = -1;
    let satelliteDialingTimer = -1;
    if (this.callState === 2) {
      timer = setInterval(() => {
        if (this.dialing === '...') {
          this.dialing = '';
        }
        this.dialing += '.';
      }, 500);
      if (this.callType === CallStateConst.TYPE_SATELLITE) {
        satelliteDialingTimer = setTimeout(() => {
          this.satelliteDialingTips = $r('app.string.satellite_dialing_tips')
        }, 5000);
      }
    }
    if (this.callState !== 2) {
      clearInterval(timer);
      clearTimeout(satelliteDialingTimer);
      this.satelliteDialingTips = '';
    }
  }

  refreshingData(): void {
    this.callLabelPrimary = getCallLabelPrimary(this.callData)
    this.callLabelSecondary = getCallLabelSecondary(this.callData)
  }

  aboutToDisappear(): void {
    observer.off('densityUpdate', this.getUIContext(), () => {
    });
  }

  build() {
    GridRow({ columns: { xs: 4, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({ span: { xs: 4, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Column() {
          this.buildPrimaryContent()

          this.buildSecondaryContent()

          this.buildCallStateContent()

          if (this.callState === 2 &&
            this.callType === CallStateConst.TYPE_SATELLITE && this.satelliteDialingTips !== '') {
            Row() {
              Text(this.satelliteDialingTips)
                .textExtend()
                .align(Alignment.Start)
                .id('callUI_components_HiCarContactCard_Row_If_Text_satelliteDialingTips')
            }
            .translate({ y: this.translateTime })
            .animation({
              curve: this.isShowKeyboard ?
              curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
            })
          }
        }
        .margin({ top: this.textContentTop() })
      }
    }
    .margin({
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
    })
  }
}

@Extend(Text)
function textExtend() {
  .fontSize(16)
  .height(21)
  .lineHeight(21)
  .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
  .fontWeight(FontWeight.Regular)
}
