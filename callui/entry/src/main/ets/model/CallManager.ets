/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

/**
 * @file: Call management
 */
import CallDataManager from './CallDataManager';
import LogUtils from '../common/utils/LogUtils'
import DefaultCallData from '../common/struct/TypeUtils';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import common from '@ohos.app.ability.common';
import CallTimeListStruct from '../common/struct/CallTimeListStruct';
import CallStateConst from '../common/constant/CallStateConst';
import BannerNotificationManager from './BannerNotificationManager';
import { isScreenLocked } from '../common/utils/DeviceTypeUtils';
import { display } from '@kit.ArkUI';
import deviceInfo from '@ohos.deviceInfo';
import { abilityManager } from '@kit.AbilityKit';

const TAG = 'CallManager';

export interface Ctx {
  callData: DefaultCallData
  callList: DefaultCallData[]
  callTimeList: CallTimeListStruct[]
}

/**
 * class CallManager
 */
export default class CallManager {
  private mCallDataManager: CallDataManager;
  private static sCallManager: CallManager;

  public static getInstance(): CallManager {
    if (!CallManager.sCallManager) {
      CallManager.sCallManager = new CallManager()
    }
    return CallManager.sCallManager;
  }

  private constructor() {
    this.mCallDataManager = CallDataManager.getInstance();
  }

  /**
   * update callData callBack
   *
   * @param { Object } callData -Object
   * @param { number } currentCallId - number
   */
  async update(callData: DefaultCallData, currentCallId?: number) {
    LogUtils.i(TAG, 'update callData callId:' + callData.callId);
    if (callData.callType === CallStateConst.TYPE_VOIP) {
      await this.setHeadsUpEnabled(callData);
      BannerNotificationManager.getInstance().sendBannerNotification(callData);
      if (callData.callState === CallStateConst.CALL_STATUS_DISCONNECTED && currentCallId === callData.callId) {
        GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.VOIP_ABILITY_CONTEXT)?.
        terminateSelf().then(() => {
          LogUtils.i(TAG, 'update, voipAbility terminateSelf because service disconnected');
        });
      }
      return;
    }
    this.mCallDataManager.update(callData);
    LogUtils.i(TAG, 'update callId:' + callData.callId);
  }

  private async getVoipForeground(callData: DefaultCallData) {
    try {
      const voipAbilitys = await abilityManager.getForegroundUIAbilities();
      if (voipAbilitys.length === 0) {
        LogUtils.i(TAG, 'the current application is in the background');
        return false;
      }
      for (const voipAbility of voipAbilitys) {
        if (voipAbility.bundleName === callData?.voipCallAttribute?.voipBundleName) {
          LogUtils.i(TAG, 'the current application is in the foreground.');
          return true;
        }
      }
      return false;
    } catch (e) {
      LogUtils.e(TAG, 'get voipAbilityStates failed');
      return false;
    }
  }

  private async setHeadsUpEnabled(callData: DefaultCallData) {
    const isVoipForegroundFound = await this.getVoipForeground(callData);
    if (isVoipForegroundFound) {
       BannerNotificationManager.enableBannerNotification(false);
       return;
    }
    let subVoipCallCheck = callData.voipCallAttribute?.extensionId !== '' &&
      callData.callState === CallStateConst.CALL_STATUS_ACTIVE;
    if (subVoipCallCheck) {
      BannerNotificationManager.enableBannerNotification(false);
      return;
    }
    let notShowBannerForIncomingCall = callData.voipCallAttribute?.extensionId === '' &&
      callData.voipCallAttribute?.showBannerForIncomingCall !== undefined &&
      !callData.voipCallAttribute?.showBannerForIncomingCall;
    if (notShowBannerForIncomingCall) {
      LogUtils.i(TAG, 'The current application is in the foreground.');
      BannerNotificationManager.enableBannerNotification(false);
      return;
    }
    if (callData.callState !== CallStateConst.CALL_STATUS_INCOMING &&
      callData.callState !== CallStateConst.CALL_STATUS_DIALING) {
      return;
    }
    if (CallDataManager.getInstance().hasAnyAliveCall()) {
      return;
    }
    try {
      LogUtils.i(TAG, `productSeries is vde: ${deviceInfo.productSeries.startsWith('VDE')}`);
      // VDE折叠状态，需设置横幅为true
      if (!isScreenLocked() || (display.isFoldable() && deviceInfo.productSeries.startsWith('VDE') &&
        (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED ||
          display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED))) {
        LogUtils.i(TAG, 'current Notification is true');
        AppStorage.setOrCreate('firstVoipCall', true);
        BannerNotificationManager.enableBannerNotification(true);
      } else {
        BannerNotificationManager.enableBannerNotification(false);
      }
    } catch (err) {
      LogUtils.i(TAG, `enableBannerNotification error code: ${err?.code}, msg: ${err?.message}`);
    }
  }
}
