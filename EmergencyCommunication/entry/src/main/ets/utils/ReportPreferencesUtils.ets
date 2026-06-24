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

const TAG = 'ReportPreferencesUtils';

/**
 * UE report Preferences Utils
 */
export default class ReportPreferencesUtils {
  private static sInstance: ReportPreferencesUtils;
  private reportPreferences: dataPreferences.Preferences | null = null;
  /**
   * UE report Preferences database
   */
  private static readonly REPORT_PREFERENCE_NAME = 'report_preference_name';

  private constructor() {
  }

  public static getInstance() {
    if (!ReportPreferencesUtils.sInstance) {
      ReportPreferencesUtils.sInstance = new ReportPreferencesUtils();
    }
    return ReportPreferencesUtils.sInstance;
  }

  public isReportPreferencesExist() {
    return Boolean(this.reportPreferences);
  }

  public getSyncByPreferences(key: string, defValue: preferences.ValueType) {
    try {
      return this.reportPreferences?.getSync(key, defValue) || defValue;
    } catch (e) {
      LogUtils.e(TAG, `getSyncByPreferences error: ${JSON.stringify(e)}`);
      return defValue;
    }
  }

  private putSyncByPreferences = (key: string, value: dataPreferences.ValueType) => {
    try {
      this.reportPreferences?.putSync(key, value);
    } catch (e) {
      LogUtils.e(TAG, `putSyncByPreferences error: ${JSON.stringify(e)}`);
    }
  }

  public async putAndFlushInPreferences(key: string, value: dataPreferences.ValueType) {
    if (this.reportPreferences) {
      this.putSyncByPreferences(key, value);
      await this.flushReportPreferences();
    }
  }

  private deleteSyncByPreferences = (key: string) => {
    try {
      this.reportPreferences?.deleteSync(key);
    } catch (e) {
      LogUtils.e(TAG, `deleteSyncByPreferences error: ${JSON.stringify(e)}`);
    }
  }

  public async deleteAndFlushInPreferences(key: string) {
    if (this.reportPreferences) {
      this.deleteSyncByPreferences(key);
      await this.flushReportPreferences();
    }
  }

  private removeReportPreferencesFromCacheSync(context: Context) {
    LogUtils.i(TAG, 'removeReportPreferencesFromCacheSync');
    this.reportPreferences = null;
    try {
      dataPreferences.removePreferencesFromCacheSync(context,
        ReportPreferencesUtils.REPORT_PREFERENCE_NAME);
    } catch (e) {
      LogUtils.e(TAG, `removeReportPreferencesFromCacheSync error: ${JSON.stringify(e)}`)
    }
  }

  public async loadReportPreferences(context: common.Context, callback?: () => void) {
    LogUtils.i(TAG, 'loadReportPreferences');
    let options: dataPreferences.Options = {
      name: ReportPreferencesUtils.REPORT_PREFERENCE_NAME
    };
    if (this.reportPreferences) {
      this.removeReportPreferencesFromCacheSync(context);
    }
    try {
      await dataPreferences.getPreferences(context, options)
        .then((object: dataPreferences.Preferences) => {
          this.reportPreferences = object;
          LogUtils.i(TAG, 'Succeeded in getting preferences.');
          if (callback) {
            callback()
          }
        }).catch((err: BusinessError) => {
          this.reportPreferences = null;
          LogUtils.e(TAG, 'Failed to get preferences. code =' + err.code + ', message =' + err.message);
          if (callback) {
            callback()
          }
        });
    } catch (e) {
      this.reportPreferences = null;
      LogUtils.e(TAG, 'Failed to get preferences, error:' + JSON.stringify(e));
      if (callback) {
        callback()
      }
    }
  }

  private async flushReportPreferences() {
    if (!this.reportPreferences) {
      return;
    }

    try {
      await this.reportPreferences.flush().then(() => {
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