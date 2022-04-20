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
 * @file: Voice call API interface call
 */

import call from '@ohos.telephony.call';
import HiLog from '../default/common/utils/Hilog';

const prefixLog = 'callui service:@ohos.telephony.call:';
const TAG = "TelephonyApi";

export default class TelephonyApi {

  /**
   * register call state callback
   *
   * @param { Function } callBack - inject an Function
   */
  public registerCallStateCallback(callBack) {
    call.on('callDetailsChange', (data) => {
      if (!data) {
        HiLog.i(TAG,prefixLog + 'call.on registerCallStateCallback' + JSON.stringify(data))
        return;
      }
      HiLog.i(TAG,prefixLog + 'call.on registerCallStateCallback callState: ' + JSON.stringify(data.callState))
      callBack(data);
    });
  }

  /**
   * onRegister call state callback
   */
  public unRegisterCallStateCallback() {
    call.off('callDetailsChange', (data) => {
      if (!data) {
        HiLog.i(TAG,prefixLog + 'call.off unRegisterCallStateCallback' + JSON.stringify(data))
        return;
      }
      HiLog.i(TAG,prefixLog + 'call.off unRegisterCallStateCallback')
    });
  }

  /**
   * accept call
   *
   * @param { number } callId - call id
   */
  public acceptCall = function (callId) {
    call.answer(callId).then((res) => {
      HiLog.i(TAG,prefixLog +  "call.answer : %s")
    }).catch((err) => {
      HiLog.i(TAG, prefixLog + "call.answer catch : %s" + JSON.stringify(err))
    })
  }

  /**
   * reject call
   *
   * @param { number } callId - call id
   *
   * @param { boolean } isSendSms - is send sms
   *
   * @param { string } msg - message string
   */
  public rejectCall = function (callId, isSendSms = false, msg = '') {
    const rejectCallPromise = isSendSms ? call.reject(callId, {messageContent: msg}) : call.reject(callId);
    rejectCallPromise.then((res) => {
      HiLog.i(TAG,prefixLog +  "then:rejectCall : %s")
    })
      .catch((err) => {
        HiLog.i(TAG, prefixLog + "catch:rejectCall : %s" + JSON.stringify(err))
      });
  };

  /**
   * hang up Call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public hangUpCall = (callId) => new Promise((resolve, reject) => {
    call.hangup(callId).then((res) => {
      resolve(res);
      HiLog.i(TAG, prefixLog + "then:hangUpCall : %s")
    }).catch((err) => {
      reject(err);
      HiLog.i(TAG, prefixLog + "catch:hangUpCall : %s" + JSON.stringify(err))
    });
  });
}


