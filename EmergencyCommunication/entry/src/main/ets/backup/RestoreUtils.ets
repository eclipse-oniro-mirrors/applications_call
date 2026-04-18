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

import LogUtils from '../utils/HiLog';
import common from '@ohos.app.ability.common';
import { fileUtils } from './FileUtils';
import { contactsRdbHelper } from '../backup/ContactsRdbHelper';
import * as Constants from './RestoreConstants';
import { prefUtils } from './PrefUtils';
import BackupExtensionContext from '@ohos.file.BackupExtensionContext';
import { contextConstant } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { fileIo } from '@kit.CoreFileKit';
import { settings } from '@kit.BasicServicesKit';
import { Utils } from '../utils/Utils';
import { EmergencyInfoStruct } from '../utils/ClassStruct';
import { DataStorageUtil } from '../utils/DataStorageUtil';
import * as storageUtil from '../utils/DataStorageUtil';

const TAG = 'RestoreUtils';

export default class RestoreUtils {
  private static instance: RestoreUtils;
  private progressInfo: string = '';
  private errorInfo: string = '';

  /**
   * Get RestoreUtil instance.
   *
   * @returns { RestoreUtil } The RestoreUtil instance.
   */
  public static getInstance(): RestoreUtils {
    if (RestoreUtils.instance == null || RestoreUtils.instance == undefined) {
      RestoreUtils.instance = new RestoreUtils();
    }
    return RestoreUtils.instance;
  }

  private async init(context: common.Context): Promise<boolean> {
    if (!context) {
      LogUtils.e(TAG, 'init context invalid');
      return false;
    }

    let isPrefInitSuccess: boolean = await prefUtils.init(context);
    if (!isPrefInitSuccess) {
      LogUtils.e(TAG, 'init init pref failed');
      return false;
    }
    return true;
  }

  /**
   * Restore from dual-framework to single-framework
   */
  public async startRestore(context: common.Context, dataMigrationType: string): Promise<void> {
    let isInitSuccess: boolean = await this.init(context);
    if (!isInitSuccess) {
      LogUtils.e(TAG, 'startRestore init failed');
      return;
    }

    LogUtils.i(TAG, 'startRestore data migration type:' + dataMigrationType);
    if (dataMigrationType.startsWith(Constants.RestoreVersion.VER_DUAL_UPGRADE_TO_SINGLE)) {
      await this.startMig(context);
    } else if (dataMigrationType.startsWith(Constants.RestoreVersion.VER_DUAL_CLONE_TO_SINGLE)) {
      LogUtils.i(TAG, 'startRestore hm2Next data migration type:' + dataMigrationType);
      let contextBack: BackupExtensionContext = context as BackupExtensionContext
      await this.copyhm2NextFiles('restore', contextBack ? contextBack.databaseDir : '',
        contextBack, contextBack.backupDir)
    } else {
      LogUtils.i(TAG, 'startRestore NEXT2NEXT data migration type:' + dataMigrationType);
      await this.startNextToNextMig(context);
    }
  }

  private async copyhm2NextFiles(clonePath: string, applicationContextPath: string, context: common.Context,
    backupDir: string) {
    if (context === null || context === undefined) {
      LogUtils.e(TAG, 'copyhm2NextFiles current context is null or undefined');
      return;
    }

    try {
      let dstPath = applicationContextPath + '/rdbtmp';
      let isDesClonePathExists: boolean = fileIo.accessSync(dstPath);
      if (!isDesClonePathExists) {
        fs.mkdirSync(dstPath);
      }
      fileUtils.copyFilesByDir(`${backupDir}/${clonePath}`, dstPath);
    } catch (err) {
      LogUtils.e(TAG, `copyhm2NextFiles  err:${err?.message}`);
    }

    await contactsRdbHelper.queryEmergencyInfoSubData(context, Constants.EMERGENCY_INFO_TB);
    await contactsRdbHelper.queryEmergencyInfoSubData(context, Constants.EMERGENCY_CONTACT_TB);
    await contactsRdbHelper.queryEmergencyInfoSubData(context, Constants.EMERGENCY_DIAL_SOS_NUMBER_SWITCH_TB);
    await contactsRdbHelper.queryEmergencyInfoSubData(context, Constants.EMERGENCY_SEND_SOS_SMS_SWITCH_TB);
  }

  private async startNextToNextMig(context: common.Context): Promise<void> {
    try {
      await this.startNextToNextProcess(context);
    } catch (err) {
      LogUtils.e(TAG, `startNextToNextProcess mig err:${err?.message}`);
    }
  }

  private async startNextToNextProcess(context: common.Context): Promise<void> {
    LogUtils.i(TAG, `startNextToNextProcess Start!`);
    await this.copyNextToNextFiles(context as BackupExtensionContext);
  }

