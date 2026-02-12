/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import preferences from '@ohos.data.preferences';
import LogUtils from '../utils/HiLog';
import common from '@ohos.app.ability.common';
import * as Constants from './RestoreConstants';

const TAG = 'PrefUtils';

class PrefUtils {
  private emInfoPref: preferences.Preferences | undefined = undefined;
  private contactsPref: preferences.Preferences | undefined = undefined;
  private restorePref: preferences.Preferences | undefined = undefined;

  /**
   * Init RestoreUtil with context object
   *
   * @param { Context } context - Indicates the context of application or capability.
   * @return { boolean } return init success or not
   */
  public async init(context: common.Context): Promise<boolean> {
    try {
      if (!context) {
        LogUtils.e(TAG, 'init context invalid');
        return false;
      }
      this.restorePref = await preferences.getPreferences(context, Constants.RESTORE_INFO_PREF_NAME);
      this.emInfoPref = await preferences.getPreferences(context, Constants.NEW_EM_INFO_PREF_NAME);
      this.contactsPref = await preferences.getPreferences(context, Constants.NEW_EM_CONTACTS_PREF_NAME);
    } catch (error) {
      LogUtils.e(TAG, `get mig status pref error code:${error?.code}`);
      return false;
    }
    return true;
  }

  private getPreferences(prefName: string): preferences.Preferences | undefined {
    switch (prefName) {
      case Constants.NEW_EM_INFO_PREF_NAME:
        return this.emInfoPref;
      case Constants.NEW_EM_CONTACTS_PREF_NAME:
        return this.contactsPref;
      case Constants.RESTORE_INFO_PREF_NAME:
        return this.restorePref;
      default:
        return undefined;
    }
  }

  public async getStatus(key: string, defStatus: preferences.ValueType): Promise<preferences.ValueType | undefined> {
    if (!key || '' === key) {
      LogUtils.e(TAG, `getStatus key invalid`);
      return undefined;
    }
    if (!this.restorePref) {
      LogUtils.e(TAG, `getStatus cannot get pref for key:${key}`);
      return undefined;
    }
    try {
      let currentStatus = await this.restorePref.get(key, defStatus);
      LogUtils.i(TAG, `getStatus return key:${key} status:${currentStatus}`);
      return currentStatus;
    } catch (err) {
      LogUtils.e(TAG, `getStatus err:${JSON.stringify(err)}`);
      return defStatus;
    }
  }

  public async saveToPref(key: string, value: preferences.ValueType, prefName?: string): Promise<void> {
    LogUtils.d(TAG, `save to pref key:${key} value Len:${JSON.stringify(value)?.length} pref:${prefName}`);
    if (!key || value === null || value === undefined) {
      LogUtils.e(TAG, `saveToPref error invalid params`);
      return;
    }
    let preferences = this.getPreferences(prefName ?? Constants.RESTORE_INFO_PREF_NAME);
    if (!preferences) {
      LogUtils.e(TAG, `save to pref error cannot get pref`);
      return;
    }
    try {
      await preferences.put(key, value);
      await preferences.flush();
    } catch (err) {
      LogUtils.e(TAG, `saveToPref err:${JSON.stringify(err)}`);
    }
  }

  public async saveParsedOldInfoToPref(key: string, value: preferences.ValueType) {
    switch (key) {
      case Constants.OLD_EM_CONTACTS_KEY:
        // when save old emergency contact uri list, save to old pref first, wait query number and name from database
        await this.saveToPref(key, value);
        break;
      default:
        await this.saveToPref(key, value, Constants.NEW_EM_INFO_PREF_NAME);
        break;
    }
  }

  public async getOldEmContactsUriList(): Promise<string> {
    if (this.restorePref) {
      try {
        return await this.restorePref.get(Constants.OLD_EM_CONTACTS_KEY, '') as string;
      } catch (err) {
        LogUtils.e(TAG, `getOldEmContactsUriList err:${JSON.stringify(err)}`);
      }
    }
    LogUtils.i(TAG, 'getOldEmContacts pref invalid');
    return '';
  }
}

export const prefUtils: PrefUtils = new PrefUtils();
