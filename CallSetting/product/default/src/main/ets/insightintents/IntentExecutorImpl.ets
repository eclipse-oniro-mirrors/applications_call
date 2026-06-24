/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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

import { InsightIntentExecutor, insightIntent, UIExtensionContentSession } from '@kit.AbilityKit';
import { LogUtils } from '@ohos/common/CommonIndex';
import { IntentItemManager } from './util/IntentItemManager';
import { SettingItemProperty } from './model/SettingItemProperty';
import { ERROR_MSG, IntentCodeConstants } from './constant/IntentCodeConstant';
import { IntentType } from './constant/IntentConstant';
import { StringUtil } from '../common/utils/StringUtil';
import { IntentCheckAdaptor } from './adapter/IntentCheckAdaptor';
import { IntentSwitchAdaptor } from './adapter/IntentSwitchAdaptor';
import { IntentCustomAdaptor } from './adapter/IntentCustomAdapter';

const TAG = 'IntentExecutorImpl';
const DEFAULT_INTENT_COMPONENT: string = 'pages/DefaultIntentComponent';
const WINDOW_BACKGROUND_COLOR: string = '#00ffffff';

export interface UIExtensionStorage {
  uiExtensionSession: UIExtensionContentSession
}

/**
 * Insight Intent Execution Entry
 *
 * @since 2024-05-29
 */
export default class IntentExecutorImpl extends InsightIntentExecutor {
  private static readonly CUSTOM_INTENT_NAME_MAP: Set<string> = new Set([
    IntentType.CHECK_DATA_ROAMING_SWITCH,
    IntentType.GET_DATA_ROAMING_SWITCH,
    IntentType.SET_DATA_ROAMING_SWITCH
  ]);

  private static readonly IMS_INTENT_NAME_MAP: Set<string> = new Set([
    IntentType.CHECK_IMS_SWITCH,
    IntentType.GET_IMS_SWITCH,
    IntentType.SET_IMS_SWITCH
  ]);

  /**
   * The intent framework invokes the UIExtensionAbility callback method.
   */
  onExecuteInUIExtensionAbility(intentName: string, intentParam: Record<string, Object>,
    pageLoader: UIExtensionContentSession):
  insightIntent.ExecuteResult | Promise<insightIntent.ExecuteResult> {
    let itemName: string = String(intentParam.itemName).toLowerCase();
    LogUtils.i(TAG, `onExecuteInUIExtensionAbility :: itemName is ${itemName}`)
    return new Promise((resolve, reject) => {
      IntentItemManager.getItem(itemName).then(async (item: SettingItemProperty) => {
        LogUtils.i(TAG, `item is ${item.itemName}`);
        AppStorage.setOrCreate<SettingItemProperty>('intentItem', item);
        let dataState = await IntentSwitchAdaptor.getSwitchStatus(itemName);
        LogUtils.i(TAG, `onExecuteInUIExtensionAbility :: ${itemName} state is : ${dataState}`)
        AppStorage.setOrCreate<boolean>(itemName, dataState);
        let localStorage: LocalStorage = new LocalStorage({
          uiExtensionSession: pageLoader
        } as UIExtensionStorage);
        pageLoader.loadContent(DEFAULT_INTENT_COMPONENT, localStorage);
        pageLoader.setWindowBackgroundColor(WINDOW_BACKGROUND_COLOR);
        let defaultRsp: insightIntent.ExecuteResult = {
          code: IntentCodeConstants.DEFAULT_CODE_SUCCESS
        }
        resolve(defaultRsp);
      }).catch(() => {
        LogUtils.e(TAG, 'catch error');
        let defaultRsp: insightIntent.ExecuteResult = {
          code: IntentCodeConstants.DEFAULT_CODE_FAILED,
        }
        resolve(defaultRsp);
      });
    });
  }

