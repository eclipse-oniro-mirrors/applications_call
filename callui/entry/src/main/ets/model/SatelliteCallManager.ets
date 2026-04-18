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

/**
 * @file: satellite Call management
 */
import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import DefaultCallData from '../common/struct/TypeUtils';
import Utils from '../common/utils/utils';
import { App } from '@kit.ArkUI';

const TAG = 'SatelliteCallManager';

/**
 * class SatelliteCallManager
 */
export default class SatelliteCallManager {
  private static sCallDataManager: SatelliteCallManager;

  public static getInstance(): SatelliteCallManager {
    if (!SatelliteCallManager.sCallDataManager) {
      SatelliteCallManager.sCallDataManager = new SatelliteCallManager();
    }
    return SatelliteCallManager.sCallDataManager;

  }

  public tryShowSatelliteCallAnswerToast(oldCall: DefaultCallData, newCall: DefaultCallData) {
    LogUtils.i(TAG, 'show satellite call answer Toast oldCallId:' + oldCall.callId + ',newCallId:' + newCall.callId);
    if (oldCall.callType !== CallStateConst.TYPE_SATELLITE || newCall.callType !== CallStateConst.TYPE_SATELLITE) {
      return;
    }
    if (oldCall.callState === newCall.callState) {
      // The satellite call answer toast should only prompted when call state changed
      return;
    }
    if ((oldCall.callState === CallStateConst.CALL_STATUS_INCOMING ||
      oldCall.callState === CallStateConst.CALL_STATUS_WAITING) &&
      (newCall.callState === CallStateConst.CALL_STATUS_ANSWER ||
        newCall.callState === CallStateConst.CALL_STATUS_ACTIVE)) {
      Utils.getInstance().showToast(AppStorage.get<boolean>('isHyacinthMode') ? $r('app.string.disableChangedToEarpiece_hyacinth') : $r('app.string.disableChangedToEarpiece'), 2000);
    }
  }
}