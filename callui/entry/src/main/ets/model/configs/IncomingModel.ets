/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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
 * @file: Button group configuration file
 */

import ImagePathConst from '../../common/constant/ImagePathConst';

const SMS_REJECTION = `sys.symbol.message_fill`;
const CUSTOM_MSG_ID: number = 4;
const REMIND_REJECTION = `sys.symbol.alarm_fill_1`;
const VOICE_CALL = `sys.symbol.phone_fill`;
let REMIND_HOUR_1: number = 1;
let REMIND_HOUR_2: number = 2;
let REMIND_MINUTES_30: number = 30;

export interface btn {
  type: string
  iconText: Resource
  iconDefaultUrl: string
  iconDisableUrl: string
  iconTouchUrl?: string
  isDisable: boolean
}

interface remindListType {
  id: number
  msg: Resource
  value: number
}

let msgBtn: btn = {
  type: 'msg',
  iconText: $r('app.string.sms'),
  iconDefaultUrl: SMS_REJECTION,
  iconTouchUrl: SMS_REJECTION,
  iconDisableUrl: SMS_REJECTION,
  isDisable: false
}

let remindBtn: btn = {
  type: 'remind',
  iconText: $r('app.string.remind'),
  iconDefaultUrl: REMIND_REJECTION,
  iconTouchUrl: REMIND_REJECTION,
  iconDisableUrl: REMIND_REJECTION,
  isDisable: false
}
let voiceCallAnswerBtn: btn = {
  type: 'voiceCall',
  iconText: $r('app.string.voiceCall'),
  iconDefaultUrl: VOICE_CALL,
  iconTouchUrl: VOICE_CALL,
  iconDisableUrl: VOICE_CALL,
  isDisable: false
}

let callAssistantInComingBtn: btn = {
    type: 'callAssistant',
    iconText: $r('app.string.call_assistant_setting_title'),
    iconDefaultUrl: 'sys.symbol.AI_phone_fill',
    iconDisableUrl: 'sys.symbol.AI_phone_fill',
    iconTouchUrl: 'sys.symbol.AI_phone_fill',
    isDisable: false,
}

let minutes: remindListType = {
  id: 1,
  msg: $r('app.plural.minutes', REMIND_MINUTES_30, REMIND_MINUTES_30),
  value: 30
}

let oneHour: remindListType = {
  id: 2,
  msg: $r('app.plural.hoursLater', REMIND_HOUR_1, REMIND_HOUR_1),
  value: 60
}

let twoHour: remindListType = {
  id: 3,
  msg: $r('app.plural.hoursLater', REMIND_HOUR_2, REMIND_HOUR_2),
  value: 120
}

export const inComingBtnList = [
  msgBtn,
  remindBtn
];

export const inComingVideoBtnList = [
  msgBtn,
  voiceCallAnswerBtn,
  remindBtn
];

export const videoPreviewBtnList = [
  msgBtn,
  callAssistantInComingBtn,
  remindBtn
]

export const remindList = [
  minutes,
  oneHour,
  twoHour
];

export function getInComingBtnListByVideoState(isVideo: boolean, isInvalidNumber = false): btn[] {
  if (isInvalidNumber) {
    if (isVideo) {
      return [voiceCallAnswerBtn];
    } else {
      return [];
    }
  }
  return isVideo ? inComingVideoBtnList : inComingBtnList;
}