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
 * @file: Call management
 */

import CallDataManager from './callDataManager.js';
import {formatTime} from '../common/utils/utils.js';
import commonEvent from '@ohos.commonevent';
import featureAbility from '@ohos.ability.featureAbility';
import {publish} from './callServiceProxy.js';

let subscriber;
const TIMING = 1000;

const events = ['callui.event.callDetailsChange'];

/**
 * class CallManager
 */
class CallManager {
    constructor(ctx) {
        this.callData = ctx.callData;
        this.timer = null;
        this.ctx = ctx;
        this.callTimeList = ctx.callTimeList;
        this.callDataManager = new CallDataManager(ctx.callData, ctx.callList, ctx.callTimeList);
        this.openTimer(this.updateCallTimeList.bind(this));
        this.sendNotificationHandle = (arg) => arg;
        this.registerSubscriber();
        this.initCallData();
    }

    initCallData() {
        featureAbility.getWant().then((want) => {
            if (want && want.parameters && ('callState' in want.parameters)) {
                this.update(want.parameters);
            } else {
                publish({
                    key: 'getInitCallData',
                    params: []
                });
            }
        }).catch((error) => {
            console.error('Operation failed. Cause: ' + JSON.stringify(error));
        });
    }

    async registerSubscriber() {
        subscriber = await new Promise((resolve) => {
            commonEvent.createSubscriber({events},
                (err, data) => {
                    resolve(data);
                }
            );
        });

        commonEvent.subscribe(subscriber, (err, res) => {
            if (err.code === 0) {
                const callData = JSON.parse(res.data);
                if (callData) {
                    this.update(callData);
                }
            } else {
                console.error('callUI commonEvent.subscribe err: ' + JSON.stringify(err));
            }
        });

    }

    /**
     * unsubscribe
     */
    unsubscribe() {
        commonEvent.unsubscribe(subscriber, (err) => {
            if (err.code !== 0) {
                console.error('callUI commonEvent.unsubscribe err: ' + JSON.stringify(err));
            }
        });
    }

    /**
     * update callData callBack
     * @param { Object } callData -Object
     */
    update(callData) {
        this.callDataManager.update(callData);
    }

    /**
     * add callStateChange callBack
     * @param { Function } callBack - Function
     */
    addCallBack(callBack) {
        this.callDataManager.callStateChange = callBack;
    }

    /**
     * update call time list
     */
    updateCallTimeList() {
        this.callTimeList.forEach((item, i) => {
            item.endTimestamp = new Date().getTime();
            const diffSeconds = Math.floor((item.endTimestamp - item.startTimestamp) / TIMING);
            item.callTime = formatTime(diffSeconds);
            this.callTimeList.splice(i, 1, {
                ...item,
            });
        });
    }

    /**
     * open timer
     * @param { Function } callBack - add updateCallTimeList callBack
     */
    openTimer(callBack) {
        this.timer = setInterval(callBack, TIMING);
    }

    /**
     * clear timer
     */
    clearTimer() {
        clearInterval(this.timer);
    }
}

export default CallManager;