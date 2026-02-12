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
import { common, Want } from '@kit.AbilityKit';
import { rpc } from '@kit.IPCKit';
import { LogUtil } from './LogUtil';
import { JSON } from '@kit.ArkTS';
import { Callback } from '@ohos.base';

interface EnableObject {
  /**
   * 方法方法说明:enableSearchItems:使能搜索项;disableSearchItems:去使能搜索项
   */
  method: string,
  extra: object
}

interface SearchItems {
  itemList: string[]; // 配置搜索项name，同seachpage.json中的itemName
}

const TAG = 'SettingsSearchUtils';

export default class SettingsSearchUtils {
  /**
   * 动态使能“更多流量设置”、“套餐设置”搜索项
   *
   * @param context - 上下文
   * @param isEnabled - 是否使能
   * @param callback - 结果回调
   */
  public static enableMoreAndPackageSettings(context: common.UIExtensionContext | common.ServiceExtensionContext,
    isEnabled: boolean, callback?: Callback<boolean>) {
    SettingsSearchUtils.enableSearchItems(context, isEnabled, ['more_data_usage_settings_title', 'data_plan_settings'],
      callback);
  }

  /**
   * 动态使能“更多流量设置”、“套餐设置”、“限额提醒”搜索项
   *
   * @param context - 上下文
   * @param isEnabled - 是否使能
   * @param callback - 结果回调
   */
  public static enableAllItemsInMoreSettings(context: common.UIExtensionContext | common.ServiceExtensionContext,
    isEnabled: boolean, callback?: Callback<boolean>) {
    SettingsSearchUtils.enableSearchItems(context, isEnabled,
      ['more_data_usage_settings_title', 'data_plan_settings', 'usage_reminders'], callback);
  }

  /**
   * 动态使能“限额提醒”搜索项
   *
   * @param context - 上下文
   * @param isEnabled - 是否使能
   * @param callback - 结果回调
   */
  public static enableLimitReminder(context: common.UIExtensionContext | common.ServiceExtensionContext,
    isEnabled: boolean, callback?: Callback<boolean>) {
    SettingsSearchUtils.enableSearchItems(context, isEnabled, ['usage_reminders'], callback);
  }

  private static async enableSearchItems(context: common.UIExtensionContext | common.ServiceExtensionContext,
    isEnabled: boolean, itemList: string[], callback?: Callback<boolean>) {
    if (context === null || context === undefined) {
      callback?.(false);
      LogUtil.error(TAG, `enableSearchItems context is null`);
      return;
    }
    let connectionId: number = -1;
    let want: Want = {
      bundleName: 'com.ohos.settings',
      abilityName: 'SettingsExtService'
    };
    let options: common.ConnectOptions = {
      onConnect(elementName, remote: rpc.IRemoteObject) {
        if (remote === null) {
          LogUtil.error(TAG, `enableSearchItems onConnect remote is null`);
          context.disconnectServiceExtensionAbility(connectionId);
          callback?.(false);
          return;
        }
        let option: rpc.MessageOption = new rpc.MessageOption();
        let dataSequence = rpc.MessageSequence.create();
        let replySequence = rpc.MessageSequence.create();
        let enableItems: SearchItems = {
          itemList: itemList
        }
        let enableObj: EnableObject = {
          method: isEnabled ? 'enableSearchItems' : 'disableSearchItems',
          extra: enableItems
        }
        enableObj.extra = enableItems;
        dataSequence.writeString(JSON.stringify(enableObj));
        try {
          remote.sendMessageRequest(2, dataSequence, replySequence, option).then((result) => {
            LogUtil.info(TAG, `enableSearchItems result = ` + result.code);
            callback?.(true);
          });
        } catch (err) {
          LogUtil.info(TAG, `enableSearchItems failed`);
          callback?.(false);
        } finally {
          dataSequence.reclaim();
          replySequence.reclaim();
          context.disconnectServiceExtensionAbility(connectionId);
        }
      },
      onDisconnect(elementName) {
        LogUtil.info(TAG, `enableSearchItems onDisconnect`);
      },
      onFailed(code) {
        LogUtil.info(TAG, `enableSearchItems onFailed` + code);
      }
    }
    connectionId = context.connectServiceExtensionAbility(want, options);
  }
}

