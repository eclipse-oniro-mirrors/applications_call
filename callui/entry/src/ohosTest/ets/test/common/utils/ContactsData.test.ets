/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { describe, expect, it } from '@ohos/hypium';
import DefaultCallData, { VoipCallAttribute } from '../../../../../main/ets/common/struct/TypeUtils';
import { ContactsData } from '../../../../../main/ets/common/utils/ContactsData';

let reportIncomingOrOutgoingCallInfoTest_01 = () => {
  let callData: DefaultCallData = {
    accountId: -1,
    accountNumber: '',
    callId: -1,
    callState: 2, // CALL_STATUS_DIALING
    callType: 1, // TYPE_IMS
    conferenceState: -1,
    contactName: '',
    contactId: -1,
    contactAvatar: null,
    formatNumber: '',
    isEcc: false,
    isRingSilenced: false,
    callDirection: undefined,
    wasVideoCall: false,
    startTime: -1,
    videoState: -1,
    conferenceType: 1,
    numberLocation: '',
    crsType: -1,
    imsCallMode: undefined,
    contactCompany: '',
    contactCompanyPosition: '',
    voipCallAttribute: new VoipCallAttribute(),
    originalCallType: -1,
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
    isInvalidNumber: false,
    isHoldVideoUx: false,
    isVoiceMailNumber: false,
    isAnswered: false,
    hasAnsweredIncomingCallLog: false
  }
  new ContactsData().reportIncomingOrOutgoingCallInfo(callData);
  expect(callData.contactName.length === 0).assertTrue();
}

let reportIncomingOrOutgoingCallInfoTest_02 = () => {
  let callData: DefaultCallData = {
    accountId: -1,
    accountNumber: '',
    callId: -1,
    callState: 4, //CALL_STATUS_INCOMING
    callType: -1,
    conferenceState: -1,
    contactName: 'contactName',
    contactId: -1,
    contactAvatar: null,
    formatNumber: '',
    isEcc: false,
    isRingSilenced: false,
    callDirection: undefined,
    wasVideoCall: false,
    startTime: -1,
    videoState: -1,
    conferenceType: 1,
    numberLocation: '',
    crsType: -1,
    imsCallMode: undefined,
    contactCompany: '',
    contactCompanyPosition: '',
    voipCallAttribute: new VoipCallAttribute(),
    originalCallType: -1,
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
    isInvalidNumber: false,
    isHoldVideoUx: false,
    isVoiceMailNumber: false,
    isAnswered: false,
    hasAnsweredIncomingCallLog: false
  }
  new ContactsData().reportIncomingOrOutgoingCallInfo(callData);
  expect(callData.contactName.length > 0).assertTrue();
}

let reportIncomingOrOutgoingCallInfoTest_03 = async () => {
  let callData: DefaultCallData = {
    accountId: -1,
    accountNumber: 'accountNumber',
    callId: -1,
    callState: 4, //CALL_STATUS_INCOMING
    callType: 4,
    conferenceState: -1,
    contactName: 'contactName',
    contactId: -1,
    contactAvatar: null,
    formatNumber: '',
    isEcc: false,
    isRingSilenced: false,
    callDirection: undefined,
    wasVideoCall: false,
    startTime: -1,
    videoState: 3, // VideoStateType.TYPE_VIDEO_BIDIRECTIONAL
    conferenceType: 1,
    numberLocation: '',
    crsType: -1,
    imsCallMode: undefined,
    contactCompany: '',
    contactCompanyPosition: '',
    voipCallAttribute: new VoipCallAttribute(),
    originalCallType: -1,
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
    isInvalidNumber: false,
    isHoldVideoUx: false,
    isVoiceMailNumber: false,
    isAnswered: false,
    hasAnsweredIncomingCallLog: false
  }
  new ContactsData().reportIncomingOrOutgoingCallInfo(callData);
  expect(callData.callState === 4).assertTrue();
}

export default function ContactsDataTest() {
  describe('reportIncomingOrOutgoingCallInfoTest_01', () => {
    it('DataStorageUtilTest_getRejectMsgPreferences01', 0, () => {
      reportIncomingOrOutgoingCallInfoTest_01();
    })
    it('DataStorageUtilTest_getRejectMsgPreferences02', 0, () => {
      reportIncomingOrOutgoingCallInfoTest_02();
    })
    it('DataStorageUtilTest_getRejectMsgPreferences03', 0, () => {
      reportIncomingOrOutgoingCallInfoTest_03();
    })
  })
}
