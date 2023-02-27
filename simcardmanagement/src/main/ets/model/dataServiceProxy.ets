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

/**
 * @file: data service interface
 */

import data from '@ohos.telephony.data';
import LogUtils from '../common/utils/LogUtils'

const TAG = "dataServiceProxy"

/**
 * Get default dataSlotId
 *
 * @return {Promise}
 */
export function getDefaultDataSlotId() {
  return new Promise((resolve, reject) => {
    try {
      data.getDefaultCellularDataSlotId((error, data) => {
        if (error) {
          LogUtils.i(TAG, "getDefaultCellularDataSlotId error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getDefaultCellularDataSlotId data:" + JSON.stringify(data));
          resolve(data);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getDefaultCellularDataSlotId catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Set default dataSlotId
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function setDefaultDataSlotId(slotId = 0) {
  return new Promise((resolve, reject) => {
    try {
      data.setDefaultCellularDataSlotId(slotId, (error, data) => {
        if (error) {
          LogUtils.i(TAG, "setDefaultCellularDataSlotId error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "setDefaultCellularDataSlotId data:" + JSON.stringify(data));
          resolve(true);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "setDefaultCellularDataSlotId catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Is change net
 *
 * @param  {boolean} bool
 * @return {Promise}
 */
export function isChangeNet(bool = true) {
  return new Promise((resolve) => {
    resolve(true);
    LogUtils.i(TAG, "isChangeNet resolve:" + bool);
  });
}

export default {
  getDefaultDataSlotId,
  setDefaultDataSlotId,
  isChangeNet
};