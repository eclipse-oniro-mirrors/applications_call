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

/**
 * Vibration Util
 *
 * standard:
 * 1. define TAG, recommend class name.
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 */
import audio from '@ohos.multimedia.audio';
import LogUtils from './LogUtils';
import vibrator from '@ohos.vibrator';
import { BusinessError } from '@ohos.base';

const TAG = 'VibrationAndProximityUtils';
const ONCE_VIBRATION_EFFECT_ID = 'haptic.notice.connected';
const ONCE_VIBRATION_SYSTEM_USAGE = true;

/**
 *  Vibration And Proximity tool class
 */
export class VibrationUtils {
  private static instance: VibrationUtils | null = null;

  public static getInstance(): VibrationUtils {
    if (!VibrationUtils.instance) {
      VibrationUtils.instance = new VibrationUtils();
    }
    return VibrationUtils.instance;
  }

  private audioManager: audio.AudioManager;
  private audioVolumeManager: audio.AudioVolumeManager;
  private audioVolumeGroupManager: audio.AudioVolumeGroupManager | null = null;

  constructor() {
    this.audioManager = audio.getAudioManager()
    this.audioVolumeManager = this.audioManager.getVolumeManager()
    this.getVolumeGroupManager();
  }

  /**
   * once Vibration
   */
  public onceVibration(): void {
    try {
      LogUtils.i(TAG, `onceVibration start, systemUsage: ${ONCE_VIBRATION_SYSTEM_USAGE}`);
      vibrator.startVibration({
        type: 'time',
        duration: 1000
      }, {
        usage: 'physicalFeedback',
        systemUsage: ONCE_VIBRATION_SYSTEM_USAGE
      }, (error) => {
        if (error) {
          LogUtils.i(TAG, 'onceVibration fail, error.code: ' + error.code + ' ,error.message: ' + error.message);
          return;
        }
        LogUtils.i(TAG, 'onceVibration Callback returned to indicate a successful vibration.');
      });
    } catch (err) {
      LogUtils.e(TAG, 'onceVibration errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
  }

  /**
   * once Vibration Fail
   */
  public onceVibrationFail(): void {
    try {
      vibrator.startVibration({
        type: 'preset',
        effectId: 'haptic.notice.fail',
        count: 1,
      }, {
        usage: 'physicalFeedback',
        systemUsage: ONCE_VIBRATION_SYSTEM_USAGE
      }, (error) => {
        if (error) {
          LogUtils.i(TAG, 'onceVibrationFail fail, error.code: ' + error.code + ' ,error.message: ' + error.message);
          return;
        }
        LogUtils.i(TAG, 'onceVibrationFail Callback returned to indicate a successful vibration.');
      });
    } catch (err) {
      LogUtils.e(TAG, 'onceVibrationFail errCode: ' + (err as BusinessError).code + ' ,msg: ' +
      (err as BusinessError).message);
    }
  }

  /**
   * get audio volumeGroupManager
   */
  private getVolumeGroupManager(): void {
    let groupId: number = audio.DEFAULT_VOLUME_GROUP_ID;
    try {
      let value: audio.AudioVolumeGroupManager = this.audioVolumeManager?.getVolumeGroupManagerSync(groupId);
      if (!value) {
        LogUtils.e(TAG, `Failed to obtain the volume group manager.`);
        return;
      }
      LogUtils.i(TAG, 'Callback invoked to indicate that the volume group infos list is obtained.');
      this.audioVolumeGroupManager = value;
    } catch (err) {
      LogUtils.e(TAG, `Failed to obtain the volume group infos list. ${err}`);
    }
  }

  /**
   * get audio ringerMode
   */
  public getRingerMode(callback: Function): void {
    if (!this.audioVolumeGroupManager) {
      LogUtils.i(TAG, 'audioVolumeGroupManager is noty exist');
      return;
    }
    this.audioVolumeGroupManager.getRingerMode((err: BusinessError,
      value: audio.AudioRingMode) => {
      if (err) {
        LogUtils.e(TAG, `Failed to obtain the ringer mode. ${err}`);
        return;
      }
      LogUtils.i(TAG, `Callback invoked to indicate that the ringer mode is obtained ${value}.`);
      callback(value);
    });
  }

  /**
   * get call voice value
   */
  public getCallVolume(callback: Function): void {
    if (!this.audioVolumeGroupManager) {
      LogUtils.i(TAG, 'audioVolumeGroupManager is noty exist');
      return;
    }
    this.audioVolumeGroupManager.getVolume(audio.AudioVolumeType.VOICE_CALL,
      (err: BusinessError, value: number) => {
        if (err) {
          LogUtils.e(TAG, `Failed to obtain the volume. ${err}`);
          return;
        }
        LogUtils.i(TAG, `Callback invoked to indicate that the volume is obtained ${value}.`);
        callback(value);
      });
  }
}