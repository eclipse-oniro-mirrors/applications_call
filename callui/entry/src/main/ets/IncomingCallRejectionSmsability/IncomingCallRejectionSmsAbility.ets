/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import Want from '@ohos.app.ability.Want';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import * as Constants from '../common/utils/Constants';
import LogUtils from '../common/utils/LogUtils';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import display from '@ohos.display';
import { Configuration } from '@ohos.app.ability.Configuration';
import { FontScaleState } from '../common/utils/FontScaleState';
import { window } from '@kit.ArkUI';

const TAG = 'IncomingCallRejectionSmsAbility';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class IncomingCallRejectionSmsAbility extends UIExtensionAbility {
  private statusBarHeight: number = -1;

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    GlobalContextHelper.getContext()
      .set<common.UIExtensionContext>(Constants.CALL_SETTING_ABILITY_CONTEXT, this.context);
    this.adaptiveAging();
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    if (want?.parameters?.isFromExternal) {
      AppStorage.setOrCreate('isFromExternal', want?.parameters?.isFromExternal);
    }
    session.loadContent('pages/IncomingCallRejectionSms', localStorage);
    let extensionWindow = session?.getUIExtensionHostWindowProxy();
    let area = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    this.statusBarHeight = px2vp(area.topRect.height)
    AppStorage.setOrCreate<number>('statusBarHeight', this.statusBarHeight);
    try {
      AppStorage.setOrCreate('foldStatus', display.getFoldStatus());
    } catch (error) {
      LogUtils.e(TAG, 'Error in setting foldStatus');
    }
    try {
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
        AppStorage.setOrCreate('foldStatus', foldStatus);
      })
    } catch (exception) {
      LogUtils.e(TAG, 'Failed code' + JSON.stringify(exception));
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    AppStorage.setOrCreate('language', newConfig.language);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    LogUtils.i(AppStorage.get('fontSizeScale') + '', 'Ability onWindowStageCreate  fontSizeScale1');
  }

  private adaptiveAging() {
    let context = GlobalContextHelper.getContext().
    getValue<common.UIAbilityContext>(Constants.CALL_SETTING_ABILITY_CONTEXT);
    LogUtils.i(JSON.stringify(context.config?.fontSizeScale), 'Ability onWindowStageCreate  fontSizeScale2');
    let fontSizeScale = context.config?.fontSizeScale ?? 1;
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  onSessionDestroy() {
    LogUtils.i(TAG, 'onSessionDestroy');
    try {
      display.off('foldStatusChange');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister callback. Code: ' + JSON.stringify(exception));
    }
    AppStorage.delete('foldStatus');
  }
}
