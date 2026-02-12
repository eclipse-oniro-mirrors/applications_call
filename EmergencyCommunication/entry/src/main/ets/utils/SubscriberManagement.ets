/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import CommonEventManager from '@ohos.commonEventManager';
import LogUtils from './HiLog';
import EmergencyCallController from '../control/EmergencyCallControl';
import { BusinessError } from '@ohos.base';

let subscriber: CommonEventManager.CommonEventSubscriber;
const TAG = 'SubscriberManagement';
const events = ['usual.event.SPN_INFO_CHANGED'];

export class SubscriberManagement {
  /**
   * Registered subscribers
   */
  public async registerSubscriber() {
    EmergencyCallController.getInstance().getSimOperatorNames();
    if (!CommonEventManager?.createSubscriber) {
      return;
    }
    subscriber = await new Promise((resolve) => {
      CommonEventManager.createSubscriber({
        events,
        priority: 1000,
        publisherPermission: 'ohos.permission.GET_TELEPHONY_STATE'
      },
        (err, data) => {
          resolve(data);
        }
      );
    });

    CommonEventManager.subscribe(subscriber, (err: BusinessError, res) => {
      if (err) {
        LogUtils.i(TAG, 'CommonEventManager.subscribe err : %s' + JSON.stringify(err));
      } else {
        LogUtils.i(TAG, 'CommonEventManager subscribe');
        let value: string = res.parameters?.CUR_PLMN ? res.parameters.CUR_PLMN : '';
        if (res.parameters?.CUR_SLOT_ID) {
          AppStorage.setOrCreate('simOperatorNameSecond', value);
        } else {
          AppStorage.setOrCreate('simOperatorNameFirst', value);
        }
        EmergencyCallController.getInstance().getDefaultVoiceSlotId();
      }
    });
  }

  /**
   * unsubscribe
   */
  public unsubscribe() {
    if (!subscriber) {
      return;
    }
    CommonEventManager.unsubscribe(subscriber, (err) => {
      if (err) {
        LogUtils.e(TAG, 'CommonEventManager.unsubscribe err: ' + JSON.stringify(err));
      }
    });
  }
}

let mSubscriberManagement = new SubscriberManagement();

export default mSubscriberManagement as SubscriberManagement;