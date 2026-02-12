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
import { describe, beforeAll, it, expect } from '@ohos/hypium'
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../../../testability/TestAbility';
import { BarEntry } from '../../../../../../main/ets/feature/mpchart';
import Highlight from '../../../../../../main/ets/feature/mpchart/highlight/Highlight';

export default function HighlightTest() {
  describe('HighlightTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('equalToTest01', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let highLight2: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = highLight.equalTo(highLight2);
      expect(result).assertTrue();
    })
    it('equalToTest02', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let result = highLight.equalTo(null);
      expect(result).assertFalse();
    })
    it('equalToTest03', 0, () => {
      let entry: BarEntry = new BarEntry(1, [1, 2]);
      let highLight: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        0,
        0, 0,
        null
      );
      let highLight2: Highlight = new Highlight(
        entry.getX(), entry.getY(), 0, 0,
        2,
        1, 1,
        null
      );
      let result = highLight.equalTo(highLight2);
      expect(result).assertFalse();
    })
  })
}