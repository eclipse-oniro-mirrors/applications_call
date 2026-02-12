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

import common from '@ohos.app.ability.common';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { getRingToneAttrsArray, getRingToneName } from '../common/utils/CommonFunUtil';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { addAirPlaneModeListener, removeAirPlaneModeListener } from '../common/utils/AirPlaneStateManager';
import { systemSoundManager } from '@kit.AudioKit';
import { getMaxSimCount } from '../model/RegisterSimStateApi';

const TAG = 'CallSettingVM';
const MAX_SIM_COUNTS = 2;

export default class CallSettingVM {
  private static instance: CallSettingVM;
  public simRingtoneOne: string = '';
  public simRingtoneTwo: string = '';
  public toneAttrsArray: systemSoundManager.ToneAttrsArray = [];
  private isFromExternal: boolean = false;

  public static getInstance(): CallSettingVM {
    if (!CallSettingVM.instance) {
      CallSettingVM.instance = new CallSettingVM();
    }
    return CallSettingVM.instance;
  }

  initData() {
    this.getRingTongOfCall();
    addAirPlaneModeListener();
  }

  getRingTongOfCall() {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
    getRingToneAttrsArray(context, (ringtoneAttrsArr: systemSoundManager.ToneAttrsArray) => {
      this.toneAttrsArray = ringtoneAttrsArr;
      this.getCardOneRingToneName(context, ringtoneAttrsArr);
    });
  }

  async getCardOneRingToneName(context: common.UIAbilityContext, attrsArr: systemSoundManager.ToneAttrsArray) {
    if (getMaxSimCount() === MAX_SIM_COUNTS) {
      this.simRingtoneTwo = await getRingToneName(context, 1, attrsArr);
    }
    this.simRingtoneOne = await getRingToneName(context, 0, attrsArr);
  }

  isGetInitSimRingtone(): boolean {
    if (getMaxSimCount() === MAX_SIM_COUNTS) {
      if (this.simRingtoneOne.length > 0 &&
        this.simRingtoneTwo.length > 0) {
        return true;
      }
      return false;
    }
    return true;
  }

  unregister() {
    try {
      removeAirPlaneModeListener();
    } catch (err) {
      LogUtils.e(TAG, `aboutToDisappear err = ${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  getIsFromExternal(): boolean {
    return this.isFromExternal;
  }

  setIsFromExternal(isFromExternal: boolean) {
    this.isFromExternal = isFromExternal;
  }
}