/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import call from '@ohos.telephony.call';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';
import LogUtils from '../common/utils/LogUtils';
import Utils from '../common/utils/utils';
import { answerCallApi, ImsCallMode, VideoStateType } from '../common/utils/VideoCallApi';
import BannerNotificationManager from './BannerNotificationManager';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import { getActiveCallId, setConferenceDisconnecting } from '../common/utils/CallListHelper';
import DefaultCallData from '../common/struct/TypeUtils';
import CallDataManager from './CallDataManager';
import ConferenceConst from '../common/constant/ConferenceConst';

const TAG = 'CallServiceProxy';
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
  private static sCallServiceProxy: CallServiceProxy;
  private mUtils: Utils = Utils.getInstance();

  public static getInstance(): CallServiceProxy {
    if (!CallServiceProxy.sCallServiceProxy) {
      CallServiceProxy.sCallServiceProxy = new CallServiceProxy();
    }
    return CallServiceProxy.sCallServiceProxy;
  }

  /**
   * Stops the ringtone.
   */
  public muteRinger() {
    LogUtils.i(TAG, 'muteRinger');
    try {
      call.muteRinger();
    } catch (err) {
      LogUtils.e(TAG, `muteRinger exception, Code:${err?.code}, message:${err?.message}`);
    }
  }

  /**
   * accept call
   *
   * @param { number } callId - call id
   */
  public acceptCall = (callId: number, isVideoCall: boolean) => {
    try {
      ReportUtil.getInstance().callAnswerTime = new Date().valueOf();
      answerCallApi(!isVideoCall ? VideoStateType.TYPE_VOICE : VideoStateType.TYPE_VIDEO_BIDIRECTIONAL, callId);
    } catch (err) {
      LogUtils.e(TAG, prefixLog + 'call.answerCall catch : %s' + JSON.stringify(err));
    }

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
  public rejectCall = (callId: number, isSendSms: boolean = false, msg: string = '') => {
    const rejectCallPromise = isSendSms ? call.rejectCall(callId, {
      messageContent: msg
    }) : call.rejectCall(callId);
    rejectCallPromise.then(() => {
      LogUtils.i(TAG, prefixLog + 'then:rejectCall');
    })
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, prefixLog + 'catch:rejectCall : %s' + JSON.stringify(err));
      });
  };
  /**
   * hang up Call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public hangUpCall = (callId: number) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      let targetCall = CallDataManager.getInstance().callList.find((v: DefaultCallData) => v.callId === callId);
      if (targetCall && (Utils.getInstance().isConferenceCall(targetCall))) {
        setConferenceDisconnecting(CallDataManager.getInstance().callList);
      }
      call.hangUpCall(callId).then((res: void) => {
        resolve(res);
        LogUtils.i(TAG, prefixLog + 'then:hangUpCall : %s' + JSON.stringify(callId))
      }).catch((err: BusinessError) => {
        reject(err);
        LogUtils.e(TAG, prefixLog + 'catch:hangUpCall : %s' + JSON.stringify(err))
      });
    });
  /**
   * hang up Conference Call
   *
   * @param { number } callId - call id of a conference participant, used to find the main call id
   *
   * @return { Object } promise object
   */
  public hangUpConference = (callId: number) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      this.getMainCallId(callId, (mainCallId: number) => {
        setConferenceDisconnecting(CallDataManager.getInstance().callList);
        LogUtils.i(TAG,
          `${prefixLog}hangUpConference: getMainCallId#then: callId: ${callId}, mainCallId: ${mainCallId}`);
        call.hangUpCall(mainCallId).then((res: void) => {
          resolve(res);
          LogUtils.i(TAG, prefixLog + 'hangUpConference: hangUpCall#then: ' + JSON.stringify(mainCallId))
        }).catch((err: BusinessError) => {
          reject(err);
          LogUtils.e(TAG, prefixLog + 'hangUpConference: hangUpCall#catch: ' + JSON.stringify(err))
        });
      }).catch((err: BusinessError) => {
        reject(err);
        LogUtils.e(TAG, prefixLog + 'hangUpConference: getMainCallId#catch: ' + JSON.stringify(err))
      });
    });
  /**
   * hold call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public holdCall = (callId: number) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      call.holdCall(callId).then((res: void) => {
        resolve(res);
        LogUtils.i(TAG, prefixLog + 'then:holdCall : %s' + JSON.stringify(callId))
      })
        .catch((err: BusinessError) => {
          reject(err);
          LogUtils.e(TAG, prefixLog + 'catch:holdCall : %s' + JSON.stringify(err))
        });
    });
  /**
   * un hold call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public unHoldCall = (callId: number) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      call.unHoldCall(callId).then((res: void) => {
        resolve(res);
        LogUtils.i(TAG, prefixLog + 'then:unholdCall : %s' + JSON.stringify(callId))
      })
        .catch((err: BusinessError) => {
          reject(err);
          LogUtils.e(TAG, prefixLog + 'catch:unHoldCall : %s' + JSON.stringify(err))
        });
    });
  /**
   * un hold conference
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public unHoldConference = (callId: number) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      this.getMainCallId(callId, (mainId: number) => {
        call.unHoldCall(mainId).then((res) => {
          resolve(res);
          LogUtils.i(TAG, prefixLog + 'then:unHoldConference : %s' + JSON.stringify(callId))
        })
          .catch((err: BusinessError) => {
            reject(err);
            LogUtils.e(TAG, prefixLog + 'catch:unHoldConference : %s' + JSON.stringify(err))
          });
      })
    });

  /**
   * set call mute
   */
  public setMuted() {
    call.setMuted().then(() => {
      LogUtils.i(TAG, prefixLog + 'then:setMute');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, prefixLog + 'catch:setMute : ' + JSON.stringify(err));
    });
  };

  /**
   * cancel call mute
   */
  public cancelMuted() {
    call.cancelMuted().then(() => {
      LogUtils.i(TAG, prefixLog + 'then:cancelMuted');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, prefixLog + 'catch:cancelMuted : ' + JSON.stringify(err));
    });
  };

  /**
   * switch call
   *
   * @param { number } callId - call id
   *
   * @return { Object } promise object
   */
  public switchCall = (callId: number) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      call.switchCall(callId).then((res: void) => {
        resolve(res);
        LogUtils.i(TAG, prefixLog + 'then:switchCall : %s' + JSON.stringify(callId))
      })
        .catch((err: BusinessError) => {
          reject(err);
          LogUtils.e(TAG, prefixLog + 'catch:switchCall : %s' + JSON.stringify(err))
        });
    });

  /**
   * register call event callback
   */
  public registerCallEventCallback(callBack?: Function) {
    try {
      call.on('callEventChange', (data: call.CallEventOptions) => {
        if (!data) {
          LogUtils.i(TAG, prefixLog + 'call.on registerCallEventCallback err');
        } else {
          LogUtils.i(TAG, prefixLog + 'call.on registerCallEventCallback success');
          if (callBack) {
            callBack(data);
          }
        }
      });
    } catch (err) {
      LogUtils.e(TAG, 'call.on registerCallEventCallback catch err' + JSON.stringify(err));
    }
  }

  /**
   * unRegister call event callback
   */
  public unRegisterCallEventCallback() {
    try {
      call.off('callEventChange', (data: call.CallEventOptions) => {
        if (!data) {
          LogUtils.i(TAG, prefixLog + 'call.off unRegisterCallEventCallback error');
        } else {
          LogUtils.i(TAG, prefixLog + 'call.off unRegisterCallEventCallback success');
        }
      });
    } catch (err) {
      LogUtils.e(TAG, 'call.off unRegisterCallEventCallback catch err' + JSON.stringify(err));
    }
  }

  /**
   * start DTMF
   *
   * @param { number } callId - call id
   *
   * @param { string } str - str char
   */
  public startDTMF = (callId: number = 1, str: string = '1') => {
    call.startDTMF(callId, str).then(() => {
      LogUtils.i(TAG, prefixLog + 'then:startDtmf : %s' + JSON.stringify(callId) + JSON.stringify(str))
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, prefixLog + 'catch:startDtmf : %s' + JSON.stringify(err))
    });
  }

  /**
   * stop DTMF
   *
   * @param { number } callId - call id
   */
  public stopDTMF = (callId: number = 1) => {
    try {
      call.stopDTMF(callId).then(() => {
        LogUtils.i(TAG,  `${prefixLog} then:stopDTMF: ${callId}`);
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `${prefixLog} catch:stopDTMF: ${err?.code}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `call.stopDTMF catch err: ${err?.message} ${err?.code}`);
    }
  };

  /**
   * combine conference
   *
   * @param { number } callId - call id
   */
  public combineConference = (callId: number, callback: Function) => {
    call.combineConference(callId).then(() => {
      LogUtils.i(TAG, prefixLog + 'then:combineConference : %s' + JSON.stringify(callId))
    }, (err: BusinessError) => {
      callback(err);
      LogUtils.i(TAG, prefixLog + 'catch:combineConference : %s' + JSON.stringify(err))
    }).catch((err: BusinessError) => {
      Utils.getInstance().showToast(err.message);
      LogUtils.i(TAG, prefixLog + 'catch:combineConference : %s' + JSON.stringify(err))
    });
  };
  /**
   * get conference mainID
   *
   * @param { number } callId - call id
   * @param { function } callback - callback of success
   *
   * @return { Object } promise object
   */
  public getMainCallId = (callId: number, callback: Function) => new Promise(
    (resolve: (value: number) => void, reject: (reason?: BusinessError) => void) => {
      call.getMainCallId(callId).then((res: number) => {
        callback(res);
        resolve(res);
        LogUtils.i(TAG, prefixLog + 'then:getMainCallId : ' + JSON.stringify(callId))
      }).catch((err: BusinessError) => {
        reject(err as BusinessError);
        LogUtils.i(TAG, prefixLog + 'catch:getMainCallId : %s' + JSON.stringify(err as BusinessError))
      });
    });
  /**
   * kick out from conference
   *
   * @param { number } callId - call id
   * @param { function } callback - callback of success
   *
   * @return { Object } promise object
   */
  public kickOutFromConference = (callId: number, callback: Function) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      call.kickOutFromConference(callId).then((res) => {
        callback(res);
        resolve(res);
        LogUtils.i(TAG, prefixLog + 'then:kickOutFromConference : %s' + JSON.stringify(callId))
      }).catch((err: BusinessError) => {
        reject(err);
        LogUtils.i(TAG, prefixLog + 'catch:kickOutFromConference : %s' + JSON.stringify(err))
      });
    });
  /**
   * separate member from conference
   *
   * @param { number } callId - call id
   * @param { function } callback - callback of success
   *
   * @return { Object } promise object
   */
  public separateFromConference = (callId: number, callback: Function) => new Promise(
    (resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
      call.separateConference(callId).then((res) => {
        callback(res, null);
        resolve(res);
        LogUtils.i(TAG, prefixLog + 'then:separateConference : %s' + JSON.stringify(callId))
      }, (err: BusinessError) => {
        callback(null, err);
        LogUtils.i(TAG, prefixLog + 'catch:separateConference : %s' + JSON.stringify(err))
      }).catch((err: BusinessError) => {
        reject(err);
        LogUtils.i(TAG, prefixLog + 'catch:separateConference : %s' + JSON.stringify(err))
      });
    });

  public hangUpActiveCallWhenVoiceToVideoCall(callList: Array<DefaultCallData>): void {
    const activeCallId = getActiveCallId(callList);
    if (activeCallId !== -1) {
      const activeCall = callList.find(item => item.callId === activeCallId);
      if (activeCall?.imsCallMode === ImsCallMode.CALL_MODE_AUDIO_ONLY &&
        activeCall?.videoState === VideoStateType.TYPE_VIDEO_BIDIRECTIONAL
      ) {
        CallServiceProxy.getInstance()?.hangUpCall(activeCall.callId);
      }
    }
  }
}
