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

import window from '@ohos.window';
import CallStateConst from '../constant/CallStateConst';
import ConferenceConst from '../constant/ConferenceConst';
import DefaultCallData from '../struct/TypeUtils';
import { GlobalContextHelper } from './GlobalContextHelper';
import Method from './Method';
import { CRS_TONE_NUM, ImsCallMode, VideoStateType } from './VideoCallApi';
import * as Constants from '../../common/utils/Constants';
import { BusinessError } from '@ohos.base';
import LogUtils from './LogUtils';
import Utils from './utils';
import { systemSoundManager } from '@kit.AudioKit';
import { SystemMode } from './SystemMode';

const TAG = 'CallListHelper';

type WindowSystemBarNames = 'status' | 'navigation';

/**
 * Find the primary incoming call.
 * If we have 2 incoming call, the call with a larger call id will be the primary call.
 * @param callList
 * @returns the primary call or undefined if no incoming call exists.
 * @see getSecondaryIncomingCall
 * @see isIncomingCall
 */
export function getPrimaryIncomingCall(callList: Array<DefaultCallData>): DefaultCallData | undefined {
  let result: DefaultCallData | undefined = undefined;
  for (let call of callList) {
    if (isIncomingCall(call.callState)) {
      if (result && result.callId > call.callId) {
        continue;
      }
      result = call;
    }
  }
  return result;
}

/**
 * Find the secondary incoming call.
 * @param callList
 * @returns the secondary incoming call or undefined if no incoming call or not 2 incoming call case.
 * @see getPrimaryIncomingCall
 * @see isIncomingCall
 */
export function getSecondaryIncomingCall(callList: Array<DefaultCallData>): DefaultCallData | undefined {
  if (callList.length <= 1) {
    return undefined;
  }

  let primaryIncomingCall = getPrimaryIncomingCall(callList);
  if (!primaryIncomingCall) {
    // No incoming
    return undefined;
  }

  for (let call of callList) {
    if (call.callId !== primaryIncomingCall.callId && isIncomingCall(call.callState)) {
      return call;
    }
  }
  return undefined;
}

/**
 * Find the outgoing call
 * @param callList
 * @returns the outgoing call or undefined if not found
 */
export function getOutgoingCall(callList: Array<DefaultCallData>): DefaultCallData | undefined {
  for (let call of callList) {
    if (isOutgoingCall(call.callState)) {
      return call;
    }
  }
  return undefined;
}

/**
 * This is a modem limitation:
 *
 * For call waiting situation, hold the active call and answer the incoming call will use a same command.
 * Also, we could only contains one active call, so the only choice is drop the active call.
 *
 * This conflicts should notify to user.
 *
 * @param callList the call list
 * @param primaryIncoming optional, indicate the call will be answered.
 *        If not set, the primary incoming call will be used.
 * @returns true if under secondary call waiting case, false otherwise.
 */
export function isSecondaryCallWaiting(callList: Array<DefaultCallData>, primaryIncoming?: DefaultCallData): boolean {
  if (callList.length < 3) {
    // This limitation will only occurred when at least 3 calls existing
    return false;
  }

  primaryIncoming = primaryIncoming ? primaryIncoming : getPrimaryIncomingCall(callList);
  if (!primaryIncoming) {
    return false;
  }

  // Get call list for only other SIM
  let secondaryCallList = getSubCallListForAccount(callList, getOtherAccountId(primaryIncoming.accountId));
  if (secondaryCallList.length < 2) {
    return false;
  }

  let hasActiveCall = false;
  let hasIncomingCall = false;
  for (let call of secondaryCallList) {
    if (!hasActiveCall && call.callState === CallStateConst.callStateObj.CALL_STATUS_ACTIVE) {
      hasActiveCall = true;
    }
    if (!hasIncomingCall && call.callState === CallStateConst.callStateObj.CALL_STATUS_WAITING) {
      // The INCOMING state is for single call situation, so we should only check the WAITING status here.
      hasIncomingCall = true;
    }

    if (hasActiveCall && hasIncomingCall) {
      // Hint!
      return true;
    }
  }

  // Normal
  return false;
}

