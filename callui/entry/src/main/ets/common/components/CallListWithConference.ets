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
import ConferenceConst from '../constant/ConferenceConst';
import CallServiceProxy from '../../model/CallServiceProxy';
import LogUtils from '../utils/LogUtils';
import DefaultCallData, { getSimIcon } from '../struct/TypeUtils';
import CallTimeListStruct from '../struct/CallTimeListStruct';
import { getPrimaryIncomingCall, isIncomingCall, isOutgoingCall, isVideoCall } from '../utils/CallListHelper';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import CallDataManager from '../../model/CallDataManager';
import { getCallLabelPrimary } from '../utils/CallLabelUtils';
import { LengthMetrics } from '@kit.ArkUI';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import { StringUtil } from '../utils/StringUtil';
import Utils from '../utils/utils';
import { ACCESSIBILITY_LEVEL_YES } from '../utils/Constants';

const TAG = 'CallListWithConference';
// first member of conference
const CONFERENCE_TYPE_FIRST: number = 0;
// other members of conference
const CONFERENCE_TYPE_IGNORE: number = 1;
// common call
const COMMON_CALL_TYPE: number = 2;

@Component
export default struct CallListWithConference {
  @Link @Watch('updateCallListToShow') callList: Array<DefaultCallData>;
  @Link @Watch('updateCallListToShow') callData: DefaultCallData;
  @State callState: number = 0;
  @State callId: number = 0;
  @State callListToShow: DefaultCallData[] = [];
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link isShowSim: boolean;
  @State callCount: number = 0;
  @State isForegroundIncoming: boolean = false;
  @State allImsConference: boolean = false;
  @Link showConferenceDetail: boolean;
  @StorageLink('SplitScreenType') @Watch('updateCallListToShow') splitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  private mCallServiceProxy?: CallServiceProxy;

  public aboutToAppear(): void {
    this.updateCallListToShow();
    LogUtils.i(TAG, 'aboutToAppear');
    this.mCallServiceProxy = CallServiceProxy.getInstance();
  }

