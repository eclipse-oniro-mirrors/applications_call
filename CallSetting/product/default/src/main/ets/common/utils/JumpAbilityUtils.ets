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

import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';

const TAG = 'JumpAbilityUtils';

export class JumpAbilityUtils {
  static async jumpToSettings() {
    let want: Want = {
      bundleName: 'com.ohos.settings',
      abilityName: 'com.ohos.settings.MainAbility',
      uri: 'mobile_data_settings_entry'
    };
    try {
      await CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)?.
      startAbility(want, (err) => {
        if (err.code) {
          LogUtils.i(TAG, `startAbility failed, code is ${err.code}, message is ${err.message}`);
          return;
        }
        LogUtils.i(TAG, 'startAbility succeed');
      });
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.i(TAG, `startAbility failed failed, code is ${error.code}, message is ${error.message}`);
    }
  }
}