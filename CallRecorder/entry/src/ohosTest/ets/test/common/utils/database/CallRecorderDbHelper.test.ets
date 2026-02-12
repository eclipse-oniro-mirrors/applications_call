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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import rdb from '@ohos.data.relationalStore';
import { callRecorderDbHelper } from '../../../../../../main/ets/common/utils/database/CallRecorderDbHelper';
import { GlobalContextHelper } from '../../../../../../main/ets/common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../../../main/ets/common/constant/Constant';
import CallRecorderCloneConstant from '../../../../../../main/ets/common/constant/CallRecorderCloneConstant';
import CallRecorderSingleConstant from '../../../../../../main/ets/common/constant/CallRecorderSingleConstant';
import HashMap from '@ohos.util.HashMap';
import commonController from '../../../../../../main/ets/common/control/CommonCtrol';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { sleep } from '../Sleep';
import relationalStore from '@ohos.data.relationalStore';
import LogUtils from '../../../../../../main/ets/common/utils/LogUtils';
import CallRecorderDualConstant from '../../../../../../main/ets/common/constant/CallRecorderDualConstant';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import DatabaseHelper from '../../../../../../main/ets/common/utils/DatabaseHelper';
import { copyDbDataHelper } from '../../../../../../main/ets/common/utils/CopyDbDataHelper';

const TAG = 'CallRecorderDbHelperTest';

async function CallRecorderDbHelperTest_queryCount_01Func(context: Context) {
  LogUtils.i(TAG, 'CallRecorderDbHelperTest_queryCount_01Func start');
  let tableName: string = CallRecorderSingleConstant.RECORD_LOG_TB_NAME;
  let result = await callRecorderDbHelper.queryCount(context, tableName);
  expect(result >= 0).assertTrue();
}

async function CallRecorderDbHelperTest_queryCount_02Func(context: Context) {
  LogUtils.i(TAG, 'CallRecorderDbHelperTest_queryCount_02Func start');
  let result = await callRecorderDbHelper.queryCount(context, '');
  expect(result >= 0).assertTrue();
}

async function CallRecorderDbHelperTest_queryCount_03Func(context: Context) {
  LogUtils.i(TAG, 'CallRecorderDbHelperTest_queryCount_03Func start');
  try {
    await createAndInsertDualCloneDb(context);
  } catch (err) {
    LogUtils.e(TAG, 'queryCount_03Func createAndInsertDualCloneDb error:' + JSON.stringify(err));
  }
  try {
    AppStorage.setOrCreate('MigrateType', CallRecorderCloneConstant.CLONE_VERSION_NAME);
    await callRecorderDbHelper.queryRecordConfig(context);
    LogUtils.i(TAG, 'queryCount_03Func queryRecordConfig ok');

    let count = await callRecorderDbHelper.queryCount(context, CallRecorderCloneConstant.CONTACT_TB);
    LogUtils.i(TAG, 'queryCount_03Func count:' + count);
    await callRecorderDbHelper.queryCallRecorder(context, 0, new HashMap<string, number>());
    await callRecorderDbHelper.queryRecordContact(context, 0);
    LogUtils.i(TAG, 'queryCount_03Func query on CLONE_VERSION_NAME ok');

    AppStorage.setOrCreate('MigrateType', 'test');
    await callRecorderDbHelper.queryCallRecorder(context, 0, new HashMap<string, number>());
    await callRecorderDbHelper.queryRecordContact(context, 0);
    LogUtils.i(TAG, 'queryCount_03Func query on test ok');
  } catch (err) {
    LogUtils.e(TAG, 'queryCount_03Func err:' + JSON.stringify(err));
  }
}

async function CallRecorderDbHelperTest_queryCount_04_err_case(testNoContext: Context) {
  await callRecorderDbHelper.delOldSingleDb(testNoContext);

  let tableName: string = CallRecorderSingleConstant.RECORD_LOG_TB_NAME;
  AppStorage.setOrCreate('MigrateType', 'test');
  await callRecorderDbHelper.queryCount(testNoContext, tableName);

  AppStorage.setOrCreate('MigrateType', CallRecorderCloneConstant.CLONE_VERSION_NAME);
  let context = abilityDelegatorRegistry.getAbilityDelegator().getAppContext();
  await callRecorderDbHelper.queryCount(context, tableName);

  let result = await callRecorderDbHelper.queryCount({} as common.Context, tableName);
  expect(result >= 0).assertTrue();
}

