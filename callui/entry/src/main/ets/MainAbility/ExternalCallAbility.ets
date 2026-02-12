/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { common } from '@kit.AbilityKit';
import { ExternalCallModel } from '../model/ExternalCallModel';
import CallDataManager from '../model/CallDataManager';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ExternalCallAbility';

export default class ExternalCallAbility extends Ability {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    LogUtils.i(TAG, 'onCreate');
    this.checkCallList();
    this.initAbilityParam();
  }

  private checkCallList(): void {
    if (CallDataManager.getInstance().callList.length === 0) {
      LogUtils.i(TAG, 'no calls. shut down ExternalCallAbility.');
      // this.context.terminateSelf().then(() => {
      //   LogUtils.i(TAG, 'terminateSelf success');
      // }, (err: BusinessError) => {
      //   LogUtils.i(TAG, `terminateSelf failed, code is ${err.code}, message is ${err.message}`);
      // });
      return;
    }
  }

  private initAbilityParam(): void {
    GlobalContextHelper.getContext().set<common.UIAbilityContext>(Constants.EXTERNAL_CALL_ABILITY_CONTEXT,
      this.context);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtils.i(TAG, 'onWindowStageCreate');
    windowStage.setShowOnLockScreen(true);
    windowStage.loadContent('pages/externalPages/ExternalCallPage', (err, data) => {
      if (err.code) {
        LogUtils.e(TAG, 'Failed to load the content. Cause:' + err.code);
        return;
      }
      LogUtils.i(TAG, 'Succeeded in loading the content. Data');
    });
    try {
      ExternalCallModel.getInstance().setExternalWindow(windowStage.getMainWindowSync());
    } catch (err) {
      LogUtils.e(TAG, `getMainWindowSync err:${err?.code} ${err?.message}`);
    }
  }

  onWindowStageDestroy(): void {
    LogUtils.i(TAG, 'onWindowStageDestroy');
  }

  onForeground() {
    LogUtils.i(TAG, 'onForeground');
    ExternalCallModel.getInstance().mIsExternalBackground = false;
  }

  onBackground() {
    LogUtils.i(TAG, 'onBackground');
    ExternalCallModel.getInstance().mIsExternalBackground = true;
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy');
    ExternalCallModel.getInstance().onExternalAbilityDestroy();
  }
};