/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

/**
 * @file: Video Call data management
 */
import { BusinessError, Callback } from '@ohos.base';
import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import DefaultCallData from '../common/struct/TypeUtils';
import * as DeviceTypeConst from '../common/constant/DeviceTypeConst';
import {
  controlCameraApi,
  ImsCallMode,
  ImsCallModeInfo,
  PeerDimensionsDetail,
  setDisplayWindowApi,
  setPreviewWindowApi,
  VideoRequestResultType,
  VideoStateType,
  CRS_TONE_NUM,
  CameraCapabilities,
  updateImsCallModeApi,
} from '../common/utils/VideoCallApi';
import BottomViewModel from '../viewmodel/BottomViewModel';
import {
  isActiveCall,
  isHdVideoRbt,
  isIncomingCall,
  isOneWayVideo,
  isOutgoingCall,
  isVideoCall,
  isVoiceCall,
  shouldShowRbtView
} from '../common/utils/CallListHelper';
import VideoCameraHelper from '../common/struct/VideoCameraHelper';
import CallManagerService from '../ServiceAbility/CallManagerService';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import Method from '../common/utils/Method';
import { call } from '@kit.TelephonyKit';
import Utils from '../common/utils/utils';
import { emitter } from '@kit.BasicServicesKit';
import { OPEN_VIDEO_CAMERA } from '../common/utils/Constants';

const TAG = 'VideoCallManager';

/**
 * class VideoCallManager
 */
export default class VideoCallManager {
  private callData: DefaultCallData = new DefaultCallData();
  private callList: Array<DefaultCallData> = [];
  private static sCallDataManager: VideoCallManager;
  public peerScreenAspectRatio: number = -1;
  public currentScreenAspectRatio: number = -1;
  public imsCallModeInfo?: ImsCallModeInfo;
  private mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  public currentOpenedCameraCallId: number = -1;
  public callSessionEvent: call.CallSessionEvent[] = [];

  public static getInstance(): VideoCallManager {
    if (!VideoCallManager.sCallDataManager) {
      VideoCallManager.sCallDataManager = new VideoCallManager();
    }
    return VideoCallManager.sCallDataManager;
  }

  private handleCallModeAudioOnly(imsCallModeInfo: ImsCallModeInfo, updatedCall: DefaultCallData) {
    if (imsCallModeInfo.result === VideoRequestResultType.TYPE_REQUEST_REJECTED_BY_REMOTE) {
      if (isVideoCall(updatedCall.videoState)) {
        // Remote rejected
        this.fallbackToEarpiece();
        Utils.getInstance().showToast($r('app.string.rejectVideoMsg'));
        // We should set the video state back to voice manually if remote rejected our video upgrade request.
        updatedCall.videoState = VideoStateType.TYPE_VOICE;
        this.controlCamera(updatedCall.callId, '');
        setPreviewWindowApi(updatedCall.callId, '');
        ReportUtil.getInstance().reportCallInterfaceClickBtn('video', false);
      } else {
        // Upgrade request canceled
        this.needDisplayUpgradeVideo(false);
      }
    } else if (imsCallModeInfo.result === VideoRequestResultType.TYPE_REQUEST_TIMED_OUT) {
      this.needDisplayUpgradeVideo(false);
      updatedCall.videoState = VideoStateType.TYPE_VOICE;
      this.controlCamera(updatedCall.callId, '');
      setPreviewWindowApi(updatedCall.callId, '');
      this.fallbackToEarpiece();
      ReportUtil.getInstance().reportCallInterfaceClickBtn('video', false);
    } else if (imsCallModeInfo.result === VideoRequestResultType.TYPE_REQUEST_SUCCESS) {
      if (imsCallModeInfo.isRequestInfo) {
        if (isActiveCall(updatedCall.callState)) {
          // Remote downgrade request
          Utils.getInstance().showToast($r('app.string.switchVoiceCallMsg'));
        }
        this.controlCamera(updatedCall.callId, '');
        setPreviewWindowApi(updatedCall.callId, '');
        setDisplayWindowApi(updatedCall.callId, '');
      }
    } else if (imsCallModeInfo.result === VideoRequestResultType.TYPE_REQUEST_FAILURE) {
      this.handleUpgradeFailures(imsCallModeInfo, updatedCall);
    }
  }

