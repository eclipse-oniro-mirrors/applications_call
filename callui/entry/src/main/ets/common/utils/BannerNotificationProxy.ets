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

import LogUtils from '../utils/LogUtils';
import display from '@ohos.display';
import inputMethod from '@ohos.inputMethod';

import panel from '@ohos.inputMethod.Panel';

const TAG = 'BannerNotificationProxy';

export async function hasImmersiveWindow(): Promise<boolean> {
  let windowStatus = false;
  try {
    let displayClass = display.getDefaultDisplaySync();
    windowStatus = await displayClass.hasImmersiveWindow();
  } catch (error) {
    LogUtils.e(TAG, 'hasImmersiveWindow error: code: ' + error.code + ', message: ' + error.message);
  }
  LogUtils.i(TAG, 'hasImmersiveWindow ' + windowStatus);
  return windowStatus;
}

export async function isPanelShown(): Promise<boolean> {
  let isShownPanel = false;
  // check if the input method panel is shown.
  let info: panel.PanelInfo = {
    type: panel.PanelType.SOFT_KEYBOARD,
    flag: panel.PanelFlag.FLAG_FIXED
  };
  try {
    let inputMethodSetting = inputMethod.getSetting();
    isShownPanel = await inputMethodSetting.isPanelShown(info);
    LogUtils.i(TAG, 'Succeeded in querying isPanelShown, result: ' + isShownPanel);
  } catch (err) {
    LogUtils.e(TAG, `Failed to query isPanelShown: ${JSON.stringify(err)}`);
  }
  return isShownPanel;
}

export default class BannerNotificationProxy {
}
