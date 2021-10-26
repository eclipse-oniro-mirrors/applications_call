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
 * @file: Conference call status
 */

// Free conference call
export const TEL_CONFERENCE_IDLE = 0;

// Conference call activation
export const TEL_CONFERENCE_ACTIVE = 1;

// The conference call is disconnecting
export const TEL_CONFERENCE_DISCONNECTING = 2;

// Conference call disconnected
export const TEL_CONFERENCE_DISCONNECTED = 3;

export const conferenceStateObj = {
    TEL_CONFERENCE_IDLE,
    TEL_CONFERENCE_ACTIVE,
    TEL_CONFERENCE_DISCONNECTING,
    TEL_CONFERENCE_DISCONNECTED
};