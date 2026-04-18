/**
 * Copyright (c) 2022-2025 Huawei Device Co., Ltd.
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

export default class CallStateConst {
  // calling
  public static CALL_STATUS_ACTIVE: number = 0;
  // State keeping
  public static CALL_STATUS_HOLDING: number = 1;
  // Dialing
  public static CALL_STATUS_DIALING: number = 2;
  // The other party is ringing
  public static CALL_STATUS_ALERTING: number = 3;
  // Call from the other party
  public static CALL_STATUS_INCOMING: number = 4;
  // Waiting for third-party calls
  public static CALL_STATUS_WAITING: number = 5;
  // Hung up
  public static CALL_STATUS_DISCONNECTED: number = 6;
  // Hanging up
  public static CALL_STATUS_DISCONNECTING: number = 7;
  // Idle state
  public static CALL_STATUS_IDLE: number = 8;
  // answer state
  public static CALL_STATUS_ANSWER: number = 9;
  // cs call type
  public static TYPE_CS: number = 0;
  // PS Call
  public static TYPE_IMS: number = 1;
  // voip call type,  call.CallType.Type_VOIP
  public static TYPE_VOIP: number = 4;
  // satellite call type,  call.CallType.Type_SATELLITE
  public static TYPE_SATELLITE: number = 5;

  public static AWAY_FROM_PROXIMITY: number = 5;

  public static CALL_DIRECTION_OUTGOING = 1;
  public static CALL_DIRECTION_INCOMING = 2;
  public static TEXT_INCOMING_CALL_ANSWER = 'answer';
  public static TEXT_INCOMING_CALL_ANSWER_VIDEO = 'answerVideo';
  public static TEXT_INCOMING_CALL_REJECT = 'reject';
  public static TEXT_IN_CALL_HANG_UP = 'hangup';
  public static TEXT_IN_CALL_MUTE = 'mute';
  public static TEXT_IN_CALL_UN_MUTE = 'un-mute';
  public static TEXT_IN_CALL_DISABLED_MUTE = 'mute-disable';
  public static TEXT_IN_CALL_UN_HOLD_ON = 'un-hold-on';
  public static TEXT_IN_CALL_AUDIO_EAR = 'ear';
  public static TEXT_IN_CALL_AUDIO_BT = 'bluetooth';
  public static TEXT_IN_CALL_AUDIO_RECEIVER = 'receiver';
  public static TEXT_IN_CALL_AUDIO_SPEAKER = 'speaker';
  public static TEXT_IN_CALL_AUDIO_SPEAKER_ON = 'speaker-on';
  public static TEXT_IN_CALL_AUDIO_MUTE_OFF_DISABLED = 'mute-off-disabled';
  public static VIDEO_STATE_VOICE = 0;
  public static VIDEO_STATE_VIDEO_VT = 1;
  public static VIDEO_STATE_VIDEO_VX = 2;
  public static VIDEO_STATE_VIDEO = 3;
  public static callStateObj: Record<string, number> = {
    'CALL_STATUS_ACTIVE': CallStateConst.CALL_STATUS_ACTIVE,
    'CALL_STATUS_HOLDING': CallStateConst.CALL_STATUS_HOLDING,
    'CALL_STATUS_DIALING': CallStateConst.CALL_STATUS_DIALING,
    'CALL_STATUS_ALERTING': CallStateConst.CALL_STATUS_ALERTING,
    'CALL_STATUS_INCOMING': CallStateConst.CALL_STATUS_INCOMING,
    'CALL_STATUS_WAITING': CallStateConst.CALL_STATUS_WAITING,
    'CALL_STATUS_DISCONNECTED': CallStateConst.CALL_STATUS_DISCONNECTED,
    'CALL_STATUS_DISCONNECTING': CallStateConst.CALL_STATUS_DISCONNECTING,
    'CALL_STATUS_IDLE': CallStateConst.CALL_STATUS_IDLE,
    'CALL_STATUS_ANSWER': CallStateConst.CALL_STATUS_ANSWER
  };
  public static callStateTextArray = [
    '',
    $r('app.string.callHold'),
    $r('app.string.dialing'),
    $r('app.string.partyIsRinging'),
    '',
    '',
    $r('app.string.hangUpCompleted'),
    $r('app.string.hangingUp'),
    ''
  ]
}