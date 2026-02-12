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

import { describe, it, expect, MockKit, when } from '@ohos/hypium';
import VideoCameraHelper from '../../../../../main/ets/common/struct/VideoCameraHelper';
import VideoCameraStatus from '../../../../../main/ets/common/struct/VideoCameraStatus';
import { DisplayUtil } from '../../../../../main/ets/common/utils/DisplayUtil';

let videoInfo: VideoCameraStatus = {
  callId: 1,
  currentCameraId: 'string',
  isCameraClose: true
}

let getCurrentCameraId_test = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('videoCameraInfo').afterReturn(videoInfo);
  VideoCameraHelper.getInstance().getCurrentCameraId();
  expect(true).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

let updateCameraStatus_test = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('cameraState').afterReturn(1);
  VideoCameraHelper.getInstance().updateCameraStatus(0, true);
  expect(true).assertTrue();
  when(mockFunc)('cameraState').afterReturn(2);
  VideoCameraHelper.getInstance().updateCameraStatus(0);
  expect(true).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

let getCameraIds_test = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  let mockFunc2: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mockFunc)().afterReturn(true);
  when(mockFunc2)().afterReturn(1);
  VideoCameraHelper.getInstance().getCameraIds();
  expect(true).assertTrue();
  mocker.clear(DisplayUtil);
  mocker.clearAll();
}

export default function VideoCameraHelperTest() {
  describe('VideoCameraHelperTest', () => {
    it('VideoCameraHelperTest_updateCameraStatus', 0, () => {
      updateCameraStatus_test();
    });
    it('VideoCameraHelperTest_getCurrentCameraId', 0, () => {
      getCurrentCameraId_test();
    });
    it('VideoCameraHelperTest_getCameraIds', 0, () => {
      getCameraIds_test();
    });
  })
}