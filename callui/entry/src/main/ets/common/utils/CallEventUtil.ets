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

import LogUtils from './LogUtils';
import CommonEventManager from '@ohos.commonEventManager';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ReportUtil';
const VOIP_EVENTS = 'usual.event.EXTENSION_LOAD';
const DROPDOWN_WINDOW_EVENT = 'sceneboard.event.HIDE_DROPDOWN_WINDOW';
const DROPDOWN_WINDOW_EVENT_OPTIONS: CommonEventManager.CommonEventPublishData = {
  subscriberPermissions: ['ohos.permission.NOTIFICATION_CONTROLLER']
}

export class CallEventUtil {
  public static readonly EVENT_SUCCESS = 100;
  public static readonly EVENT_FAIL = 101;
  public static readonly UI_ABILITY_DESTROY_NORMAL = 102;
  public static readonly UI_ABILITY_DESTROY_ABNORMAL = 103;

  public static sendCommonEvent(options: CommonEventManager.CommonEventPublishData): void {
    try {
      CommonEventManager.publish(VOIP_EVENTS, options, err => {});
    } catch (err) {
      LogUtils.e(TAG, `sendCommonEvent: ${err.code}, message is ${err.message}`);
    }
  }

  public static async sendDropdownWindowEvent(): Promise<void> {
    try {
      CommonEventManager.publish(DROPDOWN_WINDOW_EVENT, DROPDOWN_WINDOW_EVENT_OPTIONS, (err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, `send drop down window event fail: ${err.code}, message is ${err.message}`);
        }
      });
      LogUtils.i(TAG, 'send drop down window event finish');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `send drop down window event fail:, code is ${err.code}, message is ${err.message}`);
    }
  }

  public static getEventOptions(
    eventId: number, voipBundleName: string, voipCallId?: string, uid?: number) {
    let result: CommonEventManager.CommonEventPublishData = {
      code: eventId,
      subscriberPermissions: ['ohos.permission.GET_TELEPHONY_STATE'],
      isOrdered: false,
      isSticky: false,
      parameters: {
        voipBundleName: voipBundleName,
        voipCallId: voipCallId,
        uid: uid
      }
    };
    return result;
  }
}