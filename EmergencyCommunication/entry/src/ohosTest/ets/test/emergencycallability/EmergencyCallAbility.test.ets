/**
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

import { describe, it, expect } from '@ohos/hypium';
import EmergencyCallAbility from '../../../../main/ets/emergencycallability/EmergencyCallAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import * as Constants from '../../../../main/ets/utils/Constants';

let emergencyCallAbility = new EmergencyCallAbility();

let want: Want = {};

let launchParam: AbilityConstant.LaunchParam = {
  launchReason: AbilityConstant.LaunchReason.UNKNOWN,
  lastExitReason: AbilityConstant.LastExitReason.UNKNOWN,
  lastExitMessage: ''
};

let EmergencyCallAbilityTest_onCreate = () => {
  emergencyCallAbility.onCreate(want, launchParam);
  expect(true).assertTrue();
}

let EmergencyCallAbilityTest_onNewWant = () => {
  emergencyCallAbility.onNewWant(want, launchParam);
  expect(true).assertTrue();
}

let EmergencyCallAbilityTest_onDestroy = () => {
  emergencyCallAbility.onDestroy();
  expect(true).assertTrue();
}

let EmergencyCallAbilityTest_onWindowStageCreate = () => {
  let windowStage = EmergencyGlobalContextHelper.getContext().getValue<window.WindowStage>(Constants.EMERGENCY_CALL_WINDOW_STAGE);
  emergencyCallAbility.onWindowStageCreate(windowStage);
  expect(true).assertTrue();
}

let EmergencyCallAbilityTest_onWindowStageDestroy = () => {
  emergencyCallAbility.onWindowStageDestroy();
  expect(true).assertTrue();
}

let EmergencyCallAbilityTest_onForeground = () => {
  emergencyCallAbility.onForeground();
  expect(true).assertTrue();
}

let EmergencyCallAbilityTest_onBackground = () => {
  emergencyCallAbility.onBackground();
  expect(true).assertTrue();
}

export default function EmergencyCallAbilityTest() {
  describe('EmergencyCallAbilityTest', () => {
    it('EmergencyCallAbilityTest_onCreate', 0, () => {
      EmergencyCallAbilityTest_onCreate();
    });
    it('EmergencyCallAbilityTest_onNewWant', 0, () => {
      EmergencyCallAbilityTest_onNewWant();
    });
    it('EmergencyCallAbilityTest_onDestroy', 0, () => {
      EmergencyCallAbilityTest_onDestroy();
    });
    it('EmergencyCallAbilityTest_onWindowStageDestroy', 0, () => {
      EmergencyCallAbilityTest_onWindowStageDestroy();
    });
    it('EmergencyCallAbilityTest_onBackground', 0, () => {
      EmergencyCallAbilityTest_onBackground();
    });
  })
}