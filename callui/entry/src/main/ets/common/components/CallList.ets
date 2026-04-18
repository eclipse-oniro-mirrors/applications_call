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
 * @file: User list component
 */

import CallStateConst from '../constant/CallStateConst';
import CallServiceProxy from '../../model/CallServiceProxy';
import LogUtils from '../utils/LogUtils';
import DefaultCallData, { getSimIcon } from '../struct/TypeUtils';
import CallTimeListStruct from '../struct/CallTimeListStruct';
import { isIncomingCall, isOutgoingCall, isVideoCall } from '../utils/CallListHelper';
import Recording from '../utils/Recording';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import CallDataManager from '../../model/CallDataManager';
import { getCallLabelPrimary } from '../utils/CallLabelUtils';
import { LengthMetrics } from '@kit.ArkUI';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import { StringUtil } from '../utils/StringUtil';
import Utils from '../utils/utils';
import { ACCESSIBILITY_LEVEL_YES, IMS_DOMAIN } from '../utils/Constants';
import CallUtils from '../utils/CallUtils';
import I18n from '@ohos.i18n';
import Intl from '@ohos.intl';
import { AccessibilityUtil } from '../utils/AccessiblityUtil';
import { NewCallIcon } from './NewCallIcon';

const TAG = 'CallList';

@Component
export default struct CallList {
  @Link @Watch('updateCallListToShow') callList: Array<DefaultCallData>;
  @Link @Watch('updateCallListToShow') callData: DefaultCallData;
  @State callState: number = 0;
  @State callId: number = 0;
  @State callType: number = 0;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link isShowSim: boolean;
  @State callListToShow: Array<DefaultCallData> = []
  @StorageLink('SplitScreenType') @Watch('updateCallListToShow') splitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @StorageLink('isRTL') isRTL: boolean = false;
  private mCallServiceProxy?: CallServiceProxy;
  @State showNewCallMap: Map<number, boolean> = new Map();

