/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import UIAbility from '@ohos.app.ability.UIAbility';
import LogUtils from '../common/utils/LogUtils';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import display from '@ohos.display';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import emitter from '@ohos.events.emitter';
import CallDataManager from '../model/CallDataManager';
import { BusinessError } from '@ohos.base';
import { Configuration } from '@ohos.app.ability.Configuration';
import { CallFaultEventUtil } from '../common/utils/ReportUtils/CallFaultEventUtil';
import { FontScaleState } from '../common/utils/FontScaleState';
import { ListenScreenUnlocked } from '../common/utils/ListenScreenUnlocked';
import SplitScreenManager from '../model/SplitScreenManager';
import { maximizeByPcMode } from '../common/utils/PcModeHelper';
import BannerNotificationManager from '../model/BannerNotificationManager';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { FullGC } from '../common/utils/ArkTool';
import DefaultCallData from '../common/struct/TypeUtils';
import CallStateConst from '../common/constant/CallStateConst';
import { VisionGlassConstants } from '../common/constant/VisionGlassConstants';
import CallManagerService from '../ServiceAbility/CallManagerService';
import { ProximityUtils } from '../common/utils/ProximityUtils';
import { ExternalCallModel } from '../model/ExternalCallModel';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import { DisplayMode } from '../common/utils/ReportUtils/DisplayMode';


const TAG = 'CallUIMainAbility';
const emitterId = 101;
const IS_ENABLE_NEW_FEATURE_EVENT = 'INTELLIGENT_ENABLE_NEW_FEATURES';

