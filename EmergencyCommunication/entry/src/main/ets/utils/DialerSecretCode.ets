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

import EmergencyCallController from '../control/EmergencyCallControl';
import LogUtils from './HiLog';

const TAG = 'DialerSecretCode';
const whiteList: Set<string> = new Set<string>([
  '*#2846#',
  '*#2846*',
  '*#28460',
  '*#28465#',
  '*#*#121314#*#*',
  '*#*#2589#*#*',
  '*#*#2845#*#*',
  '*#*#2846#*#*',
  '*#*#2847#*#*',
  '*#*#28465#*#*',
  '*#*#2846579#*#*'
])

export default class DialerSecretCode {
  private static sInstance: DialerSecretCode;

  static getInstance() {
    if (DialerSecretCode.sInstance == null) {
      DialerSecretCode.sInstance = new DialerSecretCode();
    }
    return DialerSecretCode.sInstance;
  }

  dealSecretCode(value: string): boolean {
    if (whiteList.has(value)) {
      LogUtils.i(TAG, 'dealSecretCode is called');
      let emergencyCallController = EmergencyCallController.getInstance();
      emergencyCallController.dialerSpecialCode(value);
      return true;
    }
    return false;
  }
}