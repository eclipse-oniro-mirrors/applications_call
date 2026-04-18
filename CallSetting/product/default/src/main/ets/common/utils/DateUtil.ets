/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { systemDateTime } from '@kit.BasicServicesKit';

const TAG = 'DateUtil';

export class DateUtil {

  /**
   * get string from date
   *
   * @param {number} timestamp - timestamp
   *
   * @return { string } - return date string
   */
  static formatTime(timestamp: number): string {
    let time = timestamp ? timestamp * 1000 : systemDateTime.getTime();
    const date = new Date(time);

    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0'); // 月份补零
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  /**
   * get string array from date
   *
   * @param {number} timestamp - timestamp
   *
   * @return { string[] } - return date string
   */
  static getTimeList(timestamp: number): string[] {
    let result: string[] = [];
    let time = timestamp ? timestamp * 1000 : systemDateTime.getTime();
    const date = new Date(time);

    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0'); // 月份补零
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');

    result.push(year.toString(), month.toString(), day.toString(), hours.toString(), minutes.toString(),
      seconds.toString());
    return result;
  }
}

export enum TimeIndex {
  YEAR,
  MONTH,
  DAY,
  HOUR,
  MINUTE
}

export enum  AcrossDay {
  NO_ACROSS,
  START_TIME_ACROSS,
  END_TIME_ACROSS,
}