  public aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.mCallServiceProxy = CallServiceProxy.getInstance();
    this.updateCallListToShow();
  }

  private updateCallListToShow() {
    // We should listen both callList change and callData change because the primary incoming call will change
    this.callState = this.callData.callState;
    this.callId = this.callData.callId;
    this.callType = this.callData.callType;
    this.callListToShow = this.callList.filter(
      (v) => isIncomingCall(this.callState, true) ? v.callId !== this.callId : true
    );
    this.changeSpliteScreenType()
  }

  private changeSpliteScreenType() {
    if (SplitScreenManager.getInstance().isSplitScreen(this.splitScreenType)) {
      this.callListToShow = this.callListToShow.filter(
        (v) => SplitScreenManager.getInstance()
          .callListItem(this.callData, v, this.splitScreenType)
      );
    }
  }

  /**
   * Phone number display
   *
   * @return {string} Phone number
   */
  public getCallTime(item: DefaultCallData): string | undefined | Resource {
    let callTimeObj = this.callTimeList.find((o: CallTimeListStruct) => o.callId === item.callId);
    return callTimeObj ? callTimeObj.callTime : undefined;
  }

  /**
   * Accept call
   *
   * @param {number} callId - callId
   */
  public onAccept(callId: number, isVideoAnswer: boolean) {
    LogUtils.i(TAG, 'onAccept : ' + callId + ', callList length : ' + JSON.stringify(this.callList.length) +
      ', incomingCall.videoState :' + this.callData.videoState);
    this.mCallServiceProxy?.acceptCall(callId, isVideoAnswer);
    if (this.callList.length >= 2) {
      ReportUtil.getInstance().reportMultiCallAction(1);
      ReportUtil.getInstance().reportIsDualCardClickListToAnswer(this.callList.length);
    }
  }

  /**
   * Hang up call
   *
   * @param {number} callId - callId
   */
  public onHangUp(callId: number) {
    LogUtils.i(TAG, 'onHangUp callId : ' + callId +
      ', callList length : ' + JSON.stringify(this.callList.length));
    this.mCallServiceProxy?.hangUpCall(callId);
    if (this.callList.length >= 2) {
      let actionValue: number = CallDataManager.getInstance().isActiveCall(callId) ? 2 : 0;
      ReportUtil.getInstance().reportMultiCallAction(actionValue);
      if (actionValue === 2) {
        CallUtils.reportHangupCount();
        ReportUtil.getInstance().reportMultiCallHangUpOne();
      }
      ReportUtil.getInstance().reportIsDualCardClickListReject(this.callList.length);
    }
  }

  /**
   * UnHold call
   *
   * @param {number} callId - callId
   */
  public onUnHold(callId: number) {
    if (this.callList.length > 2) {
      LogUtils.w(TAG, 'onUnHold : Skip for non-2-way case!');
      return;
    }

    if (isIncomingCall(this.callState) || isOutgoingCall(this.callState)) {
      LogUtils.w(TAG, 'onUnHold : Skip for incoming or outgoing!');
      return;
    }

    LogUtils.i(TAG, 'onUnHold: finding calls to unhold');
    ReportUtil.getInstance().reportDualCardClickExchangeList();
    for (let item of this.callListToShow) {
      if (item.callState === CallStateConst.CALL_STATUS_HOLDING) {
        LogUtils.i(TAG, 'onUnHold: Hint call ' + item.callId);
        Recording.getInstance().changeRecorderStatus();
        this.mCallServiceProxy?.unHoldCall(item.callId);
        return;
      }
    }
    LogUtils.w(TAG, 'onUnHold: could not found call to unhold! clicked callid = ' + callId);
  }

  isHideListItem(isNewFoldPhoneExternalScreen: boolean, item: DefaultCallData) {
    LogUtils.i(TAG, `isHideListItem, callList length: ${this.callList.length}, callState: ${item.callState}`);
    if (isNewFoldPhoneExternalScreen) {
      if (this.callList.length > 3) {
        return !isIncomingCall(item.callState);
      } else if (this.callList.length > 2) {
        return item.callState === CallStateConst.CALL_STATUS_HOLDING ||
          item.callState === CallStateConst.CALL_STATUS_ACTIVE;
      } else if (this.callList.length > 1) {
        return item.callState === CallStateConst.CALL_STATUS_HOLDING;
      }
    }
    return false;
  }

  getSymbolFontSize(): number {
    return this.isNewFoldPhoneExternalScreen ? 20 : 24;
  }

  private getAccessibilityText(): string {
    let accessibilityText = this.screenReaderStatus ? (this.callData.accountId == 0 ?
      StringUtil.formatResourceToString($r('app.string.sim_card_num_no_space'), StringUtil.simIdFormat(1)) :
      StringUtil.formatResourceToString($r('app.string.sim_card_num_no_space'), StringUtil.simIdFormat(2))) : ''
    return accessibilityText;
  }

  build() {
    Column() {
      List() {
        ForEach(this.callListToShow, (item: DefaultCallData) => {
          if (!this.isHideListItem(this.isNewFoldPhoneExternalScreen, item)) {
            ListItem() {
              Row() {
                if (this.callType === CallStateConst.TYPE_SATELLITE) {
                  Image($r('app.media.ic_satellite_call'))
                    .margin({ end: LengthMetrics.vp(8)})
                    .width(14)
                    .height(14)
                } else {
                  if (this.isShowSim) {
                    SymbolGlyph(getSimIcon(item.accountId))
                      .fontColor(['#FFFFFF'])
                      .fontSize($r('app.float.wh_value_12'))
                      .margin({ end: LengthMetrics.vp(8)})
                      .width(12)
                      .height(12)
                      .accessibilityText(this.getAccessibilityText())
                      .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                  }
                }

                Row() {
                  Text(getCallLabelPrimary(item, false))
                    .fontColor($r('sys.color.font_on_primary'))
                    .fontSize($r('app.float.call_calllist_name_font'))
                    .fontWeight(FontWeight.Medium)
                    .margin({ end: LengthMetrics.vp(16) })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .direction(this.isRTL ? Direction.Rtl : Direction.Auto)
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                }.layoutWeight(1)

                if (item.callState === CallStateConst.callStateObj.CALL_STATUS_ACTIVE) {
                  if (CallUtils.getImsDomain(item) === IMS_DOMAIN.IMS_DOMAIN_VOWIFI) {
                    Image($r('app.media.vowifi'))
                      .margin({ end: LengthMetrics.vp(4) })
                      .width(22)
                      .height(12)
                      .draggable(false)
                  } else if (item.callType === CallStateConst.TYPE_IMS) {
                    NewCallIcon({
                      isHDMode: this.showNewCallMap.get(item.accountId) === true,
                      iconColor: '#FFFFFF',
                    })
                      .margin({ end: LengthMetrics.vp(4) })
                      .opacity($r('sys.float.alpha_secondary'))
                      .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                      .accessibilityText(this.screenReaderStatus ?
                        StringUtil.formatResourceToString($r('app.string.call_hd_symbol')) : '')
                      .id('callUI_call_list_SymbolGlyph_hd')
                  }

                  Text(this.getCallTime(item))
                    .fontSize($r('app.float.call_calllist_time_or_status_font'))
                    .fontColor($r('sys.color.font_on_secondary'))
                    .height($r('app.float.call_calllist_text_height'))
                    .lineHeight($r('app.float.call_calllist_text_height'))
                    .accessibilityText(this.screenReaderStatus ?
                    Utils.getInstance().getAccessibilityTextOfTime(this.getCallTime(item)?.toString()) : '')
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                } else {
                  Text(CallStateConst.callStateTextArray[item.callState])
                    .fontSize($r('app.float.call_calllist_time_or_status_font'))
                    .fontColor($r('sys.color.font_on_secondary'))
                    .height($r('app.float.call_calllist_text_height'))
                    .lineHeight($r('app.float.call_calllist_text_height'))
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                }

                if (isIncomingCall(item.callState)) {
                  Button() {
                    SymbolGlyph($r('sys.symbol.phone_down_fill'))
                      .fontSize(this.getSymbolFontSize())
                      .fontColor([$r('sys.color.icon_on_primary')])
                      .align(Alignment.Center)
                      .width(this.getSymbolFontSize())
                      .height(this.getSymbolFontSize())
                      .fontWeight(FontWeight.Medium)
                      .opacity(1)
                      .draggable(false)
                  }
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor($r('sys.color.warning'))
                  .onClick(() => this.onHangUp(item.callId))
                  .accessibilityText(this.screenReaderStatus ? StringUtil.formatResourceToString($r('app.string.hangUp')) : '')

                  Button() {
                    SymbolGlyph($r('sys.symbol.phone_fill'))
                      .fontSize(this.getSymbolFontSize())
                      .fontColor([$r('sys.color.icon_on_primary')])
                      .align(Alignment.Center)
                      .width(this.getSymbolFontSize())
                      .height(this.getSymbolFontSize())
                      .fontWeight(FontWeight.Medium)
                      .opacity(1)
                      .draggable(false)
                  }
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor($r('sys.color.confirm'))
                  .margin({ start: LengthMetrics.vp(16) })
                  .onClick(() => this.onAccept(item.callId, false))
                  .dialingDotExtend(this.screenReaderStatus)

                  if (isVideoCall(item.videoState)) {
                    Button() {
                      SymbolGlyph($r(`sys.symbol.video_fill`))
                        .fontSize(this.getSymbolFontSize())
                        .fontColor([$r('sys.color.icon_on_primary')])
                        .align(Alignment.Center)
                        .width(this.getSymbolFontSize())
                        .height(this.getSymbolFontSize())
                        .fontWeight(FontWeight.Medium)
                        .opacity(1)
                        .draggable(false)
                    }
                    .width(40)
                    .height(40)
                    .borderRadius(20)
                    .backgroundColor($r('sys.color.confirm'))
                    .onClick(() => this.onAccept(item.callId, true))
                    .margin({ start: LengthMetrics.vp(16) })
                    .dialingDotExtend(this.screenReaderStatus)
                  }
                } else {
                  SymbolGlyph($r('sys.symbol.phone_down_fill'))
                    .fontSize($r('app.float.height_answer_btn_30'))
                    .fontColor(['#E84026'])
                    .width(30)
                    .height(30)
                    .draggable(false)
                    .onClick(() => this.onHangUp(item.callId))
                    .margin({ start: LengthMetrics.vp(16) })
                    .draggable(false)
                    .accessibilityText(StringUtil.formatResourceToString($r('app.string.hangUp')))
                    .accessibilityRole(AccessibilityRoleType.BUTTON)
                }
              }
              .alignItems(VerticalAlign.Center)
              .onClick(() => this.onUnHold(item.callId))
              .height($r('app.float.call_calllist_height'))
              .onAppear(() => {
                if (item.callState === CallStateConst.CALL_STATUS_ACTIVE && this.callListToShow.length > 1) {
                  AccessibilityUtil.requestFocusForAccessibility(`multiContactCard_callList_${item.callId}}`);
                }
              })
              .id(`multiContactCard_callList_${item.callId}}`)
            }
          }
        })
      }
      .divider({ strokeWidth: '1px', color: $r('sys.color.ohos_id_color_list_separator_dark') })
      .width('100%')
      .listDirection(Axis.Vertical)
      .scrollBar(BarState.Off)

      Divider()
        .color($r('sys.color.ohos_id_color_list_separator_dark'))
    }
    .constraintSize({ minHeight: this.isNewFoldPhoneExternalScreen ? 0 : $r('app.float.call_list_top') })
    .id('callui_callList_Column')
  }
}

@Extend(Button)
function dialingDotExtend(screenReaderStatus: boolean) {
  .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
  .accessibilityText(screenReaderStatus ? StringUtil.formatResourceToString($r('app.string.answer')) : '')
  .accessibilityDescription(screenReaderStatus ?
  StringUtil.formatResourceToString($r('app.string.one_finger_double_click')) : '')
  .accessibilityRole(AccessibilityRoleType.BLANK)
}