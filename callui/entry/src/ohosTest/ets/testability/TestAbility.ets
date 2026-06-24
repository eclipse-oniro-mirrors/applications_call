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

import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import hilog from '@ohos.hilog';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import common from '@ohos.app.ability.common';
import { GlobalContextHelper } from '../../../main/ets/common/utils/GlobalContextHelper';
import * as Constants from '../../../main/ets/common/utils/Constants';

export default class TestAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onCreate');
    let abilityDelegator: AbilityDelegatorRegistry.AbilityDelegator;
    abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    let abilityDelegatorArguments: AbilityDelegatorRegistry.AbilityDelegatorArgs;
    abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments();

    GlobalContextHelper.getContext().set<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT, this.context);
    GlobalContextHelper.getContext().set(Constants.CALL_SERVICE_CONTEXT, this.context);
    GlobalContextHelper.getContext().set<common.Context>('BackupExtensionAbility', this.context);
    AppStorage.setOrCreate<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT, this.context);
    AppStorage.setOrCreate('testAbility', this.context);
    AppStorage.setOrCreate<common.Context>('BackupExtensionAbility', this.context);
    hilog.info(0x0000, 'testTag', '%{public}s', 'start run testcase!!!');
    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);
  }

  onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onDestroy');
    AppStorage.delete(Constants.CALL_ABILITY_CONTEXT);
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onWindowStageCreate');
    try {
      let mainWindow = windowStage.getMainWindowSync();
      GlobalContextHelper.getContext().set<window.Window>(Constants.WINDOW, mainWindow);
      AppStorage.setOrCreate('testWindow', mainWindow);
      windowStage.loadContent('testability/pages/Index', (err, data) => {
        if (err.code) {
          hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s',
          JSON.stringify(data) ?? '');
      });
      let width = mainWindow.getWindowProperties().windowRect.width;
      let height = mainWindow.getWindowProperties().windowRect.height;
      AppStorage.setOrCreate('windowSizeChangeMd', {
        width: width, height: height
      });
    } catch (err) {
      hilog.error(0x0000, 'testTag', 'Failed to load the content');
    }
  }

  onWindowStageDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onForeground');
  }

  onBackground() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onBackground');
  }
}