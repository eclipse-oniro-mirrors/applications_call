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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import { PushParam } from '../constants/CommonConstants';
import window from '@ohos.window';
import { LogUtil } from '../util/LogUtil';
import { GlobalContext } from './CommunicationSettingAbility';
import { FontScaleState } from '../util/fontScaleState';
import { Configuration } from '@ohos.app.ability.Configuration';
import { BusinessError } from '@kit.BasicServicesKit';
import { AccessibilityUtils } from '../util/AccessibilityUtils';

const TAG: string = 'ConnectionExtAbility';

export default class ConnectionExtAbility extends UIExtensionAbility {
  onCreate() {
    LogUtil.log(TAG, `onCreate`);
    GlobalContext.getContext().setObject('rankPageContext', this.context);
    AccessibilityUtils.addAccessibilityStateChangeListener();
  }

  onForeground() {
    LogUtil.log(TAG, `onForeground`);
    AccessibilityUtils.getAccessibilitySwitchState();
  }

  onBackground() {
    LogUtil.log(TAG, `onBackground`);
  }

  onDestroy() {
    LogUtil.log(TAG, `onDestroy`);
    AccessibilityUtils.releaseAccessibility();
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtil.log(TAG, `onSessionCreate`);
    this.fetchSystemFontSizeScale();
    this.setColorModeProps(this.context.config);
    let storage: LocalStorage = new LocalStorage();
    let pushParam = want?.parameters?.pushParams as PushParam;
    storage.setOrCreate('session', session);
    let bundleName = pushParam?.bundleName as string;
    if (bundleName) {
      AppStorage.setOrCreate('bundleName', pushParam.bundleName);
    }
    let uid = pushParam?.uid as number;
    if (uid) {
      AppStorage.setOrCreate('uid', pushParam.uid);
    }
    this.setSafeAreaInfo(session);
    session.loadContent('pages/SingleAppPage', storage);
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtil.log(TAG, `onSessionDestroy`);
    try {
      let extensionWindow = session.getUIExtensionHostWindowProxy();
      if (extensionWindow) {
        extensionWindow.off('avoidAreaChange');
      }
    } catch (err) {
      LogUtil.error(TAG,
        'off avoidAreaChange errCode: ' + (err as BusinessError).code + ' ,msg: ' + (err as BusinessError).message);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    FontScaleState.updateAppFontGearSize(newConfig.fontSizeScale);
    this.setColorModeProps(newConfig);
  }

  private areaChangeCallBack = (): void => {
    let storage = LocalStorage.getShared();
    let session: UIExtensionContentSession | undefined = storage.get('session');
    if (session) {
      try {
        let extensionWindow = session.getUIExtensionHostWindowProxy();
        // 状态栏高度
        let statusBarHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
        AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
        LogUtil.info(TAG, 'areaChangeCallBack statusBarHeight: ' + px2vp(statusBarHeight));
      } catch (err) {
        LogUtil.error(TAG,
          'areaChangeCallBack errCode: ' + (err as BusinessError).code + ' ,msg: ' + (err as BusinessError).message);
      }
    }
  }

  setSafeAreaInfo(session: UIExtensionContentSession): void {
    LogUtil.info(TAG, `setSafeAreaInfo`);
    let extensionWindow = session.getUIExtensionHostWindowProxy();

    // 状态栏高度
    let statusBarHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;

    // 导航条高度
    let naviIndicatorHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      .bottomRect.height;
    AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    AppStorage.setOrCreate<number>('naviIndicatorHeight', px2vp(naviIndicatorHeight));
    LogUtil.info(TAG, `statusBar : ${px2vp(statusBarHeight)}, naviBar : ${px2vp(naviIndicatorHeight)}`);
    try {
      extensionWindow.on('avoidAreaChange', this.areaChangeCallBack);
    } catch (err) {
      LogUtil.error(TAG,
        'on avoidAreaChange errCode: ' + (err as BusinessError).code + ' ,msg: ' + (err as BusinessError).message);
    }
  }

  fetchSystemFontSizeScale(): void {
    let fontSizeScale = this.context.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  setColorModeProps(config?: Configuration) {
    let newColorMode = config?.colorMode !== undefined ? config?.colorMode : AppStorage.get<number>('currentColorMode');
    let currentColorMode = AppStorage.get<number>('currentColorMode');
    if (newColorMode === currentColorMode) {
      LogUtil.info(TAG, 'ColorMode has not changed.');
      return;
    }
    AppStorage.setOrCreate('currentColorMode', newColorMode);
  }
};