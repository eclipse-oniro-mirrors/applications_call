/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { describe, it, expect } from '@ohos/hypium';
import Banner from '../../../../../main/ets/common/utils/Banner';
import common from '@ohos.app.ability.common';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import ServiceExtensionContext from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import * as Constants from '../../../../../main/ets/common/utils/Constants';
import { sleep } from '../../Utils';

let preferencesKey = 'needShowBannerGuide';

let BannerTest_setFirstStartStatus_01 = () => {
  let bannerInstance = Banner.getInstance();
  expect(bannerInstance).not().assertUndefined();
  bannerInstance.setFirstStartStatus();
  expect(true).assertTrue();
}

let BannerTest_getInstance_01 = () => {
  let bannerInstance = Banner.getInstance();
  expect(bannerInstance).not().assertUndefined();
}

let BannerTest_getFirstStartStatus_01 = async () => {
  let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!textContext) {
    return;
  }
  GlobalContextHelper.getContext().set(Constants.CALL_SERVICE_CONTEXT, textContext);
  let bannerInstance = Banner.getInstance();
  expect(bannerInstance !== undefined).assertTrue();
  let options: dataPreferences.Options = {
    name: preferencesKey
  };
  let preferences: dataPreferences.Preferences | null = null;
  preferences = dataPreferences.getPreferencesSync(textContext, options);
  let realValue = preferences.getSync(preferencesKey, true);
  expect(preferences !== undefined).assertTrue();
  preferences.putSync(preferencesKey, true);
  GlobalContextHelper.getContext().set(Constants.CALL_SERVICE_CONTEXT, textContext);
  let result = bannerInstance.getFirstStartStatus();
  expect(result).assertEqual(true);
  await sleep(1000);
  preferences.putSync(preferencesKey, realValue);
}

let BannerTest_getFirstStartStatus_02 = async () => {
  let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!textContext) {
    return;
  }
  GlobalContextHelper.getContext().set(Constants.CALL_SERVICE_CONTEXT, textContext);
  let bannerInstance = Banner.getInstance();
  expect(bannerInstance).not().assertUndefined();
  let options: dataPreferences.Options = {
    name: preferencesKey
  };
  let preferences: dataPreferences.Preferences | null = null;
  preferences = dataPreferences.getPreferencesSync(textContext, options);
  let realValue = preferences.getSync(preferencesKey, true);
  expect(preferences).not().assertUndefined();
  preferences.putSync(preferencesKey, false);
  GlobalContextHelper.getContext().set(Constants.CALL_SERVICE_CONTEXT, textContext);
  let result = bannerInstance.getFirstStartStatus();
  expect(result).assertEqual(false);
  await sleep(1000);
  preferences.putSync(preferencesKey, realValue);
}

let BannerTest_setFirstStartStatus_02 = () => {
  let bannerInstance = Banner.getInstance();
  expect(bannerInstance).not().assertUndefined();
  bannerInstance.setFirstStartStatus();
  expect(true).assertTrue();
}

let BannerTest_jumpToBannerGuide_01 = () => {
  let bannerInstance = Banner.getInstance();
  expect(bannerInstance).not().assertUndefined();
  bannerInstance.jumpToBannerGuide();
  expect(true).assertTrue();
}

let BannerTest_jumpToBannerGuide_02 = async () => {
  let bannerInstance = Banner.getInstance();
  expect(bannerInstance).not().assertUndefined();
  let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
    .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
  let options: dataPreferences.Options = {
    name: preferencesKey
  };
  let preferences: dataPreferences.Preferences | null = null;
  preferences = dataPreferences.getPreferencesSync(serviceContext, options);
  let realValue = preferences.getSync(preferencesKey, true);
  expect(preferences).not().assertUndefined();
  preferences.putSync(preferencesKey, true);
  bannerInstance.jumpToBannerGuide();
  await sleep(1500);
  expect(true).assertTrue();
  preferences.putSync(preferencesKey, realValue);
}

export default function BannerTest() {
  describe('BannerTest', () => {
    it('BannerTest_setFirstStartStatus_01', 0, async () => {
      BannerTest_setFirstStartStatus_01();
    })
    it('BannerTest_getInstance_01', 0, async () => {
      BannerTest_getInstance_01();
    })
    it('BannerTest_getFirstStartStatus_01', 0, async () => {
      await BannerTest_getFirstStartStatus_01();
    })
    it('BannerTest_getFirstStartStatus_02', 0, async () => {
      await BannerTest_getFirstStartStatus_02();
    })
    it('BannerTest_setFirstStartStatus_02', 0, async () => {
      BannerTest_setFirstStartStatus_02();
    })
    it('BannerTest_jumpToBannerGuide_01', 0, async () => {
      BannerTest_jumpToBannerGuide_01();
    })
    it('BannerTest_jumpToBannerGuide_02', 0, async () => {
      BannerTest_jumpToBannerGuide_02();
    })
  })
}