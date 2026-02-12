/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import Ability from '@ohos.app.ability.UIAbility';
import LogUtils from '../common/utils/LogUtils';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import display from '@ohos.display';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import { BusinessError } from '@ohos.base';

const TAG = 'VoipAbility';

export default class VoipAbility extends Ability {
  private windowObj?: window.Window;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    LogUtils.i(TAG, 'onCreate');
    GlobalContextHelper.getContext().set<common.UIAbilityContext>(Constants.VOIP_ABILITY_CONTEXT, this.context);
    GlobalContextHelper.getContext().set<Want>(Constants.VOIP_ABILITY_WANT, want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    LogUtils.i(TAG, 'onWindowStageCreate');
    windowStage.setShowOnLockScreen(true);
    GlobalContextHelper.getContext().set<window.Window>(Constants.WINDOW, windowStage.getMainWindowSync());
    let sysBarProps: window.SystemBarProperties = {
      statusBarContentColor: '#ffffff'
    };
    GlobalContextHelper.getContext().getValue<window.Window>(Constants.WINDOW)?.
    setWindowSystemBarProperties(sysBarProps);
    windowStage.loadContent('pages/voipPage', (err, data) => {
      if (err.code) {
        LogUtils.e(TAG, 'Failed to load the content. Cause:' + err.code);
        return;
      }
      LogUtils.i(TAG, 'Succeeded in loading the content. Data');
    });
    windowStage.getMainWindow().then((windowObj) => {
      this.windowObj = windowObj;
      // Obtain the window size
      try {
        this.mCallColumnUtils.updateBreakpoint(windowObj.getWindowProperties().windowRect.width);
      } catch (error) {
        LogUtils.e(TAG, `Failed to getWindowProperties. Code: ${error?.code}, msg: ${error?.message}`);
      }
      // Monitor window size change
      windowObj.on('windowSizeChange', (windowSize)=>{
        this.mCallColumnUtils.updateBreakpoint(windowSize.width);
      });
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `Failed to getMainWindow. Code: ${err?.code}, msg: ${err?.message}`);
    })
    this.addFoldStatusListener();
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    LogUtils.i(TAG, 'onWindowStageDestroy');
    if (!this.windowObj) {
      return;
    }
    try {
      this.windowObj.off('windowSizeChange');
    } catch (exception) {
      LogUtils.e(TAG, 'windowSizeChange catch err:' + JSON.stringify(exception));
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtils.i(TAG, 'onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    LogUtils.i(TAG, 'onBackground');
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy');
    this.removeFoldStatusListener();
    let want: Want = {
      bundleName: '',
      abilityName: '',
      parameters: {
        'ability.params.backToOtherMissionStack': true,
      }
    };
    // clear want.
    GlobalContextHelper.getContext().set<Want>(Constants.VOIP_ABILITY_WANT, want);
  }

  addFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
      })
    } catch (exception) {
      LogUtils.e(TAG, 'foldStatusChange exp=' + JSON.stringify(exception));
    }
  }

  removeFoldStatusListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      display.off('foldStatusChange');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
  }
};
