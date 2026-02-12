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


import { AbilityConstant, common, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { CallSettingGlobalContextHelper, LogUtils } from '@ohos/common';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT, CARD_PAGE_MODE } from '../common/constant/CallSettingsConstant';
import SatelliteServiceSettingsVM from '../viewModel/SatelliteServiceSettingsVM';

const TAG = 'CallSettingGlobalContextHelper';

export default class SatelliteUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'SatelliteUIAbility onCreate');
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'SatelliteUIAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    LogUtils.i(TAG, 'SatelliteUIAbility onWindowStageCreate');
    CallSettingGlobalContextHelper.getContext()
      .set<common.UIAbilityContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT, this.context);
    try {
      let windowClass = windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true);
    } catch (e) {
      LogUtils.e(TAG, `set full screen failed ${e?.code}, ${e?.message}`);
    }
    windowStage.loadContent('pages/SatelliteNetworkBlankPage', (err) => {
      if (err.code) {
        LogUtils.e(TAG, `Failed to load the content. Cause: ${err.code}, ${err.message}`);
        return;
      }
      LogUtils.i(TAG, 'Succeeded in loading the content.');
    });
    AppStorage.setOrCreate<number>('statusBarHeight', 0);
    AppStorage.setOrCreate<NavigationMode>('navigationMode', NavigationMode.Stack);
    AppStorage.setOrCreate<string>('pageMode', CARD_PAGE_MODE);
    AppStorage.setOrCreate('currentLanguage', this.context.resourceManager.getConfigurationSync().locale);
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    LogUtils.i(TAG, 'SatelliteUIAbility onWindowStageDestroy');
    SatelliteServiceSettingsVM.getInstance().unRegisterData();
    AppStorage.delete('statusBarHeight');
    AppStorage.delete('navigationMode');
    AppStorage.delete('pageMode');
    AppStorage.delete('currentLanguage');
    AppStorage.delete('currentColorMode');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.setOrCreate('currentLanguage', newConfig?.language);
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtils.i(TAG, 'SatelliteUIAbility onForeground');
    // 蓬莱模式小概率回到前台后context release，重新赋值
    CallSettingGlobalContextHelper.getContext()
      .set<common.UIAbilityContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT, this.context);
  }

  onBackground(): void {
    // Ability has back to background
    LogUtils.i(TAG, 'SatelliteUIAbility onBackground');
  }
}
