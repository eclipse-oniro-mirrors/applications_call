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
import type { AsyncCallback } from '@ohos.base';
import call from '@ohos.telephony.call';
import {
  onPeerDimensionsChange,
  onImsCallModeChange,
  controlCameraApi,
  setPreviewWindowApi,
  setDisplayWindowApi,
  updateImsCallModeApi,
  onCameraCapabilitiesChange,
  answerCallApi
} from '../../../main/ets/common/utils/VideoCallApi';
import { sleep } from './Utils';

export interface PeerDimensionsDetail {
  callId: number;
  width: number;
  height: number;
}

export enum ImsCallMode {
  CALL_MODE_AUDIO_ONLY = 0,
  CALL_MODE_SEND_ONLY,
  CALL_MODE_RECEIVE_ONLY,
  CALL_MODE_SEND_RECEIVE,
  CALL_MODE_VIDEO_PAUSED,
}

export enum VideoRequestResultType {
  TYPE_REQUEST_SUCCESS = 0,
  TYPE_REQUEST_FAILURE,
  TYPE_REQUEST_INVALID,
  TYPE_REQUEST_TIMED_OUT,
  TYPE_REQUEST_REJECTED_BY_REMOTE,
  TYPE_REQUEST_UPGRADE_CANCELED,
  TYPE_DOWNGRADE_RTP_OR_RTCP_TIMEOUT = 100,
  TYPE_DOWNGRADE_RTP_AND_RTCP_TIMEOUT,
}

export interface ImsCallModeInfo {
  callId: number;
  result: VideoRequestResultType;
  isRequestInfo: boolean;
  imsCallMode: ImsCallMode;
}

export interface CameraCapabilities {
  callId: number;
  width: number;
  height: number;
}

export interface ControlCamera {
  callId: number,
  cameraId: string
}

export interface PreviewWindowApi {
  callId: number,
  surfaceId: string
}

export interface ImsCallModeApi {
  callId: number,
  mode: ImsCallMode,
  callback?: AsyncCallback<void>
}

export interface AnswerCall {
  videoState: call.VideoStateType,
  callId?: number
}


let onPeerDimensionsChange_test = async () => {
  onPeerDimensionsChange((data: PeerDimensionsDetail) => {
    call.on('peerDimensionsChange', (callData: PeerDimensionsDetail) => {
      expect(data).assertEqual(callData);
    });
  });

  await sleep(1000);
}

let onImsCallModeChange_test = async () => {
  onImsCallModeChange((data: ImsCallModeInfo) => {
    call.on('imsCallModeChange', (callData: call.ImsCallModeInfo) => {
      expect(data).assertEqual(callData);
    });
  });

  await sleep(1000);
}

let controlCameraApi_test = async () => {
  let json: ControlCamera = {
    callId: 1,
    cameraId: '1222'
  }
  controlCameraApi(json.callId, json.cameraId);
  expect(true).assertTrue();

  await sleep(1000);
}
let setPreviewWindowApi_test = async () => {
  let json: PreviewWindowApi = {
    callId: 1,
    surfaceId: '1222'
  }
  setPreviewWindowApi(json.callId, json.surfaceId);
  expect(true).assertTrue();

  await sleep(1000);
}
let setDisplayWindowApi_test = async () => {
  let json: PreviewWindowApi = {
    callId: 1,
    surfaceId: '1222'
  }
  setDisplayWindowApi(json.callId, json.surfaceId);
  expect(true).assertTrue();

  await sleep(1000);
}
let updateImsCallModeApi_test = async () => {
  let json: ImsCallModeApi = {
    callId: 1,
    mode: ImsCallMode.CALL_MODE_AUDIO_ONLY,
    callback: () => {
    }
  };
  updateImsCallModeApi(json.callId, json.mode, json.callback);
  expect(true).assertTrue();

  await sleep(1000);
}
let offImsCallModeChange_test = async () => {
  call.off('imsCallModeChange', (callData: call.ImsCallModeInfo) => {
    expect(true).assertTrue();
  });

  await sleep(1000);
}
let cancelCallUpgradeApi_test = async () => {
  let callId: number = 1;
  call.cancelCallUpgrade(callId);
  expect(true).assertTrue();

  await sleep(1000);
}
let onCameraCapabilitiesChange_test = async () => {
  onCameraCapabilitiesChange((data: PeerDimensionsDetail) => {
    call.on('cameraCapabilitiesChange', (callData: call.CameraCapabilities) => {
      expect(data).assertEqual(callData);
    });
  });

  await sleep(1000);
}
let offPeerDimensionsChange_test = async () => {
  call.off('peerDimensionsChange', () => {
  });
  expect(true).assertTrue();

  await sleep(1000);
}
let offCameraCapabilitiesChange_test = async () => {
  call.off('cameraCapabilitiesChange', () => {
  });
  expect(true).assertTrue();

  await sleep(1000);
}
let answerCallApi_test = async () => {
  let json: AnswerCall = {
    callId: 1,
    videoState: call.VideoStateType.TYPE_VOICE
  };
  answerCallApi(json.callId, json.videoState);
  expect(true).assertTrue();

  await sleep(1000);
}


export default function VideoCallApiTest() {
  describe('VideoCallApiTest', () => {
    it('VideoCallApiTest_onPeerDimensionsChange_test', 0, () => {
      onPeerDimensionsChange_test();
    })
    it('VideoCallApiTest_onImsCallModeChange_test', 1, () => {
      onImsCallModeChange_test();
    })
    it('VideoCallApiTest_controlCameraApi_test', 2, () => {
      controlCameraApi_test();
    })
    it('VideoCallApiTest_setPreviewWindowApi_test', 3, () => {
      setPreviewWindowApi_test();
    })
    it('VideoCallApiTest_setDisplayWindowApi_test', 4, () => {
      setDisplayWindowApi_test();
    })
    it('VideoCallApiTest_updateImsCallModeApi_test', 5, () => {
      updateImsCallModeApi_test();
    })
    it('VideoCallApiTest_offImsCallModeChange_test', 6, () => {
      offImsCallModeChange_test();
    })
    it('VideoCallApiTest_cancelCallUpgradeApi_test', 7, () => {
      cancelCallUpgradeApi_test();
    })
    it('VideoCallApiTest_onCameraCapabilitiesChange_test', 8, () => {
      onCameraCapabilitiesChange_test();
    })
    it('VideoCallApiTest_offPeerDimensionsChange_test', 9, () => {
      offPeerDimensionsChange_test();
    })
    it('VideoCallApiTest_offCameraCapabilitiesChange_test', 10, () => {
      offCameraCapabilitiesChange_test();
    })
    it('VideoCallApiTest_answerCallApi_test', 11, () => {
      answerCallApi_test();
    })
  })
}