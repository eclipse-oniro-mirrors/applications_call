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

import telephonyData from '@ohos.telephony.data';
import radio from '@ohos.telephony.radio';
import { LogUtils } from '../utils/LogUtils';
import { BusinessError } from '@ohos.base';
import { ReportUtil } from '../utils/ReportUtil';

const TAG = 'MobileDataStatus';

/**
 * Get cellular data status
 *
 * @return {Promise} promise object
 */
export function isCellularDataEnabled() {
  return telephonyData.isCellularDataEnabled();
}

export function isCellularDataEnabledSync() {
  return telephonyData.isCellularDataEnabledSync();
}

/**
 * Enable mobile data
 *
 * @return {Promise} promise object
 */
export function enableCellularData() {
  return telephonyData.enableCellularData();
}

/**
 * disableCellularData mobile data
 *
 * @return {Promise} promise object
 */
export function disableCellularData() {
  return telephonyData.disableCellularData();
}

/**
 * Whether to enable cellular data roaming
 *
 * @return {Promise}
 */
export function getCellularDataRoaming(slotId = 0) {
  return telephonyData.isCellularDataRoamingEnabled(slotId);
}

/**
 * Enabling Data Roaming
 *
 * @return {Promise}
 */
export function enableCellularDataRoamingCardOne(slotId = 0) {
  ReportUtil.getInstance().reportClickMobileRoamingButton(1, 1);
  return new Promise((resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
    try {
      telephonyData.enableCellularDataRoaming(slotId, (error, value) => {
        if (error) {
          LogUtils.e(TAG, 'enableCellularDataRoaming card one error :' + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, 'enableCellularDataRoaming card one success : then' + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'enableCellularDataRoaming card one catch: ' + JSON.stringify(error));
      reject(error);
    }
  });
}

export function enableCellularDataRoamingCardTwo(slotId = 1) {
  ReportUtil.getInstance().reportClickMobileRoamingButton(2, 1);
  return new Promise((resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
    try {
      telephonyData.enableCellularDataRoaming(slotId, (error, value) => {
        if (error) {
          LogUtils.e(TAG, 'enableCellularDataRoaming card two error :' + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, 'enableCellularDataRoaming card two success :then' + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'enableCellularDataRoaming card two catch: ' + JSON.stringify(error));
      reject(error);
    }
  });
}

export async function enableCellularDataRoamingCard(slotId: number): Promise<boolean> {
  let result = true;
  try {
    if (slotId === 0) {
      await enableCellularDataRoamingCardOne();
    } else if (slotId === 1) {
      await enableCellularDataRoamingCardTwo();
    } else {
      LogUtils.e(TAG, 'enableCellularDataRoamingCard unknown slotId');
      result = false;
    }
  } catch (e) {
    result = false;
  }
  return result;
}

/**
 * Enabling Data Roaming
 *
 * @return {Promise}
 */
export function disableCellularDataRoamingCardOne(slotId = 0) {
  ReportUtil.getInstance().reportClickMobileRoamingButton(1, 0);
  return new Promise((resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
    try {
      telephonyData.disableCellularDataRoaming(slotId, (error, value) => {
        if (error) {
          LogUtils.e(TAG, 'disableCellularDataRoaming card one error : ' + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, 'disableCellularDataRoaming card one success : then' + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'disableCellularDataRoaming card one catch:' + JSON.stringify(error));
      reject(error);
    }
  });
}

export function disableCellularDataRoamingCardTwo(slotId = 1) {
  ReportUtil.getInstance().reportClickMobileRoamingButton(2, 0);
  return new Promise((resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
    try {
      telephonyData.disableCellularDataRoaming(slotId, (error, value) => {
        if (error) {
          LogUtils.e(TAG, 'disableCellularDataRoaming card two error :' + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, 'disableCellularDataRoaming card two success :then' + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'disableCellularDataRoaming card two catch:' + JSON.stringify(error));
      reject(error);
    }
  });
}

export async function disableCellularDataRoamingCard(slotId: number): Promise<boolean> {
  let result = true;
  try {
    if (slotId === 0) {
      await disableCellularDataRoamingCardOne();
    } else if (slotId === 1) {
      await disableCellularDataRoamingCardTwo();
    } else {
      LogUtils.e(TAG, 'disableCellularDataRoamingCard unknown slotId');
      result = false;
    }
  } catch (e) {
    result = false;
  }
  return result;
}

export function setNetworkCapabilityLTEOn(slotId: number) {
  let type: radio.NetworkCapabilityType = radio.NetworkCapabilityType.SERVICE_TYPE_LTE;
  let state: radio.NetworkCapabilityState = radio.NetworkCapabilityState.SERVICE_CAPABILITY_ON;
  radio.setNetworkCapability(slotId, type, state).then(() => {
    LogUtils.i(TAG, 'setNetworkCapability LTE card ' + slotId + ' On success');
  }).catch((err: BusinessError) => {
    LogUtils.e(TAG, 'setNetworkCapability LTE card ' + slotId + ' : catch' + JSON.stringify(err.code));
  });
}

export function setNetworkCapabilityLTEOff(slotId: number) {
  let type: radio.NetworkCapabilityType = radio.NetworkCapabilityType.SERVICE_TYPE_LTE;
  let state: radio.NetworkCapabilityState = radio.NetworkCapabilityState.SERVICE_CAPABILITY_OFF;
  radio.setNetworkCapability(slotId, type, state).then(() => {
    LogUtils.i(TAG, 'setNetworkCapability LTE card ' + slotId + ' Off success');
  }).catch((err: BusinessError) => {
    LogUtils.e(TAG, 'setNetworkCapability LTE card ' + slotId + ' : catch' + JSON.stringify(err.code));
  });
}

export function setNetworkCapabilityNROn(slotId: number) {
  let type: radio.NetworkCapabilityType = radio.NetworkCapabilityType.SERVICE_TYPE_NR;
  let state: radio.NetworkCapabilityState = radio.NetworkCapabilityState.SERVICE_CAPABILITY_ON;
  radio.setNetworkCapability(slotId, type, state).then(() => {
    LogUtils.i(TAG, 'setNetworkCapability NR card ' + slotId + ' On success');
  }).catch((err: BusinessError) => {
    LogUtils.e(TAG, 'setNetworkCapability NR card ' + slotId + ' : catch' + JSON.stringify(err.code));
  });
}

export function setNetworkCapabilityNROff(slotId: number) {
  let type: radio.NetworkCapabilityType = radio.NetworkCapabilityType.SERVICE_TYPE_NR;
  let state: radio.NetworkCapabilityState = radio.NetworkCapabilityState.SERVICE_CAPABILITY_OFF;
  radio.setNetworkCapability(slotId, type, state).then(() => {
    LogUtils.i(TAG, 'setNetworkCapability NR card ' + slotId + ' Off success');
  }).catch((err: BusinessError) => {
    LogUtils.e(TAG, 'setNetworkCapability NR card ' + slotId + ' : catch' + JSON.stringify(err.code));
  });
}