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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import { ScreenInfo } from '../../../main/ets/common/struct/CallUiDataStruct';
import CallColumnUtils, { AppHeightBp, AppWidthBp } from '../../../main/ets/common/utils/CallColumnUtils';
import { DisplayUtil } from '../../../main/ets/common/utils/DisplayUtil';
import { sleep } from './Utils';
import LogUtils from '../../../main/ets/common/utils/LogUtils';
import { window } from '@kit.ArkUI';
import { AppWindowStyleData } from '../../../main/ets/common/struct/TypeUtils';

let CallColumnUtilsTest_testCallColumnUtils = () => {
  let curBp = 'sm';
  let ratio = (9 / 16);
  let gridCount = CallColumnUtils.getInstance().getDialogGridCount(curBp, ratio);
  expect(gridCount).assertEqual(4);
  let ratio1 = (10 / 16);
  let gridCount1 = CallColumnUtils.getInstance().getDialogGridCount(curBp, ratio1);
  expect(gridCount1).assertEqual(3);
  let curBp1 = 'md';
  let ratio2 = (3 / 4);
  let gridCount2 = CallColumnUtils.getInstance().getDialogGridCount(curBp1, ratio2);
  expect(gridCount2).assertEqual(5);
  let ratio3 = (4 / 4);
  let gridCount3 = CallColumnUtils.getInstance().getDialogGridCount(curBp1, ratio3);
  expect(gridCount3).assertEqual(4);
  let curBp2 = 'lg';
  let ratio4 = (4 / 3);
  let gridCount4 = CallColumnUtils.getInstance().getDialogGridCount(curBp2, ratio4);
  expect(gridCount4).assertEqual(6);
  let ratio5 = (5 / 3);
  let gridCount5 = CallColumnUtils.getInstance().getDialogGridCount(curBp2, ratio5);
  expect(gridCount5).assertEqual(5);
  let curBp3 = 'gm';
  let ratio6 = (9 / 16);
  let gridCount6 = CallColumnUtils.getInstance().getDialogGridCount(curBp3, ratio6);
  expect(gridCount6).assertEqual(4);
  let ratio7 = 0;
  let gridCount7 = CallColumnUtils.getInstance().getDialogGridCount(curBp, ratio7);
  expect(gridCount7).assertEqual(4);
}

let CallColumnUtilsTest_updateBreakpoint = () => {
  CallColumnUtils.getInstance().updateBreakpoint(-1);
  AppStorage.setOrCreate('curBp', 'sm');
  CallColumnUtils.getInstance().updateBreakpoint(1000);
  let curBp1 = AppStorage.get<string>('curBp');
  expect(curBp1).assertEqual('xs');
  CallColumnUtils.getInstance().updateBreakpoint(1900);
  let curBp2 = AppStorage.get<string>('curBp');
  expect(curBp2).assertEqual('sm');
  CallColumnUtils.getInstance().updateBreakpoint(2200);
  let curBp3 = AppStorage.get<string>('curBp');
  expect(curBp3).assertEqual('md');
  CallColumnUtils.getInstance().updateBreakpoint(3000);
  let curBp4 = AppStorage.get<string>('curBp');
  expect(curBp4).assertEqual('lg');
  CallColumnUtils.getInstance().updateBreakpoint(3500);
  let curBp5 = AppStorage.get<string>('curBp');
  expect(curBp5).assertEqual('lg');
}

let getItemSpace_test = () => {
  let testDate = 'sm';
  let result = CallColumnUtils.getInstance().getItemSpace(testDate);
  expect(result !== null).assertTrue();
  sleep(1000);
  let testDate1 = 'md';
  let result1 = CallColumnUtils.getInstance().getItemSpace(testDate1);
  expect(result1 !== undefined).assertTrue();
  sleep(1000);
  let testDate2 = 'xs';
  let result2 = CallColumnUtils.getInstance().getItemSpace(testDate2);
  expect(result2 !== undefined).assertTrue();
  result2 = CallColumnUtils.getInstance().getItemSpace(testDate2, true);
  expect(result2 !== undefined).assertTrue();
  testDate2 = 'lg';
  result2 = CallColumnUtils.getInstance().getItemSpace(testDate2);
}

