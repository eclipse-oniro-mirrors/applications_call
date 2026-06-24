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
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import CallSettingAbility from '../../../main/ets/callsettingability/CallSettingAbility';
import { ConfigurationConstant, Configuration, AbilityConstant } from '@kit.AbilityKit';
import Want from '@ohos.app.ability.Want';
import { DisplayUtil } from '../../../main/ets/common/utils/DisplayUtil';
import CallSettingUIExtAbility from '../../../main/ets/callsettingextability/CallSettingExtAbility';
import SatelliteUiExtentionAbility from '../../../main/ets/satelliteability/SatelliteUiExtentionAbility';

export default function CallSettingAbilityTest() {
  let mocker: MockKit = new MockKit();
  describe('CallSettingAbilityTest', () => {

    it('callsettingability_test', 0, () => {
      let callSettingAbility = new CallSettingAbility();
      let launchParam: AbilityConstant.LaunchParam = {
        launchReason: AbilityConstant.LaunchReason.UNKNOWN,
        lastExitReason: AbilityConstant.LastExitReason.UNKNOWN,
        lastExitMessage: ''
      }
      let emptyWant: Want = {};
      let want: Want = {
        uri: 'test'
      }
      let config: Configuration = {
        colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
      };
      callSettingAbility.setSystemBarProps();
      callSettingAbility.setSystemBarProps(config);
      callSettingAbility.setSystemBarProps();
      callSettingAbility.addWindowStatusListener();
      (callSettingAbility as object)['onConfigurationUpdate']();
      callSettingAbility.onConfigurationUpdate(config);
      (callSettingAbility as object)['adaptiveAging']();
      callSettingAbility.removeFoldStatusListener();
      callSettingAbility.onWindowStageDestroy();
      callSettingAbility.addFoldStatusListener();
      let mockFunc = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      callSettingAbility.addFoldStatusListener();
      callSettingAbility.removeFoldStatusListener();
      callSettingAbility.onNewWant(emptyWant, launchParam);
      callSettingAbility.onNewWant(want, launchParam);
      callSettingAbility.onCreate(emptyWant, launchParam);
      let result = callSettingAbility.onCreate(want, launchParam);
      mocker.ignoreMock(DisplayUtil, DisplayUtil.isFoldable);
      expect(result === null).assertFalse();
    })
    it('CallSettingExtAbility_test', 0, () => {
      let ex = new CallSettingUIExtAbility();
      let config: Configuration = {
        colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
      };
      let config1: Configuration = {
        colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
        language: 'Chinese'
      };
      let config2: Configuration = {
        colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
        language: 'English'
      };
      (ex as object)['onConfigurationUpdate']();
      let result = ex.onConfigurationUpdate(config);
      ex.onConfigurationUpdate(config1);
      ex.onConfigurationUpdate(config2);
      let sate = new SatelliteUiExtentionAbility();
      (sate as object)['addFoldStatusChangeListener']();
      (sate as object)['removeFoldStatusChangeListener']();
      (sate as object)['updateSatelliteNeedEndCallback']();
      let mockFunc = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      (sate as object)['addFoldStatusChangeListener']();
      (sate as object)['removeFoldStatusChangeListener']();
      (sate as object)['updateSatelliteNeedEndCallback']();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.isFoldable);
      expect(result === null).assertFalse();
    })
  })
}