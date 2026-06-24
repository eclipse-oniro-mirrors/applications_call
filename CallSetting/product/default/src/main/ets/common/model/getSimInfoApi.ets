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
 * @file: Obtaining card status
 */

import sim from '@ohos.telephony.sim';
import { LogUtils } from '@ohos/common/CommonIndex';
import { BusinessError } from '@ohos.base';

const TAG = 'getSimInfoApi';

function getPhoneNumber(slotId: number) {
  return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
    try {
      sim.getShowNumber(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, 'getShowNumber error:' + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, 'getShowNumber success:' + 'The request is successful.');
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, 'getShowNumber catch:' + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Get cardOne status
 *
 * @param {number} slotId - return card The slot id
 * @return {Promise} promise object
 */
export function getSimStateCardOne(slotId = 0): Promise<sim.SimState> {
  return sim.getSimState(slotId);
}

/**
 * Get cardTwo status
 *
 * @param {string} slotId - card The slot id
 * @return {Promise} promise object
 */
export function getSimStateCardTwo(slotId = 1): Promise<sim.SimState> {
  return sim.getSimState(slotId);
}

/**
 * Get cardOnePhoneNumber
 *
 * @param {number} slotId - Returns the id
 * @return {Promise} promise object
 */
export function getSimCardOnePhoneNumber(slotId = 0): Promise<string> {
  return getPhoneNumber(slotId);
}

/**
 * Get cardTwoPhoneNumber
 *
 * @param {number} slotId - card The slot id
 * @return {Promise} promise object
 */
export function getSimCardTwoPhoneNumber(slotId = 1): Promise<string> {
  return getPhoneNumber(slotId);
}

export function getSimCardActiveStatus(slotId: number): Promise<boolean> {
  return sim.isSimActive(slotId);
}

export function getSimCardDefaultPhoneNumber(slotId = 0) {
  return sim.getSimTelephoneNumber(slotId);
}

