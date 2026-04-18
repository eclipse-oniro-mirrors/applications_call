/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
 * @file: Network mode interface
 */
import radio from '@ohos.telephony.radio';
import { BusinessError } from '@ohos.base';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'setPreferredNetworkModelApi';

/**
 * Set the preferred network mode
 *
 * @param {string} slotId - card The slot id
 * @param {number} auto - card The slot id
 * @return {Promise} promise object
 */
export function setPreferredNetwork(slotId: number, auto: radio.PreferredNetworkMode) {
  return new Promise((resolve: (value: void) => void) => {
    radio.setPreferredNetwork(slotId, auto).then((res) => {
      LogUtils.i(TAG, 'setPreferredNetwork success data then:' + JSON.stringify(res))
      resolve(res);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'setPreferredNetwork  catch:' + JSON.stringify(err))
    });
  });
}

/**
 * Get the preferred network mode
 *
 * @param {string} val - card The slot id
 * @return {Promise} promise object
 */
export function getPreferredNetwork(val: number) {
  return new Promise((resolve: (value: radio.PreferredNetworkMode) => void) => {
    radio.getPreferredNetwork(val).then((res) => {
      LogUtils.i(TAG, 'getPreferredNetwork success data then:' + JSON.stringify(res));
      resolve(res);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'getPreferredNetwork success catch:' + JSON.stringify(err));
    });
  });
}

export function getSupportNetwork(slotId = 0) {
  return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
    try {
      let isSupported = radio.isNrSupported();
      LogUtils.i(TAG, 'getSupportNetwork success data:' + JSON.stringify(isSupported));
      resolve(isSupported);
    } catch (error) {
      LogUtils.i(TAG, 'getSupportNetwork success catch:' + JSON.stringify(error));
      reject(error);
    }
  });
};