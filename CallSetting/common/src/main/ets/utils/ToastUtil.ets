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

import { promptAction } from '@kit.ArkUI';
import { LogUtils } from './LogUtils';

const TAG: string = 'ToastUtil: ';

/**
 * Toast 提示工具类
 */
export class ToastUtil {
  public static SHORT_DURATION: number = 2000;

  private static lastClickTime: number = 0;

  public static handleMultiToast(message: string | Resource, duration?: number): void {
    // 防止连续点击，间隔时间为弹窗显示时间2s
    let nowTime: number = Date.now();
    let finalDuration: number = duration ?? ToastUtil.SHORT_DURATION;
    if (ToastUtil.lastClickTime !== 0 && nowTime - ToastUtil.lastClickTime < finalDuration) {
      LogUtils.i(TAG, `onButtonClick, less than 2s since the last showToast`);
      return;
    }
    ToastUtil.lastClickTime = nowTime;
    try {
      promptAction.showToast({ message: message, duration: finalDuration })
    } catch (e) {
      LogUtils.e(TAG, `showToast error ${e?.code}`);
    }
  }
}