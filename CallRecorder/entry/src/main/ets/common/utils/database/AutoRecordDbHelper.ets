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
import common from '@ohos.app.ability.common';
import LogUtils from '../LogUtils';
import relationalStore from '@ohos.data.relationalStore';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import CallRecorderSingleConstant from '../../constant/CallRecorderSingleConstant';
import CallRecorderDualConstant from '../../constant/CallRecorderDualConstant';
import { callRecorderDbHelper } from './CallRecorderDbHelper';
import HashMap from '@ohos.util.HashMap';

const TAG = 'AutoRecordDbHelper';
let rdbStore: relationalStore.RdbStore;

class AutoRecordDbHelper {
  /**
   * init relationalstore to autorecord.db
   */
  async initRDB(context: common.Context,
    dbName: string = CallRecorderDualConstant.AUTO_RECORD_DB_NAME): Promise<undefined | relationalStore.RdbStore> {
    LogUtils.i(TAG, 'init, dbName length:' + dbName.length);
    try {
      const CONFIG: relationalStore.StoreConfig = {
        name: dbName,
        securityLevel: relationalStore.SecurityLevel.S1
      };
      rdbStore = await relationalStore.getRdbStore(context, CONFIG);
      return rdbStore;
    } catch (error) {
      LogUtils.e(TAG, `initDB failed error:${JSON.stringify(error)}`);
    }
    return undefined;
  }

  /**
   * get count
   *
   * @param context
   * @param tableName of autorecord.db
   *
   */
  async queryCount(context: common.Context, table: string): Promise<number> {
    LogUtils.i(TAG, `queryCount start:${table}`);
    let count = 0;
    try {
      let rdbStore = await this.initRDB(context);
      if (rdbStore === undefined) {
        return Promise.resolve(0);
      }
      let queryColumn = ['count(1)'];
      let predicatesInfo = new relationalStore.RdbPredicates(table);
      let resultSet = await rdbStore.query(predicatesInfo, queryColumn);
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
        LogUtils.i(TAG, `queryContactCount count : ${count}`);
      }
      resultSet.close();
    } catch (error) {
      LogUtils.e(TAG, `queryCount error:${JSON.stringify(error)}`);
    }
    return Promise.resolve(count);
  }

  /**
   * get contact data from the table 'customize' in autorecord.db
   *
   * @param context
   * @param startIndex,each time 200 data records are obtained.
   * For example, the start value is 0 for the first time and 200 for the second time.
   *
   */
  async queryContactData(context: common.Context, startIndex: number): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'queryContactData start');
    let recordContactList: ValuesBucket[] = [];
    try {
      let rdbStore = await this.initRDB(context);
      if (rdbStore === undefined) {
        return recordContactList;
      }
      let predicatesInfo = new relationalStore.RdbPredicates(CallRecorderDualConstant.CUSTOMIZE_TABLE_NAME);
      let resultSet: relationalStore.ResultSet | undefined = undefined;
      predicatesInfo
        .orderByAsc(CallRecorderDualConstant.CUSTOMIZE_ID)
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
      LogUtils.e(TAG, `queryContactData err:${JSON.stringify(err)}`);
    }
    return Promise.resolve(recordContactList);
  }

  private convertToValuesBucketForRecordContact(resultSet: relationalStore.ResultSet,
                                                recordConfigList: ValuesBucket[]): void {
    LogUtils.i(TAG, 'convertToValuesBucketForRecordConfig start');
    do {
      let valuesBucket: ValuesBucket = {};
      valuesBucket['phone_number'] =
        resultSet.getString(resultSet.getColumnIndex(CallRecorderDualConstant.CUSTOMIZE_NUMBER));
      valuesBucket['name'] =
        resultSet.getString(resultSet.getColumnIndex(CallRecorderDualConstant.CUSTOMIZE_NAME));
      recordConfigList.push(valuesBucket);
    } while (resultSet.goToNextRow());
  }

  async queryAutoRecordDbForHmUpgradeNext(context: common.Context, startIndex: number): Promise<ValuesBucket[]> {
    let callRecodeResult: ValuesBucket[] = [];
    try {
      let rdbStore = await this.initRDB(context);
      if (rdbStore === undefined) {
        LogUtils.e(TAG, 'queryAutoRecordDbForHmUpgradeNext init rdb error');
        return Promise.resolve(callRecodeResult);
      }
      let predicatesInfo = new relationalStore.RdbPredicates(CallRecorderDualConstant.RECORDER_FILE_TABLE_NAME);
      predicatesInfo.orderByAsc(CallRecorderDualConstant.RECORD_ID)
        .limitAs(CallRecorderSingleConstant.QUERY_PAGE_NUM)
        .offsetAs(startIndex);
      let resultSet = await rdbStore.query(predicatesInfo);
      if (resultSet.goToFirstRow()) {
        await callRecorderDbHelper.convertToValuesBucket(resultSet, callRecodeResult,
          context, new HashMap<string, number>());
      } else {
        LogUtils.i(TAG, 'query result is empty');
      }
      resultSet.close();
    } catch (err) {
      LogUtils.i(TAG, `queryAutoRecordDbForHmUpgradeNext error:${JSON.stringify(err)}`);
    }
    return Promise.resolve(callRecodeResult);
  }
}

export const arDbHelper: AutoRecordDbHelper = new AutoRecordDbHelper();