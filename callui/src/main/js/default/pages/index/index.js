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
 * @file: Main interface
 */

import callStateObj, {getCallStateText} from '../../common/constant/callStateConst.js';
import {sendNotification, cancelNotification} from '../../model/sendNotification.js';

const MARGIN_VALUE = 60;
const SIM_CARD_DELAYED_DISPLAY = 100;
const TIMER_DELAY = 0;

export default {
    data: {
        callStateObj,
        callData: {},
        callList: [],
        isShowKeyboard: false,
        inputValue: '',
        consoleTxt: '',
    },
    computed: {

        /**
         * Call status
         */
        callState() {
            return this.callData.callState;
        },
    },

    onInit() {
        this.callData = this.$app.callData;
        this.callList = this.$app.callList;
        this.$app.callManger.addCallBack(this.onCallStateChange.bind(this));
        this.$app.callManger.sendNotificationHandle = sendNotification;
    },

    /**
     * The calling interface is initialized after running
     */
    onReady() {
        this.onCallStateChange(this.callData.callState);
        let delayMethod = setTimeout(() => {
            this.simCardState();
            clearTimeout(delayMethod);
        }, SIM_CARD_DELAYED_DISPLAY);
    },

    /**
     * Create timer
     * @param {number} newVal - Incoming number
     */
    onCallStateChange(newVal) {
        this.$child('contactCard').onCallStateChange(newVal);
        let timer = setTimeout(() => {
            const funcBtnGroupDom = this.$child('funcBtnGroup');
            if (funcBtnGroupDom && typeof funcBtnGroupDom.onCallStateChange === 'function') {
                funcBtnGroupDom.onCallStateChange(newVal);
            }
            clearTimeout(timer);
        }, TIMER_DELAY);
    },

    /**
     * Close dialog box
     */
    cancel() {
        this.$element('msgDialog').close();
    },

    /**
     * Input content
     * @param {boolean} bool - Incoming value
     */
    showKeyboard({ detail: bool }) {
        this.isShowKeyboard = bool;
    },

    /**
     * Limit text box scrolling effect
     * @param {number} val - Incoming value
     */
    cellClick({ detail: val }) {
        let dtmfStr = this.inputValue + val;
        const codeBoxDom = this.$child('contactCard').$element('codeBox');
        if (codeBoxDom) {
            const rectObj = codeBoxDom.getBoundingClientRect();
            if (rectObj && rectObj.left < MARGIN_VALUE) {
                this.inputValue = dtmfStr.substr(1);
            } else {
                this.inputValue = dtmfStr;
            }
        } else {
            this.inputValue = dtmfStr;
        }
    },
    onActive() {
        cancelNotification();
        this.$app.appInactiveState = false;
    },
    onInactive() {
        this.$app.appInactiveState = true;
        const {callState, accountNumber} = this.callData;
        if (callState !== callStateObj.CALL_STATUS_DISCONNECTED) {
            const key = getCallStateText(callState) || '';
            let callStateText = key ? this.$t(`strings.${key}`) : '';
            if (callState === callStateObj.CALL_STATUS_INCOMING) {
                callStateText = this.$t('strings.incomingCall');
            }
            let text = accountNumber + '  ' + callStateText;
            sendNotification(text);
        }
    },
    onBackPress() {
        return true;
    }
};
