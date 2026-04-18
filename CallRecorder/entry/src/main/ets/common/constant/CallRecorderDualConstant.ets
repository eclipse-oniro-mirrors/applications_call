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

export default class CallRecorderDualConstant {
  //Dual Database Name
  public static AUTO_RECORD_DB_NAME = 'autorecord.db';
  //Table name in the Dual database
  public static CUSTOMIZE_TABLE_NAME = 'customize';
  public static RECORDER_FILE_TABLE_NAME = 'call_record_file';
  //table --customize
  public static CUSTOMIZE_ID = '_id';
  public static CUSTOMIZE_NAME = 'name';
  public static CUSTOMIZE_NUMBER = 'number';
  //table --call_record_file
  public static DURATION = 'duration';
  public static FILE_SIZE = 'file_size';
  public static RECORD_ID = '_id';
  public static DATA = '_data';
  public static TITLE = 'title';
  public static DATE_ADDED = 'date_added';
}