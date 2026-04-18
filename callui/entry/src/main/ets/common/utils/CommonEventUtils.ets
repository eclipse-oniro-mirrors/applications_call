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

import {commonEventManager} from '@kit.BasicServicesKit';
import LogUtils from './LogUtils';

const TAG = 'CommonEventUtils';

export async function createSubscriber(
  events: Array<string>): Promise<commonEventManager.CommonEventSubscriber | undefined> {
  let CONFIG_CHANGE_EVENT: commonEventManager.CommonEventSubscribeInfo = {
    events: events,
  }
  let subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined
  try {
    subscriber = await commonEventManager.createSubscriber(CONFIG_CHANGE_EVENT);
  } catch (err) {
    LogUtils.e(TAG, `createSubscriber err: code is ${err.code}, message is ${err.message}`);
  }
  return subscriber;
}

// instrument ignore next
export function subscribeEvent(callBack: Function, subscriber?: commonEventManager.CommonEventSubscriber) {
  try {
    if (!subscriber) {
      LogUtils.w(TAG, 'subscribe fail with invalid subscriber');
      return;
    }
    commonEventManager.subscribe(subscriber, (err, eventData: commonEventManager.CommonEventData) => {
      if (err) {
        LogUtils.e(TAG, `subscribe receve err: code is ${err?.code}, message is ${err?.message}`);
      } else {
        LogUtils.i(TAG, `{ ${eventData?.event}, ${eventData?.bundleName}, ${eventData?.data}, ${eventData?.code} }`);
        callBack(eventData?.data);
      }
    });
  } catch (err) {
    LogUtils.e(TAG, `subscribe err: code is ${err.code}, message is ${err.message}`);
  }
}

export function unSubscribeEvent(subscriber?: commonEventManager.CommonEventSubscriber): void {
  if (!subscriber) {
    LogUtils.w(TAG, 'unSubscribeConfigChange fail with invalid subscriber');
    return;
  }
  try {
    commonEventManager.unsubscribe(subscriber);
  } catch (err) {
    LogUtils.e(TAG, `unsubscribe err: code is ${err.code}, message is ${err.message}`);
  }
}