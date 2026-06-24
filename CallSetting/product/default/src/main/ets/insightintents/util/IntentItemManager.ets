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

import { LogUtils } from '@ohos/common/CommonIndex';
import { StringUtil } from '../../common/utils/StringUtil';
import { SettingItemProperty } from '../model/SettingItemProperty';

const SETTINGS_CONFIG_FILE = 'settings_item_config.json';
const TAG = 'IntentItemManager';

/**
 * 预设设置项属性值解析
 *
 * @since 2024-05-29
 */
export class IntentItemManager {
  private static itemInfoCache: Map<string, SettingItemProperty> = new Map();

  /**
   * Obtains a specified SETTING_CONFIG_FILE JSON file object.
   */
  private static async getSettingItemsConfig(): Promise<void> {
    LogUtils.i(TAG, 'getSettingItemsConfig');
    let context = AppStorage.get<Context>('pageContext');
    if (!context) {
      LogUtils.e(TAG, 'getSettingItemsConfig context is undefined');
      return;
    }
    let rawContent: string = await StringUtil.getStringByFileAsync(context.resourceManager, SETTINGS_CONFIG_FILE);
    LogUtils.i(TAG, 'rawContent is : ' + rawContent);
    if (rawContent) {
      let items: SettingItemProperty[] = JSON.parse(rawContent) as Array<SettingItemProperty>;
      items.forEach(item => IntentItemManager.itemInfoCache.set(item.itemName, item));
      return;
    }
    LogUtils.w(TAG, 'SettingItemPropertys is empty');
    return;
  }

  /**
   * Obtains a specified setting item object.
   *
   * @param itemName item name
   */
  public static async getItem(itemName: string): Promise<SettingItemProperty> {
    LogUtils.i(TAG, 'getItem');
    if (IntentItemManager.itemInfoCache.has(itemName)) {
      return IntentItemManager.itemInfoCache.get(itemName) as SettingItemProperty;
    }
    let settingItemProperty: SettingItemProperty | undefined;
    try {
      await IntentItemManager.getSettingItemsConfig();
      settingItemProperty = IntentItemManager.itemInfoCache.get(itemName) as SettingItemProperty;
    } catch (e) {
      LogUtils.e(TAG, `cannot find itemName: ${itemName} in settings_item_config`);
      return Promise.reject()
    }
    return settingItemProperty;
  }
}