  private handleUpgradeFailures(imsCallModeInfo: ImsCallModeInfo, updatedCall: DefaultCallData) {
    if (!imsCallModeInfo.isRequestInfo) {
      if (isActiveCall(updatedCall.callState)) {
        this.fallbackToEarpiece();
        updatedCall.videoState = VideoStateType.TYPE_VOICE;
        updatedCall.imsCallMode = ImsCallMode.CALL_MODE_AUDIO_ONLY;
        if (AppStorage.get('acceptVideoCallDialog')) {
          this.needDisplayUpgradeVideo(false);
        } else {
          Utils.getInstance().showToast($r('app.string.switchVideoCallFailed'));
        }
        this.controlCamera(updatedCall.callId, '');
        setPreviewWindowApi(updatedCall.callId, '');
      }
    }
  }

  public handleImsCallModeChange(imsCallModeInfo: ImsCallModeInfo, updatedCall: DefaultCallData) {
    LogUtils.i(TAG, `onImsCallModeChange ImsCallModeInfoe :${JSON.stringify(imsCallModeInfo)}`);
    let newImsCallMode = imsCallModeInfo.imsCallMode;
    switch (newImsCallMode) {
      case ImsCallMode.CALL_MODE_AUDIO_ONLY:
        this.handleCallModeAudioOnly(imsCallModeInfo, updatedCall);
        break;
      case ImsCallMode.CALL_MODE_SEND_RECEIVE:
        if (isActiveCall(updatedCall.callState) &&
          imsCallModeInfo.result === VideoRequestResultType.TYPE_REQUEST_SUCCESS) {
          if (imsCallModeInfo.isRequestInfo) {
            if (this.callList.length > 1) {
              // Force reject the remote upgrade request if multi call!
              this.modifyImsCallMode(updatedCall, ImsCallMode.CALL_MODE_AUDIO_ONLY);

              // Force clear the imsCallMode because we've rejected the upgrade request
              newImsCallMode = ImsCallMode.CALL_MODE_AUDIO_ONLY;
            } else {
              this.needDisplayUpgradeVideo(true);
            }
          } else {
            ReportUtil.getInstance().reportCallInterfaceClickBtn('video', true);
          }
        }
        break;
      case ImsCallMode.CALL_MODE_RECEIVE_ONLY:
        if (isOutgoingCall(updatedCall.callState)) {
          this.warmUpCameraForRbt();
        } else if (isActiveCall(updatedCall.callState) && imsCallModeInfo.result ===
        VideoRequestResultType.TYPE_REQUEST_SUCCESS) {
          if (imsCallModeInfo.isRequestInfo) {
            // We should only interested in 'voice upgrade to one-way video' case.
            // The 'Video downgrade to one-way video' case will be handled automatically when videoState changed.
            if (isVoiceCall(updatedCall)) {
              // Auto accept on-way video upgrade request
              this.modifyImsCallMode(updatedCall, ImsCallMode.CALL_MODE_RECEIVE_ONLY);
            }
          }
        }
        break;
      default:
        break;
    }
    // Finally, save the new imsCallMode to callData
    updatedCall.imsCallMode = newImsCallMode;
  }

  private fallbackToEarpiece(): void {
    let isAutoOpenSpeaker: boolean | undefined = AppStorage.get('isAutoOpenSpeaker');
    if (!this.mBottomViewModel.isHaveMultiDevice && isAutoOpenSpeaker) {
      this.mBottomViewModel.setAudioDeviceSpeaker(DeviceTypeConst.DEVICE_EARPIECE);
    }
  }

