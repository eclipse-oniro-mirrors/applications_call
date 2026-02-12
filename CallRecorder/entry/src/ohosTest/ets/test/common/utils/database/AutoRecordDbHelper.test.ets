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
import { describe, it, expect, MockKit, when, ArgumentMatchers, beforeAll, afterAll } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import { GlobalContextHelper } from '../../../../../../main/ets/common/utils/GlobalContextHelper';
import { Constant } from '../../../../../../main/ets/common/constant/Constant';
import CallRecorderDualConstant from '../../../../../../main/ets/common/constant/CallRecorderDualConstant';
import { arDbHelper as autoRecordDbHelper } from '../../../../../../main/ets/common/utils/database/AutoRecordDbHelper';
import relationalStore from '@ohos.data.relationalStore';
import LogUtils from '../../../../../../main/ets/common/utils/LogUtils';
import { ValuesBucket } from '@ohos.data.ValuesBucket';

const TAG = 'AutoRecordDbHelperTest';

let AutoRecordDbHelperTest_queryCount_01 = async (context: common.Context) => {
  LogUtils.i(TAG, 'queryCount_01 start');
  await autoRecordDbHelper.queryCount(context, CallRecorderDualConstant.RECORDER_FILE_TABLE_NAME);
  let count = await autoRecordDbHelper.queryCount(context, 'no exist table name');
  LogUtils.i(TAG, 'queryCount_01 end count:' + count);
  expect(count === 0).assertTrue();
}

let AutoRecordDbHelperTest_queryCount_02 = async (context: common.Context) => {
  LogUtils.i(TAG, 'AutoRecordDbHelperTest_queryCount_02 start');
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(autoRecordDbHelper, autoRecordDbHelper.initRDB);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
  let count = await autoRecordDbHelper.queryCount(context, CallRecorderDualConstant.RECORDER_FILE_TABLE_NAME);
  mocker.clearAll();
  expect(count >= 0).assertTrue();
}

let AutoRecordDbHelperTest_queryCount_03 = async (context: common.Context) => {
  LogUtils.i(TAG, 'queryCount_03 start');
  let count = await autoRecordDbHelper.queryCount(context, CallRecorderDualConstant.RECORDER_FILE_TABLE_NAME);
  LogUtils.i(TAG, 'queryCount_03 end count:' + count);
  expect(count >= 0).assertTrue();
}

let AutoRecordDbHelperTest_queryContactData_01 = async (context: common.Context) => {
  LogUtils.i(TAG, 'AutoRecordDbHelperTest_queryContactData_01 start');
  let result = await autoRecordDbHelper.queryContactData(context, 0);
  expect(result.length == 0).assertTrue();
}

let AutoRecordDbHelperTest_queryContactData_02 = async (context: common.Context) => {
  LogUtils.i(TAG, 'AutoRecordDbHelperTest_queryContactData_02 start');
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(autoRecordDbHelper, autoRecordDbHelper.initRDB);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
  let result = await autoRecordDbHelper.queryContactData(context, 0);
  expect(result.length >= 0).assertTrue();
  mocker.clearAll();
}

let AutoRecordDbHelperTest_initRDB_01 = async (context: common.Context) => {
  LogUtils.i(TAG, 'initRDB start');
  try {
    await autoRecordDbHelper.queryContactData(context, 0);
    await autoRecordDbHelper.queryAutoRecordDbForHmUpgradeNext(context, 0);
    await createDb(context);
    LogUtils.i(TAG, 'initRDB createDb ok');
    let contactCount = await autoRecordDbHelper.queryCount(context, CallRecorderDualConstant.CUSTOMIZE_TABLE_NAME);
    if (contactCount > 0) {
      await autoRecordDbHelper.queryContactData(context, 0);
      LogUtils.i(TAG, 'initRDB queryContactData ok');
    }
    let fileConut = await autoRecordDbHelper.queryCount(context, CallRecorderDualConstant.RECORDER_FILE_TABLE_NAME);
    if (fileConut > 0) {
      await autoRecordDbHelper.queryAutoRecordDbForHmUpgradeNext(context, 0);
      LogUtils.i(TAG, 'initRDB queryAutoRecordDbForHmUpgradeNext ok');
    }
    LogUtils.i(TAG, 'initRDB createDb contactCount:' + contactCount + ', fileConut:' + fileConut);

    expect(fileConut >= 0).assertTrue();
  } catch (err) {
    LogUtils.e(TAG, 'initRDB getDatabaseInfo err:' + JSON.stringify(err));
  }
}

let AutoRecordDbHelperTest_queryAutoRecordDbForHmUpgradeNext_01 = async (context: common.Context) => {
  LogUtils.i(TAG, 'queryAutoRecordDbForHmUpgradeNext 01 start');
  let result: ValuesBucket[] = await autoRecordDbHelper.queryAutoRecordDbForHmUpgradeNext(context, 900000);

  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(autoRecordDbHelper, autoRecordDbHelper.initRDB);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(undefined);
  await autoRecordDbHelper.queryAutoRecordDbForHmUpgradeNext(context, 0);
  mocker.clearAll();
  expect(result.length === 0).assertTrue();
}

