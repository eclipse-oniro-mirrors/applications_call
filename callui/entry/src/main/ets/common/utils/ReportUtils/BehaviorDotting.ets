/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import CallStateConst from '../../constant/CallStateConst';
import DefaultCallData, { CallDataPatch, MarkType } from '../../struct/TypeUtils';
import { VideoStateType } from '../VideoCallApi';
import { securityGuard } from '@kit.SecurityGuardKit';
import LogUtils from '../LogUtils';
import CallTimeListStruct from '../../struct/CallTimeListStruct';
import CallDataManager from '../../../model/CallDataManager';
import { AntiFraudState } from '../Constants';

const MARK_TYPE_FRAUD_RISK: number = 12;
const TAG = 'BehaviorDotting';

export class BehaviorDotting {
  private static behaviorDotting: BehaviorDotting;
  public version = '1.0';
  public eventId = 0x009000001;

  public static getInstance(): BehaviorDotting {
    if (!BehaviorDotting.behaviorDotting) {
      BehaviorDotting.behaviorDotting = new BehaviorDotting();
    }
    return BehaviorDotting.behaviorDotting;
  }

  private dottingTimeData(): string {
    return new Date().getTime().toString();
  }

  hungOutDotting(callData: DefaultCallData) {
    let callType = (callData.videoState === VideoStateType.TYPE_VIDEO_BIDIRECTIONAL) ? 'video' : 'voice';
    let callState = (callData.callDirection === CallStateConst.CALL_DIRECTION_INCOMING) ? 'inactiveCall' : 'activeCall';
    let numberIsInContacts = (callData.contactName !== undefined && callData.contactName !== '') ? '1' : '0';
    let occurTime = this.dottingTimeData();
    try {
      let contentRecord: Record<string, string | number> = {};
      contentRecord.callId = callData.callId;
      contentRecord.inContacts = numberIsInContacts;
      contentRecord.callType = callType;
      contentRecord.action = 'hangup';
      contentRecord.occurTime = occurTime;
      contentRecord.callState = callState;
      //挂断,取通话时长
      let callTime: CallTimeListStruct | undefined =
        CallDataManager.getInstance().getCallTimeObjByCallId(callData.callId);
      //通话开始时间
      contentRecord.callTime = callTime !== undefined ? callTime.startTimestamp : 0;
      //通话时长
      let callDuration: number = callTime !== undefined ? callTime.endTimestamp - callTime.startTimestamp : 0;
      contentRecord.duration = callDuration;
      //是否高风险电话
      let isAntiFraud: boolean = callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD;
      contentRecord.riskType = isAntiFraud ? '1' : '0';
      //是否非大陆地区电话
      let isForeignNumber = callData.accountNumber.includes('+') && !callData.accountNumber.includes('+86');
      contentRecord.isForeign = isForeignNumber ? '1' : '0';
      //归属地
      contentRecord.fromArea = callData.numberLocation;
      securityGuard.reportSecurityEvent({
        eventId: this.eventId,
        version: this.version,
        content: JSON.stringify(contentRecord)
      })
      LogUtils.i(TAG, 'reportSecurityEvent end success.');
    } catch (error) {
      LogUtils.e(TAG, 'reportSecurityEvent end call error: ' + JSON.stringify(error));
    }
  }

  incomingCallDotting(targetObj: DefaultCallData, callData: DefaultCallData) {
    if (callData.callState !== CallStateConst.CALL_STATUS_ACTIVE) {
      return;
    }
    if ((targetObj.callState === CallStateConst.CALL_STATUS_ANSWER) ||
      (targetObj.callState === CallStateConst.CALL_STATUS_WAITING) ||
      (targetObj.callState === CallStateConst.CALL_STATUS_ALERTING) ||
      (targetObj.callState === CallStateConst.CALL_STATUS_INCOMING)) {
      let callType = (callData.videoState === VideoStateType.TYPE_VIDEO_BIDIRECTIONAL) ? 'video' : 'voice';
      let callState =
        (callData.callDirection === CallStateConst.CALL_DIRECTION_INCOMING) ? 'inactiveCall' : 'activeCall';
      let numberIsInContacts =
        (callData.contactName !== undefined && callData.contactName !== '') ? '1' : '0';
      let occurTime = this.dottingTimeData();
      try {
        securityGuard.reportSecurityEvent({
          eventId: this.eventId,
          version: this.version,
          content: JSON.stringify({
            'callId': callData.callId,
            'inContacts': numberIsInContacts,
            'callType': callType,
            'action': 'accept',
            'occurTime': occurTime,
            'callState': callState
          })
        })
      } catch (error) {
        LogUtils.e(TAG, 'reportSecurityEvent begin call error: ' + JSON.stringify(error));
      }

    }
  }

  updatedCallTypeDotting(callData: DefaultCallData, mode: string) {
    let callState = (callData.callDirection === CallStateConst.CALL_DIRECTION_INCOMING) ? 'inactiveCall' : 'activeCall';
    let numberIsInContacts =
      (callData.contactName !== undefined && callData.contactName !== '') ? '1' : '0';
    let occurTime = this.dottingTimeData();
    try {
      securityGuard.reportSecurityEvent({
        eventId: this.eventId,
        version: this.version,
        content: JSON.stringify({
          'callId': callData.callId,
          'inContacts': numberIsInContacts,
          'callType': 'video',
          'action': 'accept',
          'occurTime': occurTime,
          'callState': callState,
          'mode': mode
        })
      })
    } catch (error) {
      LogUtils.e(TAG, 'reportSecurityEvent begin call error: ' + JSON.stringify(error));
    }
  }
}