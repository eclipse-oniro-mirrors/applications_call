/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogUtils } from '@ohos/common';

const TAG = 'VibrateUtil';

/**
 * VibrateUtil
 *
 * @since 2023-05-26
 */
export default class VibrateUtil {
  private static readonly TYPE = 'time';
  private static readonly DURATION = 300;
  private static readonly USAGE = 'notification';

  /**
   * play vibration for start vibration
   */
  public static startVibrate() {
    try {
      vibrator.startVibration({
        type: VibrateUtil.TYPE,
        duration: VibrateUtil.DURATION,
      }, {
        usage: VibrateUtil.USAGE
      }, (error: BusinessError) => {
        if (error) {
          LogUtils.e(TAG, `Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
          return;
        }
        LogUtils.i(TAG, 'Succeed in starting vibration');
      });
    } catch (err) {
      LogUtils.e(TAG, `An unexpected error occurred. code: ${err.code}, message: ${err.message}`);
    }
  }

  /**
   * play vibration for start vibration
   */
  public static stopVibrate() {
    try {
      // 按照VIBRATOR_STOP_MODE_TIME模式停止振动
      vibrator.stopVibration(vibrator.VibratorStopMode.VIBRATOR_STOP_MODE_TIME, (error: BusinessError) => {
        if (error) {
          LogUtils.e(TAG, `Failed to stop vibration. Code: ${error.code}, message: ${error.message}`);
          return;
        }
        LogUtils.i(TAG, 'Succeed in stopping vibration');
      })
    } catch (err) {
      LogUtils.e(TAG, `An unexpected error occurred. code: ${err.code}, message: ${err.message}`);
    }
  }
}