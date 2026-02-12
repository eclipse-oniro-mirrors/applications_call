/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import I18n from '@ohos.i18n';
import { EnvironmentCallback } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration';
import LogUtils from './LogUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import Utils from './utils';

const TAG = 'CallColumnUtils';

export const HANG_UP_LTR_ANGLE = 135;
export const HANG_UP_RTL_ANGLE = -135;
export const SPEAKERPHONE_RTL_ANGLE = 180;

export function isRTLHandle(): void {
  let isrtl = I18n.isRTL(I18n.System.getSystemLocale());
  LogUtils.i(TAG, `first isrtl value: ${isrtl}`);
  AppStorage.setOrCreate('isRTL', isrtl);

  let environmentCallback: EnvironmentCallback = {
    onConfigurationUpdated(newConfig: Configuration) {
      let isrtl = I18n.isRTL(I18n.System.getSystemLocale());
      LogUtils.i(TAG, `language change isrtl value: ${isrtl}`);
      AppStorage.setOrCreate('isRTL', isrtl);
    },
    onMemoryLevel(level) {
      LogUtils.i(TAG, `onMemoryLevel level: ${level}`);
    }
  }
  try {
    let context = Utils.getInstance().getContext(true);
    context.getApplicationContext().on('environment', environmentCallback);
  } catch (err) {
    let code = (err as BusinessError).code;
    let message = (err as BusinessError).message;
    LogUtils.e(TAG, `Failed to register applicationContext. Code is ${code}, message is ${message}`);
  }
}