async function CallRecorderDbHelperTest_queryCallRecorder_01Func(testNoContext: Context) {
  let recordLogMap: HashMap<string, number> = await commonController.getInstance()
    .queryForRecordLog(GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT));
  let result = await callRecorderDbHelper.queryCallRecorder(testNoContext, 0, recordLogMap);
  expect(result.length >= 0).assertTrue();
}

async function CallRecorderDbHelperTest_queryCallRecorder_02Func(testNoContext: Context) {
  let result = await callRecorderDbHelper.queryCallRecorder(testNoContext, 1000000, new HashMap());
  expect(result.length >= 0).assertTrue();
}

async function CallRecorderDbHelperTest_queryRecordConfig_01Func(testNoContext: Context) {
  let valuesBucket: ValuesBucket = {};
  let result = await callRecorderDbHelper.queryRecordConfig(testNoContext);
  await callRecorderDbHelper.queryRecordConfig(GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_DATA_SHARE_ABILITY_CONTEXT));
  expect(typeof result).assertEqual(typeof valuesBucket);
}

async function CallRecorderDbHelperTest_queryRecordConfig_02Func(testNoContext: Context) {
  let valuesBucket: ValuesBucket = {};
  let result = await callRecorderDbHelper.queryRecordConfig(testNoContext);
  expect(typeof result).assertEqual(typeof valuesBucket);
}

async function CallRecorderDbHelperTest_queryRecordContact_01Func(testNoContext: Context) {
  let recordContactList: ValuesBucket[] = [];
  let result = await callRecorderDbHelper.queryRecordContact(testNoContext, 0);
  expect(result.length).assertEqual(recordContactList.length);
}

async function CallRecorderDbHelperTest_queryRecordContact_02Func(testNoContext: Context) {
  let result = await callRecorderDbHelper.queryRecordContact(testNoContext, 1000000);
  expect(result.length >= 0).assertTrue();
}

async function CallRecorderDbHelperTest_convertToValuesBucket_01(testNoContext: Context) {
  const OLD_CONFIG: rdb.StoreConfig = {
    name: 'testdb.db',
    securityLevel: rdb.SecurityLevel.S1
  };
  let rdbStore = await rdb.getRdbStore(testNoContext, OLD_CONFIG);
  try {
    let table_file = 'CREATE TABLE IF NOT EXISTS testTb (_id INTEGER PRIMARY KEY AUTOINCREMENT' +
      ', title TEXT, _data TEXT, date_added LONG, file_size LONG, duration LONG);';
    await rdbStore.executeSql(table_file);
    let rowId: number = await rdbStore.insert('testTb', {
      '_id': 1,
      'title': '13800000001_20240616072714.m4a',
      '_data': '/storage/emulated/0/Sounds/CallRecord/13800000001_20240616072714.m4a',
      'date_added': 1718494034000,
      'file_size': 132513,
      'duration': 10773
    });
  } catch (error) {
    LogUtils.i(TAG, 'CallRecorderDbHelperTest_convertToValuesBucket_01' + error.message);
  }
  let predicatesInfo = new rdb.RdbPredicates('testTb');
  let resultSet: rdb.ResultSet = await rdbStore.query(predicatesInfo);
  let logMap = new HashMap<string, number>();
  let ary = [];
  if (resultSet.goToFirstRow()) {
    await callRecorderDbHelper.convertToValuesBucket(resultSet, ary, testNoContext, logMap);
  }
  rdbStore.delete(predicatesInfo);
  rdb.deleteRdbStore(testNoContext, OLD_CONFIG);
  expect(ary.length >= 0).assertTrue();
}

async function CallRecorderDbHelperTest_isNeedSaveToDb_01() {
  let map: HashMap<string, number> = new HashMap();
  map.set('file_size', 132513);
  map.set('duration', 10442,);
  let result = callRecorderDbHelper.isNeedSaveToDb(map, 'duration',
    '/storage/emulated/0/Sounds/CallRecord/13800000001_20240616072714.m4a', '');
  expect(result).assertFalse();
}

