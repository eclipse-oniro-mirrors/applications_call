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
import { Encrypted } from '../../../main/ets/soslocationservice/SosEncrypted'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'

export default function SosEncryptedTest() {
  describe('SosEncryptedTest', () => {
    it('SosEncryptedTest_stringToUint8Array', 0, async () => {
      let arr = Encrypted.stringToUint8Array('aA/你');
      Encrypted.uint8ArrayToString(arr);
      arr[0] = 10000;
      arr[1] = 0;
      arr[2] = 120000;
      arr[3] = 130000;
      arr[4] = 1;
      let result = Encrypted.uint8ArrayToString(arr);
      expect(result.length >= 0).assertTrue();
    })
  })
}