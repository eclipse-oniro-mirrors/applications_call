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
 * @file: Header information display component
 */

import router from '@system.router';
import callStateObj, {
    defaultCallData,
    CALL_STATUS_ACTIVE,
    CALL_STATUS_DIALING,
    CALL_STATUS_WAITING,
    getCallStateText
} from '../../../common/constant/callStateConst.js';
import {formatPhoneNum} from '../../utils/utils.js';
import {TEL_CONFERENCE_ACTIVE} from '../../constant/conferenceConst.js';

const THREE_DOTS = 3;
const TIMER_TIMING = 1000;

export default {
    props: {
        callData: {
            default: defaultCallData
        },
        callList: {
            default: []
        },
        isShowKeyboard: {
            default: false
        },
        kbCommand: {
            default: ''
        }
    },
    data: {
        callStateObj,
        address: '',
        simCardType: '',
        timer: null,
        pointTimer: null,
        callStateText: '',
        pointText: '',
        callTimeList: []
    },
    computed: {

        /**
         * Call status
         * @return {number} - Call status
         */
        callState() {
            return this.callData.callState;
        },

        /**
         * Phone number display
         * @return {string} - phone number
         */
        phoneNumber() {
            return formatPhoneNum(this.callData.accountNumber) || this.$t('strings.unknownNumber');
        },

        /**
         * Whether to display the time
         * @return {boolean} - return success true fail false
         */
        isShowTime() {
            return this.callState === CALL_STATUS_ACTIVE && this.callList.length === 1;
        },

        /**
         * Determine whether to display the call list or the input box
         * @return {boolean} - return success true fail false
         */
        isShowCard() {
            return this.callList.length === 1
            || (this.callList.length > 1 && this.callList.some((v) => v.callState === CALL_STATUS_WAITING));
        },

        /**
         * Conference call status
         * @return {number} - Conference call status
         */
        conferenceState() {
            return this.callData.conferenceState;
        },

        /**
         * Conference call
         * @return {boolean} -  return success true fail false
         */
        isConference() {
            return this.conferenceState === TEL_CONFERENCE_ACTIVE;
        },

        /**
         * Reference call-list component
         * @return {boolean} - return success true fail false
         */
        isShowCallList() {
            return (!this.kbCommand || (this.kbCommand && !this.isShowKeyboard))
            && (this.callState === this.callStateObj.CALL_STATUS_WAITING
            || this.callList.length >= 2);
        }
    },
    onInit() {
        this.callTimeList = this.$app.callTimeList;
    },

    /**
     * Animation effect of three dots behind dialing
     */
    addTextPoint() {
        let count = 0;
        this.pointTimer = setInterval(() => {
            this.pointText = new Array(count % THREE_DOTS + 1).fill('.').join('');
            if (count >= THREE_DOTS) {
                count = 0;
            }
            count++;
        }, TIMER_TIMING);
    },

    /**
     * Internationalization display and adding three-point animation effect of dialing status
     * @param {number} newVal - state
     */
    onCallStateChange(newVal) {
        const key = getCallStateText(newVal) || '';
        this.callStateText = key ? this.$t(`strings.${key}`) : '';
        this.pointTimer && clearInterval(this.pointTimer);
        if (newVal === CALL_STATUS_DIALING) {
            this.addTextPoint();
        }
    },

    /**
     * Jump to the conference call interface
     */
    userList() {
        router.push({
            uri: 'pages/conferenceManage/conferenceManage'
        });
    }
};