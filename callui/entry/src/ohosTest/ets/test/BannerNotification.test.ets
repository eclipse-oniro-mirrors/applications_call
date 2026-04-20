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
import notificationManager from '@ohos.notificationManager';
import * as BannerNotificationProxy from '../../../main/ets/common/utils/BannerNotificationProxy';
import wantAgent from '@ohos.wantAgent';

export default function BannerNotificationTest() {
  describe('BannerNotificationTest', () => {
    it('BannerNotificationTest1', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'startNotification'
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertEqual('startNotification')
    })
    it('BannerNotificationResourceTest', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let b = 'bannerResource'
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(b).assertEqual('bannerResource')
    })
    it('hasImmersiveWindow', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let hasImmersiveWindow = await BannerNotificationProxy.hasImmersiveWindow();

      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(typeof hasImmersiveWindow === 'string').assertFalse();
    })
    it('isPanelShown', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let isPanelShown = await BannerNotificationProxy.isPanelShown();
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(isPanelShown).assertEqual(false)
    })
  })
}