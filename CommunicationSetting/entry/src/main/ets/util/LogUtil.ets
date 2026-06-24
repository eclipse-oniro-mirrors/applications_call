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

import hilog from '@ohos.hilog';

const MODULE_TAG: string = 'CommunicationSetting';

/**
 * 日志工具类
 *
 * @since 2024-07-20
 */
export class LogUtil {
  private static readonly DOMAIN: number = 0x0000;

  static debug(pageTag: string, msg: string): void {
    hilog.debug(LogUtil.DOMAIN, MODULE_TAG, pageTag + ': ' + msg);
  }

  static log(pageTag: string, msg: string): void {
    hilog.info(LogUtil.DOMAIN, MODULE_TAG, pageTag + ': ' + msg);
  }

  static info(pageTag: string, msg: string): void {
    hilog.info(LogUtil.DOMAIN, MODULE_TAG, pageTag + ': ' + msg);
  }

  static warn(pageTag: string, msg: string): void {
    hilog.warn(LogUtil.DOMAIN, MODULE_TAG, pageTag + ': ' + msg);
  }

  static error(pageTag: string, msg: string): void {
    hilog.error(LogUtil.DOMAIN, MODULE_TAG, pageTag + ': ' + msg);
  }

  static printBuilderLog(pageTag: string, msg: string): boolean {
    hilog.info(LogUtil.DOMAIN, MODULE_TAG, pageTag + ': ' + msg);
    return true;
  }
}