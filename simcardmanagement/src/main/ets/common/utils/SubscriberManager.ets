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
import commonEvent from '@ohos.commonEvent';
import LogUtils from './LogUtils'
let subscriber;
const TAG = "SubscriberManager"
const events = ['usual.event.SPN_INFO_CHANGED', 'usual.event.SIM_STATE_CHANGE'];

export class SubscriberManager {

  /**
   * Registered subscribers
   */
  public async registerSubscriber() {
    subscriber = await new Promise((resolve) => {
      commonEvent.createSubscriber({
        events,
        priority: 1000
      },
        (err, data) => {
          resolve(data);
        }
      );
    });

    commonEvent.subscribe(subscriber, (err, res) => {
      LogUtils.i(TAG, "commonEvent subscribe 1 : %s" + JSON.stringify(res));
      if (err.code === 0) {
        LogUtils.i(TAG, "commonEvent subscribe : %s" + JSON.stringify(res));
        if (!!res.parameters.CUR_PLMN) {
          AppStorage.SetOrCreate("operatorName", res.parameters);
        }
      } else {
        LogUtils.i(TAG, "commonEvent.subscribe err : %s" + JSON.stringify(err));
      }
    });
  }
  /**
   * unsubscribe
   */
  public unsubscribe() {
    commonEvent.unsubscribe(subscriber, (err) => {
      if (err.code !== 0) {
        LogUtils.i(TAG, "commonEvent.unsubscribe err: %s" + JSON.stringify(err))
      }
    });
  }
}

let mSubscriberManager = new SubscriberManager();

export default mSubscriberManager as SubscriberManager;