/**
 * Copyright (c) 2024-2025 Huawei Device Co., Ltd.
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

import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import LogUtils from '../../../main/ets/common/utils/LogUtils';
import { VideoController} from '../../../main/ets/controller/VideoController';

export default function VideoControllerTest() {
  describe('getInstance_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('should_return_same_instance_when_getInstance_is_called_multiple_times', 0, () => {
      let instance1: VideoController = VideoController.getInstance();
      let instance2: VideoController = VideoController.getInstance();
      expect(instance1).assertEqual(instance2);
    });

    it('should_create_avPlayer_successfully', 0, async () => {
      let videoController: VideoController = new VideoController();
      let mocker: MockKit = new MockKit();
      let mockSetAVPlayerCallback: Function = mocker.mockFunc(videoController, videoController.setAVPlayerCallback);
      when(mockSetAVPlayerCallback)(ArgumentMatchers.any).afterReturnNothing();

      await videoController.createAVPlayer();
      let result: string = (videoController as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(videoController, videoController.setAVPlayerCallback);
    });

    it('should_handle_error_when_createAVPlayer_fails', 0, async () => {
      let videoController: VideoController = new VideoController();
      let mocker: MockKit = new MockKit();
      let mockSetAVPlayerCallback: Function = mocker.mockFunc(videoController, videoController.setAVPlayerCallback);
      when(mockSetAVPlayerCallback)(ArgumentMatchers.any).afterReturnNothing();
      await videoController.createAVPlayer();
      let result: string = (videoController as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(videoController, videoController.setAVPlayerCallback);
    });

    it('should_call_prepare_when_avPlayer_is_not_undefined', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let videoController: VideoController = new VideoController();

      await videoController.stopPlay();
      let result: string = (videoController as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_not_call_prepare_when_avPlayer_is_undefined', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let videoController: VideoController = VideoController.getInstance();

      await videoController.stopPlay();
      let result: string = (videoController as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_release_play_anyway', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let instance1: VideoController = VideoController.getInstance();
      await instance1.releasePlayAnyway();
      let result: string = (instance1 as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_do_prepared', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let instance1: VideoController = VideoController.getInstance();
      await instance1.doPrepared();
      let result: string = (instance1 as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_stop_ringing', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let instance1: VideoController = VideoController.getInstance();
      instance1.stopRinging();
      let result: string = (instance1 as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_pause_play', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let instance1: VideoController = VideoController.getInstance();
      await instance1.pausePlay();
      let result: string = (instance1 as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });


    it('should_re_play', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();

      let instance1: VideoController = VideoController.getInstance();
      await instance1.rePlay();
      let result: string = (instance1 as object)['isDoNotDisturb'];
      expect(result).assertFalse();
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });
  });
}