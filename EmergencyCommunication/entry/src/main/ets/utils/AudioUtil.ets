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
import audio from '@ohos.multimedia.audio';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from './HiLog';

const TAG = `AudioUtil`;

export class AudioUtil {
  private static sInstance: AudioUtil;
  public static readonly BUSINESS_MAIN_KEY = 'carrier_call';
  public static audioManager: audio.AudioManager = audio.getAudioManager();
  public static readonly SOS_OLD_MEDIA_VOLUME = 'sos_oldMediaVolume';
  public audioManager: audio.AudioManager = audio.getAudioManager();
  public audioVolumeGroupManager: audio.AudioVolumeGroupManager | null = null;

  constructor() {
    this.getAudioVolumeGroupManager();
  }

  public static getInstance() {
    if (AudioUtil.sInstance == null) {
      AudioUtil.sInstance = new AudioUtil();
    }
    return AudioUtil.sInstance;
  }

  public static async setCallAudioParameters(kvPairs: Record<string, string>): Promise<void> {
    return AudioUtil.audioManager.setExtraParameters(AudioUtil.BUSINESS_MAIN_KEY, kvPairs);
  }

  private getAudioManager() {
    if (!this.audioManager) {
      this.audioManager = audio.getAudioManager();
    }
    return this.audioManager;
  }

  private getAudioVolumeGroupManager() {
    try {
      if (!this.audioVolumeGroupManager) {
        const audioManager = this.getAudioManager();
        const audioVolumeManager: audio.AudioVolumeManager = audioManager.getVolumeManager();
        this.audioVolumeGroupManager = audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID);
      }
    } catch (e) {
      LogUtils.e(TAG, `getAudioVolumeGroupManager error: ${JSON.stringify(e)}`);
    }
    return this.audioVolumeGroupManager;
  }

  public async setMaxVolumeOfMedia() {
    LogUtils.i(TAG, 'setMaxVolumeOfMedia');
    try {
      const audioManager = this.getAudioManager();
      const audioVolumeGroupManager = this.getAudioVolumeGroupManager();
      if (!audioVolumeGroupManager) {
        LogUtils.e(TAG, `setMaxVolumeOfMedia: audioVolumeGroupManager is empty`);
        return;
      }
      const oldMediaVolume = audioVolumeGroupManager.getVolumeSync(audio.AudioVolumeType.MEDIA);
      const volumeMediaMax: number = audioVolumeGroupManager.getMaxVolumeSync(audio.AudioVolumeType.MEDIA);
      AppStorage.setOrCreate(AudioUtil.SOS_OLD_MEDIA_VOLUME, oldMediaVolume);
      await audioManager.disableSafeMediaVolume().then(() => {
        LogUtils.i(TAG, 'disableSafeMediaVolume success.');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `disableSafeMediaVolume fail: ${err.code},${err.message}`);
      });
      await audioVolumeGroupManager.setVolume(audio.AudioVolumeType.MEDIA, volumeMediaMax)
        .catch((err: BusinessError) => {
          LogUtils.e(TAG, `Failed to set the volume. ${err}`);
        });
    } catch (e) {
      LogUtils.e(TAG, `setMaxVolumeOfMedia error: ${JSON.stringify(e)}`)
    }
  }

  public async recoverMediaVolume() {
    LogUtils.i(TAG, 'recoverMediaVolume');
    if (!AppStorage.has(AudioUtil.SOS_OLD_MEDIA_VOLUME)) {
      LogUtils.w(TAG, 'recoverMediaVolume: not have oldMediaVolume');
      return;
    }
    try {
      const audioVolumeGroupManager = this.getAudioVolumeGroupManager();
      if (!audioVolumeGroupManager) {
        LogUtils.e(TAG, `recoverMediaVolume: audioVolumeGroupManager is empty`);
        return;
      }
      const oldMediaVolume = AppStorage.get<number>(AudioUtil.SOS_OLD_MEDIA_VOLUME);
      if (typeof oldMediaVolume === 'number' && !isNaN(oldMediaVolume)) {
        await audioVolumeGroupManager.setVolume(audio.AudioVolumeType.MEDIA, oldMediaVolume).then(() => {
          LogUtils.i(TAG, 'recoverRingtoneVolume: set MEDIA Volume success.');
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `recoverMediaVolume: Failed to set the MEDIA volume. ${err}`);
        });
      }
    } catch (e) {
      LogUtils.e(TAG, `recoverMediaVolume error: ${JSON.stringify(e)}`)
    }
  }
}

export const enum AudioParams {
  /** Set 'audio2voicet' to true, then play recordings only to the other end of the call  */
  AUDIO2VOICE = 'audio2voicetx',
  MUTE_TTS = 'mute_tts',
  INPUT_MUTE = 'input_mute',
  OUTPUT_MUTE = 'output_mute',
  MUTE_CALL = 'mute_call',
  AUDIO_MIX2VOICE = 'audiomix2voicetx'
}