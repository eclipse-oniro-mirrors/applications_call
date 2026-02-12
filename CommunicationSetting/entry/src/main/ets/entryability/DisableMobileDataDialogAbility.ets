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
import { FontScaleState } from '../util/fontScaleState';
import { LogUtil } from '../util/LogUtil';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration';
import { SimManager } from '../util/SimManager';

const TAG = 'DisableMobileDataDialogAbility';

export default class DisableMobileDataDialogAbility extends UIExtensionAbility {
  onCreate() {
    LogUtil.log(TAG, `DisableMobileDataDialogAbility onCreate`);
  }

  onForeground() {
    LogUtil.log(TAG, `DisableMobileDataDialogAbility onForeground`);
  }

  onBackground() {
    LogUtil.log(TAG, `DisableMobileDataDialogAbility onBackground`);
  }

  onDestroy() {
    LogUtil.log(TAG, `DisableMobileDataDialogAbility onDestroy`);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    this.fetchSystemFontSizeScale();
    SimManager.getInstance().init();
    let storage: LocalStorage = new LocalStorage();
    let slotId: number = want.parameters?.['slotId'] as number;
    storage.setOrCreate('session', session);
    storage.setOrCreate('slotId', slotId);
    session.loadContent('pages/DisableMobileDataDialogPage', storage);
    session.setWindowBackgroundColor('#00000000');
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    SimManager.getInstance().destroy();
    LogUtil.log(TAG, `DisableMobileDataDialogAbility onSessionDestroy`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    FontScaleState.updateAppFontGearSize(newConfig.fontSizeScale)
  }

  fetchSystemFontSizeScale(): void {
    let fontSizeScale = this.context.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }
}