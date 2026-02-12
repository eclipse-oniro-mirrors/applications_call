/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import LogUtils from './LogUtils';
import i18n from '@ohos.i18n';
import intl from '@ohos.intl';

const TAG = 'TimeUtil';

export class TimeUtil {
  getRecordDisplayNameTime(date: Date): string {
    let yearStr = date.getFullYear().toString();
    let monthStr: string = (date.getMonth() + 1).toString().padStart(2, '0');
    let dayStr = date.getDate().toString().padStart(2, '0');
    let hourStr = date.getHours().toString().padStart(2, '0');
    let minuteStr = date.getMinutes().toString().padStart(2, '0');
    let secondStr = date.getSeconds().toString().padStart(2, '0');
    return yearStr + monthStr + dayStr + hourStr + minuteStr + secondStr;
  }

  isTimestamp(str: string): boolean {
    return str.trim() != '' && str.trim().length === 13 && !isNaN(Number(str.trim())) &&
      !isNaN((new Date(Number(str.trim()))).getTime());
  }

  getDateFromRecordDisplayNameTime(time: string): Date {
    let year = time.substring(0, 4);
    let month = time.substring(4, 6);
    let day = time.substring(6, 8);
    let date = new Date();
    date.setFullYear(Number.parseInt(year), Number.parseInt(month) - 1, Number.parseInt(day));
    return date;
  }

  getLocalizedMonthDateString(date: Date): string {
    let locale = i18n.System.getSystemLocale();
    let options: DateTimeOptions = {
      month: 'long',
      day: 'numeric',
    };
    let dateTimeFormat = new intl.DateTimeFormat(locale, options);
    let dateStr = dateTimeFormat.format(date);
    LogUtils.i(TAG, `format date: ${dateStr}`);
    return dateStr;
  }
}

let mUtil = new TimeUtil();

export default mUtil as TimeUtil;

