/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from './HiLog';

const TAG = `VibratorUtil`;

export class VibratorUtil {
  static async startVibration(duration: number) {
    try {
      await vibrator.startVibration({
        type: 'time',
        duration: duration
      }, {
        id: 0,
        usage: 'alarm'
      }).then(() => {
        LogUtils.i(TAG, 'Succeed in starting vibration');
      }, (error: BusinessError) => {
        LogUtils.e(TAG, `Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `An unexpected error occurred. error: ${JSON.stringify(err)}`);
    }
  }

  static async stopAllVibration() {
    try {
      await vibrator.stopVibration().then(() => {
        LogUtils.i(TAG, 'Succeed in stopping vibration');
      }, (error: BusinessError) => {
        LogUtils.e(TAG, `Failed to stop vibration. Code: ${error.code}, message: ${error.message}`);
      });
    } catch (error) {
      LogUtils.e(TAG, `An unexpected error occurred. error: ${JSON.stringify(error)}`);
    }
  }
}