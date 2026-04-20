/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import common from '@ohos.app.ability.common';
import LogUtils from '../common/utils/LogUtils';
import { Constant } from '../common/constant/Constant';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { Configuration } from '@ohos.app.ability.Configuration';
import { FontScaleState } from '../common/utils/FontScaleState'
import { display, window } from '@kit.ArkUI';
import CallRecorderColumnUtils from '../common/utils/CallRecorderColumnUtils';
//import { PafUiWidget } from '@hms-paf/ui-widget-base';

const TAG = 'CallRecorderSettingAbility';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class CallRecorderExtensionAbility extends UIExtensionAbility {
  private statusBarHeight: number = -1;
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'CallRecorderExtensionAbility start');
    GlobalContextHelper.getContext()
      .set<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT, this.context);
    let fontSizeScale = this.context.config?.fontSizeScale ?? 1;
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    LogUtils.i(TAG, 'onSessionCreate' + fontSizeScale);
    if (want?.parameters?.isFromExternal) {
      AppStorage.setOrCreate('isFromExternal', want?.parameters?.isFromExternal);
    }
    FontScaleState.updateAppFontGearSize(fontSizeScale);
    let param: Record<string, UIExtensionContentSession> = {
      'session': session
    };
    let storage: LocalStorage = new LocalStorage(param);
    AppStorage.setOrCreate('session', session);
    session.loadContent('pages/Index', storage);
    let extensionWindow = session?.getUIExtensionHostWindowProxy();
    let area = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    this.statusBarHeight = px2vp(area.topRect.height)
    //PafUiWidget.initWindowProxy(extensionWindow, this.context);
    AppStorage.setOrCreate<number>('statusBarHeight', this.statusBarHeight);
    try {
      let displayWidth = display.getDefaultDisplaySync().width;
      CallRecorderColumnUtils.getInstance().updateBreakpoint(displayWidth);
    } catch (error) {
      LogUtils.e(TAG, 'Error getting default display width');
    }
    extensionWindow.on('windowSizeChange', (windowSize) => {
      try {
        CallRecorderColumnUtils.getInstance().updateBreakpoint(windowSize.width);
      } catch (err) {
        LogUtils.e(TAG, `onWindowStageCreate err = ${JSON.stringify(err)}`);
      }
    });
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, `UIExtAbility onSessionDestroy`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    LogUtils.i(TAG, 'onConfigurationUpdate' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }
}
