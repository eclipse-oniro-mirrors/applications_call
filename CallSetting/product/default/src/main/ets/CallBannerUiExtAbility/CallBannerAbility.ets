/*
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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { display } from '@kit.ArkUI';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { CALL_BANNER_ABILITY_SESSION } from '../common/constant/CallSettingsConstant';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';

const TAG = 'CallBannerExtensionAbility';

export default class CallBannerExtensionAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'CallBannerExtensionAbility start');
    CallSettingGlobalContextHelper.getContext()
      .set<UIExtensionContentSession>(CALL_BANNER_ABILITY_SESSION, session);
    this.setIsNewFoldPhoneExternalScreen();
    this.addFoldStatusListener(session);
    session.loadContent('pages/BannerGuidePage');
    session.setWindowBackgroundColor(Color.Transparent.toString());
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, `UIExtAbility onSessionDestroy`);
  }

  addFoldStatusListener(session: UIExtensionContentSession): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    // try {
    //   display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
    //     LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
    //     this.setIsNewFoldPhoneExternalScreen();
    //     AppStorage.setOrCreate('foldStatus', foldStatus);
    //   })
    // } catch (exception) {
    //   LogUtils.e(TAG, 'foldStatusChange exp=' + JSON.stringify(exception));
    // }
  }

  setIsNewFoldPhoneExternalScreen() {
    let isNewFoldPhoneExternalScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
    AppStorage.setOrCreate('isNewFoldPhoneExternalScreen', isNewFoldPhoneExternalScreen);
  }
}
