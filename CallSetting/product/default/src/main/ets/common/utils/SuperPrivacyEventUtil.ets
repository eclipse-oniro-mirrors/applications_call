/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import { LogUtils } from '@ohos/common/CommonIndex';
import CommonEventManager from '@ohos.commonEventManager';

const TAG = 'SuperPrivacyEventUtil';
const SUPER_PRIVACY_MODE_EVENTS = 'usual.event.SUPER_PRIVACY_MODE';

export class SuperPrivacyEventUtil {
  public static readonly EVENT_SUCCESS = 100;
  public static readonly EVENT_FAIL = 101;
  public static readonly UI_ABILITY_DESTROY_NORMAL = 102;
  public static readonly UI_ABILITY_DESTROY_ABNORMAL = 103;
  public static readonly TYPE_VIDEO = 3;

  public static sendSuperPrivacyModeEvent(options: CommonEventManager.CommonEventPublishData): void {
    try {
      CommonEventManager.publish(SUPER_PRIVACY_MODE_EVENTS, options, err => {
        if (err) {
          LogUtils.e(TAG, `sendCommonEvent: ${err.code}, message is ${err.message}`);
        } else {
          LogUtils.i(TAG, 'publish CommonEvent' + options.code);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `sendCommonEvent: ${err.code}, message is ${err.message}`);
    }
  }

  public static getSuperPrivacyModeEventOptions(phoneNumber: String, accountId: number, videoState: number,
    dialScene: number, dialType: number, callType: number, isAnswer: boolean) {
    let result: CommonEventManager.CommonEventPublishData = {
      subscriberPermissions: ['ohos.permission.SET_TELEPHONY_STATE'],
      code: 100802,
      isOrdered: false,
      isSticky: false,
      parameters: {
        phoneNumber: phoneNumber,
        accountId: accountId,
        videoState: videoState,
        dialScene: dialScene,
        dialType: dialType,
        callType: callType,
        isAnswer: isAnswer
      }
    };
    return result;
  }

  public static getAnswerSuperPrivacyModeEventOptions(videoState: number, callId: number, isAnswer: boolean) {
    let result: CommonEventManager.CommonEventPublishData = {
      subscriberPermissions: ['ohos.permission.SET_TELEPHONY_STATE'],
      code: 100803,
      isOrdered: false,
      isSticky: false,
      parameters: {
        videoState: videoState,
        callId: callId,
        isAnswer: isAnswer
      }
    };
    return result;
  }

  public static getInCallSuperPrivacyModeEventOptions(isHangup: boolean) {
    let result: CommonEventManager.CommonEventPublishData = {
      subscriberPermissions: ['ohos.permission.SET_TELEPHONY_STATE'],
      code: 100803,
      isOrdered: false,
      isSticky: false,
      parameters: {
        isInCall: true,
        isHangup: isHangup
      }
    };
    return result;
  }
}
