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
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import LogUtils from '../utils/HiLog';

const TAG: string = 'PreferencesListenerUtil';

export class PreferencesListenerUtil {
  private static preferencesListenerUtil: PreferencesListenerUtil;
  private EVENT_NAME: string = 'event.custom.emergencycommunication.EMERGENCY_INFO_CHANGE';
  private PERMISSIONS: string[] = ['ohos.permission.GET_TELEPHONY_STATE'];
  private EMERGENCY_INFO_PREFERENCES_NAME = 'emergency_info_preference_name';
  private prefEmergencyInfoHelper: preferences.Preferences | null = null;

  public static getInstance(): PreferencesListenerUtil {
    if (!PreferencesListenerUtil.preferencesListenerUtil) {
      PreferencesListenerUtil.preferencesListenerUtil = new PreferencesListenerUtil();
    }
    return PreferencesListenerUtil.preferencesListenerUtil;
  }

  /**
   * 订阅首选项数据变更
   * @param context {Context}
   * @returns {Promise<void>}
   */
  public async startPreferenceListener(context: Context): Promise<void> {
    LogUtils.i(TAG, 'startPreferenceListener start');
    try {
      this.prefEmergencyInfoHelper = await preferences.getPreferences(context, this.EMERGENCY_INFO_PREFERENCES_NAME);
      // 添加紧急信息监听器
      this.prefEmergencyInfoHelper.on('change', this.onChange);
    } catch (err) {
      const error = err as BusinessError;
      LogUtils.e(TAG, `startPreferenceListener error code: ${error.code}, message: ${error.message}`);
    }
  }

  /**
   * 取消订阅首选项数据变更
   */
  public processPreferenceListener(): void {
    this.prefEmergencyInfoHelper?.off('change');
  }

  // 定义监听器回调
  private onChange = (key: string): void => {
    LogUtils.i(TAG, `The key: ${key} changed`);
    // 发送广播
    this.sendPublicEvent();
  }

  // 定义广播发送函数
  public sendPublicEvent(): void {
    LogUtils.i(TAG, 'sendPublicEvent start');
    commonEventManager.publish(this.EVENT_NAME, { subscriberPermissions: this.PERMISSIONS }, (err: BusinessError) => {
      if (err) {
        LogUtils.e(TAG, `Publish event fail, code: ${err.code}, message: ${err.message}.`);
        return;
      }
      LogUtils.i(TAG, 'Publish broadcast success.');
    })
  }
}