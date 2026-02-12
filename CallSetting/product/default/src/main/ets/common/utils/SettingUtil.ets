/*
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

import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import { settings } from '@kit.BasicServicesKit';
import { isSupportMultiDeviceCommunicationSharing } from './Utils';
import { observer } from '@kit.TelephonyKit';
import TipsJumpUtils, { FUN_NAME_DISTRIBUTED } from './PlaySkillsJumpUtils';

const TAG = 'SettingUtils';

export const GESTURE_FLIP_MUTE_CALL: string = 'motion_flip_mute_call';

export const GESTURE_PICK_UP_REDUCE_VOLUME: string = 'motion_pickup_reduce_call';

export const GESTURE_QUICK_CALL: string = 'motion_quick_answer';

/**
 * Monitor the call state
 *
 * @param {function} callBack - call-back
 */
export function onCallStateChange(callBack: Function) {
  return observer.on('callStateChange', (callStateInfo) => {
    callBack(callStateInfo);
    LogUtils.i(TAG, 'registerCallStateChange: then ' + callStateInfo?.state)
    return callStateInfo
  });
}

export function offCallStateChange() {
  LogUtils.i(TAG, 'unregisterCallStateChange');
  return observer.off('callStateChange');
}