let getPaddingSpace_test_01 = () => {
  let testDate = 'sm';
  let result = CallColumnUtils.getInstance().getPaddingSpace(testDate);
  expect(result !== undefined).assertTrue();
}

let getPaddingSpace_test_02 = () => {
  let testDate = 'md';
  let result = CallColumnUtils.getInstance().getPaddingSpace(testDate);
  expect(result !== undefined).assertTrue();

  testDate = 'lg';
  result = CallColumnUtils.getInstance().getPaddingSpace(testDate);
  expect(result !== undefined).assertTrue();
}


let getPaddingSpace_test_03 = () => {
  let testDate = 'xs';
  let result = CallColumnUtils.getInstance().getPaddingSpace(testDate);
  expect(result !== null).assertTrue();
}

let getRowSpace_test_01 = () => {
  let testDate = 'sm';
  let result = CallColumnUtils.getInstance().getRowSpace(testDate);
  expect(8).assertEqual(result);
}

let getRowSpace_test_02 = () => {
  let testDate = 'md';
  let result = CallColumnUtils.getInstance().getRowSpace(testDate);
  expect(12).assertEqual(result);
}

let getRowSpace_test_03 = () => {
  let testDate = 'xs';
  let result = CallColumnUtils.getInstance().getRowSpace(testDate);
  expect(8).assertEqual(result);
}

let getVideoKeyBoardRowSpace_test_01 = () => {
  let testDate = 'sm';
  let result = CallColumnUtils.getInstance().getVideoKeyBoardRowSpace(testDate);
  expect(0).assertEqual(result);
}

let getVideoKeyBoardRowSpace_test_02 = () => {
  let testDate = 'md';
  let result = CallColumnUtils.getInstance().getVideoKeyBoardRowSpace(testDate);
  expect(8).assertEqual(result);
}

let getVideoSmall_test_01 = () => {
  let result = CallColumnUtils.getInstance().getVideoSmall('sm', 0, 0)
  expect(typeof result === 'number').assertTrue()
}

let getGridCount_test_01 = () => {
  let testDate = 'sm';
  let result = CallColumnUtils.getInstance().getGridCount(testDate);
  expect(4).assertEqual(result);
}

let getGridCount_test_02 = () => {
  let testDate = 'md';
  let result = CallColumnUtils.getInstance().getGridCount(testDate);
  expect(8).assertEqual(result);
}

let getGridCount_test_03 = () => {
  let testDate = 'xs';
  let result = CallColumnUtils.getInstance().getGridCount(testDate);
  expect(4).assertEqual(result);
}

let getDisplayNameForAutoSize_test = () => {
  let testDate = 'sm';
  let resultTrue = CallColumnUtils.getInstance().getDisplayNameForAutoSize(undefined, testDate, true, true);
  sleep(1000);
  let resultFalse1 = CallColumnUtils.getInstance().getDisplayNameForAutoSize(undefined, testDate, false, true);
  testDate = 'lg';
  let resultFalse = CallColumnUtils.getInstance().getDisplayNameForAutoSize(undefined, testDate, false, true);
  sleep(1000);
  testDate = 'md';
  let result1 = CallColumnUtils.getInstance().getDisplayNameForAutoSize(undefined, testDate);
  AppStorage.delete('windowSizeChangeMd');
  let result2 = CallColumnUtils.getInstance().getDisplayNameForAutoSize(undefined, testDate);
  expect(typeof resultTrue === 'number' || typeof result1 === 'number' || typeof resultFalse === 'number' ||
    typeof resultFalse1 === 'number'|| typeof result2 === 'number' ).assertFalse();
}

let getCallTextHeight_test = () => {
  let result3 = CallColumnUtils.getInstance().getGridWidth('sm');
  expect(typeof result3 === 'number').assertTrue();
  sleep(1000);
  let result4 = CallColumnUtils.getInstance().getGridWidth('md');
  expect(typeof result4 === 'number').assertTrue();
  sleep(1000);
  let result5 = CallColumnUtils.getInstance().getGridWidth('lg');
  expect(typeof result5 === 'number').assertTrue();
}

