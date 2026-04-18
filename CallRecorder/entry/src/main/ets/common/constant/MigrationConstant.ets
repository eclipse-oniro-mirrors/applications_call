/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
export type StartMigrationCallBack = (code: number, message: string) => void;

export enum MigrationWorkerMessageType {
  MIGRATION = 'migration',
  PROGRESS = 'progress',
  SIGNAL = 'signal',
  CLOSE = 'close'
}

export enum MigrationStatus {
  FAILED = 1,
  SUCCESS = 0,
  INVALID = -1
}

export enum MigrationCommand {
  STOP_MIGRATION = 0,
  START_MIGRATION = 1,
  SEND_PROCESS_MIGRATION = 2,
  PAUSE_MIGRATION = 3,
  RESUME_MIGRATION = 4
}

export enum MigrationRecordStatus {
  NOT_MIGRATED = 0,
  MIGRATED = 1,
  PART_MIGRATED = 2,
  ALL_MIGRATED = 3
}

export enum MigrationProcessStatus {
  RUNNING = 0,
  STOP = 1,
  PAUSE = 2,
  RESUME = 3,
  COMPLETE = 4
}

export enum MigrationLockStatus {
  UNLOCKED = 0,
  LOCKED = 1
}

export enum MigrationSpaceStatus {
  INTERNAL_ERROR = -1,
  SPACE_ENOUGH = 0,
  SPACE_NOT_ENOUGH = 1000
}

export enum Device {
  PHONE = 'phone',
  TABLET = 'tablet',
  PC = '2in1'
}

@Sendable
export class MigrationConstant {
  public static INIT_VALUE: number = -1;
  public static ARRAY_BUFFER_SIZE: number = 8;
  // 500M space size
  public static FREE_SIZE: number = 524288000;
  public static MIGRATION_RECORD_PATH: string = '/storage/Users/currentUser/Sounds/CallRecord';
  public static PATH_SEPARATOR: string = '/';
  public static FILE_NAME_M4A_SUFFIX: string = '.m4a';
  public static FILE_NAME_AMR_SUFFIX: string = '.amr';
  public static FILE_NAME_TMP_SUFFIX: string = '.tmp';
  public static FILE_NAME_UNDERLINE_SEPARATOR: string = '_';
  public static FILE_NAME_SPACE_SEPARATOR: string = ' ';
  public static EMPTY_STRING: string = '';

  public static DATABASE: string = 'call_record.db';
  public static MIGRATION_TABLE: string = 'tab_transfer_records';
  public static RECORD_TABLE: string = 'record_log';

  // tab_transfer_records
  public static COLUMN_ID: string = 'id';
  public static COLUMN_DISPLAY_NAME: string = 'display_name';
  public static COLUMN_ORI_URI: string = 'ori_uri';
  public static COLUMN_NEW_URI: string = 'new_uri';
  public static COLUMN_RECORDER_ADDED: string = 'recorder_added';
  public static COLUMN_HAS_TRANSFER: string = 'has_transfer';
  public static COLUMN_TRY_TIMES: string = 'try_times';

  // record_log
  public static COLUMN_FILE_PATH: string = 'file_path';
  public static COLUMN_DURATION: string = 'duration';
  public static COLUMN_DATE_ADDED: string = 'date_added';
}