  private async copyNextToNextFiles(context: BackupExtensionContext): Promise<void> {
    LogUtils.i(TAG, `copyNextToNextFiles Start!`);
    let oriContextArea = context.area;
    context.area = contextConstant.AreaMode.EL2;
    let el2FileBackupDir = context.backupDir;
    context.area = oriContextArea;

    let newEmergencyInfo: EmergencyInfoStruct = { name: '', address: '', bloodType: '', allergicReaction: '',
      drug: '', isOrganDonor: '', drugStatusAndNotice: ''};
    await contactsRdbHelper.queryEmergencyInfoData('', newEmergencyInfo);

    let  newEmergencyContact = DataStorageUtil.getInstance().getEmergencyContactsSync(context) || [];

    DataStorageUtil.getInstance().removeInfoPreferencesFromCacheSync(context);
    DataStorageUtil.getInstance().removePreferencesFromCacheSync(context);

    let isPrefCopySuccess =
      fileUtils.copyFilesByDir(el2FileBackupDir + Constants.NEXT_TO_NEXT_OLD_PREF_DIR, context.preferencesDir, false);
    LogUtils.i(TAG, `end copyFile check isPrefCopySuccess:` + isPrefCopySuccess);

    await storageUtil.getEmergencyInfo();
    DataStorageUtil.getInstance().getContactsPreferencesSync(context);

    let oldEmergencyInfo: EmergencyInfoStruct = { name: '', address: '', bloodType: '', allergicReaction: '',
      drug: '', isOrganDonor: '', drugStatusAndNotice: ''};
    await contactsRdbHelper.queryEmergencyInfoData('', oldEmergencyInfo);

    let oldEmergencyContact = DataStorageUtil.getInstance().getEmergencyContactsSync(context) || [];

    contactsRdbHelper.oldEmergencyInfoData2New(oldEmergencyInfo, newEmergencyInfo);
    contactsRdbHelper.oldEmergencyContact2New(oldEmergencyContact, newEmergencyContact);
  }

  private async startMig(context: common.Context): Promise<void> {
    try {
      await this.startProcess(context);
    } catch (err) {
      LogUtils.e(TAG, `mig err:${JSON.stringify(err)}`);
    }
  }

  private async startProcess(context: common.Context): Promise<void> {
    let curProgress =
      await prefUtils.getStatus(Constants.RESTORE_PROGRESS_KEY, Constants.RestoreProgress.INIT) as number;
    LogUtils.i(TAG, `startMig progress:${curProgress}`);
    if (Constants.RestoreProgress.RESTORE_SUCCESS === curProgress) {
      return;
    }
    await prefUtils.saveToPref(Constants.RESTORE_PROGRESS_KEY, Constants.RestoreProgress.INIT);

    await this.copyFiles(context as BackupExtensionContext);
    let isParseXmlSuccess = await this.parseXmlToPref(context);
    if (!isParseXmlSuccess) {
      LogUtils.i(TAG, 'startMig parse contact from xml failed');
      RestoreUtils.getInstance().appendResultInfo('no old contact list, no need restore.');
    }

    let isParseDbSuccess = await this.getContactFromDb(context);
    if (!isParseDbSuccess) {
      LogUtils.i(TAG, 'startMig get contact from database failed');
    }

    if (!isParseDbSuccess || !isParseXmlSuccess) {
      return;
    }

    await prefUtils.saveToPref(Constants.RESTORE_PROGRESS_KEY, Constants.RestoreProgress.RESTORE_SUCCESS);
  }

  private async copyFiles(context: BackupExtensionContext): Promise<void> {
    // 1. move shared pref xml file to context shared pref dir
    let isPrefCopySuccess: boolean = await prefUtils.getStatus(Constants.COPY_PREF_STATUS_KEY, false) as boolean;
    LogUtils.i(TAG, `enter copyFile check isPrefCopySuccess:${isPrefCopySuccess}`);
    if (!isPrefCopySuccess) {
      let oriContextArea = context.area;
      context.area = contextConstant.AreaMode.EL1;
      let el1FileBackupDir = context.backupDir;
      context.area = oriContextArea;
      isPrefCopySuccess = fileUtils.copyFilesByDir(el1FileBackupDir + Constants.OLD_PREF_DIR, context.preferencesDir);
      LogUtils.i(TAG, `copyPref result:${isPrefCopySuccess}`);
      await prefUtils.saveToPref(Constants.COPY_PREF_STATUS_KEY, isPrefCopySuccess);
    }

    // 2. move db file to context shared pref dir
    let isDbCopySuccess: boolean = await prefUtils.getStatus(Constants.COPY_DB_STATUS_KEY, false) as boolean;
    LogUtils.i(TAG, `enter copyFile check isDbCopySuccess:${isDbCopySuccess}`);
    if (!isDbCopySuccess) {
      isDbCopySuccess = fileUtils.copyFilesByDir(context.backupDir + Constants.OLD_DB_DIR, context.databaseDir, true);
      LogUtils.i(TAG, `copyDb result: ${isDbCopySuccess}`);
      await prefUtils.saveToPref(Constants.COPY_DB_STATUS_KEY, isDbCopySuccess);
    }
  }