let addDisplayChange_test = () => {
  let result = CallColumnUtils.getInstance().addDisplayChange();
  expect(result == null).assertTrue();
}

let getUiMaxWidth_test = () => {
  let curBpSm = 'sm';
  let result = CallColumnUtils.getInstance().getUiMaxWidth(curBpSm, 24);
  expect(typeof result === 'number').assertTrue();
  sleep(1000);
  let curBpMd = 'md';
  let result1 = CallColumnUtils.getInstance().getUiMaxWidth(curBpMd, 24);
  expect(typeof result1 === 'number').assertTrue();
  sleep(1000);
  let curBpLg = 'lg';
  let result2 = CallColumnUtils.getInstance().getUiMaxWidth(curBpLg, 24);
  expect(typeof result2 === 'number').assertTrue();
}

let getTextWidth_test = () => {
  let testStr = '你好';
  let result = CallColumnUtils.getInstance().getTextWidth(testStr, 14);
  expect(typeof result === 'number').assertTrue();
}

let splitTextIntoLines_test = () => {
  let testStr = '你好';
  let maxWidth = CallColumnUtils.getInstance().getTextWidth(testStr, 14);
  let result = CallColumnUtils.getInstance().splitTextIntoLines(testStr + testStr, 14, maxWidth);
  expect(result.length).assertEqual(2);
}

let getKeyBordMarginSpace_test_01 = () => {
  let result = CallColumnUtils.getInstance().getKeyBordMarginSpace('xs');
  expect(result !== null).assertTrue();
}

let getKeyBordMarginSpace_test_02 = () => {
  let result = CallColumnUtils.getInstance().getKeyBordMarginSpace('sm');
  expect(result !== null).assertTrue();
}

let getKeyBordMarginSpace_test_03 = () => {
  let result = CallColumnUtils.getInstance().getKeyBordMarginSpace('md');
  expect(result !== null).assertTrue();
}
let getKeyBordMarginSpace_test_04 = () => {
  let result = CallColumnUtils.getInstance().getKeyBordMarginSpace('lg');
  expect(result !== null).assertTrue();
}

let removeDisplayChange_test = () => {
  let result = CallColumnUtils.getInstance().removeDisplayChange();
  expect(result == null).assertTrue();
}

let rowsGap_test_01 = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let windowSizeChangeMd: ScreenInfo = {
    width: 1080,
    height: 1920
  };
  let statusBarHeight: number = 56;
  let airbarHeight: number = 56;
  let curBp: string = 'md';
  let result = callcolumnutils.rowsGap(windowSizeChangeMd, false, statusBarHeight, airbarHeight, curBp, false);
  expect(result !== null).assertTrue();
}

let rowsGap_test_02 = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let windowSizeChangeMd: ScreenInfo = {
    width: 1080,
    height: 1920
  };
  let statusBarHeight: number = 56;
  let airbarHeight: number = 56;
  let curBp: string = 'sm';
  let mocker: MockKit = new MockKit();
  let displayUtil = new DisplayUtil();
  let mockfunc2: Function = mocker.mockFunc(displayUtil, DisplayUtil.isFoldable);
  when(mockfunc2)().afterReturn(true);
  let mockfunc3: Function = mocker.mockFunc(displayUtil, DisplayUtil.getScreenFoldStatus);
  when(mockfunc3)().afterReturn(2);
  let result = callcolumnutils.rowsGap(windowSizeChangeMd, true, statusBarHeight, airbarHeight, curBp, false);
  expect(result !== null).assertTrue();
  mocker.ignoreMock(displayUtil, DisplayUtil.isFoldable);
  mocker.ignoreMock(displayUtil, DisplayUtil.getScreenFoldStatus);
}

