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
import LogUtils from '../utils/HiLog';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import SubscriberManagement from '../utils/SubscriberManagement';
import common from '@ohos.app.ability.common';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import CallColumnUtils from '../utils/CallColumnUtils';
import { Router } from '@ohos.arkui.UIContext';
import { ReportUtil } from '../utils/ReportUtil';
import { BusinessError } from '@ohos.base';
import { DisplayUtil } from '../utils/DisplayUtil';
import display from '@ohos.display';
import { FontScaleState } from '../utils/FontScaleState';
import { ConfigurationConstant, Configuration, wantAgent, WantAgent } from '@kit.AbilityKit';
import { Utils } from '../utils/Utils';
import { emitter, runningLock, systemDateTime } from '@kit.BasicServicesKit';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { deviceStandby } from '@kit.BackgroundTasksKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { EfficiencyResourcesController } from '../control/EfficiencyResourcesController';

const TAG = 'EmergencyMainAbility';

/** 申请CPU能效资源的原因 */
const REASON_APPLY_EFFICIENCY_RESOURCES = 'apply';

export default class EmergencyCallAbility extends UIAbility {

  public static ABILITY_NAME = 'EmergencyCallAbility'

  private windowObj?: window.Window;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private windowStage: window.WindowStage | null = null;
  private lastColorMode: ConfigurationConstant.ColorMode | undefined = undefined;
  public isPlaying: boolean | undefined = false;
  private foldChangeCallBack = (foldStatus: display.FoldStatus) => {
    LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
    this.setIsNewFoldPhoneExternalScreen(this.windowObj as window.Window);
  };
  private tempRunlock?: runningLock.RunningLock;
  private resRequest: deviceStandby.ResourceRequest = {
    resourceTypes: deviceStandby.ResourceType.NETWORK,
    uid: this.getUidByBundle(Constants.BUNDLE_NAME_EMERGENCY_CALL),
    name: Constants.BUNDLE_NAME_EMERGENCY_CALL,
    duration: 600,
    reason: 'apply',
  };
  private resRequestLocation: deviceStandby.ResourceRequest = {
    resourceTypes: deviceStandby.ResourceType.NETWORK,
    uid: this.getUidByBundle(Constants.BUNDLE_NAME_LOCATION),
    name: Constants.BUNDLE_NAME_LOCATION,
    duration: 120,
    reason: 'apply',
  };

