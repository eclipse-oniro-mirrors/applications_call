/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { describe, beforeEach, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium'
import { SampleUtil } from '../../../../../main/ets/common/utils/SampleUtil';
import { media } from '@kit.MediaKit';

export default function SampleUtilTest() {
  describe('SampleUtilTest', () => {
    let mocker: MockKit;
    let sampleUtil: SampleUtil = new SampleUtil();
    beforeEach(() => {
      mocker = new MockKit();
    })

    it('SampleUtilTest_trySaveSamples', 0, async () => {
      let res = true;
      try {
        await sampleUtil.trySaveSamples('1');
        await sampleUtil.trySaveSamples('');
      } catch (e) {
        res = false;
      }
      expect(res).assertFalse();
    })

    it('SampleUtilTest_writeWaveSamplesToFile', 0, () => {
      let res = true;
      try {
        sampleUtil.writeWaveSamplesToFile('path', [1, 2, 3]);
      } catch (e) {
        res = false;
      }
      expect(res).assertTrue();
    });

    it('SampleUtilTest_startAmplitudeTimer', 0, async  () => {
      let res = true;
      try {
        let avRecorder = await media.createAVRecorder();
        sampleUtil.startAmplitudeTimer(avRecorder);
      } catch (e) {
        res = false;
      }
      expect(res).assertTrue();
    });

    it('SampleUtilTest_fixSamples', 0, async () => {
      let res = true;
      try {
        let samples: number[] = [1, 2, 3];
        await sampleUtil.fixSamples('testPath', samples);
      } catch (e) {
        res = false;
      }
      expect(res).assertFalse();
    });
  })
}