  private async parseXmlToPref(context: common.Context): Promise<boolean> {
    let isParseSuccess: boolean = await prefUtils.getStatus(Constants.PREF_XML_PARSE_STATUS_KEY, false) as boolean;
    LogUtils.i(TAG, `enter parseXmlToPref check isParseSuccess:${isParseSuccess}`);
    if (!isParseSuccess) {
      let oldPrefXmlFilePath = `${context.preferencesDir}/${Constants.OLD_EM_XML_NAME}`;
      let isPrefFileExists = fileUtils.isFileAccessibleSync(oldPrefXmlFilePath);
      RestoreUtils.getInstance().appendResultInfo(`parseXmlToPref PrefFileExists:${isPrefFileExists};`);
      if (!isPrefFileExists) {
        LogUtils.i(TAG, 'no old emergency info file, cannot restore');
        await prefUtils.saveToPref(Constants.PREF_XML_PARSE_STATUS_KEY, true);
        await prefUtils.saveToPref(Constants.DB_READ_STATUS_KEY, true);
        return true;
      }

      isParseSuccess = await fileUtils.parseXmlToPref(oldPrefXmlFilePath);
      LogUtils.i(TAG, `enter parseXmlToPref result:${isParseSuccess}`);
      await prefUtils.saveToPref(Constants.PREF_XML_PARSE_STATUS_KEY, isParseSuccess);
      RestoreUtils.getInstance().appendResultInfo(`parseXmlToPref result:${isParseSuccess};`);
      if (isParseSuccess) {
        let parsedOldContactUriList = await prefUtils.getOldEmContactsUriList();
        if (!parsedOldContactUriList || parsedOldContactUriList === '') {
          LogUtils.i(TAG, 'after parseXmlToPref success, get empty old contact list, no need query db');
          await prefUtils.saveToPref(Constants.DB_READ_STATUS_KEY, true);
          RestoreUtils.getInstance().appendResultInfo('no old contact list, no need restore.');
        }
      }
    }
    return isParseSuccess;
  }

  private async getContactFromDb(context: common.Context): Promise<boolean> {
    let isDbReadSuccess: boolean = await prefUtils.getStatus(Constants.DB_READ_STATUS_KEY, false) as boolean;
    LogUtils.i(TAG, `enter getContactFromDb check isDbReadSuccess:${isDbReadSuccess}`);
    if (!isDbReadSuccess) {
      isDbReadSuccess = await contactsRdbHelper.restoreContactsFromDb(context);
      await prefUtils.saveToPref(Constants.DB_READ_STATUS_KEY, isDbReadSuccess);
      RestoreUtils.getInstance().appendResultInfo(`getContactFromDb result:${isDbReadSuccess};`);

      let sosSmsSwitch = settings.getValueSync(context, Constants.AUTO_SEND_SOS_SMS_SWITCH, '0');
      let sosNumberSwitch = settings.getValueSync(context, Constants.AUTO_DIAL_SOS_NUMBER_SWITCH, '0');
      let smsSwitch = sosSmsSwitch === Constants.AUTO_SEND_SOS_SMS_SWITCH_ON;
      let numberSwitch = sosNumberSwitch === Constants.AUTO_DIAL_SOS_NUMBER_SWITCH_ON;
      LogUtils.i(TAG, `getContactFromDb smsSwitch:${sosSmsSwitch} numberSwitch:${sosNumberSwitch}`);
      Utils.setAutoSendSosSmsSwitch(context, smsSwitch);
      Utils.setAutoDialSosNumberSwitch(context, numberSwitch);
    }
    return isDbReadSuccess;
  }

  public async checkNeedContinueRestore(context: common.Context): Promise<void> {
    let isInitSuccess: boolean = await this.init(context);
    if (!isInitSuccess) {
      LogUtils.e(TAG, 'checkNeedContinueRestore init failed');
      return;
    }

    let isCheckedFromAbility: boolean = await prefUtils.getStatus(Constants.RESTORE_FROM_ABILITY, false) as boolean;
    if (!isCheckedFromAbility) {
      let curProgress: number = await prefUtils.getStatus(Constants.RESTORE_PROGRESS_KEY,
        Constants.RestoreProgress.STATUS_UNKNOWN) as number;
      LogUtils.i(TAG, `checkNeedContinueRestore curProgress:${curProgress}`);
      if (Constants.RestoreProgress.INIT === curProgress) {
        await prefUtils.saveToPref(Constants.RESTORE_FROM_ABILITY, true);
        await this.startMig(context);
      }
    }
  }

  getProgressInfo(): string {
    return this.progressInfo;
  }

  appendResultInfo(newInfo: string): void {
    this.progressInfo = this.progressInfo + newInfo;
  }

  getErrorInfo(): string {
    return this.errorInfo;
  }

  appendErrorInfo(newInfo: string): void {
    this.errorInfo = this.errorInfo + newInfo;
  }
}
