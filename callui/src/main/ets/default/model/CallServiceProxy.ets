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

/**
 * The code here is the voice call interface and the sim card interface,
 * as well as the interface piling test simulation,
 * which is convenient for development, so I will leave it for now.
 */

import commonEvent from '@ohos.commonEvent';
import call from '@ohos.telephony.call';
import app from '@system.app';
import HiLog from '../common/utils/Hilog';

const TAG = "CallServiceProxy";
const prefixLog = 'callUI app:@ohos.telephony.call:';

/**
 * dial call
 * @param { string } phoneNumber - phone number
 * @param { number } accountId - account id
 * @param { number } videoState - video state
 * @param { number } dialScene - dial scene
 * @return { Object } promise object
 */
export default class CallServiceProxy {
  private static sCallServiceProxy: CallServiceProxy ;

  /**
   * Make a phone call
   */
  public dialCall(phoneNumber, accountId = 0, videoState = 0, dialScene = 0) {
    HiLog.i(TAG, "dialCall phoneNumber : ")
    return call.dial(phoneNumber, {
      accountId,
      videoState,
      dialScene
    });
  }

  public static getInstance(): CallServiceProxy {
    if (CallServiceProxy.sCallServiceProxy == null) {
      CallServiceProxy.sCallServiceProxy = new CallServiceProxy();
    }
    return CallServiceProxy.sCallServiceProxy;
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
    });
  };

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

  /**
   * hold call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public holdCall = (callId) => new Promise((resolve, reject) => {
    call.holdCall(callId).then((res) => {
      resolve(res);
      HiLog.i(TAG,prefixLog +  "then:holdCall : %s")
    })
      .catch((err) => {
        reject(err);
        HiLog.i(TAG,prefixLog +  "catch:holdCall : %s" + JSON.stringify(err))
    });
  });

  /**
   * un hold call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public unHoldCall = (callId) => new Promise((resolve, reject) => {
    call.unHoldCall(callId).then((res) => {
      resolve(res);
      HiLog.i(TAG,prefixLog +  "then:unHoldCall : %s")
    })
      .catch((err) => {
        reject(err);
        HiLog.i(TAG,prefixLog +  "catch:unHoldCall : %s" + JSON.stringify(err))
    });
  });


  /**
   * audio channel switch
   *
   * @param {number} device - device type
   *
   * @return {Promise} promise object
   */
  public setAudioDevice = (device = 1) => new Promise((resolve, reject) => {
    call.setAudioDevice(device).then((res) => {
      HiLog.i(TAG,prefixLog +  "then:setAudioDevice : %s")
      resolve(res);
    }).catch((err) => {
      reject(err);
      HiLog.i(TAG,prefixLog +  "catch:setAudioDevice : %s" + JSON.stringify(err))
    });
  });

  /**
   * set call mute
   */
  public setMuted() {
    call.setMuted().then((res) => {
      HiLog.i(TAG,prefixLog +  "then:setMute : %s")
    }).catch((err) => {
      HiLog.i(TAG,prefixLog +  "catch:setMute : %s" + JSON.stringify(err))
    });
  };

  /**
   * cancel call mute
   */
  public cancelMuted() {
    call.cancelMuted().then((res) => {
      HiLog.i(TAG,prefixLog +  "then:cancelMuted : %s")
    }).catch((err) => {
      HiLog.i(TAG,prefixLog +  "catch:cancelMuted : %s" + JSON.stringify(err))
    });
  };

  /**
   * switch call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public switchCall = (callId) => new Promise((resolve, reject) => {
    call.switchCall(callId).then((res) => {
      resolve(res);
      HiLog.i(TAG,prefixLog +  "then:switchCall : %s")
    })
      .catch((err) => {
        reject(err);
        HiLog.i(TAG,prefixLog +  "catch:switchCall : %s" + JSON.stringify(err))
    });
  });

  /**
   * register call state callback
   *
   * @param { Function } callBack - inject an Function
   */
  public registerCallStateCallback(callBack) {
    call.on('callDetailsChange', (data) => {
      if (!data) {
        HiLog.i(TAG,prefixLog +  "call.on registerCallStateCallback : %s")
        return;
      }
      HiLog.i(TAG,prefixLog +  "call.on registerCallStateCallback callState : %s")
      callBack(data);
    });
  }

  /**
   * onRegister call state callback
   */
  public unRegisterCallStateCallback() {
    call.off('callDetailsChange', (data) => {
      if (!data) {
        HiLog.i(TAG,prefixLog +  "call.off unRegisterCallStateCallback : %s")
        return;
      }
      HiLog.i(TAG,prefixLog +  "call.off unRegisterCallStateCallback : %s")
    });
  }

  /**
   * register call event callback
   */
  public registerCallEventCallback() {
    call.on('callEventChange', (data) => {
      if (!data) {
        HiLog.i(TAG,prefixLog +  "call.on callEventChange : %s")
      } else {
        HiLog.i(TAG,prefixLog +  "call.on callEventChange : %s")
      }
    });
  }

  /**
   * unRegister call event callback
   */
  public unRegisterCallEventCallback() {
    call.off('callEventChange', (data) => {
      if (!data) {
        HiLog.i(TAG,prefixLog +  "call.off unRegisterCallEventCallback : %s")
      } else {
        HiLog.i(TAG,prefixLog +  "call.off unRegisterCallEventCallback : %s")
      }
    });
  }

  /**
   * start DTMF
   *
   * @param { number } callId - call id
   *
   * @param { string } str - str char
   */
  public startDTMF = (callId, str) => {
    call.startDTMF(callId, str).then((res) => {
      HiLog.i(TAG,prefixLog +  "then:startDtmf : %s")
    }).catch((err) => {
      HiLog.i(TAG,prefixLog +  "catch:startDtmf : %s" + JSON.stringify(err))
    });
  };

  /**
   * stop DTMF
   *
   * @param { number } callId - call id
   */
  public stopDTMF = (callId) => {
    call.stopDTMF(callId).then((res) => {
      HiLog.i(TAG,prefixLog +  "then:stopDtmf : %s")
    }).catch((err) => {
      HiLog.i(TAG,prefixLog +  "then:startDtmf : %s" + JSON.stringify(err))
    });
  };

  /**
   * combine conference
   *
   * @param { number } callId - call id
   */
  public combineConference = (callId) => {
    call.combineConference(callId).then((res) => {
      HiLog.i(TAG,prefixLog +  "then:combineConference : %s")
    }).catch((err) => {
      HiLog.i(TAG,prefixLog +  "catch:combineConference : %s" + JSON.stringify(err))
    });
  };

  public publish(data) {
    HiLog.i(TAG,prefixLog +  "callui.event.callEvent publish  : %s")
    commonEvent.publish('callui.event.callEvent', {
      bundleName: 'com.ohos.callui',
      isOrdered: false,
      data: JSON.stringify(data)
    }, (res) => {
      HiLog.i(TAG,prefixLog +  "callui.event.callEvent success  : %s")
    });
    HiLog.i(TAG,prefixLog +  "callui.event.callEvent publish end : %s")
  }
}

