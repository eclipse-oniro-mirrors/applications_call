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

import { describe, it, expect } from '@ohos/hypium';
import CallColumnUtils from '../../../../main/ets/utils/CallColumnUtils';

let call = new CallColumnUtils();

export default function CallColumnUtilsTest() {
  describe('CallColumnUtilsTest', () => {
    // bar plate machine Pixel 3.25
    it('TestCallColumnUtils_01', 0, () => {
      let el = new CallColumnUtils();
      let arr = [300, 500, 700, 900];
      let brr = ['xs', 'sm', 'md', 'lg'];

      for (let i = 0; i < arr.length; i++) {
        el.updateBreakpoint(arr[i] * 3.25);
        let curBp = AppStorage.get<string>('curBp');
        expect(brr.indexOf(curBp ?? 'lg') >= 0).assertTrue();
      }
    })

    it('TestCallColumnUtils_getDialogGridCount_02', 0, () => {
      TestCallColumnUtils_02();
    })

    it('TestCallColumnUtils_03', 0, () => {
      TestCallColumnUtils_03();
    })
    it('TestCallColumnUtils_4', 0, () => {
      (call as object)['getDialogGridCount']();
      call.getItemSpace('sm');
      call.getItemSpace('md');
      call.getItemSpace('test');
      call.getPaddingSpace('sm', true);
      call.getPaddingSpace('xs', true);
      call.getPaddingSpace('md', true);
      call.getPaddingSpace('md', false);
      call.getPaddingSpace('test', false);
      call.getAddressTwoLineShow(undefined);
      call.getAddressTwoLineShow('longlonglonglonglonglonglong' +
        'longlonglonglonglonglonglonglonglonglonglong');
      let result = call.getDualSimPadding('md');
      call.getDualSimPadding('test');
      call.getDualSimPadding('sm');
      call.getDualSimButtonWidth('md');
      call.getDualSimButtonWidth('test');
      call.getDualSimButtonWidth('sm');
      expect(result).assertEqual(67);
    })
  })
}

function TestCallColumnUtils_02() {
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
}

function TestCallColumnUtils_03() {
  let curBpSm = 'sm';
  let curBpLg = 'lg';
  let Alignment = CallColumnUtils.getInstance().getDialogAlignment(curBpSm);
  expect(Alignment).assertEqual(DialogAlignment.Default);
  let Alignments = CallColumnUtils.getInstance().getDialogAlignment(curBpLg);
  expect(Alignments).assertEqual(DialogAlignment.Center);
}

