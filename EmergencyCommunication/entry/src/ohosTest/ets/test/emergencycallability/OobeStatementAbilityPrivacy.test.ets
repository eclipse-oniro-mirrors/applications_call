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
import OobeStatementAbilityPrivacy from '../../../../main/ets/emergencycallability/OobeStatementAbilityPrivacy';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

let OobeStatement = new OobeStatementAbilityPrivacy();
let want: Want = {};
let launchParam: AbilityConstant.LaunchParam = {
  launchReason: AbilityConstant.LaunchReason.UNKNOWN,
  lastExitReason: AbilityConstant.LastExitReason.UNKNOWN,
  lastExitMessage: ''
};
let OobeStatement_onCreate = () => {
  OobeStatement.onCreate();
  expect(true).assertTrue();
}
let OobeStatement_onDestroy = () => {
  OobeStatement.onDestroy();
  expect(true).assertTrue();
}
let OobeStatement_onForeground = () => {
  OobeStatement.onForeground();
  expect(true).assertTrue();
}

let OobeStatement_onBackground = () => {
  OobeStatement.onBackground();
  expect(true).assertTrue();
}

export default function OobeStatementAbilityPrivacyTest() {
  describe('OobeStatementAbilityPrivacyTest', () => {
    beforeAll(() => {
    })
    beforeEach(() => {
    })
    afterEach(() => {
    })
    afterAll(() => {
    })
    it('OobeStatement_onCreate', 0, () => {
      OobeStatement_onCreate();
    });
    it('OobeStatement_onDestroy', 0, () => {
      OobeStatement_onDestroy();
    });
    it('OobeStatement_onForeground', 0, () => {
      OobeStatement_onForeground();
    });
    it('OobeStatement_onBackground', 0, () => {
      OobeStatement_onBackground();
    });
  })
}