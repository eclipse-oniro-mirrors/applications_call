/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';
import window from '@ohos.window';
import { LogUtil } from '../../../main/ets/util/LogUtil';
import { ContextUtils } from '../common/ContextUtils';

const TAG: string = 'TestAbility : ';

export default class TestAbility extends UIAbility {
  onCreate() {
    LogUtil.info(`${TAG} onCreate`);
    ContextUtils.setContext(this.context);
    let abilityDelegator: AbilityDelegatorRegistry.AbilityDelegator;
    abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    let abilityDelegatorArguments: AbilityDelegatorRegistry.AbilityDelegatorArgs;
    abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments();
    LogUtil.info(`${TAG} start run testcase`);
    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);
  }

  onDestroy() {
    LogUtil.info(`${TAG} onDestroy`);
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    LogUtil.info(`${TAG} onWindowStageCreate`);
    windowStage.loadContent('testability/pages/Index', (err, data) => {
      if (err.code) {
        LogUtil.error(`${TAG} Failed to load the content err : ${err.code}`);
        return;
      }
      LogUtil.info(`${TAG} Succeeded in loading the content data : ${data}`);
    });
  }

  onWindowStageDestroy() {
    LogUtil.info(`${TAG} onWindowStageDestroy`);
  }

  onForeground() {
    LogUtil.info(`${TAG} onForeground`);
  }

  onBackground() {
    LogUtil.info(`${TAG} onBackground`);
  }
}