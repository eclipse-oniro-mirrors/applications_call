/**
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

import LogUtils from '../utils/HiLog';
import Want from '@ohos.app.ability.Want';
import SOSEmergencyCallAbility from '../sosemergencycallability/SOSEmergencyCallAbility';
import { SosEmergencyHelpSettings } from './SosEmergencyHelpSettings';
import { common, UIExtensionContentSession } from '@kit.AbilityKit';
import LooseObject from '../data/LooseObject';
import { CanAddOrEditEmergencyInfo } from '../utils/EmergencyInfoUtil';
//import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';

const TAG = 'EmergencyInfoUIExtension';

@Builder
export function sateEmergencyInfoUIExtension(previousPage: string): void {
  EmergencyInfoUIExtension({ previousPage: previousPage })
}

export const ON_RECEIVE_ACTION_JUMP_TO_SOS_SETTINGS_PAGE = 'jump';

export const ON_RECEIVE_URI_JUMP_TO_SOS_SETTINGS_PAGE = 'sos_emergency_help_entry';

@Component
export default struct EmergencyInfoUIExtension {
  previousPage: string = '';
  @Consume('pathInfos') pathInfos: NavPathStack;
  private proxyComponent: UIExtensionProxy | null = null;
  want: Want = {
    'bundleName': 'com.ohos.emergencycommunication',
    'abilityName': 'com.ohos.emergencycommunication.EmergencyInfoAbility',
    'parameters': {
      'ability.want.params.uiExtensionType': 'sys/commonUI',
      'ability.want.params.IsNotifyOccupiedAreaChange': true,
      'source': 'index'
    }
  }
  @StorageProp(SOSEmergencyCallAbility.KEY_IS_WINDOW_LAYOUT_FULL_SCREEN) isWindowLayoutFullScreen: boolean = false;
  @StorageProp(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT) topStatusBarHeight: number = 0;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.want.parameters = {
      'ability.want.params.uiExtensionType': 'sys/commonUI',
      'ability.want.params.IsNotifyOccupiedAreaChange': true,
      'source': 'index',
      'previousPage': this.previousPage
    }
  }

  build() {
/*    HdsNavDestination() {
      Column() {
        UIExtensionComponent(this.want)
          .size({ width: '100%', height: '100%' })
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRemoteReady');
            this.proxyComponent = proxy;
          })
          .onReceive((data) => {
            LogUtils.i(TAG, 'UIExtensionComponent onReceive');
            if (data && data['action'] === ON_RECEIVE_ACTION_JUMP_TO_SOS_SETTINGS_PAGE &&
              String(data['uri']) === ON_RECEIVE_URI_JUMP_TO_SOS_SETTINGS_PAGE) {
              LogUtils.i(TAG, `onReceive: Jump to SosEmergencyHelpSettings`);
              this.handleJumpToSosSettingsPage();
            }
          })
          .onRelease((releaseCode: number) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRelease');
            this.pathInfos.pop();
          })
          .onResult((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onResult');
            this.pathInfos.pop();
          })
          .onError((error: ErrorObject) => {
            LogUtils.i(TAG, 'UIExtensionComponent ' + 'onError: ' + error.code + ', name: ' + error.name +
              ', message: ' + error.message);
          })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
      }
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    }*/
    NavDestination() {
      Column() {
        UIExtensionComponent(this.want)
          .size({ width: '100%', height: '100%' })
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRemoteReady');
            this.proxyComponent = proxy;
          })
          .onReceive((data) => {
            LogUtils.i(TAG, 'UIExtensionComponent onReceive');
            if (data && data['action'] === ON_RECEIVE_ACTION_JUMP_TO_SOS_SETTINGS_PAGE &&
              String(data['uri']) === ON_RECEIVE_URI_JUMP_TO_SOS_SETTINGS_PAGE) {
              LogUtils.i(TAG, `onReceive: Jump to SosEmergencyHelpSettings`);
              this.handleJumpToSosSettingsPage();
            }
          })
          .onRelease((releaseCode: number) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRelease');
            this.pathInfos.pop();
          })
          .onResult((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onResult');
            this.pathInfos.pop();
          })
          .onError((error: ErrorObject) => {
            LogUtils.i(TAG, 'UIExtensionComponent ' + 'onError: ' + error.code + ', name: ' + error.name +
              ', message: ' + error.message);
          })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
      }
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(true)
  }

  private handleJumpToSosSettingsPage() {
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
    switch (this.previousPage) {
      case SosEmergencyHelpSettings.PAGE_NAME:
        this.pathInfos.clear();
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

interface ErrorObject {
  code: number;
  name: string;
  message: string;
}