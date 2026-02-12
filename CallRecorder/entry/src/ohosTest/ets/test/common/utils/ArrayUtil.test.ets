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
import { ArrayUtil } from '../../../../../main/ets/common/utils/ArrayUtil';

interface selfFace {
  name: string,
  id: string,
}

let ArrayUtilTest_true = () => {
  let list: object[] = [];
  let result = ArrayUtil.isEmpty(list);
  expect(result).assertEqual(true);
}
let ArrayUtilTest_not_null = () => {
  let use: selfFace = { name: "chen", id: '123' };
  let list: object[] = [use];
  let result = ArrayUtil.isEmpty(list);
  expect(result).assertEqual(false);
}


export default function ArrayUtilTest() {
  describe('ArrayUtilTest', () => {
    it('ArrayUtilTest_null', 0, () => {
      ArrayUtilTest_not_null();
    })
    it('ArrayUtilTest_true', 0, () => {
      ArrayUtilTest_true();
    })
  })
}