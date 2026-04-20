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

export default class CallRecorderCloneConstant {
  //Clone Database Name
  public static CALL_RECORDER_CLONE_DB_NAME = 'callRecorder.db';
  public static CALL_RECORDER_CLONE_NEXT_DB_NAME = 'old_call_record.db';
  //Copy Audio files paths
  public static HMOS2NEXT_UPGRADE_AUDIO_PATH = 'restore/Sounds/CallRecord';
  public static NEXT2NEXT_CLONE_AUDIO_PATH = 'restore/data/storage/el2/group';
  public static NEXT2NEXT_CLONE_AUDIO_PATH2 = 'restore/data/storage/el2/base/.backup/restore/CallRecord';
  public static NEXT2NEXT_CLONE_AUDIO_PATH3 = 'restore/data/storage/el2/base/haps/entry/files/CallRecord';
  //Table name in the clone database
  public static FILE_LIST_TABLE_NAME = 'comandroidphoneautorecordbackup_copy_file_list_info';
  public static RECORDER_FILE_TB = 'comandroidphoneautorecordbackupcall_record_file_tb';
  public static CONTACT_TB = 'comandroidphoneautorecordbackupcustomize_tb';
  //table --comandroidphoneautorecordbackup_copy_file_list_info
  public static FILE_LIST_ID = '_id';
  public static FILE_LISE_VALUE = 'value';
  //table --comandroidphoneautorecordbackupcall_record_file_tb
  public static DURATION = 'duration';
  public static FILE_SIZE = 'file_size';
  public static RECORD_ID = '_id';
  public static DATA = '_data';
  public static TITLE = 'title';
  public static DATE_ADDED = 'date_added';
  public static CLONE_VERSION_NAME: string = '99.99.99.999';
  public static UPGRADE_VERSION_NAME: string = '0.0.0.0';
  public static QUERY_PAGE_NUM = 200;
  //Query fields whose data is required from the CALL_RECORDER table in the dual-framework database.
  public static CALL_RECORDER_CLONE_RECORD: string[] = [
    CallRecorderCloneConstant.DURATION,
    CallRecorderCloneConstant.FILE_SIZE,
    CallRecorderCloneConstant.RECORD_ID,
    CallRecorderCloneConstant.DATA,
    CallRecorderCloneConstant.TITLE,
    CallRecorderCloneConstant.DATE_ADDED
  ];
}
