/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import MigrationServiceExtStub from './MigrationServiceExtStub';
import common from '@ohos.app.ability.common';
import LogUtils from '../common/utils/LogUtils';
import { FileUtils } from '../common/utils/FileUtils';
import { MigrationProgress, MigrationRecord, MigrationResult } from '../common/struct/MigrationStruct';
import DatabaseHelper from '../common/utils/DatabaseHelper';
import { isPhone, isTablet } from '../common/utils/CommonUtil';
import { ErrorEvent, MessageEvents, worker } from '@kit.ArkTS';
import { relationalStore } from '@kit.ArkData';
import { MigrationServiceHelper } from './MigrationServiceHelper';
import { MigrationConstant, MigrationLockStatus, MigrationWorkerMessageType, StartMigrationCallBack,
  MigrationProcessStatus,
  MigrationSpaceStatus} from '../common/constant/MigrationConstant';
import { storageStatistics } from '@kit.CoreFileKit';

const TAG: string = 'MigrationServiceExtImpl';

export default class MigrationServiceExtImpl extends MigrationServiceExtStub {
  public static signalSab: SharedArrayBuffer = new SharedArrayBuffer(MigrationConstant.ARRAY_BUFFER_SIZE);
  public static processSignal = new Int32Array(MigrationServiceExtImpl.signalSab);

  public useContext: Context;

  private migrationDir: string = '';
  private groupDir: string = '';
  private isMigrationDirInvalid: boolean = true;
  private isGroupDirInvalid: boolean = true;
  private isMigrationDBInit: boolean = true;

  private workerInstance?: worker.ThreadWorker;
  private currentProgress: MigrationProgress = new MigrationProgress();

  constructor(context: common.Context) {
    super('MigrationServiceExtImpl');
    this.useContext = context;
    MigrationServiceExtImpl.processSignal[0] = MigrationProcessStatus.RUNNING; // 初始值为 0
    MigrationServiceExtImpl.processSignal[1] = MigrationLockStatus.UNLOCKED; // 初始锁状态为 0（未锁定）
  }

  public startMigrationService(callback: StartMigrationCallBack) {
    this.startMigration().then((info) => {
      callback(info.errCode, info.message);
    });
  }

  public stopMigrationService() {
    LogUtils.i(TAG, `stopMigrationService`);
    Atomics.store(MigrationServiceExtImpl.processSignal, 0, MigrationProcessStatus.STOP);
    MigrationServiceHelper.clearPauseMigrationProgress(this.useContext);
    LogUtils.i(TAG, 'stop process signal: ' + MigrationServiceExtImpl.processSignal);
  }

  public pauseMigrationService() {
    LogUtils.i(TAG, `pauseMigrationService`);
    Atomics.store(MigrationServiceExtImpl.processSignal, 0, MigrationProcessStatus.PAUSE);
    LogUtils.i(TAG, 'pause process signal: ' + MigrationServiceExtImpl.processSignal);
  }

  public resumeMigrationService(callback: StartMigrationCallBack) {
    LogUtils.i(TAG, `resumeMigrationService`);
    let progress = MigrationServiceHelper.getPauseMigrationProgress(this.useContext);
    if (progress === null) {
      LogUtils.w(TAG, `pause progress does not exist, will restart migration`);
      progress = new MigrationProgress();
    }
    MigrationServiceHelper.clearPauseMigrationProgress(this.useContext);
    Atomics.store(MigrationServiceExtImpl.processSignal, 0, MigrationProcessStatus.RESUME);
    this.workerInstance = undefined;
    this.startMigrationInner(new MigrationResult(), progress).then((info) => {
      callback(info.errCode, info.message);
    });
  }

