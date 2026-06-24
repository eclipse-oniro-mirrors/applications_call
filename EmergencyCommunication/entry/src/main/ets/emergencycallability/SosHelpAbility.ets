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
import { display, uiExtensionHost, window } from '@kit.ArkUI';
import EmergencyWarningPreferencesUtils from '../utils/EmergencyWarningPreferencesUtils';
import CallColumnUtils from '../utils/CallColumnUtils';
import { Configuration } from '@kit.AbilityKit';
import { FontScaleState } from '../utils/FontScaleState';
import { isTablet } from '../utils/DeviceTypeUtils';
//import { PafUiWidget } from '@hms-paf/ui-widget-base';
import { DisplayUtil } from '../utils/DisplayUtil';

const TAG = 'SosHelpAbility';
const IS_SEARCH_FROM_FOLD = 'from_search';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class SosHelpAbility extends UIExtensionAbility{
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | null = null;
  private foldChangeCallBack = (foldStatus: display.FoldStatus) => {
    LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
    AppStorage.setOrCreate<number>('searchFoldStatus', foldStatus);
  };
  onCreate() {
    LogUtils.i(TAG, `Ability onCreate`);
    EmergencyGlobalContextHelper.getContext()
      .set<common.UIExtensionContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT, this.context);
    EmergencyWarningPreferencesUtils.getInstance().loadEmergencyWarningInfoPreferences(this.context);
    FontScaleState.updateAppFontGearSize(this.context?.config?.fontSizeScale);
    DisplayUtil.updateIsRtl();
  }

  onConfigurationUpdate(newConfig: Configuration) {
    LogUtils.i(TAG, 'Ability onConfigurationUpdate');
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
  }

  onForeground() {
    LogUtils.i(TAG, `Ability onForeground`)
  }

  onBackground() {
    LogUtils.i(TAG, `Ability onBackground`)
  }

  onDestroy() {
    LogUtils.i(TAG, `Ability onDestroy`)
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'Ability onSessionCreate');
    try {
      let localStorage: LocalStorage = new LocalStorage({
        session: session,
      } as extensionProperties);
      session.loadContent('pages/SosEmergencyHelpSettings', localStorage);
    } catch (e) {
      LogUtils.e(TAG, 'build LocalStorage failed ' + JSON.stringify(e));
    }
    let windowProxy: uiExtensionHost.UIExtensionHostWindowProxy = session.getUIExtensionHostWindowProxy();
    //PafUiWidget.initWindowProxy(windowProxy, this.context);
    this.setSafeAreaInfo(session);
    session.setWindowBackgroundColor(Color.Transparent.toString());
    let extensionWindow = session?.getUIExtensionHostWindowProxy();
    let windowWidth = extensionWindow.properties.uiExtensionHostWindowProxyRect.width
    this.mCallColumnUtils.updateBreakpoint(windowWidth);
    try {
      let foldStatus = display.getFoldStatus()
      if (foldStatus !== 0 || isTablet()) {
        LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
        if (want.parameters && want.parameters.startReason === IS_SEARCH_FROM_FOLD) {
          LogUtils.i(TAG, 'Ability onSessionCreate is search from fold device');
          AppStorage.setOrCreate<Boolean>('hideArrow', true);
        } else {
          LogUtils.i(TAG, 'Ability onSessionCreate no need to hide');
          AppStorage.setOrCreate<Boolean>('hideArrow', false);
        }
        AppStorage.setOrCreate<number>('searchFoldStatus', display.getFoldStatus());
        display.on('foldStatusChange', this.foldChangeCallBack);
      }
    } catch (exception) {
      LogUtils.e(TAG, 'Failed code' + JSON.stringify(exception));
    }
  }

  setSafeAreaInfo(session: UIExtensionContentSession): void {
    LogUtils.i(TAG, `setSafeAreaInfo`);
    let extensionWindow = session.getUIExtensionHostWindowProxy();
    this.extensionWindow = extensionWindow;
    let statusBarHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
    let naviIndicatorHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      .bottomRect.height;
    AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    AppStorage.setOrCreate<number>('naviIndicatorHeight', px2vp(naviIndicatorHeight));
    AppStorage.setOrCreate('isFromExternal', true);
    AppStorage.setOrCreate('currentColorMode', this.context.config?.colorMode);
    AppStorage.setOrCreate('currentLanguage', this.context.config?.language);
    LogUtils.i(TAG, `statusBar : ${px2vp(statusBarHeight)}, naviBar : ${px2vp(naviIndicatorHeight)}`);
    this.addAvoidAreaChangeLister();
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, `Ability onSessionDestroy`);
    try {
      display.off('foldStatusChange', this.foldChangeCallBack);
    } catch (e) {
      LogUtils.e(TAG, 'display off foldStatusChange error:' + JSON.stringify(e));
    }
    this.removeAvoidAreaChangeLister();
  }

  private addAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        this.extensionWindow?.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
          LogUtils.i(TAG, `avoidAreaChange type: ${data.type}`);
          this.setWindowAvoidArea(data.type, data.area);
        });
      }
    } catch (err) {
      LogUtils.e(TAG, `add avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private setWindowAvoidArea(type: window.AvoidAreaType, area: window.AvoidArea) {
    if (type === window.AvoidAreaType.TYPE_SYSTEM) {
      let statusBarHeight = area.topRect.height;
      AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    }
  }

  private removeAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        this.extensionWindow?.off('avoidAreaChange');
      }
    } catch (err) {
      LogUtils.e(TAG, `remove avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }
}