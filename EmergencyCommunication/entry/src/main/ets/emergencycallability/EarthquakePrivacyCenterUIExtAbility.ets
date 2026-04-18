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
import { display, uiExtensionHost, window } from '@kit.ArkUI';
import { Configuration } from '@ohos.app.ability.Configuration';
import CallColumnUtils from '../utils/CallColumnUtils';
import { ConfigurationConstant } from '@kit.AbilityKit';
//import { PafUiWidget } from '@hms-paf/ui-widget-base';
import { FontScaleState } from '../utils/FontScaleState';

const TAG = 'EmergencyEarthquakeAbility';
const IS_SEARCH_FROM_FOLD = ',isShowBack:false';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class EmergencyEarthquakeAbility extends UIExtensionAbility {

  onCreate() {
    LogUtils.i(TAG, `Ability onCreate`)
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

  onConfigurationUpdate(newConfig: Configuration) {
    LogUtils.i(TAG, 'Ability onConfigurationUpdate');
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'Ability onSessionCreate');
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    let isFromOOBE = false;
    if (want?.parameters) {
      isFromOOBE = want?.parameters['isFromOOBE'] as boolean;
      AppStorage.setOrCreate('isFromOOBE', isFromOOBE);
    }
    LogUtils.i(TAG, 'isFromOOBE: ' + isFromOOBE);
    if (isFromOOBE) {
      LogUtils.i(TAG, 'UIExtAbility onSessionCreate from OOBE');
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    }
    let fontSizeScale = this.context?.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    let windowProxy: uiExtensionHost.UIExtensionHostWindowProxy = session.getUIExtensionHostWindowProxy();
    //PafUiWidget.initWindowProxy(windowProxy, this.context);
    this.setSafeAreaInfo(session);
    session.loadContent('pages/EarthquakePrivacyCenterPage', localStorage);
    session.setWindowBackgroundColor(Color.Transparent.toString());
    AppStorage.setOrCreate('isFromExternal', true);
    AppStorage.setOrCreate('currentColorMode', this.context.config?.colorMode);
    AppStorage.setOrCreate('currentLanguage', this.context.config?.language);
    let extensionWindow = session.getUIExtensionHostWindowProxy();
    let windowWidth = extensionWindow.properties.uiExtensionHostWindowProxyRect.width
    let mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
    mCallColumnUtils.updateBreakpoint(windowWidth);
  }

  setSafeAreaInfo(session: UIExtensionContentSession): void {
    LogUtils.i(TAG, `setSafeAreaInfo`);
    let extensionWindow = session.getUIExtensionHostWindowProxy();
    let statusBarHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
    let naviIndicatorHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      .bottomRect.height;
    AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    AppStorage.setOrCreate<number>('naviIndicatorHeight', px2vp(naviIndicatorHeight));
    LogUtils.i(TAG, `statusBar : ${px2vp(statusBarHeight)}, naviBar : ${px2vp(naviIndicatorHeight)}`);
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, `Ability onSessionDestroy`);
    session.sendData({
      'action': 'exit'
    });
  }
}