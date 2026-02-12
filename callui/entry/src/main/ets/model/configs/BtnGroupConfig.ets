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

let record: Record<string, string | boolean | Resource> = {
  'type': 'record',
  'iconDisableUrl': 'sys.symbol.waveform_1',
  'iconDefaultUrl': 'sys.symbol.waveform_1',
  'iconActiveUrl': 'sys.symbol.waveform_1',
  'iconTouchUrl': 'sys.symbol.waveform_1',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#0A59F7',
  'iconTouchFontColor': '#0A59F7',
  'isDisable': true,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let keep: Record<string, string | boolean | Resource> = {
  'type': 'keep',
  'iconDisableUrl': 'sys.symbol.pause',
  'iconDefaultUrl': 'sys.symbol.pause',
  'iconActiveUrl': 'sys.symbol.pause',
  'iconTouchUrl': 'sys.symbol.pause',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#E84026',
  'iconTouchFontColor': '#E84026',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let add: Record<string, string | boolean | Resource> = {
  'type': 'add',
  'iconDisableUrl': 'sys.symbol.plus',
  'iconDefaultUrl': 'sys.symbol.plus',
  'iconTouchUrl': 'sys.symbol.plus',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconTouchFontColor': '#5A5A5A',
  'iconActiveUrl': '',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let addnew: Record<string, string | boolean | Resource> = {
  'type': 'add',
  'iconDisableUrl': 'sys.symbol.person_filled_badge_plus',
  'iconDefaultUrl': 'sys.symbol.person_filled_badge_plus',
  'iconTouchUrl': 'sys.symbol.person_filled_badge_plus',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconTouchFontColor': '#5A5A5A',
  'iconActiveUrl': '',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let summarize: Record<string, string | boolean | Resource> = {
  'type': 'summarize',
  'iconDisableUrl': 'sys.symbol.AI_doc_plaintext',
  'iconDefaultUrl': 'sys.symbol.AI_doc_plaintext',
  'iconTouchUrl': 'sys.symbol.AI_doc_plaintext',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconTouchFontColor': '#0A59F7',
  'iconActiveFontColor': '#0A59F7',
  'iconActiveUrl': 'sys.symbol.AI_doc_plaintext',  // active iconurl为空，则一直为默认，需要和iconactive fontcolor成套出现
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let video: Record<string, string | boolean | Resource> = {
  'type': 'video',
  'iconDisableUrl': 'sys.symbol.video_fill',
  'iconDefaultUrl': 'sys.symbol.video_fill',
  'iconActiveUrl': 'sys.symbol.video_fill',
  'iconTouchUrl': 'sys.symbol.video_fill',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#ffffff',
  'iconTouchFontColor': '#5A5A5A',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let notepad: Record<string, string | boolean | Resource> = {
  'type': 'notepad',
  'iconDisableUrl': 'sys.symbol.doc_plaintext_fill',
  'iconDefaultUrl': 'sys.symbol.doc_plaintext_fill',
  'iconActiveUrl': 'sys.symbol.doc_plaintext_fill',
  'iconTouchUrl': 'sys.symbol.doc_plaintext_fill',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#ffffff',
  'iconTouchFontColor': '#5A5A5A',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let mute: Record<string, string | boolean | Resource> = {
  'type': 'mute',
  'iconDisableUrl': 'sys.symbol.mic_fill',
  'iconDefaultUrl': 'sys.symbol.mic_fill',
  'iconActiveUrl': 'sys.symbol.mic_slash_fill',
  'iconTouchUrl': 'sys.symbol.mic_slash_fill',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#E84026',
  'iconTouchFontColor': '#E84026',
  'isDisable': true,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let contact: Record<string, string | boolean | Resource> = {
  'type': 'contact',
  'iconDisableUrl': 'sys.symbol.person_2_fill',
  'iconDefaultUrl': 'sys.symbol.person_2_fill',
  'iconTouchUrl': 'sys.symbol.person_2_fill',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconTouchFontColor': '#5A5A5A',
  'iconActiveUrl': '',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let exchange: Record<string, string | boolean | Resource> = {
  'type': 'exchange',
  'iconDisableUrl': 'sys.symbol.reverse_order',
  'iconDefaultUrl': 'sys.symbol.reverse_order',
  'iconActiveUrl': 'sys.symbol.reverse_order',
  'iconTouchUrl': 'sys.symbol.reverse_order',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': 'rgba(0,0,0,0.9)',
  'iconTouchFontColor': '#5A5A5A',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let merge: Record<string, string | boolean | Resource> = {
  'type': 'merge',
  'iconDisableUrl': 'sys.symbol.arrow_triangle_merge',
  'iconDefaultUrl': 'sys.symbol.arrow_triangle_merge',
  'iconActiveUrl': 'sys.symbol.arrow_triangle_merge',
  'iconTouchUrl': 'sys.symbol.arrow_triangle_merge',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': 'rgba(0,0,0,0.9)',
  'iconTouchFontColor': '#5A5A5A',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

const allButtonsList = [
  record,
  keep,
  add,
  addnew,
  video,
  notepad,
  mute,
  contact,
  exchange,
  merge,
  summarize
]

interface CallButtons {
  allButtonsList: Record<string, string | boolean | Resource>[];
  record: Record<string, string | boolean | Resource>;
  keep: Record<string, string | boolean | Resource>;
  add: Record<string, string | boolean | Resource>;
  addnew: Record<string, string | boolean | Resource>;
  video: Record<string, string | boolean | Resource>;
  notepad: Record<string, string | boolean | Resource>;
  mute: Record<string, string | boolean | Resource>;
  contact: Record<string, string | boolean | Resource>;
  exchange: Record<string, string | boolean | Resource>;
  merge: Record<string, string | boolean | Resource>;
  summarize:Record<string, string | boolean | Resource>;
}

export const callButtons: CallButtons = {
  allButtonsList,
  record,
  keep,
  add,
  addnew,
  video,
  notepad,
  mute,
  contact,
  exchange,
  merge,
  summarize
}

let keyBoard: Record<string, string | boolean | Resource> = {
  'type': 'keyBoard',
  'iconDisableUrl': 'sys.symbol.dial',
  'iconDefaultUrl': 'sys.symbol.dial',
  'iconActiveUrl': 'sys.symbol.dial',
  'iconTouchUrl': 'sys.symbol.dial',
  'iconDisableFontColor': '#ffffff',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#0A59F7',
  'iconTouchFontColor': '#0A59F7',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let hangUp: Record<string, string | boolean | Resource> = {
  'type': 'hangUp',
  'iconDisableUrl': 'sys.symbol.phone_down_fill',
  'iconDefaultUrl': 'sys.symbol.phone_down_fill',
  'iconActiveUrl': 'sys.symbol.phone_down_fill',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}


let videoHangUp: Record<string, string | boolean | Resource> = {
  'type': 'hangUp',
  'iconDisableUrl': 'sys.symbol.phone_down_fill',
  'iconDefaultUrl': 'sys.symbol.phone_down_fill',
  'iconActiveUrl': 'sys.symbol.phone_down_fill',
  'iconTouchUrl': 'sys.symbol.phone_down_fill',
  'iconDisableFontColor': '#ffffff',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#ffffff',
  'iconTouchFontColor': '#ffffff',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let videoMute: Record<string, string | boolean | Resource> = {
  'type': 'videoMute',
  'iconDisableUrl': 'sys.symbol.mic_fill',
  'iconDefaultUrl': 'sys.symbol.mic_fill',
  'iconActiveUrl': 'sys.symbol.mic_slash_fill',
  'iconTouchUrl': 'sys.symbol.mic_slash_fill',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#E84026',
  'iconTouchFontColor': '#E84026',
  'isDisable': true,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let speaker: Record<string, string | boolean | Resource> = {
  'type': 'speaker',
  'iconDisableUrl': 'sys.symbol.speaker_wave_3_fill',
  'iconDefaultUrl': 'sys.symbol.speaker_wave_3_fill',
  'iconActiveUrl': 'sys.symbol.speaker_wave_3_fill',
  'iconTouchUrl': 'sys.symbol.speaker_wave_3_fill',
  'iconDisableFontColor': '#ffffff',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#0A59F7',
  'iconTouchFontColor': '#0A59F7',
  'isDisable': false,
  'isActive': true,
  'iconText': $r('app.string.emptyStr')
}

let switchCamera: Record<string, string | boolean | Resource> = {
  'type': 'switchCamera',
  'iconDisableUrl': 'sys.symbol.switch_camera_fill',
  'iconDefaultUrl': 'sys.symbol.switch_camera_fill',
  'iconActiveUrl': 'sys.symbol.switch_camera_fill',
  'iconTouchUrl': 'sys.symbol.switch_camera_fill',
  'iconDisableFontColor': '#ffffff',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#0A59F7',
  'iconTouchFontColor': '#0A59F7',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let switchToVoice: Record<string, string | boolean | Resource> = {
  'type': 'switchToVoice',
  'iconDisableUrl': 'sys.symbol.arrow_down_left_video_badge_phone_fill',
  'iconDefaultUrl': 'sys.symbol.arrow_down_left_video_badge_phone_fill',
  'iconActiveUrl': 'sys.symbol.arrow_down_left_video_badge_phone_fill',
  'iconTouchUrl': 'sys.symbol.arrow_down_left_video_badge_phone_fill',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#0A59F7',
  'iconTouchFontColor': '#0A59F7',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

let tureOffMyVideo: Record<string, string | boolean | Resource> = {
  'type': 'tureOffMyVideo',
  'iconDisableUrl': 'sys.symbol.video_slasj_fill',
  'iconDefaultUrl': 'sys.symbol.video_slasj_fill',
  'iconActiveUrl': 'sys.symbol.video_slasj_fill',
  'iconTouchUrl': 'sys.symbol.video_slasj_fill',
  'iconDisableFontColor': 'rgba(255,255,255,0.4)',
  'iconDefaultFontColor': '#ffffff',
  'iconActiveFontColor': '#0A59F7',
  'iconTouchFontColor': '#0A59F7',
  'isDisable': false,
  'isActive': false,
  'iconText': $r('app.string.emptyStr')
}

const thirdButtons = [
  keyBoard,
  videoHangUp,
  videoMute,
  speaker,
  switchToVoice,
  switchCamera,
  tureOffMyVideo
]

export const videoBtnGroupList = thirdButtons;

interface BtnGroupConfig {
  videoBtnGroupList: Record<string, string | boolean | Resource>[];
}

const btnGroupConfig: BtnGroupConfig = {
  videoBtnGroupList
}

export default btnGroupConfig;