  private needDisplayUpgradeVideo(showDialog: boolean): void {
    let isUiStarted = AppStorage.get('onPageShow') as number;
    LogUtils.i(TAG, `needDisplayUpgradeVideo isUiStarted :${isUiStarted}, showDialog: ${showDialog}`);
    if (showDialog && !isUiStarted) {
      CallManagerService.getInstance().startAbility();
    }
    AppStorage.setOrCreate('acceptVideoCallDialog', showDialog);
  }

  public onCallSessionEvent(data: call.CallSessionEvent) {
    LogUtils.i(TAG, `onCallSessionEvent: ${JSON.stringify(data)}`);
    if (data.callId === 0) {
      data.callId = this.currentOpenedCameraCallId;
    }
    let arr: call.CallSessionEvent[] = JSON.parse(JSON.stringify(this.callSessionEvent));
    let index = arr.findIndex((val) => val.callId === data.callId);
    index >= 0 ? (arr[index] = data) : arr.push(data);
    this.callSessionEvent = arr;
    if (data.eventId === call.CallSessionEventId.EVENT_CONTROL_CAMERA_READY) {
      let surfaceId: string | undefined = AppStorage.get('surfaceId');
      LogUtils.i(TAG, `onCallSessionEvent preview: ${surfaceId}`);
      if (surfaceId) {
        setPreviewWindowApi(data.callId, surfaceId);
      }
      let peerSurfaceId: string | undefined = AppStorage.get('peerSurfaceId');
      LogUtils.i(TAG, `onCallSessionEvent display: ${peerSurfaceId}`);
      if (peerSurfaceId) {
        setDisplayWindowApi(data.callId, peerSurfaceId);
      }
    }
  }

  public surfaceIdChange(surfaceId: string) {
    if (surfaceId) {
      let currentCall = this.callSessionEvent.find((item) => {
        return item.callId === this.currentOpenedCameraCallId;
      })
      LogUtils.i(TAG, 'surfaceIdChange_' + JSON.stringify(currentCall ? currentCall : []));
      if (currentCall?.eventId === call.CallSessionEventId.EVENT_CONTROL_CAMERA_READY) {
        setPreviewWindowApi(currentCall.callId, surfaceId);
        emitter.emit(OPEN_VIDEO_CAMERA);
      }
    }
  }

  public handlePeerDimensionsChange(value: PeerDimensionsDetail) {
    LogUtils.i(TAG, `peerDimensionsChange:${JSON.stringify(value)}`);
    this.peerScreenAspectRatio = (value.width / value.height) ? (value.width / value.height) : -1;
    AppStorage.setOrCreate('peerScreenAspectRatio', this.peerScreenAspectRatio);
  }

  public handleCurrentDimensionsChange(value: CameraCapabilities) {
    LogUtils.i(TAG, `cameraCapabilitiesChange value:${JSON.stringify(value)}`);
    if (!(value.width < 0 || value.height < 0)) {
      this.currentScreenAspectRatio = (value.width / value.height) ? (value.width / value.height) : -1;
      LogUtils.i(TAG, `currentScreenAspectRatio value is ${this.currentScreenAspectRatio}`);
      AppStorage.setOrCreate('currentScreenAspectRatio', this.currentScreenAspectRatio);
    }
  }

  public videoCallIncomingOpenCamera() {
    if (isIncomingCall(this.callData.callState) && isVideoCall(this.callData.videoState)) {
      if (!this.callSessionEvent.find(item => item.callId === this.callData.callId)) {
        VideoCameraHelper.getInstance().getCameraIds();
        const currentId: string = VideoCameraHelper.getInstance().getCurrentCameraId();
        LogUtils.i(TAG, 'videoCallIncomingOpenCamera:' + currentId);
        this.controlCamera(this.callData.callId, currentId);
        VideoCameraHelper.getInstance()
          .saveVideoCameraInfo(this.callData.callId, currentId, false);
      }
    }
  }

