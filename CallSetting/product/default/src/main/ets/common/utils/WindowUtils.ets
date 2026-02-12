/*
 * Copyright (c) 2024-2025 Huawei Device Co., Ltd.
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
import { LogUtils } from '@ohos/common';
import { window } from '@kit.ArkUI';

const TAG = 'WindowUtils';

/**
 * Keep screen on when float window is showing
 *
 * @param window window
 * @param isKeepScreenOn boolean
 * @param windowName string
 */
export function setFloatWindowKeepScreen(window: window.Window, isKeepScreenOn: boolean, windowName: string): void {
  try {
    if (!window) {
      LogUtils.w(TAG, `Set window keep screen fail, invalid: ${windowName}`);
      return;
    }
    window.setWindowKeepScreenOn(isKeepScreenOn, (err) => {
      if (err?.code) {
        LogUtils.e(TAG, `Failed to keep ${windowName} screen on. Cause: ${err.code}`);
      }
    });
  } catch (err) {
    LogUtils.e(TAG, `Set window name ${windowName} keep screen error: ${err?.code}`);
  }
}