/**
 * Check if we can do merge operation. Used by check if the "Merge" button should be shown in CallUI.
 * @param callList
 * @returns true if we can do merge, false otherwise
 */
export function canMerge(callList: Array<DefaultCallData>): boolean {
  if (getActualCallCount(callList) <= 1) {
    // No call or only one call
    return false;
  }

  if (hasIncomingCall(callList)) {
    // Cannot merge: has incoming call!
    return false;
  }

  if (getOutgoingCall(callList)) {
    // Cannot merge: multi call and dialing case
    return false;
  }

  if (!getFirstCallByState(callList, CallStateConst.callStateObj.CALL_STATUS_HOLDING)) {
    // Cannot merge: no holding call! (all of the calls are conference participant)
    return false;
  }

  if (isSameAccountId(callList)) {
    return false;
  }

  // Finally, we can show the merge button!
  return true;
}

export function isSameAccountId(callList: Array<DefaultCallData>): boolean {
  let firstCall = callList[0];
  for (let call of callList) {
    if (call.accountId !== firstCall.accountId) {
      // Cannot merge: DSDA!
      return true;
    }
  }
  return false;
}

/**
 * Check if the call is an incoming call
 *
 * * For multi call case, the ANSWER state should be considered as incoming state
 * * For video call case, the ANSWER state should be considered as active state
 *
 * @param call the call
 * @param includeAnswerState if true, the ANSWER state will be considered as incoming state
 * @returns true if the call is an incoming call, false otherwise
 * @see isActiveCall
 */
export function isIncomingCall(callState: number, includeAnswerState: boolean = false): boolean {
  if (!callState) {
    return false;
  }
  return callState === CallStateConst.callStateObj.CALL_STATUS_INCOMING ||
    callState === CallStateConst.callStateObj.CALL_STATUS_WAITING ||
    (includeAnswerState && callState === CallStateConst.CALL_STATUS_ANSWER);
}

export function isIncomingVoiceSilencedCall(call: DefaultCallData, includeAnswerState: boolean = false): boolean {
  return isIncomingCall(call.callState, includeAnswerState) && !isVideoCall(call.videoState) && isSilencedCall(call);
}

export function isSilencedCall(call: DefaultCallData): boolean {
  return (call.isRingSilenced ?? false);
}

export function isDisconnectCall(call: DefaultCallData): boolean {
  return (call.callState === CallStateConst.callStateObj.CALL_STATUS_DISCONNECTING ||
    call.callState === CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED);
}

export function isOutgoingCall(callState: number): boolean {
  return callState === CallStateConst.callStateObj.CALL_STATUS_DIALING ||
    callState === CallStateConst.callStateObj.CALL_STATUS_ALERTING;
}

export function isActiveCall(callState: number): boolean {
  return callState === CallStateConst.CALL_STATUS_ANSWER ||
    callState === CallStateConst.CALL_STATUS_ACTIVE ||
    callState === CallStateConst.CALL_STATUS_HOLDING;
}

/**
 * @param callList
 * @returns actual call count, all of the participants in conference will be considered as same call
 */
export function getActualCallCount(callList: Array<DefaultCallData>): number {
  if (callList.length <= 1) {
    return callList.length;
  }

  let result = 0;
  let hasConference = false;
  for (let call of callList) {
    if (call.conferenceState !== ConferenceConst.TEL_CONFERENCE_IDLE) {
      hasConference = true;
      continue;
    }
    result++;
  }

  if (hasConference) {
    result++;
  }
  return result;
}

