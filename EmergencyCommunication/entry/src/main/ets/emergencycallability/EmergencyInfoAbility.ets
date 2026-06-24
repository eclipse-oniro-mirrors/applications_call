/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import LogUtils from '../utils/HiLog';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import common from '@ohos.app.ability.common';
import RestoreUtils from '../backup/RestoreUtils';
import CallColumnUtils from '../utils/CallColumnUtils';
import { FontScaleState } from '../utils/FontScaleState';
import { Configuration } from '@ohos.app.ability.Configuration';
import { display, uiExtensionHost, window } from '@kit.ArkUI';
import { DisplayUtil } from '../utils/DisplayUtil';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { PreferencesListenerUtil } from '../emergencydatashareextability/PreferencesListenerUtil';

const TAG = 'EmergencyInfoAbility';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class EmergencyInfoAbility extends UIExtensionAbility {
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private hostWindowProxy: uiExtensionHost.UIExtensionHostWindowProxy | undefined = undefined;
  private session?: UIExtensionContentSession;
  private extensionFlag: boolean = false;
  private foldChangeCallBack = async () => {
    try {
      await this.session?.terminateSelf();
      LogUtils.i(TAG, 'foldChangeCallBack terminateSelf success');
    } catch (e) {
      LogUtils.e(TAG, `foldChangeCallBack terminateSelfCallBack error: ${e?.code}: ${e?.message}`);
    }
  };
  private preferencesListenerUtil: PreferencesListenerUtil | null = null;

  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'EmergencyInfoAbility onCreate start');
    // start preference listener
    this.preferencesListenerUtil = PreferencesListenerUtil.getInstance();
    this.preferencesListenerUtil.startPreferenceListener(this.context);
  }

  async onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'EmergencyInfoAbility start');
    this.session = session;
    await RestoreUtils.getInstance().checkNeedContinueRestore(this.context);
    EmergencyGlobalContextHelper.getContext().
    set<common.UIExtensionContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT, this.context);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    let source: string = want.parameters?.source as string;
    let previousPage: string = want.parameters?.previousPage as string;
    LogUtils.i(TAG, `source: ${source}`)
    if (source && source === 'index' && previousPage == '') {
      localStorage.setOrCreate('extensionFlag', false);
      this.extensionFlag = false;
    } else {
      localStorage.setOrCreate('extensionFlag', true);
      this.extensionFlag = true;
    }
    session.loadContent('pages/EmergencyInfoView', localStorage);
    session.setWindowBackgroundColor(Color.Transparent.toString());
    let extensionWindow :ESObject= session?.getUIExtensionHostWindowProxy();
    let windowWidth :ESObject= extensionWindow.properties.uiExtensionHostWindowProxyRect.width;
    this.mCallColumnUtils.updateBreakpoint(windowWidth);
    this.adaptiveAging();
    extensionWindow.on('windowSizeChange', (windowSize:ESObject) => {
      LogUtils.i(TAG, 'windowSizeChanged');
      try {
        this.mCallColumnUtils.updateBreakpoint(windowSize.width);
      } catch (err) {
        LogUtils.e(TAG, `onWindowStageCreate err = ${JSON.stringify(err)}`);
      }
    });
    this.hostWindowProxy = extensionWindow;
    this.addAvoidAreaChangeLister();
    this.addFoldStatusListener();
  }

  addFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable() || !ScreenAdapterUtils.isNewFormFoldPhone()) {
      return;
    }
    if (this.extensionFlag) {
      LogUtils.i(TAG, 'extensionFlag is true, no need addFoldStatusListener');
      return;
    }
    try {
      display.on('foldStatusChange', this.foldChangeCallBack);
      LogUtils.i(TAG, 'addFoldStatusListener success');
    } catch (exception) {
      LogUtils.e(TAG, 'foldStatusChange exception = ' + JSON.stringify(exception));
    }
  }

  removeFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable() || !ScreenAdapterUtils.isNewFormFoldPhone()) {
      return;
    }
    if (this.extensionFlag) {
      LogUtils.i(TAG, 'extensionFlag is true, no need removeFoldStatusListener');
      return;
    }
    try {
      display.off('foldStatusChange', this.foldChangeCallBack);
      LogUtils.i(TAG, 'removeFoldStatusListener success');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, `UIExtAbility onSessionDestroy`);
    this.removeAvoidAreaChangeLister();
    this.removeFoldStatusListener();
  }

  onDestroy(): void | Promise<void> {
    LogUtils.i(TAG, 'EmergencyInfoAbility onDestroy start');
    // close preference listener
    this.preferencesListenerUtil?.processPreferenceListener();
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'onConfigurationUpdate' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    DisplayUtil.updateIsRtl();
  }

  private adaptiveAging() {
    let context = EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT);
    let fontSizeScale = context.config?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'adaptiveAging' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    DisplayUtil.updateIsRtl();
  }

  private addAvoidAreaChangeLister(): void {
    let avoidArea = this.hostWindowProxy?.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    let areaHeight = avoidArea?.bottomRect.height ?? 0;
    AppStorage.setOrCreate('navigationHeight', px2vp(areaHeight));
    try {
      // avoidAreaChange should be added before loading content!
      this.hostWindowProxy?.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        LogUtils.i(TAG, `avoidAreaChange type: ${data.type}`);
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          let height = data.area.bottomRect.height
          AppStorage.setOrCreate('navigationHeight', px2vp(height));
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `add avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private removeAvoidAreaChangeLister() {
    try {
      this.hostWindowProxy?.off('avoidAreaChange');
    } catch (err) {
      LogUtils.e(TAG, `off avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }
}