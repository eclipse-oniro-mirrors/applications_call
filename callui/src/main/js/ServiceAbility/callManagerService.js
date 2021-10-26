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
 * @file: call manager service
 */

import PA from '@ohos.ability.particleAbility';
import telephonyCall from './telephonyApi.js';
import commonEvent from '@ohos.commonevent';

let subscriber;

const CALL_BUNDLE_NAME = 'com.ohos.callui';
const ABILITY_NAME = 'com.ohos.callui.MainAbility';
const CALL_STATUS_INCOMING = 4;
const CALL_STATUS_DIALING = 2;
const CALL_STATUS_DISCONNECTED = 6;

const events = ['callui.event.callEvent'];

/**
 * class CallManagerService
 */
export default class CallManagerService {
    constructor() {
        this.callData = null;
        this.callList = [];
        this.addRegisterListener();
        this.addSubscriber();
    }

    /**
     * add callui app subscriber
     */
    async addSubscriber() {
        subscriber = await new Promise((resolve) => {
            commonEvent.createSubscriber({events},
                (err, data) => {
                    resolve(data);
                }
            );
        });
        commonEvent.subscribe(subscriber, (err, res) => {
            if (err.code === 0) {
                const obj = JSON.parse(res.data);
                const {key} = obj;
                if (key === 'getInitCallData') {
                    this.publishData(this.callData);
                }
            } else {
                console.error('callui service commonEvent.subscribe failed err: ' + JSON.stringify(err));
            }
        });
    }

    /**
     * add register listener
     */
    addRegisterListener() {
        telephonyCall.registerCallStateCallback(this.getCallData.bind(this));
    }

    /**
     * get callData
     * @param { Object } callData - Object
     */
    getCallData(callData) {
        this.callData = callData;
        this.updateCallList();
        const {callState} = this.callData;
        // single call or dialing pull up the application
        if ((callState === CALL_STATUS_INCOMING && this.callList.length === 1) || callState === CALL_STATUS_DIALING) {
            this.startAbility(callData);
        } else {
            this.publishData(callData);
        }
    }

    /**
     * start ability
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
            console.log('callUI service PA.startAbility res: ' + JSON.stringify(data));
        }).catch((err) => {
            console.log('callUI service PA.startAbility err: ' + JSON.stringify(err));
        });
    }

    /**
     * update callList
     */
    updateCallList() {
        const {callState, callId} = this.callData;
        const targetObj = this.callList.find((v) => v.callId === callId);
        if (targetObj) {
            Object.assign(targetObj, {...this.callData});
        } else {
            this.callList.push({...this.callData});
        }
        if (callState === CALL_STATUS_DISCONNECTED) {
            const index = this.callList.findIndex((v) => v.callId === callId);
            this.callList.splice(index, 1);
        }
    }

    /**
     * commonEvent publish data
     * @param { Object } callData - Object
     */
    publishData(callData) {
        commonEvent.publish('callui.event.callDetailsChange', {
            bundleName: CALL_BUNDLE_NAME,
            isOrdered: false,
            data: JSON.stringify(callData)
        }, (res) => {
            console.log('callUI service commonEvent.publish callback res: ' + res);
        });
    }

    /**
     * unsubscribe
     */
    unsubscribe() {
        commonEvent.unsubscribe(subscriber, (err) => {
            if (err.code !== 0) {
                console.error('callUI service commonEvent.unsubscribe err: ' + JSON.stringify(err));
            }
        });
    }

    /**
     * remove register listener
     */
    removeRegisterListener() {
        telephonyCall.unRegisterCallStateCallback();
    }
}