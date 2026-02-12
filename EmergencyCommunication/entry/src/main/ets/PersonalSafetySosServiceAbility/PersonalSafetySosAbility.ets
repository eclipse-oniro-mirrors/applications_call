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
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import SOSEmergencyCallAbility from '../sosemergencycallability/SOSEmergencyCallAbility';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../utils/HiLog';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import { window } from '@kit.ArkUI';
import { CAR_ACCIDENT, FALL_DOWN } from '../utils/Constants'
import { PersonalSafetyAccidentType } from '../utils/ClassStruct'
import { ReportUtil } from '../utils/ReportUtil';
import { PersonalSafetyReportTriggerType } from '../data/CommonData'

const TAG = 'PersonalSafetySosServiceAbility';

const MOTION_TYPE_COLLISION = 3700;
const MOTION_TYPE_FALLDOWN = 3900;

export default class PersonalSafetySosServiceAbility extends UIAbility {
  private isSetKeepScreenOn: boolean = false;
  private personalSafetyAccidentType: PersonalSafetyAccidentType = 'none';

  private getBottomRectHeightWithVp(windowClass: window.Window) {
    const type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;
    const avoidArea = windowClass.getWindowAvoidArea(type);
    const bottomRectHeightWithVp = avoidArea?.bottomRect?.height ? px2vp(avoidArea.bottomRect.height) : 0;
    AppStorage.setOrCreate('bottomRectHeight', bottomRectHeightWithVp);
  }

  private getTopStatusBarHeightWithVp(windowClass: window.Window) {
    const type = window.AvoidAreaType.TYPE_SYSTEM;
    const avoidArea = windowClass.getWindowAvoidArea(type);
    const topStatusBarHeightWithVp = avoidArea?.topRect?.height ? px2vp(avoidArea.topRect.height) : 0;
    AppStorage.setOrCreate(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT, topStatusBarHeightWithVp);
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, `Ability onCreate`);
    let motionType: number = 0;
    let parameters = want?.parameters;
    if (parameters) {
      motionType = parameters['motionType']?.valueOf() as number;
    }
    LogUtils.i(TAG, `motionType: ${motionType}`);
    if (motionType === MOTION_TYPE_COLLISION) {
      this.personalSafetyAccidentType = CAR_ACCIDENT;
    } else if (motionType === MOTION_TYPE_FALLDOWN) {
      this.personalSafetyAccidentType = FALL_DOWN;
    }
  }

  onDestroy(): void {
    LogUtils.i(TAG, `Ability onDestroy`);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    LogUtils.i(TAG, `Ability onWindowStageCreate`);

    let mainWindow: window.Window;

    try {
      mainWindow = windowStage.getMainWindowSync();
      let systemBarProperties: window.SystemBarProperties = {
        statusBarColor: '#00000000',
        statusBarContentColor: '#ffffff',
      }
      mainWindow.setWindowSystemBarProperties(systemBarProperties);
    } catch (e) {
      LogUtils.e(TAG, ` get window and set properties error: ${JSON.stringify(e)}`);
    }
    windowStage.setDefaultDensityEnabled(true);
    windowStage.setShowOnLockScreen(true);

    EmergencyGlobalContextHelper.getContext()
      .set<window.WindowStage>(Constants.EMERGENCY_CALL_WINDOW_STAGE, windowStage);

    let storage: LocalStorage = new LocalStorage();
    if (this.personalSafetyAccidentType === CAR_ACCIDENT) {
      storage.setOrCreate(Constants.PERSONAL_SAFETY_ACCIDENT_TYPE, CAR_ACCIDENT);
      ReportUtil.getInstance().reportPersonalSafetyEnter(PersonalSafetyReportTriggerType.CRASH); // 触发类型：车祸
    } else if (this.personalSafetyAccidentType === FALL_DOWN) {
      storage.setOrCreate(Constants.PERSONAL_SAFETY_ACCIDENT_TYPE, FALL_DOWN);
      ReportUtil.getInstance().reportPersonalSafetyEnter(PersonalSafetyReportTriggerType.FALL); // 触发类型：跌倒
    }

    windowStage.loadContent('pages/SosEmergencyCall', storage, (err) => {
      try {
        mainWindow.setWindowBackgroundColor('#000000');
      } catch (exception) {
        LogUtils.e(TAG, 'Failed to set the background color.');
      }
      if (err.code) {
        LogUtils.e(TAG, ` Failed to load the content. Cause: ${JSON.stringify(err) ?? ''}`);
        return;
      }

      try {
        let windowClass: window.Window = windowStage.getMainWindowSync();
        windowClass.setWakeUpScreen(true);
        this.keepScreenOn(true);
        this.setWindowLayoutFullScreen(windowClass, true);
        this.getBottomRectHeightWithVp(windowClass);
        this.getTopStatusBarHeightWithVp(windowClass);
      } catch (e) {
        LogUtils.e(TAG, `set screen error: ${JSON.stringify(e)}`);
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    LogUtils.i(TAG, 'Ability onWindowStageDestroy');

    this.keepScreenOn(false);
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtils.i(TAG, 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    LogUtils.i(TAG, 'Ability onBackground');
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

  async keepScreenOn(status: boolean) {
    try {
      let windowClass = await window.getLastWindow(this.context) //获取窗口实例
      let keepScreenOn = await windowClass.getWindowProperties().isKeepScreenOn //查看屏幕常亮状态

      if (status === true && keepScreenOn === false) {
        this.isSetKeepScreenOn = true;
      } else if (status === false && this.isSetKeepScreenOn === true) {
        this.isSetKeepScreenOn = false;
      } else {
        return;
      }

      await windowClass.setWindowKeepScreenOn(status) //设置窗口常亮或取消
    } catch (e) {
      LogUtils.e(TAG, `keepScreenOn error: ${JSON.stringify(e)}`);
    }
  }
}