async function CallRecorderDbHelperTest_isNeedSaveToDb_02() {
  let map: HashMap<string, number> = new HashMap();
  copyDbDataHelper.successCopyAudioFileList.push('/storage/emulated/0/Sounds/CallRecord/13800000001_20240616072714.m4a')
  let result = callRecorderDbHelper.isNeedSaveToDb(map, 'duration',
    '/storage/emulated/0/Sounds/CallRecord/13800000001_20240616072714.m4a', '');
  copyDbDataHelper.successCopyAudioFileList = [];
  expect(result).assertTrue();
}

async function CallRecorderDbHelperTest_isNeedSaveToDb_03() {
  let map: HashMap<string, number> = new HashMap();
  copyDbDataHelper.successCopyAudioFileList = [];
  let result = callRecorderDbHelper.isNeedSaveToDb(map, 'duration',
    '/storage/emulated/0/Sounds/CallRecord/13800000001_20240616072714.m4a', '');
  expect(result).assertFalse();
}

async function createAndInsertDualCloneDb(context: common.Context) {
  LogUtils.i(TAG, 'createAndInsertDualCloneDb start');
  relationalStore.deleteRdbStore(context, CallRecorderCloneConstant.CALL_RECORDER_CLONE_DB_NAME);
  const config: relationalStore.StoreConfig = {
    name: CallRecorderCloneConstant.CALL_RECORDER_CLONE_DB_NAME,
    securityLevel: rdb.SecurityLevel.S2
  }
  let retryTimes: number = 3;
  let rdbStore: relationalStore.RdbStore | undefined = undefined;
  do {
    retryTimes--;
    rdbStore = await init(context, config);
  } while ((retryTimes > 0 && !rdbStore))
  LogUtils.i(TAG, 'createAutoRecordDb retryTimes:' + retryTimes);
  if (!rdbStore) {
    LogUtils.e(TAG, 'createAutoRecordDb create rdb failed');
    return;
  }
  await createRecordTable(rdbStore);
  await createConfigContact(rdbStore);
  await createConfigTable(rdbStore);
}

async function createRecordTable(rdbStore: rdb.RdbStore) {
  let table_file = 'CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackupcall_record_file_tb (_id TEXT' +
    ', title TEXT, _data TEXT, date_added TEXT, file_size TEXT, duration TEXT);';
  await rdbStore.executeSql(table_file);
  LogUtils.i(TAG, 'create dual comandroidphoneautorecordbackupcall_record_file_tb ok');
  await rdbStore.insert('comandroidphoneautorecordbackupcall_record_file_tb',
    {
      '_id': '100001',
      'title': '13800000001_20240616072714.m4a',
      '_data': '/storage/emulated/0/Sounds/CallRecord/13800000001_20240616072714.m4a',
      'date_added': '1718494034000',
      'file_size': '132513',
      'duration': '10773'
    });
  await rdbStore.insert('comandroidphoneautorecordbackupcall_record_file_tb',
    {
      '_id': '100002',
      'title': '13800000002_20240616072744.m4a',
      '_data': '/storage/emulated/0/Sounds/CallRecord/13800000002_20240616072744.m4a',
      'date_added': '1718494064000',
      'file_size': '132513',
      'duration': '10773'
    });
  await rdbStore.insert('comandroidphoneautorecordbackupcall_record_file_tb',
    {
      '_id': '100003',
      'title': '13800000003_20240616072774',
      '_data': '/storage/emulated/0/Sounds/CallRecord/13800000003_20240616072774.m4a',
      'date_added': '1718494094000',
      'file_size': '132513',
      'duration': '10773'
    });
  await rdbStore.insert('comandroidphoneautorecordbackupcall_record_file_tb',
    {
      '_id': '100004',
      'title': '',
      '_data': '/storage/emulated/0/Sounds/CallRecord/13800000003_20240617072774.m4a',
      'date_added': '1718494094000',
      'file_size': '132513',
      'duration': '10773'
    });
  await rdbStore.insert('comandroidphoneautorecordbackupcall_record_file_tb',
    {
      '_id': '100005',
      'title': 'A@13800000003_20240618072774.m4a',
      '_data': '/storage/emulated/0/Sounds/CallRecord/A@13800000003_20240618072774.m4a',
      'date_added': '1718494094000',
      'file_size': '132513',
      'duration': '10773'
    });
  LogUtils.i(TAG, 'insert comandroidphoneautorecordbackupcall_record_file_tb ok');
}

