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
import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { relationalStore } from '@kit.ArkData';
import { MigrationProgress, MigrationRecord } from '../common/struct/MigrationStruct';
import LogUtils from '../common/utils/LogUtils';
import fileIo from '@ohos.file.fs';
import { MigrationConstant, MigrationProcessStatus, MigrationRecordStatus, MigrationSpaceStatus, MigrationStatus,
  MigrationWorkerMessageType} from '../common/constant/MigrationConstant';
import { FileUtils } from '../common/utils/FileUtils';
import TimeUtil from '../common/utils/TimeUtil';
import { storageStatistics } from '@kit.CoreFileKit';

/* instrument ignore file */

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
const TAG: string = 'MigrationWorker';

/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessage = (event: MessageEvents) => {
  let type = event.data.type as string;
  LogUtils.w(TAG, `onmessage data: ${type}`);
  if (type === MigrationWorkerMessageType.MIGRATION) {
    let context = event.data.context as Context;
    let migrationDir = event.data.migrationDir as string;
    let migrationRecords = event.data.migrationRecords as MigrationRecord[];
    let progress = event.data.progress as MigrationProgress;
    let processSignal = event.data.processSignal as Int32Array;
    moveFileAndUpdateRecord(context, migrationDir, migrationRecords, progress, processSignal);
  } else if (type === MigrationWorkerMessageType.CLOSE) {
    LogUtils.w(TAG, `recieve close tpye`);
    workerPort.postMessage({ type: MigrationWorkerMessageType.CLOSE });
    workerPort.close();
  }
};

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessageerror = (event: MessageEvents) => {
};

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param event error message
 */
workerPort.onerror = (event: ErrorEvent) => {
};

/**
 * 执行迁移逻辑，先move文件，再更新数据库并发送进度
 *
 * @param context Context
 * @param migrationDir 迁移目录
 * @param migrationRecords 待迁移数据
 * @param progress 进度信息对象
 * @param processSignal 流程控制标识
 */
function moveFileAndUpdateRecord(context: Context, migrationDir: string, migrationRecords: MigrationRecord[],
  progress: MigrationProgress, processSignal: Int32Array) {
  LogUtils.w(TAG, `start moveFileAndUpdateRecord`);
  let autoBackupConfig: relationalStore.StoreConfig = {
    name: MigrationConstant.DATABASE,
    securityLevel: relationalStore.SecurityLevel.S1,
    haMode: relationalStore.HAMode.MAIN_REPLICA,
    allowRebuild: true
  }
  let promise = relationalStore.getRdbStore(context, autoBackupConfig);
  let signal = Atomics.load(processSignal, 0);
  if (progress.lastFailCode === MigrationSpaceStatus.SPACE_NOT_ENOUGH) {
    progress.lastFailCode = MigrationStatus.INVALID;
  }
  promise.then((store) => {
    for (let index = 0; index < migrationRecords.length; index++) {
      signal = Atomics.load(processSignal, 0);
      if (signal == MigrationProcessStatus.STOP || signal == MigrationProcessStatus.PAUSE) {
        LogUtils.i(TAG, 'migration progress has been stopped, return directly');
        workerPort.postMessage({ type: MigrationWorkerMessageType.SIGNAL, signal: signal, progress: progress });
        workerPort.postMessage({ type: MigrationWorkerMessageType.CLOSE });
        workerPort.close();
        return;
      }
      let record = migrationRecords[index];
      let displayName = record.oriUri.substring(record.oriUri.lastIndexOf(MigrationConstant.PATH_SEPARATOR) + 1);
      let currentSuffix = displayName.endsWith(MigrationConstant.FILE_NAME_M4A_SUFFIX) ?
        MigrationConstant.FILE_NAME_M4A_SUFFIX : MigrationConstant.FILE_NAME_AMR_SUFFIX;
      if (displayName.lastIndexOf(MigrationConstant.FILE_NAME_UNDERLINE_SEPARATOR) != -1) {
        let str = displayName.substring(displayName.lastIndexOf(MigrationConstant.FILE_NAME_UNDERLINE_SEPARATOR) + 1)
          .replace(currentSuffix, '');
        if (TimeUtil.isTimestamp(str)) {
          LogUtils.i(TAG, `str is timestamp`);
          displayName = displayName.substring(0,
            displayName.lastIndexOf(MigrationConstant.FILE_NAME_UNDERLINE_SEPARATOR)) + currentSuffix;
        }
      }
      let finalName = FileUtils.getDistinctRecordFileNameFromDir(displayName, migrationDir);
      LogUtils.i(TAG, `finalName is equal to displayName: ${finalName.length === displayName.length}`);
      record.displayName = finalName;
      record.newUri = `${migrationDir}/${finalName}`;

      progress.name = displayName;
      progress.createdAt = record.recorderAdded;
      progress.originPath = record.oriUri;
      progress.newPath = record.newUri;
      LogUtils.i(TAG, 'sendMigrationProgress');
      workerPort.postMessage({ type: MigrationWorkerMessageType.PROGRESS, progress: progress });

      // 当空间不足时，暂停迁移
      let ret = checkSpaceEnough(record.oriUri);
      if (ret === MigrationSpaceStatus.SPACE_ENOUGH) {
        let moveRet = moveFile(finalName, record.oriUri, migrationDir);
        moveRet = updateRecord(store, moveRet, record);
        progress.completedCount ++;
        progress.lastStatus = MigrationStatus.SUCCESS;
        if (!moveRet) {
          progress.failedCount ++;
          progress.lastStatus = MigrationStatus.FAILED;
        }
      } else {
        progress.failedCount ++;
        progress.lastStatus = MigrationStatus.FAILED;
        if (ret === MigrationSpaceStatus.SPACE_NOT_ENOUGH) {
          progress.lastFailCode = ret;
          break;
        }
      }
    }
    workerPort.postMessage({ type: MigrationWorkerMessageType.PROGRESS, progress: progress });
    workerPort.postMessage({ type: MigrationWorkerMessageType.SIGNAL, signal: signal, progress: progress });
    LogUtils.i(TAG, 'Migration over');
    workerPort.postMessage({ type: MigrationWorkerMessageType.CLOSE });
    workerPort.close();
  });
}

