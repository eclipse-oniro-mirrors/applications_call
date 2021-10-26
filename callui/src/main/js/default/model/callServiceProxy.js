/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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
 * */

import commonEvent from '@ohos.commonevent';
import call from '@ohos.telephony.call';

const prefixLog = 'callUI app:@ohos.telephony.call:';

/**
 * dial call
 * @param { string } phoneNumber - phone number
 * @param { number } accountId - account id
 * @param { number } videoState - video state
 * @param { number } dialScene - dial scene
 * @return { Object } promise object
 */
export function dialCall(phoneNumber, accountId = 0, videoState = 0, dialScene = 0) {
    console.log(prefixLog + 'dialCall start');
    return call.dial(phoneNumber, {
        accountId,
        videoState,
        dialScene
    });
}

/**
 * accept call
 * @param { number } callId - call id
 */
export const acceptCall = function (callId) {
    call.answer(callId).then((res) => {
        console.log(prefixLog + 'then:acceptCall' + JSON.stringify(res));
    }).catch((err) => {
        console.log(prefixLog + 'catch:acceptCall' + JSON.stringify(err));
    });
};

/**
 * reject call
 * @param { number } callId - call id
 * @param { boolean } isSendSms - is send sms
 * @param { string } msg - message string
 */
export const rejectCall = function (callId, isSendSms = false, msg = '') {
    const rejectCallPromise = isSendSms ? call.reject(callId, {messageContent: msg}) : call.reject(callId);
    rejectCallPromise.then((res) => {
        console.log(prefixLog + 'then:rejectCall' + JSON.stringify(res));
    }).catch((err) => {
        console.log(prefixLog + 'catch:rejectCall' + JSON.stringify(err));
    });
};

/**
 * hang up Call
 * @param { number } callId - call id
 * @return { Object } promise object
 */
export const hangUpCall = (callId) => new Promise((resolve, reject) => {
    call.hangup(callId).then((res) => {
        resolve(res);
        console.log(prefixLog + 'then:hangUpCall' + JSON.stringify(res));
    }).catch((err) => {
        reject(err);
        console.log(prefixLog + 'catch:hangUpCall' + JSON.stringify(err));
    });
});

/**
 * hold call
 * @param { number } callId - call id
 * @return { Object } promise object
 */
export const holdCall = (callId) => new Promise((resolve, reject) => {
    call.holdCall(callId).then((res) => {
        resolve(res);
        console.log(prefixLog + 'then:holdCall' + JSON.stringify(res));
    }).catch((err) => {
        reject(err);
        console.log(prefixLog + 'catch:holdCall' + JSON.stringify(err));
    });
});

/**
 * un hold call
 * @param { number } callId - call id
 * @return { Object } promise object
 */
export const unHoldCall = (callId) => new Promise((resolve, reject) => {
    call.unHoldCall(callId).then((res) => {
        resolve(res);
        console.log(prefixLog + 'then:unHoldCall' + JSON.stringify(res));
    }).catch((err) => {
        reject(err);
        console.log(prefixLog + 'catch:unHoldCall' + JSON.stringify(err));
    });
});

/**
 * switch call
 * @param { number } callId - call id
 * @return { Object } promise object
 */
export const switchCall = (callId) => new Promise((resolve, reject) => {
    call.switchCall(callId).then((res) => {
        resolve(res);
        console.log(prefixLog + 'then:switchCall' + JSON.stringify(res));
    }).catch((err) => {
        reject(err);
        console.log(prefixLog + 'catch:switchCall' + JSON.stringify(err));
    });
});

/**
 * register call state callback
 * @param { Function } callBack - inject an Function
 */
export function registerCallStateCallback(callBack) {
    call.on('callDetailsChange', (err, res) => {
        if (err) {
            console.log(prefixLog + 'call.on registerCallStateCallback' + JSON.stringify(err));
            return;
        }
        console.log(prefixLog + 'call.on registerCallStateCallback callState: '
        + JSON.stringify(res.callState));
        callBack(res);
    });
}

/**
 * onRegister call state callback
 */
export function unRegisterCallStateCallback() {
    call.off('callDetailsChange', (err, res) => {
        if (err) {
            console.log(prefixLog + 'call.off unRegisterCallStateCallback' + JSON.stringify(err));
            return;
        }
        console.log(prefixLog + 'call.off unRegisterCallStateCallback' + JSON.stringify(res));
    });
}

/**
 * register call event callback
 */
export function registerCallEventCallback() {
    call.on('callEventChange', (err, value) => {
        if (err) {
            console.log(prefixLog + 'call.on callEventChange' + JSON.stringify(err));
        } else {
            console.log(prefixLog + 'call.on callEventChange' + JSON.stringify(value));
        }
    });
}

/**
 * unRegister call event callback
 */
export function unRegisterCallEventCallback() {
    call.off('callEventChange', (err, value) => {
        if (err) {
            console.log(prefixLog + 'call.off unRegisterCallEventCallback' + JSON.stringify(err));
        } else {
            console.log(prefixLog + 'call.off unRegisterCallEventCallback' + JSON.stringify(value));
        }
    });
}

/**
 * start DTMF
 * @param { number } callId - call id
 * @param { string } str - str char
 */
export const startDTMF = (callId, str) => {
    call.startDTMF(callId, str).then((res) => {
        console.log(prefixLog + 'then:startDtmf' + JSON.stringify(res));
    }).catch((err) => {
        console.log(prefixLog + 'catch:startDtmf' + JSON.stringify(err));
    });
};

/**
 * stop DTMF
 * @param { number } callId - call id
 */
export const stopDTMF = (callId) => {
    call.stopDTMF(callId).then((res) => {
        console.log(prefixLog + 'then:stopDtmf' + JSON.stringify(res));
    }).catch((err) => {
        console.log(prefixLog + 'catch:stopDtmf' + JSON.stringify(err));
    });
};

/**
 * combine conference
 * @param { number } callId - call id
 */
export const combineConference = (callId) => {
    call.combineConference(callId).then((res) => {
        console.log(prefixLog + 'then:combineConference' + JSON.stringify(res));
    }).catch((err) => {
        console.log(prefixLog + 'catch:combineConference' + JSON.stringify(err));
    });
};

export function publish(data) {
    console.log('callui.event.callEvent publish data: ' + JSON.stringify(data));
    commonEvent.publish('callui.event.callEvent', {
        bundleName: 'com.ohos.callui',
        isOrdered: false,
        data: JSON.stringify(data)
    }, (res) => {
        console.log('callui.event.callEvent success res: ' + res);
    });
    console.log('callui.event.callEvent publish end');
}
