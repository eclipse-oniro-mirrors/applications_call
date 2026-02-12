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
import { display } from '@kit.ArkUI';
import { describe, beforeEach, afterEach, it, expect, } from '@ohos/hypium';
import { DisplayUtils } from '../../../../main/ets/util/DisplayUtils';

export default function DisplayUtilsTest() {
  describe('DisplayUtilsTest', () => {

    it('DisplayUtilsTest_isSplit', 0, () => {
      let foldable: boolean = false;
      let status: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;
      let result = false;
      try {
        foldable = display.isFoldable();
        status = display.getFoldStatus();
      } catch (e) {
      }
      result = (foldable && (status === display.FoldStatus.FOLD_STATUS_EXPANDED ||
        status === display.FoldStatus.FOLD_STATUS_HALF_FOLDED));
      DisplayUtils.registerFoldStatusChanged();
      expect(DisplayUtils.isSplit(getContext())).assertEqual(result);
    });


    it('DisplayUtilsTest_unregisterFoldStatusChanged', 0, () => {
      DisplayUtils.unregisterFoldStatusChanged();
      expect(AppStorage.get(`foldStatus`)).assertUndefined();
    });

  })
}
