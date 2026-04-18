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
import rpc from '@ohos.rpc';
import { MigrationProgress, MigrationRecord } from '../common/struct/MigrationStruct';
import LogUtils from '../common/utils/LogUtils';
import { preferences, relationalStore, ValuesBucket } from '@kit.ArkData';
import { GROUP_ID } from '../common/utils/FileUtils';
import { MigrationCommand, MigrationConstant, MigrationRecordStatus } from '../common/constant/MigrationConstant';
import { RPCInfoConstant } from '../common/constant/RPCInfoConstant';
import { RecordLog } from '../common/struct/RecorderStruct';
import { taskpool } from '@kit.ArkTS';
import { batchInsertMigrationRecord, queryNotMigratedRecordLog } from './MigrationFunction';
import { queryNotMigratedRecord } from './MigrationFunction';

const TAG = 'MigrationServiceHelper'
const OPTIONS_NAME = 'migration';
const PREFERENCES_KEY = 'progress';

export class MigrationServiceHelper {
  private static migrationCallback?: rpc.IRemoteObject;
  private static preferencesOptions: preferences.Options = { name: OPTIONS_NAME, dataGroupId: GROUP_ID,
    storageType: preferences.StorageType.XML };

  /**
   * 保存远程对象
   *
   * @param data rpc.MessageSequence
   */
  public static handleRegister(data: rpc.MessageSequence): void {
    if (data != undefined) {
      try {
        MigrationServiceHelper.migrationCallback = data.readRemoteObject();
      } catch (err) {
        LogUtils.e(TAG, `readRemoteObject failed, code: ${err?.code}, msg: ${err?.message}`);
      }
    }
  }

  /**
   * 向远端发送数据
   *
   * @param code number
   * @param data rpc.MessageSequence
   * @param reply rpc.MessageSequence
   * @param options rpc.MessageOption
   */
  public static send2Client(code: number, data: rpc.MessageSequence, reply: rpc.MessageSequence,
    options: rpc.MessageOption) {
    if (MigrationServiceHelper.migrationCallback) {
      MigrationServiceHelper.migrationCallback.sendMessageRequest(code, data, reply, options);
    } else {
      LogUtils.e(TAG, `send2Client failed, code: ${code}`);
    }
  }

  /**
   * pause时保存迁移进度信息
   *
   * @param context Context
   * @param info 迁移进度信息
   */
  public static setPauseMigrationProgress(context: Context, info: MigrationProgress) {
    LogUtils.i(TAG, `setMigrationProgress pause info: total:${info.total}, completedCount:${info.completedCount},
      failedCount:${info.failedCount}, name:${info.name}, createdAt:${info.createdAt}, lastStatus:${info.lastStatus},
      lastFailCode:${info.lastFailCode}`);
    try {
      let migrationPreferences = preferences.getPreferencesSync(context, MigrationServiceHelper.preferencesOptions);
      migrationPreferences.put(PREFERENCES_KEY, JSON.stringify(info));
      migrationPreferences.flushSync();
    } catch (err) {
      LogUtils.e(TAG, `setPauseMigrationProgress error code:${err?.code}, msg: ${err?.message}`);
    }
  }

  /**
   * 获取迁移进度信息
   *
   * @param context Context
   */
  public static getPauseMigrationProgress(context: Context): MigrationProgress | null {
    LogUtils.i(TAG, `getPauseMigrationProgress`);
    try {
      let migrationPreferences = preferences.getPreferencesSync(context, MigrationServiceHelper.preferencesOptions);
      let progressStr = migrationPreferences.getSync(PREFERENCES_KEY,
        JSON.stringify(new MigrationProgress())) as string;
      return JSON.parse(progressStr);
    } catch (err) {
      LogUtils.e(TAG, `getPauseMigrationProgress error code:${err?.code}, msg: ${err?.message}`);
      return null;
    }
  }

  /**
   * 清除迁移进度信息
   *
   * @param context Context
   */
  public static clearPauseMigrationProgress(context: Context) {
    LogUtils.i(TAG, `clearPauseMigrationProgress`);
    try {
      let migrationPreferences = preferences.getPreferencesSync(context, MigrationServiceHelper.preferencesOptions);
      migrationPreferences.clearSync();
      migrationPreferences.flushSync();
    } catch (err) {
      LogUtils.e(TAG, `clearPauseMigrationProgress error code:${err?.code}, msg: ${err?.message}`);
    }
  }

