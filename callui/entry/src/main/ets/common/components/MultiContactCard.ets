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

/**
 * @file: Header information display component
 */
import LogUtils from '../utils/LogUtils';
import { isIncomingCall } from '../utils/CallListHelper';
import CallList from './CallList'
import DefaultCallData, { getSimIcon } from '../struct/TypeUtils'
import CallTimeListStruct from '../struct/CallTimeListStruct';
import CallListWithConference from './CallListWithConference';
import ConferenceConst from '../constant/ConferenceConst';
import {
  getCallLabelPrimary,
  getCallLabelSecondary,
  getCallLabelThird,
} from '../utils/CallLabelUtils';
import CallColumnUtils from '../utils/CallColumnUtils';
import CallStateConst from '../constant/CallStateConst';
import { LengthMetrics } from '@kit.ArkUI';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import Utils from '../utils/utils';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import { AccessibilityUtil } from '../utils/AccessiblityUtil';

const TAG = 'MultiContactCard';

@Component
export default struct MultiContactCard {
  @State callStateText: string = '';
  @State dialing: string = '.';
  @Prop isShowKeyboard: boolean = false;
  @Link @Watch('initCompanyTimer') callData: DefaultCallData;
  @Link @Watch('callListChange') callList: Array<DefaultCallData>;
  @Link callTimeList: Array<CallTimeListStruct>;
  @State isConferenceMode: boolean = false;
  @Link showConferenceDetail: boolean;
  @Link isShowSim: boolean;
  @State callLabelThird: string = '';
  @State callLabelPrimary: Resource | string = '';
  @State callLabelSecondary: string = '';
  @State callType: number = 0;
  @Link callState: number;
  @Link accountId: number;
  @Link callId: number;
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @StorageLink('simOperatorNameFirst') simOperatorNameFirst: string = '';
  @StorageLink('simOperatorNameSecond') simOperatorNameSecond: string = '';
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('onAnswer') onAnswer: boolean = false;
  @State nickFontSize: string = '38vp';
  @StorageLink('Density') @Watch('densityDidChange') density: number = 1;
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @State showSimFirstFlag: boolean = true;
  private companyTimer: number = -1;
  @StorageProp('windowSizeChangeMd') @Watch('windowSizeChange') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  private scrollController: Scroller = new Scroller();
  @Prop celiaAssistantShow: boolean;
  @Styles
  iconStyles() {
    .visibility(this.showSimFirstFlag ? Visibility.Visible : Visibility.None)
    .opacity(this.showSimFirstFlag ? 1 : 0)
    .transition(TransitionEffect.OPACITY.animation({
      duration: this.onAnswer || this.companyTimer === -1 ? 0 : 1000,
      delay: 0,
      curve: Curve.EaseInOut,
      iterations: 1
    }))
  }

