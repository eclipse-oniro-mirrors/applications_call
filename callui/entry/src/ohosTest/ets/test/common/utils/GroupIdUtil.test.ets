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
import { describe, beforeAll, it, expect } from '@ohos/hypium';
import LogUtils from '../../../../../main/ets/common/utils/LogUtils';
import { common } from '@kit.AbilityKit';
import { BackupExtensionContext } from '@kit.CoreFileKit';
import { getGroupDir } from '../../../../../main/ets/common/utils/GroupIdUtil';

const TAG = 'GroupIdUtilTest';

export default function GroupIdUtilTest() {
  describe('GroupIdUtilTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    it('GroupIdUtilTest_01', 0, async () => {
      await GroupIdUtilTest_01();
    })
  })
}

async function GroupIdUtilTest_01() {
  LogUtils.i(TAG, 'test 01 start');
  let testContext = AppStorage.get<common.Context>('BackupExtensionAbility') as BackupExtensionContext;
  let result = await getGroupDir(testContext);
  expect(typeof result === 'string').assertTrue();
  LogUtils.i(TAG, 'test 01 end');
}