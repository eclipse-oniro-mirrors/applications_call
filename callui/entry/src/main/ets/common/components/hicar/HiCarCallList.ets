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

/**
 * @file: User list component
 */
import { common } from '@kit.AbilityKit';
import CallStateConst from '../../constant/CallStateConst';
import CallServiceProxy from '../../../model/CallServiceProxy';
import LogUtils from '../../utils/LogUtils';
import DefaultCallData, { getSimIcon } from '../../struct/TypeUtils';
import CallTimeListStruct from '../../struct/CallTimeListStruct';
import { isIncomingCall, isOutgoingCall, isVideoCall } from '../../utils/CallListHelper';
import { ReportUtil } from '../../utils/ReportUtils/ReportUtil';
import { getCallLabelPrimary } from '../../utils/CallLabelUtils';
import { GlobalContextHelper } from '../../utils/GlobalContextHelper';
import CallDataManager from '../../../model/CallDataManager';
import * as Constants from '../../utils/Constants';
import { ReportDeviceType } from '../../utils/ReportUtils/ReportService';
import CallUtils from '../../utils/CallUtils';
import { NewCallIcon } from '../NewCallIcon';

const TAG = 'HiCarCallList';

@Component
export default struct HiCarCallList {
  private mCallServiceProxy?: CallServiceProxy;
  @Link @Watch('updateCallListToShow') callList: Array<DefaultCallData>;
  @Link @Watch('updateCallListToShow') callId: number;
  @Link @Watch('updateCallListToShow') callState: number;
  @Link videoState: number;
  @Link callType: number;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link hangup: boolean;
  @Link isShowSim: boolean;
  @Link isIncomingState: boolean;
  @State callListToShow: Array<DefaultCallData> = [];
  @State showNewCallMap: Map<number, boolean> = new Map();

  private updateCallListToShow() {
    // We should listen both callList change and callData change because the primary incoming call will change
    this.callListToShow = this.callList.filter(
      (v) => isIncomingCall(this.callState, true) ? v.callId !== this.callId : true
    );
  }

  /**
   * Phone number display
   *
   * @return {string} Phone number
   */
  private getCallTime(item: DefaultCallData): string | undefined | Resource {
    let callTimeObj = this.callTimeList.find((o: CallTimeListStruct) => o.callId === item.callId);
    return callTimeObj ? callTimeObj.callTime : undefined;
  }

