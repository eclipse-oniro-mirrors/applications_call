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
import {
  AbilityConstant,
  common,
  Configuration,
  ConfigurationConstant,
  errorManager,
  StartOptions,
  UIAbility,
  Want
} from '@kit.AbilityKit';
import { Router, window } from '@kit.ArkUI';
import LogUtils from '../utils/HiLog';
import { BusinessError, screenLock } from '@kit.BasicServicesKit';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import { DisplayUtil } from '../utils/DisplayUtil';
import display from '@ohos.display';
import CallColumnUtils from '../utils/CallColumnUtils';
import { FontScaleState } from '../utils/FontScaleState';
import { VibratorUtil } from '../utils/VibratorUtil';
import { SosEmergencyCallController } from '../control/SosEmergencyCallController';
import { AudioUtil } from '../utils/AudioUtil';
import { SosEmergencySmsController } from '../control/SosEmergencySmsController';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { AudioPlayerService } from '../service/AudioPlayerService';
import { SMALL_EXTERNAL_DISPLAY_ID } from '../utils/Constants'
import { SystemModeController } from '../control/SystemModeController';
import { RESTORE_TIAN_TONG_SWITCH, SatelliteUtil } from '../utils/SatelliteUtil';
import CommonData from '../data/CommonData';
import LocationUtils from '../utils/LocationUtils';
import { EfficiencyResourcesController } from '../control/EfficiencyResourcesController';
import { ContactListStruct } from '../utils/ClassStruct';

const TAG = 'SOSEmergencyCallAbility';

/** SOSEmergencyCallAbility的当前窗口状态，前台或后台 */
export const ABILITY_STATE_KEY = 'SOSEmergencyCallAbility_abilityState';

/** SOSEmergencyCallAbility当前在前台 */
const ABILITY_STATE_ON_FOREGROUND = 'onForeground';

/** SOSEmergencyCallAbility当前在后台 */
export const ABILITY_STATE_ON_BACKGROUND = 'onBackground';

/** 申请CPU能效资源的原因 */
export const REASON_APPLY_EFFICIENCY_RESOURCES = 'clearSosEmergencyCall';
/** 申请CPU能效资源的申请者 */
export const APPLICANT_APPLY_EFFICIENCY_RESOURCES = 'SOSEmergencyCallAbility';

/** 蓬莱模式下SOSEmergencyCallAbility是否在初始化时成功锁屏  */
export const IS_LOCK_SUCCESS_IN_PENG_LAI = 'SOSEmergencyCallAbility_isLockSuccessInPenglai';

