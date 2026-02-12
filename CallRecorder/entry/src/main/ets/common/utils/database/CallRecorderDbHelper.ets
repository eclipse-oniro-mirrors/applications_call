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

import rdb from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import LogUtils from '../LogUtils';
import CallRecorderCloneConstant from '../../constant/CallRecorderCloneConstant';
import CallRecorderSingleConstant from '../../constant/CallRecorderSingleConstant';
import HashMap from '@ohos.util.HashMap';
import { FileUtils, RECORD_DIR_ON_DUAL, TYPE_DUAL2NEXT, TYPE_NEXT2NEXT } from '../FileUtils';
import CallRecorderDualConstant from '../../constant/CallRecorderDualConstant';
import { copyDbDataHelper } from '../CopyDbDataHelper';

const TAG = 'CallRecorderDbHelper';

class CallRecorderDbHelper {
  private rdbStoreHelper?: rdb.RdbStore;
  public totalPath: string = '';
  public filepath: string | undefined = '';
  public migrateType: string | undefined = '';
  public isFromHm: boolean = false;
  private oldDualDbName = CallRecorderCloneConstant.CALL_RECORDER_CLONE_DB_NAME;
  private oldNextDbName = CallRecorderCloneConstant.CALL_RECORDER_CLONE_NEXT_DB_NAME;
  private oldDualContactTable = CallRecorderCloneConstant.CONTACT_TB;
  private oldNextContactTable = CallRecorderSingleConstant.RECORD_CONTACT_TB_NAME;

  protected async getMigrateType() {
    LogUtils.i(TAG, 'getMigrateType start');
    if (AppStorage.has('MigrateType')) {
      this.migrateType = AppStorage.get('MigrateType');
      this.isFromHm = (this.migrateType === CallRecorderCloneConstant.CLONE_VERSION_NAME);
      LogUtils.i(TAG, `MigrateType:${this.migrateType} isFromHm:${this.isFromHm}`);
    }
  }

  async delOldSingleDb(context: common.Context): Promise<void> {
    try {
      await rdb.deleteRdbStore(context, this.oldNextDbName);
    } catch (error) {
      LogUtils.e(TAG, `delOldSingleDb failed:${JSON.stringify(error)}`);
    }
  }

  private async initDB(context: common.Context): Promise<undefined | rdb.RdbStore> {
    LogUtils.i(TAG, 'initDB start');
    try {
      this.getMigrateType();
      const OLD_CONFIG: rdb.StoreConfig = {
        name: this.isFromHm ? this.oldDualDbName : this.oldNextDbName,
        securityLevel: this.isFromHm ? rdb.SecurityLevel.S2 : rdb.SecurityLevel.S1
      };
      this.rdbStoreHelper = await rdb.getRdbStore(context, OLD_CONFIG);
      return this.rdbStoreHelper;
    } catch (error) {
      LogUtils.e(TAG, `CallRecorderDbHelper initDB failed:${JSON.stringify(error)}`);
    }
    return undefined;
  }

