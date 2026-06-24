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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import EmergencyWarningPreferencesUtils from '../../../../main/ets/utils/EmergencyWarningPreferencesUtils'
import { common } from '@kit.AbilityKit';
import { EMERGENCY_CALL_ABILITY_CONTEXT } from '../../../../main/ets/utils/Constants';

let emergencyWarningPreferencesUtils = EmergencyWarningPreferencesUtils.getInstance();
let context: Context;

export default function EmergencyWarningPreferencesUtilsTest() {
  describe('EmergencyWarningPreferencesUtilsTest', () => {
    beforeAll(() => {
      context = EmergencyGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(EMERGENCY_CALL_ABILITY_CONTEXT);
    })

    it('EmergencyWarningPreferencesUtilsTest_', 0, async () => {
      EmergencyWarningPreferencesUtils.getInstance();
      await emergencyWarningPreferencesUtils.loadEmergencyWarningInfoPreferences(context);
      await emergencyWarningPreferencesUtils.loadEmergencyWarningInfoPreferences(context, () => {
      });
      let result = await emergencyWarningPreferencesUtils.deleteAndFlushInPreferences('test');
      (emergencyWarningPreferencesUtils as object)['flushEmergencyWarningInfoPreferences']();
      expect(result === null).assertFalse();
    })
  })
}