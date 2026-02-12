/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { describe, it, expect } from '@ohos/hypium';
import { FontScaleState } from '../../../../../main/ets/common/utils/FontScaleState';

const updateAppFontGearSize_test_01 = () => {
  const testData: number = 1;
  FontScaleState.updateAppFontGearSize(testData);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('13vp');
}

const updateAppFontGearSize_test_02 = () => {
  const testData: number = 1.8;
  FontScaleState.updateAppFontGearSize(testData);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('16vp');
}

const updateAppFontGearSize_test_03 = () => {
  const testData: number = 2;
  FontScaleState.updateAppFontGearSize(testData);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('20vp');
}

const updateAppFontGearSize_test_04 = () => {
  const testData: number = 2.3;
  FontScaleState.updateAppFontGearSize(testData);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('24vp');
}

const updateAppFontGearSize_test_05 = () => {
  const testData: number = 0.8;
  FontScaleState.updateAppFontGearSize(testData);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('13vp');
}

const updateAppFontGearSize_test_06 = () => {
  FontScaleState.updateAppFontGearSize();
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('13vp');
}

export default function FontScaleStateTest() {
  describe('FontScaleStateTest', () => {
    it('FontScaleState_test_01', 0, () => {
      updateAppFontGearSize_test_01();
      updateAppFontGearSize_test_02();
      updateAppFontGearSize_test_03();
      updateAppFontGearSize_test_04();
      updateAppFontGearSize_test_05();
      updateAppFontGearSize_test_06();
    })
  })
}
