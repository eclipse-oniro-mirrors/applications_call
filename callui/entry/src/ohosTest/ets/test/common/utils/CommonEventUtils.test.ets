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
import { subscribeEvent, unSubscribeEvent } from '../../../../../main/ets/common/utils/CommonEventUtils';

const TAG = 'CommonEventUtilsTest';

export default function CommonEventUtilsTest() {
  describe('CommonEventUtilsTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    it('CommonEventUtilsTest_02', 0, async () => {
      await CommonEventUtilsTest_02();
    })
    it('CommonEventUtilsTest_03', 0, async () => {
      await CommonEventUtilsTest_03();
    })
  })
}

async function CommonEventUtilsTest_02() {
  LogUtils.i(TAG, 'test 02 start');
  let result = subscribeEvent(() => {});
  expect(result === undefined).assertTrue();
  LogUtils.i(TAG, 'test 02 end');
}

async function CommonEventUtilsTest_03() {
  LogUtils.i(TAG, 'test 03 start');
  let result = unSubscribeEvent();
  expect(result === null).assertFalse();
  LogUtils.i(TAG, 'test 03 end');
}