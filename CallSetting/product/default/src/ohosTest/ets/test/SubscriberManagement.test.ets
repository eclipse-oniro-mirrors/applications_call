/**
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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

export default function SubscriberManagementTest() {
  describe('SubscriberManagementTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('SubscriberManagementTest001', 0, () => {
      try {
        let callState = 1;
        //subscriber language change
        let subscriber: commonEventManager.CommonEventSubscriber;
        let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
          events: ['usual.event.CALL_STATE_CHANGED']
        };
        commonEventManager.createSubscriber(subscribeInfo)
          .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
            subscriber = commonEventSubscriber;
            commonEventManager.subscribe(subscriber, (err, data) => {
              if (err) {
                return;
              }
              callState = data.parameters?.state;
            })
          })
          .catch((err: BusinessError) => {
            console.error(`call System.getSystemLanguage failed, error code: ${err.code}, message: ${err.message}.`);
          });
        setTimeout(() => {
          // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
          let a = 'test'
          // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
          expect(a).assertEqual('test')
          commonEventManager.unsubscribe(subscriber, (err) => {
            if (err) {
              console.error('unsubscribe commonEvent.unsubscribe err:' + JSON.stringify(err));
            }
          });
        }, 3000)
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        console.error(`call state change failed, error code: ${err.code}, message: ${err.message}.`);
      }
    })
  })
}