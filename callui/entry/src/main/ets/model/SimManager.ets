/**
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

import { Callback } from '@ohos.base';
import sim from '@ohos.telephony.sim';
import LogUtils from '../common/utils/LogUtils';
import { BusinessError } from '@ohos.base';
import radio from '@ohos.telephony.radio';
import { StringUtil } from '../common/utils/StringUtil';

const TAG = 'SimManager';

function notifySimCount(isSimStateActive: boolean[], callback: Callback<number>) {
  let activeCount = 0;
  for (let isActive of isSimStateActive) {
    if (isActive) {
      activeCount++;
    }
  }
  callback(activeCount);
}

export async function getActiveSimCount(callback: Callback<number>) {
  const maxSimCount = sim.getMaxSimCount();
  let isSimStateActive: boolean[] = [false, false];

  try {
    for (let i = 0; i < maxSimCount; i++) {
      // Force check if just register
      isSimStateActive[i] = sim.isSimActiveSync(i);
    }
  } catch (error) {
    LogUtils.e(TAG, 'Check sim count error! ' + JSON.stringify(error));
    return;
  }

  // Invoke the callback immediately to make this event sticky
  notifySimCount(isSimStateActive, callback);
}

export function getSimOperatorNames() {
  const maxSimCount = 2;
  for (let i = 0; i < maxSimCount; i++) {
    sim.getShowName(i, (err: BusinessError<void>, value: string) => {
      if (err) {
        LogUtils.e(TAG, 'getShowName Sim ' + i + ' error:' + JSON.stringify(err.message));
        getDefaultSimName(i);
      } else {
        if (StringUtil.isEmpty(value)) {
          getDefaultSimName(i);
        } else {
          updateSimOperatorName(i, value);
        }
      }
    })
  }
}

function getDefaultSimName(simId: number) {
  radio.getOperatorName(simId, (err: BusinessError<void>, value: string) => {
    if (err) {
      LogUtils.e(TAG, 'getOperatorName Sim ' + simId + ' error:' + JSON.stringify(err.message));
    } else {
      updateSimOperatorName(simId, value);
    }
  })
}

function updateSimOperatorName(simId: number, name: string) {
  if (simId) {
    AppStorage.setOrCreate('simOperatorNameSecond', name);
  } else {
    AppStorage.setOrCreate('simOperatorNameFirst', name);
  }
}

export function getSimOperatorConfigsBySlotId(slotId: number) {
  LogUtils.i(TAG, `getSimOperatorConfigs: ${slotId}`);
  try {
    sim.getOperatorConfigs(slotId).then((data: Array<sim.OperatorConfig>) => {
      data.forEach((element) => {
        if (element.field === 'carrier_vt_available_bool') {
          updateSimOperatorVtAvailable(slotId, element.value);
        }
      })
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, `getOperatorConfigs catch By ${slotId} ${error}`);
    })
  } catch (err) {
    LogUtils.e(TAG, `getOperatorConfigs error By ${slotId}`);
  }
}

function updateSimOperatorVtAvailable(slotId: number, value: string) {
  LogUtils.i(TAG, `update ${slotId} VtAvailable : ${value}`);
  if (slotId) {
    AppStorage.setOrCreate('simOperatorVtAvailableSecond', value === 'true');
  } else {
    AppStorage.setOrCreate('simOperatorVtAvailableFirst', value === 'true');
  }
}

export function isOperatorVtAvailable(accountId: number): boolean {
  const ret = AppStorage.get<boolean>(accountId ? 'simOperatorVtAvailableSecond' : 'simOperatorVtAvailableFirst');
  if (typeof ret === 'boolean') {
    return ret;
  }
  LogUtils.e(TAG, 'vt available storage not bool');
  return true;
}