/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import vibrator from '@ohos.vibrator';
import { BusinessError } from '@ohos.base';
import { LogUtil } from './LogUtil';

const TAG = 'VibrationUtils';

/**
 *  Vibration tool class
 */
export default class VibrationUtils {
  /**
   * once Vibration
   */
  public static onceVibration(effectId: string): void {
    try {
      vibrator.startVibration({
        type: 'preset',
        effectId: effectId,
        count: 1,
      }, {
        usage: 'unknown'
      }, (error) => {
        if (error) {
          LogUtil.error(TAG, 'onceVibration fail, error.code: ' + error.code + ' ,error.message: ' + error.message);
          return;
        }
        LogUtil.warn(TAG, 'onceVibration Callback returned to indicate a successful vibration.');
      });
    } catch (err) {
      LogUtil.error(TAG,
        'onceVibration errCode: ' + (err as BusinessError).code + ' ,msg: ' + (err as BusinessError).message);
    }
  }
}

export enum VibrationEffect {
  Light = 'haptic.slide.light',
  Heavy = 'haptic.long_press.heavy',
  Threshold = 'haptic.threshold',
  DeleteLongPress = 'haptic.delete_long_press',
  DeleteLongPressDouble = 'haptic.common.delete_long_press',
  LongPressLight = 'haptic.long_press_light',
}