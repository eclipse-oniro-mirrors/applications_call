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
import { display, window } from '@kit.ArkUI';
const TAG = 'OobeEmergencyAbilityPrivacy';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class OobeEmergencyAbilityPrivacy extends UIExtensionAbility {
  private foldChangeCallBack = (foldStatus: display.FoldStatus) => {
    LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
    AppStorage.setOrCreate('foldStatus', foldStatus);
  };
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

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'Ability onSessionCreate');
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    this.setSafeAreaInfo(session);
    session.loadContent('pages/EmergencyPrivacyPage', localStorage);
    session.setWindowBackgroundColor(Color.Transparent.toString());
    try {
      AppStorage.setOrCreate('foldStatus', display.getFoldStatus());
      display.on('foldStatusChange', this.foldChangeCallBack);
    } catch (exception) {
      LogUtils.e(TAG, 'Failed code' + JSON.stringify(exception));
    }
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
    try {
      display.off('foldStatusChange', this.foldChangeCallBack);
    } catch (exception) {
      LogUtils.e(TAG, 'Failed code' + JSON.stringify(exception));
    }
  }
}