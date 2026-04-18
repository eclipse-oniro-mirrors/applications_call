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
import {
  getFoldTypeInfo,
  getVersionName,
  isPhone,
  isScreenLocked, isTablet,
  isTwoInOne } from '../../../../../main/ets/common/utils/DeviceTypeUtils';

const TAG = 'DeviceTypeUtilsTest';

export default function DeviceTypeUtilsTest() {
  describe('DeviceTypeUtilsTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    it('DeviceTypeUtilsTest_01', 0, async () => {
      await DeviceTypeUtilsTest_01();
    })
    it('DeviceTypeUtilsTest_02', 0, async () => {
      await DeviceTypeUtilsTest_02();
    })
    it('DeviceTypeUtilsTest_03', 0, async () => {
      await DeviceTypeUtilsTest_03();
    })
    it('DeviceTypeUtilsTest_04', 0, async () => {
      await DeviceTypeUtilsTest_04();
    })
    it('DeviceTypeUtilsTest_05', 0, async () => {
      await DeviceTypeUtilsTest_05();
    })
    it('DeviceTypeUtilsTest_06', 0, async () => {
      await DeviceTypeUtilsTest_06();
    })

  })
}

async function DeviceTypeUtilsTest_01() {
  LogUtils.i(TAG, 'test 01 start');
  let result = isTablet();
  expect(typeof result === 'boolean').assertTrue();
  LogUtils.i(TAG, 'test 01 end');
}

async function DeviceTypeUtilsTest_02() {
  LogUtils.i(TAG, 'test 02 start');
  let result = isScreenLocked();
  expect(typeof result === 'boolean').assertTrue();
  LogUtils.i(TAG, 'test 02 end');
}

async function DeviceTypeUtilsTest_03() {
  LogUtils.i(TAG, 'test 03 start');
  let result = await getVersionName(() => {});
  expect(result === null).assertFalse();
  LogUtils.i(TAG, 'test 03 end');
}

async function DeviceTypeUtilsTest_04() {
  LogUtils.i(TAG, 'test 04 start');
  let result = isPhone();
  expect(typeof result === 'boolean').assertTrue();
  LogUtils.i(TAG, 'test 04 end');
}

async function DeviceTypeUtilsTest_05() {
  LogUtils.i(TAG, 'test 05 start');
  let result = getFoldTypeInfo();
  expect(typeof result === 'number').assertTrue();
  LogUtils.i(TAG, 'test 05 end');
}

async function DeviceTypeUtilsTest_06() {
  LogUtils.i(TAG, 'test 06 start');
  let result = isTwoInOne();
  expect(typeof result === 'boolean').assertTrue();
  LogUtils.i(TAG, 'test 06 end');
}