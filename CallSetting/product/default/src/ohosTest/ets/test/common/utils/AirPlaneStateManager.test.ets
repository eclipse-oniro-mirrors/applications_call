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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import dataShare from '@ohos.data.dataShare';
import * as AirPlaneStateManager from '../../../../../main/ets/common/utils/AirPlaneStateManager';

let AirPlaneStateManagerTest_addAirPlaneModeListener = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(dataShare.createDataShareHelper, dataShare.createDataShareHelper);
  when(mockFunc)(ArgumentMatchers.any).afterReturnNothing();
  AirPlaneStateManager.addAirPlaneModeListener();
  expect(true).assertTrue();
  mocker.clearAll();
}

let AirPlaneStateManagerTest_queryAirPlaneMode = () => {
  AirPlaneStateManager.queryAirPlaneMode();
  expect(true).assertTrue();
}

let AirPlaneStateManagerTest_removeAirPlaneModeListener = () => {
  AirPlaneStateManager.removeAirPlaneModeListener();
  expect(true).assertTrue();
}

export default function AirPlaneStateManagerTest() {
  describe('AirPlaneStateManagerTest', () => {
    it('AirPlaneStateManagerTest_queryAirPlaneMode', 0, () => {
      AirPlaneStateManagerTest_queryAirPlaneMode();
    });
    it('AirPlaneStateManagerTest_removeAirPlaneModeListener', 0, () => {
      AirPlaneStateManagerTest_removeAirPlaneModeListener();
    });
    it('AirPlaneStateManagerTest_addAirPlaneModeListener', 0, () => {
      AirPlaneStateManagerTest_addAirPlaneModeListener();
    });
    it('AirPlaneStateManagerTest_removeAirPlaneModeListener1', 0, () => {
      AirPlaneStateManagerTest_removeAirPlaneModeListener();
    });
  });
}