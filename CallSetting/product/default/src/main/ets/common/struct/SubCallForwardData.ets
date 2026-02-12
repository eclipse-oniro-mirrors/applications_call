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

import call from '@ohos.telephony.call';

export default class SubCallForwardData {
  public displayName: Resource;
  public isEnable?: boolean;
  public isFirst?: boolean;
  public isLast?: boolean;
  /*
   * 0: CALL_TRANSFER_DISABLE
   * 1: CALL_TRANSFER_ENABLE
   * 3: CALL_TRANSFER_REGISTRATION
   * 4: CALL_TRANSFER_ERASURE
   * */
  public forwardResult?: call.CallTransferResult;
  public callForwardType: call.CallTransferType;

  constructor(displayName: Resource, callForwardType: call.CallTransferType, isEnable?: boolean,
    forwardResult?: call.CallTransferResult, isFirst?: boolean, isLast?: boolean) {
    this.displayName = displayName;
    this.callForwardType = callForwardType;
    this.isEnable = isEnable;
    this.forwardResult = forwardResult;
    this.isFirst = isFirst;
    this.isLast = isLast;
  }
}
