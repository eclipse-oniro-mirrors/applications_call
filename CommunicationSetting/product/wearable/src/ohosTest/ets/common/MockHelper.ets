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

import { ArgumentMatchers, it, MockKit, when } from '@ohos/hypium';
import { LogUtil } from '../../../main/ets/util/LogUtil';

/**
 * MockHelper
 *
 * @since 2025-07-08
 */
export class MockHelper {
  /**
   * 打桩log函数
   *
   * @param mocker mock实例
   */
  public static mockLog(mocker: MockKit): void {
    let mockLogInfoUtil: ESObject = mocker.mockFunc(LogUtil, LogUtil.info);
    when(mockLogInfoUtil)(ArgumentMatchers.any).afterReturn(undefined);
    let mockLogWarnUtil: ESObject = mocker.mockFunc(LogUtil, LogUtil.warn);
    when(mockLogWarnUtil)(ArgumentMatchers.any).afterReturn(undefined);
    let mockLogErrorUtil: ESObject = mocker.mockFunc(LogUtil, LogUtil.error);
    when(mockLogErrorUtil)(ArgumentMatchers.any).afterReturn(undefined);
  }

  /**
   * 解除log函数打桩
   *
   * @param mocker mock实例
   */
  public static ignoreMockLog(mocker: MockKit): void {
    mocker.ignoreMock(LogUtil, LogUtil.info);
    mocker.ignoreMock(LogUtil, LogUtil.warn);
    mocker.ignoreMock(LogUtil, LogUtil.error);
  }

  /**
   * 生成普通log
   *
   * @param tag tag标记
   * @param msg msg消息体
   * @returns 完整log
   */
  public static getNormalLog(tag: string, msg: string): string {
    return `${tag}${msg}`;
  }
}
