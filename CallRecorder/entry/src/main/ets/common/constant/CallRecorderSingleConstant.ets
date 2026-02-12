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

export default class CallRecorderSingleConstant {
  // datashare uri
  public static CALL_RECORDER_URI: string = 'datashare:///com.ohos.callrecorder';
  public static CALL_RECORDER_LOG_URI: string | undefined = CallRecorderSingleConstant.CALL_RECORDER_URI +
    '/call_record/record_log';
  public static RECORD_CONFIG_URI: string | undefined = CallRecorderSingleConstant.CALL_RECORDER_URI +
    '/call_record/record_config';
  public static RECORD_LOG_TB_NAME = 'record_log';
  public static RECORD_CONFIG_TB_NAME = 'record_config';
  public static RECORD_CONTACT_TB_NAME = 'record_contact';
  public static QUERY_PAGE_NUM = 200;
  //record_log
  public static ID = 'id';
  public static FILE_PATH = 'file_path';
  public static DURATION = 'duration';
  public static DISPLAY_NAME = 'display_name';
  public static DATE_ADDED = 'date_added';
  public static TITLE = 'title';
  public static PHONE_NUMBER = 'phone_number';
  public static RECORDER_ADDED = 'recorder_added';
  public static IS_DELETED = 'is_deleted';
  public static SOUNDRECORD_DISPLAY_NAME = 'soundrecord_display_name';
  //record_config
  public static CONFIG_ID = 'id';
  public static CONFIG_IS_OPEN = 'is_open';
  public static CONFIG_OBJECT = 'object';
  //record_contact
  public static CONTACT_ID = 'id';
  public static CONTACT_PHONE_NUMBER = 'phone_number';
  public static CONTACT_NAME = 'name';
}