  public controlCamera(callId: number, cameraId: string) {
    if (cameraId) {
      this.currentOpenedCameraCallId = callId;
    } else {
      this.currentOpenedCameraCallId = -1;
    }
    controlCameraApi(callId, cameraId);
    if (!cameraId) {
      this.callSessionEvent = this.callSessionEvent.filter((item => item.callId !== callId));
    }

  }

  public videoCallStateUpdate(callData: DefaultCallData, callList: Array<DefaultCallData>) {
    LogUtils.i(TAG, 'videoCallStateUpdate callId is ' + callData.callId + ', callState is ' + callData.callState);
    this.callData = callData;
    this.callList = callList;

    // When an incoming call is received during an voice to video upgrade request, upgrade request will be cancelled.
    if (AppStorage.get('acceptVideoCallDialog') as boolean &&
      this.callList.length > 1 && isIncomingCall(this.callData.callState)) {
      const activeCall = this.callList.find(v => v.callState === CallStateConst.CALL_STATUS_ACTIVE);
      if (activeCall) {
        this.modifyImsCallMode(activeCall, ImsCallMode.CALL_MODE_AUDIO_ONLY);
        LogUtils.i(TAG, `video call invite show: false, length: ${this.callList.length}`);
        AppStorage.setOrCreate('acceptVideoCallDialog', false);
      }
    }
    this.videoCallIncomingOpenCamera();
    if (isVideoCall(this.callData.videoState)) {
      if (this.callData.callState === CallStateConst.CALL_STATUS_INCOMING) {
        AppStorage.setOrCreate('hidePeerVideoScreen', false);
      }
    }
    if (shouldShowRbtView(this.callData)) {
      this.warmUpCameraForRbt();
    }

    if (isVideoCall(this.callData.videoState)) {
      VideoCameraHelper.getInstance().updateCameraStatus(VideoCameraHelper.CAMERA_STATE_OPEN, true);
    } else if (isOneWayVideo(this.callData)) {
      VideoCameraHelper.getInstance().updateCameraStatus(VideoCameraHelper.CAMERA_STATE_CLOSED);
    } else if (isVoiceCall(this.callData)) {
      VideoCameraHelper.getInstance().updateCameraStatus(VideoCameraHelper.CAMERA_STATE_INVALID);
      VideoCameraHelper.getInstance().saveVideoCameraInfo(this.callData.callId, '', false);
    }
  }

  /**
   * Check whether need to hold video UX.
   *
   * @param oldCall old call data
   * @param newCall new call data
   */
  private checkHoldVideoUx(oldCall: DefaultCallData, newCall: DefaultCallData): void {
    if (isVideoCall(oldCall.videoState) && isHdVideoRbt(newCall.callState, newCall.videoState)) {
      newCall.isHoldVideoUx = true;
      return;
    }
    newCall.isHoldVideoUx = false;
  }

  /**
   * Compare old and new call data.
   *
   * @param oldCall old call data
   * @param newCall new call data
   */
  public compareOldAndNewCallData(oldCall: DefaultCallData, newCall: DefaultCallData): void {
    this.checkHoldVideoUx(oldCall, newCall);
    this.tryShowRemoteVoiceAnswerToast(oldCall, newCall);
    this.checkRbt(oldCall, newCall)
  }

