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

import BackupExtensionAbility, { BundleVersion } from '@ohos.application.BackupExtensionAbility';
import LogUtils from '../common/utils/LogUtils';
import CallRecorderPresenter from '../common/utils/presenter/CallRecorderPresenter';
import CallRecorderCloneConstant from '../common/constant/CallRecorderCloneConstant';
import DatabaseHelper from '../common/utils/DatabaseHelper';
import { Constant } from '../common/constant/Constant';
import { copyDbDataHelper } from '../common/utils/CopyDbDataHelper';
import CommonController from '../common/control/CommonCtrol';
import DbBackUpProcessor from '../database/DbBackUpProcessor';

const TAG = 'BackupExtension';

/**
 * Migration Data Processing Program
 */
export default class BackupExtension extends BackupExtensionAbility {
  private result: IResultExInfo = {
    resultInfo: [
      {
        type: 'ErrorInfo',
        errorCode: '0',
        errorInfo: ''
      }, {
        type: 'CompatibilityInfo',
        next2hmos: 1
      }
    ]
  };
  private errorResult: IErrorExInfo = {
    resultInfo: [
      {
        type: 'ErrorInfo',
        errorCode: '13500088',
        errorInfo: ''
      }
    ]
  };

  async onBackupEx(backupInfo: string): Promise<string> {
    copyDbDataHelper.isBackup = true;
    LogUtils.i(TAG, 'onBackupEx')
    await CallRecorderPresenter.getInstance().copyGroupAudioFileBeforeBackup(this.context);
    let infos: infos[] | undefined;
    try {
      infos = JSON.parse(backupInfo);
    } catch (err) {
      LogUtils.e(TAG, `onBackupEx err code:${err?.code}, msg:${err?.message}`);
    }
    if (!infos || infos.length <= 0) {
      LogUtils.i(TAG, 'onBackupEx error');
      return '';
    }
    if (infos[0].detail === 'next2hmos') {
      LogUtils.i(TAG, 'onBackupEx start back up');
      let backUpResult = await DbBackUpProcessor.getInstance().startBackUp(this.context);
      LogUtils.i(TAG, 'onBackupEx start back up end, result = ' + backUpResult);
      if (!backUpResult || backUpResult === '') {
        return JSON.stringify(this.result);
      }
      return JSON.stringify(this.errorResult);
    }
    return '';
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    LogUtils.i(TAG, `onRestore start, bundleVersion code: ${bundleVersion.code}, name: ${bundleVersion.name}`);
    try {
      await this.processRestore(bundleVersion);
    } catch (err) {
      LogUtils.e(TAG, `onRestore err code:${err?.code}, msg: ${err?.message}`);
    }
  }

  async processRestore(bundleVersion: BundleVersion): Promise<void> {
    let versionName: string | undefined = bundleVersion.name;
    if (versionName.startsWith(CallRecorderCloneConstant.UPGRADE_VERSION_NAME)) {
      versionName = CallRecorderCloneConstant.UPGRADE_VERSION_NAME;
    }
    await this.checkAndInitNewDb();
    AppStorage.setOrCreate('MigrateType', versionName);
    LogUtils.i(TAG, `bundleVersion:${bundleVersion.code}`);
    const applicationContextPath: string = this.context ? this.context.databaseDir : '';
    if (applicationContextPath) {
      let isCopyDbSuccess = false;
      let restorePath = '';
      isCopyDbSuccess = await CallRecorderPresenter.getInstance().copyFiles(restorePath, applicationContextPath,
        this.context, this.context.backupDir);
      if (isCopyDbSuccess) {
        LogUtils.i(TAG, 'callRecord  migrate start');
        CallRecorderPresenter.getInstance().init();
        await CallRecorderPresenter.getInstance().migrateDbFile(this.context!);
        LogUtils.i(TAG, 'callRecord  migrate end');
      }
    } else {
      LogUtils.i(TAG, 'applicationContextPath not exist');
    }
  }

  async checkAndInitNewDb(): Promise<void> {
    try {
      await DatabaseHelper.getInstance().getDatabaseInfo(Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_LOG,
        this.context);
    } catch (err) {
      LogUtils.e(TAG, `checkAndInitNewDb err code:${err?.code}, msg: ${err?.message}`);
    }
  }

  async onRestoreEx(bundleVersion: BundleVersion, restoreInfo: string): Promise<string> {
    copyDbDataHelper.isBackup = false;
    LogUtils.i(TAG,
      `onRestoreEx begin bundleVersion code:${bundleVersion.code},name:${bundleVersion.name},restoreInfo:${restoreInfo}`);
    await this.onRestore(bundleVersion);
    await CommonController.getInstance().notifyRecordLogChange(this.context);
    let restoreResult = copyDbDataHelper.getCopyFileResultInfo();
    LogUtils.i(TAG, `onRestoreEx end restoreResult:${restoreResult}`);
    return restoreResult;
  }

  onProcess(): string {
    LogUtils.i(TAG, 'onProcess');
    return copyDbDataHelper.getCopyFileProgressInfo();
  }
}

interface infos {
  type: string;
  detail: string;
}

export interface IResultExInfo {
  resultInfo: [IResultErrorInfo, IResultTypeInfo];
}

export interface IErrorExInfo {
  resultInfo: [IResultErrorInfo];
}

export interface IResultErrorInfo {
  type: string;
  errorCode: string;
  errorInfo: string;
}

export interface IResultTypeInfo {
  type: string;
  next2hmos: number;
}
