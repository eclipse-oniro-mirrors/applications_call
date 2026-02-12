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

import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { LogUtils, ReportUtil, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import display from '@ohos.display';
import CallSettingVM from '../viewModel/CallSettingVM';
import { pafInit } from '../common/utils/PafEngineUtils';
import { ConfigurationConstant, Configuration } from '@kit.AbilityKit';
import { FontScaleState } from '../common/utils/FontScaleState';
import { ReportWorkSchedulerUtil } from '../WorkSchedulerExtension/ReportWorkSchedulerUtil';
import SplitScreenManager from '../model/SplitScreenManager';
// instrument ignore file

const TAG = 'CallSettingAbility';

export default class CallSettingAbility extends UIAbility {
  public storage?: LocalStorage;
  private windowObj?: window.Window;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private lastColorMode: ConfigurationConstant.ColorMode | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'Ability onCreate, uri: ' + want?.uri);
    this.setWantUri(want);
    CallSettingGlobalContextHelper.getContext()
      .set<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT, this.context);
    this.storage = new LocalStorage();
    CallSettingVM.getInstance().setIsFromExternal(false);
    CallSettingVM.getInstance().initData();
    ReportUtil.getInstance();
    ReportWorkSchedulerUtil.tryStartButtonStateReportWorkScheduler();
  }

  onDestroy(): void {
    AppStorage.delete('callSettingsUri');
    LogUtils.i(TAG, 'Ability onDestroy');
    CallSettingVM.getInstance().unregister();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    LogUtils.i(TAG, 'Ability onWindowStageCreate');
    pafInit(windowStage, this.context);
    this.adaptiveAging();
    try {
      let mainWindow = windowStage.getMainWindowSync();
      let currentColorMode = this.context?.config?.colorMode;
      AppStorage.setOrCreate('currentColorMode', currentColorMode);
      let currentDirection = this.context?.config?.direction;
      AppStorage.setOrCreate('currentDirection', currentDirection);
      let systemBarProperties: window.SystemBarProperties = {
        statusBarContentColor: currentColorMode ? '#ff000000' : '#ffffffff',
      }
      mainWindow.setWindowSystemBarProperties(systemBarProperties);
      windowStage.loadContent('pages/Index', (err, data) => {
        if (err.code) {
          LogUtils.i(TAG, 'Failed to load the content. Cause: ' + JSON.stringify(err) ?? '');
          return;
        }
        LogUtils.i(TAG, 'Succeeded in loading the content. Data: ' + JSON.stringify(data) ?? '');
        mainWindow.setWindowBackgroundColor(currentColorMode ? '#f2f3f5' : '#ff000000');
      });
    } catch (err) {
      LogUtils.e(TAG, `getMainWindowSync error:  ${err?.code}, ${err?.message}`);
    }
    try {
      windowStage.getMainWindow().then((windowObj) => {
        this.windowObj = windowObj;
        try {
          let width = windowObj.getWindowProperties().windowRect.width;
          let height = windowObj.getWindowProperties().windowRect.height;
          this.addWindowStatusListener();
          SplitScreenManager.getInstance().updateScreenSize(width, height);
          // Obtain the window size
          AppStorage.setOrCreate('ratio'
            , windowObj.getWindowProperties().windowRect.width / windowObj.getWindowProperties().windowRect.height);
          this.mCallColumnUtils.updateBreakpoint(windowObj.getWindowProperties().windowRect.width);
          // Monitor window size change
          windowObj.on('windowSizeChange', (windowSize) => {
            SplitScreenManager.getInstance().updateScreenSize(windowSize.width, windowSize.height);
            AppStorage.setOrCreate('ratio', windowSize.width / windowSize.height);
            this.mCallColumnUtils.updateBreakpoint(windowSize.width);
          });
        } catch (err) {
          LogUtils.e(TAG, `onWindowStageCreate err = ${JSON.stringify(err)}`);
        }
        this.addFoldStatusListener();
        try {
          // 添加安全水印标志
          this.windowObj.setWaterMarkFlag(true);
        } catch (err) {
          LogUtils.e(TAG, `onWindowStageCreate Failed to set water mark flag. Cause:  ${err?.code}, ${err?.message}`);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `windowStage getMainWindow error:  ${err?.code}, ${err?.message}`);
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    LogUtils.i(TAG, 'Ability onWindowStageDestroy');
    AppStorage.delete('currentColorMode');
    if (!this.windowObj) {
      return;
    }
    try {
      // 删除安全水印标志
      this.windowObj.setWaterMarkFlag(false);
    } catch (err) {
      LogUtils.e(TAG, `onWindowStageDestroy Failed to set water mark flag. Cause:  ${err?.code}, ${err?.message}`);
    }
    try {
      this.windowObj.off('windowSizeChange');
    } catch (exception) {
      LogUtils.e(TAG, 'windowSizeChange catch err:' + JSON.stringify(exception));
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtils.i(TAG, 'Ability onForeground');
    this.setSystemBarProps();
  }

  onBackground(): void {
    // Ability has back to background
    LogUtils.i(TAG, 'Ability onBackground');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam) {
    LogUtils.i(TAG, 'Ability onNewWant, uri: ' + want?.uri);
    AppStorage.setOrCreate('isGoHome', true);
    this.setWantUri(want);
  }

  addFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    // try {
    //   display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
    //     LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
    //     AppStorage.setOrCreate('foldStatus', foldStatus);
    //   })
    // } catch (exception) {
    //   LogUtils.e(TAG, 'foldStatusChange exp=' + JSON.stringify(exception));
    // }
  }

  addWindowStatusListener(): void {
    // let windowStatus = this.windowObj?.getWindowStatus() ?? 0;
    // LogUtils.i(TAG, 'windowStatusChange windowStatusType init' + windowStatus);
    // SplitScreenManager.getInstance().updateWindowStatusType(windowStatus);
    try {
      // Monitor window status change
      // this.windowObj?.on('windowStatusChange', (windowStatusType) => {
      //   SplitScreenManager.getInstance().updateWindowStatusType(windowStatusType);
      // });
    } catch (err) {
      LogUtils.e(TAG, `windowStatusChange exp= ${JSON.stringify(err)}`);
    }
  }

  removeFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      // display.off('foldStatusChange');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
  }

  setSystemBarProps(config?: Configuration) {
    LogUtils.i(TAG, 'setSystemBarProps start');
    let currentColorMode: ConfigurationConstant.ColorMode | undefined =
      config?.colorMode !== undefined ? config?.colorMode : AppStorage.get('currentColorMode');
    if (this.lastColorMode === currentColorMode) {
      LogUtils.i(TAG, 'ColorMode has not changed.')
      return;
    }
    let systemBarProperties: window.SystemBarProperties = {
      statusBarContentColor: currentColorMode ? '#ff000000' : '#ffffffff',
    }
    this.lastColorMode = currentColorMode;
    try {
      this.windowObj?.setWindowBackgroundColor(currentColorMode ? '#f2f3f5' : '#ff000000');
      this.windowObj?.setWindowSystemBarProperties(systemBarProperties);
    } catch (err) {
      LogUtils.e(TAG, `setSystemBarProps setWindowBackgroundColor err = ${JSON.stringify(err)}`);
    }
  }

  onConfigurationUpdate(newConfig: Configuration) {
    LogUtils.i(TAG, 'Ability onConfigurationUpdate');
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
    AppStorage.setOrCreate('currentDirection', newConfig?.direction);
    this.setSystemBarProps(newConfig);

    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'onConfigurationUpdate' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private adaptiveAging() {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
    let fontSizeScale = context.config?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'adaptiveAging' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private setWantUri(want: Want) {
    if (want?.uri !== undefined) {
      AppStorage.setOrCreate('callSettingsUri', want.uri.toString());
    }
  }
}
