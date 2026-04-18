/*
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

import Intl from '@ohos.intl';
import I18n from '@ohos.i18n';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'SimIdFormat';

export let simIdFormat = (formatNumber: number) => {
  try {
    let systemLanguage = I18n.System.getAppPreferredLanguage();
    LogUtils.i(TAG, 'systemLanguage:' + systemLanguage);
    let options: Intl.NumberOptions = { locale: 'Locale' };
    let numberFormat: Intl.NumberFormat = new Intl.NumberFormat(systemLanguage, options);
    return numberFormat.format(formatNumber);
  } catch (error) {
    return formatNumber.toString();
  }
}

export function phoneFormat(phoneNumber: string): string {
  try {
    let phoneFormatter: (string)[] = [];
    for (let i = 0; i < phoneNumber.length; i++) {
      if (isDigitRegex(phoneNumber[i])) {
        const num = Number(phoneNumber[i]);
        phoneFormatter.push(simIdFormat(num));
      } else {
        phoneFormatter.push(phoneNumber[i]);
      }
    }
    return phoneFormatter.join('');
  } catch (error) {
    return phoneNumber;
  }
}

function isDigitRegex(char: string): boolean {
  return /^\d$/.test(char);
}