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

import common from '@ohos.app.ability.common';
import { FileUtils } from '../common/utils/FileUtils';
import LogUtils from '../common/utils/LogUtils';
import ohosDataRdb from '@ohos.data.relationalStore';
import relationalStore from '@ohos.data.relationalStore';
import CallRecorderSingleConstant from '../common/constant/CallRecorderSingleConstant';
import { ValuesBucket } from '@kit.ArkData';
import { backUpToDoubleDbHelper } from '../common/utils/database/BackUpToDoubleDbHelper';

const TAG = 'DbBackUpProcessor';

/**
 * the create call record file table sql
 */
let CREATE_CALL_RECORD_FILE_TABLE_SQL = `CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackupcall_record_file_tb (` +
  `_id          INTEGER,` +
  `title        TEXT,` +
  `_data        TEXT,` +
  `date_added   INTEGER,` +
  `file_size    INTEGER,` +
  `duration     INTEGER)`;

/**
 * the create customize file table sql
 */
let CREATE_CUSTOMIZE_TABLE_SQL = `CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackupcustomize_tb (` +
  `_id          INTEGER,` +
  `name         TEXT,` +
  `number       TEXT)`;

/**
 * the create copy_file_list file table sql
 */
let CREATE_COPY_FILE_LIST_TABLE_SQL = `CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackup_copy_file_list_info (` +
  `_id          INTEGER,` +
  `value        TEXT)`;

/**
 * the create default_file_list file table sql
 */
let CREATE_DEFAULT_FILE_LIST_TABLE_SQL = `CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackup_default_file_list_info (` +
  `_id          INTEGER,` +
  `value        TEXT)`;

/**
 * the create uri file table sql
 */
let CREATE_URI_TABLE_SQL = `CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackup_uri_info (` +
  `_id          INTEGER,` +
  `need_count   INTEGER,` +
  `value       TEXT)`;

/**
 * the create uri file table sql
 */
let CREATE_VERSION_TABLE_SQL = `CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackup_version_info (` +
  `version          INTEGER,` +
  `extra_data       TEXT)`;

// rdb目录下临时DB
export const TEMP_BACK_UP_DOUBLE_CALL_RECORDER_DB = 'temp_back_up_double_call_recorder.db';

// 指定目录DB
let CALL_RECORDER_DB = 'autorecord.db';

export const BACKUP_CALL_RECORD_FILE_TB = 'comandroidphoneautorecordbackupcall_record_file_tb';
export const BACKUP_CUSTOMIZE_TB = 'comandroidphoneautorecordbackupcustomize_tb';
export const BACKUP_COPY_FILE_LIST_INFO = 'comandroidphoneautorecordbackup_copy_file_list_info';
export const BACKUP_DEFAULT_FILE_LIST_INFO = 'comandroidphoneautorecordbackup_default_file_list_info';
export const BACKUP_URI_INFO = 'comandroidphoneautorecordbackup_uri_info';
export const BACKUP_VERSION_INFO = 'comandroidphoneautorecordbackup_version_info';

let NEXT2HMOS = 'next2hmos';

export const tempConfig: ohosDataRdb.StoreConfig = {
  name: TEMP_BACK_UP_DOUBLE_CALL_RECORDER_DB,
  securityLevel: ohosDataRdb.SecurityLevel.S1
};

export default class DbBackUpProcessor {
  private static instance: DbBackUpProcessor;

  public static getInstance(): DbBackUpProcessor {
    if (!DbBackUpProcessor.instance) {
      DbBackUpProcessor.instance = new DbBackUpProcessor();
    }
    return DbBackUpProcessor.instance;
  }

  public async startBackUp(context: common.Context): Promise<string> {
    if (!context) {
      LogUtils.e(TAG, 'startBackUp invalid context');
      return 'invalid context';
    }
    // 1.检测是否存在临时db和之前的备份记录
    await this.deletePreTemDb(context);
    await this.deleteDestDirDb(context);

    // 2.创建DB
    const doubleDb = await this.getTempRdb(context);
    if (!doubleDb) {
      LogUtils.e(TAG, 'get backUp DBHelper error');
      return 'get backUp DBHelper error';
    }
    // 3.创建表
    await this.createBasicTables(doubleDb);

    // 4.备份表
    await this.startCloneNext2Hm(context);

    // 5.移动DB到指定沙箱
    let copyResult = await this.copyDb(context, doubleDb);

    // 6.删除临时db
    await this.deletePreTemDb(context);
    return copyResult;
  }

