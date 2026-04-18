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
import EccServiceExtAbility from '../../../../main/ets/serviceextability/EccServiceExtAbility'
import { Utils } from '../../../../main/ets/utils/Utils';

export default function EccServiceExtAbilityTest() {
  describe('EccServiceExtAbilityTest', () => {
    let ecc = new EccServiceExtAbility();
    let want: Want = {
      parameters: {
        phoneNumber: '132333333333',
        callerName: 'call_status_manager',
        slotId: 0
      }
    }
    let want1: Want = {
      parameters: {
        phoneNumber: '132333333333',
        callerName: 'test',
        slotId: 0
      }
    }
    it('EccServiceExtAbilityTest', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(Utils, Utils.isSosLocationUpdateSwitchOn);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      await ecc.onConnect(want);
      await ecc.onConnect(want1);
      let result = ecc.getSimCardPhoneNumber(0);
      mocker.ignoreMock(Utils, Utils.isSosLocationUpdateSwitchOn);
      expect(result === null).assertFalse();
    })
  })
}