export function getWasConnectedCallCount(callList: Array<DefaultCallData>): number {
  let result = 0;
  let hasConference = false;
  for (let call of callList) {
    if (call.callState === CallStateConst.callStateObj.CALL_STATUS_DIALING ||
      call.callState === CallStateConst.callStateObj.CALL_STATUS_ALERTING ||
      call.callState === CallStateConst.callStateObj.CALL_STATUS_INCOMING ||
      call.callState === CallStateConst.callStateObj.CALL_STATUS_WAITING) {
      // Skip if not connected yet
      continue;
    }

    if (call.conferenceState !== ConferenceConst.TEL_CONFERENCE_IDLE) {
      hasConference = true;
      continue;
    }
    result++;
  }

  if (hasConference) {
    result++;
  }
  return result;
}

/**
 * Find the foreground call: INCOMING > OUTGOING > ACTIVE > HOLD > DISCONNECT
 * @param callList
 * @returns the foreground call or undefined if no call exists
 */
export function getForegroundCall(callList: Array<DefaultCallData>): DefaultCallData | undefined {
  // No call!
  if (callList.length === 0) {
    return undefined;
  }

  // If only one call, use it and skip all checks.
  if (callList.length === 1) {
    return callList[0];
  }

  let call: DefaultCallData | undefined = undefined;

  // 1. Incoming call
  call = getPrimaryIncomingCall(callList);
  if (call) {
    return call;
  }

  // 2. Outgoing call
  call = getOutgoingCall(callList);
  if (call) {
    return call;
  }

  // 3. Active call
  call = getFirstCallByState(callList, CallStateConst.callStateObj.CALL_STATUS_ACTIVE);
  if (call) {
    return call;
  }

  // 4 Holding call
  call = getFirstCallByState(callList, CallStateConst.callStateObj.CALL_STATUS_HOLDING);
  if (call) {
    return call;
  }

  // 5. Disconnect call
  call = getDisconnectCall(callList);
  if (call) {
    LogUtils.w(TAG, 'Using disconnected call as foreground call! callList.length = ' + callList.length);
    return call;
  }

  // 6. No call (should not reach here)
  LogUtils.e(TAG, 'Cannot find foreground call! callList.length = ' + callList.length);
  return undefined;
}

/**
 * Find the foreground live call: ACTIVE > OUTGOING
 * @param callList
 * @returns the foreground live call or undefined if no call exists
 */
export function getForegroundLiveCall(callList: Array<DefaultCallData>): DefaultCallData | undefined {
  // No call!
  if (callList.length === 0) {
    return undefined;
  }

  let call: DefaultCallData | undefined = undefined;

  // 1. Active call
  call = getFirstCallByState(callList, CallStateConst.callStateObj.CALL_STATUS_ACTIVE);
  if (call) {
    return call;
  }

  // 2. Outgoing call
  call = getOutgoingCall(callList);
  if (call) {
    return call;
  }

  return undefined;
}

function hasIncomingCall(callList: Array<DefaultCallData>): boolean {
  for (let call of callList) {
    if (isIncomingCall(call.callState)) {
      return true;
    }
  }
  return false;
}

function getDisconnectCall(callList: Array<DefaultCallData>): DefaultCallData | undefined {
  for (let call of callList) {
    if (call.callState === CallStateConst.callStateObj.CALL_STATUS_DISCONNECTING ||
      call.callState === CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED) {
      return call
    }
  }
  return undefined;
}

export function setConferenceDisconnecting(callList: Array<DefaultCallData>): void {
  LogUtils.i(TAG, 'setConferenceDisconnecting.');
  for (let call of callList) {
    if (Utils.getInstance().isConferenceCall(call)) {
      call.callState = CallStateConst.callStateObj.CALL_STATUS_DISCONNECTING;
    }
  }
}

export function getFirstCallByState(callList: Array<DefaultCallData>, callState: number): DefaultCallData | undefined {
  for (let call of callList) {
    if (call.callState === callState) {
      return call;
    }
  }
  return undefined;
}

