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
 * @file: Incoming call interface components
 */

import {acceptCall, rejectCall, hangUpCall} from '../../../model/callServiceProxy.js';
import {CALL_STATUS_WAITING} from '../../constant/callStateConst.js';
import {BASE_URL} from '../../constant/imagePathConst.js';

const SMS_REJECTION = `${BASE_URL}shortMessageDisabled.png`;
const SMS_REMINDER = `${BASE_URL}remindDisabled.png`;

export default {
    props: {
        callData: {
            default: {}
        },
    },
    data: {
        btnList: [],
        msgList: [],
        remindList: [],
    },
    onInit() {
        this.btnList = [
            {
                type: 'msg',
                iconText: this.$t('strings.sms'),
                iconDefaultUrl: SMS_REJECTION,
            },
            {
                type: 'remind',
                iconText: this.$t('strings.remind'),
                iconDefaultUrl: SMS_REMINDER,
            },
        ];

        this.msgList = [
            {
                id: 1,
                msg: this.$t('strings.backLater')
            },
            {
                id: 2,
                msg: this.$t('strings.answerThePhone')
            },
            {
                id: 3,
                msg: this.$t('strings.contactMeLater')
            },
            {
                id: 4,
                msg: this.$t('strings.beThereSoon')
            },
            {
                id: 5,
                msg: this.$t('strings.customSMS')
            }
        ];

        this.remindList = [
            {
                id: 1,
                msg: this.$t('strings.minutes')
            },
            {
                id: 2,
                msg: this.$t('strings.oneHourLater')
            },
            {
                id: 3,
                msg: this.$t('strings.twoHoursLater')
            },
        ];

    },

    /**
     * Control the dialog box to close
     * @param {string} type - string
     */
    cancelHandle(type) {
        if (type === 'msg') {
            this.$element('msgDialog').close();
        } else if (type === 'remind') {
            this.$element('remindDialog').close();
        }
    },

    /**
     * Control the dialog box to open
     * @param {Object} obj - Object
     */
    btnClick(obj) {
        const type = obj.detail;
        if (type === 'msg') {
            this.$element('msgDialog').show();
        } else if (type === 'remind') {
            this.$element('remindDialog').show();
        }
    },

    /**
     * Answer the phone interface
     */
    onAnswer() {
        console.log('onAnswer function start');
        console.log('this.callData: ' + JSON.stringify(this.callData));
        acceptCall(this.callData.callId);
    },

    /**
     * Handling interface call hangup and rejection
     */
    async onReject() {
        const {callId, callState} = this.callData;
        if (callState !== CALL_STATUS_WAITING) {
            rejectCall(callId);
        } else {
            hangUpCall(callId);
        }
    },

    /**
     * Call rejection interface
     * @param {string} msg - Send SMS content
     */
    msgItemClick(msg) {
        rejectCall(this.callData.callId, msg);
        this.cancelHandle('msg');
    }
};