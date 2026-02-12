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
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CALL_BUNDLE_NAME } from './Constants';
import LogUtils from './LogUtils';

const TAG = 'AccessibilityUtil';

export class AccessibilityUtil {
  /**
   * 无障碍模式下主动聚焦
   * @param customerId 对应待聚焦组间id属性值
   */
  static requestFocusForAccessibility(customerId: string): void {
    let screenReaderStatus = AppStorage.get<boolean>('screenReaderStatus');
    LogUtils.i(TAG, `requestFocusForAccessibility, screenReaderStatus is ${screenReaderStatus}`);
    if (!screenReaderStatus) {
      return;
    }

    let eventInfo: accessibility.EventInfo = {
      type: 'requestFocusForAccessibility',
      bundleName: CALL_BUNDLE_NAME,
      triggerAction: 'common',
      customId: customerId
    };

    // 发送聚焦事件
    try {
      // instrument ignore next
      accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, `failed to send event, code is ${err.code}, message is ${err.message}`);
          return;
        }
        LogUtils.i(TAG, `succeeded in send event, customerId is ${customerId}`);
      });
    } catch (e) {
      LogUtils.e(TAG, `sendAccessibilityEvent error, code is ${e.code}, message is ${e.message}`);
    }
  }

  /**
   * 无障碍模式下主动播报
   * @param customerId 内容
   */
  static announceForAccessibilityNotInterrupt(text: string) {
    let screenReaderStatus = AppStorage.get<boolean>('screenReaderStatus');
    LogUtils.i(TAG, `announceForAccessibilityNotInterrupt, screenReaderStatus is ${screenReaderStatus}`);
    if (!screenReaderStatus) {
      return;
    }

    let eventInfo: accessibility.EventInfo = ({
      type: 'announceForAccessibilityNotInterrupt',
      bundleName: CALL_BUNDLE_NAME,
      triggerAction: 'common',
      textAnnouncedForAccessibility: text
    });

    try {
      accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, `announceForAccessibilityNotInterrupt failed to send event, code is ${err.code}, message is ${err.message}`);
          return;
        }
        LogUtils.i(TAG, `announceForAccessibilityNotInterrupt succeeded in send event`);
      });
    } catch (e) {
      LogUtils.e(TAG, `announceForAccessibilityNotInterrupt error, code is ${e?.code}, message is ${e?.message}`);
    }
  }
}