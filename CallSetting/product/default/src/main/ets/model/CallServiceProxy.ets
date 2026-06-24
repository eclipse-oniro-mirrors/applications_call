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
 * @file: Interface reference
 */

import call from '@ohos.telephony.call';
import { BusinessError } from '@ohos.base';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'CallServiceProxy';

/**
 * get call forward info
 *
 * @param {number} slotId - slot id
 * @param {number} callForwardType - mobile busy
 * @return {Promise}
 */
export async function getCallForwardInfo(slotId: number, callForwardType: call.CallTransferType):
  Promise<call.CallTransferResult | BusinessError> {
  LogUtils.i(TAG, 'getCallForwardInfo');
  return new Promise((resolve, reject) => {
    try {
      call.getCallTransferInfo(slotId, callForwardType).then((value) => {
        LogUtils.i(TAG, 'getCallForwardInfo resolve' + value);
        resolve(value);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'getCallForwardInfo error: ' + error.message);
        reject(error);
      });
    } catch (error) {
      LogUtils.e(TAG, 'getCallForwardInfo catch error: ' + (error as BusinessError).message);
      reject(error);
    }
  });
}

/**
 * set call forward
 *
 * @param {number} slotId - slot id
 * @param {number} options - CallTransferInfo {CallTransferSettingType, CallTransferType, transferNum}
 * @return {Promise}
 */
export function setCallForward(slotId: number, options: call.CallTransferInfo): Promise<BusinessError | void> {
  LogUtils.i(TAG, 'setCallForward');
  return new Promise((resolve, reject) => {
    try {
      call.setCallTransfer(slotId, options, (error, value) => {
        if (error) {
          LogUtils.e(TAG, 'setCallForward error: ' + error.message);
          reject(error);
        } else {
          LogUtils.i(TAG, 'setCallForward resolve' + value);
          resolve(value);
        }
      });
    } catch (error) {
      LogUtils.e(TAG, 'setCallForward catch error: ' + (error as BusinessError).message);
      reject(error);
    }
  });
}

/**
 * set callWaiting
 *
 * @param {boolean} activate - {true, false}
 * @param {number} slotId - slot id
 *
 * @return {Promise} promise - promise
 */
export function setCallWaiting(activate: boolean, slotId: number): Promise<void | BusinessError> {
  LogUtils.i(TAG, 'setCallWaiting');
  return new Promise((resolve, reject) => {
    try {
      call.setCallWaiting(slotId, activate).then((value) => {
        LogUtils.i(TAG, 'setCallWaiting resolve');
        resolve(value);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'setCallWaiting then error: ' + error.message);
        reject(error);
      });
    } catch (error) {
      LogUtils.e(TAG, 'setCallWaiting catch error: ' + (error as BusinessError).message);
      reject(error);
    }
  });
}

/**
 * get call waiting
 *
 * @param {number} slotId - slot id
 *
 * @return {Promise}
 */
export function getCallWaiting(slotId: number): Promise<call.CallWaitingStatus | BusinessError> {
  LogUtils.i(TAG, 'getCallWaiting slotId: ' + slotId);
  return new Promise((resolve, reject) => {
    try {
      call.getCallWaitingStatus(slotId).then((value) => {
        LogUtils.i(TAG, 'getCallWaiting value : ' + value);
        resolve(value);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'getCallWaiting then error: ' + error.message);
        reject(error);
      });
    } catch (error) {
      LogUtils.e(TAG, 'getCallWaiting catch error: ' + (error as BusinessError).message);
      reject(error);
    }
  });
}

/**
 * get call Restriction
 *
 * @param {number} slotId - slot id
 * @param {call.CallRestrictionType} callRestrictionType - {0, 1, 2, 3, 4, 5, 6, 7}
 *
 * @return {Promise}
 */
export async function getCallBarringStatus(slotId: number, type: call.CallRestrictionType):
  Promise<Array<call.RestrictionStatus | call.CallRestrictionType> | BusinessError> {
  LogUtils.i(TAG, 'getCallBarringStatus slotId: ' + slotId + ', type: ' + type);
  return new Promise((resolve, reject) => {
    try {
      call.getCallRestrictionStatus(slotId, type).then((value) => {
        LogUtils.i(TAG, 'getCallBarringStatus value' + value);
        resolve([value, type]);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'getCallBarringStatus then error: ' + error.message);
        reject(error);
      });
    } catch (error) {
      LogUtils.e(TAG, 'getCallBarringStatus catch error: ' + (error as BusinessError).message);
      reject(error);
    }
  });
}

/**
 * set Call Restriction
 *
 * @param {number} slotId - slot id
 * @param {call.CallRestrictionInfo} callRestrictionInfo - {CallRestrictionType, password, CallRestrictionMode}
 *
 * @return {Promise}
 */
export function setCallBarring(slotId: number, callBarringInfo: call.CallRestrictionInfo):
  Promise<void | BusinessError> {
  LogUtils.i(TAG, 'setCallBarring');
  return new Promise((resolve, reject) => {
    try {
      call.setCallRestriction(slotId, callBarringInfo).then((value) => {
        LogUtils.i(TAG, 'setCallBarring value' + value);
        resolve(value);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'setCallBarring then error: ' + error.message);
        reject(error);
      });
    } catch (error) {
      LogUtils.e(TAG, 'setCallBarring catch error: ' + (error as BusinessError).message);
      reject(error);
    }
  });
}

/**
 * roaming call
 *
 * @param {number} slotId
 * @param {string} oldPwd
 * @param {string} newPwd
 * @return {Promise}
 */
export function setCallBarringPwd(slotId: number, oldPwd: string, newPwd: string): Promise<void | BusinessError> {
  LogUtils.i(TAG, 'setCallBarringPwd');
  return new Promise((resolve, reject) => {
    try {
      call.setCallRestrictionPassword(slotId, oldPwd, newPwd).then((value) => {
        LogUtils.i(TAG, 'setCallBarringPwd value' + value);
        resolve(value);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'setCallBarringPwd then error: ' + error.message);
        reject(error);
      });
    } catch (error) {
      LogUtils.e(TAG, 'setCallBarringPwd catch error: ' + (error as BusinessError).message);
      reject(error);
    }
  });
}
