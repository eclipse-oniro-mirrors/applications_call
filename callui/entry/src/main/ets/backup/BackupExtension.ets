/**
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

import LogUtils from '../common/utils/LogUtils';
import BackupExtensionAbility, { BundleVersion } from '@ohos.application.BackupExtensionAbility';
import { copyDataHelper } from './CopyDataHelper';
import RejectMsgPresenter from './presenter/RejectMsgPresenter';
import { contextConstant } from '@kit.AbilityKit';
import CallSettingPresenter from './presenter/CallSettingPresenter';
import { callSettingDbHelper } from './presenter/CallSettingDbHelper';

const TAG = 'BackupExtension';
const AND_PREFIX = 'and';
const ROID_SUFFIX = 'roid';
const RESTORE_PATH = `/restore/com.${AND_PREFIX}${ROID_SUFFIX}.server.telecom/de/shared_prefs`;
const RESTORE_PATH_RDB = `restore/data/storage/el2/base/haps/callui/preferences/`

/**
 * Migration Data Processing Program
 */
export default class BackupExtension extends BackupExtensionAbility {
  onBackup() {
    LogUtils.i(TAG, `onBackup init`);
  }

  async onRestoreEx(bundleVersion: BundleVersion, restoreInfo: string): Promise<string> {
    LogUtils.i(TAG, `onRestoreEx ver:${JSON.stringify(bundleVersion)} restoreInfo:${JSON.stringify(restoreInfo)}`);
    let errorInfo = '';
    try {
      await this.onRestore(bundleVersion);
    } catch (err) {
      LogUtils.e(TAG, `restore failed:${JSON.stringify(err)}`);
      errorInfo = `restore failed:${JSON.stringify(err)}`;
    }
    let resultInfo = await this.makeResultInfo(errorInfo);
    LogUtils.i(TAG, `resultInfo:${resultInfo}`);
    return resultInfo;
  }

  async makeResultInfo(errorInfo: string): Promise<string> {
    let errorInfoRecord: Record<string, ESObject> = {
      'type':'ErrorInfo',
      'errorCode': (errorInfo !== '') ? '13500099' : '0',
      'errorInfo': errorInfo
    };
    return `{"resultInfo":[${JSON.stringify(errorInfoRecord)}]}`;
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    let versionName: string | undefined = bundleVersion.name;
    AppStorage.setOrCreate('MigrateType', versionName);
    LogUtils.i(TAG, `onRestore start MigrateType:${versionName} bundleVersion:${bundleVersion.code}`);
    if (versionName.startsWith('0.0.0.0')) {
      let oldPath = this.getBackupDir() + RESTORE_PATH;
      let newPath = this.context ? this.context.preferencesDir : '';
      let isCopySuccess = copyDataHelper.copyListFile(oldPath, newPath);
      if (isCopySuccess) {
        LogUtils.i(TAG, ' migrate start ');
        RejectMsgPresenter.getInstance().init();
        await RejectMsgPresenter.getInstance().migratePrefFile(this.context!);
        LogUtils.i(TAG, ' migrate end ');
      }
    } else if (versionName === '99.99.99.999') {
      const applicationContextPath: string = this.context ? this.context.databaseDir : '';
      if (applicationContextPath) {
        let isCopyDbSuccess = false;
        let restorePath = '';
        restorePath = '/restore';
        isCopyDbSuccess = await CallSettingPresenter.getInstance().copyFiles(restorePath, applicationContextPath,
          this.context, this.context.backupDir);
        if (isCopyDbSuccess) {
          LogUtils.i(TAG, 'callSetting migrate start');
          await CallSettingPresenter.getInstance().migrateDbFile(this.context!);
          LogUtils.i(TAG, 'callSetting migrate end');
        } else {
          LogUtils.i(TAG, 'callSetting migrate failure');
        }
      } else {
        LogUtils.i(TAG, 'applicationContextPath not exist');
      }
      LogUtils.i(TAG, 'onRestore end');
    } else {
      LogUtils.i(TAG, 'dankedanStart');
      let oldPath = this.context.backupDir + RESTORE_PATH_RDB;
      let newPath = this.context ? this.context.preferencesDir : '';
      let isCopySuccess = copyDataHelper.copyListFilePre(oldPath, newPath);
      if (isCopySuccess) {
        await callSettingDbHelper.updateRejectMsg(false, this.context);
      }
      LogUtils.i(TAG, 'isCopySuccess:' + isCopySuccess);
    }
  }

  getBackupDir(): string {
    let oriArea = this.context.area;
    this.context.area = contextConstant.AreaMode.EL1;
    let backupDir = this.context.backupDir;
    this.context.area = oriArea;
    return backupDir;
  }
}