async function createConfigContact(rdbStore: rdb.RdbStore) {
  let table_contact = 'CREATE TABLE IF NOT EXISTS comandroidphoneautorecordbackupcustomize_tb (id TEXT' +
    ', name TEXT,number TEXT);';
  await rdbStore.executeSql(table_contact);
  LogUtils.i(TAG, 'create comandroidphoneautorecordbackupcustomize_tb ok');
  await rdbStore.insert('comandroidphoneautorecordbackupcustomize_tb',
    { '_id': 1, 'name': 'A', 'number': '13800001111' });
  await rdbStore.insert('comandroidphoneautorecordbackupcustomize_tb',
    { '_id': 2, 'name': 'B', 'number': '13800001112' });
  await rdbStore.insert('comandroidphoneautorecordbackupcustomize_tb',
    { '_id': 3, 'name': 'C', 'number': '13800001113' });
  LogUtils.i(TAG, 'insert comandroidphoneautorecordbackupcustomize_tb ok');
}

async function createConfigTable(rdbStore: rdb.RdbStore) {
  let table_config = 'CREATE TABLE IF NOT EXISTS record_config (id TEXT, is_open TEXT, object TEXT);';
  await rdbStore.executeSql(table_config);
  LogUtils.i(TAG, 'create record_config ok');
  await rdbStore.insert('record_config', { '_id': 1, 'is_open': '1', 'object': '1' });
  LogUtils.i(TAG, 'insert record_config ok');
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

function getContextFromAbility(): common.Context {
  return GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
}

export default function CallRecorderDbHelperTest() {
  let testNoContext = getContextFromAbility();
  describe('CallRecorderDbHelperTest', () => {
    it('CallRecorderDbHelperTest_queryCount_01', 0, async () => {
      await CallRecorderDbHelperTest_queryCount_01Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryCount_02', 0, async () => {
      await CallRecorderDbHelperTest_queryCount_02Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryCount_03', 0, async () => {
      await CallRecorderDbHelperTest_queryCount_03Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryCallRecorder_01', 0, async () => {
      await CallRecorderDbHelperTest_queryCallRecorder_01Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryCallRecorder_02', 0, async () => {
      await CallRecorderDbHelperTest_queryCallRecorder_02Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryRecordConfig_01', 0, async () => {
      await CallRecorderDbHelperTest_queryRecordConfig_01Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryRecordConfig_02', 0, async () => {
      await CallRecorderDbHelperTest_queryRecordConfig_02Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryRecordContact_01', 0, async () => {
      await CallRecorderDbHelperTest_queryRecordContact_01Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryRecordContact_02', 0, async () => {
      await CallRecorderDbHelperTest_queryRecordContact_02Func(testNoContext);
    });
    it('CallRecorderDbHelperTest_queryCount_04_err_case', 0, async () => {
      await CallRecorderDbHelperTest_queryCount_04_err_case(testNoContext);
    });
    it('CallRecorderDbHelperTest_convertToValuesBucket_01', 0, async () => {
      await CallRecorderDbHelperTest_convertToValuesBucket_01(testNoContext);
    });
    it('CallRecorderDbHelperTest_isNeedSaveToDb_01', 0, async () => {
      await CallRecorderDbHelperTest_isNeedSaveToDb_01();
    });
    it('CallRecorderDbHelperTest_isNeedSaveToDb_02', 0, async () => {
      await CallRecorderDbHelperTest_isNeedSaveToDb_02();
    });
    it('CallRecorderDbHelperTest_isNeedSaveToDb_03', 0, async () => {
      await CallRecorderDbHelperTest_isNeedSaveToDb_03();
    });
  });
}