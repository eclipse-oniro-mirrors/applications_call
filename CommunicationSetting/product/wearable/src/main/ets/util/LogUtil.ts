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

const COMMUNICATION_SETTING_NAME: string = 'CommunicationSetting';

/**
 * 日志工具类
 *
 * @since 2024-07-02
 */
export class LogUtil {
  private static readonly SETTING_DOMAIN: number = 0x0500;

  static debug(msg): void {
    hilog.debug(LogUtil.SETTING_DOMAIN, COMMUNICATION_SETTING_NAME, msg);
  }

  static log(msg): void {
    hilog.info(LogUtil.SETTING_DOMAIN, COMMUNICATION_SETTING_NAME, msg);
  }

  static info(msg): void {
    hilog.info(LogUtil.SETTING_DOMAIN, COMMUNICATION_SETTING_NAME, msg);
  }

  static warn(msg): void {
    hilog.warn(LogUtil.SETTING_DOMAIN, COMMUNICATION_SETTING_NAME, msg);
  }

  static error(msg): void {
    hilog.error(LogUtil.SETTING_DOMAIN, COMMUNICATION_SETTING_NAME, msg);
  }

  static printBuilderLog(msg): boolean {
    hilog.info(LogUtil.SETTING_DOMAIN, COMMUNICATION_SETTING_NAME, msg);
    return true;
  }
}