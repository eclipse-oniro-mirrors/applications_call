/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import { i18n } from '@kit.LocalizationKit';
import sim from '@ohos.telephony.sim';
import radio from '@ohos.telephony.radio';
import LogUtils from './HiLog';

const TAG = 'TelephoneUtil';

export class I18nPhoneNumberFormat {
  private instancePhoneNumberFormat: i18n.PhoneNumberFormat | null = null;
  public getInstancePhoneNumberFormat = () => {
    if (this.instancePhoneNumberFormat) {
      return this.instancePhoneNumberFormat;
    }
    try {
      this.instancePhoneNumberFormat = new i18n.PhoneNumberFormat(i18n.System.getSystemRegion(), { type: 'NATIONAL' });
    } catch (e) {
      LogUtils.e(TAG, 'getInstancePhoneNumberFormat error: ' + JSON.stringify(e));
      this.instancePhoneNumberFormat = null;
    }
    return this.instancePhoneNumberFormat;
  }

  private constructor() {
  }

  private static instance: I18nPhoneNumberFormat;

  static getInstance(): I18nPhoneNumberFormat {
    if (I18nPhoneNumberFormat.instance == undefined) {
      I18nPhoneNumberFormat.instance = new I18nPhoneNumberFormat();
    }
    return I18nPhoneNumberFormat.instance;
  }
}

export class I18nPhoneNumberFormatE164 {
  private instancePhoneNumberFormatE164: i18n.PhoneNumberFormat | null = null;
  public getInstancePhoneNumberFormatE164 = () => {
    if (this.instancePhoneNumberFormatE164) {
      return this.instancePhoneNumberFormatE164;
    }
    try {
      this.instancePhoneNumberFormatE164 = new i18n.PhoneNumberFormat(i18n.System.getSystemRegion(), { type: 'E164' });
    } catch (e) {
      LogUtils.e(TAG, 'getInstancePhoneNumberFormatE164 error:' + JSON.stringify(e));
      this.instancePhoneNumberFormatE164 = null;
    }
    return this.instancePhoneNumberFormatE164;
  }

  private constructor() {
  }

  private static instance: I18nPhoneNumberFormatE164;

  static getInstance(): I18nPhoneNumberFormatE164 {
    if (I18nPhoneNumberFormatE164.instance == undefined) {
      I18nPhoneNumberFormatE164.instance = new I18nPhoneNumberFormatE164();
    }
    return I18nPhoneNumberFormatE164.instance;
  }
}


export class TelephoneUtil {
  public static formatDisplayPhoneNum(phoneNumber: string): string {
    try {
      //先去空格
      phoneNumber = phoneNumber.replace(/\s*/g, '');
      //先用 national 格式化一次
      let nationalPhoneNumberFormat = I18nPhoneNumberFormat.getInstance().getInstancePhoneNumberFormat();
      if (!nationalPhoneNumberFormat) {
        return phoneNumber;
      }
      let isNumberNationalValid: boolean = nationalPhoneNumberFormat.isValidNumber(phoneNumber);
      let nationalFormatNumber = isNumberNationalValid ? nationalPhoneNumberFormat.format(phoneNumber) : phoneNumber;
      let nationalFormatNumberTemp = nationalFormatNumber.replace(/\s*/g, '');
      let nationalFormatNumLen = nationalFormatNumberTemp.length;
      let originNumLen = phoneNumber.length;
      if (nationalFormatNumLen <= originNumLen &&
        nationalFormatNumberTemp === phoneNumber.substring(originNumLen - nationalFormatNumLen)) {
        return nationalFormatNumber;
      }
      //如果经过以上处理不符合条件，再用e164格式化
      let e164phoneNumberFormat = I18nPhoneNumberFormatE164.getInstance().getInstancePhoneNumberFormatE164();
      if (!e164phoneNumberFormat) {
        return phoneNumber;
      }
      let isNumberE164Valid: boolean = e164phoneNumberFormat.isValidNumber(phoneNumber);
      let e164FormatNumber = isNumberE164Valid ? e164phoneNumberFormat.format(phoneNumber) : phoneNumber;
      return e164FormatNumber;
    } catch (error) {
      LogUtils.e(TAG, `formatDisplayPhoneNum failed, error: ${JSON.stringify(error)}`);
    }
    return phoneNumber;
  }
}


