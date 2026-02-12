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

/**
 * Log Util
 *
 * standard:
 * 1. define tag, recommend class name.
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 */

import hilog from '@ohos.hilog';

const DOMAIN: number = 0xD001F16;
const TAG: string = 'CallSetting';

/**
 *  log package tool class
 */
export class LogUtils {
  static d(tag: string, msg: string): void {
    hilog.debug(DOMAIN, TAG, `${tag}:${msg}`);
  }

  static i(tag: string, msg: string): void {
    hilog.info(DOMAIN, TAG, `${tag}:${msg}`);
  }

  static w(tag: string, msg: string): void {
    hilog.warn(DOMAIN, TAG, `${tag}:${msg}`);
  }

  static e(tag: string, msg: string): void {
    hilog.error(DOMAIN, TAG, `${tag}:${msg}`);
  }
}
