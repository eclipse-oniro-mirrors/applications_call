/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import LogUtils from '../utils/HiLog';
import { prefUtils } from './PrefUtils';
import RestoreUtils from './RestoreUtils';
import rdb from '@ohos.data.relationalStore';
import * as RestoreConstants from './RestoreConstants';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import { common } from '@kit.AbilityKit';
import { EMERGENCY_CALL_ABILITY_CONTEXT } from '../utils/Constants';

const TAG = 'EmergencyCallBackupExtension';

export default class EmergencyCallBackupExtension extends BackupExtensionAbility {
  onBackup() {
    LogUtils.i(TAG, `onBackup`);
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    LogUtils.i(TAG, `onRestore start ver:${bundleVersion.name}_${bundleVersion.code}`);
    EmergencyGlobalContextHelper.getContext()
      .set<common.ExtensionContext>(EMERGENCY_CALL_ABILITY_CONTEXT, this.context);
    await RestoreUtils.getInstance().startRestore(this.context, bundleVersion.name);
  }

  async onRestoreEx(bundleVersion: BundleVersion, restoreInfo: string): Promise<string> {
    LogUtils.i(TAG, `onRestoreEx ver:${JSON.stringify(bundleVersion)} restoreInfo:${restoreInfo}`);
    await this.onRestore(bundleVersion);
    try {
      await rdb.deleteRdbStore(this.context, RestoreConstants.OLD_DATABASE_NAME);
      await rdb.deleteRdbStore(this.context, 'profile.db');
      await rdb.deleteRdbStore(this.context, 'calls.db');
    } catch (error) {
      LogUtils.e(TAG, `delte failed, error :${JSON.stringify(error)}`);
    }
    let resultInfo = await this.makeResultInfo();
    LogUtils.i(TAG, `resultInfo:${resultInfo}`);
    return resultInfo;
  }

  async makeResultInfo(): Promise<string> {
    let xmlStatus = await prefUtils.getStatus(RestoreConstants.PREF_XML_PARSE_STATUS_KEY, true) as boolean;
    let dbStatus = await prefUtils.getStatus(RestoreConstants.DB_READ_STATUS_KEY, true) as boolean;
    let progressInfo: string = RestoreUtils.getInstance().getProgressInfo();
    let errorInfo: string = RestoreUtils.getInstance().getErrorInfo();
    let errorInfoRecord: Record<string, ESObject> = {
      'type':'ErrorInfo',
      'errorCode': (!xmlStatus || !dbStatus) ? '13500099' : '0',
      'errorInfo': `xmlStatus:${xmlStatus} dbStatus:${dbStatus}; info1:${errorInfo}; info2:${progressInfo}`
    };
    return `{"resultInfo":[${JSON.stringify(errorInfoRecord)}]}`;
  }
}