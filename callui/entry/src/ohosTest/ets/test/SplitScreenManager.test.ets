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
import { ArgumentMatchers, describe, expect, it, MockKit, when } from "@ohos/hypium";
import SplitScreenManager, { SplitScreenType } from "../../../main/ets/model/SplitScreenManager";
import { display, window } from "@kit.ArkUI";
import { DisplayUtilDT } from "../../../main/ets/common/utils/DisplayUtilDT";
import LogUtils from "../../../main/ets/common/utils/LogUtils";
import ScreenAdapterUtils from "../../../main/ets/common/utils/ScreenAdapterUtils";
import { DisplayUtil } from "../../../main/ets/common/utils/DisplayUtil";
import DefaultCallData from "../../../main/ets/common/struct/TypeUtils";


export default function SplitScreenManagerTest() {
  describe('SplitScreenManagerTest', () => {

    let getWindowWidth_test = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.screenWidth = 720;
      let result = spManager.getWindowWidth();
      expect(result).assertEqual(720);
    }

    let isTwoInOne_test = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.isTwoInOneDevice = null;
      let result = spManager.isTwoInOne();
      expect(result).assertFalse();
    }

    let isExpandedStatus_test = () => {
      let mocker: MockKit = new MockKit();
      let displayUtilDT = new DisplayUtilDT();
      let mockDisplayGetFoldStatus: Function = mocker.mockFunc(displayUtilDT, display.getFoldStatus);
      when(mockDisplayGetFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_UNKNOWN);
      let spManager = SplitScreenManager.getInstance();
      const result = spManager.isExpandedStatus();
      expect(result).assertEqual(false);
      mocker.ignoreMock(displayUtilDT, DisplayUtilDT.getFoldStatus);
    }

    let updateWindowStatusType_test = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.updateWindowStatusType(window.WindowStatusType.FULL_SCREEN);
      expect(spManager.windowStatusType).assertEqual(window.WindowStatusType.FULL_SCREEN);
    }

    let updateScreenSize_test = () => {
      let splitscreenmanager: SplitScreenManager = SplitScreenManager.getInstance();
      let mocker: MockKit = new MockKit();
      let mockLandscapeFunc: Function = mocker.mockFunc(splitscreenmanager, splitscreenmanager.isLandscape);
      when(mockLandscapeFunc)().afterReturn(false);

      splitscreenmanager.updateScreenSize(1920, 1080);

      expect(splitscreenmanager.screenWidth).assertEqual(1920);
      expect(splitscreenmanager.screenHeight).assertEqual(1080);

      mocker.ignoreMock(splitscreenmanager, splitscreenmanager.isLandscape);
    }

    let getSplitScreenType_test_01 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenWidth = 1008;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 1008;
      spManager.screenHeight = 1920;
      let result = spManager.getSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
    }

    let getSplitScreenType_test_02 = () => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenWidth = 1080;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 540;
      spManager.screenHeight = 960;
      spManager.windowStatusType = window.WindowStatusType.SPLIT_SCREEN;

      let result = spManager.getSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let getSplitScreenType_test_03 = () => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenWidth = 1080;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 540;
      spManager.screenHeight = 960;
      spManager.windowStatusType = window.WindowStatusType.SPLIT_SCREEN;
      ScreenAdapterUtils.isNewFoldPhone = true;
      let result = spManager.getSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    }
    let getSplitScreenType_test_04 = () => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      let spManager = SplitScreenManager.getInstance();
      spManager.isTabletDevice = true;
      ScreenAdapterUtils.isNewFoldPhone = false;
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(true);

      spManager.fullScreenWidth = 1080;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 540;
      spManager.screenHeight = 960;
      spManager.windowStatusType = window.WindowStatusType.SPLIT_SCREEN;
      let result = spManager.getSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let getSplitScreenType_test_05 = () => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();

      let displayUtil = new DisplayUtil();
      let displayUtilFoldStatus: Function = mocker.mockFunc(displayUtil, DisplayUtil.isFoldable);
      when(displayUtilFoldStatus)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenWidth = 1080;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 540;
      spManager.screenHeight = 960;
      spManager.windowStatusType = window.WindowStatusType.SPLIT_SCREEN;
      let result = spManager.getSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(displayUtil, DisplayUtil.isFoldable);
    }

    let getSplitScreenType_test_06 = () => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      let displayUtil = new DisplayUtil();
      let displayUtilFoldStatus: Function = mocker.mockFunc(displayUtil, DisplayUtil.isFoldable);
      when(displayUtilFoldStatus)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let spManager = SplitScreenManager.getInstance();

      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);

      spManager.fullScreenWidth = 1080;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 540;
      spManager.screenHeight = 960;
      spManager.windowStatusType = window.WindowStatusType.SPLIT_SCREEN;
      ScreenAdapterUtils.isNewFoldPhone = false;
      let result = spManager.getSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(spManager, spManager.isTablet);
      mocker.ignoreMock(displayUtil, DisplayUtil.isFoldable);

    }

    let getIpadSplitScreenType_test_01 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenHeight = -1;
      let result = spManager.getIpadSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
    }

    let getIpadSplitScreenType_test_02 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenHeight = 1920;
      spManager.screenHeight = 900;
      let result = spManager.getIpadSplitScreenType();
      expect(result).assertEqual(SplitScreenType.MEDIUM);
    }

    let getIpadSplitScreenType_test_03 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenHeight = 1920;
      spManager.screenHeight = 600;
      let result = spManager.getIpadSplitScreenType();
      expect(result).assertEqual(SplitScreenType.SMALL);
    }

    let getIpadSplitScreenType_test_04 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenHeight = 1920;
      spManager.screenHeight = 1200;
      let result = spManager.getIpadSplitScreenType();
      expect(result).assertEqual(SplitScreenType.BIG);
    }

    let getIpadSplitScreenType_test_05 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenHeight = 1920;
      spManager.screenHeight = 1600;
      let result = spManager.getIpadSplitScreenType();
      expect(result).assertEqual(SplitScreenType.DEFAULT);
    }

    let isSplitScreen_test_01 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenHeight = -1;
      let result = spManager.isSplitScreen(SplitScreenType.DEFAULT);
      expect(result).assertFalse();
    }

    let isSplitScreen_test_02 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenWidth = 1080;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 1080;
      spManager.screenHeight = 1920;
      let result = spManager.isSplitScreen(SplitScreenType.DEFAULT);
      expect(result).assertFalse();
    }

    let isSplitScreen_test_03 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.fullScreenWidth = 1080;
      spManager.fullScreenHeight = 1920;
      spManager.screenWidth = 540;
      spManager.screenHeight = 960;
      let result = spManager.isSplitScreen(SplitScreenType.SMALL);
      expect(result).assertTrue();
    }

    let isSplitScreenStatus_test_01 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.windowStatusType = window.WindowStatusType.SPLIT_SCREEN;
      let result = spManager.isSplitScreenStatus();
      expect(result).assertTrue();
    }

    let isSplitScreenStatus_test_02 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.windowStatusType = window.WindowStatusType.FULL_SCREEN;
      let result = spManager.isSplitScreenStatus();
      expect(result).assertFalse();
    }

    let callFuncBtnsVisibility_test_01 = () => {
      let spManager = SplitScreenManager.getInstance();
      let result = spManager.callFuncBtnsVisibility(SplitScreenType.SMALL);
      expect(result).assertEqual(Visibility.None);
    }

    let callFuncBtnsVisibility_test_02 = () => {
      let spManager = SplitScreenManager.getInstance();
      let mocker: MockKit = new MockKit();
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);
      let isTwoinOneFunc: Function = mocker.mockFunc(spManager, spManager.isTwoInOne);
      when(isTwoinOneFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let result = spManager.callFuncBtnsVisibility(SplitScreenType.MEDIUM);
      expect(result).assertEqual(Visibility.None);
      mocker.ignoreMock(spManager, spManager.isTablet);
      mocker.ignoreMock(spManager, spManager.isTwoInOne);
    }

    let callFuncBtnsVisibility_test_03 = () => {
      let spManager = SplitScreenManager.getInstance();
      spManager.isTwoInOneDevice = true;
      let result = spManager.callFuncBtnsVisibility(SplitScreenType.MEDIUM);
      expect(result).assertEqual(Visibility.Visible);
    }

    let callFuncBtnsVisibility_test_04 = () => {
      let spManager = SplitScreenManager.getInstance();
      let result = spManager.callFuncBtnsVisibility(SplitScreenType.BIG);
      expect(result).assertEqual(Visibility.Visible);
    }

    let callBottomKeyboardBtnEnable_test_01 = () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let spManager: SplitScreenManager = new SplitScreenManager();
      let mockIsPhone: Function = mocker.mockFunc(spManager, spManager.isPhone);
      when(mockIsPhone)().afterReturn(true);

      let result = spManager.callBottomKeyboardBtnEnable(SplitScreenType.SMALL);
      expect(result).assertEqual(false);

      result = spManager.callBottomKeyboardBtnEnable(SplitScreenType.MEDIUM);
      expect(result).assertEqual(false);

      result = spManager.callBottomKeyboardBtnEnable(SplitScreenType.BIG);
      expect(result).assertEqual(false);

      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(spManager, spManager.isPhone);
    }

    let callBottomKeyboardBtnEnable_test_02 = () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();
      let spManager: SplitScreenManager = new SplitScreenManager();
      let mockIsPhone: Function = mocker.mockFunc(spManager,spManager.isPhone);
      when(mockIsPhone)().afterReturn(false);

      let splitScreenManager: SplitScreenManager = new SplitScreenManager();
      let result = splitScreenManager.callBottomKeyboardBtnEnable(SplitScreenType.DEFAULT);
      expect(result).assertEqual(true);

      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(spManager, spManager.isPhone);
    }

    let isTwoCallIncoming_test_01 = () => {
      let callList: Array<DefaultCallData> = [];
      let type: SplitScreenType = SplitScreenType.DEFAULT;
      let spManager: SplitScreenManager = new SplitScreenManager();
      const result = spManager.isTwoCallIncoming(callList, type);
      expect(result).assertEqual(false);
    }

    let isTwoCallIncoming_test_02 = () => {
      let callData = new DefaultCallData();
      callData.callState = 4;
      let callData1 = new DefaultCallData();
      callData1.callState = 4;
      let callList: Array<DefaultCallData> = [callData, callData1];
      let type: SplitScreenType = SplitScreenType.DEFAULT;
      let spManager: SplitScreenManager = new SplitScreenManager();
      const result = spManager.isTwoCallIncoming(callList, type);
      expect(result).assertEqual(false);
    }

    let isTwoCallIncoming_test_03 = () => {
      let callData = new DefaultCallData();
      callData.callState = 4;
      let callData1 = new DefaultCallData();
      callData1.callState = 4;
      let callList: Array<DefaultCallData> = [callData, callData1];
      let type: SplitScreenType = SplitScreenType.MEDIUM;
      let spManager: SplitScreenManager = new SplitScreenManager();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      const result = spManager.isTwoCallIncoming(callList, type);
      expect(result).assertEqual(true);
      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let isTwoCallIncoming_test_04 = () => {
      let callData = new DefaultCallData();
      callData.callState = 1;
      let callData1 = new DefaultCallData();
      callData1.callState = 1;
      let callList: Array<DefaultCallData> = [callData, callData1];
      let type: SplitScreenType = SplitScreenType.MEDIUM;
      let spManager: SplitScreenManager = new SplitScreenManager();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      const result = spManager.isTwoCallIncoming(callList, type);
      expect(result).assertEqual(false);
      mocker.ignoreMock(LogUtils, LogUtils.i);
    }

    let incomingCallFuncBtn_test_01 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();
      let result = spManager.incomingCallFuncBtn([], SplitScreenType.DEFAULT, false);
      expect(result).assertEqual(Visibility.None);
    }

    let incomingCallFuncBtn_test_02 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();

      let mocker: MockKit = new MockKit();
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let callData = new DefaultCallData();
      callData.callState = 4;
      let callData1 = new DefaultCallData();
      callData1.callState = 4;
      let callList: Array<DefaultCallData> = [callData, callData1];

      let result = spManager.incomingCallFuncBtn(callList, SplitScreenType.SMALL, true);
      expect(result).assertEqual(Visibility.None);
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let incomingCallFuncBtn_test_03 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();
      let mocker: MockKit = new MockKit();
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let result = spManager.incomingCallFuncBtn([], SplitScreenType.DEFAULT, true);
      expect(result).assertEqual(Visibility.Visible);
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let incomingCallFuncBtn_test_04 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();
      let mocker: MockKit = new MockKit();
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let result = spManager.incomingCallFuncBtn([], SplitScreenType.SMALL, true);
      expect(result).assertEqual(Visibility.None);
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let incomingCallFuncBtn_test_05 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();

      let mocker: MockKit = new MockKit();
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let callData = new DefaultCallData();
      callData.callState = 4;
      let callData1 = new DefaultCallData();
      callData1.callState = 4;
      let callList: Array<DefaultCallData> = [callData, callData1];

      let result = spManager.incomingCallFuncBtn(callList, SplitScreenType.MEDIUM, true);
      expect(result).assertEqual(Visibility.None);
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let incomingCallFuncBtn_test_06 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();
      let mocker: MockKit = new MockKit();
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let result = spManager.incomingCallFuncBtn([], SplitScreenType.BIG, true);
      expect(result).assertEqual(Visibility.Visible);
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let commonCallCard_test_01 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();
      let mocker: MockKit = new MockKit();
      let isTabletFunc: Function = mocker.mockFunc(spManager, spManager.isTablet);
      when(isTabletFunc)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let result = spManager.commonCallCard(true, SplitScreenType.SMALL);
      expect(result).assertEqual(Visibility.None);
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let commonCallCard_test_02 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();
      let result = spManager.commonCallCard(false, SplitScreenType.SMALL);
      expect(result).assertEqual(Visibility.Visible);
    }

    let callListItem_test_01 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();
      let callData = new DefaultCallData();
      let callData1 = new DefaultCallData();
      let result = spManager.callListItem(callData, callData1, SplitScreenType.DEFAULT);
      expect(result).assertTrue();
    }

    let callListItem_test_02 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();

      let mocker: MockKit = new MockKit();
      let isPhonetFunc: Function = mocker.mockFunc(spManager, spManager.isPhone);
      when(isPhonetFunc)(ArgumentMatchers.anyBoolean).afterReturn(true);

      let callData = new DefaultCallData();
      callData.callState = 1;
      let callData1 = new DefaultCallData();
      callData1.callState = 4;
      let result = spManager.callListItem(callData, callData1, SplitScreenType.MEDIUM);
      expect(result).assertTrue();

      when(isPhonetFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);
      callData.callId = 123;
      callData1.callId = 123;
      let result1 = spManager.callListItem(callData, callData1, SplitScreenType.MEDIUM);
      expect(result1).assertTrue();
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    let callListItem_test_03 = () => {
      let spManager: SplitScreenManager = new SplitScreenManager();

      let mocker: MockKit = new MockKit();
      let isPhonetFunc: Function = mocker.mockFunc(spManager, spManager.isPhone);
      when(isPhonetFunc)(ArgumentMatchers.anyBoolean).afterReturn(false);

      let callData = new DefaultCallData();
      callData.callState = 4;
      callData.callId = 123;
      let callData1 = new DefaultCallData();
      callData1.callState = 4;
      callData1.callId = 123;
      let result = spManager.callListItem(callData, callData1, SplitScreenType.MEDIUM);
      expect(result).assertFalse();
      mocker.ignoreMock(spManager, spManager.isTablet);
    }

    it('SplitScreenManagerTest_getWindowWidth_test', 0, () => {
      getWindowWidth_test()
    })

    it('SplitScreenManagerTest_isTwoInOne_test', 0, () => {
      isTwoInOne_test();
    });

    it('SplitScreenManagerTest_isExpandedStatus_test', 0, async () => {
      isExpandedStatus_test();
    });

    it('SplitScreenManagerTest_updateWindowStatusType_test', 0, async () => {
      updateWindowStatusType_test();
    });

    it('SplitScreenManagerTest_updateScreenSize_test', 0, () => {
      updateScreenSize_test();
    });

    it('SplitScreenManagerTest_getSplitScreenType_test', 0, () => {
      getSplitScreenType_test_01();
      getSplitScreenType_test_02();
      getSplitScreenType_test_03();
      getSplitScreenType_test_04();
      getSplitScreenType_test_05();
      getSplitScreenType_test_06();
    });

    it('SplitScreenManagerTest_getIpadSplitScreenType_test', 0, () => {
      getIpadSplitScreenType_test_01();
      getIpadSplitScreenType_test_02();
      getIpadSplitScreenType_test_03();
      getIpadSplitScreenType_test_04();
      getIpadSplitScreenType_test_05();
    });

    it('SplitScreenManagerTest_isSplitScreen_test', 0, () => {
      isSplitScreen_test_01();
      isSplitScreen_test_02();
      isSplitScreen_test_03();
    });

    it('SplitScreenManagerTest_isSplitScreenStatus_test', 0, () => {
      isSplitScreenStatus_test_01();
      isSplitScreenStatus_test_02();
    });

    it('SplitScreenManagerTest_callFuncBtnsVisibility_test', 0, () => {
      callFuncBtnsVisibility_test_01();
      callFuncBtnsVisibility_test_02();
    });

    it('SplitScreenManagerTest_callFuncBtnsVisibility', 0, () => {
      callFuncBtnsVisibility_test_03();
      callFuncBtnsVisibility_test_04();
    });

    it('SplitScreenManagerTest_callBottomKeyboardBtnEnable', 0, () => {
      callBottomKeyboardBtnEnable_test_01();
      callBottomKeyboardBtnEnable_test_02();
    });

    it('SplitScreenManagerTest_isTwoCallIncoming', 0, () => {
      isTwoCallIncoming_test_01();
      isTwoCallIncoming_test_02();
      isTwoCallIncoming_test_03();
      isTwoCallIncoming_test_04();
    });

    it('SplitScreenManagerTest_incomingCallFuncBtn', 0, () => {
      incomingCallFuncBtn_test_01();
      incomingCallFuncBtn_test_02();
      incomingCallFuncBtn_test_03();
      incomingCallFuncBtn_test_04();
      incomingCallFuncBtn_test_05();
      incomingCallFuncBtn_test_06();
    });

    it('SplitScreenManagerTest_commonCallCard', 0, () => {
      commonCallCard_test_01();
      commonCallCard_test_02();
    });

    it('SplitScreenManagerTest_callListItem', 0, () => {
      callListItem_test_01();
      callListItem_test_02();
      callListItem_test_03();
    });
  });
}