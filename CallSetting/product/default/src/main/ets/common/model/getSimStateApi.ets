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
import { BusinessError } from '@ohos.base';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'GetSimStateApi';

const SIM_STATE: Record<string, number> = {
  'SIM_STATE_UNKNOWN': 0,
  'SIM_STATE_NOT_PRESENT': 1,
  'SIM_STATE_LOCKED': 2,
  'SIM_STATE_NOT_READY': 3,
  'SIM_STATE_READY': 4,
  'SIM_STATE_LOADED': 5
};

/**
 * Get cardOne status
 *
 * @param {number} slotId - return card The slot id
 * @return {Promise} promise object
 */
export function getSimStateCardOne(slotId = 0) {
  return sim.getSimState(slotId);
}
/**
 * Get cardTwo status
 *
 * @param {string} slotId - card The slot id
 * @return {Promise} promise object
 */
export function getSimStateCardTwo(slotId = 1) {
  return sim.getSimState(slotId);
}

export async function getSimState(slotId: number): Promise<number> {
  let result: number;
  try {
    if (slotId === 0) {
      result = await getSimStateCardOne();
    } else if (slotId === 1) {
      result = await getSimStateCardTwo();
    } else {
      LogUtils.e(TAG, 'getSimState unknown slotId');
      result = SIM_STATE.SIM_STATE_UNKNOWN;
    }
  } catch (e) {
    result = SIM_STATE.SIM_STATE_UNKNOWN;
  }
  return result;
}

export function isSimActive(slotId = 0) {
  return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
    try {
      sim.isSimActive(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, 'isSimActive error slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, 'isSimActive data slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, 'isSimActive catch slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
      reject(error);
    }
  });
}

export async function getSimLabelSync(slotId: number): Promise<sim.SimLabel|null> {
  try {
    return await sim.getSimLabelSync(slotId);
  } catch (err) {
    LogUtils.e(TAG, `getSimLabelSync failed, errCode: ${err?.code}`);
    return null;
  }
}


