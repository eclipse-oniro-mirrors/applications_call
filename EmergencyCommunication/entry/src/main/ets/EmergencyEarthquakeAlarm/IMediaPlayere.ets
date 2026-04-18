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
import media from '@ohos.multimedia.media';
import { BusinessError } from '@ohos.base';
import { Context } from '@ohos.abilityAccessCtrl';
import LogUtils from '../utils/HiLog';
import { audio } from '@kit.AudioKit';
import { taskpool } from '@kit.ArkTS';
import OperatePlayer from '../control/OperatePlayer';

const TAG = 'IMediaPlayer';
const stateIdle = 'idle';
const stateInitialized = 'initialized';
const statePrepared = 'prepared';
const statePlaying = 'playing';
const statePaused = 'paused';
const stateCompleted = 'completed';
const stateStopped = 'stopped';
const stateReleased = 'released';
const DIDI_DELAY_PLAY_TIMES = 370;


export class IMediaPlayer {
  private count: number = 0;
  private isSeek: boolean = false;
  private fileSize: number = -1;
  private fd: number = 0;
  private context: Context;
  private avPlayer?: media.AVPlayer;
  private speed: number = 1;

  private audioManager = audio.getAudioManager();
  private audioSessionManager: audio.AudioSessionManager = this.audioManager.getSessionManager();

  private strategy: audio.AudioSessionStrategy = {
    concurrencyMode: audio.AudioConcurrencyMode.CONCURRENCY_PAUSE_OTHERS
  };

  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_NOTIFICATION, // 音频流使用类型
    rendererFlags: 0 // 音频渲染器标志
  }

  constructor(context: Context, usage?: number) {
    this.context = context;
    if (usage !== undefined) {
      this.audioRendererInfo.usage = usage;
    }
  }

  setAVPlayerCallback(avPlayer: media.AVPlayer, onPlayCompleted?: () => void): void {
    avPlayer.on('seekDone', (seekDoneTime: number) => {
      LogUtils.i(TAG, `AVPlayer seek succeeded, seek time is ${seekDoneTime}`)
    });
    avPlayer.on('error', (err: BusinessError) => {
      avPlayer.reset();
    });
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case stateIdle:
          LogUtils.i(TAG, 'AVPlayer state idle called.');
          break;
        case stateInitialized:
          LogUtils.i(TAG, 'AVPlayer state initialized called.');
          if (this.avPlayer) {
            this.avPlayer.audioRendererInfo = this.audioRendererInfo;
          }
          avPlayer.prepare();
          break;
        case statePrepared:
          LogUtils.i(TAG, 'AVPlayer state prepared called.');
          avPlayer.setSpeed(this.speed);
          avPlayer.play();
          break;
        case statePlaying:
          LogUtils.i(TAG, 'AVPlayer state playing called.');
          break;
        case statePaused:
          LogUtils.i(TAG, 'AVPlayer state paused called.');
          avPlayer.play();
          break;
        case stateCompleted:
          LogUtils.i(TAG, 'AVPlayer state completed called.');
          avPlayer.stop();
          if (onPlayCompleted) {
            onPlayCompleted();
          }
          break;
        case stateStopped:
          LogUtils.i(TAG, 'AVPlayer state stopped called.');
          avPlayer.reset();
          break;
        case stateReleased:
          LogUtils.i(TAG, 'AVPlayer state released called.');
          break;
        default:
          LogUtils.i(TAG, 'AVPlayer state unknown called.');
          break;
      }
    });
  }

  async release(): Promise<void> {
    if (this.avPlayer !== undefined) {
      this.avPlayer.release();
      return;
    }
  }

  async reset(): Promise<void> {
    if (this.avPlayer !== undefined) {
      this.avPlayer.reset();
    }
  }

  doPlayThread(rawFd: string, delayTimes: number = DIDI_DELAY_PLAY_TIMES) {
    let subTask = new taskpool.Task(OperatePlayer.doPlayThread, this.context, rawFd);
    // 数组和didi声音一起播放是，延后370ms
    taskpool.executeDelayed(delayTimes, subTask).then(() => {
      LogUtils.i(TAG, `doPlayThread done`);
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, `execute doPlayThread error=${JSON.stringify(error?.code)}`);
    });
  }

  setActivateAudioSession() {
    this.audioSessionManager.activateAudioSession(this.strategy).then(() => {
      LogUtils.i(TAG, 'activateAudioSession SUCCESS');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `activateAudioSession ERROR: ${err.code}`);
    });
  }

  deactivateAudioSession() {
    this.audioSessionManager.deactivateAudioSession().then(() => {
      LogUtils.i(TAG, 'deactivateAudioSession SUCCESS');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `deactivateAudioSession ERROR: ${err.code}`);
    });
  }

  async doPlaySync(rawFd: string): Promise<void> {
    return new Promise(async (resolve) => {
      if (rawFd === undefined) {
        LogUtils.i(TAG, `doPlaySync rawFd null`);
        return;
      }
      LogUtils.i(TAG, `doPlaySync rawFd: ${rawFd}`);
      const onPlayCompleted = () => {
        LogUtils.i(TAG, 'doPlaySync :onPlayCompleted');
        resolve();
      }
      if (this.avPlayer === undefined) {
        this.avPlayer = await media.createAVPlayer();
      }
      this.setAVPlayerCallback(this.avPlayer, onPlayCompleted);
      if (this.avPlayer.state !== stateIdle) {
        await this.avPlayer.reset();
      }
      let fileDescriptor = await this.context.resourceManager.getRawFd(rawFd);
      let avFileDescriptor: media.AVFileDescriptor =
        { fd: fileDescriptor.fd, offset: fileDescriptor.offset, length: fileDescriptor.length };
      this.isSeek = false;
      this.avPlayer.fdSrc = avFileDescriptor;
    });
  }

  async doPlay(rawFd: string, onPlayCompleted?: () => void): Promise<void> {
    this.speed = 1; // speed 1 X
    LogUtils.i(TAG, `doPlay`);
    if (rawFd === undefined) {
      LogUtils.i(TAG, `doPlay rawFd is undefined`);
      return;
    }
    if (this.avPlayer === undefined) {
      this.avPlayer = await media.createAVPlayer();
      this.setAVPlayerCallback(this.avPlayer, onPlayCompleted);
    }
    if (this.avPlayer.state !== stateIdle) {
      await this.avPlayer.reset();
    }
    let fileDescriptor = await this.context.resourceManager.getRawFd(rawFd);
    let avFileDescriptor: media.AVFileDescriptor =
      { fd: fileDescriptor.fd, offset: fileDescriptor.offset, length: fileDescriptor.length };
    this.isSeek = false;
    this.avPlayer.fdSrc = avFileDescriptor;
  }
}