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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { IMediaPlayer } from '../../../main/ets/EmergencyEarthquakeAlarm/IMediaPlayere'
import { media } from '@kit.MediaKit';
export default function IMediaPlayerTest() {
  describe('IMediaPlayerTest', () => {
    beforeAll(() => {
    })
    beforeEach(() => {
    })
    afterEach(() => {
    })
    afterAll(() => {
    })
    it('IMediaPlayerTest_1', 0, () => {
      let a = 'test'
      let iMediaPlayer = new IMediaPlayer(getContext());
      iMediaPlayer.release();
      iMediaPlayer.reset()
      iMediaPlayer.doPlay('di.mp3')
      expect(a).assertEqual('test')
    })
  })
}