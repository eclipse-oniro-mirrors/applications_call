/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
export class Constant {
  //contact.db dataShare request base address
  public static CONTENT_URI: string = 'datashare:///com.ohos.contactsdataability';
  //contact.db contact_data table views request address
  public static CONTACT_URI: string = Constant.CONTENT_URI + '/contacts/contact_data';
  //call_record.db dataShare request base address
  public static RECORDER_DATA_SHARE_URL: string = 'datashare:///com.ohos.callrecorder.datashareAbility';
  //call_record.db record_config table request address
  public static RECORD_CONFIG: string = '/call_record/record_config';
  //call_record.db record_contact table request address
  public static RECORD_CONTACT: string = '/call_record/record_contact';
  //call_record.db record_log table request address
  public static RECORD_LOG: string = '/call_record/record_log';
  //contacts.hap page bundle name
  public static CONTACT_BUNDLE_NAME: string = 'com.ohos.contacts';
  //contacts.hap page ability name
  public static CONTACT_ABILITY_NAME: string = 'com.ohos.contacts.MainAbility';
  //contacts.hap page There is an icon on the home screen and click the entry category.
  public static COMMON_ENTITIES: string = 'entity.system.home';
  //CallRecorder.hap page bundle name
  public static RECORDER_BUNDLE_NAME: string = 'com.ohos.callrecorder';
  //CallRecorder.hap page ability name
  public static RECORDER_ABILITY_NAME: string = 'com.ohos.callrecorder.CallRecorderAbility';
  //CallRecorder.hap ability context
  public static CALL_RECORDER_ABILITY_CONTEXT: string = 'callRecorderAbilityContext';
  //CallRecorder.hap dataShare context
  public static CALL_RECORDER_DATA_SHARE_ABILITY_CONTEXT: string = 'callRecorderDataShareAbilityContext';
  // Columns used for query contacts
  public static COLUMNS = ['id', 'display_name', 'detail_info', 'type_id', 'contact_id', 'format_phone_number'];

  public static UNSUPPORTED_FILENAME_REGEXP = /[\\:*?"<>\/|]/;
}