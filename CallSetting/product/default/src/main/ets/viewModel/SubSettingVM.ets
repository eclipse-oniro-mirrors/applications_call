/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import commonData from '../data/CommonData';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';

const TAG = 'SubSettingVM';

export default class SubSettingVM {
  private static instance: SubSettingVM;

  public static getInstance(): SubSettingVM {
    if (!SubSettingVM.instance) {
      SubSettingVM.instance = new SubSettingVM();
    }
    return SubSettingVM.instance;
  }

  clickToContactsSpeedDail() {
    LogUtils.i(TAG, 'clickToContactsSpeedDail, startAbility');
    let str: Record<string, Object> = {
      'bundleName': commonData.string.CONTACT_BUNDLE_NAME,
      'abilityName': commonData.string.CONTACT_SPEED_DIAL_ABILITY_NAME,
    };
    CallSettingGlobalContextHelper.getContext().
    getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)?.startAbility(str).then(() => {
      LogUtils.i(TAG, 'clickToContactsSpeedDial, startAbility success');
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, 'clickToContactsSpeedDial, failed Cause: ' + JSON.stringify(error.message));
    })
  }

  clickToContactsVoicemail(slotId: number) {
    LogUtils.i(TAG, 'clickToContactsVoicemail, startAbility');
    let parameters: Record<string, number | string> = {
      'pageFlag': commonData.string.VOICE_MAIL_PAGE,
      'slotId': slotId
    };
    let str: Record<string, Object> = {
      'bundleName': commonData.string.CONTACT_BUNDLE_NAME,
      'abilityName': commonData.string.CONTACT_SPEED_DIAL_ABILITY_NAME,
      'parameters': parameters
    };
    CallSettingGlobalContextHelper.getContext().
    getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)?.startAbility(str).then(() => {
      LogUtils.i(TAG, 'clickToContactsSpeedDial, startAbility success');
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, 'clickToContactsSpeedDial, failed Cause: ' + JSON.stringify(error.message));
    })
  }
}