  private async startCloneNext2Hm(context: common.Context): Promise<void> {
    await this.startMigrateCallRecord(context);
    await this.startMigrateCustomize(context);
    await this.startMigrateCopyFileList(context);
    await this.startMigrateDefaultFileList(context);
    await this.startMigrateUriList(context);
    await this.startMigrateVersionList(context);
  }

  private async startMigrateCallRecord(context: common.Context) {
    let tableName: string = CallRecorderSingleConstant.RECORD_LOG_TB_NAME;
    let count = await backUpToDoubleDbHelper.queryCount(context, tableName);
    let totalPage = Math.ceil(count / CallRecorderSingleConstant.QUERY_PAGE_NUM);
    LogUtils.i(TAG, 'startMigrateCallRecord count = ' + count + ', totalPage =' + totalPage);
    for (let curPage = 1; curPage <= totalPage; curPage++) {
      let callRecodeResult: ValuesBucket[] = await backUpToDoubleDbHelper.queryCallRecorder(
        context, CallRecorderSingleConstant.QUERY_PAGE_NUM * (curPage - 1));
      await backUpToDoubleDbHelper.batchInsertRecordInfoForBackUp(context, callRecodeResult);
    }
    LogUtils.i(TAG, 'endMigrateCallRecord');
  }

  private async startMigrateCustomize(context: common.Context) {
    let tableName: string = CallRecorderSingleConstant.RECORD_CONTACT_TB_NAME;
    let count = await backUpToDoubleDbHelper.queryCount(context, tableName);
    let totalPage = Math.ceil(count / CallRecorderSingleConstant.QUERY_PAGE_NUM);
    LogUtils.i(TAG, 'startMigrateCustomize count = ' + count + ', totalPage =' + totalPage);
    for (let curPage = 1; curPage <= totalPage; curPage++) {
      let recordContactDataStruct: ValuesBucket[] = await backUpToDoubleDbHelper.queryCustomizeData(
        context, CallRecorderSingleConstant.QUERY_PAGE_NUM * (curPage - 1));
      await backUpToDoubleDbHelper.batchInsertCustomizeForBackUp(context, recordContactDataStruct);
    }
    LogUtils.i(TAG, 'endMigrateCustomize');
  }

  private async startMigrateCopyFileList(context: common.Context) {
    let copyFileDataStruct: ValuesBucket[] = await backUpToDoubleDbHelper.getCopyFileData(context);
    await backUpToDoubleDbHelper.batchInsertCopyFileForBackUp(context, copyFileDataStruct);
  }

  private async startMigrateDefaultFileList(context: common.Context) {
    let copyFileDataStruct: ValuesBucket[] = await backUpToDoubleDbHelper.getDefaultFileData(context);
    await backUpToDoubleDbHelper.batchInsertDefaultFileForBackUp(context, copyFileDataStruct);
  }

  private async startMigrateUriList(context: common.Context) {
    let copyFileDataStruct: ValuesBucket[] = await backUpToDoubleDbHelper.getUriData(context);
    await backUpToDoubleDbHelper.batchInsertUriForBackUp(context, copyFileDataStruct);
  }

  private async startMigrateVersionList(context: common.Context) {
    let copyFileDataStruct: ValuesBucket[] = await backUpToDoubleDbHelper.getVersionData(context);
    await backUpToDoubleDbHelper.batchInsertVersionForBackUp(context, copyFileDataStruct);
  }

  private async getTempRdb(context: common.Context) {
    let rdbStore: relationalStore.RdbStore | undefined;
    try {
      rdbStore = await ohosDataRdb.getRdbStore(context, tempConfig);
    } catch (err) {
      LogUtils.e(TAG, `getTempRdb failed: ${err?.code}  msg: ${err?.message}`);
    }
    return rdbStore;
  }

