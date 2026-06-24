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
import { beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import { LogUtil } from '../../../../main/ets/util/LogUtil';
import { common, ConfigurationConstant, UIExtensionContentSession } from '@kit.AbilityKit';
import { FontScaleState } from '../../../../main/ets/util/fontScaleState';
import UIExtAbility from '../../../../main/ets/entryability/NetAccessPolicyUIExtension';
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo';

const TAG: string = 'NetAccessPolicyUIExtAbility';

export default function UIExtAbilityTest() {
  describe('UIExtAbilityTest', () => {
    let netAccessPolicyUIExtAbility: UIExtAbility ;
    let want: Want;
    beforeEach(() => {
      netAccessPolicyUIExtAbility = new UIExtAbility();
      let context: common.UIExtensionContext = {
        config: {
          fontSizeScale: 1,
          colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        }
      } as common.UIExtensionContext;
      netAccessPolicyUIExtAbility.context = context;
      want = {
        bundleName: 'com.ohos.communicationsetting',
        moduleName: 'entry',
        abilityName: 'CommunicationSettingAbility',
        parameters: {
          'appid': 20020127,
        }
      };
    })
    it('onCreateTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      netAccessPolicyUIExtAbility.onCreate()
      mocker.verify('log', [TAG, 'UIExtAbility onCreate']).once();
      mocker.clear(LogUtil);
    })
    it('onForegroundTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      netAccessPolicyUIExtAbility.onForeground()
      mocker.verify('log', [TAG, 'UIExtAbility onForeground']).once();
      mocker.clear(LogUtil);
    })
    it('onBackgroundTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      netAccessPolicyUIExtAbility.onBackground()
      mocker.verify('log', [TAG, 'UIExtAbility onBackground']).once();
      mocker.clear(LogUtil);
    })
    it('onDestroyTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      netAccessPolicyUIExtAbility.onDestroy()
      mocker.verify('log', [TAG, 'UIExtAbility onDestroy']).once();
      mocker.clear(LogUtil);
    })
    it('onSessionDestroyTest', 0, () => {
      let session: UIExtensionContentSession = {} as UIExtensionContentSession
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      netAccessPolicyUIExtAbility.onSessionDestroy(session)
      mocker.verify('log', [TAG, 'UIExtAbility onSessionDestroy']).once();
      mocker.clear(LogUtil);
    })
    it('onSessionCreateTest', 0, () => {
      let appInfo = new AppInfo('', -1, 0, 0);
      let session: UIExtensionContentSession = {
        loadContent: (path: string, storage?: LocalStorage): void => {
          appInfo.uid = 1000001;
        },
        setWindowBackgroundColor: (color: string): void => {
        }
      } as UIExtensionContentSession;
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(netAccessPolicyUIExtAbility, netAccessPolicyUIExtAbility.fetchSystemFontSizeScale);
      netAccessPolicyUIExtAbility.onSessionCreate(want, session);
      expect(AppInfo.appInfoChecked(appInfo)).assertFalse();
    })
    it('fetchSystemFontSizeScaleTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(FontScaleState, FontScaleState.updateAppFontGearSize);
      netAccessPolicyUIExtAbility.fetchSystemFontSizeScale();
      mocker.verify('updateAppFontGearSize', [1]).once();
      mocker.clear(FontScaleState);
    })
    it('onConfigurationUpdateTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(FontScaleState, FontScaleState.updateAppFontGearSize);
      netAccessPolicyUIExtAbility.onConfigurationUpdate({
        fontSizeScale: 1,
        colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      });
      mocker.verify('updateAppFontGearSize', [1]).once();
      mocker.clear(FontScaleState);
    })
  })
}