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
 * @file: Conference call
 */

import router from '@system.router';
import {hangUpCall} from '../../model/callServiceProxy.js';


export default {
    data: {
        callList: []
    },
    onInit() {
        this.callList = this.$app.callList;
    },

    /**
     * Return to the conference call interface by Lu You
     */
    returnBtn() {
        router.back();
    },

    /**
     * Call hangup interface
     * @param {number} callID - callId
     */
    hangUp(callId) {
        hangUpCall(callId);
    }
};