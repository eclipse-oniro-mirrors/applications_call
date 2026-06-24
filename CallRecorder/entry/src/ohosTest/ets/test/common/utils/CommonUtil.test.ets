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
import { describe, it, expect, } from '@ohos/hypium';
import { formatPhoneNum, terminateSelfWithResult } from '../../../../../main/ets/common/utils/CommonUtil';
import i18n from '@ohos.i18n';
import { UIExtensionContentSession } from '@kit.AbilityKit';

let CommonUtilTest_formatPhoneNum_01Func = () => {
  let phoneNumber: string = '17314984771';
  let countryId = i18n.System.getSystemRegion();
  let phoneNumberFormat = new i18n.PhoneNumberFormat(countryId);
  let isNumberValid: boolean = phoneNumberFormat.isValidNumber(phoneNumber);
  let formatNumber = isNumberValid ? phoneNumberFormat.format(phoneNumber) : phoneNumber;
  let result = formatPhoneNum(phoneNumber);
  expect(result).assertEqual(formatNumber);
};
let CommonUtilTest_formatPhoneNum_02Func = () => {
  let phoneNumber: string = '(sshdsgayw';
  let countryId = i18n.System.getSystemRegion();
  let phoneNumberFormat = new i18n.PhoneNumberFormat(countryId);
  let isNumberValid: boolean = phoneNumberFormat.isValidNumber(phoneNumber);
  let formatNumber = isNumberValid ? phoneNumberFormat.format(phoneNumber) : phoneNumber;
  let result = formatPhoneNum(phoneNumber);
  expect(result).assertEqual(formatNumber);
};
let CommonUtilTest_terminateSelfWithResult_01Func = () => {
  let session: UIExtensionContentSession = terminateSelfWithResult(false);
  expect(session == null).assertTrue();
}
let CommonUtilTest_terminateSelfWithResult_02Func = () => {
  let session: UIExtensionContentSession = terminateSelfWithResult(true);
  expect(session == null).assertTrue();
}

export default function CommonUtilTest() {
  describe('CommonUtilTest', () => {
    it('CommonUtilTest_formatPhoneNum_01', 0, () => {
      CommonUtilTest_formatPhoneNum_01Func();
    });
    it('CommonUtilTest_formatPhoneNum_02', 0, () => {
      CommonUtilTest_formatPhoneNum_02Func();
    });
    it('CommonUtilTest_terminateSelfWithResult_01', 0, () => {
      CommonUtilTest_terminateSelfWithResult_01Func();
    });
    it('CommonUtilTest_terminateSelfWithResult_02', 0, () => {
      CommonUtilTest_terminateSelfWithResult_02Func();
    });
  });
}