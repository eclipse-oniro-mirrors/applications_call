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
import window from '@ohos.window';
import settings from '@ohos.settings';
import { BusinessError } from '@ohos.base';
import LogUtils from './LogUtils';
import { isTablet } from '../utils/DeviceTypeUtils';

const TAG = 'PcModeHelper'

export async function maximizeByPcMode(context: Context, win: window.Window) {
  if (!isTablet()) {
    return;
  }

  // instrument ignore next       忽略代码块
  if (!isWindowPcMode(context)) {
    return;
  }

  // instrument ignore next       忽略代码块
  win.maximize().then(() => {
    LogUtils.i(TAG, 'maximize done');
  }).catch((error: BusinessError) => {
    LogUtils.e(TAG, 'maximize fail ' + JSON.stringify(error));
  });
}


export function isWindowPcMode(context: Context) {
  try {
    const value =
      settings.getValueSync(context, 'window_pcmode_switch_status', 'false', settings.domainName.USER_PROPERTY);
    LogUtils.i(TAG, 'IS_FREE_WINDOW_ENABLE value is ' + value);
    return value === 'true';
  } catch (err) {
    if (err) {
      LogUtils.e(TAG, 'get settings value failed! ' + JSON.stringify(err));
    }
  }
  return false;
}