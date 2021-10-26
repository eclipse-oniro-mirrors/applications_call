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

import call from '@ohos.telephony.call';

const prefixLog = 'callui service:@ohos.telephony.call:';

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
        console.log(prefixLog + 'call.on registerCallStateCallback callState: ' + res.callState);
        callBack(res);
    });
    console.log('call.on call end');
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

export default {
    registerCallStateCallback,
    unRegisterCallStateCallback,
};
