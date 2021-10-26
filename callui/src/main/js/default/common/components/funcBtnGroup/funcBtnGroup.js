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
 * @file: Function button group component
 */

import FA from '@ohos.ability.featureAbility';
import {btnGroupList, threePartyList} from './btnGroupConfig.js';
import {
    CALL_STATUS_ACTIVE, CALL_STATUS_IDLE, CALL_STATUS_HOLDING, defaultCallData
} from '../../../common/constant/callStateConst.js';
import {holdCall, unHoldCall, switchCall, combineConference} from '../../../model/callServiceProxy.js';
import clone from '../../utils/clone.js';
import {TEL_CONFERENCE_ACTIVE} from '../../constant/conferenceConst.js';

const textMap = {
    'record': 'recording',
    'keep': 'keep',
    'add': 'addCall',
    'video': 'videoCall',
    'mute': 'mute',
    'contact': 'contactPerson',
    'exchange': 'exchange',
    'merge': 'mergeCall'
};

export default {
    props: {
        callData: {
            default: defaultCallData
        },
        callList: {
            default: []
        }
    },
    data: {
        timer: null,
        count: 0,
        btnGroupList,
        threePartyList,
        btnList: [],
        oldCallState: CALL_STATUS_IDLE,
    },
    computed: {

        /**
         * @return {number} - call state
         */
        callState() {
            return this.callData.callState;
        }
    },
    onInit() {
        this.btnGroupList.forEach((v) => {
            v.iconText = this.$t(`strings.${textMap[v.type]}`);
        });
        this.threePartyList.forEach((v) => {
            v.iconText = this.$t(`strings.${textMap[v.type]}`);
        });
        this.btnList = clone(this.btnGroupList);
    },

    /**
     * update state of group buttons
     * @param {number} newVal - call state
     */
    onCallStateChange(newVal) {
        if (this.callList.length >= 2 && this.callList.every((v) => v.conferenceState !== TEL_CONFERENCE_ACTIVE)) {
            this.btnList.splice(1, 2, ...clone(this.threePartyList));
        } else {
            this.btnList.splice(1, 2, ...clone(this.btnGroupList).splice(1, 2));
        }
        if (newVal === CALL_STATUS_ACTIVE || newVal === CALL_STATUS_HOLDING) {
            this.btnList.forEach((item) => {
                if (!['video', 'record', 'add', 'mute', 'contact'].includes(item.type)) {
                    item.isDisable = false;
                }
            });
            if (newVal === CALL_STATUS_HOLDING) {
                this.btnList[1].isActive = true;
                this.btnList[4].isDisable = true;
            }
        } else {
            this.btnList.forEach((item) => {
                if (item.type === 'contact') {
                    item.isDisable = true;
                }
            });
        }
    },

    /**
     * Display the buttons of the button group
     * @param {Object} obj - object
     */
    btnClick(obj) {
        const type = obj.detail;
        const { callId } = this.callData;
        if (['record', 'keep', 'video', 'mute'].includes(type)) {
            this.btnList.forEach((item) => {
                if (item.type === type) {
                    item.isActive = !item.isActive;
                }
            });
            if (type === 'record') {
                if (this.btnList[0].isActive) {
                    this.clockHandle();
                } else {
                    this.count = 0;
                    clearInterval(this.timer);
                    this.btnList[0].iconText = this.$t('strings.recording');
                }
            }
        }

        switch (type) {
            case 'record':
                break;
            case 'keep':
                this.keepHandle('keep');
                break;
            case 'exchange':
                switchCall(callId);
                break;
            case 'add':
                FA.startAbility({
                    want: {
                        bundleName: 'com.ohos.contacts',
                        abilityName: 'com.ohos.contacts.MainAbility',
                        parameters: null
                    }
                });
                break;
            case 'video':
                break;
            case 'mute':
                break;
            case 'contact':
                FA.startAbility({
                    want: {
                        bundleName: 'com.ohos.contacts',
                        abilityName: 'com.ohos.contacts.MainAbility',
                        parameters: null
                    }
                });
                break;
            case 'merge':
                combineConference(callId);
                break;
            default:
                break;
        }

    },

    /**
     * Call hold interface
     * @param {string} type - Click the hold button
     */
    keepHandle(type) {
        const awaitIsActive = this.btnList.find((v) => v.type === type).isActive;
        awaitIsActive ? holdCall(this.callData.callId) : unHoldCall(this.callData.callId);
    },

    /**
     * Clear timer
     */
    onDestroy() {
        this.timer && clearInterval(this.timer);
    }
};