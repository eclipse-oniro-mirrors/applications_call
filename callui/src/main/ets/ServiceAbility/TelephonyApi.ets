/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
 * @file: Voice call API interface call
 */

import call from '@ohos.telephony.call';
import HiLog from '../default/common/utils/Hilog.ets';

const prefixLog = 'callui service:@ohos.telephony.call:';
const TAG = "TelephonyApi";

export default class TelephonyApi {

  /**
   * register call state callback
   *
   * @param { Function } callBack - inject an Function
   */
  public registerCallStateCallback(callBack) {
    call.on('callDetailsChange', (err, res) => {
      if (err) {
        HiLog.i(TAG,prefixLog + 'call.on registerCallStateCallback' + JSON.stringify(err))
        return;
      }
      HiLog.i(TAG,prefixLog + 'call.on registerCallStateCallback callState: ' + JSON.stringify(res.callState))
      callBack(res);
    });
  }

  /**
   * onRegister call state callback
   */
  public unRegisterCallStateCallback() {
    call.off('callDetailsChange', (err, res) => {
      if (err) {
        HiLog.i(TAG,prefixLog + 'call.off unRegisterCallStateCallback' + JSON.stringify(err))
        return;
      }
      HiLog.i(TAG,prefixLog + 'call.off unRegisterCallStateCallback' + JSON.stringify(res))
    });
  }
}


