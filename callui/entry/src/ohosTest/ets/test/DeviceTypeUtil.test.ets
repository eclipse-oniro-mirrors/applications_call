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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import CallStateConst from '../../../main/ets/common/constant/CallStateConst';
import { getDeviceTypeInfo } from '../../../main/ets/common/utils/DeviceTypeUtils';
import Utils from '../../../main/ets/common/utils/utils';
import { BannerResourceManager, CallStateType } from '../../../main/ets/model/BannerResourceManager';

export default function DeviceTypeUtilTest() {
  describe('DeviceTypeUtilTest', () => {
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
    it('testDeviceType', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      const deviceTypeInfo = getDeviceTypeInfo();
      const isTablet = deviceTypeInfo === 'tablet';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(isTablet || !isTablet).assertEqual(true);
    })
    it('getIconNamesByStateTest', 0, async () => {
      let bannerResManager = new BannerResourceManager(Utils.getInstance().getContext());
      let result = await bannerResManager.getIconNamesByState(CallStateType.OutGoingCall,CallStateConst.VIDEO_STATE_VOICE);
      expect(result?.names?.length).assertEqual(1);
    })
  })
}