/**
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

import CallStateConst from '../constant/CallStateConst';
import DefaultCallData from '../struct/TypeUtils';
import { isVideoCall } from './CallListHelper';
import { ReportUtil } from './ReportUtils/ReportUtil';

export class ContactsData {
  public static readonly DB_BASE_URI = 'datashare:///com.ohos.contactsdataability';
  public static readonly DB_URI = 'datashare:///com.ohos.contactsdataability' + '/contacts/contact_data';
  public static readonly CONTACT_NAME = 'display_name';
  public static readonly CONTACT_ID = 'contact_id';
  public static readonly RAW_CONTACT_ID = 'raw_contact_id';
  public static readonly BLOB_DATA = 'blob_data';
  public static readonly COMPANY = 'company';
  public static readonly COMPANY_POSITION = 'position';
  public static readonly TYPE_ID = 'type_id';
  public static readonly IS_DELETED = 'is_deleted';
  public static readonly MARK_MY_CARD = 'primary_contact';
  public static readonly DETAIL_INFO = 'detail_info';
  public static readonly FORMAT_PHONE_NUMBER = 'format_phone_number';
  public static readonly ORGANIZATION = '4';
  public static readonly PHOTO = '8';
  public static readonly NOTE = '10';
  public static readonly COLUMNS =
    [ContactsData.CONTACT_ID, ContactsData.CONTACT_NAME, ContactsData.DETAIL_INFO, ContactsData.FORMAT_PHONE_NUMBER];
  public static readonly CONTACT_TYPE = [ContactsData.ORGANIZATION, ContactsData.PHOTO, ContactsData.NOTE];
  public static readonly COLUMN_ENHANCED =
    [ContactsData.CONTACT_ID, ContactsData.TYPE_ID, ContactsData.BLOB_DATA, ContactsData.COMPANY,
      ContactsData.COMPANY_POSITION, ContactsData.DETAIL_INFO];

  public async reportIncomingOrOutgoingCallInfo(callData: DefaultCallData) {
    let isContact = callData.contactName.length > 0 ? true : false;
    if (callData.callState === CallStateConst.CALL_STATUS_INCOMING) {
      let callType: number = callData.callType == CallStateConst.TYPE_VOIP ? 1 : 0;
      let phoneNumberLength: number = callData.accountNumber.length > 0 ? callData.accountNumber.length : 0;
      let incomingMediaType: number = isVideoCall(callData.videoState) ? 1 : 0;
      await ReportUtil.getInstance().reportHasIncomingCall(callType, phoneNumberLength, isContact, callData.callId,
        callData.accountId, incomingMediaType);
    } else if (callData.callState === CallStateConst.CALL_STATUS_DIALING &&
      callData.callType !== CallStateConst.TYPE_VOIP) {
      ReportUtil.getInstance().reportDialOutgoing(callData);
    }
  }
}