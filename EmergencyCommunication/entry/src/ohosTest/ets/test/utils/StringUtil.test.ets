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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit } from '@ohos/hypium'
import { isObjectType } from '../../../../main/ets/data/LooseObject';
import { isJSONString, isObjectJSONString, StringUtil } from '../../../../main/ets/utils/StringUtil'

export default function StringUtilTest() {
  describe('StringUtilTest', () => {
    it('StringUtilTest_isEmpty_true', 0, () => {
      expect(StringUtil.isEmpty(undefined)).assertTrue();
    })
    it('StringUtilTest_isEmpty_false', 0, () => {
      expect(StringUtil.isEmpty('test')).assertFalse();
    })
    it('LooseObjectTest_isObjectType_true', 0, async () => {
      expect(isObjectType({})).assertEqual(true);
    })
    it('LooseObjectTest_isObjectType_false', 0, async () => {
      expect(isObjectType(1)).assertEqual(false);
    })
    it('StringUtilTest_isJSONString_true', 0, () => {
      expect(isJSONString(JSON.stringify({}))).assertTrue();
    })
    it('StringUtilTest_isJSONString_false', 0, () => {
      expect(isJSONString('string')).assertFalse();
    })
    it('StringUtilTest_isObjectJSONString_01', 0, () => {
      expect(isObjectJSONString('')).assertFalse();
    })
    it('StringUtilTest_isObjectJSONString_02', 0, () => {
      expect(isObjectJSONString(JSON.stringify({}))).assertTrue();
    })
    it('StringUtilTest_isObjectJSONString_03', 0, () => {
      expect(isObjectJSONString('  ')).assertFalse();
    })
    it('StringUtilTest_isObjectJSONString_04', 0, () => {
      expect(isObjectJSONString(JSON.stringify('test'))).assertFalse();
    })
  })
}