  private getUidByBundle(bundleName: string): number {
    try {
      let appFlags = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
      let applicationInfo = bundleManager.getApplicationInfoSync(bundleName, appFlags);
      LogUtils.i(TAG, 'getUidByBundle success, bundleName = ' + bundleName + ', uid = ' + applicationInfo?.uid);
      return applicationInfo?.uid;
    } catch (err) {
      LogUtils.e(TAG, 'getUidByBundle err: ' + JSON.stringify(err));
    }
    return 0;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'Ability onCreate');
    EmergencyGlobalContextHelper.getContext()
      .set<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT, this.context);
    SubscriberManagement.registerSubscriber();
    ReportUtil.getInstance();
  }

  requestExemption(resRequest: deviceStandby.ResourceRequest) {
    try {
      LogUtils.i(TAG, 'requestExemptionResource');
      deviceStandby.requestExemptionResource(resRequest);
    } catch (e) {
      LogUtils.e(TAG, 'requestExemptionResource error:' + JSON.stringify(e));
    }
  }

  unRequestExemption(resRequest: deviceStandby.ResourceRequest) {
    try {
      LogUtils.i(TAG, 'unRequestExemption');
      deviceStandby.releaseExemptionResource(resRequest);
    } catch (e) {
      LogUtils.e(TAG, 'unRequestExemption error:' + JSON.stringify(e));
    }
  }

  async keepAlive() {
    try {
      let isSupported = runningLock.isSupported(runningLock.RunningLockType.BACKGROUND);
      LogUtils.i(TAG, 'BACKGROUND type supported: ' + isSupported);
      if (!isSupported) {
        LogUtils.w(TAG, 'BACKGROUND type not supported: ' + isSupported);
        return;
      }
    } catch (err) {
      LogUtils.i(TAG, 'check supported failed, err: ' + err);
    }
    this.tempRunlock =
      await runningLock.create('earthquake_running_lock', runningLock.RunningLockType.BACKGROUND);
    try {
      this.tempRunlock.hold(600000);
      LogUtils.i(TAG, 'hold running lock success');
    } catch (err) {
      LogUtils.e(TAG, 'hold running lock failed, err: ' + err);
    }
    let isHolding = this.tempRunlock.isHolding();
    LogUtils.i(TAG, 'hold isHolding success + ' + isHolding);
  }

  releaseKeepAlive() {
    try {
      let isHolding = this.tempRunlock?.isHolding();
      LogUtils.i(TAG, 'hold isHolding success + ' + isHolding);
      if (isHolding) {
        this.tempRunlock?.unhold()
        let isHolding = this.tempRunlock?.isHolding();
        LogUtils.i(TAG, 'hold unHolding success + ' + isHolding);
      }
    } catch (err) {
      LogUtils.e(TAG, 'hold running lock failed, err: ' + err);
    }
  }

  keepBackGroundRunning() {
    LogUtils.i(TAG, 'keepBackGroundRunning Start!');
    try {
      const timeOut = 600000;
      EfficiencyResourcesController.applyCpuEfficiencyResources(timeOut, REASON_APPLY_EFFICIENCY_RESOURCES, TAG);
    } catch (err) {
      LogUtils.e(TAG, 'keepBackGroundRunning, err: ' + err);
    }
  }

  stopBackGroundRunning() {
    LogUtils.i(TAG, 'stopBackGroundRunning Start!');
    try {
      EfficiencyResourcesController.reduceCpuEfficiencyResources(REASON_APPLY_EFFICIENCY_RESOURCES, TAG);
    } catch (err) {
      LogUtils.e(TAG, 'stopBackGroundRunning, err: ' + err);
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    let ctx = this.windowObj?.getUIContext();
    if (ctx) {
      let url = 'pages/Index';
      let router: Router = ctx.getRouter();
      router.replaceUrl({
        url
      }).then(() => {
        if (this.windowStage) {
          this.windowStage.setShowOnLockScreen(true);
        }
      })
        .catch((err: BusinessError) => {
          LogUtils.e(TAG, `Failed to push url:${err.message}`);
        })

    } else {
      LogUtils.e(TAG, `no uiContext`);
    }
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'Ability onDestroy');
    this.removeFoldStatusListener();
    SubscriberManagement.unsubscribe();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    LogUtils.i(TAG, 'Ability onWindowStageCreate');
    let currentColorMode = this.context?.config?.colorMode;
    AppStorage.setOrCreate('currentColorMode', currentColorMode);
    let systemBarProperties: window.SystemBarProperties = {
      statusBarContentColor: currentColorMode ? '#ff000000' : '#ffffffff',
    }
    try {
      let mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowSystemBarProperties(systemBarProperties);
    } catch (businessError) {
      LogUtils.e(TAG, `get mainWindow error. Cause: ${businessError?.message}`);
    }
    windowStage.setDefaultDensityEnabled(true);

    this.adaptiveAging();

    this.windowStage = windowStage;
    windowStage.setShowOnLockScreen(true);
    EmergencyGlobalContextHelper.getContext().
    set<window.WindowStage>(Constants.EMERGENCY_CALL_WINDOW_STAGE, windowStage);
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        LogUtils.i(TAG, 'Failed to load the content. Cause: ' + JSON.stringify(err) ?? '');
        return;
      }
      LogUtils.i(TAG, 'Succeeded in loading the content.');
    });
    windowStage.getMainWindow().then((windowObj) => {
      this.windowObj = windowObj;
      try {
        // Obtain the window size
        AppStorage.setOrCreate('ratio'
          , windowObj.getWindowProperties().windowRect.width / windowObj.getWindowProperties().windowRect.height);
        this.mCallColumnUtils.updateBreakpoint(windowObj.getWindowProperties().windowRect.width);
        AppStorage.setOrCreate('windowSizeChangeMd', {
          width: windowObj.getWindowProperties().windowRect.width,
          height: windowObj.getWindowProperties().windowRect.height
        });
      } catch (businessError) {
        LogUtils.e(TAG, `updateBreakpoint error. Cause: ${businessError?.message}`);
      }
      // Monitor window size change
      windowObj.on('windowSizeChange', (windowSize)=>{
        if (windowSize?.height > 0) {
          AppStorage.setOrCreate('ratio', windowSize?.width / windowSize?.height);
        } else {
          AppStorage.setOrCreate('ratio', 9 / 16);
        }
        AppStorage.setOrCreate('windowSizeChangeMd', {
          width: windowSize?.width,
          height: windowSize?.height
        });
        this.mCallColumnUtils.updateBreakpoint(windowSize.width);
      });
      this.setIsNewFoldPhoneExternalScreen(this.windowObj);
      this.addFoldStatusListener();
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getMainWindow Failed: ${err?.message}`);
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    LogUtils.i(TAG, 'Ability onWindowStageDestroy');
    AppStorage.delete('currentColorMode');
    AppStorage.delete('isNewFoldPhoneExternalScreen');
    if (!this.windowObj) {
      return;
    }
    try {
      this.windowStage = null;
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

  addFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      display.on('foldStatusChange', this.foldChangeCallBack);
    } catch (exception) {
      LogUtils.e(TAG, 'foldStatusChange exception = ' + JSON.stringify(exception));
    }
  }

  removeFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      display.off('foldStatusChange', this.foldChangeCallBack);
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'onConfigurationUpdate' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    DisplayUtil.updateIsRtl();
    this.setSystemBarProps(newConfig);
  }

  private adaptiveAging() {
    let context = EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT);
    let fontSizeScale = context.config?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'adaptiveAging' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    DisplayUtil.updateIsRtl();
  }

  setSystemBarProps(config?: Configuration) {
    LogUtils.i(TAG, 'setSystemBarProps start');
    let currentColorMode: ConfigurationConstant.ColorMode | undefined =
      config?.colorMode !== undefined ? config?.colorMode : AppStorage.get('currentColorMode');
    if (this.lastColorMode === currentColorMode) {
      LogUtils.i(TAG, 'ColorMode has not changed.');
      return;
    }
    let systemBarProperties: window.SystemBarProperties = {
      statusBarContentColor: currentColorMode ? '#ff000000' : '#ffffffff',
    }
    this.lastColorMode = currentColorMode;
    this.windowObj?.setWindowBackgroundColor(currentColorMode ? '#f2f3f5' : '#ff000000');
    this.windowObj?.setWindowSystemBarProperties(systemBarProperties);
  }

  setIsNewFoldPhoneExternalScreen(windowObj: window.Window) {
    if (!windowObj) {
      return;
    }
    let isNewFoldPhoneExternalScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
    AppStorage.setOrCreate('isNewFoldPhoneExternalScreen', isNewFoldPhoneExternalScreen);
    if (isNewFoldPhoneExternalScreen) {
      Utils.setSystemBarEnable(windowObj, false);
      Utils.setWindowLayoutFullScreenApi(windowObj, true);
    } else {
      Utils.setSystemBarEnable(windowObj, true);
      Utils.setWindowLayoutFullScreenApi(windowObj, false);
    }
  }
}