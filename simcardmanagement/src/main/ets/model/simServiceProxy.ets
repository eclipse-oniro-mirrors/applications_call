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
 * @file: SIM card service interface
 */

import sim from '@ohos.telephony.sim';
import LogUtils from '../common/utils/LogUtils'
import { getString } from '../common/utils/Utils'

const TAG = "simServiceProxy"

/**
 * Get simAccount number
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getSimAccountNumber(slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      sim.getSimAccountInfo(slotId, (error, info) => {
        if (error) {
          LogUtils.i(TAG, "getSimAccountNumber getSimAccountInfo error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getSimAccountNumber getSimAccountInfo data:" + JSON.stringify(info.showNumber));
          resolve(info.showNumber);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getSimAccountNumber getSimAccountInfo catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * is has simcard
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function hasSimCard(slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      sim.hasSimCard(slotId, (error, data) => {
        if (error) {
          LogUtils.i(TAG, "hasSimCard error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "hasSimCard data:" + JSON.stringify(data));
          resolve(data);
        }
        ;
      });
    } catch (error) {
      LogUtils.i(TAG, "hasSimCard catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Get simSpn
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getSimSpn(slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      sim.getSimSpn(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "getSimSpn error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getSimSpn data:" + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "hasSimCard catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Get sim telephone number
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getSimTelephoneNumber(slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      sim.getSimTelephoneNumber(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "getSimTelephoneNumber error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getSimTelephoneNumber data:" + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getSimTelephoneNumber catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Is sim active
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function isSimActive(slotId = 0) {
  return new Promise((resolve, reject) => {
    try {
      sim.isSimActive(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "isSimActive error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "isSimActive data:" + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "isSimActive catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Get sim state
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getSimState(slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      sim.getSimState(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "getSimState error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getSimState data:" + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getSimState catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Get default voiceSlotId
 *
 * @return {Promise}
 */
export function getDefaultVoiceSlotId() {
  return new Promise(function (resolve, reject) {
    try {
      sim.getDefaultVoiceSlotId((error, value) => {
        if (error) {
          LogUtils.i(TAG, "getDefaultVoiceSlotId error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getDefaultVoiceSlotId data:" + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getDefaultVoiceSlotId catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Set default voiceSlotId
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function setDefaultVoiceSlotId(slotId = 0) {
  return new Promise((resolve, reject) => {
    try {
      sim.setDefaultVoiceSlotId(slotId, (error, data) => {
        if (error) {
          LogUtils.i(TAG, "setDefaultVoiceSlotId error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "setDefaultVoiceSlotId data:" + JSON.stringify(data));
          resolve(true);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "setDefaultVoiceSlotId catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Set sim active
 *
 * @param  {number} slotId - slot ID
 * @param  {boolean} bool - Is SIM card activated
 * @return {Promise}
 */
export function setSimActive(slotId = 0, bool) {
  if (bool) {
    return new Promise((resolve, reject) => {
      try {
        sim.activateSim(slotId, (error) => {
          if (error) {
            LogUtils.i(TAG, "activateSim error:" + JSON.stringify(error));
            reject(error);
          } else {
            LogUtils.i(TAG, "activateSim data:" + JSON.stringify(bool));
            resolve(true);
          }
        });
      } catch (error) {
        LogUtils.i(TAG, "activateSim catch:" + JSON.stringify(error));
        reject(error);
      }
    });
  } else {
    return new Promise((resolve, reject) => {
      try {
        sim.deactivateSim(slotId, (error) => {
          if (error) {
            LogUtils.i(TAG, "deactivateSim error:" + JSON.stringify(error));
            reject(error);
          } else {
            LogUtils.i(TAG, "deactivateSim data:" + JSON.stringify(bool));
            resolve(false);
          }
        });
      } catch (error) {
        LogUtils.i(TAG, "deactivateSim catch:" + JSON.stringify(error));
        reject(error);
      }
    });
  }
}

/**
 * Set show name
 *
 * @param  {number} slotId - slot ID
 * @param  {string} name - name Value
 * @return {Promise}
 */
export function setShowName(slotId = 0, name = '') {
  LogUtils.i(TAG, "setShowName data:" + JSON.stringify(name));
  return new Promise((resolve, reject) => {
    try {
      sim.setShowName(slotId, name, (error) => {
        if (error) {
          LogUtils.i(TAG, "setShowName error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "setShowName success:");
          resolve(true);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "setShowName catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Get show name
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getShowName(slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      sim.getShowName(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "getShowName error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getShowName data:" + JSON.stringify(value));
          if (value == 'CHINA MOBILE') {
            resolve(getString($r('app.string.china_mobile')));
          } else {
            resolve(value);
          }
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getShowName catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Set show number
 *
 * @param  {number} slotId - slot ID
 * @param  {string} number - phone number
 * @return {Promise}
 */
export function setShowNumber(slotId = 0, number = '') {
  LogUtils.i(TAG, "setShowNumber number:" + JSON.stringify(number));
  return new Promise((resolve, reject) => {
    try {
      sim.setShowNumber(slotId, number, (error) => {
        if (error) {
          LogUtils.i(TAG, "setShowNumber error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "setShowNumber success:");
          resolve(true);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "setShowNumber catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * Get show number
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getShowNumber(slotId = 0) {
  return new Promise(function (resolve, reject) {
    try {
      sim.getShowNumber(slotId, (error, value) => {
        if (error) {
          LogUtils.i(TAG, "getShowNumber error:" + JSON.stringify(error));
          reject(error);
        } else {
          LogUtils.i(TAG, "getShowNumber data:" + JSON.stringify(value));
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, "getShowNumber catch:" + JSON.stringify(error));
      reject(error);
    }
  });
}

const simAdapter = {
  getSimAccountNumber,
  getSimSpn,
  getSimTelephoneNumber,
  setDefaultVoiceSlotId,
  getDefaultVoiceSlotId,
  isSimActive,
  hasSimCard,
  getSimState,
  setSimActive,
  setShowName,
  getShowName,
  setShowNumber,
  getShowNumber
};

export default simAdapter;