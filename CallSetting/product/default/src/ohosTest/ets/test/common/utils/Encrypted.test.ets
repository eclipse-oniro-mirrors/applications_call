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
import { Encrypted, LogUtils } from '@ohos/common/CommonIndex';
import buffer from '@ohos.buffer'
import cryptoFramework from '@ohos.security.cryptoFramework'
import { JSON } from '@kit.ArkTS'

const TAG = 'EncryptedTest'

export default function EncryptedTest() {
  describe('EncryptedTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('stringToUint8Array_stringToUint8Array', 0, () => {
      let encrypted = new Encrypted();
      let str = 'test'
      let result = Encrypted.stringToUint8Array(str).toString();
      let exp = new Uint8Array(buffer.from(str, 'utf-8').buffer).toString();
      expect(result).assertEqual(exp);
    })
    it('stringToUint8Array_uint8ArrayToString', 0, () => {
      let uint8 = new Uint8Array(4);
      uint8[0] = 16;
      uint8[1] = 192;
      uint8[2] = 224;
      uint8[3] = 1000;
      let result = Encrypted.uint8ArrayToString(uint8);
      expect(result).assertEqual(' 耀');
    })
    it('stringToUint8Array_sha256Summary', 0, async () => {
      let result = await Encrypted.sha256Summary('test');
      let md = cryptoFramework.createMd('SHA256');
      await md.update({ data: Encrypted.stringToUint8Array('test') });
      let mdOutput = await md.digest();
      expect(JSON.stringify(result)).assertEqual(JSON.stringify(mdOutput));
    })
  })
}