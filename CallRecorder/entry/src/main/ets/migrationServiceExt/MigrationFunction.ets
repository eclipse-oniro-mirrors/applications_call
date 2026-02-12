/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { MigrationRecord } from '../common/struct/MigrationStruct';
import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { MigrationConstant } from '../common/constant/MigrationConstant';
import LogUtils from '../common/utils/LogUtils';
import { RecordLog } from '../common/struct/RecorderStruct';

/* instrument ignore file */

@Concurrent
export async function queryNotMigratedRecord(context: Context): Promise<MigrationRecord[]> {
  let autoBackupConfig: relationalStore.StoreConfig = {
    name: MigrationConstant.DATABASE,
    securityLevel: relationalStore.SecurityLevel.S1,
    haMode: relationalStore.HAMode.MAIN_REPLICA,
    allowRebuild: true
  }
  let store = await relationalStore.getRdbStore(context, autoBackupConfig);
  let predicates = new relationalStore.RdbPredicates(MigrationConstant.MIGRATION_TABLE)
    .equalTo(MigrationConstant.COLUMN_HAS_TRANSFER, 0);
  let resultSet = await store.query(predicates);
  let index = 0;
  let result: MigrationRecord[] = [];
  if (resultSet.rowCount == 0) {
    LogUtils.i('MigrationFunction', 'queryNotMigratedRecord resultSet is empty');
    return result;
  }
  resultSet.goToFirstRow();
  do {
    let migrationRecord = new MigrationRecord();
    migrationRecord.id = resultSet.getLong(resultSet.getColumnIndex(MigrationConstant.COLUMN_ID));
    migrationRecord.displayName = resultSet.getString(resultSet.getColumnIndex(MigrationConstant.COLUMN_DISPLAY_NAME));
    migrationRecord.oriUri = resultSet.getString(resultSet.getColumnIndex(MigrationConstant.COLUMN_ORI_URI));
    migrationRecord.newUri = resultSet.getString(resultSet.getColumnIndex(MigrationConstant.COLUMN_NEW_URI));
    migrationRecord.recorderAdded =
      resultSet.getLong(resultSet.getColumnIndex(MigrationConstant.COLUMN_RECORDER_ADDED));
    migrationRecord.hasTransfer = resultSet.getLong(resultSet.getColumnIndex(MigrationConstant.COLUMN_HAS_TRANSFER));
    migrationRecord.tryTimes = resultSet.getLong(resultSet.getColumnIndex(MigrationConstant.COLUMN_TRY_TIMES));
    result[index ++] = migrationRecord;
  } while (resultSet.goToNextRow());
  resultSet.close();
  return result;
}

@Concurrent
export async function queryNotMigratedRecordLog(context: Context, pathPrefix: string): Promise<RecordLog[]> {
  let autoBackupConfig: relationalStore.StoreConfig = {
    name: MigrationConstant.DATABASE,
    securityLevel: relationalStore.SecurityLevel.S1,
    haMode: relationalStore.HAMode.MAIN_REPLICA,
    allowRebuild: true
  }
  let store = await relationalStore.getRdbStore(context, autoBackupConfig);
  let predicates = new relationalStore.RdbPredicates(MigrationConstant.RECORD_TABLE)
    .beginsWith(MigrationConstant.COLUMN_FILE_PATH, pathPrefix);
  let resultSet = await store.query(predicates);
  let index = 0;
  let result: RecordLog[] = [];
  if (resultSet.rowCount == 0) {
    LogUtils.i('MigrationFunction', 'queryNotMigratedRecordLog resultSet is empty');
    return result;
  }
  resultSet.goToFirstRow();
  do {
    let record: RecordLog = new RecordLog();
    record.filePath = resultSet.getString(resultSet.getColumnIndex(MigrationConstant.COLUMN_FILE_PATH));
    record.displayName = resultSet.getString(resultSet.getColumnIndex(MigrationConstant.COLUMN_DISPLAY_NAME));
    record.duration = resultSet.getLong(resultSet.getColumnIndex(MigrationConstant.COLUMN_DURATION));
    record.dateAdded = resultSet.getLong(resultSet.getColumnIndex(MigrationConstant.COLUMN_DATE_ADDED));
    record.recorderAdded = resultSet.getLong(resultSet.getColumnIndex(MigrationConstant.COLUMN_RECORDER_ADDED));
    result[index ++] = record;
  } while (resultSet.goToNextRow());
  resultSet.close();
  return result;
}

@Concurrent
export async function batchInsertMigrationRecord(context: Context, migrationRecords: ValuesBucket[]) {
  let autoBackupConfig: relationalStore.StoreConfig = {
    name: MigrationConstant.DATABASE,
    securityLevel: relationalStore.SecurityLevel.S1,
    haMode: relationalStore.HAMode.MAIN_REPLICA,
    allowRebuild: true
  }
  let store = await relationalStore.getRdbStore(context, autoBackupConfig);
  try {
    store.beginTransaction();
    await store.batchInsert(MigrationConstant.MIGRATION_TABLE, migrationRecords);
    store.commit();
  } catch (err) {
    LogUtils.e('MigrationFunction', `batchInsert error code:${err?.code}, msg: ${err?.message}`);
    store.rollBack();
  }
}