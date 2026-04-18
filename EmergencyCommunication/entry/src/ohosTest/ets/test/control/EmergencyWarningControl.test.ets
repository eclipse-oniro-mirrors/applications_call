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
import { describe, it, expect } from '@ohos/hypium'
import EmergencyWarningController from '../../../../main/ets/control/EmergencyWarningControl'
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper'
import { common } from '@kit.AbilityKit'
import * as Constants from '../../../../main/ets/utils/Constants';

export default function EmergencyWarningControlTest() {
  let context = EmergencyGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT);
  describe('EmergencyWarningControlTest', () => {
    it('EmergencyWarningControlTest_01', 0, async () => {
      let stance = EmergencyWarningController.getInstance();
      let r = await stance.readValueFromConfigJSON(context);
      expect(r === null).assertEqual(false);
    })
    it('EmergencyWarningControlTest_02', 0, async () => {
      let r = await EmergencyWarningController.requestDeniedLocationPermissions([], context);
      if (r === undefined) {
        expect(r).assertEqual(undefined);
      } else {
        expect(r).assertEqual([]);
      }
    })
    it('EmergencyWarningControlTest_03', 0, async () => {
      let r = await EmergencyWarningController.isNotificationEnabled();
      if (r) {
        expect(r).assertEqual(true);
      } else {
        expect(r).assertEqual(false);
      }
    })
    it('EmergencyWarningControlTest_04', 0, async () => {
      let r = EmergencyWarningController.getEarthquakeWarningNotificationText(context, 'test', 'test', 'test',
        $r('app.string.yes'));
      r = EmergencyWarningController.getEarthquakeWarningNotificationText(context, 'test', 'test', '',
        $r('app.string.yes'));
      expect(r).assertEqual('');
    })
  })
}