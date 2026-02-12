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
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from "@ohos/hypium";
import { TrifoldManager } from "../../../../../main/ets/common/utils/TrifoldManager";
import { display } from "@kit.ArkUI";
import ScreenAdapterUtils from "../../../../../main/ets/common/utils/ScreenAdapterUtils";
import LogUtils from "../../../../../main/ets/common/utils/LogUtils";

export default function TrifoldManagerTest() {
  describe('rection_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });
    let isTrifold_test_01 = () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      AppStorage.set('FoldStatus', 11);
      let result = trifoldManager.isTrifold();
      expect(result).assertFalse();

      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let isTrifold_test_02 = () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      AppStorage.set('FoldStatus', 21);
      expect(trifoldManager.isTrifold()).assertFalse();

      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let isTrifold_test_03 = () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      AppStorage.set('FoldStatus', 13);
      expect(trifoldManager.isTrifold()).assertFalse();

      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let isTrifold_test_04 = () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      AppStorage.set('FoldStatus', 23);
      expect(trifoldManager.isTrifold()).assertFalse();

      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let isTrifold_test_05 = () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      AppStorage.set('FoldStatus', 1);
      expect(trifoldManager.isTrifold()).assertFalse();

      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let rection_test_01 = () => {
      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      let mocker: MockKit = new MockKit();

      let mockIsTrifold: Function = mocker.mockFunc(trifoldManager, trifoldManager.isTrifold);
      when(mockIsTrifold)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let orientation: display.Orientation = display.Orientation.LANDSCAPE_INVERTED;
      const result = trifoldManager.rection(orientation);
      expect(result).assertEqual(display.Orientation.PORTRAIT);

      mocker.ignoreMock(trifoldManager, trifoldManager.isTrifold);
    }

    let rection_test_02 = () => {
      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      let mocker: MockKit = new MockKit();

      let mockIsTrifold: Function = mocker.mockFunc(trifoldManager, trifoldManager.isTrifold);
      when(mockIsTrifold)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let orientation: display.Orientation = display.Orientation.LANDSCAPE;
      const result = trifoldManager.rection(orientation);
      expect(result).assertEqual(display.Orientation.PORTRAIT_INVERTED);

      mocker.ignoreMock(trifoldManager, trifoldManager.isTrifold);
    }

    let rection_test_03 = () => {
      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      let mocker: MockKit = new MockKit();

      let mockIsTrifold: Function = mocker.mockFunc(trifoldManager, trifoldManager.isTrifold);
      when(mockIsTrifold)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let orientation: display.Orientation = display.Orientation.PORTRAIT;
      const result = trifoldManager.rection(orientation);
      expect(result).assertEqual(display.Orientation.LANDSCAPE);

      mocker.ignoreMock(trifoldManager, trifoldManager.isTrifold);
    }

    let rection_test_04 = () => {
      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      let mocker: MockKit = new MockKit();
      AppStorage.set('FoldStatus', 23);
      let mockIsTrifold: Function = mocker.mockFunc(trifoldManager, trifoldManager.isTrifold);
      when(mockIsTrifold)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let orientation: display.Orientation = display.Orientation.PORTRAIT_INVERTED;
      const result = trifoldManager.rection(orientation);
      expect(result).assertEqual(display.Orientation.LANDSCAPE_INVERTED);

      mocker.ignoreMock(trifoldManager, trifoldManager.isTrifold);
    }

    let rection_test_05 = () => {
      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      let mocker: MockKit = new MockKit();
      let mockIsTrifold: Function = mocker.mockFunc(trifoldManager, trifoldManager.isTrifold);
      when(mockIsTrifold)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let screenAdapter = ScreenAdapterUtils.getInstance();
      let mockIsNewFold: Function = mocker.mockFunc(screenAdapter, screenAdapter.isNewFoldPhoneExternalScreen);
      when(mockIsNewFold)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let orientation: display.Orientation = display.Orientation.LANDSCAPE;
      const result = trifoldManager.rection(orientation);
      expect(result).assertEqual(display.Orientation.PORTRAIT);

      mocker.ignoreMock(screenAdapter, screenAdapter.isNewFoldPhoneExternalScreen);
    }

    let rection_test_06 = () => {
      let trifoldManager: TrifoldManager = TrifoldManager.getInstance();
      let mocker: MockKit = new MockKit();

      let screenAdapter = ScreenAdapterUtils.getInstance();
      let mockIsNewFold: Function = mocker.mockFunc(screenAdapter, screenAdapter.isNewFoldPhoneExternalScreen);
      when(mockIsNewFold)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let orientation: display.Orientation = display.Orientation.LANDSCAPE;
      const result = trifoldManager.rection(orientation);
      expect(result).assertEqual(display.Orientation.LANDSCAPE);

      mocker.ignoreMock(screenAdapter, screenAdapter.isNewFoldPhoneExternalScreen);
    }

    it('isTrifold_test_01', 0, () => {
      isTrifold_test_01();
    });
    it('isTrifold_test_02', 0, () => {
      isTrifold_test_02();
    });
    it('isTrifold_test_03', 0, () => {
      isTrifold_test_03();
    });
    it('isTrifold_test_04', 0, () => {
      isTrifold_test_04();
    });
    it('isTrifold_test_05', 0, () => {
      isTrifold_test_05();
    });

    it('rection_test_01', 0, () => {
      rection_test_01();
    });
    it('rection_test_02', 0, () => {
      rection_test_02();
    });
    it('rection_test_03', 0, () => {
      rection_test_03();
    });
    it('rection_test_04', 0, () => {
      rection_test_04();
    });
    it('rection_test_05', 0, () => {
      rection_test_05();
    });
    it('rection_test_06', 0, () => {
      rection_test_06();
    });

  });
}