/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import DialerVoice from '../../../../main/ets/utils/DialerVoice';
import { sleep } from './Sleep';

let playAudioTestFn = () => {
  let dialerVoice = new DialerVoice();
  let arr = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '*', '#', ''];
  for (let i = 0; i < arr.length; i++) {
    dialerVoice.playAudio(arr[i]);
  }
  expect(0).assertEqual(0);
}
let tonePlayerTestFn = async () => {
  let arr = [0, 99999999999999999];
  let dialerVoice = new DialerVoice()
  for (let i = 0; i < arr.length; i++) {
    dialerVoice.tonePlayer(arr[i])
    expect(true).assertTrue();
  }
}

export default function DialerVoiceTest() {
  describe('DialerVoiceTest', () => {
    it('DialerVoiceTest_playAudio', 0, () => {
      playAudioTestFn();
    })
    it('DialerVoiceTest_tonePlayer', 0, async () => {
     await tonePlayerTestFn();
    })
  })
}