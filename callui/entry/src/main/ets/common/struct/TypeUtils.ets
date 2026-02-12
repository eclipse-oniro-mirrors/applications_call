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

import ConferenceConst from '../constant/ConferenceConst';

import { MarkType } from '../../model/NumberMark';
import { Patch, Patcher } from '../utils/Misc';

// Re-export for compatibility.
export { MarkType };

export class NumberMarkInfo {
  public markType: MarkType = -1;
  public markContent: string = '';
  public markCount: number = -1;
  public markSource?: string = '';
  public isCloud?: boolean = false;
  public markDetails?: string = '';
}

export default class DefaultCallData {
  public accountId: number = -1;
  public accountNumber: string = '';
  public callId: number = -1;
  public callState: number = -1;
  public callType: number = -1;
  public conferenceState: number = -1;
  public contactName: string = '';
  public distributedContactName?: string = '';
  public contactId?: number = -1;
  public contactAvatar?: PixelMap | null = null;
  public contactAvatarColor?: string = '';
  public contactSmallAvatar?: PixelMap | null = null;
  public formatNumber: string = '';
  public isEcc: boolean = false;
  public isRingSilenced?: boolean = false;
  public callDirection?: number = undefined;
  public wasVideoCall?: boolean = false;
  public startTime: number = -1;
  public videoState: number = -1;
  public conferenceType?: number = 1;
  public numberLocation: string = '';
  public crsType?: number = -1;
  public imsCallMode?: number = undefined;
  public contactCompany: string = '';
  public contactCompanyPosition: string = '';
  public contactNote?: string = '';
  public voipCallAttribute?: VoipCallAttribute = new VoipCallAttribute();
  public originalCallType?: number = -1;
  public numberMarkInfo: NumberMarkInfo = { markContent: '', markType: -1, markCount: -1 };
  public isInvalidNumber?: boolean = false;
  public isHoldVideoUx?: boolean = false;
  public isVoiceMailNumber?: boolean = false;
  public isAnswered?: boolean = false;
  public hasAnsweredIncomingCallLog?: boolean = false;
  public extraParams?: Record<string, Object>;
  public isAntiFraud?: boolean = false;
  public isMapNavigation?: boolean = false;
  public isMarkPanelShown?: boolean = false;
}

export type CallDataPatch = Patch<DefaultCallData, 'callId'>;

export function callDataToSafeString(call: DefaultCallData): string {
  return '{' +
    // Basic info
    'id:' + call.callId +
    ',callState:' + call.callState +
    ',accountId:' + call.accountId +
    ',isConf:' + (call.conferenceState !== ConferenceConst.TEL_CONFERENCE_IDLE) +
    ',type:' + call.callType +
    // caller info
    ',numberLen:' + call.accountNumber?.length +
    ',nameLen:' + call.contactName?.length +
    // Video info
    ',videoState:' + call.videoState +
    ',imsMode:' + call.imsCallMode +
    ',crs:' + call.crsType +
    // Yellow page & number mark info
    `,numberMarkInfo:` + `{markType:${call.numberMarkInfo?.markType},isCloud:${call.numberMarkInfo?.isCloud}}` +
    `,isVoiceMailNumber: ${call.isVoiceMailNumber},isEcc: ${call.isEcc}` +
    '}';
}

export class VoipCallAttribute {
  public voipCallId: string = '';
  public userName: string = '';
  public userProfile?: PixelMap = undefined;
  public extensionId: string = '';
  public abilityName: string = '';
  public voipBundleName: string = '';
  public showBannerForIncomingCall: boolean = true;
  public hasMicPermission: boolean = true;
  public isCapsuleSticky: boolean = false;
  public isConferenceCall: boolean = false;
  public isVoiceAnswerSupported: boolean = true;
  public appName: string = '';
  public uid: number = 0;
  public appIndex: number = -1;
  public isExpired: boolean = false;
}

export class DefaultDistributeDeviceAddressData {
  public devName: Resource = $r('app.string.emptyStr');
  public devId: string = '';
}

export function getSimIcon(accountId: number): Resource {
  if (accountId === 0) {
    return $r('sys.symbol.simcard_1');
  } else {
    return $r('sys.symbol.simcard_2');
  }
}

export const callDataPatcher = new Patcher<DefaultCallData, CallDataPatch>(new DefaultCallData(), 'DefaultCallData');

export class AppWindowStyleData {
  public appWidth?: number;
  public maxWidth: number | undefined;
  public maxHeight: number | undefined;
}

export class AppBtnStyleData {
  public btnWidth: number = 64;
  public rowsGap: number = 20;
  public innerSymbolColor?: string = 'font_on_primary';
  public innerSymbolSize?: string = '28vp';
  public outerLabelTextColor?: string = 'font_on_secondary';
  public outerLabelTextSize?: string = '14vp';
  public outerLabelTextWeight?: FontWeight = FontWeight.Regular;
  public btnLabelTextGap?: string = '4vp';
  public dtmfTopMargin?: string = '12vp';
  public dtmfTopTextColor?: string = 'font_on_primary';
  public dtmfTopTextSize?: string = '24vp';
  public dtmfTopTextWeight?: FontWeight = FontWeight.Bold;
  public dtmfTopSymbolTextSize?: string = '24vp';
  public dtmfTopSymbolTextLineHeight?: string = '24vp';
  public dtmfTopSymbolTextWeight?: FontWeight = FontWeight.Bold;

  public dtmfBottomTextColor?: string = 'font_on_secondary';
  public dtmfBottomTextSize?: string = '12vp';
  public dtmfBottomTextLineHeight?: string = '14vp';
  public dtmfBottomPlusSize?: string = '14vp';
  public dtmfBottomPlusLineHeight?: string = '14vp';
  public dtmfBottomSymbolTextSize?: string = '14vp';
  public dtmfBottomSymbolTextLineHeight?: string = '14vp';

  public dtmfBottomTextWeight?: FontWeight = FontWeight.Regular;
  public dtmfBottomTopGap?: string = '38vp';
}

export class AppFuncBtnStyleData {
  public btnWidth: number = 64;
  public rowsGap: number = 20;

  public innerIconWidth?: string = '28vp';
  public outerTextSize?: string = '14vp';
  public outerTextHeight?: string = '19vp';
  public btnLabelGap?: number = 4;
  public funcBtnGroupHeight?: number = 194;
  // 短信/提醒Symbol
  public incomingIconWidth?: string = '24vp';
}

export class AppBottomBtnStyleData {
  public btnWidth: number = 64;
  public bottomGapX: number = 64;
}
