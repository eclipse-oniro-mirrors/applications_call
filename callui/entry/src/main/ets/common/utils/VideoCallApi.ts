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

import call from '@ohos.telephony.call';
import type { AsyncCallback } from '@ohos.base';
import LogUtils from './LogUtils';

const TAG = 'VideoCallApi';

export const CRS_TONE_NUM = 2;

/**
 * getNumberLocation
 *
 * @return {String} - numberLocation
 */

export function onPeerDimensionsChange(callback: (data: PeerDimensionsDetail) => void): void {
  try {
    // @ts-ignore
    call.on('peerDimensionsChange', (data) => {
      callback(data);
    });
  } catch (err) {
    LogUtils.e(TAG, ' onPeerDimensionsChange error: ' + err?.code);
  }
}

export function onImsCallModeChange(callback: (data: ImsCallModeInfo) => void): void {
  try {
    // @ts-ignore
    call.on('imsCallModeChange', (data) => {
      // @ts-ignore
      callback(data);
    });
  } catch (err) {
    LogUtils.e(TAG, 'onImsCallModeChange error: ' + err?.code);
  }
}

export function onCallSessionEvent(callback: (data: call.CallSessionEvent) => void): void {
  try {
    // @ts-ignore
    call.on('callSessionEvent', (data) => {
      // @ts-ignore
      callback(data);
    });
  } catch (err) {
    LogUtils.e(TAG, 'callSessionEvent error: ' + err?.code);
  }
}

export function offCallSessionEvent(): void {
  try {
    // @ts-ignore
    call.off('callSessionEvent', (data) => {
      LogUtils.i(TAG, 'callSessionEvent.');
    });
  } catch (err) {
    LogUtils.e(TAG, 'off callSessionEvent error: ' + err?.code);
  }
}

export function controlCameraApi(callId: number, cameraId: string): void {
  try {
    call.controlCamera(callId, cameraId);
    LogUtils.i(TAG, 'controlCamera cameraId: ' + cameraId + ', callId:' + callId);
  } catch (err) {
    LogUtils.e(TAG, 'controlCameraApi error: ' + err?.code);
  }
}

export function setPreviewWindowApi(callId: number, surfaceId: string): void {
  try {
    // @ts-ignore
    call.setPreviewSurface(callId, surfaceId);
    LogUtils.i(TAG, `setPreviewSurface: ${surfaceId} for callId: + ${callId}`);
  } catch (err) {
    LogUtils.e(TAG, 'setPreviewSurface error: ' + err?.message);
  }
}

export function setDisplayWindowApi(callId: number, surfaceId: string): void {
  try {
    // @ts-ignore
    call.setDisplaySurface(callId, surfaceId);
    LogUtils.i(TAG, `setDisplaySurface: ${surfaceId} for callId: + ${callId}`);
  } catch (err) {
    LogUtils.e(TAG, 'setDisplaySurface error: ' + err.code);
  }
}

export function updateImsCallModeApi(callId: number, mode: ImsCallMode, callback?: AsyncCallback<void>): void {
  try {
    callback = callback ? callback : (): void => {
    };
    // @ts-ignore
    call.updateImsCallMode(callId, mode, callback);
  } catch (err) {
    LogUtils.e(TAG, 'updateImsCallModeApi error:' + err?.code);
  }
}

export function offImsCallModeChange(): void {
  try {
    // @ts-ignore
    call.off('imsCallModeChange', (data) => {
      LogUtils.i(TAG, 'offImsCallModeChange.');
    });
  } catch (err) {
    LogUtils.e(TAG, 'off imsCallModeChange error: ' + err?.code);
  }
}

/**
 * Cancel voiceToVideo upgrade.
 * @param callId
 */
export function cancelCallUpgradeApi(callId: number): void {
  try {
    // @ts-ignore
    call.cancelCallUpgrade(callId);
  } catch (error) {
    LogUtils.e(TAG, 'cancelCallUpgradeApi error: ' + JSON.stringify(error));
  }
}

export function onCameraCapabilitiesChange(callback: (data: PeerDimensionsDetail) => void): void {
  try {
    // @ts-ignore
    call.on('cameraCapabilitiesChange', (value: call.CameraCapabilities) => {
      callback(value);
    });
  } catch (err) {
    LogUtils.e(TAG, 'onCameraCapabilitiesChange error: ' + err?.code);
  }
}

export function offPeerDimensionsChange(): void {
  try {
    // @ts-ignore
    call.off('peerDimensionsChange', () => {
    });
  } catch (err) {
    LogUtils.e(TAG, 'peerDimensionsChange error: ' + err?.code);
  }
}

