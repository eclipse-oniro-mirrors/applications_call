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
import { describe, it, expect } from '@ohos/hypium';
import DialerSecretCode from '../../../../main/ets/utils/DialerSecretCode';

export default function DialerSecretCodeTest() {
  describe('DialerSecretCodeTest', () => {

    let mDialerSecretCode: DialerSecretCode = DialerSecretCode.getInstance();

    it('DialerSecretCodeTest_dealSecretCode_01', 0, () => {
      let result = mDialerSecretCode.dealSecretCode('*#*#121314#*#*');
      expect(result).assertTrue();
    })

    it('DialerSecretCodeTest_dealSecretCode_02', 0, () => {
      let result = mDialerSecretCode.dealSecretCode('*#*#2846579#*#*');
      expect(result).assertTrue();
    })

    it('DialerSecretCodeTest_dealSecretCode_03', 0, () => {
      let result = mDialerSecretCode.dealSecretCode('*#*#2847#*#*');
      expect(result).assertTrue();
    })

    it('DialerSecretCodeTest_dealSecretCode_04', 0, () => {
      let result = mDialerSecretCode.dealSecretCode('*#*#2845#*#*');
      expect(result).assertTrue();
    })
    it('DialerSecretCodeTest_dealSecretCode_05', 0, () => {
      DialerSecretCode.getInstance();
      mDialerSecretCode.dealSecretCode('*#*#2589#*#*');
      let result = mDialerSecretCode.dealSecretCode('test');
      expect(result).assertFalse();
    })
  });
}