/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import DataShareExtensionAbility, { UpdateOperation } from '@ohos.application.DataShareExtensionAbility';
import { AsyncCallback } from '@ohos.base';
import Want from '@ohos.app.ability.Want';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import LogUtils from '../common/utils/LogUtils';
import relationalStore from '@ohos.data.relationalStore';
import DatabaseHelper from '../common/utils/DatabaseHelper';

const TAG = 'CallRecorderDataAbility';
let rdbStore: relationalStore.RdbStore;

export default class CallRecorderDataShareAbility extends DataShareExtensionAbility {
  onCreate(want: Want, callback: AsyncCallback<void>) {}

  async insert(uri: string, valueBucket: ValuesBucket, callback: AsyncCallback<number>) {
    // Called by the server when it inserts data into the database. This API can be overridden when needed.
    let uriObject = await DatabaseHelper.getInstance().getDatabaseInfo(uri, this.context);
    if (!uriObject) {
      return;
    }
    rdbStore = await DatabaseHelper.getInstance().getDualWriteRdbStore(this.context);
    try {
      return rdbStore.insert(uriObject.tableUse, valueBucket, (err, rowId) => {
        if (rowId !== undefined) {
          LogUtils.i(TAG, `resultSet.rowCount:${rowId}`);
        }
        if (callback !== undefined) {
          LogUtils.i(TAG, `Insert is successful, rowId = ${rowId}`);
          callback(err, rowId);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `rdbStore insert failed, err: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  async delete(uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: AsyncCallback<number>) {
    let uriObject = await DatabaseHelper.getInstance().getDatabaseInfo(uri, this.context);
    if (!uriObject) {
      return;
    }
    rdbStore = await DatabaseHelper.getInstance().getDualWriteRdbStore(this.context);
    try {
      return rdbStore.delete(uriObject.tableUse, predicates, (err, rows) => {
        if (err) {
          LogUtils.e(TAG, `delete failed, code is ${err.code}`);
          return;
        }
        LogUtils.i(TAG, `delete row count: ${rows}`);
        callback(err, rows);
      });
    } catch (err) {
      LogUtils.e(TAG, `rdbStore delete failed, err: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  async query(uri: string, predicates: dataSharePredicates.DataSharePredicates, columns: Array<string>,
    callback: AsyncCallback<Object>) {
    LogUtils.i(TAG, 'query start');
    let uriObject = await DatabaseHelper.getInstance().getDatabaseInfo(uri, this.context);
    if (!uriObject) {
      return;
    }
    rdbStore = await DatabaseHelper.getInstance().getDualWriteRdbStore(this.context);
    try {
      return rdbStore.query(uriObject.tableUse, predicates, columns, (err, resultSet) => {
        if (resultSet !== undefined) {
          LogUtils.i(TAG, `query resultSet uri=${uri} rowCount=${resultSet.rowCount}`);
        }
        if (callback !== undefined) {
          callback(err, resultSet);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `rdbStore query failed, err: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  async update(uri: string, predicates: dataSharePredicates.DataSharePredicates, value: ValuesBucket,
    callback: AsyncCallback<number>) {
    // Called by the server when the database is updated. This API can be overridden when needed.
    let uriObject = await DatabaseHelper.getInstance().getDatabaseInfo(uri, this.context);
    if (!uriObject) {
      return;
    }
    try {
      rdbStore = await DatabaseHelper.getInstance().getDualWriteRdbStore(this.context);
      return rdbStore.update(uriObject.tableUse, value, predicates, (err, rows) => {
        if (err) {
          LogUtils.e(TAG, `Updated failed, code is ${err.code}`);
          return;
        }
        LogUtils.i(TAG, `Updated row count: ${rows}`);
        callback(err, rows);
      });
    } catch (err) {
      LogUtils.e(TAG, `Updated failed, error code: ${err.code}`);
    }
  }

  /* instrument ignore next */
  async batchUpdate(operations:Record<string, Array<UpdateOperation>>, callback:Function): Promise<void> {
    LogUtils.i(TAG, 'batchUpdate start');
    let results : Record<string, Array<number>> = {};
    rdbStore = await DatabaseHelper.getInstance().getDualWriteRdbStore(this.context);
    if (!rdbStore) {
      LogUtils.e(TAG, 'batchUpdate get invalid rdbStore');
      callback(null, results);
      return;
    }
    let recordOps : Record<string, Array<UpdateOperation>> = operations;
    let lists = Object.entries(recordOps);
    for (let i = 0; i < lists.length; i++) {
      let table: string = lists[i][0];
      let values: UpdateOperation[] = lists[i][1];
      LogUtils.e(TAG, `batchUpdate on:${table} size:${values?.length}`);
      results[table] = await this.singleUpdate(rdbStore, table, values);
    }
    callback(null, results);
  }

  /* instrument ignore next */
  async singleUpdate(curRdbStore: relationalStore.RdbStore, table: string,
    values: Array<UpdateOperation>): Promise<number[]> {
    let result : number[] = [];
    let insertRowId: number = -1;
    for (const value of values) {
      try {
        insertRowId = await curRdbStore.update(table, value.values, value.predicates);
      } catch (err) {
        LogUtils.e(TAG, `singleUpdate err:${err?.code}-${err?.message}`);
        insertRowId = -1;
      }
      result.push(insertRowId);
    }
    LogUtils.e(TAG, `singleUpdate on:${table} last row:${insertRowId}`);
    return result;
  }

  async batchInsert(uri: string, valueBuckets: Array<ValuesBucket>, callback: AsyncCallback<number>) {
    let uriObject = await DatabaseHelper.getInstance().getDatabaseInfo(uri, this.context);
    if (!uriObject) {
      return;
    }
    rdbStore = await DatabaseHelper.getInstance().getDualWriteRdbStore(this.context);
    LogUtils.i(TAG, `batchInsert is successful` + uriObject.tableUse);
    try {
      return rdbStore.batchInsert(uriObject.tableUse, valueBuckets, (err, rowId) => {
        if (rowId !== undefined) {
          LogUtils.i(TAG, `resultSet.rowCount:${rowId}`);
        }
        if (callback !== undefined) {
          LogUtils.i(TAG, `Insert is successful, rowId = ${rowId}`);
          callback(err, rowId);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `rdbStore batchInsert failed, err: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  normalizeUri(uri: string, callback: AsyncCallback<string>) {
    // Called when the URI provided by the user is converted to the URI usable by the server.
  }

  denormalizeUri(uri: string, callback: AsyncCallback<string>) {
    // Called by the server when the URI used by the server is converted to the initial URI passed by the user.
  }
}