export function getFirstCallByStateExcludeCall(callList: Array<DefaultCallData>, callState: number,
  excludeCall: DefaultCallData): DefaultCallData | undefined {
  for (let call of callList) {
    if (call.callState === callState && call.accountId !== excludeCall.accountId &&
      call.callId !== excludeCall.callId) {
      return call;
    }
  }
  return undefined;
}

/**
 * For only DUAL SIM device
 * @returns the other sim account id
 */
export function getOtherAccountId(accountId: number): number {
  return (accountId + 1) % 2;
}

function getSubCallListForAccount(callList: Array<DefaultCallData>, account: number): Array<DefaultCallData> {
  let result: DefaultCallData[] = [];
  for (let call of callList) {
    if (call.accountId === account) {
      let obj = new DefaultCallData();
      Method.assign(obj, call) // MUST use deep copy!
      result.push(obj);
    }
  }
  return result;
}

export function getVideoCall(callList: Array<DefaultCallData>): DefaultCallData | undefined {
  for (let call of callList) {
    if (call.videoState === CallStateConst.VIDEO_STATE_VIDEO) {
      return call;
    }
  }
  return undefined;
}

/**
 * is call a video call.
 * @param callData
 * @returns
 */
export function isVideoCall(videoState: number): boolean {
  if (SystemMode.getInstance().isModePenglai()) {
    // If it is the Penglai mode, return false directly.
    return false;
  } else if (videoState === VideoStateType.TYPE_VIDEO_BIDIRECTIONAL) {
    // If the video status is a two-way communication type, return true
    return true;
  } else {
    // Return false in other cases
    return false;
  }
}

/**
 * Is a hd video rbt.
 *
 * @param callData
 * @returns whether the call has hd video rbt
 */
export function isHdVideoRbt(callState: number, videoState: number): boolean {
  return isOutgoingCall(callState) && videoState === VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
}

export function isOneWayVideo(callData: DefaultCallData): boolean {
  return callData.callState === CallStateConst.CALL_STATUS_ACTIVE &&
    (callData.videoState === VideoStateType.TYPE_VIDEO_RECEIVE_ONLY ||
      callData.videoState === VideoStateType.TYPE_VIDEO_SEND_ONLY);
}

export function isVoiceCall(callData: DefaultCallData): boolean {
  return callData.videoState === VideoStateType.TYPE_VOICE;
}

export function setWindowLayoutFullScreenApi(isLayoutFullScreen: boolean) {
  try {
    let promise = GlobalContextHelper.getContext().getValue<window.Window>(Constants.WINDOW)?.
    setWindowLayoutFullScreen(isLayoutFullScreen)
    promise.then(() => {
      LogUtils.i(TAG, 'Succeeded in setting the window layout to full-screen mode.');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
    });
  } catch (error) {
    LogUtils.e(TAG, 'Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(error));
  }
}

export function setSystemBarEnable(isSystemBarEnable: boolean) {
  let names: WindowSystemBarNames[] = [];
  if (isSystemBarEnable) {
    names = ['status', 'navigation'];
  } else {
    names = [];
  }
  try {
    let promise =
      GlobalContextHelper.getContext().getValue<window.Window>(Constants.WINDOW)?.setWindowSystemBarEnable(names);
    promise.then(() => {
      LogUtils.i(TAG, 'setWindowSystemBarEnable success.');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `setWindowSystemBarEnable failed. err code: ${err.code}, err message: ${err.message}`);
    });
  } catch (exception) {
    LogUtils.e(TAG, `setWindowSystemBarEnable failed. err code: ${exception.code}, err message: ${exception.message}`);
  }
}

export function getActiveCallId(callList: Array<DefaultCallData>): number {
  for (let call of callList) {
    if (call.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      return call.callId;
    }
  }
  return -1;
}

export function hasAliveCallForSlotId(slotId: number, callList: Array<DefaultCallData>): boolean {
  let callData = callList.find((call: DefaultCallData) => call.callState !==
  CallStateConst.CALL_STATUS_DISCONNECTED && call.callState !== CallStateConst.CALL_STATUS_DISCONNECTING &&
    call.accountId === slotId);
  return callData !== undefined;
}

