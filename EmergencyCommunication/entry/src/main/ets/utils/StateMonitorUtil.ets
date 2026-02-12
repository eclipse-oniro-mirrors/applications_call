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

import { BusinessError } from '@ohos.base';
import radio from '@ohos.telephony.radio';
import LogUtils from './HiLog';

const TAG = 'StateMonitorUtil';

export function checkRadioOn(callback: (slotId: number) => void) {
  // Used in nested mode to avoid problems caused by async.
  isRadioOn(0, (resSlotFirst) => {
    if (resSlotFirst) {
      callback(0);
    } else {
      isRadioOn(1, (resSlotSec) => {
        if (resSlotSec) {
          callback(1);
        }
      })
    }
  })
}

function isRadioOn(slotId: number, callback: (result: boolean) => void) {
  radio.isRadioOn(slotId, (err: BusinessError, data: boolean) => {
    LogUtils.i(TAG, `Success, slotId:${JSON.stringify(slotId)} isRadioOn->${data}`);
    if (err) {
      callback(false);
      LogUtils.e(TAG, `isRadioOn failed: err->${JSON.stringify(err)}`);
    } else {
      callback(data);
    }
  });
}