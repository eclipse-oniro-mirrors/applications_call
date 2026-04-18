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

import { hiSysEvent } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import DefaultCallData from '../../struct/TypeUtils';
import CallStateConst from '../../constant/CallStateConst';
import { ReportService } from './ReportService';

/** malfunctions report call field domain */
const DOMAIN = 'PHONE';
const INCOMING_CALL_NO_UI = 'INCOMING_CALL_NO_UI';
const CALL_END_UI_NOT_DISAPPEAR = 'CALL_END_UI_NOT_DISAPPEAR';

export class CallFaultEventUtil extends ReportService {
  private timeIdOne: number = -1;
  private timeIdTwo: number = -1;
  private disconnectedId: number = 0;
  private uiOnPageShow: boolean = false;
  private isOnDestroy: boolean = false;
  private isDisconnected: boolean = false;
  private static sCallFaultEventUtil: CallFaultEventUtil;
  private isBannerNotification: boolean = false;

  public static getInstance(): CallFaultEventUtil {
    if (!CallFaultEventUtil.sCallFaultEventUtil) {
      CallFaultEventUtil.sCallFaultEventUtil = new CallFaultEventUtil();
    }
    return CallFaultEventUtil.sCallFaultEventUtil;
  }

  domain(): string {
    return DOMAIN;
  }

  eventType(): hiSysEvent.EventType {
    return hiSysEvent.EventType.FAULT;
  }

  public startCallFullScreen(callData: DefaultCallData) {
    if (callData?.callType === CallStateConst.TYPE_VOIP) {
      return;
    }

    this.timeIdOne = setTimeout(() => {
      this.reportTimeOutNoInterface(callData);
    }, 1500);
  }

  public onPageFinishCallEvent() {
    this.uiOnPageShow = true;
    this.clearIncomingTimeId();
  }

  clearIncomingTimeId() {
    if (this.timeIdOne !== -1) {
      clearTimeout(this.timeIdOne);
    }
    if (this.timeIdTwo !== -1) {
      clearTimeout(this.timeIdTwo);
    }
  }

  /**
   * Hang-up always does not start the interface
   *
   * @param { error } errorCode.
   */
  public disconnectedFinishCallEventFault() {
    if (!this.uiOnPageShow) {
      let params: Record<string, string | number | boolean | undefined> = {};
      params['REASON'] = 'The call ends, but the interface is not displayed.';
      this.report(INCOMING_CALL_NO_UI, params);
    } else {
      //Hang-up screen not destroyed
      this.isDisconnected = true;
      this.disconnectedId = setTimeout(() => {
        if (this.isOnDestroy) {
          clearTimeout(this.disconnectedId)
          return;
        }
        let params: Record<string, string | number | boolean | undefined> = {};
        params['REASON'] = 'The call ends, but the screen does not disappear.';
        this.report(CALL_END_UI_NOT_DISAPPEAR, params);
      }, 1500);
    }
  }

  /**
   * Failed to invoke the interface.
   *
   * @param { error } errorCode.
   */
  public startAbilityErrorEvent(errCode: number) {
    let params: Record<string, string | number | boolean | undefined> = {};
    params['REASON'] = 'The startAbility interface is incorrect. The interface is not opened.';
    params['ERROR_CODE'] = JSON.stringify(errCode);
    this.clearIncomingTimeId();
    this.report(INCOMING_CALL_NO_UI, params);
  }

  /**
   * Incoming call does not pull up the interface.
   *
   * @param { callData } callData.
   */
  public reportTimeOutNoInterface(callData: DefaultCallData) {
    if (this.uiOnPageShow) {
      return;
    }
    let params: Record<string, string | number | boolean | undefined> = {};
    params['REASON'] = 'No screen is displayed when an incoming call lasts for 1.5s.';
    this.report(INCOMING_CALL_NO_UI, params);

    this.timeIdTwo = setTimeout(() => {
      if (this.uiOnPageShow) {
        //Timeout interface
        params['REASON'] = 'Incoming call 3s up interface.';
        this.report(INCOMING_CALL_NO_UI, params);
      } else {
        //The interface is not started after 3s.
        params['REASON'] = 'No screen is displayed when an incoming call lasts for 3s.';
        this.report(INCOMING_CALL_NO_UI, params);
      }
    }, 3000);
  }

  public startCallBannerNotification() {
    this.isBannerNotification = true;
  }

  /**
   * Incoming call does not pull up banner.
   *
   * @param { callData } callData.
   */
  public finishBannerNotificationCallEventFault(callData: DefaultCallData, errCode: number) {
    if (this.isBannerNotification) {
      let params: Record<string, string | number | boolean | undefined> = {};
      params['REASON'] = 'No screen is displayed Failed to start the banner interface.';
      params['CALLTYPE'] = callData.callType;
      params['ERROR_CODE'] = errCode;
      this.report(INCOMING_CALL_NO_UI, params);
    }
  }

  public reportOnDestroy() {
    this.isOnDestroy = true;
    if (this.disconnectedId) {
      clearTimeout(this.disconnectedId);
    }
  }

  /**
   * Cancel notification failure dotting.
   *
   * @param { error } errorCode.
   */
  public cancelNotificationCallFaultEvent(error: BusinessError) {
    if (this.isDisconnected) {
      let params: Record<string, string | number | boolean | undefined> = {};
      params['REASON'] = 'Hang-up cancel notification failed';
      params['ERROR_CODE'] = error.code;
      this.report(CALL_END_UI_NOT_DISAPPEAR, params);
    }
  }
}