/**
 * 检查存储空间
 * 条件：当前空间最小500M，或当前空间小于待迁移的录音大小 * 1.3
 *
 * @param filePath 文件路径
 * @returns number 0：空间足够，-1：内部错误，1000：空间不足
 */
function checkSpaceEnough(filePath: string): number {
  try {
    let freeSize = storageStatistics.getFreeSizeSync();
    LogUtils.i(TAG, `freeSize: ${freeSize}`);
    if (MigrationConstant.FREE_SIZE > freeSize) {
      LogUtils.e(TAG, `space size is not enough`);
      return MigrationSpaceStatus.SPACE_NOT_ENOUGH;
    }
    if (!fileIo.accessSync(filePath)) {
      LogUtils.e(TAG, `file does not exist`);
      return MigrationSpaceStatus.SPACE_ENOUGH;
    }
    let fileStat = fileIo.statSync(filePath);
    if (fileStat === null || fileStat === undefined) {
      LogUtils.e(TAG, `fileStat is null`);
      return MigrationSpaceStatus.INTERNAL_ERROR;
    }
    LogUtils.i(TAG, `dir size: ${fileStat?.size}`);
    if (fileStat !== null && freeSize < fileStat.size * 1.3) {
      LogUtils.e(TAG, `space size is not enough`);
      return MigrationSpaceStatus.SPACE_NOT_ENOUGH;
    }
    return MigrationSpaceStatus.SPACE_ENOUGH;
  } catch (err) {
    LogUtils.e(TAG, `checkSpaceEnough failed, error code:${err?.code}, msg: ${err?.message}`);
    return MigrationSpaceStatus.INTERNAL_ERROR;
  }
}

/**
 * move文件
 * 先命名为.tmp临时文件，move完成后再重命名
 *
 * @param targetFileName 文件名
 * @param oriUri 文件原路径
 * @param migrationDir 目标文管路径
 */
function moveFile(targetFileName: string, oriUri: string, migrationDir: string) {
  let newUri = `${migrationDir}/${targetFileName}`;
  let moveRet = true;
  try {
    let fileExist = fileIo.accessSync(oriUri);
    if (fileExist) {
      let tmpNewUri = `${newUri}${MigrationConstant.FILE_NAME_TMP_SUFFIX}`;
      fileIo.moveFileSync(oriUri, tmpNewUri);
      fileIo.renameSync(tmpNewUri, newUri);
    }
  } catch (err) {
    LogUtils.e(TAG, `move file failed, error code:${err?.code}, msg: ${err?.message}`);
    moveRet = false;
  }
  return moveRet;
}

/**
 * 更新迁移数据
 *
 * @param store RdbStore
 * @param moveRet 上一步moveFile函数的结果
 * @param record 迁移数据
 */
function updateRecord(store: relationalStore.RdbStore, moveRet: boolean, record: MigrationRecord) {
  try {
    store.beginTransaction();
    if (moveRet) {
      let filePathPredicates = new relationalStore.RdbPredicates(MigrationConstant.RECORD_TABLE)
        .equalTo(MigrationConstant.COLUMN_FILE_PATH, record.oriUri);
      let filePathVB: relationalStore.ValuesBucket = {
        file_path: record.newUri,
        display_name: record.displayName
      };
      store.updateSync(filePathVB, filePathPredicates);

      let hasTransferPredicates = new relationalStore.RdbPredicates(MigrationConstant.MIGRATION_TABLE)
        .equalTo(MigrationConstant.COLUMN_ORI_URI, record.oriUri);
      let hasTransferVB: relationalStore.ValuesBucket = {
        display_name: record.displayName,
        new_uri: record.newUri,
        has_transfer: MigrationRecordStatus.MIGRATED,
        recorder_added: record.recorderAdded
      };
      store.updateSync(hasTransferVB, hasTransferPredicates);
    } else {
      let tryTimesPredicates = new relationalStore.RdbPredicates(MigrationConstant.MIGRATION_TABLE)
        .equalTo(MigrationConstant.COLUMN_ORI_URI, record.oriUri);
      let tryTimesVB: relationalStore.ValuesBucket = {
        try_times: record.tryTimes + 1,
        recorder_added: record.recorderAdded
      };
      store.updateSync(tryTimesVB, tryTimesPredicates);
    }
    store.commit();
  } catch (err) {
    LogUtils.e(TAG, `update record failed, error code:${err?.code}, msg: ${err?.message}`);
    store.rollBack();
    moveRet = false;
  }
  return moveRet;
}