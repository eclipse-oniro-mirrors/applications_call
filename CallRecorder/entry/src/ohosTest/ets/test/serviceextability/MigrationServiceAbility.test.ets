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
import Want from '@ohos.app.ability.Want';
import MigrationServiceAbility from '../../../../main/ets/serviceextability/MigrationServiceAbility';

let MigrationServiceAbilityTest_onConnect = () => {
  let migrationServiceAbility = new MigrationServiceAbility();
  let want: Want = {};
  let ret = migrationServiceAbility.onConnect(want);
  expect(ret !== undefined).assertTrue();
}

let MigrationServiceAbilityTest_onDisconnect = () => {
  let migrationServiceAbility = new MigrationServiceAbility();
  let want: Want = {};
  let ret = migrationServiceAbility.onDisconnect(want);
  expect(ret === undefined).assertTrue();
}

export default function MigrationServiceAbilityTest() {
  describe('MigrationServiceAbilityTest', () => {
    it('MigrationServiceAbilityTest_onConnect', 0, () => {
      MigrationServiceAbilityTest_onConnect();
    })
    it('MigrationServiceAbilityTest_onDisconnect', 0, () => {
      MigrationServiceAbilityTest_onDisconnect();
    })
  })
}
