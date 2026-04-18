/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../common/utils/LogUtils';
import { audio } from '@kit.AudioKit';
import CallDataManager from '../model/CallDataManager';

const TAG = 'VideoController';

export const aVPlayerStatePlaying = 'playing';
export const aVPlayerStatePrepared = 'prepared';
export const aVPlayerStatePaused = 'paused';
export const aVPlayerStateCompleted = 'completed';
export const aVPlayerStateStopped = 'stopped';
export const aVPlayerStateReleased = 'released';
export const aVPlayerStateInitialized = 'initialized';
export const aVPlayerStateIdle = 'idle';

// 蜂窝铃声流
export const STREAM_USAGE_VOICE_RINGTONE = 20;

export class VideoController {
  private surfaceId: string = '';
  private avPlayer: media.AVPlayer | undefined;
  private state: string = '';
  private isDoNotDisturb: boolean = false;
  private static instance: VideoController | null = null;
  private sizeCallBacks: Function[] = [];
  private accountId: number = -1;
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: STREAM_USAGE_VOICE_RINGTONE,
    rendererFlags: 0
  }

  public static getInstance(): VideoController {
    if (!VideoController.instance) {
      VideoController.instance = new VideoController();
    }
    return VideoController.instance;
  }

  async createAVPlayer() {
    let avPlayer: media.AVPlayer = await media.createAVPlayer();
    this.avPlayer = avPlayer;
    this.setAVPlayerCallback(this.avPlayer);
  }

  async stopPlay() {
    if (this.avPlayer !== undefined) {
      this.avPlayer?.prepare()
      LogUtils.i(TAG, 'stopPlay is called')
    }
  }

  async releasePlay() {
    if (this.avPlayer !== undefined &&
      (!CallDataManager.getInstance().hasIncomingCall() || CallDataManager.getInstance().callList.length === 1)) {
      this.surfaceId = ''
      await this.avPlayer?.release();
      this.avPlayer = undefined;
      LogUtils.i(TAG, 'releasePlay is called')
    }
  }

  async releasePlayAnyway() {
    LogUtils.i(TAG, 'releasePlayAnyway is called')
    if (this.avPlayer !== undefined ) {
      this.surfaceId = '';
      await this.avPlayer?.release();
      this.avPlayer = undefined;
      LogUtils.i(TAG, 'releasePlay is called')
    }
  }

  async doPrepared() {
    if (this.avPlayer !== undefined) {
      await this.avPlayer?.prepare();
      LogUtils.i(TAG, 'doPrepared is called')
    }
  }

  stopRinging() {
    if (this.avPlayer !== undefined && this.state === aVPlayerStatePlaying) {
      this.avPlayer.setVolume(0);
      LogUtils.i(TAG, 'stopRinging is called')
    }
  }

  reRinging() {
    if (this.avPlayer !== undefined && this.state === aVPlayerStatePlaying) {
      try {
        LogUtils.i(TAG, `reRinging is called`);
        this.avPlayer.setVolume(1);
      } catch (err) {
        LogUtils.i(TAG, `getVolumeByStream failed, err:${err?.message} code:${err?.code}`);
      }
    }
  }

  async pausePlay() {
    if (this.avPlayer !== undefined) {
      await this.avPlayer?.pause();
      LogUtils.i(TAG, 'pausePlay is called')
    }
  }

  async rePlay() {
    if (this.avPlayer !== undefined) {
      LogUtils.i(TAG, 'rePlay is called')
      this.avPlayer.surfaceId = this.surfaceId;
      await this.avPlayer?.play();
    }
  }

  // 根据沙箱中视频文件路径播放
  async playVideoByUrl(url: string, surfaceId: string = '') {
    LogUtils.i(TAG, 'playVideoByUrl is called')
    // 创建avPlayer实例对象。
    this.surfaceId = surfaceId;
    if (this.avPlayer === undefined) {
      await this.createAVPlayer();
    }
    if (!this.avPlayer || this.avPlayer === undefined) {
      return;
    }
    let fdPath = 'fd://';
    // 打开相应的资源文件地址获取fd，并为url赋值触发initialized状态机上报。
    let file = await fs.open(url);
    fdPath = fdPath + '' + file.fd;
    this.avPlayer.url = fdPath;
  }

  // 根据沙箱中视频文件路径播放
  async playVideoByFd(fd: number, isDoNotDisturb: boolean, accountId: number, surfaceId: string = '') {
    LogUtils.i(TAG, 'playVideoByFd is called')
    // 创建avPlayer实例对象。
    this.surfaceId = surfaceId;
    this.accountId = accountId;
    if (this.avPlayer === undefined) {
      await this.createAVPlayer();
    }
    if (!this.avPlayer || this.avPlayer === undefined) {
      return;
    }
    this.isDoNotDisturb = isDoNotDisturb;
    let fdPath = 'fd://' + fd;
    this.avPlayer.url = fdPath;
  }

  updateSurfaceId(surfaceId: string) {
    LogUtils.i(TAG, 'updateSurfaceId, surfaceId = ' + surfaceId);
    if (this.avPlayer !== undefined) {
      this.surfaceId = surfaceId;
      this.avPlayer.surfaceId = surfaceId;
      this.updateSizeListeners(this.avPlayer.width, this.avPlayer.height);
    }
  }

  getAvPlayerState() {
    return this.avPlayer?.state;
  }

  getAccountId() {
    return this.accountId;
  }

  // 注册avplayer回调函数。
  // instrument ignore next
  setAVPlayerCallback(avPlayer: media.AVPlayer) {
    // startRenderFrame首帧渲染回调函数。
    avPlayer.on('startRenderFrame', () => {
      LogUtils.i(TAG, `AVPlayer start render frame`);
    });
    // seek操作结果回调函数。
    avPlayer.on('seekDone', (seekDoneTime: number) => {
      LogUtils.i(TAG, `AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    });
    // error回调监听函数,当avPlayer在操作过程中出现错误时调用reset接口触发重置流程。
    avPlayer.on('error', (err: BusinessError) => {
      LogUtils.e(TAG, `Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
      avPlayer.reset(); // 调用reset重置资源，触发idle状态。
    });
    // 状态机变化回调函数。
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      LogUtils.i(TAG, 'AVPlayer state: ' + state)
      this.state = state;
      switch (state) {
        case aVPlayerStateIdle: // 成功调用reset接口后触发该状态机上报。
          avPlayer.release(); // 调用release接口销毁实例对象。
          break;
        case aVPlayerStateInitialized: // avplayer 设置播放源后触发该状态上报。
          if (this.surfaceId !== '') {
            avPlayer.surfaceId = this.surfaceId; // 设置显示画面，当播放的资源为纯音频时无需设置。
          } else {
            // avPlayer.forceLoadVideo(true);
          }
          avPlayer.audioRendererInfo = this.audioRendererInfo;
          if (!CallDataManager.getInstance().hasActiveCall()) {
            avPlayer.audioRendererInfo = this.audioRendererInfo;
          }
          avPlayer.prepare();
          break;
        case aVPlayerStatePrepared: // prepare调用成功后上报该状态机。
          if (this.surfaceId !== '') {
            avPlayer.surfaceId = this.surfaceId; // 设置显示画面，当播放的资源为纯音频时无需设置。
          }
          if (CallDataManager.getInstance().hasActiveCall() || CallDataManager.getInstance().hasCrsCall() ||
            CallDataManager.getInstance().existDialingCall()) {
            avPlayer.setVolume(0);
          }
          this.updateSizeListeners(avPlayer.width, avPlayer.height);
          avPlayer.play(); // 调用播放接口开始播放。
          break;
        case aVPlayerStatePlaying: // play成功调用后触发该状态机上报。
          avPlayer.videoScaleType = 1;
          avPlayer.loop = true
          if (this.isDoNotDisturb) {
            avPlayer.setVolume(0);
          }
          if (this.surfaceId !== '') {
            avPlayer.surfaceId = this.surfaceId; // 设置显示画面，当播放的资源为纯音频时无需设置。
          }
          break;
        case aVPlayerStatePaused: // pause成功调用后触发该状态机上报。
          break;
        case aVPlayerStateCompleted: // 播放结束后触发该状态机上报。
          avPlayer.stop(); //调用播放结束接口。
          break;
        case aVPlayerStateStopped: // stop接口成功调用后触发该状态机上报。
          avPlayer.reset(); // 调用reset接口初始化avplayer状态。
          break;
        case aVPlayerStateReleased:
          this.avPlayer = undefined;
          break;
        default:
          LogUtils.i(TAG, 'AVPlayer state unknown called.');
          break;
      }
    });
  }

  addSizeUpdateCallback(fn: Function): void {
    this.sizeCallBacks.push(fn);
  }

  removeSizeUpdateCallback(fn: Function): void {
    let index: number = this.sizeCallBacks.indexOf(fn);
    if (index < 0 || index >= this.sizeCallBacks.length) {
      return;
    }
    this.sizeCallBacks.splice(index, 1);
    LogUtils.i(TAG, 'removeTimeUpdateCallback index = ' + index);
  }

  public updateSizeListeners(curWith: number, curHeight: number) {
    if (curWith === 0 || curHeight === 0) {
      LogUtils.i(TAG, 'updateStatusListeners, invalid size, return.');
      return;
    }
    this.sizeCallBacks.forEach((fn: Function) => {
      fn(curWith, curHeight);
    });
  }
}