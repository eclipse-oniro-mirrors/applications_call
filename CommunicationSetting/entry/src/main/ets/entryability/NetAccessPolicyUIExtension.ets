/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { FontScaleState } from '../util/fontScaleState';
import { LogUtil } from '../util/LogUtil';
import { Configuration } from '@ohos.app.ability.Configuration';

const TAG: string = 'NetAccessPolicyUIExtAbility'

export default class UIExtAbility extends UIExtensionAbility {
  onCreate() {
    LogUtil.log(TAG, `UIExtAbility onCreate`);
  }

  onForeground() {
    LogUtil.log(TAG, `UIExtAbility onForeground`);
  }

  onBackground() {
    LogUtil.log(TAG, `UIExtAbility onBackground`);
  }

  onDestroy() {
    LogUtil.log(TAG, `UIExtAbility onDestroy`);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    this.fetchSystemFontSizeScale();
    let storage: LocalStorage = new LocalStorage();
    let appUid: number = want.parameters?.appUid as number;
    storage.setOrCreate('session', session);
    storage.setOrCreate('appUid', appUid);
    session.loadContent('pages/NetAccessPolicyDiagPage', storage);
    session.setWindowBackgroundColor('#00000000');
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtil.log(TAG, `UIExtAbility onSessionDestroy`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    FontScaleState.updateAppFontGearSize(newConfig.fontSizeScale)
  }
  
  fetchSystemFontSizeScale(): void {
    let fontSizeScale = this.context.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }
};