  /**
   * 发送进度信息
   *
   * @param info 迁移进度信息
   */
  public static sendMigrationProgress(info: MigrationProgress) {
    LogUtils.i(TAG, `sendMigrationProgress info: total:${info.total}, completedCount:${info.completedCount},
      failedCount:${info.failedCount}, name:${info.name}, createdAt:${info.createdAt}, lastStatus:${info.lastStatus},
      lastFailCode:${info.lastFailCode}`);
    let data = rpc.MessageSequence.create();
    data.writeInterfaceToken(RPCInfoConstant.VALIDATE_STRING);
    let reply = rpc.MessageSequence.create();
    let option = new rpc.MessageOption();
    let code = MigrationCommand.SEND_PROCESS_MIGRATION;
    data.writeInt(RPCInfoConstant.SUCCESS_STATUS_CODE);
    data.writeString(RPCInfoConstant.SUCCESS_STATUS_MESSAGE);
    data.writeString(JSON.stringify(info));
    MigrationServiceHelper.send2Client(code, data, reply, option);
    data.reclaim();
    reply.reclaim();
  }

  /**
   * 设置迁移进度标识：部分成功/全部成功
   *
   * @param store RdbStore
   * @param progress 迁移进度信息
   */
  /* instrument ignore next */
  public static setMigrationSignal(store: relationalStore.RdbStore, progress: MigrationProgress) {
    let signals: number[] = [MigrationRecordStatus.PART_MIGRATED, MigrationRecordStatus.ALL_MIGRATED];
    let signalPredicates = new relationalStore.RdbPredicates(MigrationConstant.MIGRATION_TABLE)
      .in(MigrationConstant.COLUMN_HAS_TRANSFER, signals);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = store.querySync(signalPredicates);
      if (resultSet.rowCount === 0) {
        store.insertSync(MigrationConstant.MIGRATION_TABLE, {
          id: 0,
          ori_uri: 'NA',
          new_uri: 'NA',
          has_transfer: progress.failedCount != 0 || progress.completedCount < progress.total ?
          MigrationRecordStatus.PART_MIGRATED : MigrationRecordStatus.ALL_MIGRATED
        });
      } else {
        let signalVB: relationalStore.ValuesBucket = {
          id: 0,
          has_transfer: progress.failedCount != 0 || progress.completedCount < progress.total ?
          MigrationRecordStatus.PART_MIGRATED : MigrationRecordStatus.ALL_MIGRATED
        };
        store.updateSync(signalVB, signalPredicates);
      }
    } catch (err) {
      LogUtils.e(TAG, `setMigrationSignal failed, error code:${err?.code}, msg: ${err?.message}`);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 构建待迁移数据并入库
   *
   * @param context Context
   * @param records 通话录音记录
   * @param newPathPrefix 新路径
   */
  public static async buildAndInsertMigrationRecords(context: Context, records: RecordLog[], newPathPrefix: string):
    Promise<MigrationRecord[]> {
    let valuesBuckets: ValuesBucket[] = [];
    let migrationRecords: MigrationRecord[] = [];
    let m4aRecordPaths: string[] = [];
    let amrRecordPaths: string[] = [];
    for (let index = 0; index < records.length; index++) {
      let migrationRecord = new MigrationRecord();
      migrationRecord.displayName = records[index].displayName;

      if (MigrationServiceHelper.checkAndMakeupRecordLog(records[index])) {
        migrationRecord.displayName = records[index].displayName;
        if (records[index].displayName.endsWith(MigrationConstant.FILE_NAME_M4A_SUFFIX)) {
          m4aRecordPaths.push(records[index].filePath);
        } else {
          amrRecordPaths.push(records[index].filePath)
        }
      }
      migrationRecord.recorderAdded = records[index].recorderAdded;
      migrationRecord.oriUri = records[index].filePath;
      migrationRecord.newUri = newPathPrefix + records[index].displayName;
      migrationRecords.push(migrationRecord);

      let v: ValuesBucket = {
        display_name: migrationRecord.displayName,
        ori_uri: migrationRecord.oriUri,
        new_uri: migrationRecord.newUri,
        recorder_added: migrationRecord.recorderAdded,
        has_transfer: MigrationRecordStatus.NOT_MIGRATED,
        try_times: 0
      };
      valuesBuckets[index] = v;
    }
    await MigrationServiceHelper.batchUpdateRecordLogDisplayNameWithSuffix(context, m4aRecordPaths, amrRecordPaths);
    LogUtils.i(TAG, `insert length: ${valuesBuckets.length}`);
    await MigrationServiceHelper.batchInsertMigrationRecord(context, valuesBuckets);
    return migrationRecords;
  }

  /**
   * 迁移数据批量入库
   *
   * @param context Context
   * @param migrationRecords 迁移数据
   */
  public static async batchInsertMigrationRecord(context: Context, migrationRecords: ValuesBucket[]) {
    LogUtils.i(TAG, 'batchInsertMigrationRecord');
    try {
      await taskpool.execute(batchInsertMigrationRecord, context, migrationRecords);
    } catch (err) {
      LogUtils.e(TAG, `batchInsertMigrationRecord failed, error code:${err?.code}, msg: ${err?.message}`);
    };
  }

  /**
   * 查询待迁移数据
   *
   * @param context Context
   */
  public static async queryNotMigratedRecord(context: Context): Promise<MigrationRecord[]> {
    LogUtils.i(TAG, 'queryNotMigratedRecord');
    try {
      return await taskpool.execute(queryNotMigratedRecord, context) as MigrationRecord[];
    } catch (err) {
      LogUtils.e(TAG, `queryNotMigratedRecord failed, error code:${err?.code}, msg: ${err?.message}`);
      return [];
    };
  }

  /**
   * 查询待迁移的通话录音数据
   *
   * @param context Context
   * @param pathPrefix 路径前缀
   */
  public static async queryNotMigratedRecordLog(context: Context, pathPrefix: string): Promise<RecordLog[]> {
    LogUtils.i(TAG, 'queryNotMigratedRecordLog');
    try {
      return await taskpool.execute(queryNotMigratedRecordLog, context, pathPrefix) as RecordLog[];
    } catch (err) {
      LogUtils.e(TAG, `queryNotMigrationredRecordLog failed, error code:${err?.code}, msg: ${err?.message}`);
      return [];
    };
  }

  /**
   * 补全record_log表displayName字段后缀名
   *
   * @param context Context
   * @param m4aFilePaths .m4a后缀
   * @param amrFilePaths .amr后缀
   */
  public static async batchUpdateRecordLogDisplayNameWithSuffix(context: Context, m4aFilePaths: string[],
    amrFilePaths: string[]) {
    if (m4aFilePaths.length === 0 && amrFilePaths.length === 0) {
      return;
    }
    LogUtils.i(TAG, 'batchUpdateRecordLogDisplayName');
    try {
      let autoBackupConfig: relationalStore.StoreConfig = {
        name: MigrationConstant.DATABASE,
        securityLevel: relationalStore.SecurityLevel.S1,
        haMode: relationalStore.HAMode.MAIN_REPLICA,
        allowRebuild: true
      }
      let store = await relationalStore.getRdbStore(context, autoBackupConfig);
      if (m4aFilePaths.length > 0) {
        let m4aSql = `update record_log set display_name += '.m4a' where file_path in (${m4aFilePaths.join(',')});`;
        store.executeSync(m4aSql, m4aFilePaths);
      }
      if (amrFilePaths.length > 0) {
        let amrSql = `update record_log set display_name += '.amr' where file_path in (${amrFilePaths.join(',')});`;
        store.executeSync(amrSql, amrFilePaths);
      }
    } catch (err) {
      LogUtils.e(TAG, `batchUpdateRecordLogDisplayName failed, error code:${err?.code}, msg: ${err?.message}`);
    };
  }

  /**
   * 补全RecordLog对象displayName字段后缀名
   *
   * @param record RecordLog
   */
  public static checkAndMakeupRecordLog(record: RecordLog): boolean {
    if (record.filePath.endsWith(MigrationConstant.FILE_NAME_M4A_SUFFIX) &&
      !record.displayName.endsWith(MigrationConstant.FILE_NAME_M4A_SUFFIX)) {
      record.displayName += MigrationConstant.FILE_NAME_M4A_SUFFIX;
      return true;
    }
    if (record.filePath.endsWith(MigrationConstant.FILE_NAME_AMR_SUFFIX) &&
      !record.displayName.endsWith(MigrationConstant.FILE_NAME_AMR_SUFFIX)) {
      record.displayName += MigrationConstant.FILE_NAME_AMR_SUFFIX;
      return true;
    }
    return false;
  }
}