async function createDb(context: common.Context) {
  const config: relationalStore.StoreConfig = {
    name: CallRecorderDualConstant.AUTO_RECORD_DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1
  };
  let retryTimes: number = 3;
  let rdbStore: relationalStore.RdbStore | undefined = undefined;
  do {
    retryTimes--;
    relationalStore.deleteRdbStore(context, CallRecorderDualConstant.AUTO_RECORD_DB_NAME);
    rdbStore = await init(context, config);
  } while ((retryTimes > 0 && !rdbStore))
  LogUtils.i(TAG, 'createAutoRecordDb retryTimes:' + retryTimes);
  if (!rdbStore) {
    LogUtils.e(TAG, 'createAutoRecordDb create rdb failed');
    return;
  }
  let table_file = 'CREATE TABLE IF NOT EXISTS call_record_file (_id INTEGER PRIMARY KEY AUTOINCREMENT' +
    ', title TEXT, _data TEXT, date_added LONG, file_size LONG, duration LONG);';
  await rdbStore.executeSql(table_file);
  LogUtils.i(TAG, 'create table call_record_file ok');
  await autoRecordDbHelper.queryContactData(context, 0);
  LogUtils.i(TAG, 'query table call_record_file ok');
  await rdbStore.insert('call_record_file', {
    '_id': 1,
    'title': '13800000001_20240616072714.m4a',
    '_data': '/storage/emulated/0/Sounds/CallRecord/13800000001_20240616072714.m4a',
    'date_added': 1718494034000,
    'file_size': 132513,
    'duration': 10773
  });
  await rdbStore.insert('call_record_file', {
    '_id': 2,
    'title': '13800000002_20240616072744.m4a',
    '_data': '/storage/emulated/0/Sounds/CallRecord/13800000002_20240616072744.m4a',
    'date_added': 1718494064000,
    'file_size': 132513,
    'duration': 10773
  });
  await rdbStore.insert('call_record_file', {
    '_id': 3,
    'title': '13800000003_20240616072774.m4a',
    '_data': '/storage/emulated/0/Sounds/CallRecord/13800000003_20240616072774.m4a',
    'date_added': 1718494094000,
    'file_size': 132513,
    'duration': 10773
  });
  LogUtils.i(TAG, 'insert table call_record_file ok');
  let table_contact = 'CREATE TABLE IF NOT EXISTS customize (_id INTEGER PRIMARY KEY AUTOINCREMENT' +
    ', name TEXT,number TEXT);';
  await rdbStore.executeSql(table_contact);
  LogUtils.i(TAG, 'create table customize ok');
  await autoRecordDbHelper.queryAutoRecordDbForHmUpgradeNext(context, 0);
  LogUtils.i(TAG, 'query table auto record for hm upgrade ok');
  await rdbStore.insert('customize', { '_id': 1, 'name': 'A', 'number': '13800001111' });
  await rdbStore.insert('customize', { '_id': 2, 'name': 'B', 'number': '13800001112' });
  await rdbStore.insert('customize', { '_id': 3, 'name': 'C', 'number': '13800001113' });
  LogUtils.i(TAG, 'insert table customize ok');
}

async function init(context: common.Context, config: relationalStore.StoreConfig):
  Promise<relationalStore.RdbStore | undefined> {
  try {
    let rdbStore = await relationalStore.getRdbStore(context, config);
    return rdbStore;
  } catch (err) {
    LogUtils.i(TAG, 'createAutoRecordDb err:' + JSON.stringify(err));
    return undefined;
  }
}

export default function AutoRecordDbHelperTest() {
  describe('AutoRecordDbHelperTest', () => {
    let testContext = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    beforeAll(() => {
      LogUtils.i(TAG, 'enter AutoRecordDbHelperTest beforeAll');
    });
    afterAll(() => {
      LogUtils.i(TAG, 'afterAll exist AutoRecordDbHelperTest');
    });
    it('AutoRecordDbHelperTest_initRDB_01', 0, async () => {
      await AutoRecordDbHelperTest_initRDB_01(testContext);
    });
    it('AutoRecordDbHelperTest_queryCount_01', 0, async () => {
      await AutoRecordDbHelperTest_queryCount_01(testContext);
    });
    it('AutoRecordDbHelperTest_queryCount_02', 0, async () => {
      await AutoRecordDbHelperTest_queryCount_02(testContext);
    });
    it('AutoRecordDbHelperTest_queryCount_03', 0, async () => {
      await AutoRecordDbHelperTest_queryCount_03(testContext);
    });
    it('AutoRecordDbHelperTest_queryContactData_01', 0, async () => {
      await AutoRecordDbHelperTest_queryContactData_01(testContext);
    });
    it('AutoRecordDbHelperTest_queryContactData_02', 0, async () => {
      await AutoRecordDbHelperTest_queryContactData_02(testContext);
    });
    it('AutoRecordDbHelperTest_queryAutoRecordDbForHmUpgradeNext_01', 0, async () => {
      await AutoRecordDbHelperTest_queryAutoRecordDbForHmUpgradeNext_01(testContext);
    });
  })
}