  private async deletePreTemDb(context: common.Context) {
    let templeDbAbsPath = this.getTempleDbAbsPath(context);
    if (!FileUtils.isFileExist(templeDbAbsPath)) {
      LogUtils.i(TAG, `deletePreTemDb no tem db need delete`);
      return;
    }
    try {
      // 删除缓存库，需谨慎
      await relationalStore.deleteRdbStore(context, tempConfig);
      LogUtils.i(TAG, `deletePreTemDb success`);
    } catch (err) {
      LogUtils.e(TAG, `deletePreTemDb failed: ${err?.code}  msg: ${err?.message}`);
    }
  }

  private async deleteDestDirDb(context: common.Context) {
    let destDbAbsPath = this.getDestDirAbsPath(context);
    if (!FileUtils.isFileExist(destDbAbsPath)) {
      LogUtils.i(TAG, `destDbAbsPath no db need delete`);
      return;
    }
    const deleteDbResult = FileUtils.deleteFileSync(destDbAbsPath);
    LogUtils.i(TAG, `deleteDestDirDb result is ${deleteDbResult}`);
  }

  private getDestDirAbsPath(context: common.Context) {
    let destDbDir = context.filesDir + '/' + NEXT2HMOS + '/' + 'database';
    let destDbAbsPath = destDbDir + '/' + CALL_RECORDER_DB;
    return destDbAbsPath;
  }

  private getTempleDbAbsPath(context: common.Context) {
    let rdbDir = context.databaseDir + '/rdb';
    let templeDbAbsPath = rdbDir + '/' + TEMP_BACK_UP_DOUBLE_CALL_RECORDER_DB;
    return templeDbAbsPath;
  }

  private async copyDb(context: common.Context, rdbStore: relationalStore.RdbStore): Promise<string> {
    LogUtils.i(TAG, 'copyDb start');
    let destDbDir = context.filesDir + '/' + NEXT2HMOS;
    if (!FileUtils.isFileExist(destDbDir)) {
      FileUtils.mkDirSync(destDbDir);
    }
    if (!FileUtils.isFileExist(destDbDir)) {
      LogUtils.e(TAG, 'copyDb destDir not exist');
      return 'dest dir not exist';
    }
    destDbDir = destDbDir + '/' + 'database'
    FileUtils.mkDirSync(destDbDir);
    if (!FileUtils.isFileExist(destDbDir)) {
      LogUtils.e(TAG, 'copyDb destDir not exist two');
      return 'dest dir not exist';
    }
    try {
      const rdb = rdbStore;
      if (!rdb) {
        LogUtils.i(TAG, `copyDb rdb is undefined`);
        return 'copyDb rdb is undefined';
      }
      let destDbAbsPath = this.getDestDirAbsPath(context);
      await rdb.backup(destDbAbsPath);
      LogUtils.i(TAG, 'copyDb success');
      return '';
    } catch (err) {
      LogUtils.e(TAG, `copyDb getErr: ${err?.code}, ${err?.message}`);
      return 'copyDb error';
    }
  }

  private async createBasicTables(rdbStore: ohosDataRdb.RdbStore) {
    if (!rdbStore) {
      LogUtils.e(TAG, 'createBasicTables rdbStore is null');
      return;
    }
    try {
      await rdbStore.executeSql(CREATE_CALL_RECORD_FILE_TABLE_SQL, []);
      await rdbStore.executeSql(CREATE_CUSTOMIZE_TABLE_SQL, []);
      await rdbStore.executeSql(CREATE_COPY_FILE_LIST_TABLE_SQL, []);
      await rdbStore.executeSql(CREATE_DEFAULT_FILE_LIST_TABLE_SQL, []);
      await rdbStore.executeSql(CREATE_URI_TABLE_SQL, []);
      await rdbStore.executeSql(CREATE_VERSION_TABLE_SQL, []);
      LogUtils.i(TAG, 'createBasicTables succeed');
    } catch (err) {
      LogUtils.e(TAG, `createBasicTables err code: ${err?.code}  msg: ${err?.message}`);
    }
  }
}