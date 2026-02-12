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
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'IMediaPlayer';
const stateIdle = 'idle';
const stateInitialized = 'initialized';
const statePrepared = 'prepared';
const statePlaying = 'playing';
const statePaused = 'paused';
const stateCompleted = 'completed';
const stateStopped = 'stopped';
const stateReleased = 'released';


export class IMediaPlayer {
  private context: Context;
  private avPlayer?: media.AVPlayer;

  constructor(context: Context) {
    this.context = context;
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
          avPlayer.prepare();
          break;
        case statePrepared:
          LogUtils.i(TAG, 'AVPlayer state prepared called.');
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
      this.avPlayer = undefined;
      return;
    }
  }

  async reset(): Promise<void> {
    if (this.avPlayer !== undefined) {
      this.avPlayer.reset();
    }
  }

  async doPlay(rawFd: string, onPlayCompleted?: () => void): Promise<void> {
    try {
      if (rawFd === undefined) {
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
      this.avPlayer.fdSrc = avFileDescriptor;
    } catch (err) {
      LogUtils.e(TAG, `doPlay catch errCode: ${err?.code}, errMessage: ${err?.message}`);
    }
  }
}