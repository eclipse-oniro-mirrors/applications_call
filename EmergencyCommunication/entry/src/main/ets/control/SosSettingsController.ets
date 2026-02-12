/**
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
import { HashMap } from '@kit.ArkTS';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { PermissionsUtils } from '../utils/PermissionsUtils';
import LogUtils from '../utils/HiLog';
import EmergencyWarningController from './EmergencyWarningControl';
import Prompt from '@ohos.promptAction';
import { SosEmergencyHelpSettings } from '../pages/SosEmergencyHelpSettings';
import { common, UIExtensionContentSession } from '@kit.AbilityKit';
import LooseObject from '../data/LooseObject';
import { CanAddOrEditEmergencyInfo } from '../utils/EmergencyInfoUtil';
import { CAR_ACCIDENT, FALL_DOWN } from '../utils/Constants';
import { WrappedEmergencyContactsInfo } from '../pages/WrappedEmergencyContactsInfo';


const TAG = 'SosSettingsController';

export class SosSettingsController {
  private static sInstance: SosSettingsController;

  constructor() {
  }

  static getInstance() {
    if (SosSettingsController.sInstance == null) {
      SosSettingsController.sInstance = new SosSettingsController();
    }
    return SosSettingsController.sInstance;
  }

  public async checkAutoSendSOSMessagePermission(): Promise<boolean> {
    const mapPermissionsToGrantStatus: HashMap<Permissions, abilityAccessCtrl.GrantStatus> =
      await PermissionsUtils.checkPermissionOfSOSAutoSendSMS();
    if (!mapPermissionsToGrantStatus.isEmpty()) {
      let listOfNeedPermission: Permissions[] = [];
      for (const entry of mapPermissionsToGrantStatus.entries()) {
        if (entry[0] && entry[1] === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
          listOfNeedPermission.push(entry[0]);
        }
      }
      if (listOfNeedPermission.length === 0) {
        return true;
      } else {
        LogUtils.i(TAG, `check PERMISSION_DENIED ${listOfNeedPermission}`);
        const authResults = await EmergencyWarningController.requestDeniedLocationPermissions(listOfNeedPermission,
          getContext());
        if (!authResults || authResults.length === 0) {
          return false;
        }
        if (authResults.every((v) => (v === 0))) {
          return true;
        } else {
          Prompt.showToast({
            message: $r('app.string.sos_permissions_tips_of_auto_send_sms'),
            duration: 5000,
            bottom: 80
          });
          return false;
        }
      }
    } else {
      return false;
    }
  }

  public async checkPersonalSafetyOpenPermission(): Promise<boolean> {
    const mapPermissionsToGrantStatus: HashMap<Permissions, abilityAccessCtrl.GrantStatus> =
      await PermissionsUtils.checkPermissionOfPersonalSafetyAutoCallAndSendSMS();
    if (!mapPermissionsToGrantStatus.isEmpty()) {
      let listOfNeedPermission: Permissions[] = [];
      for (const entry of mapPermissionsToGrantStatus.entries()) {
        if (entry[0] && entry[1] === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
          listOfNeedPermission.push(entry[0]);
        }
      }
      if (listOfNeedPermission.length === 0) {
        return true;
      } else {
        LogUtils.i(TAG, `check PERMISSION_DENIED ${listOfNeedPermission}`);
        const authResults = await EmergencyWarningController.requestDeniedLocationPermissions(listOfNeedPermission,
          getContext());
        if (!authResults || authResults.length === 0) {
          return false;
        }
        if (authResults.every((v) => (v === 0))) {
          return true;
        } else {
          Prompt.showToast({
            message: $r('app.string.sos_permissions_tips_of_auto_send_sms'),
            duration: 5000,
            bottom: 80
          });
          return false;
        }
      }
    } else {
      return false;
    }
  }

  public static getNoSOSContactsDialogPrimaryTitle(autoSendSOSMessageSwitchState: boolean,
    autoAutoDialSOSNumberSwitchState: boolean,
    type: 'autoSendSMS' | 'autoDialNumber' | 'carAccident' | 'fallDown' | 'inherit', oldTitle: Resource | null) {
    if (type === 'inherit') {
      return oldTitle || $r('app.string.unable_auto_dial_and_send_sms_dialog_title');
    }

    let title: Resource | null = null;
    if (autoSendSOSMessageSwitchState === false && autoAutoDialSOSNumberSwitchState === false) {
      switch (type) {
        case 'autoSendSMS':
          title = $r('app.string.unable_send_help_info');
          break;
        case 'autoDialNumber':
          title = $r('app.string.unable_auto_dial_dialog_title');
          break;
        case CAR_ACCIDENT:
          title = $r('app.string.cannot_enable_car_accident_sos');
          break;
        case FALL_DOWN:
          title = $r('app.string.cannot_enable_fall_down_sos');
          break;
        default:
          title = $r('app.string.unable_auto_dial_and_send_sms_dialog_title');
      }
    } else {
      title = $r('app.string.unable_auto_dial_and_send_sms_dialog_title');
    }
    return title;
  }

  public handleJumpToSosSettingsPage(previousPage: string, pathInfos: NavPathStack) {
    LogUtils.i(TAG, `handleJumpToSosSettingsPage ${previousPage}`);
    const startAbilityToSosSettings = () => {
      (getContext() as common.UIAbilityContext).startAbility({
        bundleName: 'com.ohos.settings',
        abilityName: 'com.ohos.settings.MainAbility',
        uri: 'sos_emergency_help_entry',
        parameters: {
          settingsParamBundleName: 'com.ohos.emergencycommunication'
        }
      });
    };
    switch (previousPage) {
      case SosEmergencyHelpSettings.PAGE_NAME:
        pathInfos.clear();
        break;
      case WrappedEmergencyContactsInfo.currentPage:
        const session: UIExtensionContentSession | undefined =
          LocalStorage.getShared()?.get<UIExtensionContentSession>('session');
        try {
          session?.sendData({
            action: 'jump',
            uri: 'sos_emergency_help_entry',
            bundleName: 'com.ohos.emergencycommunication',
          } as LooseObject);
        } catch (e) {
          LogUtils.e(TAG, `onReceive:Failed to sendData. code: ${e?.code}, message: ${e?.message}`);
        }
        break;
      default:
        CanAddOrEditEmergencyInfo((isUnlock) => {
          if (isUnlock) {
            startAbilityToSosSettings();
          }
        });
    }
  }
}