export function offCameraCapabilitiesChange(): void {
  try {
    // @ts-ignore
    call.off('cameraCapabilitiesChange', () => {
    });
  } catch (err) {
    LogUtils.e(TAG, 'cameraCapabilitiesChange error: ' + err?.code);
  }
}

export function answerCallApi(videoState: VideoStateType, callId?: number): void {
  try {
    // @ts-ignore
    call.answerCall(videoState, callId);
  } catch (err) {
    LogUtils.e(TAG, 'answerCallApi error: ' + err?.code);
  }
}

export function setDeviceDirection(callId: number, deviceDirection: call.DeviceDirection): void {
  try {
    // @ts-ignore
    call.setDeviceDirection(callId, deviceDirection)
      .then(() => {
        LogUtils.i(TAG, `setDeviceDirection success callId:${callId},deviceDirection:${deviceDirection}`);
      })
      .catch((err) => {
        LogUtils.e(TAG, 'setDeviceDirection err: ' + JSON.stringify(err.code));
      });
  } catch (err) {
    LogUtils.e(TAG, 'setDeviceDirection error: ' + err?.code);
  }
}

export interface CameraCapabilities {
  /**
   * Indicates the id of call.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  callId: number;

  /**
   * Indicates the camera width.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  width: number;

  /**
   * Indicates the the camera height.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  height: number;
}

export enum ImsCallMode {
  /**
   * Indicates audio only calls.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 8
   */
  CALL_MODE_AUDIO_ONLY = 0,

  /**
   * Indicates that only calls are sent.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 8
   */
  CALL_MODE_SEND_ONLY,

  /**
   * Indicates receiving only calls.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 8
   */
  CALL_MODE_RECEIVE_ONLY,

  /**
   * Indicates permission to send and receive calls.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 8
   */
  CALL_MODE_SEND_RECEIVE,

  /**
   * Indicates a pause in video calls.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 8
   */
  CALL_MODE_VIDEO_PAUSED,
}

export enum VideoStateType {
  /**
   * Indicates the call is in voice state.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 7
   */
  TYPE_VOICE = 0,
  /**
   * Indicates the call is in video state.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 7
   * @deprecated since 11
   * @useinstead telephony.call#TYPE_VIDEO_BIDIRECTIONAL
   */
  TYPE_VIDEO,
  /**
   * Indicates the call is in send only video state.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_VIDEO_SEND_ONLY = 1,
  /**
   * Indicates the call is in receive only video state.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_VIDEO_RECEIVE_ONLY,
  /**
   * Indicates the call is in send and receive video state.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_VIDEO_BIDIRECTIONAL,
}

export interface PeerDimensionsDetail {
  /**
   * Indicates the id of call.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  callId: number;

  /**
   * Indicates the peer dimensions width.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  width: number;

  /**
   * Indicates the the peer dimensions height.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  height: number;
}

export interface ImsCallModeInfo {
  /**
   * Indicates the id of call.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  callId: number;

  /**
   * Indicates the request result.
   *
   * @type { VideoRequestResultType }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  result: VideoRequestResultType;

  /**
   * Indicates if this is a request which received from remote,
   *
   * @type { boolean }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  isRequestInfo: boolean;

  /**
   * Indicates the ImsCallMode of call.
   *
   * @type { ImsCallMode }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  imsCallMode: ImsCallMode;
}

export enum VideoRequestResultType {
  /**
   * Indicates the request was successful.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_REQUEST_SUCCESS = 0,
  /**
   * Indicates the request failed.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_REQUEST_FAILURE,
  /**
   * Indicates the request ignored due to invalid parameters.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_REQUEST_INVALID,
  /**
   * Indicates the request timed out.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_REQUEST_TIMED_OUT,
  /**
   * Indicates the request rejected by remote.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_REQUEST_REJECTED_BY_REMOTE,
  /**
   * Indicates the upgrade request canceled.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_REQUEST_UPGRADE_CANCELED,
  /**
   * Indicates the ImsCall Mode downgrade RTP time out.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_DOWNGRADE_RTP_OR_RTCP_TIMEOUT = 100,
  /**
   * Indicates the ImsCall Mode downgrade RTP and RTCP time out.
   *
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  TYPE_DOWNGRADE_RTP_AND_RTCP_TIMEOUT,
}

export interface PeerDimensionsDetail {
  /**
   * Indicates the id of call.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  callId: number;

  /**
   * Indicates the peer dimensions width.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  width: number;

  /**
   * Indicates the the peer dimensions height.
   *
   * @type { number }
   * @syscap SystemCapability.Telephony.CallManager
   * @systemapi Hide this for inner system use.
   * @since 11
   */
  height: number;
}