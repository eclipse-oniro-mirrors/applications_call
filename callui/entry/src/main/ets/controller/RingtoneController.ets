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
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../common/utils/LogUtils';
import { audio, systemSoundManager } from '@kit.AudioKit';

const TAG = 'RingtoneController';

// 蜂窝铃声流
const STREAM_USAGE_VOICE_RINGTONE = 20;

export const aVPlayerStateIdle = 'idle';
export const aVPlayerStateInitialized = 'initialized';
export const aVPlayerStatePrepared = 'prepared';
export const aVPlayerStatePlaying = 'playing';
export const aVPlayerStateCompleted = 'completed';
export const aVPlayerStateStopped = 'stopped';
export const aVPlayerStateReleased = 'released';

/**
 * 普通语音来电铃声控制器
 */
export class RingtoneController {
  private static instance: RingtoneController | null = null;
  private avPlayer: media.AVPlayer | undefined;
  private state: string = '';
  private isRingtonePlaying: boolean = false;
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: STREAM_USAGE_VOICE_RINGTONE,
    rendererFlags: 0
  }

  public static getInstance(): RingtoneController {
    if (!RingtoneController.instance) {
      RingtoneController.instance = new RingtoneController();
    }
    return RingtoneController.instance;
  }

  private async createAVPlayer(): Promise<void> {
    if (this.avPlayer !== undefined) {
      return;
    }
    let avPlayer: media.AVPlayer = await media.createAVPlayer();
    this.avPlayer = avPlayer;
    this.setAVPlayerCallback(this.avPlayer);
  }

  /**
   * 播放系统默认来电铃声（蜂窝按卡槽；VoIP 应传入 0 使用 SIM0）
   * @param accountId 卡槽 ID，用于获取对应 SIM 卡铃声；非 0/1 时回退 SIM0
   */
  public async playDefaultRingtone(accountId: number = 0): Promise<void> {
    if (this.isRingtonePlaying) {
      LogUtils.i(TAG, 'playDefaultRingtone already playing, return');
      return;
    }
    try {
      let sysSoundManager: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
      const slotId: number = accountId === 1 ? 1 : 0;
      let ringtoneType: systemSoundManager.RingtoneType = slotId === 1 ?
        systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_1 :
        systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_0;
      let result: systemSoundManager.ToneAttrs = await sysSoundManager.getCurrentRingtoneAttribute(ringtoneType);
      let ringtoneUri: string = result.getUri();
      LogUtils.i(TAG, 'playDefaultRingtone ringtoneUri: ' + ringtoneUri);
      let resultArray = await sysSoundManager.openToneList([ringtoneUri]);
      if (!resultArray || resultArray.length === 0 || resultArray[0].length < 2) {
        LogUtils.e(TAG, 'playDefaultRingtone openToneList failed');
        return;
      }
      let fd: number = resultArray[0][1] as number;
      await this.playRingtoneByFd(fd);
    } catch (err) {
      LogUtils.e(TAG, 'playDefaultRingtone error: ' + JSON.stringify(err));
    }
  }

  private async playRingtoneByFd(fd: number): Promise<void> {
    await this.createAVPlayer();
    if (!this.avPlayer || this.avPlayer === undefined) {
      LogUtils.e(TAG, 'playRingtoneByFd avPlayer is undefined');
      this.isRingtonePlaying = false;
      return;
    }
    this.isRingtonePlaying = true;
    this.avPlayer.url = 'fd://' + fd;
  }

  /**
   * 停止来电铃声
   */
  public stopRingtone(): void {
    if (!this.isRingtonePlaying) {
      return;
    }
    this.isRingtonePlaying = false;
    if (this.avPlayer === undefined) {
      return;
    }
    try {
      this.avPlayer.stop();
      LogUtils.i(TAG, 'stopRingtone success');
    } catch (err) {
      LogUtils.e(TAG, 'stopRingtone error: ' + JSON.stringify(err));
    }
  }

  private setAVPlayerCallback(avPlayer: media.AVPlayer): void {
    avPlayer.on('error', (err: BusinessError) => {
      LogUtils.e(TAG, 'AVPlayer error, code: ' + err.code + ', message: ' + err.message);
      this.isRingtonePlaying = false;
      avPlayer.reset();
    });
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      LogUtils.i(TAG, 'AVPlayer state: ' + state);
      this.state = state;
      switch (state) {
        case aVPlayerStateIdle: // 成功调用reset接口后触发该状态机上报。
          avPlayer.release();
          break;
        case aVPlayerStateInitialized: // avplayer 设置播放源后触发该状态上报。
          avPlayer.audioRendererInfo = this.audioRendererInfo;
          avPlayer.prepare();
          break;
        case aVPlayerStatePrepared: // prepare调用成功后上报该状态机。
          avPlayer.play();
          break;
        case aVPlayerStatePlaying: // play成功调用后触发该状态机上报。
          avPlayer.loop = true;
          break;
        case aVPlayerStateCompleted: // 播放结束后触发该状态机上报。
          avPlayer.stop();
          break;
        case aVPlayerStateStopped: // stop接口成功调用后触发该状态机上报。
          avPlayer.reset();
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
}
