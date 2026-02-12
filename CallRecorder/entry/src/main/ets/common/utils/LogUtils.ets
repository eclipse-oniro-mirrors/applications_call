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

/**
 * Log Util
 *
 * standard:
 * 1. define TAG, recommend class name.
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 */

import hilog from '@ohos.hilog';

const DOMAIN: number = 0xD001F17;
const TAG: string = 'CallRecorder';

/**
 *  log package tool class
 */
export class LogUtils {
  d(tag: string, msg: string): void {
    hilog.debug(DOMAIN, TAG, `${tag}:${msg}`);
  }

  i(tag: string, msg: string): void {
    hilog.info(DOMAIN, TAG, `${tag}:${msg}`);
  }

  w(tag: string, msg: string): void {
    hilog.warn(DOMAIN, TAG, `${tag}:${msg}`);
  }

  e(tag: string, msg: string): void {
    hilog.error(DOMAIN, TAG, `${tag}:${msg}`);
  }
}

let mLogUtil = new LogUtils();

export default mLogUtil as LogUtils;

