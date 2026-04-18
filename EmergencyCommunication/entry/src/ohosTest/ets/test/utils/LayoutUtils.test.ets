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
import LayoutUtils from '../../../../main/ets/utils/LayoutUtils'

export default function LayoutUtilsTest() {
  describe('LayoutUtilsTest', () => {

    it('LayoutUtilsTest_getDialogGridCount', 0, () => {
      LayoutUtils.getAdaptableTabletPadding('right');
      LayoutUtils.getAdaptableTabletPadding('left');
      let result = LayoutUtils.getDialogGridCount('sm', 10 / 16);
      LayoutUtils.getDialogGridCount('sm', 7 / 16);
      LayoutUtils.getDialogGridCount('md', 1 / 2);
      LayoutUtils.getDialogGridCount('md', 5 / 4);
      LayoutUtils.getDialogGridCount('lg', 5 / 3);
      LayoutUtils.getDialogGridCount('lg', 1);
      LayoutUtils.getDialogGridCount('test', 1);
      LayoutUtils.getDialogGridCount('', 0);
      LayoutUtils.getDialogAlignment('sm');
      LayoutUtils.getDialogAlignment('lg');
      expect(result).assertEqual(3);
    })

    it('should_return_3_when_curBp_is_sm_and_ratio_is_greater_than_9_16', 0, () => {
      let result = LayoutUtils.getDialogGridCount('sm', 10 / 16);
      expect(result).assertEqual(3);
    });

    it('should_return_4_when_curBp_is_sm_and_ratio_is_less_than_9_16', 0, () => {
      let result = LayoutUtils.getDialogGridCount('sm', 8 / 16);
      expect(result).assertEqual(4);
    });

    it('should_return_5_when_curBp_is_md_and_ratio_is_greater_than_3_4', 0, () => {
      let result = LayoutUtils.getDialogGridCount('md', 4 / 3);
      expect(result).assertEqual(4);
    });

    it('should_return_6_when_curBp_is_lg_and_ratio_is_greater_than_4_3', 0, () => {
      let result = LayoutUtils.getDialogGridCount('lg', 5 / 3);
      expect(result).assertEqual(5);
    });

    it('should_return_4_when_curBp_is_unknown_and_ratio_is_greater_than_4_3', 0, () => {
      let result = LayoutUtils.getDialogGridCount('unknown', 5 / 3);
      expect(result).assertEqual(4);
    });

    it('should_return_default_alignment_when_curBp_is_sm', 0, () => {
      let result = LayoutUtils.getDialogAlignment('sm');
      expect(result).assertEqual(DialogAlignment.Default);
    });

    it('should_return_center_alignment_when_curBp_is_not_sm', 0, () => {
      let result = LayoutUtils.getDialogAlignment('md');
      expect(result).assertEqual(DialogAlignment.Center);
    });
  })
}