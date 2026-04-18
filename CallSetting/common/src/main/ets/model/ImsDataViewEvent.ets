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

import radio from '@ohos.telephony.radio';
import { LogUtils } from '../utils/LogUtils';
import call from '@ohos.telephony.call';
import { BusinessError } from '@ohos.base';

const TAG = 'ImsDataViewEvent';

export function enableImsSwitchCardOne() {
  call.enableImsSwitch(0).then((data) => {
    AppStorage.SetOrCreate('imsOne', true);
    LogUtils.i(TAG, 'enableImsSwitch card one : success then ' + JSON.stringify(data));
    setNRMode(0, radio.NROptionMode.NR_OPTION_NSA_AND_SA);
  }).catch((error: BusinessError) => {
    LogUtils.e(TAG, 'enableImsSwitch card one : catch' + JSON.stringify(error));
  });
}

export function enableImsSwitchCardTwo() {
  call.enableImsSwitch(1).then((data) => {
    LogUtils.i(TAG, 'enableImsSwitch card two : success then ' + JSON.stringify(data));
    setNRMode(1, radio.NROptionMode.NR_OPTION_NSA_AND_SA);
  }).catch((error: BusinessError) => {
    LogUtils.e(TAG, 'enableImsSwitch card two : catch' + JSON.stringify(error));
  });
}

export function disableImsSwitchCardOne() {
  call.disableImsSwitch(0).then((data) => {
    AppStorage.SetOrCreate('imsOne', false);
    LogUtils.i(TAG, 'disableImsSwitch card one : success then ' + JSON.stringify(data));
    setNRMode(0, radio.NROptionMode.NR_OPTION_NSA_ONLY);
  }).catch((error: BusinessError) => {
    LogUtils.e(TAG, 'disableImsSwitch card one : catch' + JSON.stringify(error));
  });
}

export function disableImsSwitchCardTwo() {
  call.disableImsSwitch(1).then((data) => {
    LogUtils.i(TAG, 'disableImsSwitch card two : success then ' + JSON.stringify(data));
    setNRMode(1, radio.NROptionMode.NR_OPTION_NSA_ONLY);
  }).catch((error: BusinessError) => {
    LogUtils.e(TAG, 'disableImsSwitch card two : catch' + JSON.stringify(error));
  });
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

export function isImsSwitchEnabled(slotId: number) {
  let result = true;
  try {
    result = call.isImsSwitchEnabledSync(slotId);
  } catch (err) {
    LogUtils.e(TAG, 'isImsSwitchEnabled catch:' + JSON.stringify(err));
    result = false;
  }
  return result;
}

function setNRMode(slotId: number, mode: radio.NROptionMode) {
  radio.setNROptionMode(slotId, mode).then(() => {
    LogUtils.i(TAG, 'setNROption success. slotId: ' + slotId + ' ,mode: ' + mode);
  }).catch((err: BusinessError) => {
    LogUtils.i(TAG,
      'setNROption failed. slotId: ' + slotId + ' ,mode: ' + mode + ' catch: ' + JSON.stringify(err));
  });
}
