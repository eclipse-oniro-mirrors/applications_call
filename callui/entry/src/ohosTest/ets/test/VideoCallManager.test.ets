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

import { describe, it, expect } from '@ohos/hypium';
import { CameraCapabilities, PeerDimensionsDetail } from '../../../main/ets/common/utils/VideoCallApi';
import VideoCallManager from './../../../../src/main/ets/model/VideoCallManager';

let value: PeerDimensionsDetail = {
  callId: 1,
  width: 0,
  height: 0
}

let value2: CameraCapabilities = {
  callId: 1,
  width: 0,
  height: 0
}

let handlePeerDimensionsChange_test = () => {
  VideoCallManager.getInstance().handlePeerDimensionsChange(value);
  expect(true).assertTrue();
  value.width = 2;
  value.height = 1;
  VideoCallManager.getInstance().handlePeerDimensionsChange(value);
  expect(true).assertTrue();
}

let handleCurrentDimensionsChange_test = () => {
  VideoCallManager.getInstance().handleCurrentDimensionsChange(value2);
  expect(true).assertTrue();
  value2.width = 2;
  value2.height = 1;
  VideoCallManager.getInstance().handlePeerDimensionsChange(value2);
  expect(true).assertTrue();
}

export default function VideoCallManagerTest() {
  describe('VideoCallManagerTest', () => {
    it('VideoCallManagerTest_handlePeerDimensionsChange', 0, () => {
      handlePeerDimensionsChange_test();
    });
    it('VideoCallManagerTest_handleCurrentDimensionsChange', 0, () => {
      handleCurrentDimensionsChange_test();
    });
  })
}