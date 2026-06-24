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
import { IMediaPlayer } from '../EmergencyEarthquakeAlarm/IMediaPlayere';
import LogUtils from '../utils/HiLog';
import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';

namespace OperatePlayer {

  /**
   * 异步线程播放地震didi声音
   *
   * @param context 上下文
   * @param rawFd 资源文件
   */
  @Concurrent
  export function doPlayThread(context: common.Context, rawFd: string) {
    LogUtils.i('IMediaPlayer', `doPlayThread on thread mediaPlayer `);
    try {
      let mediaPlayer: IMediaPlayer = new IMediaPlayer(context, audio.StreamUsage.STREAM_USAGE_ALARM)
      mediaPlayer.doPlay(rawFd);
    } catch (e) {
      LogUtils.i('IMediaPlayer', `doPlayThread on thread error ${JSON.stringify(e)}`);
    }
    LogUtils.i('IMediaPlayer', `doPlayThread on thread end`);
  }
}

export default OperatePlayer;