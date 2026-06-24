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

import data_preferences from '@ohos.data.preferences';
import { LogUtils } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

const TAG = 'dataStorageUtil';
const DATA_PREFERENCES_NAME = 'data_preference_name';
const DATA_KEY_END = 'data_key';

let dataPreferences: data_preferences.Preferences;
let defaultData: number[] = [0, 0];

function getDataPreferences(context: common.ExtensionContext | common.UIAbilityContext,
  callback: (result: boolean) => void) {
  if (!context) {
    callback(false);
    return;
  }
  try {
    let promise = data_preferences.getPreferences(context, DATA_PREFERENCES_NAME);
    promise.then((object) => {
      dataPreferences = object;
      LogUtils.i(TAG, 'Succeeded in getting preferences.');
      callback(true);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'Failed to get preferences. code =' + err.code + ', message =' + err.message);
      callback(false);
    })
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'Failed to get preferences. code =' + error.code + ', message =' + error.message);
    callback(false);
  }
}

export function getStorageData(context: common.UIAbilityContext, callback: (data: number[]) => void): void {
  let getStorageDataCallback = (result: boolean) => {
    if (result) {
      try {
        let key = DATA_KEY_END;
        let data = dataPreferences.getSync(key, JSON.stringify(defaultData));
        LogUtils.i(TAG, 'getStorageData getAll object = ' + data);
        callback(JSON.parse(data.toString()));
      } catch (err) {
        LogUtils.e(TAG, 'getStorageData error to get all key-values. code =' + (err as BusinessError).code + ', message =' + (err as BusinessError).message);
        callback(defaultData);
      }
    } else {
      callback(defaultData)
    }
  }

  if (!dataPreferences) {
    getDataPreferences(context, getStorageDataCallback);
  } else {
    getStorageDataCallback(true);
  }
}

export function updateStorage(context: common.UIAbilityContext, value: number[]): void {
  let updateStorageCallback = (result: boolean) => {
    if (result) {
      let key = DATA_KEY_END;
      try {
        dataPreferences.putSync(key, JSON.stringify(value));
        saveStorage(context);
      } catch (err) {
        LogUtils.i(TAG, 'Failed to put value of ' + key + '. code =' + (err as BusinessError).code +
          ', message =' + (err as BusinessError).message);
      }
    }
  }
  if (!dataPreferences) {
    getDataPreferences(context, updateStorageCallback);
  } else {
    updateStorageCallback(true);
  }
}

function saveStorage(context: common.UIAbilityContext): void {
  let saveStorageCallback = (result: boolean) => {
    if (result) {
      try {
        let promise = dataPreferences.flush();
        promise.then(() => {
          LogUtils.i(TAG, 'Succeeded in flushing.');
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'Failed to flush. code =' + err.code + ', message =' + err.message);
        })
      } catch (err) {
        LogUtils.e(TAG, 'Failed to flush. code =' + (err as BusinessError).code +
          ', message =' + (err as BusinessError).message);
      }
    } else {
    }
  }
  if (!dataPreferences) {
    getDataPreferences(context, saveStorageCallback);
  } else {
    saveStorageCallback(true);
  }
}