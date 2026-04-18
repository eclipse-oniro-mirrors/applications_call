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
import { display, window } from '@kit.ArkUI';
import EmergencyWarningPreferencesUtils from '../utils/EmergencyWarningPreferencesUtils';
import EmergencyWarningController from '../control/EmergencyWarningControl';
import { Utils } from '../utils/Utils';
import OOBEStatementBaseUIExtAbility from '../base/ability/OOBEStatementBaseUIExtAbility';

const TAG = 'OobeStatementAbility';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class OobeStatementAbility extends OOBEStatementBaseUIExtAbility {
  onCreate() {
    LogUtils.i(TAG, `Ability onCreate`)
    EmergencyGlobalContextHelper.getContext()
      .set<common.UIExtensionContext>(Constants.EMERGENCY_EARTHQUAKE_ABILITY_CONTEXT, this.context);
    AppStorage.setOrCreate(Utils.EMERGENCY_WARNING_CURRENT_CONTEXT,
      Constants.EMERGENCY_EARTHQUAKE_ABILITY_CONTEXT);;
    EmergencyWarningController.getInstance().readValueFromConfigJSON(this.context);
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
    super.onSessionCreate(want, session);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    this.setSafeAreaInfo(session);
    session.loadContent('pages/permissionPage', localStorage);
    session.setWindowBackgroundColor(Color.Transparent.toString());
    try {
      AppStorage.setOrCreate('foldStatus', display.getFoldStatus());
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
        AppStorage.setOrCreate('foldStatus', foldStatus);
      })
    } catch (exception) {
      LogUtils.e(TAG, 'Failed code' + JSON.stringify(exception));
    }
  }

  setSafeAreaInfo(session: UIExtensionContentSession): void {
    LogUtils.i(TAG, `setSafeAreaInfo`);
    let extensionWindow:ESObject = session.getUIExtensionHostWindowProxy();
    let statusBarHeight:ESObject = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
    let naviIndicatorHeight :ESObject= extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      .bottomRect.height;
    AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    AppStorage.setOrCreate<number>('naviIndicatorHeight', px2vp(naviIndicatorHeight));
    LogUtils.i(TAG, `statusBar : ${px2vp(statusBarHeight)}, naviBar : ${px2vp(naviIndicatorHeight)}`);
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, `Ability onSessionDestroy`);
  }
}