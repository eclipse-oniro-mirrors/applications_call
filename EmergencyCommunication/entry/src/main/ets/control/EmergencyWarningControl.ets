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
import LogUtils from '../utils/HiLog';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import { ConfigStruct } from '../utils/ClassStruct';
import HashMap from '@ohos.util.HashMap';
import { Utils } from '../utils/Utils';
import { notificationManager } from '@kit.NotificationKit';

const TAG = 'EmergencyWarningController';

export default class EmergencyWarningController {
  private static sInstance: EmergencyWarningController;
  public mapName2Value: HashMap<string, string> = new HashMap<string, string>();
  public static readonly IGNORE_LOCATION_SWITCH_KEY = 'EmergencyWarning_isOpenedLocationSwitch';

  private constructor() {
  }

  static getInstance() {
    if (!EmergencyWarningController.sInstance) {
      EmergencyWarningController.sInstance = new EmergencyWarningController();
    }
    return EmergencyWarningController.sInstance;
  }

  public async readValueFromConfigJSON(context: common.Context) {
    if (!context) {
      return;
    }
    let tempMapName2Value: HashMap<string, string> = new HashMap<string, string>();
    try {
      let value = await context?.resourceManager.getRawFileContent(
        'config.json'
      ).catch((e: BusinessError) => {
        LogUtils.e(TAG, `readValueFromConfigJSON failed, error: ${e.code}`);
      });
      let configList: ConfigStruct[] = value ? JSON.parse(String.fromCharCode(...Array.from(value))).config : [];
      if (configList.length > 0) {
        configList.forEach((v) => {
          tempMapName2Value.set(v.name, v.value);
        })
        this.mapName2Value.setAll(tempMapName2Value);
      }
    } catch (e) {
      LogUtils.e(TAG, `readValueFromConfigJSON failed, error:${e.code}`);
    }
  }

  /**
   * apply for Denied Location Permission
   * @param listOfNeedPermission list Of Denied Location Permission
   * @returns authResults  The value 0 indicates that a permission is granted, and the value -1 indicates not,
   * value 2 indicates abnormality.
   */
  static async requestDeniedLocationPermissions(listOfNeedPermission: Permissions[], contextParam: Context) {
    let atManager = abilityAccessCtrl.createAtManager();
    let context = contextParam || Utils.getEmergencyWarningCurrentLoadFilesContext();
    if (!context) {
      return;
    }
    try {
      let data: PermissionRequestResult | void = await atManager.requestPermissionsFromUser(context,
        listOfNeedPermission).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'requestPermissionsFromUser failed errCode:' + err.code + ',errMessage:' + err.message);
      })
      return data ? [...data.authResults] : [];
    } catch (err) {
      LogUtils.e(TAG, 'requestPermissionsFromUser failed errCode:' + err.code + ',errMessage:' + err.message);
      return;
    }
  }

  public static isNotificationEnabled = async () => {
    try {
      const result = await notificationManager.isNotificationEnabled().then((data: boolean) => {
        return data;
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `isNotificationEnabled fail: ${err.code}`);
        return false;
      });
      return result;
    } catch (e) {
      LogUtils.e(TAG, `isNotificationEnabled fail: ${e.code}`);
      return false;
    }
  }
  /**
   * @param context
   * @param epicenter
   * @param magnitude magnitude of earthquake
   * @param deviceAddress
   * @param feeling earthquake sensation
   * @returns
   */
  public static getEarthquakeWarningNotificationText = (context: Context, epicenter: string, magnitude: string,
    deviceAddress: string, feeling: Resource) => {
    try {
      if (deviceAddress) {
        return context.resourceManager.getStringSync(
          $r('app.string.emergencyInfromationText').id,
          epicenter,
          magnitude,
          deviceAddress,
          context.resourceManager.getStringSync(feeling.id));
      } else {
        return context.resourceManager.getStringSync(
          $r('app.string.earthquake_warning_notification_text_without_device_address').id,
          epicenter,
          magnitude,
          context.resourceManager.getStringSync(feeling.id));
      }
    } catch (e) {
      LogUtils.e(TAG, `getEarthquakeWarningNotificationText error: ${e.code}`);
      return '';
    }
  }

  public getValueFromConfigMap(key: string) {
    return this.mapName2Value.get(key);
  }
}