  public async queryCount(context: common.Context, tableName: string): Promise<number> {
    let count = 0;
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return Promise.resolve(0);
      }
      let queryColumn = ['count(1)'];
      let predicatesInfo = new rdb.RdbPredicates(tableName);
      let resultSet = await rdbStore.query(predicatesInfo, queryColumn);
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
        LogUtils.i(TAG, `queryCount count : ${count}`);
      }
      resultSet.close();
      await rdbStore.close();
    } catch (error) {
      LogUtils.e(TAG, 'queryCount error');
    }
    return Promise.resolve(count);
  }

  public async queryCallRecorder(context: common.Context, startIndex: number,
    recordLogMap: HashMap<string, number>): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'queryCallRecorder start');
    let callRecodeResult: ValuesBucket[] = [];
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return callRecodeResult;
      }
      let resultSet: rdb.ResultSet | undefined = undefined;
      if (this.migrateType == CallRecorderCloneConstant.CLONE_VERSION_NAME) {
        let predicatesInfo = new rdb.RdbPredicates(CallRecorderCloneConstant.RECORDER_FILE_TB);
        predicatesInfo
          .orderByAsc(CallRecorderCloneConstant.RECORD_ID)
          .limitAs(CallRecorderCloneConstant.QUERY_PAGE_NUM)
          .offsetAs(startIndex);
        resultSet = await rdbStore.query(predicatesInfo, CallRecorderCloneConstant.CALL_RECORDER_CLONE_RECORD);
      } else {
        let predicatesInfo = new rdb.RdbPredicates(CallRecorderSingleConstant.RECORD_LOG_TB_NAME);
        predicatesInfo
          .orderByAsc(CallRecorderSingleConstant.ID)
          .limitAs(CallRecorderCloneConstant.QUERY_PAGE_NUM)
          .offsetAs(startIndex);
        resultSet = await rdbStore.query(predicatesInfo);
      }
      if (resultSet.goToFirstRow()) {
        if (this.migrateType == CallRecorderCloneConstant.CLONE_VERSION_NAME) {
          await this.convertToValuesBucket(resultSet, callRecodeResult, context, recordLogMap);
        } else {
          this.convertToValuesBucketForNext2Next(resultSet, callRecodeResult, recordLogMap);
        }
      } else {
        LogUtils.i(TAG, 'queryCallRecorder no callRecord found ...');
      }
      resultSet.close();
    } catch (err) {
      LogUtils.e(TAG, 'queryCallRecorder error');
    }
    return Promise.resolve(callRecodeResult);
  }

  public async convertToValuesBucket(resultSet: rdb.ResultSet, callRecodeResult: ValuesBucket[],
    context: common.Context, recordLogMap: HashMap<string, number> = new HashMap<string, number>()): Promise<void> {
    LogUtils.i(TAG, 'convertToValuesBucket start size:' + resultSet.rowCount);
    do {
      let valuesBucket: ValuesBucket = {};
      let duration: number = resultSet.getLong(resultSet.getColumnIndex(CallRecorderCloneConstant.DURATION));
      valuesBucket[CallRecorderSingleConstant.DURATION] = duration;
      let title = resultSet.getString(resultSet.getColumnIndex(CallRecorderCloneConstant.TITLE));
      let filePath = resultSet.getString(resultSet.getColumnIndex(CallRecorderCloneConstant.DATA));
      if (this.checkIsRenamedTitle(filePath, title)) {
        valuesBucket[CallRecorderSingleConstant.TITLE] = title;
      } else {
        valuesBucket[CallRecorderSingleConstant.TITLE] = '';
      }
      // The DATE_ADDED field needs to be obtained from the begin_time field in the calllog table
      // in the call record database. Currently, the DATE_ADDED field is not allowed to obtain the value.
      // The value is left blank after the SE confirmation.

      title = this.getDisplayName(filePath, title);
      valuesBucket[CallRecorderSingleConstant.DISPLAY_NAME] = title;
      let number: string = this.getPhoneNumberFormTitle(title) ? this.getPhoneNumberFormTitle(title) : '';
      number = number.replace(new RegExp(' ', 'g'), '');
      valuesBucket[CallRecorderSingleConstant.PHONE_NUMBER] = number;
      let recorderAdded: number = resultSet.getLong(resultSet.getColumnIndex(CallRecorderCloneConstant.DATE_ADDED));
      valuesBucket[CallRecorderSingleConstant.RECORDER_ADDED] = recorderAdded;
      let dateAdded = (recorderAdded - duration);
      valuesBucket[CallRecorderSingleConstant.DATE_ADDED] = ((dateAdded > 0) ? Math.floor(dateAdded / 1000) : '');
      let newFilePath = FileUtils.replaceAudioFileDir(TYPE_DUAL2NEXT, filePath) ?? '';
      valuesBucket[CallRecorderSingleConstant.FILE_PATH] = newFilePath;
      let key: string = title + '_' + recorderAdded;
      if (this.isNeedSaveToDb(recordLogMap, key, newFilePath, filePath)) {
        callRecodeResult.push(valuesBucket);
      }
    } while (resultSet.goToNextRow());
  }

  checkIsRenamedTitle(filePath: string, title: string): boolean {
    let fileName = filePath.replace(`${FileUtils.getDualDir(filePath)}/`, '');
    if (fileName !== title) {
      let diffOnFileNameAndTitle = fileName.replace(title, '');
      return diffOnFileNameAndTitle === '.m4a' || diffOnFileNameAndTitle === '.amr';
    } else {
      return false;
    }
  }

  getDisplayName(filePath: string, displayName: string): string {
    if (filePath.endsWith('.m4a') && !displayName.endsWith('.m4a')) {
      return displayName + '.m4a';
    }
    if (filePath.endsWith('.amr') && !displayName.endsWith('.amr')) {
      return displayName + '.amr';
    }
    return displayName;
  }

  isNeedSaveToDb(dbMaps: HashMap<string, number>, newRecordKeys: string, newFilePath: string,
    oldPath: string): boolean {
    if (!dbMaps.isEmpty() && dbMaps.hasKey(newRecordKeys)) {
      copyDbDataHelper.addRepeatAudioCountInDb();
      return false;
    }
    if (copyDbDataHelper.isCopySuccessRecord(newFilePath)) {
      return true;
    }
    copyDbDataHelper.addExAudioPathCountInDb();
    if (oldPath.indexOf('Sounds/CallRecord') < 0) {
      LogUtils.i(TAG, 'no matched file');
    }
    return false;
  }

  private convertToValuesBucketForNext2Next(resultSet: rdb.ResultSet, callRecordList: ValuesBucket[],
    recordLogMap: HashMap<string, number> = new HashMap<string, number>()): void {
    LogUtils.i(TAG, 'convertToValuesBucketForNext2Next start size:' + resultSet.rowCount);
    do {
      let valuesBucket: ValuesBucket = {}
      let oldFilePath = resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.FILE_PATH));
      let newFilePath = FileUtils.replaceAudioFileDir(TYPE_NEXT2NEXT, oldFilePath);
      valuesBucket[CallRecorderSingleConstant.FILE_PATH] = newFilePath;
      valuesBucket[CallRecorderSingleConstant.DURATION] =
      resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.DURATION));
      valuesBucket[CallRecorderSingleConstant.TITLE] =
      resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.TITLE));
      valuesBucket[CallRecorderSingleConstant.DATE_ADDED] =
      resultSet.getLong(resultSet.getColumnIndex(CallRecorderSingleConstant.DATE_ADDED));
      let displayName: string = resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.DISPLAY_NAME));
      valuesBucket[CallRecorderSingleConstant.DISPLAY_NAME] = displayName;
      valuesBucket[CallRecorderSingleConstant.PHONE_NUMBER] =
        resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.PHONE_NUMBER));
      let recorderAdded: number =
        resultSet.getLong(resultSet.getColumnIndex(CallRecorderSingleConstant.RECORDER_ADDED));
      valuesBucket[CallRecorderSingleConstant.RECORDER_ADDED] = recorderAdded;
      try {
        let isDeleted: number = resultSet.getLong(resultSet.getColumnIndex(CallRecorderSingleConstant.IS_DELETED));
        valuesBucket[CallRecorderSingleConstant.IS_DELETED] = isDeleted;
        let soundDisplayName: string =
          resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.SOUNDRECORD_DISPLAY_NAME));
        valuesBucket[CallRecorderSingleConstant.SOUNDRECORD_DISPLAY_NAME] = soundDisplayName;
      } catch (err) {
        LogUtils.e(TAG, 'convertToValuesBucketForNext2Next err:' + JSON.stringify(err));
      }
      let key: string = displayName + '_' + recorderAdded;
      if (this.isNeedSaveToDb(recordLogMap, key, newFilePath, oldFilePath)) {
        callRecordList.push(valuesBucket);
      }
    } while (resultSet.goToNextRow());
  }

  private getPhoneNumberFormTitle(title: string): string {
    if (title == null || title == '' || title == undefined) {
      return '';
    }
    let underlineIndex = title.indexOf('_');
    let atIndex = title.indexOf('@');
    if (underlineIndex > 0 && underlineIndex < title.length) {
      //135 9257 0552_20231214142136.m4a
      if (atIndex < 0 || atIndex >= title.length) {
        return title.substring(0, underlineIndex);
      } else {
        return title.substring(atIndex + 1, underlineIndex);
      }
    }
    return '';
  }

  public async queryRecordConfig(context: common.Context): Promise<ValuesBucket> {
    LogUtils.i(TAG, 'queryRecordConfig start');
    let valuesBucket: ValuesBucket = {};
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return valuesBucket;
      }
      let predicatesInfo = new rdb.RdbPredicates(CallRecorderSingleConstant.RECORD_CONFIG_TB_NAME);
      let resultSet: rdb.ResultSet = await rdbStore.query(predicatesInfo);
      if (resultSet.goToFirstRow()) {
        valuesBucket[CallRecorderSingleConstant.CONFIG_IS_OPEN] =
        resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.CONFIG_IS_OPEN));
        valuesBucket[CallRecorderSingleConstant.CONFIG_OBJECT] =
        resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.CONFIG_OBJECT));
      } else {
        LogUtils.i(TAG, 'queryRecordConfig no callRecord found ...');
      }
      resultSet.close();
    } catch (err) {
      LogUtils.i(TAG, 'queryRecordConfig error');
    }
    return Promise.resolve(valuesBucket);
  }

  public async queryRecordContact(context: common.Context, startIndex: number): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'queryRecordContact start');
    let recordContactList: ValuesBucket[] = [];
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return [];
      }
      let predicatesInfo = new rdb.RdbPredicates(this.isFromHm ? this.oldDualContactTable : this.oldNextContactTable);
      let resultSet: rdb.ResultSet | undefined = undefined;
      predicatesInfo
        .orderByAsc(this.isFromHm ? CallRecorderCloneConstant.RECORD_ID : CallRecorderSingleConstant.CONTACT_ID)
        .limitAs(CallRecorderSingleConstant.QUERY_PAGE_NUM)
        .offsetAs(startIndex);
      resultSet = await rdbStore.query(predicatesInfo);
      if (resultSet.goToFirstRow()) {
        this.convertToValuesBucketForRecordContact(resultSet, recordContactList);
      } else {
        LogUtils.i(TAG, 'queryRecordContact no callRecord found ...');
      }
      resultSet.close();
    } catch (err) {
      LogUtils.e(TAG, 'queryRecordContact error' + JSON.stringify(err));
    }
    return Promise.resolve(recordContactList);
  }

  private convertToValuesBucketForRecordContact(resultSet: rdb.ResultSet,
    recordConfigList: ValuesBucket[]): void {
    LogUtils.i(TAG, 'convertToValuesBucketForRecordConfig start');
    do {
      let valuesBucket: ValuesBucket = {};
      valuesBucket['phone_number'] =
      resultSet.getString(resultSet.getColumnIndex(this.isFromHm ? CallRecorderDualConstant.CUSTOMIZE_NUMBER :
        CallRecorderSingleConstant.CONTACT_PHONE_NUMBER));
      valuesBucket['name'] =
      resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.CONTACT_NAME));
      recordConfigList.push(valuesBucket);
    } while (resultSet.goToNextRow());
  }
}

export const callRecorderDbHelper: CallRecorderDbHelper = new CallRecorderDbHelper();
