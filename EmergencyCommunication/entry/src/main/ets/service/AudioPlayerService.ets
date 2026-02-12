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
import media from '@ohos.multimedia.media';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../utils/HiLog';
import { AVPlayerState } from '../data/CommonData';
import { common } from '@kit.AbilityKit';
import { Utils } from '../utils/Utils';
import { SosEmergencyCallController } from '../control/SosEmergencyCallController';
import { audio } from '@kit.AudioKit';
import { CAR_ACCIDENT, FALL_DOWN } from '../utils/Constants'

const TAG = 'AudioPlayerService';

export class AudioPlayerService {
  private static sInstance: AudioPlayerService | null;
  public savedVolume: number | null = null;
  private avPlayerOfSos: media.AVPlayer | null = null;
  private avPlayerOfBeeBuzz: media.AVPlayer | null = null;

  constructor() {
  }

  static getInstance() {
    if (AudioPlayerService.sInstance == null) {
      AudioPlayerService.sInstance = new AudioPlayerService();
    }
    return AudioPlayerService.sInstance;
  }

  public static destroyInstance() {
    AudioPlayerService.sInstance = null;
  }

  private setSosAVPlayerCallbackOnCall(callId: number, failCallback: () => void) {
    this.avPlayerOfSos?.on('seekDone', (seekDoneTime) => {
      LogUtils.i(TAG, `AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    })
    this.avPlayerOfSos?.on('error', (err) => {
      LogUtils.i(TAG, `Invoke avPlayerOfSos failed, code is ${err.code}, message is ${err.message}`);
      this.avPlayerOfSos?.reset();
      failCallback();
    })
    this.avPlayerOfSos?.on('stateChange', async (state, reason) => {
      LogUtils.i(TAG, 'AVPlayer state: ' + state);
      switch (state) {
        case AVPlayerState.IDLE:
          LogUtils.i(TAG, 'AVPlayer state idle called.');
          this.avPlayerOfSos?.release();
          break;
        case AVPlayerState.INITIALIZED:
          LogUtils.i(TAG, 'AVPlayer state initialized called.');
          if (this.avPlayerOfSos) {
            this.avPlayerOfSos.audioRendererInfo = {
              usage: audio.StreamUsage.STREAM_USAGE_VOICE_CALL_ASSISTANT,
              rendererFlags: 0
            };

            this.avPlayerOfSos.prepare();
          }
          break;
        case AVPlayerState.PREPARED:
          LogUtils.i(TAG, 'AVPlayer state prepared called.');
          this.avPlayerOfSos?.play();
          break;
        case AVPlayerState.PLAYING:
          LogUtils.i(TAG, 'AVPlayer state playing called.');
          break;
        case AVPlayerState.PAUSED:
          LogUtils.i(TAG, 'AVPlayer state paused called.');
          break;
        case AVPlayerState.COMPLETED:
          LogUtils.i(TAG, 'AVPlayer state completed called.');
          this.avPlayerOfSos?.stop();
          SosEmergencyCallController.getInstance().endAutoDialSosCallByCallId(callId);
          break;
        case AVPlayerState.STOPPED:
          LogUtils.i(TAG, 'AVPlayer state stopped called.');
          this.avPlayerOfSos?.reset();
          break;
        case AVPlayerState.RELEASED:
          LogUtils.i(TAG, 'AVPlayer state released called.');
          break;
        default:
          LogUtils.i(TAG, 'AVPlayer state unknown called.');
          break;
      }
    })
  }

  public async destroyAvPlayerOfSos(callback?: () => void) {
    LogUtils.i(TAG, 'destroyAvPlayerOfSos');
    if (!this.avPlayerOfSos) {
      callback && callback();
      return;
    }
    LogUtils.i(TAG, 'destroyAvPlayerOfSos avPlayerOfSos state: ' + this.avPlayerOfSos?.state);
    try {
      await this.avPlayerOfSos.reset();
    } catch (e) {
      LogUtils.e(TAG, `destroyAvPlayerOfSos: avPlayerOfSos.reset error: ${JSON.stringify(e)}`);
    }

    if (this.avPlayerOfSos.state !== 'released') {
      try {
        await this.avPlayerOfSos.release();
      } catch (e) {
        LogUtils.e(TAG, `destroyAvPlayerOfSos: avPlayerOfSos.release error: ${JSON.stringify(e)}`);
      }
    }

    this.avPlayerOfSos = null;
    callback && callback();
  }

  public async startPlaySosAudioOnCall(callId: number, failCallback: () => void, type: string) {
    LogUtils.i(TAG, `startPlaySosAudioOnCall type:${type}`);
    const playAudioFunction = async () => {
      this.avPlayerOfSos = await media.createAVPlayer();
      this.setSosAVPlayerCallbackOnCall(callId, failCallback);
      let context = getContext(this) as common.UIAbilityContext;
      let fileName: string = ''
      if (type === 'sosCall') {
        fileName = Utils.getSosAudioFileName();
      } else if (type === CAR_ACCIDENT) {
        fileName = Utils.getPersonalSafetySosAudioFileName(CAR_ACCIDENT);
      } else if (type === FALL_DOWN) {
        fileName = Utils.getPersonalSafetySosAudioFileName(FALL_DOWN);
      }
      if (!fileName) {
        failCallback();
        return;
      }
      let fileDescriptor = await context.resourceManager.getRawFd(fileName);
      let avFileDescriptor: media.AVFileDescriptor =
        { fd: fileDescriptor.fd, offset: fileDescriptor.offset, length: fileDescriptor.length };
      this.avPlayerOfSos.fdSrc = avFileDescriptor;
    }
    try {
      this.destroyAvPlayerOfSos(playAudioFunction);
    } catch (e) {
      LogUtils.e(TAG, 'startPlaySosAudioOnCall failed, error: ' + JSON.stringify(e));
      failCallback();
    }
  }

  public destroyAvPlayerOfBeeBuzz = async (callback?: () => void) => {
    LogUtils.i(TAG, 'destroyAvPlayerOfBeeBuzz');
    if (!this.avPlayerOfBeeBuzz) {
      callback && callback();
      return;
    }

    LogUtils.i(TAG, 'destroyAvPlayerOfBeeBuzz avPlayerOfBeeBuzz state: ' + this.avPlayerOfBeeBuzz.state);
    try {
      await this.avPlayerOfBeeBuzz.reset();
    } catch (e) {
      LogUtils.e(TAG, `destroyAvPlayerOfBeeBuzz: avPlayerOfBeeBuzz.reset error: ${JSON.stringify(e)}`);
    }
    if (this.avPlayerOfBeeBuzz.state !== 'released') {
      try {
        await this.avPlayerOfBeeBuzz.release();
      } catch (e) {
        LogUtils.e(TAG, `destroyAvPlayerOfBeeBuzz: avPlayerOfBeeBuzz.release error: ${JSON.stringify(e)}`);
      }
    }
    this.avPlayerOfBeeBuzz = null;
    callback && callback();
  }
  private setBeeBuzzAVPlayerCallback = () => {
    if (!this.avPlayerOfBeeBuzz) {
      LogUtils.e(TAG, 'setBeeBuzzAVPlayerCallback: avPlayerOfBeeBuzz empty');
      return;
    }
    this.avPlayerOfBeeBuzz.on('seekDone', (seekDoneTime) => {
      LogUtils.i(TAG, `avPlayerOfBeeBuzz seek succeeded, seek time is ${seekDoneTime}`);
    })
    this.avPlayerOfBeeBuzz.on('error', (err) => {
      LogUtils.i(TAG, `Invoke avPlayerOfBeeBuzz failed, code is ${err.code}, message is ${err.message}`);
      this.avPlayerOfBeeBuzz?.reset();
    })
    this.avPlayerOfBeeBuzz.on('stateChange', async (state, reason) => {
      LogUtils.i(TAG, 'avPlayerOfBeeBuzz state: ' + state);
      switch (state) {
        case AVPlayerState.IDLE:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state idle called.');
          this.avPlayerOfBeeBuzz?.release();
          break;
        case AVPlayerState.INITIALIZED:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state initialized called.');
          this.avPlayerOfBeeBuzz?.prepare();
          break;
        case AVPlayerState.PREPARED:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state prepared called.');
          if (this.avPlayerOfBeeBuzz) {
            this.avPlayerOfBeeBuzz.loop = true;
            this.avPlayerOfBeeBuzz.play();
          }
          break;
        case AVPlayerState.PLAYING:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state playing called.');
          break;
        case AVPlayerState.PAUSED:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state paused called.');
          break;
        case AVPlayerState.COMPLETED:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state completed called.');
          this.avPlayerOfBeeBuzz?.stop();
          break;
        case AVPlayerState.STOPPED:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state stopped called.');
          this.avPlayerOfBeeBuzz?.reset();
          break;
        case AVPlayerState.RELEASED:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state released called.');
          break;
        default:
          LogUtils.i(TAG, 'avPlayerOfBeeBuzz state unknown called.');
          break;
      }
    })
  }
  public startPlayBeeBuzzAlarm = () => {
    LogUtils.i(TAG, 'startPlayBeeBuzzAlarm');
    const playAudioFunction = async () => {
      this.avPlayerOfBeeBuzz = await media.createAVPlayer();
      this.setBeeBuzzAVPlayerCallback();
      const context = getContext(this) as common.UIAbilityContext;
      const fileName = 'alarm.ogg';
      const fileDescriptor = await context.resourceManager.getRawFd(fileName);
      let avFileDescriptor: media.AVFileDescriptor =
        { fd: fileDescriptor.fd, offset: fileDescriptor.offset, length: fileDescriptor.length };
      this.avPlayerOfBeeBuzz.fdSrc = avFileDescriptor;
    }
    try {
      this.destroyAvPlayerOfBeeBuzz(playAudioFunction);
    } catch (e) {
      LogUtils.e(TAG, 'startPlayBeeBuzzAlarm failed, error: ' + JSON.stringify(e));
    }
  }
}