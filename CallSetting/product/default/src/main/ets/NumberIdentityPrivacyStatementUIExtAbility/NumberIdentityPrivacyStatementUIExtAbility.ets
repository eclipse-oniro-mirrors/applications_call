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
import { LogUtils } from '@ohos/common/CommonIndex';
import { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { extensionProperties } from '../MainAbility/MainAbility';
import { uiExtensionHost } from '@kit.ArkUI';
// import { PafUiWidget } from '@hms-paf/ui-widget-base';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import CallSettingVM from '../viewModel/CallSettingVM';

const TAG = 'NumberIdentityPrivacyStatementUIExtAbility';

export default class NumberIdentityPrivacyStatementUIExtAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'UIExtAbility onSessionCreate');
    let callerBundleName = '';
    let isFromExternal = false;
    if (want?.parameters) {
      callerBundleName = want?.parameters['ohos.aafwk.param.callerBundleName'] as string;
      isFromExternal = want?.parameters['isFromExternal'] as boolean;
    }
    LogUtils.i(TAG, 'callerBundleName: ' + callerBundleName);
    if (callerBundleName === CallSettingsConstant.OOBE_BUNDLE_NAME) {
      LogUtils.i(TAG, 'UIExtAbility onSessionCreate from OOBE');
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    }
    let windowProxy: uiExtensionHost.UIExtensionHostWindowProxy = session.getUIExtensionHostWindowProxy();
    // PafUiWidget.initWindowProxy(windowProxy, this.context);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
      context: this.context
    } as extensionProperties);
    if (want?.parameters?.type === 'privacyStatement') {
      if (callerBundleName === CallSettingsConstant.OOBE_BUNDLE_NAME) {
        AppStorage.setOrCreate('localPrivacyStatement', 'NumberIdentity');
        session.loadContent('pages/CommonPrivacyStatementOOBE', localStorage);
      } else {
        session.loadContent('pages/NumberIdentityPrivacyStatement', localStorage);
      }
    } else {
      session.loadContent('pages/NumberIdentityPermissionStatement', localStorage);
    }
    session.setWindowBackgroundColor(Color.Transparent.toString());
    let fontSizeScale = this.context?.config?.fontSizeScale ?? 1;
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    AppStorage.setOrCreate('callerBundleName', callerBundleName);
    AppStorage.setOrCreate('currentLanguage', this.context.resourceManager.getConfigurationSync().locale);
    CallSettingVM.getInstance().setIsFromExternal(isFromExternal);
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    LogUtils.i(TAG, `UIExtAbility onSessionDestroy`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtils.i(TAG, `UIExtAbility onConfigurationUpdate`);
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
  }

  onDestroy(): void | Promise<void> {
    LogUtils.i(TAG, `UIExtAbility onDestroy`);
  }
}