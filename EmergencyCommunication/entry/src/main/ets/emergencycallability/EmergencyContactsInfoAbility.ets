/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { errorManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import { Configuration } from '@ohos.app.ability.Configuration';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import LogUtils from '../utils/HiLog';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import CallColumnUtils from '../utils/CallColumnUtils';
import { FontScaleState } from '../utils/FontScaleState';
import { DisplayUtil } from '../utils/DisplayUtil';
import { PreferencesListenerUtil } from '../emergencydatashareextability/PreferencesListenerUtil';
import { extensionProperties } from './EarthquakePrivacyCenterUIExtAbility';
import { uiExtensionHost, window } from '@kit.ArkUI';

const TAG = 'EmergencyContactsInfoAbility';

export default class EmergencyContactsInfoAbility extends UIExtensionAbility {
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private preferencesListenerUtil: PreferencesListenerUtil | null = null;
  private errorManagerRegisterId: number = -1;
  private extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | null = null;

  onCreate(): void {
    LogUtils.i(TAG, 'onCreate');
    this.catchJSCrashError();
    // start preference listener
    this.preferencesListenerUtil = PreferencesListenerUtil.getInstance();
    this.preferencesListenerUtil.startPreferenceListener(this.context);
  }

  async onSessionCreate(want: Want, session: UIExtensionContentSession) {
    try {
      EmergencyGlobalContextHelper.getContext()
        .set<common.UIExtensionContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT, this.context);
      let localStorage: LocalStorage = new LocalStorage({ session: session } as extensionProperties);
      localStorage.setOrCreate('extensionFlag', true);
      session.loadContent('pages/WrappedEmergencyContactsInfo', localStorage);
      session.setWindowBackgroundColor(Color.Transparent.toString());
      this.extensionWindow = session?.getUIExtensionHostWindowProxy();
      let windowWidth = this.extensionWindow?.properties.uiExtensionHostWindowProxyRect.width ?? 0;
      this.mCallColumnUtils.updateBreakpoint(windowWidth);
      this.adaptiveAging();
      this.setWindowSizeChangeListener();
    } catch (e) {
      LogUtils.e(TAG, `onSessionCreate err = ${e?.code} ${e?.message}`);
    }
  }

  private onWindowSizeChange = (windowSize: window.Size) => {
    LogUtils.i(TAG, 'setWindowSizeChangeListener: windowSizeChange');
    this.mCallColumnUtils.updateBreakpoint(windowSize.width);
  }
  private setWindowSizeChangeListener = () => {
    try {
      this.extensionWindow?.on('windowSizeChange', this.onWindowSizeChange);
    } catch (e) {
      LogUtils.e(TAG, `setWindowSizeChangeListener err = ${e?.code} ${e?.message}`);
    }
  }
  private cancelWindowSizeChangeListener = () => {
    try {
      this.extensionWindow?.off('windowSizeChange', this.onWindowSizeChange);
    } catch (e) {
      LogUtils.e(TAG, `cancelWindowSizeChangeListener err = ${e?.code} ${e?.message}`);
    }
  }

  private adaptiveAging() {
    LogUtils.i(TAG, 'onSessionCreate fontSizeScale: ' + this.context.config?.fontSizeScale);
    let fontSizeScale = this.context.config?.fontSizeScale ?? 1;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    DisplayUtil.updateIsRtl();
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, `onSessionDestroy`);
    this.cancelWindowSizeChangeListener();
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtils.i(TAG, `onConfigurationUpdate`);
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    LogUtils.i(TAG, 'onConfigurationUpdate fontSizeScale: ' + AppStorage.get<number>('fontSizeScale'));
    DisplayUtil.updateIsRtl();
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

  onDestroy(): void | Promise<void> {
    LogUtils.i(TAG, `onDestroy`);
    // close preference listener
    this.preferencesListenerUtil?.processPreferenceListener();
    try {
      errorManager.off('error', this.errorManagerRegisterId)
        .catch((e: BusinessError) => {
          LogUtils.e(TAG, `onDestroy errorManager.off('error') error: ${e?.code} ${e?.message}`);
        });
    } catch (e) {
      LogUtils.e(TAG, `onDestroy errorManager.off('error') error: ${e?.code} ${e?.message}`);
    }
  }
}