export function shouldShowRbtView(callData: DefaultCallData): boolean {
  if (isIncomingCall(callData.callState) && callData.crsType === CRS_TONE_NUM) {
    // Voice & Video RBT
    return true;
  }

  if (isOutgoingCall(callData.callState) && callData.imsCallMode === ImsCallMode.CALL_MODE_RECEIVE_ONLY) {
    // Voice ColorRing only. Video ColorRing will display in VideoXComponent
    return true;
  }

  return false;
}

export function canShowVideoCallUi(callState: number, videoState: number, isHoldVideoUx?: boolean): boolean {
  if (isIncomingCall(callState, true)) {
    // For incoming call, we should display answer button for all calls
    return false;
  }

  if (videoState === VideoStateType.TYPE_VIDEO_BIDIRECTIONAL) {
    return true;
  }

  if (videoState === VideoStateType.TYPE_VIDEO_RECEIVE_ONLY &&
    callState === CallStateConst.CALL_STATUS_ACTIVE) {
    return true;
  }

  if (isHoldVideoUx) {
    LogUtils.i(TAG, 'the call has HD video rbt');
    return true;
  }

  return false;
}

export function isUpgradingToVideo(callData: DefaultCallData): boolean {
  if (callData.callState !== CallStateConst.CALL_STATUS_ACTIVE) {
    return false;
  }

  // For local upgrading call, when IMS api invoked, we'll set the videoState to TYPE_VIDEO_BIDIRECTIONAL and set set
  // the imsCallMode to CALL_MODE_AUDIO_ONLY manually.
  return isVideoCall(callData.videoState) && callData.imsCallMode === ImsCallMode.CALL_MODE_AUDIO_ONLY;
}

export function isAliveCall(callData: DefaultCallData) {
  if (callData.callState !== CallStateConst.CALL_STATUS_DISCONNECTING &&
    callData.callState !== CallStateConst.CALL_STATUS_DISCONNECTED) {
    return true;
  }
  return false;
}

export function getCallById(callList: Array<DefaultCallData>, callId: number) {
  return callList.find((callData: DefaultCallData) => callData.callId === callId);
}

export function shouldShowVideoRing(callData: DefaultCallData): boolean {
  LogUtils.i(TAG, 'shouldShowVideoRing is called, callState = ' + callData.callState);
  if (isIncomingCall(callData.callState) && callData.extraParams?.['VideoRingPath'] &&
    callData.extraParams?.['VideoRingPath'] !== '') {
    return !shouldShowRbtView(callData);
  }
  return false;
}

export async function getVideoRingPath(callData: DefaultCallData): Promise<number> {
  LogUtils.i(TAG, 'getVideoRingPath is called');
  let ringPath: string = '';
  let fileFd = -1;
  let sysSoundManager: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
  try {
    if (callData.extraParams?.['VideoRingPath'] === 'system_video_ring') {
      LogUtils.i(TAG, 'getVideoRingPath simCard = ' + (callData.accountId === 0 ?
      systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_0 :
      systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_1))
      let result: systemSoundManager.ToneAttrs =
        await sysSoundManager.getCurrentRingtoneAttribute(callData.accountId === 0 ?
        systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_0 :
        systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_1);
      ringPath = result.getUri();
    } else {
      ringPath = callData.extraParams?.['VideoRingPath'] as string;
    }
    let resultArray = await sysSoundManager.openToneList([ringPath]);
    if (resultArray?.length > 0 && resultArray[0]?.length > 1) {
      fileFd = resultArray[0][1];
    }
  } catch (error) {
    LogUtils.e(TAG, 'getVideoRingPath, getCurrentRingtoneAttribute or openToneList error, ' + JSON.stringify(error));
  }
  return fileFd;
}
