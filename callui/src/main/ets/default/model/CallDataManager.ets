/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
 * @file: Call data management
 */
import CallStateManager from './CallStateManager.ets';
import CallStateConst from '../common/constant/CallStateConst.ets';
import app from '@system.app';
import SendNotification from './SendNotification.ets';
import NotificationManager from '../model/NotificationManager.ets';
import HiLog from '../common/utils/Hilog.ets';

const TAG = "CallDataManager";

/**
 * class CallDataManager
 */
export default class CallDataManager {
  callData :any= {};
  callList :any = [];
  callTimeList :any = [];
  private callStateChange: any;
  private mCallStateManager: CallStateManager ;
  private mSendNotification: SendNotification ;
  private sCallDataManager : CallDataManager ;
  constructor (callData, callList, callTimeList){
    this.mSendNotification = SendNotification.getInstance();
    this.mCallStateManager = CallStateManager.getInstance()
    this.callData = callData;
    this.callList = callList;
//    this.callTimeList = callTimeList;
    this.callStateChange = (arg) => arg;
    this.mCallStateManager = new CallStateManager(this.callData);
  }

  /**
   * update callList and callData callTimeList
   *
   * @param { object } callData
   */
  public update(callData) {
    const { callState, callId } = callData;
    const targetObj = this.callList.find((v) => v.callId === callId);
    HiLog.i(TAG, "update : " )
    if (targetObj) {
      Object.assign(targetObj, {
        ...callData
      });
    } else {
      this.addCallList({
        ...callData
      });
    }

    if (callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      this.updateCallTimeList(callData);
    }
    const singleCallState = callState === CallStateConst.CALL_STATUS_ACTIVE ||
    callState === CallStateConst.CALL_STATUS_WAITING || this.callList.length === 1;
    const multiCallState = (callState === CallStateConst.CALL_STATUS_DIALING ||
    callState === CallStateConst.CALL_STATUS_ALERTING) && this.callList.length > 1;
    if (singleCallState || multiCallState) {
      this.mCallStateManager.update(callData);
      this.callStateChange(callState);
    }

    if (callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
      if (this.callList.length === 1) {
        this.mSendNotification.cancelNotification();
        AppStorage.Get<NotificationManager>('notificationManager').sendCapsuleNotification(callData, true);
        app.terminate();
      } else {
        this.removeCallById(callId);
        const activeCallData = this.callList.find((v) => v.callState === CallStateConst.CALL_STATUS_ACTIVE);
        if (activeCallData) {
          this.mCallStateManager.update(activeCallData);
          this.callStateChange(activeCallData);
        } else if (this.callList[0]) {
          this.mCallStateManager.update(this.callList[0]);
          this.callStateChange(this.callList[0].callState);
        }
      }
    }
  }

  /**
   * addCallList
   *
   * @param { object } callData
   */
  private addCallList(callData) {
    this.callList.push(callData);
  }

  /**
   * remove call by call id
   *
   * @param { object } callId - call id
   */
  private removeCallById(callId) {
    const index = this.callList.findIndex((v) => v.callId === callId);
    this.callList.splice(index, 1);
    if (this.callTimeList.find((v) => v.callId === callId)) {
      this.callTimeList.splice(index, 1);
    }
  }

  /**
   * update callTimeList
   *
   * @param { object } callData
   */
  updateCallTimeList(callData) {
    const CallTimeObj = this.callTimeList.find((v) => v.callId === callData.callId);
    HiLog.i(TAG, "updateCallTimeList : %s" )
    if (!CallTimeObj && callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      const obj = {
        callId: callData.callId,
        callTime: '00:00',
        startTimestamp: callData.startTime || (new Date().getTime()/1000),
        endTimestamp: 0,
      };
      this.callTimeList.push(obj);
      AppStorage.SetOrCreate("CallTimeList", this.callTimeList)
      HiLog.i(TAG, "updateCallTimeList : %s")
    }
  }
}