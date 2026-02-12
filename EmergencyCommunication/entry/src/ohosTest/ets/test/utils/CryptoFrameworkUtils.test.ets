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
import { describe, expect, it } from '@ohos/hypium';
import { CryptoFrameworkUtils } from '../../../../main/ets/utils/CryptoFrameworkUtils';

export default function CryptoFrameworkUtilsTest() {
  describe('CryptoFrameworkUtilsTest', () => {
    it('CryptoFrameworkUtilsTest_01', 0, () => {
      CryptoFrameworkUtils.getSHA256DigestString('123');
      expect(1).assertEqual(1);
    })

    it('should_return_empty_string_when_input_is_empty', 0, async () => {
      const result = await CryptoFrameworkUtils.getSHA256DigestString('');
      expect(result).assertEqual('');
    });

    it('should_return_correct_SHA256_digest_string_when_input_is_valid', 0, async () => {
      const input = 'test';
      const result = await CryptoFrameworkUtils.getSHA256DigestString(input);
      const expectedDigest = '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
      expect(result).assertEqual(expectedDigest);
    });
    it('CryptoFrameworkUtilsTest_stringToSha256', 0, () => {
      CryptoFrameworkUtils.stringToSha256('test');
      expect(1).assertEqual(1);
    })
  })
}