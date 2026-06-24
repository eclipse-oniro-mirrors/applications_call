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
import LogUtils from '../../../../../main/ets/common/utils/LogUtils';

let LogUtilsTest_01 = () => {
  let TAG = 'Test';
  let msg = 'mobileDataSettings';
  LogUtils.d(TAG, msg);
  expect(0).assertEqual(0);
}

let LogUtilsTest_02 = () => {
  let TAG = 'Test';
  let msg = 'mobileDataSettings';
  LogUtils.i(TAG, msg);
  expect(0).assertEqual(0);
}

let LogUtilsTest_03 = () => {
  let TAG = 'Test';
  let msg = 'mobileDataSettings';
  LogUtils.w(TAG, msg);
  expect(0).assertEqual(0);
}

let LogUtilsTest_04 = () => {
  let TAG = 'Test';
  let msg = 'mobileDataSettings';
  LogUtils.e(TAG, msg);
  expect(0).assertEqual(0);
}

export default function LogUtilsTest() {
  describe('LogUtilsTest', () => {
    it('LogUtilsTest_01', 0, () => {
      LogUtilsTest_01();
    })
    it('LogUtilsTest_02', 0, () => {
      LogUtilsTest_02();
    })
    it('LogUtilsTest_03', 0, () => {
      LogUtilsTest_03();
    })
    it('LogUtilsTest_04', 0, () => {
      LogUtilsTest_04();
    })
  })
}