  /**
   * Intention Framework Startup Background Ability Callback
   */
  async onExecuteInUIAbilityBackgroundMode(intentName: string,
    intentParam: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `backgroundMode intentName is ${intentName}, intentParam is ${JSON.stringify(intentParam)}`);
    let rsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        'errMsg': ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED],
      }
    };
    try {
      // The intentParam of the customized intention does not contain itemName and is processed separately.
      if (IntentExecutorImpl.CUSTOM_INTENT_NAME_MAP.has(intentName)) {
        rsp = await this.executeCustomIntent(intentName, intentParam);
        return rsp;
      }
      if (IntentExecutorImpl.IMS_INTENT_NAME_MAP.has(intentName)) {
        rsp = await this.executeImsIntent(intentName, intentParam);
        return rsp;
      }
      let itemName: string = String(intentParam.itemName).toLowerCase();
      let item: SettingItemProperty | null = null;
      try {
        item = await IntentItemManager.getItem(itemName);
      } catch (e) {
        LogUtils.e(TAG, `backgroundMode unsupport intent itemName: ${itemName}`);
        if (intentName === IntentType.CHECK_SETTING_ITEM) {
          rsp = {
            code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
            result: {
              'itemName': intentParam.itemName,
              'appBundleName': intentParam.appBundleName,
              'isSupport:': false
            }
          }
        }
        return rsp;
      }
      rsp = await this.executeBackgroundIntent(item, intentName, itemName, intentParam);
    } catch (error) {
      LogUtils.e(TAG, 'execute intent failed');
    }
    return rsp;
  }

  private async executeCustomIntent(intentName: string, intentParam: Record<string, Object>) {
    let rsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        'errMsg': ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED],
      }
    };
    let appBundleName: string = this.getAppBundleName(intentParam);
    LogUtils.i(TAG, `executeCustomIntent, intentName: ${intentName},appBundleName: ${appBundleName}`);
    let slotId: number = Number(intentParam.slotId);
    rsp = await IntentCustomAdaptor.checkDateRoamingSwitch(slotId);
    if (!this.isSupport(rsp)) {
      LogUtils.e(TAG, 'executeCustomIntent :: checkDateRoamingSwitch is unSupported');
      return rsp;
    }
    switch (intentName) {
      case IntentType.GET_DATA_ROAMING_SWITCH:
        rsp = await IntentCustomAdaptor.getDataRoamingSwitch(slotId);
        break;
      case IntentType.SET_DATA_ROAMING_SWITCH:
        let switchFlag: number = Number(intentParam.switchFlag);
        rsp = await IntentCustomAdaptor.setDataRoamingSwitch(slotId, switchFlag);
        break;
      case IntentType.CHECK_DATA_ROAMING_SWITCH:
        break;
      default:
        LogUtils.e(TAG, 'unSupport intent');
        break;
    }
    return rsp;
  }

  private async executeImsIntent(intentName: string, intentParam: Record<string, Object>) {
    let rsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        'errMsg': ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED],
      }
    };
    let slotId: number = Number(intentParam.slotId);
    rsp = await IntentCustomAdaptor.checkImsSupport(slotId);
    if (!this.isSupport(rsp)) {
      LogUtils.e(TAG, 'executeImsIntent :: checkImsSupport is unSupported');
      return rsp;
    }
    switch (intentName) {
      case IntentType.GET_IMS_SWITCH:
        rsp = IntentCustomAdaptor.getImsSwitch(slotId);
        break;
      case IntentType.SET_IMS_SWITCH:
        let switchFlag: number = Number(intentParam.switchFlag);
        rsp = IntentCustomAdaptor.setImsSwitch(slotId, switchFlag);
        break;
      default:
        break;
    }
    return rsp;
  }

  private async executeBackgroundIntent(item: SettingItemProperty, intentName: string, itemName: string,
    intentParam: Record<string, Object>) {
    let rsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        'errMsg': ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED],
      }
    };
    if (intentName === IntentType.CHECK_SETTING_PAGE) {
      let entryKey: string = String(intentParam.entryKey);
      let appBundleName: string = String(intentParam.appBundleName);
      return IntentCheckAdaptor.checkSettingPage(entryKey, appBundleName);
    }
    AppStorage.setOrCreate<SettingItemProperty>('intentItem', item);
    let appBundleName: string = this.getAppBundleName(intentParam);
    LogUtils.i(TAG, `executeBackgroundIntent, itemName: ${itemName}, intentName: ${intentName},
      appBundleName: ${appBundleName}`);
    rsp = await IntentCheckAdaptor.checkSettingItem(itemName, appBundleName);
    if (!this.isSupport(rsp)) {
      LogUtils.e(TAG, `executeBackgroundIntent :: checkSettingItem ${itemName} is unSupported`);
      return rsp;
    }
    switch (intentName) {
      case IntentType.GET_SETTING_SWITCH:
        rsp = await IntentSwitchAdaptor.getSettingSwitch(itemName, appBundleName);
        break;
      case IntentType.SET_SETTING_SWITCH:
        let switchFlag: number = Number(intentParam.switchFlag);
        rsp = await IntentSwitchAdaptor.setSettingSwitch(itemName, appBundleName, switchFlag);
        break;
      case IntentType.CHECK_SETTING_ITEM:
        break;
      default:
        LogUtils.e(TAG, 'unSupport intent');
        break;
    }
    return rsp;
  }

  private isSupport(rsp: insightIntent.ExecuteResult): boolean {
    return (rsp && rsp.code === 0 && rsp.result?.isSupport) as boolean;
  }

  private getAppBundleName(intentParam: Record<string, Object>) {
    let appBundleName: string = String(intentParam.appBundleName);
    if (StringUtil.isEmpty(appBundleName)) {
      AppStorage.setOrCreate('appBundleName', null);
    } else {
      AppStorage.setOrCreate('appBundleName', appBundleName);
    }
    return appBundleName;
  }
}