  /**
   * Accept call
   *
   * @param {number} callId - callId
   */
  private onAccept(callId: number, isVideoAnswer: boolean): void {
    LogUtils.i(TAG, `onAccept: ${callId} , incomingCall callId: ${this.callId}` +
      `, incomingCall.videoState: ${this.videoState}`);
    this.mCallServiceProxy?.acceptCall(callId, isVideoAnswer);
    if (this.callList.length === 1) {
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.HICAR_CALL_ABILITY_CONTEXT)?.
      terminateSelf().then(() => LogUtils.i(TAG, 'acceptCall terminateSelfCallBack'));
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT)?.
      terminateSelf().then(() => LogUtils.i(TAG, 'acceptCall terminateSelfCallBack'));
    } else if (this.callList.length >= 2) {
      ReportUtil.getInstance().reportMultiCallAction(1, ReportDeviceType.HICAR);
      ReportUtil.getInstance().reportIsDualCardClickListToAnswer(this.callList.length, ReportDeviceType.HICAR);
    }
  }

  /**
   * Hang up call
   *
   * @param {number} callId - callId
   */
  private onHangUp(callId: number): void {
    LogUtils.i(TAG, `onHangUp : ${callId}`);
    this.hangup = true;
    this.mCallServiceProxy?.hangUpCall(callId);
    if (this.callList.length === 1) {
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.HICAR_CALL_ABILITY_CONTEXT)?.
      terminateSelf().then(() => {
        LogUtils.i(TAG, 'onHangUp terminateSelfCallBack');
      });
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT)?.
      terminateSelf().then(() => {
        LogUtils.i(TAG, 'onHangUp terminateSelfCallBack');
      });
    } else if (this.callList.length >= 2) {
      const actionValue: number = CallDataManager.getInstance().isActiveCall(callId) ? 2 : 0;
      ReportUtil.getInstance().reportMultiCallAction(actionValue, ReportDeviceType.HICAR);
      if (actionValue === 2) {
        CallUtils.reportHangupCount();
        ReportUtil.getInstance().reportMultiCallHangUpOne(ReportDeviceType.HICAR);
      }
      ReportUtil.getInstance().reportIsDualCardClickListReject(this.callList.length, ReportDeviceType.HICAR);
    }
  }

  /**
   * UnHold call
   *
   * @param {number} callId - callId
   */
  private onUnHold(callId: number): void {
    if (this.callList.length > 2) {
      LogUtils.w(TAG, 'onUnHold : Skip for non-2-way case!');
      return;
    }

    if (isIncomingCall(this.callState) || isOutgoingCall(this.callState)) {
      LogUtils.w(TAG, 'onUnHold : Skip for incoming or outgoing!');
      return;
    }

    LogUtils.i(TAG, 'onUnHold: finding calls to unhold');
    ReportUtil.getInstance().reportDualCardClickExchangeList(ReportDeviceType.HICAR);
    for (let item of this.callListToShow) {
      if (item.callState === CallStateConst.CALL_STATUS_HOLDING) {
        LogUtils.i(TAG, `onUnHold: Hint call ${item.callId}`);
        this.mCallServiceProxy?.unHoldCall(item.callId);
        return;
      }
    }
    LogUtils.w(TAG, `onUnHold: could not found call to unhold! clicked callid = ${callId}`);
  }

  @Builder
  buildListItem(item: DefaultCallData) {
    ListItem() {
      Row() {
        this.buildItemIcon(item);

        if (item.callState === CallStateConst.callStateObj.CALL_STATUS_ACTIVE) {
          this.buildActiveRow(item);
        } else {
          this.buildUnActiveRow(item);
        }

        this.buildItemButton(item);
      }
      .alignItems(VerticalAlign.Center)
      .onClick(() => this.onUnHold(item.callId))
      .width('100%')
      .height(63)
    }
  }

  @Builder
  buildItemIcon(item: DefaultCallData) {
    if (this.callType === CallStateConst.TYPE_SATELLITE) {
      Image($r('app.media.ic_satellite_call'))
        .margin({ right: 8 })
        .width(14)
        .height(14)
        .id(`callUI_components_HiCarCallList_rowImage_satellite_${item.callId}`)
    } else {
      if (this.isShowSim) {
        SymbolGlyph(getSimIcon(item.accountId))
          .fontColor([$r('sys.color.ohos_fa_icon_contrary')])
          .fontSize(12)
          .width(12)
          .height(12)
          .margin({ right: 8 })
          .id(`callUI_components_HiCarCallList_rowImage_getSimIcon_${item.accountId}`)
      }
    }
  }

  @Builder
  buildItemButton(item: DefaultCallData) {
    if (isIncomingCall(item.callState)) {
      Image($r('app.media.ic_public_ring_off'))
        .width(40)
        .height(40)
        .onClick(() => this.onHangUp(item.callId))
      Image($r('app.media.ic_public_answer'))
        .width(40)
        .height(40)
        .onClick(() => this.onAccept(item.callId, false))
        .margin({ left: 16 })
      if (isVideoCall(item.videoState)) {
        Image($r('app.media.ic_public_answer_video'))
          .width(40)
          .height(40)
          .borderRadius(40)
          .backgroundColor($r('sys.color.confirm'))
          .alignSelf(ItemAlign.Center)
          .onClick(() => this.onAccept(item.callId, true))
          .margin({ left: 16 })
      }
    } else {
      Image($r('app.media.ic_hangup_list'))
        .width(30)
        .height(30)
        .draggable(false)
        .onClick(() => this.onHangUp(item.callId))
        .margin({ left: 16 })
        .fillColor($r('sys.color.warning'))
        .draggable(false)
    }
  }

  @Builder
  buildActiveRow(item: DefaultCallData) {
    Text(getCallLabelPrimary(item))
      .fontColor($r('sys.color.font_on_primary'))
      .fontSize($r('sys.float.Body_L'))
      .fontWeight(FontWeight.Medium)
      .margin({ right: 16 })
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
      .id(`callUI_components_HiCarCallList_rowText_getCallLabelPrimary_${item.callId}`)

    if (CallUtils.getImsDomain(item) === Constants.IMS_DOMAIN.IMS_DOMAIN_VOWIFI) {
      Image($r('app.media.vowifi'))
        .margin({ right: 4 })
        .width(22)
        .height(12)
        .draggable(false)
    } else if (item.callType === CallStateConst.TYPE_IMS) {
      NewCallIcon({
        isHDMode: this.showNewCallMap.get(item.accountId) === true,
        iconColor: '#99FFFFFF',
      })
        .margin({ right: 4 })
        .opacity($r('sys.float.alpha_secondary'))
        .id(`callUI_components_HiCarCallList_rowImage_phone_HD_${item.callId}`)
    }

    Text(this.getCallTime(item))
      .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
      .fontSize($r('sys.float.Body_M'))
      .height(19)
      .lineHeight(19)
      .id(`callUI_components_HiCarCallList_rowText_getCallTime_${item.callId}`)
  }

  @Builder
  buildUnActiveRow(item: DefaultCallData) {
    Text(getCallLabelPrimary(item))
      .fontColor($r('sys.color.font_on_primary'))
      .fontSize($r('sys.float.Body_L'))
      .fontWeight(FontWeight.Medium)
      .margin({ right: 16 })
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
      .id(`callUI_components_HiCarCallList_rowText_getCallLabelPrimary_${item.callId}`)
    Text(CallStateConst.callStateTextArray[item.callState])
      .fontSize($r('sys.float.Body_M'))
      .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
      .height(19)
      .lineHeight(19)
      .id(`callUI_components_HiCarCallList_rowText_callState_${item.callState}`)
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.mCallServiceProxy = CallServiceProxy.getInstance();
    this.updateCallListToShow();
  }

  build() {
    Column() {
      List() {
        ForEach(this.callListToShow, (item: DefaultCallData) => {
          this.buildListItem(item);
        })
      }
      .divider({ strokeWidth: '1px', color: $r('sys.color.font_on_fourth') })
      .width('100%')
      .listDirection(Axis.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .size({
      width: '100%',
      height: isIncomingCall(this.callState, true) ? 64 : 128
    })
    .constraintSize({ minHeight: $r('app.float.call_list_top') })
  }
}