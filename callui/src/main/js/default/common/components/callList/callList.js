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
 * @file: User list component
 */

import callStateObj, {CALL_STATUS_WAITING, CALL_STATUS_IDLE, getCallStateText, callStateTextMap
} from '../../../common/constant/callStateConst.js';
import {hangUpCall} from '../../../model/callServiceProxy.js';

export default {
    props: {
        callList: {
            default: []
        },
        callTimeList: {
            default: []
        },
        callState: {
            default: CALL_STATUS_IDLE
        },
    },
    data: {
        callStateObj,
        callStateTextMap,
    },
    computed: {

        /**
         * Three-way call list
         * @return {boolean} - Three-way call list
         */
        list() {
            let arr = this.callList.map((item) => {
                const obj = {};
                const callTimeObj = this.callTimeList.find((o) => o.callId === item.callId);
                callTimeObj && Object.assign(obj, {
                    ...callTimeObj
                });
                return Object.assign({}, {
                    ...obj,
                    ...item
                });
            });
            return arr.filter((v) => v.callState !== CALL_STATUS_WAITING);
        },

        /**
         * Phone number display
         * @return {string} Phone number
         */
        phoneNumber() {
            return this.$item.accountNumber || this.$t('strings.unknownNumber');
        },

        /**
         * Internationalized text
         * @return {string} key - getCallStateText Internationalized text
         */
        callStateText() {
            const key = getCallStateText(this.callState) || '';
            return key && this.$t(`strings.${key}`);
        }
    },

    /**
     * hang up
     * @param {number} callId - callId
     */
    onHangUp(callId) {
        hangUpCall(callId);
    }
};

