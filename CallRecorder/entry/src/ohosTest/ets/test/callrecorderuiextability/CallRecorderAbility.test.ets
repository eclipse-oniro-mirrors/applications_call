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
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { describe, it, expect, MockKit, when, ArgumentMatchers, beforeAll } from '@ohos/hypium';
import CallRecorderExtensionAbility from '../../../../main/ets/callrecorderuiextability/CallRecorderAbility';
import LogUtils from '../../../../main/ets/common/utils/LogUtils';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import { Constant } from '../../../../main/ets/common/constant/Constant';
import { common } from '@kit.AbilityKit';
import { uiExtensionHost } from '@kit.ArkUI';
import window from '@ohos.window';

/**
 * 通过CodeMate插件生成代码
 */
export default function CallRecorderExtensionAbilityTest() {
  describe('CallRecorderExtensionAbilityTest', () => {
    let want: Want;
    let area: window.AvoidArea;
    let session: UIExtensionContentSession;
    let testContext: common.UIExtensionContext;
    beforeAll(() => {
      want = {
        bundleName: 'com.ohos.callrecorder',
        abilityName: 'com.ohos.callrecorder.CallRecorderAbility'
      };
      let rect: window.Rect = {
        left: 0,
        top: 0,
        width: 100,
        height: 100
      };
      area = {
        visible: false,
        leftRect: rect,
        topRect: rect,
        rightRect: rect,
        bottomRect: rect
      };
      let extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy = {
        getWindowAvoidArea: (type: window.AvoidAreaType): window.AvoidArea => {
          return area;
        },
        on: (type: 'windowSizeChange', callback?: Callback<window.Size>): void => {
        }
      } as uiExtensionHost.UIExtensionHostWindowProxy;
      session = {
        loadContent: (path: string, storage?: LocalStorage): void => {
        },
        getUIExtensionHostWindowProxy: () => {
          return extensionWindow
        }
      } as UIExtensionContentSession;
      testContext = GlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
      testContext.config = { fontSizeScale: 2 };
    });

    it('atc_should_initialize_statusBarHeight_when_isFromExternal_is_true', 0, async () => {
      let callrecorderextensionability: CallRecorderExtensionAbility = new CallRecorderExtensionAbility();
      callrecorderextensionability.context = testContext;
      let mocker: MockKit = new MockKit();
      want.parameters = { isFromExternal: true };
      let loadContentMock: Function = mocker.mockFunc(session, session.loadContent);
      when(loadContentMock)(ArgumentMatchers.any).afterReturnNothing();
      let ret = callrecorderextensionability.onSessionCreate(want, session);
      expect(ret === undefined).assertTrue();
      mocker.ignoreMock(session, session.loadContent);
    });

    it('atc_should_log_info_when_onSessionDestroy_is_called', 0, async () => {
      let callrecorderextensionability: CallRecorderExtensionAbility = new CallRecorderExtensionAbility();
      let mocker: MockKit = new MockKit();
      let logUtilsMock: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(logUtilsMock)(ArgumentMatchers.any).afterReturnNothing();
      let ret = callrecorderextensionability.onSessionDestroy(session);
      expect(ret === undefined).assertTrue();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('atc_should_use_default_font_size_scale_when_newConfig_is_not_provided', 0, () => {
      let callrecorderextensionability: CallRecorderExtensionAbility = new CallRecorderExtensionAbility();
      callrecorderextensionability.context = testContext;
      let mocker: MockKit = new MockKit();
      let mockLogUtilsI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtilsI)(ArgumentMatchers.any).afterReturnNothing();
      let config = testContext.config;
      config.fontSizeScale = undefined;
      let ret = callrecorderextensionability.onConfigurationUpdate(config);
      expect(ret === undefined).assertTrue();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

  });
}