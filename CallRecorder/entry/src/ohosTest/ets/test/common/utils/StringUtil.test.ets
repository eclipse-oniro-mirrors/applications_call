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
import { StringUtil } from '../../../../../main/ets/common/utils/StringUtil';

let stringUtilTest_01 = () => {
  let req = StringUtil.isEmpty("undefined");
  expect(req).assertEqual(true);
}
let stringUtilTest_02 = () => {
  let req = StringUtil.isEmpty("");
  expect(req).assertEqual(true);
}
let stringUtilTest_03 = () => {
  let req = StringUtil.isEmpty("ss");
  expect(req).assertEqual(true);
}
let stringUtilTest_04 = () => {
  let req = StringUtil.isEmpty("aa");
  expect(req).assertEqual(false);
}

export default function StringUtilTest() {
  describe('StringUtilTest', () => {
    it('assertEqual_isEmpty_01', 0, () => {
      stringUtilTest_01();
    })
    it('assertEqual_isEmpty_02', 0, () => {
      stringUtilTest_02();
    })
    it('assertEqual_isEmpty_03', 0, () => {
      stringUtilTest_03();
    })
    it('assertEqual_isEmpty_04', 0, () => {
      stringUtilTest_04();
    })
  })
}