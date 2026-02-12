/**
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
 * @file: phone number format management
 */
import LogUtils from '../common/utils/LogUtils';
import CallDataManager from './CallDataManager';
import DefaultCallData, { callDataPatcher } from '../common/struct/TypeUtils';
import call from '@ohos.telephony.call';
import i18n from '@ohos.i18n';
import { taskpool } from '@kit.ArkTS';
import { TaskUtil } from '../common/utils/TaskUtil';

const TAG = 'PhoneNumberFormatManager';

/**
 * class PhoneNumberFormatManager
 */
//export default class PhoneNumberFormatManager {
/**
 * get format phone number
 *
 * @param { Object } callData -Object
 */
export function getFormatNumber(callData: DefaultCallData): boolean {
  if (callData.formatNumber) {
    LogUtils.i(TAG, 'formatNumber is exist');
    return false;
  }
  let phoneNumber: string = callData.accountNumber;
  const patch = callDataPatcher.createPatch({
    callId: callData.callId,
    formatNumber: phoneNumber,
  });
  if (phoneNumber) {
    try {
      createFormatNumberTask(phoneNumber, (formatNumber: string) => {
        patch.formatNumber = formatNumber;
        callDataPatcher.apply(callData, patch, 'createFormatNumberTask callback');
        CallDataManager.getInstance().updateCallerInfo(patch);
      })
    } catch (err) {
      callDataPatcher.apply(callData, patch, 'createFormatNumberTask failed');
      CallDataManager.getInstance().updateCallerInfo(patch);
      LogUtils.e(TAG, 'getFormatNumber catch err:' + JSON.stringify(err));
    }
  }
  return true;
}

export function createFormatNumberTask(phoneNumber: string, callback: (data: string) => void) {
  let task = new taskpool.Task(formatPhoneNum, phoneNumber);
  TaskUtil.getInstance().executeTask(task, (data: object) => {
    let number = data as string[];
    if (!number) {
      LogUtils.i(TAG, 'formatNumber is null');
      callback(phoneNumber);
      return;
    }
    callback(number.toString());
  })
}

/**
 * format phone number
 *
 * @param { string } phoneNumber
 */
@Concurrent
async function formatPhoneNum(phoneNumber: string): Promise<string> {
  let countryId = i18n.System.getSystemRegion();
  let options: call.NumberFormatOptions = {
    countryCode: countryId
  }
  try {
    let number = await call.formatPhoneNumber(phoneNumber, options);
    LogUtils.i('PhoneNumberFormatManager', 'formatPhoneNumber success');
    return number;
  } catch (err) {
    LogUtils.e('PhoneNumberFormatManager', 'formatPhoneNumber fail, promise: err');
    return phoneNumber;
  }
}