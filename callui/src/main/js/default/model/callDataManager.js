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
 * @file: Call data management
 */

import CallStateManager from './callStateManager.js';
import {
    CALL_STATUS_DIALING,
    CALL_STATUS_ALERTING,
    CALL_STATUS_DISCONNECTED,
    CALL_STATUS_ACTIVE,
    CALL_STATUS_WAITING
} from '../common/constant/callStateConst.js';
import app from '@system.app';
import {cancelNotification} from './sendNotification.js';

/**
 * class CallDataManager
 */
export default class CallDataManager {
    constructor(callData, callList, callTimeList) {
        this.callData = callData;
        this.callList = callList;
        this.callTimeList = callTimeList;
        this.callStateChange = (arg) => arg;
        this.callStateManager = new CallStateManager(this.callData);
    }

    /**
     * update callList and callData callTimeList
     * @param { object } callData
     */
    update(callData) {
        const { callState, callId } = callData;
        const targetObj = this.callList.find((v) => v.callId === callId);
        if (targetObj) {
            Object.assign(targetObj, {
                ...callData
            });
        } else {
            this.addCallList({
                ...callData
            });
        }

        if (callState === CALL_STATUS_ACTIVE) {
            this.updateCallTimeList(callData);
        }
        const singleCallState = callState === CALL_STATUS_ACTIVE || callState === CALL_STATUS_WAITING || this.callList.length === 1;
        const multiCallState = (callState === CALL_STATUS_DIALING || callState === CALL_STATUS_ALERTING) && this.callList.length > 1;
        if (singleCallState || multiCallState) {
            this.callStateManager.update(callData);
            this.callStateChange(callState);
        }

        if (callState === CALL_STATUS_DISCONNECTED) {
            if (this.callList.length === 1) {
                cancelNotification();
                app.terminate();
            } else {
                this.removeCallById(callId);
                const activeCallData = this.callList.find((v) => v.callState === CALL_STATUS_ACTIVE);
                if (activeCallData) {
                    this.callStateManager.update(activeCallData);
                    this.callStateChange(activeCallData);
                } else if (this.callList[0]) {
                    this.callStateManager.update(this.callList[0]);
                    this.callStateChange(this.callList[0].callState);
                }
            }
        }
    }

    /**
     * addCallList
     * @param { object } callData
     */
    addCallList(callData) {
        this.callList.push(callData);
    }

    /**
     * remove call by call id
     * @param { object } callId - call id
     */
    removeCallById(callId) {
        const index = this.callList.findIndex((v) => v.callId === callId);
        this.callList.splice(index, 1);
        if (this.callTimeList.find((v) => v.callId === callId)) {
            this.callTimeList.splice(index, 1);
        }
    }

    /**
     * update callTimeList
     * @param { object } callData
     */
    updateCallTimeList(callData) {
        const callTimeObj = this.callTimeList.find((v) => v.callId === callData.callId);
        if (!callTimeObj && callData.callState === CALL_STATUS_ACTIVE) {
            const obj = {
                callId: callData.callId,
                callTime: '00:00',
                startTimestamp: callData.startTime || new Date().getTime(),
                endTimestamp: 0,
            };
            this.callTimeList.push(obj);
        }
    }
}