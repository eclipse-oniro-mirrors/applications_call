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
import { LogUtils } from '@ohos/common/CommonIndex';
import commonEventManager from '@ohos.commonEventManager';
import { terminalDialogAbility } from './Utils';

let subscriber: commonEventManager.CommonEventSubscriber;
const TAG = 'SubscriberManagement';
const events = ['usual.event.CALL_STATE_CHANGED'];

export class SubscriberManagement {
  /**
   * Registered subscribers
   */
  public async registerSubscriber() {
    LogUtils.i(TAG, 'registerSubscriber-');
    subscriber = await new Promise((resolve) => {
      commonEventManager.createSubscriber({
        events,
        priority: 1000
      },
        (err, data) => {
          resolve(data);
        }
      );
    });

    commonEventManager.subscribe(subscriber, (err, res) => {
      LogUtils.i(TAG, 'commonEvent subscribe 1 : %s' + JSON.stringify(res));
      if (err) {
        LogUtils.i(TAG, 'CommonEventManager.subscribe err : %s' + JSON.stringify(err));
      } else {
        if (res.parameters?.state === 6 || res.parameters?.state === 7) {
          terminalDialogAbility();
        }
      }
    });
  }

  /**
   * unsubscribe
   */
  public unsubscribe() {
    commonEventManager.unsubscribe(subscriber, (err) => {
      if (err?.code !== 0) {
        LogUtils.i(TAG, 'commonEvent.unsubscribe err: %s' + JSON.stringify(err))
      }
    });
  }
}

let mSubscriberManagement = new SubscriberManagement();

export default mSubscriberManagement as SubscriberManagement;