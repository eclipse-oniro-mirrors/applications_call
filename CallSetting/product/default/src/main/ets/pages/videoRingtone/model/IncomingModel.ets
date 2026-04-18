/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

const SMS_REJECTION = `sys.symbol.message_fill`;
const REMIND_REJECTION = `sys.symbol.alarm_fill_1`;

export interface ScreenInfo {
  width: number,
  height:number
}

export interface btn {
  type: string
  iconText: Resource
  iconDefaultUrl: string
  iconDisableUrl: string
  iconTouchUrl?: string
  isDisable: boolean
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

let callAssistantInComingBtn: btn = {
    type: 'callAssistant',
    iconText: $r('app.string.call_assistant_setting_title'),
    iconDefaultUrl: 'sys.symbol.AI_phone_fill',
    iconDisableUrl: 'sys.symbol.AI_phone_fill',
    iconTouchUrl: 'sys.symbol.AI_phone_fill',
    isDisable: false,
}

export const videoPreviewBtnList = [
  msgBtn,
  // callAssistantInComingBtn,
  remindBtn
]