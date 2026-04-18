/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import LogUtils from './HiLog';
import audio from '@ohos.multimedia.audio';

const TAG = 'DialerVoice';

export default class DialerVoice {
  private timer: number = 0;

  /*
   * Play different audio resources based on key digits.
   */
  public playAudio(number: string) {
    switch (number) {
      case '1':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_1);
        break;
      case '2':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_2);
        break;
      case '3':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_3);
        break;
      case '4':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_4);
        break;
      case '5':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_5);
        break;
      case '6':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_6);
        break;
      case '7':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_7);
        break;
      case '8':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_8);
        break;
      case '9':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_9);
        break;
      case '0':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_0);
        break;
      case '*':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_S);
        break;
      case '#':
        this.tonePlayer(audio.ToneType.TONE_TYPE_DIAL_P);
        break;
      default:
        LogUtils.e(TAG, 'keyTone src is error');
    }
  }

  async tonePlayer(type: audio.ToneType) {
    LogUtils.i(TAG, 'TonePlayer');
    if (this.timer) {
      clearTimeout(this.timer);
    }

    let audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_DTMF,
      rendererFlags: 0
    };
    this.timer = setTimeout(async () => {
      try {
        let tonePlayer: audio.TonePlayer = await audio.createTonePlayer(audioRendererInfo);
        await tonePlayer.load(type);
        await tonePlayer.start();
        setTimeout(async () => {
          await tonePlayer.stop();
          await tonePlayer.release();
        }, 30)
      } catch (err) {
        LogUtils.e(TAG, 'tonePlayer err = ' + JSON.stringify(err));
      }
    }, 50)
  };
}