  /**
   * 开始迁移任务
   */
  private async startMigration(): Promise<MigrationResult> {
    let result = new MigrationResult();
    LogUtils.i(TAG, `migration start time: ${new Date().toTimeString()}`);
    if (!isPhone() && !isTablet()) {
      LogUtils.w(TAG, `not supported`);
      result.setInternalError();
      return result;
    }
    this.isMigrationDBInit = await DatabaseHelper.getInstance().initMigrationDB(this.useContext);
    LogUtils.i(TAG, `initMigrationDB: ${this.isMigrationDBInit}`);
    if (!this.isMigrationDBInit) {
      LogUtils.e(TAG, `migration db not inited`);
      result.setInternalError();
      return result;
    }
    this.migrationDir = FileUtils.getCallRecordMigrationDir();
    this.isMigrationDirInvalid = (this.migrationDir === '');
    LogUtils.i(TAG, `isMigrationDirInvalid: ${this.isMigrationDirInvalid}`);
    if (this.isMigrationDirInvalid) {
      LogUtils.e(TAG, `migrationDir is invalid`);
      result.setInternalError();
      return result;
    }
    this.groupDir = await FileUtils.getCallRecordGroupDir(this.useContext);
    this.isGroupDirInvalid = (this.groupDir === '');
    LogUtils.i(TAG, `isGroupDirInvalid: ${this.isGroupDirInvalid}`);
    if (this.isGroupDirInvalid) {
      LogUtils.e(TAG, `groupDir is invalid`);
      result.setInternalError();
      return result;
    }
    
    Atomics.store(MigrationServiceExtImpl.processSignal, 0, MigrationProcessStatus.RUNNING);
    this.workerInstance = undefined;
    return await this.startMigrationInner(result, this.currentProgress);
  }

  /**
   * 启动迁移任务
   *
   * @param result 启动结果
   * @param progress 进度信息对象
   */
  private async startMigrationInner(result: MigrationResult, progress: MigrationProgress): Promise<MigrationResult> {
    let autoBackupConfig: relationalStore.StoreConfig = {
      name: MigrationConstant.DATABASE,
      securityLevel: relationalStore.SecurityLevel.S1,
      haMode: relationalStore.HAMode.MAIN_REPLICA,
      allowRebuild: true
    }
    let oriPath = this.groupDir;
    let newPathPrefix = `${this.migrationDir}/`;
    LogUtils.i(TAG, `start get migration records`);
    let store = await relationalStore.getRdbStore(this.useContext, autoBackupConfig);
    let migrationRecords = await MigrationServiceHelper.queryNotMigratedRecord(this.useContext);
    LogUtils.i(TAG, `migrationRecords length: ${migrationRecords.length}`);
    // instrument ignore if
    if (migrationRecords.length === 0) {
      let records = await MigrationServiceHelper.queryNotMigratedRecordLog(this.useContext, oriPath);
      LogUtils.i(TAG, `recordLogs length: ${records.length}`);
      if (records.length === 0) {
        LogUtils.w(TAG, `migration records not exist`);
        progress.total = 0;
        progress.completedCount = 0;
        progress.failedCount = 0;
        MigrationServiceHelper.setMigrationSignal(store, progress);
        MigrationServiceHelper.sendMigrationProgress(progress);
        return result;
      }
      migrationRecords = await MigrationServiceHelper.buildAndInsertMigrationRecords(this.useContext, records,
        newPathPrefix);
    }
    if (progress.total === MigrationConstant.INIT_VALUE) {
      progress.total = migrationRecords.length;
    }
    migrationRecords.sort((a, b) => {
      return a.recorderAdded - b.recorderAdded;
    });
    this.startMigrationWorker(result, store, migrationRecords, progress);
    return result;
  }

