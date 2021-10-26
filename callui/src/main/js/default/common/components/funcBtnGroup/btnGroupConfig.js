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
 * @file: Button group configuration file
 */

import {BASE_URL} from '../../constant/imagePathConst.js';

const firstBtns = [
    {
        type: 'record',
        iconDisableUrl: 'soundRecordingGrey',
        iconDefaultUrl: 'soundRecording',
        iconActiveUrl: 'soundEnabled',
        isDisable: true,
        isActive: false,
        iconText: ''
    },
    {
        type: 'keep',
        iconDisableUrl: 'waitForGrey',
        iconDefaultUrl: 'waitFor',
        iconActiveUrl: 'waitForEnabled',
        isDisable: true,
        isActive: false,
        iconText: ''
    },
    {
        type: 'add',
        iconDisableUrl: 'addToGrey',
        iconDefaultUrl: 'addTo',
        iconActiveUrl: '',
        isDisable: false,
        isActive: false,
        iconText: ''
    },
    {
        type: 'video',
        iconDisableUrl: 'videoGrayingGrey',
        iconDefaultUrl: 'videoGraying',
        iconActiveUrl: 'videoEnabled',
        isDisable: true,
        isActive: false,
        iconText: ''
    },
    {
        type: 'mute',
        iconDisableUrl: 'muteGrey',
        iconDefaultUrl: 'mute',
        iconActiveUrl: 'muteEnabled',
        isDisable: true,
        isActive: false,
        iconText: ''
    },
    {
        type: 'contact',
        iconDisableUrl: 'contacts',
        iconDefaultUrl: 'contacts',
        iconActiveUrl: '',
        isDisable: false,
        isActive: false,
        iconText: ''
    }
];

const secondBtns = [
    {
        type: 'exchange',
        iconDisableUrl: 'exchangeGrey',
        iconDefaultUrl: 'exchangeIcon',
        iconActiveUrl: 'exchangeIcon',
        isDisable: false,
        isActive: false,
        iconText: ''
    },
    {
        type: 'merge',
        iconDisableUrl: 'addCallGrey',
        iconDefaultUrl: 'addCall',
        iconActiveUrl: 'addCall',
        isDisable: true,
        isActive: false,
        iconText: ''
    }
];

/**
 * Process the image text of the button group
 * @param {Array} arr - Pass in an array
 */
function addIconUrl(arr) {
    const regExp = /^icon.*.*Url$/;
    arr.forEach((item) => {
        for (let key in item) {
            if (Object.prototype.hasOwnProperty.call(item, key) && regExp.test(key)) {
                item[key] = `${BASE_URL}${item[key]}.png`;
            }
        }
    });
}

addIconUrl(firstBtns);
addIconUrl(secondBtns);

export const btnGroupList = firstBtns;
export const threePartyList = secondBtns;