export default class MainAbility extends UIAbility {
  private windowObj?: window.Window;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    LogUtils.i(TAG, 'onCreate');
    if (CallDataManager.getInstance().callList.length === 0) {
      LogUtils.i(TAG, 'no calls. shut down.');
      AppStorage.setOrCreate('clearStorage', true);
      // this.context.terminateSelf().then(() => {
      //   LogUtils.i(TAG, 'terminateSelf success');
      // }, (err: BusinessError) => {
      //   LogUtils.i(TAG, `terminateSelf failed, code is ${err.code}, message is ${err.message}`);
      // });
      return;
    }
    GlobalContextHelper.getContext().set<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT, this.context);
    if (AppStorage.has('clearStorage')) {
      AppStorage.delete('clearStorage');
    }
    CallManagerService.getInstance().updateHyacinthInfo();
  }

  onPrepareToTerminate() {
    ProximityUtils.minimize();
    return true;
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    LogUtils.i(TAG, 'onWindowStageWillDestroy');
    try {
      windowStage.off('windowStageEvent');
      windowStage.getMainWindowSync().off('windowStatusChange');
    } catch (e) {
      LogUtils.e(TAG, `Failed to off listener for window stage  ${e.code}, message: ${e.message}`);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    try {
      windowStage.loadContent('pages/index', (err) => {
        if (err.code) {
          LogUtils.e(TAG, `Failed to loadContent. code: ${err.code}, message: ${err.message}`);
          return;
        }
        try {
          PersistentStorage.persistProp('reportEnableFeatureTime', 0);
          ReportUtil.getInstance().reportNewFeatureEvent(IS_ENABLE_NEW_FEATURE_EVENT);
        } catch (e) {
          LogUtils.e(TAG, `Failed to persist property or report event. code: ${e.code}, message: ${e.message}`);
        }
      });
    } catch (e) {
      LogUtils.e(TAG, `Failed to on listener for window stage  ${e.code}, message: ${e.message}`);
    }
    LogUtils.i(TAG, 'onWindowStageCreate 11');
    if (AppStorage.has('clearStorage')) {
      return;
    }

    try {
      windowStage.setShowOnLockScreen(true);
      if (AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS)) {
        windowStage.setDefaultDensityEnabled(false);
      } else {
        windowStage.setDefaultDensityEnabled(true);
      }

      let mainWindow = windowStage.getMainWindowSync();
      this.windowObj = mainWindow;

      maximizeByPcMode(this.context, this.windowObj);

    try {
      this.windowObj.setWaterMarkFlag(true);
    } catch (e) {
      LogUtils.e(TAG, `Failed to set water mark flag of window. Cause: ${e?.code}`);
    }

    // wake up screen
    this.windowObj.setWakeUpScreen(true);

      this.registerAvoidAreaChange(this.windowObj);
      let windowHeight = this.windowObj.getWindowProperties().windowRect.height;
      let windowWidth = this.windowObj.getWindowProperties().windowRect.width;
      this.checkSmartAndFloatingWindow(windowHeight, windowWidth);

      GlobalContextHelper.getContext().set<window.Window>(Constants.WINDOW, this.windowObj);
      let sysBarProps: window.SystemBarProperties = {
        statusBarContentColor: '#ffffff'
      };
      this.windowObj.setWindowSystemBarProperties(sysBarProps).catch((err: BusinessError) => {
        LogUtils.e(TAG, `setWindowSystemBarProperties error. code: ${err?.code}, msg: ${err?.message}`);
      });
      windowStage.loadContent('pages/index').then(() => {
        this.mCallColumnUtils.getWindowDecorHeight(mainWindow);
        this.mCallColumnUtils.setWindowLimit(mainWindow);
        LogUtils.i(TAG, 'Succeeded in loading the content.');
      }).catch((err: BusinessError) => {
        if (AppStorage.get<DefaultCallData>('callData')?.callState === CallStateConst.CALL_STATUS_INCOMING) {
          ReportUtil.getInstance().reportIncomingDisplay(DisplayMode.FULLSCREEN, Constants.FAILURE);
        } else if (AppStorage.get<DefaultCallData>('callData')?.callState === CallStateConst.CALL_STATUS_DIALING) {
          ReportUtil.getInstance().reportOutgoingDisplay(DisplayMode.FULLSCREEN, Constants.FAILURE);
        }
        LogUtils.e(TAG, `Failed to load the content. code: ${err?.code}, msg: ${err?.message}`);
      });

      this.windowProperties(mainWindow);
    } catch (err) {
      LogUtils.e(TAG, `onWindowStageCreate error code: ${err?.code}, msg: ${err?.message}`);
    }
    this.adaptiveAging();
    ListenScreenUnlocked.getInstance().addStkLockNotiSubscriber();
  }

  private registerAvoidAreaChange(windowObj: window.Window): void {
    try {
      // avoidAreaChange should be added before loading content!
      windowObj.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          this.handleSystemAvoidAreaType(windowObj, data);
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          this.handleNavigationAvoidAreaType(windowObj, data);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `register avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private handleSystemAvoidAreaType(windowObj: window.Window, data: window.AvoidAreaOptions): void {
    let heightVp = this.px2vpFunc(windowObj, data.area.topRect.height);
    if (heightVp !== AppStorage.get<number>('statusBarHeight')) {
      LogUtils.i(TAG, 'StatusBar area changed! height = ' + heightVp);
    }
    AppStorage.setOrCreate('statusBarHeight', heightVp);
  }

  private handleNavigationAvoidAreaType(windowObj: window.Window, data: window.AvoidAreaOptions): void {
    let heightVp = this.px2vpFunc(windowObj, data.area.bottomRect.height);
    if (heightVp !== AppStorage.get<number>('navigationHeight')) {
      LogUtils.i(TAG, 'Navigation Indicator area changed! height = ' + heightVp);
    }
    AppStorage.setOrCreate('navigationHeight', heightVp);
  }

  private px2vpFunc(windowObj: window.Window, height: number): number {
    let uiContext: UIContext | null;
    try {
      uiContext = windowObj.getUIContext();
    } catch (err) {
      uiContext = null;
      LogUtils.e(TAG, `get context err, err: ${JSON.stringify(err)}`);
    }
    let heightVp = 0;
    if (uiContext === null) {
      heightVp = px2vp(height);
    } else {
      heightVp = uiContext.px2vp(height);
    }
    return heightVp;
  }

  private adaptiveAging() {
    let fontSizeScale = this.context.config?.fontSizeScale ?? 1;
    LogUtils.i(TAG, JSON.stringify(fontSizeScale) + ' Ability onWindowStageCreate  fontSizeScale2');
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  /**
   * 检查窗口状态和宽高变化，判断是否处于智慧多窗或悬浮窗场景，以及是否分屏
   * isShowSmartWindow 智慧多窗、智慧多窗分屏或悬浮窗场景，windowStatusType都是Floating
   * isSmartWindowSplitScreen 智慧多窗分屏
   *
   * @param windowHeight
   * @param windowWidth
   */
  checkSmartAndFloatingWindow(windowHeight: number, windowWidth: number): void {
    this.windowStatus = this.windowObj?.getWindowStatus() ?? 0;
    if (this.windowStatus !== window.WindowStatusType.FLOATING) {
      AppStorage.setOrCreate('isShowSmartWindow', false);
      return;
    }
    const size = this.mCallColumnUtils.display;
    if (size?.height && size.height > windowHeight) {
      AppStorage.setOrCreate('isShowSmartWindow', true);
      return;
    }
    if (!size?.height || size?.height === windowHeight) {
      AppStorage.setOrCreate('isShowSmartWindow', false);
      if (!size?.width || size?.width === windowWidth) {
        AppStorage.setOrCreate('isSmartWindowSplitScreen', false);
      } else if (size.width > windowWidth) {
        AppStorage.setOrCreate('isSmartWindowSplitScreen', true);
      } else {
        // do nothing
      }
    } else if (this.windowStatus == window.WindowStatusType.FLOATING){
      AppStorage.setOrCreate('isShowSmartWindow', true);
    }
  }

  windowProperties(mainWindow: window.Window) {
    // Obtain the window size
    let width = mainWindow.getWindowProperties().windowRect.width;
    let height = mainWindow.getWindowProperties().windowRect.height;

    AppStorage.setOrCreate('windowSizeChangeMd', {
      width: width, height: height
    });
    this.addWindowStatusListener();
    this.setIsNewFoldPhoneExternalScreen();
    this.setIsNewFoldPhoneInnerScreenStatus(this.windowObj);
    this.mCallColumnUtils.updateBreakpoint(width, mainWindow);
    SplitScreenManager.getInstance().updateScreenSize(width, height);
    try {
      // Monitor window size change
      mainWindow.on('windowSizeChange', (windowSize: window.Size) => {
        this.checkSmartAndFloatingWindow(windowSize.height, windowSize.width);
        this.mCallColumnUtils.updateBreakpoint(windowSize.width, mainWindow);
        AppStorage.setOrCreate('windowSizeChangeMd', {
          width: windowSize.width, height: windowSize.height
        });
        SplitScreenManager.getInstance().updateWindowStatusType(this.windowObj?.getWindowStatus() ?? 0);
        SplitScreenManager.getInstance().updateScreenSize(windowSize.width, windowSize.height);
        this.mCallColumnUtils.windowSizeChange(windowSize.width, windowSize.height, mainWindow);
        this.setIsNewFoldPhoneInnerScreenStatus(this.windowObj);
      });
    } catch (err) {
      LogUtils.e(TAG, `register windowSizeChange callback failed, err: ${JSON.stringify(err)}`);
    }
    this.addFoldStatusListener();
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    LogUtils.i(TAG, 'onWindowStageDestroy');
    ListenScreenUnlocked.getInstance().unsubscribeStkLockNoti();
    if (!this.windowObj) {
      return;
    }
    try {
      this.windowObj.off('avoidAreaChange');
      this.windowObj.off('windowSizeChange');
      AppStorage.delete('windowStatus');
    } catch (exception) {
      LogUtils.e(TAG, 'Window unregister catch err:' + JSON.stringify(exception));
    }
  }

  onForeground() {
    // Ability has brought to foreground
    LogUtils.i(TAG, 'onForeground');
    this.sendBackOrForeEmitterMsg('foreground');
  }

  onBackground() {
    // Ability has back to background
    LogUtils.i(TAG, 'onBackground');
    let bnMananger = BannerNotificationManager.getInstance();
    if (bnMananger.isStartingAbility()) {
      LogUtils.i(TAG, 'onBackground sendNotification');
      bnMananger.setIsStartingAbility(false);
      bnMananger.sendNotification();
    }
    this.sendBackOrForeEmitterMsg('background');
    setTimeout(() => {
      FullGC();
    })
  }

  onBackPressed(): boolean {
    return true;
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy');
    this.removeFoldStatusListener();
    if (AppStorage.has('clearStorage')) {
      CallDataManager.getInstance().clearStorage();
    } else {
      AppStorage.setOrCreate('clearStorage', true);
    }
    CallFaultEventUtil.getInstance().reportOnDestroy();
    ProximityUtils.keepScreenOn(false);
  }

  addFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable() && !ExternalCallModel.isSmallExternalDevice()) {
      return;
    }
    try {
      AppStorage.setOrCreate<number>('FoldStatus', display.getFoldStatus());
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
        AppStorage.setOrCreate<number>('FoldStatus', foldStatus);
        this.setIsNewFoldPhoneExternalScreen();
        this.setIsNewFoldPhoneInnerScreenStatus(this.windowObj);
      })
    } catch (exception) {
      LogUtils.e(TAG, 'foldStatusChange exp=' + JSON.stringify(exception));
    }
    try {
      AppStorage.setOrCreate<number>('foldDisplayMode', display.getFoldDisplayMode());
      display.on('foldDisplayModeChange', (foldDisplayMode: display.FoldDisplayMode) => {
        LogUtils.i(TAG, 'foldDisplayModeChange FoldDisplayMode=' + foldDisplayMode);
        AppStorage.setOrCreate<number>('foldDisplayMode', foldDisplayMode);
        this.setIsNewFoldPhoneExternalScreen();
      })
    } catch (exception) {
      LogUtils.e(TAG, 'foldDisplayModeChange exp=' + JSON.stringify(exception));
    }
  }

  addWindowStatusListener(): void {
    let windowStatus = this.windowObj?.getWindowStatus() ?? 0;
    this.windowStatus = windowStatus;
    LogUtils.i(TAG, 'windowStatusChange windowStatusType init' + windowStatus);
    SplitScreenManager.getInstance().updateWindowStatusType(windowStatus);
    try {
      // Monitor window status change
      this.windowObj?.on('windowStatusChange', (windowStatusType) => {
        this.windowStatus = windowStatusType;
        SplitScreenManager.getInstance().updateWindowStatusType(windowStatusType);
      });
    } catch (err) {
      LogUtils.e(TAG, `windowStatusChange exp= ${JSON.stringify(err)}`);
    }
  }

  removeFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable() && !ExternalCallModel.isSmallExternalDevice()) {
      return;
    }
    try {
      display.off('foldStatusChange');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
  }

  sendBackOrForeEmitterMsg(type: string) {
    let event: emitter.InnerEvent = {
      eventId: emitterId,
      priority: emitter.EventPriority.HIGH
    };
    let exportData: emitter.EventData = {
      data: {
        type
      }
    }
    emitter.emit(event, exportData);
  }

  /**
   * 处理应用在手机与Visonglass上迁移的场景
   */
  private async visionGlassAppMigration(): Promise<void> {
    try {
      const currentDisplayId = this.windowObj?.getWindowProperties()?.displayId;
      if (currentDisplayId === undefined) {
        LogUtils.w(TAG, 'VisionGlassAppMigration: failed to obtain currentDisplayId.');
        return;
      }
      let displayId = await CallManagerService.getInstance().getVisionGlassDisplayId();
      if (!AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS)) {
        LogUtils.w(TAG, 'VisionGlass is not connected.');
        AppStorage.setOrCreate(VisionGlassConstants.SHOW_IN_VISION_GLASS, false);
        return;
      }
      if (currentDisplayId === 0) {
        AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, false);
        AppStorage.setOrCreate(VisionGlassConstants.SHOW_IN_VISION_GLASS, false);
        return;
      }
      // 应用是否显示在眼镜上
      let isDisplayOnGlass = (currentDisplayId === displayId);
      AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, isDisplayOnGlass);
      AppStorage.setOrCreate(VisionGlassConstants.SHOW_IN_VISION_GLASS, isDisplayOnGlass);
      // 不在眼镜上显示时固定窗口显示分辨率，在眼镜上显示时放开窗口显示分辨率限制
      let windowStage = this.context.windowStage;
      windowStage?.setDefaultDensityEnabled(!isDisplayOnGlass);
    } catch (error) {
      LogUtils.e(TAG, `getWindowProperties error: ${JSON.stringify(error)}`);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    this.visionGlassAppMigration();
    LogUtils.i(TAG, 'Ability onWindowStageCreate  fontSizeScale' + newConfig.fontSizeScale);
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    AppStorage.setOrCreate('language', newConfig.language);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    LogUtils.i(TAG, JSON.stringify(fontSizeScale) + ' Ability onWindowStageCreate  fontSizeScale1');
  }

  setIsNewFoldPhoneExternalScreen() {
    let isNewFoldPhoneExternalScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
    AppStorage.setOrCreate('isNewFoldPhoneExternalScreen', isNewFoldPhoneExternalScreen);
  }

  setIsNewFoldPhoneInnerScreenStatus(mainWindow: window.Window | undefined) {
    const isNewFoldPhoneInnerScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneInnerScreen();
    let isFullScreen = mainWindow?.getWindowStatus() === window.WindowStatusType.FULL_SCREEN;
    LogUtils.i(TAG, `isFullScreen:${isFullScreen}`);
    if (isFullScreen && isNewFoldPhoneInnerScreen) {
      // 新折叠全屏
      AppStorage.setOrCreate('isNewFoldPhoneInnerFullScreen', true);
    } else {
      // 新折叠全屏
      AppStorage.setOrCreate('isNewFoldPhoneInnerFullScreen', false);
    }
  }
};
