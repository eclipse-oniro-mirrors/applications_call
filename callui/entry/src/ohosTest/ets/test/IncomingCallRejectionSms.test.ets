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
import i18n from '@ohos.i18n';
import { BusinessError } from '@ohos.base';
import commonEventManager from '@ohos.commonEventManager';
import display from '@ohos.display';

export default function IncomingCallRejectionSms() {
  describe('IncomingCallRejectionSmsTest', () => {
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
    it('testSystemLanguageChange', 0, () => {
      try {
        let curLanguage = i18n.System.getSystemLanguage();

        //subscriber language change
        let subscriber: commonEventManager.CommonEventSubscriber;
        let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
          events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
        };
        commonEventManager.createSubscriber(subscribeInfo)
          .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
            subscriber = commonEventSubscriber;
            commonEventManager.subscribe(subscriber, (err, data) => {
              if (err) {
                return;
              }
              curLanguage = i18n.System.getSystemLanguage();
            })
          })
          .catch((err: BusinessError) => {
            console.error(`call System.getSystemLanguage failed, error code: ${err.code}, message: ${err.message}.`);
          });

        let expectedLanguage: string = '';
        //Set system language to English or Chinese.
        if (curLanguage === 'en-Latn-CN') {
          i18n.System.setSystemLanguage('en-Latn-CN');
          expectedLanguage = 'en-Latn-CN';
        } else {
          i18n.System.setSystemLanguage('zh-Hans');
          expectedLanguage = 'zh-Hans';
        }

        setTimeout(() => {
          expect(curLanguage).assertEqual(expectedLanguage);
          commonEventManager.unsubscribe(subscriber, (err) => {
            if (err) {
              console.error('unsubscribe commonEvent.unsubscribe err:' + JSON.stringify(err));
            }
          });
        }, 3000)

      } catch (error) {
        let err: BusinessError = error as BusinessError;
        console.error(`call System.getSystemLanguage failed, error code: ${err.code}, message: ${err.message}.`);
      }
    })
    it('testFoldStatus', 0, () => {
      let currentFoldStatus : number = -1;
      currentFoldStatus = display.getFoldStatus();
      try {
        display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
          currentFoldStatus = foldStatus;
          foldStatus = 1;
        })
      } catch (exception) {
        console.error('Failed code ' + JSON.stringify(exception));
      }
      AppStorage.setOrCreate('foldStatus', currentFoldStatus)
      expect(currentFoldStatus).assertEqual(AppStorage.get<number>('foldStatus'));
    })
  })
}