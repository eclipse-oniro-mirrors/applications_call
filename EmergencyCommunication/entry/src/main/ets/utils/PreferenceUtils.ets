/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import LogUtils from './HiLog';
import data_preferences from '@ohos.data.preferences';

const TAG = 'PreferenceUtils';
const NAME: string = 'EarthquakeStore';

export default class PreferenceUtils {
  private static sInstance: PreferenceUtils;
  private mPreferences?: data_preferences.Preferences | undefined;


  private constructor(context: Context) {
    this.init(context);
  }

  /*
   * init if Call From serviceAbility context is Null
   *@param ctx Context used for dataShare
   */
  init(context: Context) {
    if (!context) {
      LogUtils.e(TAG, 'init params invalid');
      return;
    }
    this.mPreferences = this.getPreferences(context);
    LogUtils.i(TAG, 'SharedPreferencesUtils init');
  }

  static getInstance(context: Context) {
    if (!PreferenceUtils.sInstance) {
      PreferenceUtils.sInstance = new PreferenceUtils(context);
    }
    return PreferenceUtils.sInstance;
  }

  /**
   * saveToPreferences
   *
   * @param key save to Preferences
   * @param value save to Preferences
   */
  public saveToPreferences(key: string, value: data_preferences.ValueType, context: Context) {
    if (!key || !value || !context) {
      LogUtils.e(TAG, 'saveToPreferences params invalid');
      return;
    }

    let preferences: data_preferences.Preferences | undefined = this.getPreferences(context);
    if (preferences === undefined) {
      return;
    }
    try {
      preferences.putSync(key, value);
      preferences.flush();
      LogUtils.i(TAG, `saveToPreferences put success key: ${key}`);
    } catch (err) {
      LogUtils.e(TAG, `saveToPreferences failed, code = ${err?.code}, message = ${err?.message}`);
    }
  }

  public deletePreferences(key: string, context: Context) {
    LogUtils.i(TAG, 'deletePreferences start');
    if (!key || !context) {
      LogUtils.e(TAG, 'deletePreferences params invalid');
      return;
    }

    try {
      let preferences = this.getPreferencesNoCache(context);
      preferences?.deleteSync(key);
      preferences?.flush();
      LogUtils.i(TAG, 'deletePreferences success');
    } catch (err) {
      LogUtils.e(TAG, `deletePreferences failed, code = ${err?.code}, message = ${err?.message}`);
    }
  }

  /**
   * getFromPreferences
   *
   * @param key to be get
   * @param defValue get default to Preferences
   * @return the value get from Preferences
   */
  public getFromPreferences(key: string, defValue: data_preferences.ValueType,
    context: Context): data_preferences.ValueType {
    if (!key || !context) {
      LogUtils.e(TAG, 'getFromPreferences params invalid');
      return [];
    }
    let preferences: data_preferences.Preferences | undefined = this.getPreferences(context);
    if (preferences === undefined) {
      return [];
    }
    let value: data_preferences.ValueType = defValue;
    try {
      value = preferences.getSync(key, defValue);
    } catch (err) {
      LogUtils.e(TAG, `Failed to get value, code = ${err?.code}, message = ${err?.message}`);
    }
    return value;
  }

  private getPreferences(context: Context): data_preferences.Preferences | undefined {
    if (!context) {
      LogUtils.e(TAG, 'getPreferences params invalid');
      return undefined;
    }
    try {
      let preferences = this.getPreferencesSync(context);
      return preferences;
    } catch (err) {
      LogUtils.e(TAG, `getPreferencesSync failed, code = ${err?.code}, message = ${err?.message}`);
    }
    return undefined;
  }

  private getPreferencesSync(context: Context): data_preferences.Preferences | undefined {
    if (!context) {
      LogUtils.e(TAG, 'getPreferencesSync params invalid');
      return undefined;
    }
    if (this.mPreferences === undefined || this.mPreferences === null) {
      let preferences: data_preferences.Preferences = data_preferences.getPreferencesSync(context, { name: NAME });
      this.mPreferences = preferences;
    }
    let preferences = this.mPreferences;
    return preferences;
  }

  private getPreferencesNoCache(context: Context): data_preferences.Preferences | undefined {
    if (!context) {
      LogUtils.e(TAG, 'getPreferencesNoCache params invalid');
      return undefined;
    }
    let preferences: data_preferences.Preferences = data_preferences.getPreferencesSync(context, { name: NAME });
    this.mPreferences = preferences;
    return preferences;
  }
}