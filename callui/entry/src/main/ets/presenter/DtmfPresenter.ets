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

import LogUtils from '../common/utils/LogUtils'
import { call } from '@kit.TelephonyKit';

const TAG = 'DtmfPresenter';
let registerPostDialTag = false;

export function registerPostDialDelayCallback(callBack: (res: string | null) => void): void {
  LogUtils.i(TAG, 'registerPostDialWaitCallback');
  if (registerPostDialTag) {
    LogUtils.e(TAG, 'registerPostDialDelayCallback has been registered')
    return;
  }
  registerPostDialTag = true;
  try {
    call.on('postDialDelay', (data: string | null) => {
      if (!data) {
        LogUtils.i(TAG, 'call.on registerPostDialWaitCallback failed');
        callBack(null);
      }
      LogUtils.i(TAG, 'call.on registerPostDialWaitCallback success');
      callBack(data);
    });
  } catch (err) {
    LogUtils.e(TAG, 'call.on registerPostDialWaitCallback err :' + JSON.stringify(err));
  }
}

export function unRegisterPostDialDelay(): void {
  LogUtils.i(TAG, 'unRegisterPostDialDelay');
  if (!registerPostDialTag) {
    LogUtils.e(TAG, 'unRegisterPostDialDelay has not been registered')
    return;
  }
  registerPostDialTag = false;
  try {
    call.off('postDialDelay', (data: string | null) => {
      if (!data) {
        LogUtils.i(TAG, 'call.off unRegisterPostDialDelay failed');
      }
      LogUtils.i(TAG, 'call.off unRegisterPostDialDelay success: ' + data);
    });
  } catch (err) {
    LogUtils.e(TAG, 'call.off unRegisterPostDialDelay err :' + JSON.stringify(err));
  }
}

export function postDialProceed(callId: number, proceed: boolean): void {
  LogUtils.i(TAG, 'postDialProceed ');
  try {
    call.postDialProceed(callId, proceed, () => {
      LogUtils.i(TAG, 'postDialProceed callback: ' + proceed);
    });
  } catch (err) {
    LogUtils.e(TAG, 'postDialProceed err :' + JSON.stringify(err));
  }
}