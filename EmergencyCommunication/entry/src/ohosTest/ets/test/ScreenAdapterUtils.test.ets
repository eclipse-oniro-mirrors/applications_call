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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium'
import ScreenAdapterUtils from '../../../main/ets/utils/ScreenAdapterUtils'

let screen = ScreenAdapterUtils.getInstance();

export default function ScreenAdapterUtilsTest() {
  describe('ScreenAdapterUtilsTest', () => {
    it('ScreenAdapterUtils', 0, () => {
      ScreenAdapterUtils.getInstance();
      screen.isNewFoldPhoneExternalScreen();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      let result = screen.isNewFoldPhoneExternalScreen();
      expect(result).assertFalse();
      mocker.clear(ScreenAdapterUtils);
    })
  })
}