/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

export const RESTORE_INFO_PREF_NAME: string = 'restore_info';
export const NEW_EM_INFO_PREF_NAME: string = 'emergency_info_preference_name';
export const NEW_EM_CONTACTS_PREF_NAME: string = 'emergency_contacts_preference_name';

export const COPY_PREF_STATUS_KEY: string = 'COPY_PREF_STATUS_KEY';
export const COPY_DB_STATUS_KEY: string = 'COPY_DB_STATUS_KEY';
export const PREF_XML_PARSE_STATUS_KEY: string = 'PREF_XML_TRANS_STATUS_KEY';
export const DB_READ_STATUS_KEY: string = 'DB_READ_STATUS_KEY';

const OLD_EM_XML_NAME_PRF: string = 'com.and';
const OLD_EM_XML_NAME_SUF: string = 'roid.emergency_preferences.xml';
export const OLD_EM_XML_NAME: string = `${OLD_EM_XML_NAME_PRF}${OLD_EM_XML_NAME_SUF}`;
const OLD_PREF_DIR_PRF: string = '/restore/com.and';
const OLD_PREF_DIR_SUF: string = 'roid.emergency/de';
export const OLD_PREF_DIR: string = `${OLD_PREF_DIR_PRF}${OLD_PREF_DIR_SUF}`;
export const NEXT_TO_NEXT_OLD_PREF_DIR: string = `restore/data/storage/el2/base/haps/entry/preferences`;
const OLD_DB_DIR_PRF: string = '/restore/com.and';
const OLD_DB_DIR_SUF: string = 'roid.providers.contacts/ce';
export const OLD_DB_DIR: string = `${OLD_DB_DIR_PRF}${OLD_DB_DIR_SUF}`;

export const READ_DATA_SIZE_4096 = 4096;
export const XML_ENCODE_UTF_8 = 'utf-8';

export const XML_ROOT_NODE_MAP: string = 'map';
export const OLD_EM_CONTACTS_KEY: string = 'emergency_contacts';
export const OLD_EM_URI_SEPARATOR: string = '|';
const URI_SCHEME_PRF: string = 'content://com.and';
const URI_SCHEME_SUF: string = 'roid.contacts/data/';
export const OLD_EM_URI_SCHEME_PREFIX: string = `${URI_SCHEME_PRF}${URI_SCHEME_SUF}`;
export const NEW_EMERGENCY_CONTACTS_KEY = 'emergency_contacts_key';

export const RESTORE_PROGRESS_KEY: string = 'restore_Status';
export const RESTORE_FROM_ABILITY: string = 'restore_from_ability';
export const AUTO_SEND_SOS_SMS_SWITCH: string = 'auto_send_sos_sms_switch';
export const AUTO_DIAL_SOS_NUMBER_SWITCH: string = 'auto_dial_sos_number_switch';
export const AUTO_SEND_SOS_SMS_SWITCH_ON: string = '1';
export const AUTO_DIAL_SOS_NUMBER_SWITCH_ON: string = '1';

export const OLD_TO_NEW_TRANS_MAP: Map<string, string> = new Map<string, string>([
  ['name', 'name'],
  ['address', 'address'],
  ['blood_type', 'bloodType'],
  ['allergies', 'allergicReaction'],
  ['medications', 'drug'],
  ['organ_donor', 'isOrganDonor'],
  ['medical_conditions', 'drugStatusAndNotice'],
  ['autoSendSosMesPrivacyStatement', 'auto_send_sos_sms_switch'],
  ['autoDialAccidentSosPrivacyStatement', 'auto_dial_sos_number_switch'],
]);

export const OLD_DATABASE_NAME = 'contacts2.db';
export const OLD_DATA_TABLE_NAME = 'data';
export const COL_RAW_ID = 'raw_contact_id';
export const COL_DATA1 = 'data1';
export const COL_DATA_ID = '_id';
export const COL_MIMETYPE = 'mimetype_id';
export const MIMETYPE_NAME = 7;

export const EMERGENCY_INFO_TB = 'comhuaweiemergencyemergencyinfobackupemergency_info_tb';
export const EMERGENCY_CONTACT_TB = 'comhuaweiemergencyemergencyinfobackupemergency_contact_tb';
export const EMERGENCY_DIAL_SOS_NUMBER_SWITCH_TB = 'comhuaweiemergencyemergencyinfobackupauto_dial_sos_number_switch_tb';
export const EMERGENCY_SEND_SOS_SMS_SWITCH_TB = 'comhuaweiemergencyemergencyinfobackupauto_send_sos_sms_switch_tb';
export const EMERGENCY_CONTACT_MAX = 3;

export const QUERY_OLD_DATA: string[] = [
  COL_RAW_ID,
  COL_DATA1,
  COL_DATA_ID
];

export const enum RestoreVersion {
  VER_DUAL_UPGRADE_TO_SINGLE = '0.0.0.0',
  VER_DUAL_CLONE_TO_SINGLE = '99.99.99.999'
}

export enum RestoreProgress {
  // get status failed
  STATUS_UNKNOWN = -1,
  // start
  INIT = 0,
  // end
  RESTORE_SUCCESS = 1
}