  public aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear ' + this.isShowSim);
    this.showSimFirstFlag = this.isShowSim;
    this.windowSizeChange();
    this.callListChange();
    this.initCompanyTimer();
  }

  public aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.clearCompanyTimer();
  }

  clearCompanyTimer() {
    if (this.companyTimer !== -1) {
      this.showSimFirstFlag = this.isShowSim;
      clearInterval(this.companyTimer);
      this.companyTimer = -1;
      LogUtils.i(TAG, 'clearInterval companyTimer');
    }
  }

  initCompanyTimer() {
    this.callType = this.callData.callType;
    this.callLabelSecondary = getCallLabelSecondary(this.callData);
    this.callLabelPrimary = getCallLabelPrimary(this.callData);
    this.callLabelThird = getCallLabelThird(this.callData);
    if (this.callType === CallStateConst.TYPE_SATELLITE || !isIncomingCall(this.callState)) {
      this.clearCompanyTimer();
      return;
    }
    if (this.showSimFirstFlag && this.callLabelThird.length > 0) {
      if (this.companyTimer !== -1) {
        LogUtils.i(TAG, 'companyTimer already exist');
      } else {
        this.companyTimer = setInterval(() => {
          this.showSimFirstFlag = !this.showSimFirstFlag;
        }, 3000);
        LogUtils.i(TAG,
          `companyTimer create success:${this.companyTimer},companyInfoLength:${this.callLabelThird.length}`);
      }
    }
  }

  densityDidChange() {
    this.nickFontSize =
      CallColumnUtils.getInstance().getDisplayNameForAutoSize(this.callLabelPrimary, this.curBp, false);
  }

  /**
   * when call list data change
   *
   * @return {void}
   */
  private callListChange() {
    let isConferenceMode = false;
    let conferenceMemberCount = 0;
    for (let i = 0; i < this.callList.length; i++) {
      let curCallData = this.callList[i];
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        isConferenceMode = true;
        conferenceMemberCount++;
      }
    }
    if (conferenceMemberCount > 1) {
      this.isConferenceMode = isConferenceMode;
    } else {
      this.isConferenceMode = false;
    }
    if (!this.isConferenceMode) {
      this.showConferenceDetail = this.isConferenceMode;
    }
  }

  windowSizeChange() {
    let textStr = this.callLabelPrimary;
    this.nickFontSize = CallColumnUtils.getInstance().getDisplayNameForAutoSize(textStr, this.curBp);
    LogUtils.i(TAG, `windowSizeChange nickFontSize:${this.nickFontSize}`);
  }

  @Builder
  private showCallLabelThird() {
    Row() {
      if (this.callType === CallStateConst.TYPE_SATELLITE) {
        Image($r('app.media.ic_satellite_call'))
          .margin({ end: LengthMetrics.vp(4) })
          .width(14)
          .height(14)
          .draggable(false)
          .iconStyles()
      } else {
        SymbolGlyph(getSimIcon(this.accountId))
          .fontColor(['#FFFFFF'])
          .fontSize($r('app.float.wh_value_12'))
          .margin({ end: LengthMetrics.vp(4) })
          .width(12)
          .height(12)
          .draggable(false)
          .iconStyles()
      }
      if (isIncomingCall(this.callState, true)) {
        Text(this.accountId == 1 ? this.simOperatorNameSecond : this.simOperatorNameFirst)
          .fontSize($r('app.float.call_card_body_m_font'))
          .height($r('app.float.call_card_body_m_height'))
          .lineHeight($r('app.float.call_card_body_m_line_height'))
          .fontColor($r('sys.color.font_on_primary'))
          .textFadeInOutExtend((this.callLabelSecondary ?? '').length > 0 && this.showSimFirstFlag &&
            !this.onAnswer, this.onAnswer || this.companyTimer === -1)
          .accessibilityLevel('yes')
      }
      if (isIncomingCall(this.callState) && this.callLabelThird.length > 0) {
        Text(this.callLabelThird)
          .enabled(false)
          .fontSize($r('app.float.call_card_body_m_font'))
          .height($r('app.float.call_card_body_m_height'))
          .lineHeight($r('app.float.call_card_body_m_line_height'))
          .fontColor($r('sys.color.font_on_primary'))
          .textAlign(TextAlign.Center)
          .id('callUI_components_MultiContactCard_isIncomingCall_callData_companyInfo')
          .textFadeInOutExtend(!this.showSimFirstFlag && !this.onAnswer, this.onAnswer || this.companyTimer === -1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .accessibilityLevel('yes')
      }
    }
    .margin({
      bottom:  $r('sys.float.padding_level1')
    })
  }

  getIncomingCallTextTop(isNewFoldPhoneExternalScreen: boolean): number {
    if (isNewFoldPhoneExternalScreen) {
      if (this.callList.length === 3 && this.isThirdIncomingCall()) {
        return 26;
      }
      return 8;
    }
    if (SplitScreenManager.getInstance().isSplitScreen(this.splitScreenType)) {
      return SplitScreenManager.getInstance().getMultiCardIncomingTextTop(this.splitScreenType);
    }
    return 56;
  }

  isThirdIncomingCall(): boolean {
    let isActive = false;
    let isHolding = false;
    let isIncoming = false;
    this.callList.forEach(call => {
      if (call.callState === CallStateConst.CALL_STATUS_ACTIVE) {
        isActive = true;
      }
      if (call.callState === CallStateConst.CALL_STATUS_HOLDING) {
        isHolding = true;
      }
      if ([CallStateConst.CALL_STATUS_WAITING, CallStateConst.CALL_STATUS_INCOMING].includes(call.callState)) {
        isIncoming = true;
      }
    })
    return isActive && isHolding && isIncoming;
  }

  private getNickFontSize() {
    let splitFontSize = SplitScreenManager.getInstance().getDisplayNameFontSize(this.splitScreenType);
    if (splitFontSize.length > 0) {
      return splitFontSize;
    }
    let textStr = this.callLabelPrimary;
    this.nickFontSize = CallColumnUtils.getInstance().getDisplayNameForAutoSize(textStr, this.curBp);
    return this.nickFontSize;
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({ span: { xs: 2, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Column() {
          if (!(this.isShowKeyboard && this.textInput.length !== 0)) {
            if (this.isConferenceMode) {
              CallListWithConference({
                callList: $callList,
                callData: $callData,
                callTimeList: $callTimeList,
                showConferenceDetail: $showConferenceDetail,
                isShowSim: $isShowSim,
              })
                .visibility((this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? Visibility.None :
                SplitScreenManager.getInstance().callListShow(this.callList, this.splitScreenType))
            } else {
              CallList({
                callList: $callList,
                callData: $callData,
                callTimeList: $callTimeList,
                isShowSim: $isShowSim,
              })
                .visibility((this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? Visibility.None :
                SplitScreenManager.getInstance().callListShow(this.callList, this.splitScreenType))
            }

            if (isIncomingCall(this.callState, true)) {
              Column() {
                if (!this.isShowKeyboard || this.isShowKeyboard && this.textInput.length === 0) {
                  Text(this.callLabelPrimary)
                    .fontWeight(600)
                    .fontSize(this.isNewFoldPhoneExternalScreen ? '30vp' : this.getNickFontSize())
                    .fontColor($r('sys.color.font_on_primary'))
                    .margin({
                      bottom: this.isNewFoldPhoneExternalScreen ? (this.isShowKeyboard ? 0 : '5vp') :
                      $r('sys.float.padding_level1')
                    })
                    .maxLines((this.isNewFoldPhoneExternalScreen ||
                    SplitScreenManager.getInstance().isNicknameOneLine(this.splitScreenType, this.callData)) ? 1 : 2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .textAlign(TextAlign.Center)
                    .accessibilityLevel('yes')
                  Text(this.callLabelSecondary)
                    .fontSize($r('app.float.call_card_body_m_font'))
                    .height($r('app.float.call_card_body_m_height'))
                    .lineHeight($r('app.float.call_card_body_m_height'))
                    .fontColor($r('sys.color.font_on_primary'))
                    .visibility(this.callLabelSecondary ? Visibility.Visible : Visibility.None)
                    .margin({ bottom: $r('sys.float.padding_level1') })
                    .accessibilityText('"' + this.callLabelSecondary + '"')
                    .accessibilityLevel('yes')
                }

                if (this.isShowSim || this.callType === CallStateConst.TYPE_SATELLITE ||
                  this.callLabelThird.length > 0) {
                  this.showCallLabelThird();
                }

              }
              .margin({ top: this.getIncomingCallTextTop(this.isNewFoldPhoneExternalScreen) })
              .accessibilityLevel('yes')
              .accessibilityGroup(true)
              .onAppear(() => {
                AccessibilityUtil.requestFocusForAccessibility('callui_MultiContactCard_incomingCall_Column');
              })
              .id('callui_MultiContactCard_incomingCall_Column')
            }
          } else {
            Scroll(this.scrollController) {
              Text(this.textInputValue)
                .height((this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? '26vp' :
                $r('app.float.conference_detail_colom_width'))
                .fontSize((this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? '20vp' :
                $r('app.float.call_card_textinput_text_font'))
                .lineHeight((this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? '27vp' :
                $r('app.float.conference_detail_colom_width'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  bottom: (this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? 0 : $r('sys.float.padding_level4'),
                  top: (this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? 0 :
                  $r('app.float.conference_detail_top_space')
                })
                .fontColor($r('sys.color.font_on_primary'))
                .onTouch((event?: TouchEvent) => {
                  if (event?.type === TouchType.Move) {
                    this.textInputValue = this.textInput
                  }
                })
                .onSizeChange((old, newArea) => {
                  // 记录内部的高度
                  let scrollWidth = newArea.width as number;
                  const offset = this.scrollController.currentOffset();
                  this.scrollController.scrollTo({
                    yOffset: offset.yOffset,
                    xOffset: scrollWidth,
                    animation: false
                  });
                })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
          }
        }
      }
    }
    .margin({
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
    })
  }
}

@Extend(Text)
function textFadeInOutExtend(showFlag: boolean, noAnimationFlag: boolean) {
  .visibility(showFlag ? Visibility.Visible : Visibility.None)
  .opacity(showFlag ? 1 : 0)
  .transition(TransitionEffect.OPACITY.animation({
    duration: noAnimationFlag ? 0 : 1000,
    delay: 0,
    curve: Curve.EaseInOut,
    iterations: 1
  }))
}