let rowsGap_test_03 = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let windowSizeChangeMd: ScreenInfo = {
    width: 1080,
    height: 1920
  };
  let statusBarHeight: number = 56;
  let airbarHeight: number = 56;
  let curBp: string = 'md';
  let mocker: MockKit = new MockKit();
  let displayUtil = new DisplayUtil();
  let mockfunc2: Function = mocker.mockFunc(displayUtil, DisplayUtil.isFoldable);
  when(mockfunc2)().afterReturn(true);
  let mockfunc3: Function = mocker.mockFunc(displayUtil, DisplayUtil.getScreenFoldStatus);
  when(mockfunc3)().afterReturn(2);
  let result = callcolumnutils.rowsGap(windowSizeChangeMd, true, statusBarHeight, airbarHeight, curBp, false);
  expect(result !== null).assertTrue();
  mocker.ignoreMock(displayUtil, DisplayUtil.isFoldable);
  mocker.ignoreMock(displayUtil, DisplayUtil.getScreenFoldStatus);
}

let gridHeight_test_01 = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let windowSizeChangeMd: ScreenInfo = {
    width: 1080,
    height: 1920
  };
  let isShowSmartWindow: boolean = false;
  let statusBarHeight: number = 56;
  let airbarHeight: number = 56;
  let curBp: string = 'md';
  let result = callcolumnutils.gridHeight(windowSizeChangeMd, isShowSmartWindow, statusBarHeight, airbarHeight, curBp,
    false);
  expect(result !== null).assertTrue();
}

let gridHeight_test_02 = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let windowSizeChangeMd: ScreenInfo = {
    width: 1080,
    height: 1920
  };
  let isShowSmartWindow: boolean = true;
  let statusBarHeight: number = 56;
  let airbarHeight: number = 56;
  let curBp: string = 'sm';
  let mocker: MockKit = new MockKit();
  let displayUtil = new DisplayUtil();
  let mockfunc: Function = mocker.mockFunc(displayUtil, DisplayUtil.isFoldable);
  when(mockfunc)().afterReturn(true);
  let mockfunc2: Function = mocker.mockFunc(displayUtil, DisplayUtil.getScreenFoldStatus);
  when(mockfunc2)().afterReturn(2);

  let result = callcolumnutils.gridHeight(windowSizeChangeMd, isShowSmartWindow, statusBarHeight, airbarHeight, curBp,
    false);
  expect(result !== null).assertTrue();
  mocker.ignoreMock(displayUtil, DisplayUtil.isFoldable);
  mocker.ignoreMock(displayUtil, DisplayUtil.getScreenFoldStatus);
}

let getCallNormalPercent_test_01 = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let windowSize: ScreenInfo = {
    width: 1080,
    height: 1920
  };
  let isShowSmartWindow: boolean = true;
  let statusBarHeight: number = 50;
  let airbarHeight: number = 50;
  let percent: number = 0.5;
  let result = callcolumnutils.getCallNormalPercent(windowSize, isShowSmartWindow, statusBarHeight, airbarHeight, percent);
  expect(result > 0).assertTrue();
}

let getCallNormalPercent_test_02 = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let windowSize: ScreenInfo = {
    width: 1080,
    height: 1920
  };
  let isShowSmartWindow: boolean = true;
  let statusBarHeight: number = 50;
  let airbarHeight: number = 50;
  let percent: number = 0.5;
  callcolumnutils.decorHeight = 100;
  let result = callcolumnutils.getCallNormalPercent(windowSize, isShowSmartWindow, statusBarHeight, airbarHeight, percent);
  expect(result > 0).assertTrue();
}

let getWindowDecorHeight_test = () => {
  let callcolumnutils: CallColumnUtils = new CallColumnUtils();
  let mocker: MockKit = new MockKit();
  let mockLogUtilsE: Function = mocker.mockFunc(LogUtils, LogUtils.e);
  when(mockLogUtilsE)(ArgumentMatchers.anyString).afterReturnNothing();

  const windowObj = AppStorage.get<window.Window>('testWindow');
  if (!windowObj) {
    return;
  }
  let result = callcolumnutils.getWindowDecorHeight(windowObj);
  expect(result !== null).assertTrue();

  mocker.ignoreMock(LogUtils, LogUtils.e);
}

