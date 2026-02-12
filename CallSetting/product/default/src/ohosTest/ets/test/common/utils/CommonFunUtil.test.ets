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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import { getSystemRingtone } from '../../../../../main/ets/common/utils/CommonFunUtil';
import { getSystemRingtoneApi } from '../../../../../main/ets/common/model/SystemSoundManagerApi';
import sim from '@ohos.telephony.sim';
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import * as CallSettingsConstant from '../../../../../main/ets/common/constant/CallSettingsConstant';

export default function CommonFunUtilTest() {
  describe('CommonFunUtilTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })

    it('TestGetSystemRingtone_01', 0, () => {
      if (sim.getMaxSimCount()) {
        let slotId0: number = 0;
        let context = CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
        getSystemRingtone(context, slotId0, (ringName) => {
          expect(ringName).assertInstanceOf('String');
        })
        if (sim.getMaxSimCount() > 1) {
          let slotId1: number = 1;
          let context = CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
          getSystemRingtone(context, slotId1, (ringName) => {
            expect(ringName).assertInstanceOf('String');
          })
        }
      }
    })

    it('TestGetSystemRingtoneTest_02', 0, () => {
      if (sim.getMaxSimCount()) {
        let slotId0: number = 0;
        let context = CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
        let string = ' ';
        getSystemRingtone(context, slotId0, (ringName) => {
          getSystemRingtoneApi(context, slotId0, (data) => {
            string = data;
            let newStr: string = string.substring(0, string.lastIndexOf('.'));
            let lastSlashIndex: number = newStr.lastIndexOf('/');
            let result: string = newStr.substring(lastSlashIndex + 1);
            let newResult: string = result.split('_').join(' ');
            expect(ringName).assertEqual(newResult);
          })
        })
        if (sim.getMaxSimCount() > 1) {
          let slotId1: number = 1;
          let context = CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
          let string = ' ';
          getSystemRingtone(context, slotId1, (ringName) => {
            getSystemRingtoneApi(context, slotId1, (data) => {
              string = data;
              let newStr: string = string.substring(0, string.lastIndexOf('.'));
              let lastSlashIndex: number = newStr.lastIndexOf('/');
              let result: string = newStr.substring(lastSlashIndex + 1);
              let newResult: string = result.split('_').join(' ');
              expect(ringName).assertEqual(newResult);
            })
          })
        }
      }
    })
    it('TestGetSystemRingtoneTest_03', 0, () => {
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
      let slotId: number = 1;
      getSystemRingtone(context, slotId, ()=>{})
    })
  })
}
