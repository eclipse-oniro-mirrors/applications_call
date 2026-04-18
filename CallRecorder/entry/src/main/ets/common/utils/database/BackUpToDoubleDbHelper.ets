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
import { FileUtils, TYPE_NEXT2DUAL } from '../FileUtils';
import CallRecorderDualConstant from '../../constant/CallRecorderDualConstant';
import fs from '@ohos.file.fs';
import relationalStore from '@ohos.data.relationalStore';
import { BACKUP_CALL_RECORD_FILE_TB,
  BACKUP_COPY_FILE_LIST_INFO,
  BACKUP_CUSTOMIZE_TB,
  BACKUP_DEFAULT_FILE_LIST_INFO,
  BACKUP_URI_INFO,
  BACKUP_VERSION_INFO,
  tempConfig } from '../../../database/DbBackUpProcessor';
import RecordDatabaseHelper from '../DatabaseHelper';

const TAG = 'BackUpToDoubleDBHelper';

class BackUpToDoubleDBHelper {
  private rdbStoreHelper?: rdb.RdbStore;
  private newDbConfig: relationalStore.StoreConfig = {
    name: RecordDatabaseHelper.TABLE.RECORD_DATABASE,
    securityLevel: relationalStore.SecurityLevel.S1
  };

  /**
   * get count
   *
   * @param context
   * @param tableName of call_record.db
   */
  public async queryCount(context: common.Context, table: string): Promise<number> {
    LogUtils.i(TAG, `queryCount start:${table}`);
    if (!context) {
      LogUtils.e(TAG, 'queryCount invalid context');
      return Promise.resolve(0);
    }
    let count = 0;
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return Promise.resolve(0);
      }
      let queryColumn = ['count(1)'];
      let predicatesInfo = new relationalStore.RdbPredicates(table);
      let resultSet = await rdbStore.query(predicatesInfo, queryColumn);
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
        LogUtils.i(TAG, `queryCount count : ${count}`);
      }
      resultSet.close();
    } catch (error) {
      LogUtils.e(TAG, `queryCount error:${JSON.stringify(error)}`);
    }
    return Promise.resolve(count);
  }

  private async initDB(context: common.Context): Promise<undefined | rdb.RdbStore> {
    LogUtils.i(TAG, 'initDB start');
    try {
      this.rdbStoreHelper = await rdb.getRdbStore(context, this.newDbConfig);
      return this.rdbStoreHelper;
    } catch (error) {
      LogUtils.e(TAG, `initDB failed:${JSON.stringify(error)}`);
    }
    return undefined;
  }

  /**
   * get record data from the table 'record_log' in call_record.db
   *
   * @param context
   * @param startIndex,each time 200 data records are obtained.
   * For example, the start value is 0 for the first time and 200 for the second time.
   */
  public async queryCallRecorder(context: common.Context, startIndex: number): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'queryCallRecorder start');
    let callRecodeResult: ValuesBucket[] = [];
    if (!context) {
      LogUtils.e(TAG, 'queryCallRecorder invalid context');
      return callRecodeResult;
    }
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return callRecodeResult;
      }
      let resultSet: rdb.ResultSet | undefined = undefined;
      let predicatesInfo = new rdb.RdbPredicates(CallRecorderSingleConstant.RECORD_LOG_TB_NAME);
      predicatesInfo
        .orderByAsc(CallRecorderSingleConstant.ID)
        .limitAs(CallRecorderCloneConstant.QUERY_PAGE_NUM)
        .offsetAs(startIndex);
      resultSet = await rdbStore.query(predicatesInfo);
      if (resultSet.goToFirstRow()) {
        await this.convertToValuesBucket(resultSet, callRecodeResult);
      } else {
        LogUtils.i(TAG, 'queryCallRecorder no callRecord found ...');
      }
      resultSet.close();
    } catch (err) {
      LogUtils.e(TAG, 'queryCallRecorder error');
    }
    return Promise.resolve(callRecodeResult);
  }

  private async convertToValuesBucket(resultSet: rdb.ResultSet, callRecodeResult: ValuesBucket[]): Promise<void> {
    LogUtils.i(TAG, 'convertToValuesBucket start resultSet size = ' + resultSet?.rowCount);
    do {
      let valuesBucket: ValuesBucket = {};

      let id: number = resultSet.getLong(resultSet.getColumnIndex(CallRecorderSingleConstant.ID));
      valuesBucket[CallRecorderDualConstant.RECORD_ID] = id;

      let duration: number = resultSet.getLong(resultSet.getColumnIndex(CallRecorderSingleConstant.DURATION));
      valuesBucket[CallRecorderDualConstant.DURATION] = duration;

      let displayName = resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.DISPLAY_NAME));
      valuesBucket[CallRecorderDualConstant.TITLE] = displayName;

      let recorderAdded: number =
        resultSet.getLong(resultSet.getColumnIndex(CallRecorderSingleConstant.RECORDER_ADDED));
      valuesBucket[CallRecorderDualConstant.DATE_ADDED] = recorderAdded;

      let filePath = resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.FILE_PATH));
      let data = FileUtils.replaceAudioFileDir(TYPE_NEXT2DUAL, filePath) ?? '';
      valuesBucket[CallRecorderDualConstant.DATA] = data;

      let size = fs.statSync(filePath)?.size;
      valuesBucket[CallRecorderDualConstant.FILE_SIZE] = size;
      callRecodeResult.push(valuesBucket);
    } while (resultSet.goToNextRow());
  }

  public async batchInsertRecordInfoForBackUp(context: Context, recLogValue: ValuesBucket[]) {
    let recordSize = recLogValue?.length ?? 0;
    LogUtils.i(TAG, 'batchInsertRecordInfoForBackUp recordSize = ' + recordSize);
    if (recordSize === 0) {
      return;
    }
    if (!context) {
      LogUtils.e(TAG, 'batchInsertRecordInfoForBackUp invalid context');
      return;
    }
    let rdbStore: relationalStore.RdbStore | undefined;
    try {
      rdbStore = await relationalStore.getRdbStore(context, tempConfig);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertRecordInfoForBackUp get rdbStore failed`);
        return 0;
      }
      let rowId = await rdbStore.batchInsert(BACKUP_CALL_RECORD_FILE_TB, recLogValue);
      LogUtils.i(TAG, `batchInsertRecordInfoForBackUp is successful, rowId = ${rowId}`);
      return rowId;
    } catch (err) {
      LogUtils.e(TAG, `batchInsertRecordInfoForBackUp insert failed, error code: ${err.code}`);
      return 0;
    }
  }

  /**
   * get contact data from the table 'record_contact' in call_record.db
   *
   * @param context
   * @param startIndex,each time 200 data records are obtained.
   * For example, the start value is 0 for the first time and 200 for the second time.
   */
  public async queryCustomizeData(context: common.Context, startIndex: number): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'queryCustomizeData start startIndex = ' + startIndex);
    let recordContactList: ValuesBucket[] = [];
    if (!context) {
      LogUtils.e(TAG, 'queryContactData invalid context');
      return recordContactList;
    }
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return recordContactList;
      }
      let predicatesInfo = new relationalStore.RdbPredicates(CallRecorderSingleConstant.RECORD_CONTACT_TB_NAME);
      let resultSet: relationalStore.ResultSet | undefined = undefined;
      predicatesInfo
        .orderByAsc(CallRecorderSingleConstant.ID)
        .limitAs(CallRecorderSingleConstant.QUERY_PAGE_NUM)
        .offsetAs(startIndex);
      resultSet = await rdbStore.query(predicatesInfo);
      if (resultSet.goToFirstRow()) {
        this.convertToValuesBucketForCustomize(resultSet, recordContactList);
      } else {
        LogUtils.i(TAG, 'queryRecordContact no callRecord found ...');
      }
      resultSet.close();
    } catch (err) {
      LogUtils.e(TAG, `queryContactData err:${JSON.stringify(err)}`);
    }
    return Promise.resolve(recordContactList);
  }

  private convertToValuesBucketForCustomize(resultSet: relationalStore.ResultSet,
    recordConfigList: ValuesBucket[]): void {
    LogUtils.i(TAG, 'convertToValuesBucketForCustomize start result set size = ' + resultSet?.rowCount);
    do {
      let valuesBucket: ValuesBucket = {};
      valuesBucket[CallRecorderDualConstant.CUSTOMIZE_NUMBER] =
        resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.CONTACT_PHONE_NUMBER));
      valuesBucket[CallRecorderDualConstant.CUSTOMIZE_NAME] =
        resultSet.getString(resultSet.getColumnIndex(CallRecorderSingleConstant.CONTACT_NAME));
      let id: number = resultSet.getLong(resultSet.getColumnIndex(CallRecorderSingleConstant.ID));
      valuesBucket[CallRecorderDualConstant.CUSTOMIZE_ID] = id;
      recordConfigList.push(valuesBucket);
    } while (resultSet.goToNextRow());
  }

  public async batchInsertCustomizeForBackUp(context: Context, params: ValuesBucket[]) {
    let contactSize = params?.length ?? 0;
    LogUtils.i(TAG, 'batchInsertCustomizeForBackUp contactSize = ' + contactSize);
    if (contactSize === 0) {
      return;
    }
    if (!context) {
      LogUtils.e(TAG, 'batchInsertCustomizeForBackUp invalid context');
      return;
    }
    let rdbStore: relationalStore.RdbStore | undefined;
    try {
      rdbStore = await relationalStore.getRdbStore(context, tempConfig);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertCustomizeForBackUp get rdbStore failed`);
        return;
      }
      let rowId = await rdbStore.batchInsert(BACKUP_CUSTOMIZE_TB, params);
      LogUtils.i(TAG, `batchInsertCustomizeForBackUp batchInsert is successful, rowId = ${rowId}`);
    } catch (err) {
      LogUtils.e(TAG, `batchInsertCustomizeForBackUp insert failed, error code: ${err.code}`);
    }
  }

  public async getCopyFileData(context: common.Context): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'getCopyFileData start');
    let recordCopyFileList: ValuesBucket[] = [];
    if (!context) {
      LogUtils.e(TAG, 'getCopyFileData invalid context');
      return recordCopyFileList;
    }
    try {
      let valuesBucket: ValuesBucket = {};
      valuesBucket['_id'] = 0;
      valuesBucket['value'] = '/storage/emulated/0/Sounds/CallRecord';
      recordCopyFileList.push(valuesBucket);
    } catch (err) {
      LogUtils.e(TAG, `getCopyFileData err:${JSON.stringify(err)}`);
    }
    return Promise.resolve(recordCopyFileList);
  }

  public async batchInsertCopyFileForBackUp(context: Context, params: ValuesBucket[]) {
    let contactSize = params?.length ?? 0;
    LogUtils.i(TAG, 'batchInsertCopyFileForBackUp insert contactSize = ' + contactSize);
    if (contactSize === 0) {
      return;
    }
    if (!context) {
      LogUtils.e(TAG, 'batchInsertCopyFileForBackUp invalid context');
      return;
    }
    LogUtils.i(TAG, 'batchInsertCopyFileForBackUp');
    let rdbStore: relationalStore.RdbStore | undefined;
    try {
      rdbStore = await relationalStore.getRdbStore(context, tempConfig);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertCopyFileForBackUp get rdbStore failed`);
        return;
      }
      let rowId = await rdbStore.batchInsert(BACKUP_COPY_FILE_LIST_INFO, params);
      LogUtils.i(TAG, `batchInsertCopyFileForBackUp batchInsert is successful, rowId = ${rowId}`);
    } catch (err) {
      LogUtils.e(TAG, `batchInsertCopyFileForBackUp insert failed, error code: ${err.code}`);
    }
  }

  public async getDefaultFileData(context: common.Context): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'getDefaultFileData start');
    let recordCopyFileList: ValuesBucket[] = [];
    if (!context) {
      LogUtils.e(TAG, 'getDefaultFileData invalid context');
      return recordCopyFileList;
    }
    try {
      let valuesBucket: ValuesBucket = {};
      valuesBucket['_id'] = 0;
      valuesBucket['value'] = '/storage/emulated/0/record';
      recordCopyFileList.push(valuesBucket);
    } catch (err) {
      LogUtils.e(TAG, `getCopyFileData err:${JSON.stringify(err)}`);
    }
    return Promise.resolve(recordCopyFileList);
  }

  public async batchInsertDefaultFileForBackUp(context: Context, params: ValuesBucket[]) {
    let contactSize = params?.length ?? 0;
    if (contactSize === 0) {
      LogUtils.e(TAG, 'batchInsertDefaultFileForBackUp insert empty');
      return;
    }
    if (!context) {
      LogUtils.e(TAG, 'batchInsertDefaultFileForBackUp invalid context');
      return;
    }
    LogUtils.i(TAG, 'batchInsertDefaultFileForBackUp');
    let rdbStore: relationalStore.RdbStore | undefined;
    try {
      rdbStore = await relationalStore.getRdbStore(context, tempConfig);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertDefaultFileForBackUp get rdbStore failed`);
        return;
      }
      let rowId = await rdbStore.batchInsert(BACKUP_DEFAULT_FILE_LIST_INFO, params);
      LogUtils.i(TAG, `batchInsertDefaultFileForBackUp batchInsert is successful, rowId = ${rowId}`);
    } catch (err) {
      LogUtils.e(TAG, `batchInsertDefaultFileForBackUp insert failed, error code: ${err.code}`);
    }
  }

  public async getUriData(context: common.Context): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'getUriData start');
    let recordCopyFileList: ValuesBucket[] = [];
    if (!context) {
      LogUtils.e(TAG, 'getUriData invalid context');
      return recordCopyFileList;
    }
    try {
      let valuesBucket1: ValuesBucket = {};
      valuesBucket1['_id'] = 0;
      valuesBucket1['need_count'] = 1;
      valuesBucket1['value'] = '';
      recordCopyFileList.push(valuesBucket1);

      let valuesBucket2: ValuesBucket = {};
      valuesBucket2['_id'] = 1;
      valuesBucket2['need_count'] = 1;
      valuesBucket2['value'] = '';
      recordCopyFileList.push(valuesBucket2);
    } catch (err) {
      LogUtils.e(TAG, `getUriData err:${JSON.stringify(err)}`);
    }
    return Promise.resolve(recordCopyFileList);
  }

  public async batchInsertUriForBackUp(context: Context, params: ValuesBucket[]) {
    let contactSize = params?.length ?? 0;
    if (contactSize === 0) {
      LogUtils.e(TAG, 'batchInsertUriForBackUp insert empty');
      return;
    }
    if (!context) {
      LogUtils.e(TAG, 'batchInsertUriForBackUp invalid context');
      return;
    }
    LogUtils.i(TAG, 'batchInsertUriForBackUp');
    let rdbStore: relationalStore.RdbStore | undefined;
    try {
      rdbStore = await relationalStore.getRdbStore(context, tempConfig);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertUriForBackUp get rdbStore failed`);
        return;
      }
      let rowId = await rdbStore.batchInsert(BACKUP_URI_INFO, params);
      LogUtils.i(TAG, `batchInsertUriForBackUp batchInsert is successful, rowId = ${rowId}`);
    } catch (err) {
      LogUtils.e(TAG, `batchInsertUriForBackUp insert failed, error code: ${err.code}`);
    }
  }

  public async getVersionData(context: common.Context): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'getVersionData start');
    let recordCopyFileList: ValuesBucket[] = [];
    if (!context) {
      LogUtils.e(TAG, 'getVersionData invalid context');
      return recordCopyFileList;
    }
    try {
      let valuesBucket1: ValuesBucket = {};
      valuesBucket1['version'] = 3;
      recordCopyFileList.push(valuesBucket1);
    } catch (err) {
      LogUtils.e(TAG, `getVersionData err:${JSON.stringify(err)}`);
    }
    return Promise.resolve(recordCopyFileList);
  }

  public async batchInsertVersionForBackUp(context: Context, params: ValuesBucket[]) {
    let contactSize = params?.length ?? 0;
    if (contactSize === 0) {
      LogUtils.e(TAG, 'batchInsertVersionForBackUp insert empty');
      return;
    }
    if (!context) {
      LogUtils.e(TAG, 'batchInsertVersionForBackUp invalid context');
      return;
    }
    LogUtils.i(TAG, 'batchInsertVersionForBackUp');
    let rdbStore: relationalStore.RdbStore | undefined;
    try {
      rdbStore = await relationalStore.getRdbStore(context, tempConfig);
      if (!rdbStore) {
        LogUtils.e(TAG, `batchInsertVersionForBackUp get rdbStore failed`);
        return;
      }
      let rowId = await rdbStore.batchInsert(BACKUP_VERSION_INFO, params);
      LogUtils.i(TAG, `batchInsertVersionForBackUp batchInsert is successful, rowId = ${rowId}`);
    } catch (err) {
      LogUtils.e(TAG, `batchInsertVersionForBackUp insert failed, error code: ${err.code}`);
    }
  }
}

export const backUpToDoubleDbHelper: BackUpToDoubleDBHelper = new BackUpToDoubleDBHelper();