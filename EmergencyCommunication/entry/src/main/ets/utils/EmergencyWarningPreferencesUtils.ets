/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import LogUtils from './HiLog';
import { BusinessError } from '@ohos.base';
import preferences from '@ohos.data.preferences';

const TAG = 'EmergencyWarningPreferencesUtils';

export default class EmergencyWarningPreferencesUtils {
  private static sInstance: EmergencyWarningPreferencesUtils;
  private emergencyWarningInfoPreferences: dataPreferences.Preferences | null = null;
  private static readonly EMERGENCY_WARNING_INFO_PREFERENCES_NAME = 'emergency_warning_info_preference_name';

  private constructor() {
  }

  static getInstance() {
    if (!EmergencyWarningPreferencesUtils.sInstance) {
      EmergencyWarningPreferencesUtils.sInstance = new EmergencyWarningPreferencesUtils();
    }
    return EmergencyWarningPreferencesUtils.sInstance;
  }

  isEmergencyWarningInfoPreferencesExist() {
    return Boolean(this.emergencyWarningInfoPreferences);
  }

  getSyncByPreferences(key: string, defValue: preferences.ValueType) {
    return this.emergencyWarningInfoPreferences?.getSync(key, defValue) || defValue;
  }

  async putAndFlushInPreferences(key: string, value: dataPreferences.ValueType) {
    if (this.emergencyWarningInfoPreferences) {
      this.emergencyWarningInfoPreferences.putSync(key, value);
      await this.flushEmergencyWarningInfoPreferences();
    }
  }

  async deleteAndFlushInPreferences(key: string) {
    if (this.emergencyWarningInfoPreferences) {
      this.emergencyWarningInfoPreferences.deleteSync(key);
      await this.flushEmergencyWarningInfoPreferences();
    }
  }

  private removeEmergencyWarningInfoPreferencesFromCacheSync(context: Context) {
    LogUtils.i(TAG, 'removeEmergencyWarningInfoPreferencesFromCacheSync');
    this.emergencyWarningInfoPreferences = null;
    try {
      dataPreferences.removePreferencesFromCacheSync(context,
        EmergencyWarningPreferencesUtils.EMERGENCY_WARNING_INFO_PREFERENCES_NAME);
    } catch (e) {
      LogUtils.e(TAG, `removeEmergencyWarningInfoPreferencesFromCacheSync error: ${JSON.stringify(e)}`)
    }
  }

  async loadEmergencyWarningInfoPreferences(context: common.Context, callback?: () => void) {
    let options: dataPreferences.Options = {
      name: EmergencyWarningPreferencesUtils.EMERGENCY_WARNING_INFO_PREFERENCES_NAME
    };
    if (this.emergencyWarningInfoPreferences) {
      this.removeEmergencyWarningInfoPreferencesFromCacheSync(context);
    }
    try {
      await dataPreferences.getPreferences(context, options)
        .then((object: dataPreferences.Preferences) => {
          this.emergencyWarningInfoPreferences = object;
          LogUtils.i(TAG, 'Succeeded in getting preferences.');
          if (callback) {
            callback()
          }
        }).catch((err: BusinessError) => {
          this.emergencyWarningInfoPreferences = null;
          LogUtils.e(TAG, 'Failed to get preferences. code =' + err.code + ', message =' + err.message);
          if (callback) {
            callback()
          }
        });
    } catch (e) {
      this.emergencyWarningInfoPreferences = null;
      LogUtils.e(TAG, 'Failed to get preferences, error:' + JSON.stringify(e));
      if (callback) {
        callback()
      }
    }
  }

  private async flushEmergencyWarningInfoPreferences() {
    if (!this.emergencyWarningInfoPreferences) {
      return;
    }

    try {
      await this.emergencyWarningInfoPreferences.flush().then(() => {
        LogUtils.i(TAG, 'Succeeded in flushing.');
      }).catch((err: BusinessError) => {
        let code = (err as BusinessError).code;
        let message = (err as BusinessError).message;
        LogUtils.e(TAG, `Failed to flush. Code:${code}, message:${message}`);
      })
    } catch (err) {
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      LogUtils.e(TAG, `Failed to flush. Code:${code}, message:${message}`);
    }
  }
}