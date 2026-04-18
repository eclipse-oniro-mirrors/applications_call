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
import StaticSubscriberExtensionAbility from '@ohos.application.StaticSubscriberExtensionAbility'
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import LogUtils from '../utils/HiLog';
import { call, observer, sim } from '@kit.TelephonyKit';

const TAG = 'SosLocationSubscriber'

export default class SosLocationSubscriber {
  public callState = 0
  public isTimeCounting = false
  public called = ''
  public caller = 0
  public telephoneNumber = ''
  public onCallState = this.onCallStateChange()

  ReceiveEvent(called: string, caller: number) {
    this.onCallStateChange();
    this.called = called
    this.caller = caller
  }

  onCallStateChange() {
    try {
      return observer.on('callStateChange', (callStateInfo) => {
        this.handleCallStateChange(callStateInfo)
        LogUtils.i(TAG, 'registerCallStateChange: then ' + callStateInfo.state)
        return callStateInfo
      });
    } catch (e) {
      LogUtils.e(TAG, 'listen to CallStateChange failed: ' + JSON.stringify(e));
    }
  }

  offCallStateChange() {
    try {
      LogUtils.i(TAG, 'unregisterCallStateChange');
      return observer.off('callStateChange');
    } catch (e) {
      LogUtils.e(TAG, 'off to CallStateChange failed: ' + JSON.stringify(e));
    }
  }

  async sendLocationInfo() {
    LogUtils.i(TAG, 'sendLocationInfo start')
    this.isTimeCounting = true
    this.telephoneNumber = await this.getSimCardPhoneNumber(this.caller)
    let timeoutID = setInterval(() => {
      if (this.callState !== 2) {
        this.isTimeCounting = false
        LogUtils.i(TAG, 'sendLocationInfo end')
        clearInterval(timeoutID);
      }
    }, 1000)
  }

  handleCallStateChange(callStateInfo: observer.CallStateInfo) {
    LogUtils.i(TAG, 'handleCallStateChange');
    if (callStateInfo.state === 2 && !this.isTimeCounting) {
      LogUtils.i(TAG, 'handleCallStateChange callStateInfo.state: ' + callStateInfo.state);
      this.callState = callStateInfo.state
      this.sendLocationInfo()
    } else if (callStateInfo.state === 0 || callStateInfo.state === -1) {
      this.callState = callStateInfo.state
      this.offCallStateChange()
    }
  }

  async getSimCardPhoneNumber(caller: number) {
    let telephoneNumber: string = '';
    await sim.getShowNumber(caller).then(async (res) => {
      if (res === '') {
        await sim.getSimTelephoneNumber(caller).then((resDefault: string) => {
          telephoneNumber = resDefault;
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'getSimTelephoneNumber card1 other catch' + JSON.stringify(err));
        })
      } else {
        telephoneNumber = res;
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'getSimCardOnePhoneNumber card1 other catch' + JSON.stringify(err));
    });
    return telephoneNumber
  }
}