  public tryShowRemoteVoiceAnswerToast(oldCall: DefaultCallData, newCall: DefaultCallData) {
    // Update was video call first
    if (isVideoCall(newCall.videoState) || isOneWayVideo(newCall)) {
      // If new call is a video call, was video should be false
      newCall.wasVideoCall = false;
    } else if (isVideoCall(oldCall.videoState) || isOneWayVideo(oldCall)) {
      // Then, if old call is a video call, was video should be true
      newCall.wasVideoCall = true;
    } else {
      // Otherwise, was video not changed
      newCall.wasVideoCall = oldCall.wasVideoCall;
    }

    if (!newCall.wasVideoCall) {
      // Skip for voice call or video call
      return;
    }

    if (oldCall.callState === newCall.callState) {
      // The voice answer toast should only prompted when call state changed
      return;
    }

    if (oldCall.callState === CallStateConst.CALL_STATUS_ALERTING &&
      newCall.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      Utils.getInstance().showToast($r('app.string.videoCallToVoiceToast'));
      this.fallbackToEarpiece();
      this.controlCamera(newCall.callId, '');
    } else if (oldCall.callState === CallStateConst.CALL_STATUS_DIALING &&
      (newCall.callState === CallStateConst.CALL_STATUS_ACTIVE ||
        newCall.callState === CallStateConst.CALL_STATUS_ALERTING) &&
      newCall.videoState !== VideoStateType.TYPE_VIDEO_RECEIVE_ONLY) {
      // For video establish failed case, we should clear the was video call state.
      newCall.wasVideoCall = false;
      Utils.getInstance().showToast($r('app.string.establishVideoCallFailed'));
      this.controlCamera(newCall.callId, '');
    } else if ((oldCall.callState === CallStateConst.CALL_STATUS_INCOMING ||
      oldCall.callState === CallStateConst.CALL_STATUS_ANSWER) &&
      newCall.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      this.controlCamera(newCall.callId, '');
    }
  }

  public checkRbt(oldCall: DefaultCallData, newCall: DefaultCallData) {
    if (oldCall.callState === CallStateConst.CALL_STATUS_ALERTING &&
      (newCall.callState === CallStateConst.CALL_STATUS_DISCONNECTED ||
        newCall.callState === CallStateConst.CALL_STATUS_ACTIVE ||
        newCall.callState === CallStateConst.CALL_STATUS_DISCONNECTING)) {
      AppStorage.setOrCreate('isRbtError', false);
    }
  }

  private warmUpCameraForRbt() {
    LogUtils.i(TAG, 'warmUpCameraForRbt start, this.currentOpenedCameraCallId = ' + this.currentOpenedCameraCallId)
    if (this.callData.callId !== this.currentOpenedCameraCallId) {
      try {
        VideoCameraHelper.getInstance().getCameraIds();
        this.controlCamera(this.callData.callId, VideoCameraHelper.getInstance().getCurrentCameraId());
        LogUtils.i(TAG, 'setRBTsAndRingtones: skip, camera opened');
      } catch (error) {
        let err = error as BusinessError;
        LogUtils.e(TAG, `The getSupportedCameras call failed. error code: ${err.code}`);
      }
    }
  }

  public modifyImsCallMode(call: DefaultCallData, newMode: ImsCallMode, callBack?: Callback<DefaultCallData>) {
    if (!this.mBottomViewModel.isHaveMultiDevice && newMode === ImsCallMode.CALL_MODE_SEND_RECEIVE
    ) {
      AppStorage.setOrCreate('isAutoOpenSpeaker',
        this.mBottomViewModel.currentAudioDevice.deviceType !== DeviceTypeConst.DEVICE_SPEAKER);
    }
    updateImsCallModeApi(call.callId, newMode, () => {
      if (callBack) {
        LogUtils.i(TAG, `updateImsCallModeApi callid: ${call?.callId}, newMode: ${newMode}`);
        callBack(call);
        let updatedCall = new DefaultCallData();
        Method.assign(updatedCall, call);
        CallManagerService.getInstance().publishData(updatedCall);
      }
    });
  }

  /**
   * close video mode
   */
  public closeVideoMode(targetObj?: DefaultCallData) {
    if (targetObj && targetObj.videoState === VideoStateType.TYPE_VIDEO_BIDIRECTIONAL) {
      this.controlCamera(targetObj.callId, '');
      setPreviewWindowApi(targetObj.callId, '');
      setDisplayWindowApi(targetObj.callId, '');
    }
  }

  constructor() {
  }
}