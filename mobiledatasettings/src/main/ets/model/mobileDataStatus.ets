/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import LogUtils from '../common/utils/LogUtils'

const TAG = "mobileDataStatus"

/**
 * Get cellular data status
 *
 * @return {Promise} promise object
 */
export function getCellularDataState() {
  if (telephonyData.getCellularDataState) {
    return telephonyData.getCellularDataState();
  }
}

export function getOperatorName(slotId = 0) {
  return new Promise((resolve, reject) => {
    try {
      radio.getOperatorName(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "getOperatorName error:" + JSON.stringify(error))
          reject(error);
        } else {
          LogUtils.i(TAG, "getOperatorName value:" + JSON.stringify(value))
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getOperatorName catch:" + JSON.stringify(error))
      reject(error);
    }
  });
};

/**
 * Enable mobile data
 *
 * @return {Promise} promise object
 */
export function enableCellularData() {
  if (telephonyData.enableCellularData) {
    return telephonyData.enableCellularData();
  }
}

/**
 * disableCellularData mobile data
 *
 * @return {Promise} promise object
 */
export function disableCellularData() {
  if (telephonyData.disableCellularData) {
    return telephonyData.disableCellularData();
  }
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
export function enableCellularDataRoaming(slotId = 0) {
  return telephonyData.enableCellularDataRoaming(slotId);
}

/**
 * Enabling Data Roaming
 *
 * @return {Promise}
 */
export function disableCellularDataRoaming(slotId = 0) {
  return telephonyData.disableCellularDataRoaming(slotId);
}