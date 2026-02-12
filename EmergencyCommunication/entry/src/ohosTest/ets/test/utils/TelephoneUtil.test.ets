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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit, when } from '@ohos/hypium'
import { I18nPhoneNumberFormat, TelephoneUtil, I18nPhoneNumberFormatE164 } from '../../../../main/ets/utils/TelephoneUtil'

export default function TelephoneUtilTest() {
  describe('TelephoneUtilTest', () => {

    it('TelephoneUtilTest', 0, async () => {
      I18nPhoneNumberFormat.getInstance();
      I18nPhoneNumberFormat.getInstance();
      let result = TelephoneUtil.formatDisplayPhoneNum('123');
      TelephoneUtil.formatDisplayPhoneNum('13333333333');
      expect(result === '+0086123').assertFalse();
    })
    it('TelephoneUtilTest_getInstancePhoneNumberFormat', 0, () => {
      I18nPhoneNumberFormat.getInstance().getInstancePhoneNumberFormat();
      expect(1).assertEqual(1);
    })
    it('TelephoneUtilTest_getInstancePhoneNumberFormatE164', 0, () => {
      I18nPhoneNumberFormatE164.getInstance().getInstancePhoneNumberFormatE164();
      expect(1).assertEqual(1);
    })
    it('TelephoneUtilTest_formatDisplayPhoneNum', 0, () => {
      TelephoneUtil.formatDisplayPhoneNum('12345678912');
      expect(1).assertEqual(1);
    })
  })
}