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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium'
import SOSEmergencyCallAbility from '../../../main/ets/sosemergencycallability/SOSEmergencyCallAbility';
import { AbilityConstant, common, Configuration, Want } from '@kit.AbilityKit';
import { EmergencyGlobalContextHelper } from '../../../main/ets/utils/EmergencyGlobalContextHelper';
import { EMERGENCY_CALL_ABILITY_CONTEXT } from '../../../main/ets/utils/Constants';
import { window } from '@kit.ArkUI';
import { DisplayUtil } from '../../../main/ets/utils/DisplayUtil';

let ability = new SOSEmergencyCallAbility();

export default function SOSEmergencyCallAbilityTest() {
  describe('SOSEmergencyCallAbilityTest', () => {
    it('SOSEmergencyCallAbilityTest', 0, async () => {
      let launchParam: AbilityConstant.LaunchParam = {
        launchReason: AbilityConstant.LaunchReason.UNKNOWN,
        lastExitReason: AbilityConstant.LastExitReason.UNKNOWN,
        lastExitMessage: ''
      };
      let want: Want = {};
      ability.onNewWant(want, launchParam);
      let windowStage = AppStorage.get<window.WindowStage>('windowStage') as window.WindowStage;
      (ability as object)['listenWindowStageEvent'](windowStage);
      ability.onWindowStageCreate(windowStage);
      await ability.onForeground();
      await ability.onWindowStageDestroy();
      ability.addFoldStatusListener();
      ability.setSystemBarProps();
      ability.removeFoldStatusListener();
      let config: Configuration = {
        colorMode: 1,
        fontSizeScale: 1
      };
      let config1: Configuration = {};
      ability.onConfigurationUpdate(config);
      ability.onConfigurationUpdate(config1);
      ability.setSystemBarProps(config);
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      ability.addFoldStatusListener();
      await ability.onDestroy();
      ability.removeFoldStatusListener();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.isFoldable);
    })
  })
}