  /**
   * when call list data change
   *
   * @return {void}
   */
  private updateCallListToShow() {
    this.callState = this.callData.callState;
    this.callId = this.callData.callId;
    this.isForegroundIncoming = isIncomingCall(this.callState, true);
    let count: number = 0;
    let allImsType = true;
    let tempFormatArr: DefaultCallData[] = [];
    let isConferenceMode = false;
    for (let curCallData of this.callList) {
      if (this.isForegroundIncoming && curCallData.callId === this.callId) {
        continue;
      }

      let data: DefaultCallData = JSON.parse(JSON.stringify(curCallData));
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        if (isConferenceMode) {
          data.conferenceType = CONFERENCE_TYPE_IGNORE;
        } else {
          isConferenceMode = true;
          data.conferenceType = CONFERENCE_TYPE_FIRST;
          count++;
        }
        if (allImsType && data.callType !== 1) {
          allImsType = false;
        }
      } else {
        data.conferenceType = COMMON_CALL_TYPE;
        count++;
      }
      tempFormatArr.push(data);
    }
    this.allImsConference = allImsType;
    this.callListToShow = tempFormatArr;
    this.callCount = count;
    this.changeSpliteScreenType()
  }

  private changeSpliteScreenType() {
    if (SplitScreenManager.getInstance().isSplitScreen(this.splitScreenType)) {
      this.callListToShow = this.callListToShow.filter(
        (v) => SplitScreenManager.getInstance().callListItem(this.callData, v, this.splitScreenType)
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
   * Hang up call
   *
   * @param {DefaultCallData} item - DefaultCallData
   */
  public onHangUp(item: DefaultCallData) {
    LogUtils.i(TAG, 'onHangUp : ' + item.callId + ', callList length : ' + JSON.stringify(this.callList.length));
    if (item.conferenceType === CONFERENCE_TYPE_FIRST) {
      this.mCallServiceProxy?.hangUpConference(item.callId);
    } else {
      this.mCallServiceProxy?.hangUpCall(item.callId);
    }
    if (this.callList.length >= 2) {
      let actionValue: number = CallDataManager.getInstance().isActiveCall(item.callId) ? 2 : 0;
      ReportUtil.getInstance().reportMultiCallAction(actionValue);
    }
  }

  /**
   * Accept call
   *
   * @param {number} callId - callId
   */
  public onAccept(callId: number, isVideoAnswer: boolean) {
    let incomingCall = getPrimaryIncomingCall(this.callList);
    LogUtils.i(TAG, 'onAccept : ' + callId + ', callList length : ' + JSON.stringify(this.callList.length) +
      ', incomingCall.videoState :' + incomingCall?.videoState);

    this.mCallServiceProxy?.acceptCall(callId, isVideoAnswer);
    if (this.callList.length >= 2) {
      ReportUtil.getInstance().reportMultiCallAction(1);
    }
  }

  /**
   * UnHold call
   *
   * @param {DefaultCallData} callDataItem - DefaultCallData
   */
  public onUnHold(callDataItem: DefaultCallData) {
    if (this.callCount > 2) {
      LogUtils.w(TAG, 'onUnHold : Skip for non-2-way case!');
      return;
    }

    if (isIncomingCall(this.callState) || isOutgoingCall(this.callState)) {
      LogUtils.w(TAG, 'onUnHold : Skip for incoming or outgoing!');
      return;
    }

    LogUtils.i(TAG, 'onUnHold : ' + callDataItem.callId);

    for (let item of this.callListToShow) {
      if (item.callState === CallStateConst.CALL_STATUS_HOLDING) {
        if (item.conferenceState !== ConferenceConst.TEL_CONFERENCE_IDLE) {
          LogUtils.i(TAG, 'onUnHold: Hint conference call ' + item.callId);
          this.mCallServiceProxy?.unHoldConference(item.callId);
        } else {
          LogUtils.i(TAG, 'onUnHold: Hint call ' + item.callId);
          this.mCallServiceProxy?.unHoldCall(item.callId);
        }
        return;
      }
    }
    LogUtils.w(TAG, 'onUnHold: could not found call to unhold! clicked callid = ' + callDataItem.callId);
  }

  /**
   * Gert call status
   *
   * @return {number} -  callState
   */
  private getCallState(item: DefaultCallData) {
    let callObj = this.callList.find((o) => o.callId === item.callId);
    return callObj ? callObj.callState : -1;
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
          if (item.conferenceType !== CONFERENCE_TYPE_IGNORE) {
            ListItem() {
              Row() {
                if (this.isShowSim) {
                  SymbolGlyph(getSimIcon(item.accountId))
                    .fontColor(['#FFFFFF'])
                    .fontSize($r('app.float.wh_value_12'))
                    .margin({ end: LengthMetrics.vp(8) })
                    .width(12)
                    .height(12)
                    .accessibilityText(this.getAccessibilityText())
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                }

                if (item.conferenceType === CONFERENCE_TYPE_FIRST) {
                  Text($r('app.string.telephone_Conference'))
                    .fontColor($r('sys.color.font_on_primary'))
                    .fontSize($r('app.float.call_calllist_name_font'))
                    .fontWeight(FontWeight.Medium)
                    .height($r('app.float.call_callList_conference_text_height'))
                    .lineHeight($r('app.float.call_callList_conference_text_height'))
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize('24vp')
                    .fontColor([$r('sys.color.icon_on_primary')])
                    .draggable(false)
                    .margin({ start: LengthMetrics.vp(4) })
                    .onClick(() => {
                      if (this.getCallState(item) ===
                      CallStateConst.CALL_STATUS_ACTIVE && !this.isForegroundIncoming) {
                        this.showConferenceDetail = true;
                      }
                    })
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                  Blank().layoutWeight(1)
                } else {
                  Text(getCallLabelPrimary(item))
                    .fontColor($r('sys.color.font_on_primary'))
                    .fontSize($r('app.float.call_calllist_name_font'))
                    .fontWeight(FontWeight.Medium)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                }

                if (item.callState === CallStateConst.callStateObj.CALL_STATUS_ACTIVE) {
                  if (item.callType === CallStateConst.TYPE_IMS ||
                    (item.conferenceType === CONFERENCE_TYPE_FIRST && this.allImsConference)) {
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
                    .fontColor($r('sys.color.font_on_primary'))
                    .height($r('app.float.call_calllist_text_height'))
                    .lineHeight($r('app.float.call_calllist_text_height'))
                    .margin({ start: LengthMetrics.vp(8) })
                    .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
                }

                if (isIncomingCall(item.callState)) {
                  Image($r('app.media.ic_public_ring_off'))
                    .width(40)
                    .height(40)
                    .onClick(() => this.onHangUp(item))
                  Image($r('app.media.ic_public_answer'))
                    .width(40)
                    .height(40)
                    .onClick(() => this.onAccept(item.callId, false))
                    .margin({ start: LengthMetrics.vp(16) })
                  if (isVideoCall(item.videoState)) {
                    Image($r('app.media.ic_public_answer_video'))
                      .width(40)
                      .height(40)
                      .borderRadius(40)
                      .backgroundColor($r('sys.color.confirm'))
                      .alignSelf(ItemAlign.Center)
                      .onClick(() => this.onAccept(item.callId, true))
                      .margin({ start: LengthMetrics.vp(16) })
                  }
                } else {
                  SymbolGlyph($r('sys.symbol.phone_down_fill'))
                    .fontColor(['#E84026'])
                    .fontSize($r('app.float.height_answer_btn_30'))
                    .width(30)
                    .height(30)
                    .draggable(false)
                    .onClick(() => this.onHangUp(item))
                    .margin({ start: LengthMetrics.vp(16) })
                    .accessibilityText(StringUtil.formatResourceToString($r('app.string.hangUp')))
                }
              }
              .alignItems(VerticalAlign.Center)
              .onClick(() => this.onUnHold(item))
              .height($r('app.float.call_list_top'))
            }
          }
        })
      }
      .divider({ strokeWidth: '1px', color: $r('sys.color.ohos_id_color_list_separator_dark') })
      .width('100%')
      .listDirection(Axis.Vertical)
      .scrollBar(BarState.Off)

      Divider().strokeWidth('1px')
        .color($r('sys.color.ohos_id_color_list_separator_dark'))
    }
    .constraintSize({ minHeight: 64 })
  }
}