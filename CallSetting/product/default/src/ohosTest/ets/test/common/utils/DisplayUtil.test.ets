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
import { describe, it, expect, MockKit, when,
  ArgumentMatchers } from '@ohos/hypium'
import { DisplayUtil } from '../../../../../main/ets/common/utils/DisplayUtil'
import { display } from '@kit.ArkUI'

export default function DisplayUtilTest() {
  describe('DisplayUtilTest', () => {

    it('DisplayUtilTest_ScreenFoldStatus', 0, () => {
      DisplayUtil.getScreenFoldStatus();
      DisplayUtil.isExpandedStatus();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(DisplayUtil,DisplayUtil.isFoldable);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      DisplayUtil.isExpandedStatus();
      let mockFunc1 = mocker.mockFunc(DisplayUtil,DisplayUtil.getFoldStatus);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(display.FoldStatus.FOLD_STATUS_EXPANDED);
      let result = DisplayUtil.isExpandedStatus();
      expect(result).assertTrue();
      mocker.ignoreMock(DisplayUtil,DisplayUtil.getFoldStatus);
      mocker.ignoreMock(DisplayUtil,DisplayUtil.isFoldable);
    })
  })
}