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
import { SymbolIconUtil } from '../../../../../main/ets/common/utils/SymbolIconUtil';

const TAG = 'SymbolIconUtilTest';

export default function SymbolIconUtilTest() {
  describe('SymbolIconUtilTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    it('SymbolIconUtilTest_01', 0, async () => {
      await SymbolIconUtilTest_01();
    })
    it('SymbolIconUtilTest_02', 0, async () => {
      await SymbolIconUtilTest_02();
    })
    it('SymbolIconUtilTest_03', 0, async () => {
      await SymbolIconUtilTest_03();
    })
    it('SymbolIconUtilTest_04', 0, async () => {
      await SymbolIconUtilTest_04();
    })
    it('SymbolIconUtilTest_05', 0, async () => {
      await SymbolIconUtilTest_05();
    })
  })
}

async function SymbolIconUtilTest_01() {
  LogUtils.i(TAG, 'test 01 start');
  let result = SymbolIconUtil.getInstance().getEarphoneFillIcon();
  expect(result).assertEqual('sys.symbol.bluetooth');
  LogUtils.i(TAG, 'test 01 end');
}

async function SymbolIconUtilTest_02() {
  LogUtils.i(TAG, 'test 02 start');
  let result = SymbolIconUtil.getInstance().getEarphoneFillIcon('test');
  expect(typeof result === 'string').assertTrue();
  LogUtils.i(TAG, 'test 02 end');
}

async function SymbolIconUtilTest_03() {
  LogUtils.i(TAG, 'test 03 start');
  let result = SymbolIconUtil.getInstance().getXingshanEarphoneFillIcon();
  expect(result).assertEqual('sys.symbol.nearlink');
  LogUtils.i(TAG, 'test 03 end');
}

async function SymbolIconUtilTest_04() {
  LogUtils.i(TAG, 'test 04 start');
  let result = SymbolIconUtil.getInstance().getXingshanEarphoneFillIcon('test');
  expect(typeof result === 'string').assertTrue();
  LogUtils.i(TAG, 'test 04 end');
}

async function SymbolIconUtilTest_05() {
  LogUtils.i(TAG, 'test 05 start');
  let result = SymbolIconUtil.getInstance().getNearLinkIconByIconId('test');
  expect(typeof result === 'string').assertTrue();
  LogUtils.i(TAG, 'test 05 end');
}