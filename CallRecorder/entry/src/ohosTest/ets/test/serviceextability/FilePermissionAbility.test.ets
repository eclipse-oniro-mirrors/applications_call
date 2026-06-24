/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import Want from '@ohos.app.ability.Want';
import FilePermissionAbility from '../../../../main/ets/serviceextability/FilePermissionAbility';

let FilePermissionAbilityTest_onConnect = () => {
  let filePermissionAbility = new FilePermissionAbility();
  let want: Want = {};
  let ret = filePermissionAbility.onConnect(want);
  expect(ret !== undefined).assertTrue();
}


export default function FilePermissionAbilityTest() {
  describe('FilePermissionAbilityTest', () => {
    it('MigrationServiceAbilityTest_onConnect', 0, () => {
      FilePermissionAbilityTest_onConnect();
    })
  })
}
