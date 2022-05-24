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

import CallManager from './model/CallManager';
import CallStateConst from './common/constant/CallStateConst';
import HiLog from './common/utils/Hilog';
import deviceInfo from '@ohos.deviceInfo';

const TAG = "App";

export default  {
  data:{
    callData: {
      ...CallStateConst.defaultCallData
    },
    callList: [],
    callTimeList: [],
    appInactiveState: false,
  },

  /**
   * onCreate
   */
  onCreate() {
    globalThis.deviceTypeInfo = deviceInfo.deviceType;
    HiLog.i(TAG, "callui app Application onCreate")
  },

  /**
   * onDestroy
   */
  onDestroy() {
    HiLog.i(TAG, "callui app Application onDestroy")
    globalThis.callManager.clearTimer();
    globalThis.callManager.unsubscribe();
  }
};