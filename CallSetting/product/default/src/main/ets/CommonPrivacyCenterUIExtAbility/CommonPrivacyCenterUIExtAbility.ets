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
import { FontScaleState } from '../common/utils/FontScaleState';

const TAG = 'CommonPrivacyCenterUIExtAbility';

export default class CommonPrivacyCenterUIExtAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'UIExtAbility onSessionCreate');
    let callerBundleName = '';
    let abilityName: string | undefined = '';
    if (want?.parameters) {
      callerBundleName = want?.parameters['ohos.aafwk.param.callerBundleName'] as string;
      abilityName = want.abilityName;
    }
    LogUtils.i(TAG, 'callerBundleName: ' + callerBundleName);
    let isFromOOBE = false;
    if (want?.parameters) {
      isFromOOBE = want?.parameters['isFromOOBE'] as boolean;
    }
    LogUtils.i(TAG, 'isFromOOBE: ' + isFromOOBE);
    if (isFromOOBE) {
      LogUtils.i(TAG, 'UIExtAbility onSessionCreate from OOBE');
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    }
    let windowProxy: uiExtensionHost.UIExtensionHostWindowProxy = session.getUIExtensionHostWindowProxy();
    // PafUiWidget.initWindowProxy(windowProxy, this.context);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
      context: this.context
    } as extensionProperties);
    if (isFromOOBE) {
      let localPrivacyStatement = '';
      switch (abilityName) {
        case 'com.ohos.callsetting.PhonePrivacyCenterUIExtAbility':
          localPrivacyStatement = 'phone';
          break;
        case 'com.ohos.callsetting.SatellitePrivacyStatementUIExtAbility':
          localPrivacyStatement = 'satellite';
          break;
        case 'com.ohos.callsetting.NumberIdentityPrivacyCenterUIExtAbility':
          localPrivacyStatement = 'NumberIdentity';
          break;
        default:
          LogUtils.e(TAG, `abilityName Invalid.`);
          localPrivacyStatement = 'Invalid';
      }
      let fontSizeScale = this.context?.config?.fontSizeScale;
      FontScaleState.updateAppFontGearSize(fontSizeScale);
      AppStorage.setOrCreate('localPrivacyStatement', localPrivacyStatement);
      session.loadContent('pages/CommonPrivacyStatementOOBE', localStorage);
    } else {
      switch (abilityName) {
        case 'com.ohos.callsetting.PhonePrivacyCenterUIExtAbility':
          session.loadContent('pages/PhonePrivacyStatement', localStorage);
          break;
        case 'com.ohos.callsetting.SatellitePrivacyStatementUIExtAbility':
          session.loadContent('pages/SatelliteServicePrivacyStatement', localStorage);
          break;
        case 'com.ohos.callsetting.NumberIdentityPrivacyCenterUIExtAbility':
          session.loadContent('pages/NumberIdentityPrivacyStatement', localStorage);
          break;
        default:
          LogUtils.e(TAG, `session loadContent Invalid.`);
      }
    }
    session.setWindowBackgroundColor(Color.Transparent.toString());
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    AppStorage.setOrCreate('callerBundleName', callerBundleName);
    AppStorage.setOrCreate('currentLanguage', this.context.resourceManager.getConfigurationSync().locale);
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    try {
      session.sendData({
        'action': 'exit'
      });
    } catch (error) {
      LogUtils.e(TAG, `session.sendData fail, err: ${JSON.stringify(error)}`);
    }
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