  /**
   * 启动迁移子线程worker
   *
   * @param result 启动结果
   * @param store RdbStore
   * @param migrationRecords 待迁移数据
   * @param progress 进度信息对象
   */
  /* instrument ignore next */
  public startMigrationWorker(result: MigrationResult, store: relationalStore.RdbStore,
    migrationRecords: MigrationRecord[], progress: MigrationProgress) {
    LogUtils.w(TAG, `start create worker`);
    try {
      if (!this.workerInstance) {
        LogUtils.i(TAG, `init migration worker`);
        this.workerInstance = new worker.ThreadWorker('entry/ets/workers/MigrationWorker.ets');
      }
    } catch (err) {
      LogUtils.e(TAG, `init migration worker failed, error code:${err?.code}, msg: ${err?.message}`);
      result.setInternalError();
      return;
    }

    // 注册onmessage回调，当宿主线程接收到来自其创建的Worker通过workerPort.postMessage接口发送的消息时被调用，在宿主线程执行
    this.workerInstance.onmessage = (event: MessageEvents) => {
      let type = event.data.type as string;

      if (type === MigrationWorkerMessageType.CLOSE) {
        LogUtils.w(TAG, `onmessage close`);
        if (this.workerInstance) {
          this.workerInstance.terminate();
          this.workerInstance = undefined;
        }
        LogUtils.i(TAG, `migration finish time: ${new Date().toTimeString()}`);
      } else if (type === MigrationWorkerMessageType.PROGRESS) {
        this.currentProgress = event.data.progress as MigrationProgress;
        MigrationServiceHelper.sendMigrationProgress(this.currentProgress);
      } else if (type === MigrationWorkerMessageType.SIGNAL) {
        LogUtils.i(TAG, 'on message signal');
        let signal = event.data.signal as number;
        this.currentProgress = event.data.progress as MigrationProgress;
        if (signal === MigrationProcessStatus.PAUSE ||
          this.currentProgress.lastFailCode == MigrationSpaceStatus.SPACE_NOT_ENOUGH) {
          Atomics.store(MigrationServiceExtImpl.processSignal, 0, MigrationProcessStatus.PAUSE);
          MigrationServiceHelper.setPauseMigrationProgress(this.useContext, this.currentProgress);
        } else if (this.currentProgress.total === this.currentProgress.completedCount) {
          LogUtils.i(TAG, 'migration is completed');
          Atomics.store(MigrationServiceExtImpl.processSignal, 0, MigrationProcessStatus.COMPLETE);
        }
        MigrationServiceHelper.setMigrationSignal(store, this.currentProgress);
      }
    }

    this.workerInstance.onerror = (err: ErrorEvent) => {
      LogUtils.w(TAG, `workerInstance onerror message is: ${err.message}`);
    }
    this.workerInstance.onmessageerror = () => {
      LogUtils.w(TAG, 'workerInstance onmessageerror');
    }
    this.workerInstance.onexit = (e: number) => {
      // 当Worker正常退出时code为0，异常退出时code为1
      LogUtils.w(TAG, `workerInstance onexit code is: ${e}`);
    }
    this.workerInstance.postMessage({ type: MigrationWorkerMessageType.MIGRATION, context: this.useContext,
      migrationDir: this.migrationDir, migrationRecords: migrationRecords, progress: progress,
      processSignal: MigrationServiceExtImpl.processSignal });
  }

  /**
   * onDisconnect时停止迁移，关闭worker
   */
  public stopMigrationWhenOnDisconnect() {
    let signal = Atomics.load(MigrationServiceExtImpl.processSignal, 0);
    if (signal == MigrationProcessStatus.RUNNING || signal == MigrationProcessStatus.RESUME) {
      // 连接意外中断时，当作pause处理，便于下次直接恢复
      LogUtils.i(TAG, `on disconnect exceptionly`);
      Atomics.store(MigrationServiceExtImpl.processSignal, 0, MigrationProcessStatus.PAUSE);
    } else if (signal == MigrationProcessStatus.COMPLETE){
      LogUtils.i(TAG, `migration is already completed`);
      return;
    }
    if (this.workerInstance) {
      LogUtils.i(TAG, `terminate migration worker`);
      this.workerInstance.terminate();
      this.workerInstance = undefined;
    }
  }
}
