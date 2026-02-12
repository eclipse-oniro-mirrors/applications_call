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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import CallColumnUtils from '../../../../../main/ets/common/utils/CallColumnUtils';

export default function CallColumnUtilsTest() {
  describe('CallColumnUtilsTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })

    // bar plate machine Pixel 3.25
    it('testCallSettingColumnUtils_01', 0, () => {
      CallColumnUtils.getInstance().updateBreakpoint(1036);
      let curBp = AppStorage.get<string>('curBp');
      expect(curBp).assertEqual('xs');
      CallColumnUtils.getInstance().updateBreakpoint(1946);
      let curBp1 = AppStorage.get<string>('curBp');
      expect(curBp1).assertEqual('sm');
      CallColumnUtils.getInstance().updateBreakpoint(2726);
      let curBp2 = AppStorage.get<string>('curBp');
      expect(curBp2).assertEqual('md');
      CallColumnUtils.getInstance().updateBreakpoint(2734);
      let curBp3 = AppStorage.get<string>('curBp');
      expect(curBp3).assertEqual('lg');

      CallColumnUtils.getInstance().updateBreakpoint(-1);
      CallColumnUtils.getInstance().updateBreakpoint(320);
    })

    it('testCallSettingColumnUtils_02', 0, () => {
      let curBp = 'sm';
      let ratio = (10 / 16);
      let ratio0 = (9 / 16);
      let gridCount = CallColumnUtils.getInstance().getDialogGridCount(curBp, ratio);
      expect(gridCount).assertEqual(3);
      let gridCount0 = CallColumnUtils.getInstance().getDialogGridCount(curBp, ratio0);
      expect(gridCount0).assertEqual(4);

      let curBp1 = 'md';
      let ratio1 = 1;
      let ratio10 = (3 / 4);
      let gridCount1 = CallColumnUtils.getInstance().getDialogGridCount(curBp1, ratio1);
      expect(gridCount1).assertEqual(4);
      let gridCount10 = CallColumnUtils.getInstance().getDialogGridCount(curBp1, ratio10);
      expect(gridCount10).assertEqual(5);

      let curBp2 = 'lg';
      let ratio2 = 2;
      let ratio20 = (4 / 3);
      let gridCount2 = CallColumnUtils.getInstance().getDialogGridCount(curBp2, ratio2);
      expect(gridCount2).assertEqual(5);
      let gridCount20 = CallColumnUtils.getInstance().getDialogGridCount(curBp2, ratio20);
      expect(gridCount20).assertEqual(6);

      let curBp3 = ' ';
      let ratio3 = 5;
      let gridCount3 = CallColumnUtils.getInstance().getDialogGridCount(curBp3, ratio3);
      expect(gridCount3).assertEqual(4);

      CallColumnUtils.getInstance().getDialogGridCount('', 0);
    })

    it('testCallSettingColumnUtils_03', 0, () => {
      let curBpSm = 'sm';
      let curBpLg = 'lg';
      let Alignment = CallColumnUtils.getInstance().getDialogAlignment(curBpSm);
      expect(Alignment).assertEqual(DialogAlignment.Default);
      let Alignments = CallColumnUtils.getInstance().getDialogAlignment(curBpLg);
      expect(Alignments).assertEqual(DialogAlignment.Center);
    })
    it('testCallSettingColumnUtils_04', 0, () => {
      let curBpXs = 'xs';
      let curBpMd = 'md';
      let curBpLg = 'lg';
      let padding1 = CallColumnUtils.getInstance().getPaddingSpace(curBpXs).id;
      expect(padding1).assertEqual($r('sys.float.padding_level8').id);
      let padding2 = CallColumnUtils.getInstance().getPaddingSpace(curBpMd).id;
      expect(padding2).assertEqual($r('sys.float.padding_level12').id);
      let padding3 = CallColumnUtils.getInstance().getPaddingSpace(curBpLg).id;
      expect(padding3).assertEqual($r('sys.float.padding_level16').id);
    })
  })
}