export default class SOSEmergencyCallAbility extends UIAbility {
  private uiContext: UIContext | undefined = undefined;
  private windowStage: window.WindowStage | null = null;
  private windowObj?: window.Window;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private lastColorMode: ConfigurationConstant.ColorMode | undefined = undefined;
  private audioUtil: AudioUtil = AudioUtil.getInstance();
  public static readonly KEY_IS_WINDOW_LAYOUT_FULL_SCREEN = 'SOSEmergencyCallAbility_isWindowLayoutFullScreen';
  public static readonly KEY_TOP_STATUS_BAR_HEIGHT = 'topStatusBarHeight';
  private errorManagerRegisterId: number = -1;
  private foldChangeCallBack = (foldStatus: display.FoldStatus) => {
    LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
    this.setIsNewFoldPhoneExternalScreen(this.windowObj as window.Window);
  };
  private timeOutIdOfReleaseSosEmergencyCall: number | null = null;
  /**
   * releaseDataAndAbortSosFunctions 方法是否正在运行
   */
  private isRunningOfReleaseDataAndAbortSosFunctions: boolean = false;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'Ability onCreate');
    this.catchJSCrashError();
    this.lockScreen();
    this.setGestureNavigationEnabled(false);
    this.handleExternalSosTips();
    SystemModeController.getInstance();
  }

  private handleExternalSosTips(): void {
    LogUtils.i(TAG, 'handleExternalSosTips');
    if (!ScreenAdapterUtils.isSmallExternalDeviceAndFoldStatus()) {
      return;
    }
    let wants: Want = {
      bundleName: 'com.ohos.emergencycommunication',
      abilityName: 'SosExternalAbility',
      parameters: {
        'ability.params.backToOtherMissionStack': true,
      }
    }
    let options: StartOptions = {
      displayId: SMALL_EXTERNAL_DISPLAY_ID
    };
    LogUtils.i(TAG, 'start SosExternalAbility begin');
    this.context?.startAbility(wants, options).then(() => {
      LogUtils.i(TAG, 'start SosExternalAbility done');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `startAbility failed, code is ${err.code}, message is ${err.message}`);
    });
  }

  private setGestureNavigationEnabled = (enable: boolean) => {
    LogUtils.i(TAG, `setGestureNavigationEnabled enable: ${enable}`);
    try {
      window.setGestureNavigationEnabled(enable).catch((e: BusinessError) => {
        LogUtils.e(TAG, `setGestureNavigationEnabled error: ${e?.code} ${e?.message}`)
      });
    } catch (e) {
      LogUtils.e(TAG, 'setGestureNavigationEnabled error: ' + JSON.stringify(e));
    }
  }
  private listenWindowStageEvent = (windowStage: window.WindowStage) => {
    try {
      windowStage.on('windowStageEvent', async (data) => {
        LogUtils.i(TAG, 'window stage event change');

        if (data === window.WindowStageEventType.SHOWN) {
          LogUtils.i(TAG, 'current window stage event is SHOWN');
        } else if (data === window.WindowStageEventType.HIDDEN) {
          LogUtils.i(TAG, 'current window stage event is HIDDEN');
        } else if (data === window.WindowStageEventType.PAUSED) {
          LogUtils.i(TAG, 'current window stage event is PAUSED');
          this.releaseDataAndAbortSosFunctions();
        } else if (data === window.WindowStageEventType.RESUMED) {
          releaseCpuResourcesFromSosEmergencyAbility();
          LogUtils.i(TAG, 'current window stage event is RESUMED');
          this.setGestureNavigationEnabled(false);
        }
      });
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to enable the listener for window stage event changes. Cause:' +
      JSON.stringify(exception));
    }
  }
  /**
   * 是否存在没有callId的SOS的通话
   */
  private isHasSosCallWithoutCallId = () => {
    try {
      const emergencyContacts = AppStorage.get<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY);
      if (!emergencyContacts || emergencyContacts.length === 0) {
        return false;
      }
      return emergencyContacts.some(item => Boolean(item?.callType === 'sosCall' && (typeof item.callId !== 'number')));
    } catch (e) {
      LogUtils.e(TAG, `isHasSosCallWithoutCallId error: ${e?.code} ${e?.message}`);
      return false;
    }
  }

  /**
   * 释放数据和中止SOS功能（倒计时3秒的震动、自动拨打求助电话功能、蜂鸣警报、自动发送求助信息功能）
   */
  private async releaseDataAndAbortSosFunctions() {
    if (this.isRunningOfReleaseDataAndAbortSosFunctions) {
      LogUtils.i(TAG, `releaseDataAndAbortSosFunctions is running`);
      return;
    }

    this.isRunningOfReleaseDataAndAbortSosFunctions = true;
    LogUtils.i(TAG, `releaseDataAndAbortSosFunctions start`);
    try {
      this.setGestureNavigationEnabled(true);
      if (!SosEmergencyCallController.getInstance().isDisplayCallUi) {
        LogUtils.i(TAG, `releaseDataAndAbortSosFunctions: not display call page`);
        const isHasSosCallWithoutCallId = this.isHasSosCallWithoutCallId();
        LogUtils.i(TAG, `releaseDataAndAbortSosFunctions: isHasSosCallWithoutCallId ${isHasSosCallWithoutCallId}`);
        if (isHasSosCallWithoutCallId) {
          EfficiencyResourcesController.applyCpuEfficiencyResources(10000,
            REASON_APPLY_EFFICIENCY_RESOURCES, APPLICANT_APPLY_EFFICIENCY_RESOURCES);
        }
        await SosEmergencyCallController.getInstance().resetEmergencyCall(this.context, !isHasSosCallWithoutCallId);
      }
      await this.audioUtil.recoverMediaVolume();
    } catch (e) {
      LogUtils.e(TAG, `releaseDataAndAbortSosFunctions error: ${e?.code} ${e?.message}`);
    }
    this.isRunningOfReleaseDataAndAbortSosFunctions = false;
    LogUtils.i(TAG, `releaseDataAndAbortSosFunctions end`);
  }

  private catchJSCrashError() {
    const callback: errorManager.ErrorObserver = {
      onUnhandledException: (errMsg) => {
        LogUtils.e(TAG, 'catchJSCrashError:onUnhandledException:' + errMsg);
      },
      onException: (errorObj) => {
        LogUtils.e(TAG, 'catchJSCrashError:onException:name: ' + errorObj?.name + ', message: ' + errorObj?.message);
      }
    }
    this.errorManagerRegisterId = errorManager.on('error', callback);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    LogUtils.i(TAG, 'Ability onWindowStageCreate');
    this.listenWindowStageEvent(windowStage);

    let currentColorMode = this.context?.config?.colorMode;
    AppStorage.setOrCreate('currentColorMode', currentColorMode);
    let systemBarProperties: window.SystemBarProperties = {
      statusBarContentColor: currentColorMode ? '#ff000000' : '#ffffffff',
    }
    let mainWindow: window.Window | undefined;
    try {
      mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowSystemBarProperties(systemBarProperties);
      this.registerAvoidAreaChange(mainWindow);
    } catch (businessError) {
      LogUtils.e(TAG, `get mainWindow error. Cause: ${businessError?.message}`);
    }
    windowStage.setDefaultDensityEnabled(true);

    this.windowStage = windowStage;
    windowStage.setShowOnLockScreen(true);
    EmergencyGlobalContextHelper.getContext()
      .set<window.WindowStage>(Constants.EMERGENCY_CALL_WINDOW_STAGE, windowStage);

    windowStage.loadContent('pages/SosEmergencyCall', (err, data) => {
      try {
        if (mainWindow) {
          mainWindow.setWindowBackgroundColor('#000000');
          this.setWindowLayoutFullScreen(mainWindow, true);
          this.getBottomRectHeightWithVp(mainWindow);
          this.getTopStatusBarHeightWithVp(mainWindow);
        }
      } catch (exception) {
        LogUtils.e(TAG, 'Failed to set the background color.');
      }
      if (err.code) {
        LogUtils.e(TAG, ` Failed to load the content. Cause: ${JSON.stringify(err) ?? ''}`);
        return;
      }
    });

    windowStage.getMainWindow().then((windowObj) => {
      this.windowObj = windowObj;
      this.uiContext = windowObj.getUIContext();
      try {
        // Obtain the window size
        AppStorage.setOrCreate('ratio'
          , windowObj.getWindowProperties().windowRect.width / windowObj.getWindowProperties().windowRect.height);
        this.mCallColumnUtils.updateBreakpoint(windowObj.getWindowProperties().windowRect.width);
      } catch (businessError) {
        LogUtils.e(TAG, `updateBreakpoint error. Cause: ${businessError?.message}`);
      }
      // Monitor window size change
      windowObj.on('windowSizeChange', (windowSize) => {
        AppStorage.setOrCreate('ratio', windowSize.width / windowSize.height);
        this.mCallColumnUtils.updateBreakpoint(windowSize.width);
      });
      this.setIsNewFoldPhoneExternalScreen(this.windowObj);
      this.addFoldStatusListener();
    }).catch((e: BusinessError<void>) => {
      LogUtils.e(TAG, `Failed to obtain the main window. Code is ${e?.code}, message is ${e?.message}`);
    });
  }

  private registerAvoidAreaChange(windowObj: window.Window): void {
    try {
      // avoidAreaChange should be added before loading content!
      windowObj.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          let heightVp = px2vp(data.area.topRect.height);
          if (heightVp !== AppStorage.get<number>(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT)) {
            LogUtils.i(TAG, 'KEY_TOP_STATUS_BAR_HEIGHT area changed! height = ' + heightVp);
            AppStorage.setOrCreate(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT, heightVp);
          }
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          let heightVp = px2vp(data.area.bottomRect.height);
          if (heightVp !== AppStorage.get<number>('bottomRectHeight')) {
            LogUtils.i(TAG, 'bottomRectHeight area changed! height = ' + heightVp);
            AppStorage.setOrCreate('bottomRectHeight', heightVp);
          }
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `register avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private getTopStatusBarHeightWithVp(windowClass: window.Window) {
    const type = window.AvoidAreaType.TYPE_SYSTEM;
    const avoidArea = windowClass.getWindowAvoidArea(type);
    const topStatusBarHeightWithVp = avoidArea?.topRect?.height ? px2vp(avoidArea.topRect.height) : 0;
    AppStorage.setOrCreate(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT, topStatusBarHeightWithVp);
  }

  private getBottomRectHeightWithVp(windowClass: window.Window) {
    const type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;
    const avoidArea = windowClass.getWindowAvoidArea(type);
    const bottomRectHeightWithVp = avoidArea?.bottomRect?.height ? px2vp(avoidArea.bottomRect.height) : 0;
    AppStorage.setOrCreate('bottomRectHeight', bottomRectHeightWithVp);
  }

  private async setWindowLayoutFullScreen(windowClass: window.Window, isLayoutFullScreen: boolean) {
    try {
      await windowClass.setWindowLayoutFullScreen(isLayoutFullScreen)
        .then(() => {
          LogUtils.i(TAG, 'Succeeded in setting the window layout to full-screen mode.');
          AppStorage.setOrCreate<boolean>(SOSEmergencyCallAbility.KEY_IS_WINDOW_LAYOUT_FULL_SCREEN, true);
        })
        .catch((err: BusinessError) => {
          LogUtils.e(TAG,
            `Failed to set the window layout to full-screen mode. Code is ${err.code}, message is ${err.message}`);
        });
    } catch (e) {
      LogUtils.e(TAG, `setWindowLayoutFullScreen error: ${JSON.stringify(e)}`);
    }
  }

  async onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    LogUtils.i(TAG, 'Ability onNewWant');
    let abilityState = AppStorage.get<string>(ABILITY_STATE_KEY);
    LogUtils.i(TAG, 'onNewWant: abilityState ' + abilityState);
    if (abilityState === ABILITY_STATE_ON_BACKGROUND && this.windowStage) {
      await SosEmergencyCallController.getInstance().resetEmergencyCall(this.context);
      if (SystemModeController.getInstance().getIsEnableSosOnSatelliteNet()) {
        AppStorage.setOrCreate<boolean>(IS_LOCK_SUCCESS_IN_PENG_LAI, false);
      }
      try {
        this.windowStage.loadContent('pages/SosEmergencyCall', (err, data) => {
          if (err?.code) {
            LogUtils.e(TAG, `onNewWant: failed to load the content. error: ${err.code} ${err.message}`);
            return;
          }
          SosEmergencyCallController.resetInstance();
          if (this.windowStage) {
            this.windowStage.setShowOnLockScreen(true);
          }
        });
      } catch (e) {
        LogUtils.e(TAG, `onNewWant: loadContent error: ${e?.code} ${e?.message}`);
      }
    }
  }

  async onWindowStageDestroy(): Promise<void> {
    // Main window is destroyed, release UI related resources
    LogUtils.i(TAG, 'Ability onWindowStageDestroy');
    AppStorage.delete('currentColorMode');
    AppStorage.delete('isNewFoldPhoneExternalScreen');
    if (!this.windowObj) {
      return;
    }
    await this.setWindowLayoutFullScreen(this.windowObj, false);
    this.removeFoldStatusListener();
    try {
      this.windowStage = null;
      this.windowObj.off('avoidAreaChange');
      this.windowObj.off('windowSizeChange');
    } catch (exception) {
      LogUtils.e(TAG, 'windowSizeChange catch err:' + JSON.stringify(exception));
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtils.i(TAG, 'Ability onForeground');
    releaseCpuResourcesFromSosEmergencyAbility();
    AppStorage.setOrCreate(ABILITY_STATE_KEY, ABILITY_STATE_ON_FOREGROUND);
    SosEmergencyCallController.getInstance().isDisplayCallUi = null;
    this.setGestureNavigationEnabled(false);
    this.setSystemBarProps();
    this.setWindowKeepScreenOn(true);
  }

  private async setWindowKeepScreenOn(isKeepScreenOn: boolean) {
    try {
      let windowClass: window.Window | undefined = this.windowObj;
      if (!windowClass) {
        if (!this.windowStage) {
          return;
        }
        windowClass = await this.windowStage.getMainWindow();
      }
      let promise = windowClass.setWindowKeepScreenOn(isKeepScreenOn);
      await promise.then(() => {
        LogUtils.i(TAG, 'Succeeded in setting the screen to be always on.');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `Failed to set the screen to be always on. Cause code: ${err.code}, message: ${err.message}`);
      });
    } catch (exception) {
      LogUtils.e(TAG,
        `Failed to set the screen to be always on. Cause code: ${exception.code}, message: ${exception.message}`);
    }
  }

  private async lockScreen() {
    try {
      if (!screenLock.isLocked()) {
        LogUtils.i(TAG, `lockScreen`);
        screenLock.lock().then((res) => {
          LogUtils.w(TAG, `lockScreen: result: ${res}`);
          if (res && SystemModeController.getInstance().getIsEnableSosOnSatelliteNet()) {
            AppStorage.setOrCreate(IS_LOCK_SUCCESS_IN_PENG_LAI, true);
          }
        }).catch((e: BusinessError) => {
          LogUtils.e(TAG, `lockScreen error: ${JSON.stringify(e)}`);
        });
      }
    } catch (e) {
      LogUtils.e(TAG, `lockScreen error: ${JSON.stringify(e)}`);
    }
  }

  async onBackground(): Promise<void> {
    // Ability has back to background
    LogUtils.i(TAG, 'Ability onBackground');
    AppStorage.setOrCreate(ABILITY_STATE_KEY, ABILITY_STATE_ON_BACKGROUND);
    this.releaseDataAndAbortSosFunctions();
    await this.setWindowKeepScreenOn(false);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    DisplayUtil.updateIsRtl();
    LogUtils.i(AppStorage.get('fontSizeScale') + '', 'Ability onWindowStageCreate  fontSizeScale1');
    this.setSystemBarProps(newConfig);
  }

  private releaseData = () => {
    SosEmergencyCallController.destroyInstance();
    SosEmergencySmsController.destroyInstance();
    AudioPlayerService.destroyInstance();
  }
  /**
   * 若紧急通信应用打开过天通卫星开关，退出时需要恢复天通卫星开关状态
   */
  private async restoreTianTongSwitch() {
    LogUtils.i(TAG, 'restoreTianTongSwitch');
    if (SosEmergencyCallController.getInstance().isTurnedOnTianTongSwitch) {
      let res = await SatelliteUtil.requestToCallSettingService(
        SatelliteUtil.getInstance().getProxyOfCallSettingServiceExtAbility(), RESTORE_TIAN_TONG_SWITCH, '');
      if (!res || res.code !== CommonData.int['SUCCESS']) {
        LogUtils.e(TAG, 'restoreTianTongSwitch: request RESTORE_TIAN_TONG_SWITCH failed');
        return;
      }
      SosEmergencyCallController.getInstance().isTurnedOnTianTongSwitch = false;
    }
  }

  async onDestroy(): Promise<void> {
    LogUtils.i(TAG, 'Ability onDestroy');
    this.setGestureNavigationEnabled(true);
    this.audioUtil.recoverMediaVolume();

    const ignoreLocationSwitch = AppStorage.get<boolean>(SosEmergencySmsController.IGNORE_LOCATION_SWITCH_KEY);
    if (ignoreLocationSwitch) {
      try {
        LocationUtils.getInstance().setLocationSwitchIgnored(false);
      } catch (e) {
        LogUtils.e(TAG, `onDestroy disableLocation error: ${JSON.stringify(e)}`);
      }
    }
    try {
      errorManager.off('error', this.errorManagerRegisterId)
        .catch((e: BusinessError) => {
          LogUtils.e(TAG, `onDestroy errorManager.off('error') error: ${JSON.stringify(e)}`);
        });
    } catch (e) {
      LogUtils.e(TAG, `onDestroy errorManager.off('error') error: ${JSON.stringify(e)}`);
    }
    if (SystemModeController.getInstance().getIsEnableSosOnSatelliteNet() &&
      SatelliteUtil.getInstance().getConnectIdOfCallSettingServiceExtAbility() !== null) {
      await this.releaseCallSettingSatelliteServiceData();
    }
    this.releaseData();
  }

  private releaseCallSettingSatelliteServiceData = async () => {
    if (SatelliteUtil.getInstance().getProxyOfCallSettingServiceExtAbility()) {
      let switchState = SatelliteUtil.getTianTongSatelliteSwitchState(this.context);
      LogUtils.i(TAG, 'releaseCallSettingSatelliteServiceData: tianTongSatelliteSwitchState: ' + switchState);
      if (switchState) {
        await this.restoreTianTongSwitch();
      }
    }
    SatelliteUtil.getInstance().disConnectCallSettingSatelliteServiceExtAbility(this.context);
  }

  public addFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      display.on('foldStatusChange', this.foldChangeCallBack);
    } catch (exception) {
      LogUtils.e(TAG, 'foldStatusChange exception = ' + JSON.stringify(exception));
    }
  }

  public setSystemBarProps(config?: Configuration) {
    LogUtils.i(TAG, 'setSystemBarProps start');
    let currentColorMode: ConfigurationConstant.ColorMode | undefined =
      config?.colorMode !== undefined ? Number(config.colorMode) : AppStorage.get('currentColorMode');
    if (this.lastColorMode === currentColorMode) {
      LogUtils.i(TAG, 'ColorMode has not changed.');
      return;
    }
    let systemBarProperties: window.SystemBarProperties = {
      statusBarContentColor: currentColorMode ? '#ff000000' : '#ffffffff',
    }
    this.lastColorMode = currentColorMode;
    AppStorage.setOrCreate('currentColorMode', currentColorMode);
    this.windowObj?.setWindowBackgroundColor(currentColorMode ? '#f2f3f5' : '#ff000000');
    this.windowObj?.setWindowSystemBarProperties(systemBarProperties);
  }

  public removeFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      display.off('foldStatusChange', this.foldChangeCallBack);
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
  }

  private setIsNewFoldPhoneExternalScreen(windowObj: window.Window) {
    if (!windowObj) {
      return;
    }
    let isNewFoldPhoneExternalScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
    AppStorage.setOrCreate('isNewFoldPhoneExternalScreen', isNewFoldPhoneExternalScreen);
  }
}

/**
 * 释放从SosEmergencyAbility申请的CPU能效资源
 * 申请的理由指定为 REASON_APPLY_EFFICIENCY_RESOURCES
 */
export const releaseCpuResourcesFromSosEmergencyAbility = () => {
  const isAppliedCpuEfficiencyResources = EfficiencyResourcesController.getInstance().getIsApplyCPU(
    REASON_APPLY_EFFICIENCY_RESOURCES, APPLICANT_APPLY_EFFICIENCY_RESOURCES);
  LogUtils.i(TAG, `reduceCpuEfficiencyResources: isAppliedCpuEfficiencyResources ${isAppliedCpuEfficiencyResources}`);
  if (isAppliedCpuEfficiencyResources) {
    EfficiencyResourcesController.reduceCpuEfficiencyResources(REASON_APPLY_EFFICIENCY_RESOURCES,
      APPLICANT_APPLY_EFFICIENCY_RESOURCES);
  }
}
