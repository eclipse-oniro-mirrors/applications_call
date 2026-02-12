/*
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
import { addAirPlaneModeListener, queryAirPlaneMode, removeAirPlaneModeListener } from '@ohos/common/CommonIndex';

let AirplaneModeTest_addAirPlaneModeListener = async () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(dataShare.createDataShareHelper, dataShare.createDataShareHelper);
  when(mockFunc)(ArgumentMatchers.any).afterReturnNothing();
  addAirPlaneModeListener(() => {
    expect(true).assertTrue();
  });
  mocker.clearAll();
}

let AirplaneModeTest_queryAirPlaneMode = () => {
  queryAirPlaneMode(() => {
    expect(true).assertTrue();
  });
}

let AirplaneModeTest_removeAirPlaneModeListener = () => {
  removeAirPlaneModeListener();
  expect(true).assertTrue();
}

export default function AirplaneModeTest() {
  describe('AirplaneModeTest', () => {
    it('AirplaneModeTest_addAirPlaneModeListener', 0, () => {
      AirplaneModeTest_addAirPlaneModeListener();
    });
    it('AirplaneModeTest_queryAirPlaneMode', 0, () => {
      AirplaneModeTest_queryAirPlaneMode();
    });
    it('AirplaneModeTest_removeAirPlaneModeListener', 0, () => {
      AirplaneModeTest_removeAirPlaneModeListener();
    });
  });
}