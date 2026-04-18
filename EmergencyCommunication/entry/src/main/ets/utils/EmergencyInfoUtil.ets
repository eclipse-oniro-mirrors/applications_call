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

import screenLock from '@ohos.screenLock';
import { BusinessError } from '@ohos.base';
import LogUtils from './HiLog';

const TAG = 'EmergencyInfoUtil';
// 截取字符串的长度，后14位，用来转换为number，202506231848.0001
const LENGTH = 14;
const BETA_TRUE = 'true'
const BETA_FALSE = 'false'

export function CanAddOrEditEmergencyInfo(callback: (isUnlock: boolean) => void) {
    if (screenLock.isLocked()) {
      screenLock.unlock().then((isUnlock: boolean) => {
        if (!isUnlock) {
          LogUtils.i(TAG, 'Screen Lock not unlock.');
        }
        callback(isUnlock);
      }, (err: BusinessError) => {
        LogUtils.e(TAG, `Failed to unlock the screen, Code: ${err.code}, message: ${err.message}`);
        callback(false);
      });
    } else {
      LogUtils.i(TAG, 'EmergencyInfo, screen unLocked.');
      callback(true);
    }
}

/**
 * 把eewId类型，转为EventId的number类型
 *
 * @param callback
 */
export function eewidTransformEventId(eewId: string): number {
  LogUtils.i(TAG, 'eewidTransformEventId.');
  try {
    if (eewId && eewId.length > LENGTH) {
      let eewIdSub = eewId.slice(-LENGTH);
      let res = Number(eewIdSub);
      if (res) {
        return res;
      }
    } else if (eewId) {
      return Number(eewId);
    }
  } catch (e) {
    LogUtils.e(TAG, 'eewidTransformEventId fail param err');
  }
  return 0;
}

export function formatTimeToTimestamp(time: string): number {
  LogUtils.i(TAG, 'formatTimeoTimestamp.');
  try {
    let isoTimeString = time.replace(' ', 'T');
    let date = new Date(isoTimeString);
    let timestamp: number = date.getTime();
    LogUtils.i(TAG, `formatTimeoTimestamp. time ${time}, timestamp ${timestamp}`);
    return timestamp;
  } catch (e) {
    LogUtils.e(TAG, 'formatTimeoTimestamp fail param err');
  }
  return 0;
}