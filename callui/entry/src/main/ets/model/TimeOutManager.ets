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

import CallStateConst from '../common/constant/CallStateConst';
import DefaultCallData from '../common/struct/TypeUtils';
import CallUtils from '../common/utils/CallUtils';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'TimeOutManager';

@Observed
export class TimeOutManager {
  public isAnsweredTimeOut: boolean = false;
  private timeOutId: number = -1;
  private isAnsweredState: boolean = false;
  private static sTimeOutManager: TimeOutManager;

  public static getInstance(): TimeOutManager {
    if (!TimeOutManager.sTimeOutManager) {
      TimeOutManager.sTimeOutManager = new TimeOutManager();
    }
    return TimeOutManager.sTimeOutManager;
  }

  public answeredTimeOutListener(callData: DefaultCallData): void {
    const callState: number = callData.callState
    if (callState === CallStateConst.CALL_STATUS_DIALING) {
      return;
    }
    if (CallUtils.isVoipCall(callData)) {
      return;
    }
    if (this.isAnsweredState && callState !== CallStateConst.CALL_STATUS_ANSWER) {
      if (this.timeOutId !== -1) {
        LogUtils.i(TAG, 'answeredTimeOutListener clearTimeout');
        clearTimeout(this.timeOutId);
        this.isAnsweredTimeOut = false;
        this.isAnsweredState = false;
      }
    }
    if (callState === CallStateConst.CALL_STATUS_ANSWER) {
      if (this.timeOutId !== -1) {
        LogUtils.i(TAG, 'answeredTimeOutListener clearTimeout Has started timing');
        clearTimeout(this.timeOutId);
      }
      this.isAnsweredState = true;
      this.timeOutId = setTimeout(() => {
        LogUtils.i(TAG, 'answeredTimeOutListener show call is Connecting');
        this.isAnsweredTimeOut = true;
      }, 1500);
    }
  }
}