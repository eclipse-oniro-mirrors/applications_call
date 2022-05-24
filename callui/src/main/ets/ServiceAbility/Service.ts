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
 * @file: service entry
 */

import CallManagerService from './CallManagerService';
import HiLog from '../default/common/utils/Hilog';

const TAG = "Service";

export default {

  /**
   * onStart
   */
  onStart() {
    HiLog.i(TAG, "onStart callUI service")
    this.callManagerService = new CallManagerService();
  },

  /**
   * onStop
   */
  onStop() {
    HiLog.i(TAG, "onStop callUI service")
    this.callManagerService.unsubscribe();
    this.callManagerService.removeRegisterListener();
  }
};
