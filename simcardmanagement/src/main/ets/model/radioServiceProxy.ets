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
 * @file: radio service interface
 */

import radio from '@ohos.telephony.radio';
import LogUtils from '../common/utils/LogUtils'
import { getString } from '../common/utils/Utils'

const TAG = "radioserviceProxy"

/**
 * Get support network
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
let getSupportNetwork = function (slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      let isSupported = radio.isNrSupported();
      LogUtils.i(TAG, "getSupportNetwork isNrSupported:" + isSupported);
      resolve(isSupported);
    } catch (error) {
      LogUtils.i(TAG, "getSupportNetwork isNrSupported:catch" +  JSON.stringify(error));
      reject(error);
    }
  });
};

/**
 * Get operation name
 *
 * @param {number} slotId - slot id
 * @return {Promise}
 */
let getOperatorName = function (slotId = 0) {
  return new Promise((resolve, reject) => {
    try {
      radio.getOperatorName(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "getOperatorName error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getOperatorName value:" + JSON.stringify(value));
          if (value == 'CHINA MOBILE') {
            LogUtils.i(TAG, "getOperatorName value-CHINA MOBILE:" + JSON.stringify(value));
            resolve(getString($r('app.string.china_mobile')));
          } else {
            resolve(value);
          }
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getOperatorName catch:" + JSON.stringify(error));
      reject(error);
    }
  });
};

export default {
  getSupportNetwork,
  getOperatorName
};