export default function CallColumnUtilsTest() {
  describe('CallColumnUtilsTest', () => {
    it('testCallColumnUtils', 0, () => {
      CallColumnUtilsTest_testCallColumnUtils();
    })
    it('getDialogAlignment', 0, () => {
      let curBp = 'sm';
      let result = CallColumnUtils.getInstance().getDialogAlignment(curBp);
      expect(result).assertEqual(DialogAlignment.Default);
    })
    it('getDialogAlignmentTablet', 0, () => {
      let curBp = 'lg';
      let result = CallColumnUtils.getInstance().getDialogAlignment(curBp);
      expect(result).assertEqual(DialogAlignment.Center);
    })
    it('updateBreakpoint', 0, () => {
      CallColumnUtilsTest_updateBreakpoint();
    })
    it('getItemSpace_test_all', 0, () => {
      getItemSpace_test();
    })
    it('getPaddingSpace_test_all', 0, () => {
      getPaddingSpace_test_01();
      getPaddingSpace_test_02();
      getPaddingSpace_test_03();
    })
    it('getRowSpace_test_all', 0, () => {
      getRowSpace_test_01();
      getRowSpace_test_02();
      getRowSpace_test_03();
    })
    it('getVideoSmall_test_01', 0, () => {
      getVideoSmall_test_01();
    })
    it('getGridCount_test_all', 0, () => {
      getGridCount_test_01();
      getGridCount_test_02();
      getGridCount_test_03();
    })
    it('getVideoKeyBoardRowSpace_test_all', 0, () => {
      getVideoKeyBoardRowSpace_test_01();
      getVideoKeyBoardRowSpace_test_02();
    })
    it('getDisplayNameForAutoSize_test', 0, () => {
      getDisplayNameForAutoSize_test();
    })
    it('getCallTextHeight_test_all', 0, () => {
      getCallTextHeight_test();
    })
    it('addDisplayChange_test', 0, () => {
      addDisplayChange_test();
    })
    it('getUiMaxWidth_test', 0, () => {
      getUiMaxWidth_test();
    })
    it('getTextWidth_test', 0, () => {
      getTextWidth_test();
    })
    it('splitTextIntoLines_test', 0, () => {
      splitTextIntoLines_test();
    })

    it('getKeyBordMarginSpace_test', 0, () => {
      getKeyBordMarginSpace_test_01();
      getKeyBordMarginSpace_test_02();
      getKeyBordMarginSpace_test_03();
      getKeyBordMarginSpace_test_04();
    })

    it('removeDisplayChange_test', 0, () => {
      removeDisplayChange_test();
    })

    it('rowsGap_test', 0, async () => {
      rowsGap_test_01();
      rowsGap_test_02();
      rowsGap_test_03();
    });

    it('gridHeight_test', 0, async () => {
      gridHeight_test_01();
      gridHeight_test_02();
    });

    it('getCallNormalPercent_test', 0, () => {
      getCallNormalPercent_test_01();
      getCallNormalPercent_test_02();
    });

    it('getWindowDecorHeight', 0, () => {
      getWindowDecorHeight_test();
    });

    it('should_return_immediately_when_judgeIsApplyNewStyle_is_false', 0, () => {
      let callColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
      const windowObj = AppStorage.get<window.Window>('testWindow') as window.Window;
      if (!windowObj) {
        return;
      }
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(callColumnUtils, callColumnUtils.judgeIsApplyNewStyle);
      when(mockFunc)().afterReturn(false);
      callColumnUtils.setWindowLimit(windowObj);
      expect(windowObj !== null).assertTrue();
      mocker.ignoreMock(windowObj, windowObj.setWindowLimits);
      mocker.ignoreMock(callColumnUtils, callColumnUtils.judgeIsApplyNewStyle);
    });
    it('should_set_window_limits_when_judgeIsApplyNewStyle_is_true', 0, () => {
      let callColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
      const windowObj = AppStorage.get<window.Window>('testWindow') as window.Window;
      if (!windowObj) {
        return;
      }
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(callColumnUtils, callColumnUtils.judgeIsApplyNewStyle);
      when(mockFunc)().afterReturn(true);
      callColumnUtils.setWindowLimit(windowObj);
      expect(windowObj !== null).assertTrue();
      mocker.ignoreMock(windowObj, windowObj.setWindowLimits);
      mocker.ignoreMock(callColumnUtils, callColumnUtils.judgeIsApplyNewStyle);
    });

    it('should_return_immediately_when_isApplyNewStyle_is_false', 0, async () => {
      const windowObj = AppStorage.get<window.Window>('testWindow') as window.Window;
      if (!windowObj) {
        return;
      }
      let mocker: MockKit = new MockKit();
      let callcolumnutils: CallColumnUtils = new CallColumnUtils();
      let mockfunc: Function = mocker.mockFunc(callcolumnutils, callcolumnutils.judgeIsApplyNewStyle);
      when(mockfunc)().afterReturn(false);

      let mockfunc2: Function = mocker.mockFunc(callcolumnutils, callcolumnutils.initAppWindow);
      when(mockfunc2)([ArgumentMatchers.anyNumber, ArgumentMatchers.anyObj, ArgumentMatchers.anyObj,
        ArgumentMatchers.anyObj]).afterReturnNothing();

      let width: number = 1080;
      let height: number = 1920;

      let result = callcolumnutils.windowSizeChange(width, height, windowObj);
      expect(result == null).assertTrue();
      mocker.ignoreMock(callcolumnutils, callcolumnutils.judgeIsApplyNewStyle);
    });
    it('should_execute_all_steps_when_isApplyNewStyle_is_true', 0, async () => {
      const windowObj = AppStorage.get<window.Window>('testWindow') as window.Window;
      if (!windowObj) {
        return;
      }
      let mocker: MockKit = new MockKit();
      let callcolumnutils: CallColumnUtils = new CallColumnUtils();
      let mockfunc1: Function = mocker.mockFunc(callcolumnutils, callcolumnutils.judgeIsApplyNewStyle);
      when(mockfunc1)().afterReturn(true);

      let width: number = 1080;
      let height: number = 1920;

      let result = callcolumnutils.windowSizeChange(width, height, windowObj);
      expect(result == null).assertTrue();
      mocker.ignoreMock(callcolumnutils, callcolumnutils.judgeIsApplyNewStyle);
    });

    it('initAppWindow_test', 0, () => {
      let callcolumnutils: CallColumnUtils = new CallColumnUtils();
      let windowWidth = 500;
      let appWindow: AppWindowStyleData = new AppWindowStyleData();
      callcolumnutils.initAppWindow(windowWidth, AppWidthBp.DEFAULT, AppHeightBp.DEFAULT, appWindow);
      expect(appWindow.appWidth).assertEqual(windowWidth);
      expect(appWindow.maxHeight === undefined).assertTrue();

      windowWidth = 500;
      callcolumnutils.initAppWindow(windowWidth, AppWidthBp.SMALL, AppHeightBp.SMALL, appWindow);
      expect(appWindow.appWidth).assertEqual(windowWidth);
      expect(appWindow.maxHeight === undefined).assertTrue();

      windowWidth = 800;
      callcolumnutils.initAppWindow(windowWidth, AppWidthBp.MEDIUM, AppHeightBp.MEDIUM, appWindow);
      expect(appWindow.appWidth != null && appWindow.appWidth <= windowWidth).assertTrue();
      expect(appWindow.maxHeight).assertEqual(960);

      windowWidth = 1220;
      callcolumnutils.initAppWindow(windowWidth, AppWidthBp.LARGE, AppHeightBp.LARGE, appWindow);
      expect(appWindow.appWidth != null && appWindow.appWidth <= windowWidth).assertTrue();
      expect(appWindow.maxHeight).assertEqual(1280);

      windowWidth = 1920;
      callcolumnutils.initAppWindow(windowWidth, AppWidthBp.X_LARGE, AppHeightBp.LARGE, appWindow);
      expect(appWindow.appWidth).assertEqual(960);
      expect(appWindow.maxHeight).assertEqual(1280);
    });
  });
}