/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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
 * @file: Call status
 */

// calling
export const CALL_STATUS_ACTIVE = 0;

// State keeping
export const CALL_STATUS_HOLDING = 1;

// Dialing
export const CALL_STATUS_DIALING = 2;

// The other party is ringing
export const CALL_STATUS_ALERTING = 3;

// Call from the other party
export const CALL_STATUS_INCOMING = 4;

// Waiting for third-party calls
export const CALL_STATUS_WAITING = 5;

// Hung up
export const CALL_STATUS_DISCONNECTED = 6;

// Hanging up
export const CALL_STATUS_DISCONNECTING = 7;

// Idle state
export const CALL_STATUS_IDLE = 8;

const callStateObj = {
    CALL_STATUS_ACTIVE,
    CALL_STATUS_HOLDING,
    CALL_STATUS_DIALING,
    CALL_STATUS_ALERTING,
    CALL_STATUS_INCOMING,
    CALL_STATUS_WAITING,
    CALL_STATUS_DISCONNECTED,
    CALL_STATUS_DISCONNECTING,
    CALL_STATUS_IDLE
};

export const callStateTextMap = {
    [CALL_STATUS_ACTIVE]: '',
    [CALL_STATUS_HOLDING]: 'callHold',
    [CALL_STATUS_DIALING]: 'dialing',
    [CALL_STATUS_ALERTING]: 'partyIsRinging',
    [CALL_STATUS_INCOMING]: '',
    [CALL_STATUS_WAITING]: 'thirdPartyCalls',
    [CALL_STATUS_DISCONNECTED]: 'hangUpCompleted',
    [CALL_STATUS_DISCONNECTING]: 'hangingUp',
    [CALL_STATUS_IDLE]: 'callIdle'
};

const callStateTxtList = ['calling', 'callHold', 'dialing', 'partyIsRinging', '', 'thirdPartyCalls', 'hangUpCompleted',
                          'hangingUp', 'callIdle'];

export const defaultCallData = {
    callId: 0,
    callState: CALL_STATUS_IDLE,
    accountNumber: '',
    videoState: 0,
    callType: 0,
    conferenceState: 0
};

export const getCallStateText = (state) => callStateTxtList[state] !== undefined ? callStateTxtList[state] : '';

export default callStateObj;
