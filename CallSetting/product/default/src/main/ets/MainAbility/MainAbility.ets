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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import { LogUtils, MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import display from '@ohos.display';
import { uiExtensionHost, window } from '@kit.ArkUI';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { Configuration } from '@ohos.app.ability.Configuration';
import { FontScaleState } from '../common/utils/FontScaleState';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { emitter } from '@kit.BasicServicesKit';
import { EMIT_GET_RINGTONE_EVENT_ID } from '../common/constant/CallSettingsConstant';

const TAG = 'MainAbility';
const SESSION_CREATE_TASK_ID = 1001;

export interface extensionProperties {
  session?: UIExtensionContentSession;
  context?: common.UIExtensionContext;
}

export default class MainAbility extends UIExtensionAbility {
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | null = null;

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'onSessionCreate');
    hiTraceMeter.startTrace('onSessionCreate', SESSION_CREATE_TASK_ID);
    MobileDataGlobalContextHelper.getContext().
      set<common.UIExtensionContext>(Constants.SETTINGS_ABILITY_CONTEXT, this.context);
    let startReason: string = (want?.parameters?.['startReason'] ?? '') as string;
    AppStorage.setOrCreate('startReason', startReason);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    session.loadContent('pages/MobileDataIndex', localStorage);

    this.adaptiveAging();
    if (DisplayUtil.isFoldable()) {
      // try {
      //   display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
      //     LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
      //     AppStorage.setOrCreate('foldStatus', foldStatus);
      //   })
      // } catch (exception) {
      //   LogUtils.e(TAG, 'Failed code' + JSON.stringify(exception));
      // }
    }
    let extensionWindow = session?.getUIExtensionHostWindowProxy();
    this.extensionWindow = extensionWindow;
    this.addAvoidAreaChangeLister();

    try {
      this.mCallColumnUtils.updateBreakpoint(-1);
      extensionWindow.on('windowSizeChange', (windowSize) => {
        try {
          this.mCallColumnUtils.updateBreakpoint(-1);
        } catch (err) {
          LogUtils.e(TAG, `onWindowStageCreate err = ${JSON.stringify(err)}`);
        }
      });
      // AppStorage.setOrCreate('foldStatus', display.getFoldStatus());
      hiTraceMeter.finishTrace('onSessionCreate', SESSION_CREATE_TASK_ID);
    } catch (err) {
      LogUtils.e(TAG, `onSessionCreate err = ${JSON.stringify(err)}`);
    }
  }

  onForeground(): void {
    LogUtils.i(TAG, 'onForeground');
    emitter.emit({ eventId: EMIT_GET_RINGTONE_EVENT_ID });
  }

  onSessionDestroy() {
    LogUtils.i(TAG, 'onSessionDestroy');
    if (DisplayUtil.isFoldable()) {
      try {
        // display.off('foldStatusChange');
      } catch (exception) {
        LogUtils.e(TAG, 'Failed to unregister callback. Code: ' + JSON.stringify(exception));
      }
    }
    AppStorage.delete('foldStatus');
    this.removeAvoidAreaChangeLister();
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'onConfigurationUpdate' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private adaptiveAging() {
    let context = MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
    let fontSizeScale = context.config?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'adaptiveAging' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private addAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        let area = this.extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        this.setWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM, area);
        this.extensionWindow?.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
          LogUtils.i(TAG, `avoidAreaChange type: ${data.type}`);
          this.setWindowAvoidArea(data.type, data.area);
        });
      }
    } catch (err) {
      LogUtils.e(TAG, `add avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private setWindowAvoidArea(type: window.AvoidAreaType, area: window.AvoidArea) {
    if (type === window.AvoidAreaType.TYPE_SYSTEM) {
      let statusBarHeight = area.topRect.height;
      LogUtils.i(TAG, `avoidAreaChange statusBarHeight: ${px2vp(statusBarHeight)}`);
      AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    }
  }

  private removeAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        this.extensionWindow?.off('avoidAreaChange');
      }
    } catch (err) {
      LogUtils.e(TAG, `remove avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }
}
