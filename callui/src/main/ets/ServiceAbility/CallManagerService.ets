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
 * @file: call manager service
 */

import PA from '@ohos.ability.particleAbility';
import TelephonyCall from './TelephonyApi.ets';
import commonEvent from '@ohos.commonevent';
import HiLog from '../default/common/utils/Hilog.ets';

let subscriber;
const TAG = "CallManagerService";
const CALL_BUNDLE_NAME = 'com.ohos.callui';
const ABILITY_NAME = 'com.ohos.callui.MainAbility';
const CALL_STATUS_INCOMING = 4;
const CALL_STATUS_DIALING = 2;
const CALL_STATUS_DISCONNECTED = 6;
const CALL_STATUS_DISCONNECTING = 7;
const events = ['callui.event.callEvent', 'callui.event.click'];

/**
 * class CallManagerService
 */
export default class CallManagerService {
  private mTelephonyCall: TelephonyCall ;
  private callData = null;
  private callList = [];

  public constructor() {
    this.mTelephonyCall = new TelephonyCall;
    this.addRegisterListener();
    this.addSubscriber();
  }

  /**
   * add callui app subscriber
   */
  async addSubscriber() {
    subscriber = await new Promise((resolve) => {
      commonEvent.createSubscriber({
        events
      }, (err, data) => {
        HiLog.i(TAG, "addSubscriber  %s")
        resolve(data);
      });
    });

    commonEvent.subscribe(subscriber, (err, res) => {
      if (err.code === 0) {
        if (res.event === events[0]) {
          const obj = JSON.parse(res.data);
          if (obj && obj.key === 'getInitCallData') {
            this.publishData(this.callData);
          }
        }

        if (res.event === events[1]) {
          const {callId,btnType} = res.parameters
          this.btnclickAgent(callId, btnType)
        }
      } else {
        HiLog.i(TAG, "callui service commonEvent.subscribe failed err : %s" + JSON.stringify(err))
      }
      subscriber.finishCommonEvent()
        .then(() => {
        HiLog.i(TAG, "addSubscriber finishCommonEvent : %s")
      })
    });
  }

  /**
   * click button agent
   *
   * @param { number } callId - call id
   * @param { string } btnType - button type
   */
  btnclickAgent(callId, btnType) {
    HiLog.i(TAG, "btnType : %s" + btnType)
    this.getMapObj(btnType, callId)
  }

  getMapObj(typeKey, callId) {
    if (typeKey === 'answer') {
      this.mTelephonyCall.acceptCall(callId)
      this.startAbility(this.callData)
    }
    if (typeKey === 'reject') {
      this.mTelephonyCall.rejectCall(callId)
    }
    if (typeKey === 'hangUp') {
      this.mTelephonyCall.hangUpCall(callId)
    }
  }

  /**
   * add register listener
   */
  addRegisterListener() {
    this.mTelephonyCall.registerCallStateCallback(this.getCallData.bind(this));
  }

  /**
   * get callData
   *
   * @param { Object } callData - Object
   */
  getCallData(callData) {
    this.callData = callData;
    this.updateCallList();
    const {callState} = this.callData;

    /**
     * single call or dialing pull up the application
     */
    if ((callState === CALL_STATUS_INCOMING && this.callList.length === 1) || callState === CALL_STATUS_DIALING) {
      this.startAbility(callData);
    } else if (callState !== CALL_STATUS_DISCONNECTING) {
      this.publishData(callData);
    }
  }

  /**
   * start ability
   *
   * @param { Object } callData - Object
   */
  startAbility(callData) {
    PA.startAbility({
      want: {
        bundleName: CALL_BUNDLE_NAME,
        abilityName: ABILITY_NAME,
        parameters: callData
      }
    }).then((data) => {
      HiLog.i(TAG, "callUI service PA.startAbility data : %s")
    }).catch((err) => {
      HiLog.i(TAG, "callUI service PA.startAbility err : %s" + JSON.stringify(err))
    });
  }

  /**
   * update callList
   */
  updateCallList() {
    const {callState, callId} = this.callData;
    const targetObj = this.callList.find((v) => v.callId === callId);
    if (targetObj) {
      Object.assign(targetObj, {
        ...this.callData
      });
    } else {
      this.callList.push({
        ...this.callData
      });
    }
    if (callState === CALL_STATUS_DISCONNECTED) {
      const index = this.callList.findIndex((v) => v.callId === callId);
      this.callList.splice(index, 1);
    }
  }

  /**
   * commonEvent publish data
   *
   * @param { Object } callData - Object
   */
  publishData(callData) {
    commonEvent.publish('callui.event.callDetailsChange', {
      bundleName: CALL_BUNDLE_NAME,
      isOrdered: false,
      data: JSON.stringify(callData)
    }, (res) => {
      HiLog.i(TAG, "callUI service commonEvent.publish callback res : %s")
    });
  }

  /**
   * unsubscribe
   */
  unsubscribe() {
    commonEvent.unsubscribe(subscriber, (err) => {
      if (err.code !== 0) {
        HiLog.i(TAG, "callUI service commonEvent.unsubscribe err: %s" + JSON.stringify(err))
      }
    });
  }

  /**
   * remove register listener
   */
  removeRegisterListener() {
    this.mTelephonyCall.unRegisterCallStateCallback();
  }
}