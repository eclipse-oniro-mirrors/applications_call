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

import DefaultCallData, { MarkType } from '../struct/TypeUtils';
import { StringUtil } from '../utils/StringUtil';
import CallUtils from './CallUtils';
import { isIncomingCall } from './CallListHelper';
import Utils from './utils';

const TAG = 'CallLabelUtils';
const MARK_SOURCE_OF_ANTIFRAUTCENTER = '5';

/**
 * @returns display name in call card
 */
export function getFormatCallLabelPrimary(callData: DefaultCallData, isBanner: boolean = true): string {
  const label = getCallLabelPrimary(callData, isBanner);
  if (typeof label === 'string') {
    return label;
  }
  return StringUtil.formatResourceToString(label);
}

export function getFormattedNumber(callData: DefaultCallData): string {
  if (callData.formatNumber.indexOf(' ') > -1) {
    return ('\u202d' + Utils.phoneFormat(callData.formatNumber) + '\u202c') ||
    Utils.phoneFormat(callData.accountNumber);
  }
  return Utils.phoneFormat(callData.formatNumber) || Utils.phoneFormat(callData.accountNumber);
}

export function getCallLabelPrimary(callData: DefaultCallData, isBanner: boolean = true): Resource | string {
  if (isBanner && (Utils.getInstance().isConferenceCall(callData))) {
    return $r('app.string.telephone_Conference');
  }
  const markContent = getMarkContentResource(callData);
  
  // 优先检查联系人名称（无论是否为紧急号码）
  if (callData.contactName) {
    return callData.contactName;
  }
  
  // 紧急号码的特殊处理
  if (callData.isEcc) {
    if (markContent) {
      return markContent;
    }
    if (callData.numberMarkInfo.markType === 0 || CallUtils.isOversea()) {
      return $r('app.string.emergency');
    }
  }

  if (callData.isVoiceMailNumber) {
    return $r('app.string.voicemail');
  }
  if (markContent) {
    return markContent;
  }
  const phoneNumber = getFormattedNumber(callData);
  if (phoneNumber) {
    return phoneNumber;
  }
  return $r('app.string.unknownNumber');
}

export function getNumberAndLocation(callData: DefaultCallData): string {
  if (callData.numberLocation) {
    return getFormattedNumber(callData) + ' ' + callData.numberLocation;
  } else {
    // For no location but contact exists case, we should only show number at line 2
    return getFormattedNumber(callData);
  }
}

export function getCallLabelSecondary(callData: DefaultCallData): string {
  // For EMC, we should only show number at line 2
  let enterpreise: MarkType = 11;
  if (callData.isEcc) {
    return getFormattedNumber(callData);
  }
  if (callData.contactName || callData.isVoiceMailNumber) {
    return getNumberAndLocation(callData);
  } else if (isNumberMarked(callData)) {
    if (callData.numberMarkInfo.markType === enterpreise && callData.numberMarkInfo.markSource) {
      return getNumberAndLocation(callData) + ' | ' + callData.numberMarkInfo.markSource;
    }
    let numberMarked = getNumberMarked(callData);
    return getNumberAndLocation(callData) + numberMarked;
  } else if (callData.numberLocation) {
    return callData.numberLocation;
  } else {
    // If no location and no
    return getFormattedNumber(callData);
  }
}

export function getCallLabelThird(callData: DefaultCallData): string {
  if (callData.contactCompany || callData.contactCompanyPosition) {
    return (`${callData.contactCompany ?? ''} ${callData.contactCompanyPosition ?? ''}`).trim()
  }
  if (callData.contactNote) {
    return callData.contactNote;
  }
  return '';
}

export function getNumberMarked(callData: DefaultCallData): string {
  let markType = callData.numberMarkInfo.markType?.valueOf();
  if (markType === MarkType.MARK_TYPE_NONE || markType === MarkType.MARK_TYPE_CUSTOM || markType ===
  MarkType.MARK_TYPE_YELLOW_PAGE || markType === -1) {
    return '';
  } else if (callData.numberMarkInfo.isCloud && (callData.numberMarkInfo.markCount > 0)) {
    return StringUtil.formatPluralResourceToString($r('app.plural.number_marked'), callData.numberMarkInfo.markCount);
  } else if (!callData.numberMarkInfo.isCloud) {
    return StringUtil.formatResourceToString($r('app.string.marked'));
  }
  return '';
}

export function getMarkContentResource(callData: DefaultCallData): Resource | string {
  if (!isNumberMarked(callData)) {
    return '';
  }
  return callData.numberMarkInfo.markContent;
}

export function isNumberMarked(callData: DefaultCallData): boolean {
  if (callData.numberMarkInfo) {
    const markType = callData.numberMarkInfo.markType?.valueOf();
    if (markType === undefined || markType === -1 || markType === 0) {
      return false;
    }
    return true;
  }
  return false;
}

export function fileNameString(callData: DefaultCallData): string {
  const markContent = callData.numberMarkInfo.markContent;
  if (callData.isEcc) {
    if (markContent) {
      return markContent;
    }
  }
  if (callData.isVoiceMailNumber) {
    return StringUtil.getStringByNameSync('voicemail');
  }
  if (callData.contactName) {
    return callData.contactName;
  }
  if (callData.distributedContactName) {
    return callData.distributedContactName;
  }
  if (markContent) {
    return markContent;
  }
  return callData.accountNumber;
}
