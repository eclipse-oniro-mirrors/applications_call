/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit, when } from '@ohos/hypium';
import display from '@ohos.display';
import { DisplayUtil } from '../../../main/ets/common/utils/DisplayUtil';
import { DisplayUtilDT } from '../../../main/ets/common/utils/DisplayUtilDT';

const isFoldable_test_01 = () => {
  let mocker: MockKit = new MockKit();
  let isFoldable: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.isFoldable);
  when(isFoldable)().afterReturn(true);
  let foldable: boolean = DisplayUtil.isFoldable();
  expect(foldable).assertEqual(true);
}

const isFoldable_test_02 = () => {
  let mocker: MockKit = new MockKit();
  let isFoldable: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.isFoldable);
  when(isFoldable)().afterThrow('test throw exception');
  let foldable: boolean = DisplayUtil.isFoldable();
  expect(foldable || !foldable).assertEqual(true);
}

const getScreenFoldStatus_test_01 = () => {
  let mocker: MockKit = new MockKit();
  let getFoldStatus: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.getFoldStatus);
  when(getFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_EXPANDED);
  let status = DisplayUtil.getScreenFoldStatus();
  expect(status).assertEqual(display.FoldStatus.FOLD_STATUS_EXPANDED);
}

const getScreenFoldStatus_test_02 = () => {
  let mocker: MockKit = new MockKit();
  let getFoldStatus: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.getFoldStatus);
  when(getFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_FOLDED);
  let status = DisplayUtil.getScreenFoldStatus();
  expect(status).assertEqual(display.FoldStatus.FOLD_STATUS_FOLDED);
}

const getScreenFoldStatus_test_03 = () => {
  let mocker: MockKit = new MockKit();
  let getFoldStatus: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.getFoldStatus);
  when(getFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_HALF_FOLDED);
  let status = DisplayUtil.getScreenFoldStatus();
  expect(status).assertEqual(display.FoldStatus.FOLD_STATUS_HALF_FOLDED);
}

const getScreenFoldStatus_test_04 = () => {
  let mocker: MockKit = new MockKit();
  let getFoldStatus: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.getFoldStatus);
  when(getFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_UNKNOWN);
  let status = DisplayUtil.getScreenFoldStatus();
  expect(status).assertEqual(4);
}

const getScreenFoldStatus_test_05 = () => {
  let mocker: MockKit = new MockKit();
  let getFoldStatus: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.getFoldStatus);
  when(getFoldStatus)().afterReturn(-1);
  let status = DisplayUtil.getScreenFoldStatus();
  expect(status).assertEqual(0);
}

const getScreenFoldStatus_test_06 = () => {
  let mocker: MockKit = new MockKit();
  let getFoldStatus: Function = mocker.mockFunc(DisplayUtilDT, DisplayUtilDT.getFoldStatus);
  when(getFoldStatus)().afterThrow('test throw exception');
  let status = DisplayUtil.getScreenFoldStatus();
  expect(status).assertEqual(0);
}

export default function DisplayUtilTest() {
  describe('DisplayUtilTest', () => {
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
    it('isFoldable_test_01', 0, () => {
      isFoldable_test_01();
    })
    it('isFoldable_test_02', 0, () => {
      isFoldable_test_02();
    })
    it('getScreenFoldStatus_test_01', 0, () => {
      getScreenFoldStatus_test_01();
    })
    it('getScreenFoldStatus_test_02', 0, () => {
      getScreenFoldStatus_test_02();
    })
    it('getScreenFoldStatus_test_03', 0, () => {
      getScreenFoldStatus_test_03();
    })
    it('getScreenFoldStatus_test_04', 0, () => {
      getScreenFoldStatus_test_04();
    })
    it('getScreenFoldStatus_test_05', 0, () => {
      getScreenFoldStatus_test_05();
    })
    it('getScreenFoldStatus_test_06', 0, () => {
      getScreenFoldStatus_test_06();
    })
  })
}