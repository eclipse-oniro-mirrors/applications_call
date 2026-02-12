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
import { describe, expect, it, MockKit } from '@ohos/hypium'
import { LogUtil } from '../../../../main/ets/util/LogUtil'
import { FontScaleState } from '../../../../main/ets/util/fontScaleState'

const TAG = 'FontScaleState';

interface FontScaleStateTestCase {
  scales: (number | undefined)[];
  gears: number[];
  result: (number | string)[];
}

export default function FontScaleStateTest() {
  describe('FontScaleStateTest', () => {
    it('isStandardGear', 0, () => {
      expect(FontScaleState.isStandardGear(0)).assertTrue()
      expect(FontScaleState.isStandardGear(1)).assertFalse()
    })
    it('isSmallerTwoGear', 0, () => {
      expect(FontScaleState.isSmallerTwoGear(1)).assertTrue()
      expect(FontScaleState.isSmallerTwoGear(2)).assertFalse()
    })
    it('isSmallerThirdGear', 0, () => {
      expect(FontScaleState.isSmallerThirdGear(1)).assertTrue()
      expect(FontScaleState.isSmallerThirdGear(3)).assertFalse()
    })
    it('isBiggerThirdGear', 0, () => {
      expect(FontScaleState.isBiggerThirdGear(1)).assertFalse()
      expect(FontScaleState.isBiggerThirdGear(4)).assertTrue()
    })
    it('isSmallerFourGear', 0, () => {
      expect(FontScaleState.isSmallerFourGear(1)).assertTrue()
      expect(FontScaleState.isSmallerFourGear(4)).assertFalse()
    })
    it('isSmallerSixGear', 0, () => {
      expect(FontScaleState.isSmallerSixGear(1)).assertTrue()
      expect(FontScaleState.isSmallerSixGear(6)).assertFalse()
    })
    it('fetchSeniorTopAndBottomSpace', 0, () => {
      let testCase: FontScaleStateTestCase = {
        scales: [undefined, 1, 1.15, 1.3, 1.45, 1.75, 2, 2.25, 3.2],
        gears: [0, 0, 1, 2, 3, 4, 5, 6, 7],
        result: [1, 1, 10, 10, 10, '16vp', '20vp', '24vp', '24']
      }
      testCase.scales.forEach((value: number | undefined, index: number) => {
        FontScaleState.updateAppFontGearSize(value);
        expect(FontScaleState.fetchSeniorTopAndBottomSpace(testCase.gears[index], 1, 10))
          .assertEqual(testCase.result[index]);
      })
    })
  })
}