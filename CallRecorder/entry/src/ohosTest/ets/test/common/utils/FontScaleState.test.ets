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

import { describe, expect, it } from '@ohos/hypium';
import { FontScaleState } from '../../../../../main/ets/common/utils/FontScaleState';

let FontScaleStateTest = () => {
  FontScaleState.updateAppFontGearSize(1.5);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('13vp');
  FontScaleState.updateAppFontGearSize(1.8);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('16vp');
  FontScaleState.updateAppFontGearSize(2.2);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('20vp');
  FontScaleState.updateAppFontGearSize(3.5);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('24vp');
  FontScaleState.updateAppFontGearSize(0.5);
  expect(FontScaleState.topAndBottomMarginOnScale).assertEqual('13vp');
}

export function FontScaleStateTest01() {
  describe('FontScaleStateTest', () => {
    it('FontScaleStateTest', 0, () => {
      FontScaleStateTest();
    });
  })
}


