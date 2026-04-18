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

import { describe, it, expect, beforeEach, beforeAll, afterAll } from '@ohos/hypium'
import * as RestoreConstants from '../../../../main/ets/backup/RestoreConstants';
import LogUtils from '../../../../main/ets/utils/HiLog';
import { prefUtils } from '../../../../main/ets/backup/PrefUtils';
import { contactsRdbHelper } from '../../../../main/ets/backup/ContactsRdbHelper';
import { fileUtils } from '../../../../main/ets/backup/FileUtils';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import rdb from '@ohos.data.relationalStore';

const TAG = 'test_FileUtils';
const CREATE_CONTACT_DATA = `CREATE TABLE IF NOT EXISTS [data]( ` +
  `[${RestoreConstants.COL_DATA_ID}] INTEGER PRIMARY KEY AUTOINCREMENT, ` +
  `[${RestoreConstants.COL_RAW_ID}] INTEGER, ` +
  `[${RestoreConstants.COL_DATA1}] TEXT, ` +
  `[${RestoreConstants.COL_MIMETYPE}] INTEGER)`;
const XML_FILE_CONTENT = `<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
  <string name="emergency_contacts">content://com.andoid.contacts/data/8|content://com.andoid.contacts/data/1</string>
  <string name="address">我的地址：胡同18号B栋-101</string>
    <string name="medications"></string>
  <string name="blood_type">O-</string>
</map>`;

export async function getRdbStoreHelper(context: common.Context,
  dbName: string, dbDir?: string): Promise<rdb.RdbStore | undefined> {
  LogUtils.i(TAG, 'getRdbStoreHelper start');
  if (context === undefined || context === null) {
    LogUtils.w(TAG, 'getRdbStoreHelper failed context is empty');
    return undefined;
  }
  let rdbStoreHelper: rdb.RdbStore | undefined = undefined;
  LogUtils.i(TAG, 'getRdbStoreHelper dbDir:' + dbDir + ', context DbDir:' + context.databaseDir);
  try {
    const CONFIG: rdb.StoreConfig = {
      name: dbName,
      securityLevel: rdb.SecurityLevel.S1
    };
    rdbStoreHelper = await rdb.getRdbStore(context, CONFIG);
    rdbStoreHelper.executeSql(CREATE_CONTACT_DATA);
  } catch (error) {
    LogUtils.e(TAG, 'getRdbStoreHelper error:' + error?.code);
  }
  return Promise.resolve(rdbStoreHelper);
}
export function createTestDir(context: common.Context, isDb: boolean): string {
  let filePath = '';
  try {
    if (!isDb) {
      let sharedPrefPath = context.preferencesDir;
      LogUtils.i(TAG, 'createTestDir sharedPrefPath:' + sharedPrefPath);
      let isSharedPrefPathAccessible = fileUtils.isFileAccessibleSync(sharedPrefPath);
      LogUtils.i(TAG, 'createTestDir pref dir Accessible:' + isSharedPrefPathAccessible);
      filePath = `${sharedPrefPath}/testDir`;
    } else {
      let dbPath = context.databaseDir;
      LogUtils.i(TAG, 'createTestDir dbPath:' + dbPath);
      let isDbPathAccessible = fileUtils.isFileAccessibleSync(dbPath);
      LogUtils.i(TAG, 'createTestDir db dir Accessible:' + isDbPathAccessible);
      filePath = `${dbPath}/rdb`;
    }
    LogUtils.i(TAG, `createTestDir start mkdir:${filePath}`);
    fs.mkdirSync(filePath);
  } catch (error) {
    LogUtils.i(TAG, `createTestDir error:${error?.code}`);
  }
  if (fileUtils.isFileAccessibleSync(filePath)) {
    LogUtils.i(TAG, `createTestDir filePath:${filePath} ok`);
    return filePath;
  } else {
    LogUtils.i(TAG, `createTestDir filePath:${filePath} faild`);
    return '';
  }
}

const enum CreateFileResult {
  CREATE_XML_OK = 1,
  CREATE_DB_OK = 2,
  CREATE_ALL_OK = 3
}

export async function prepareFile(context: common.Context): Promise<number> {
  let xmlDirPath = createTestDir(context, false);
  LogUtils.e(TAG, `test create xml dir:${xmlDirPath}`);
  await fileUtils.copyFilesByDir(xmlDirPath, xmlDirPath);
  await fileUtils.copyFilesByDir(xmlDirPath, xmlDirPath, true);
  let createResult = 0;
  if (xmlDirPath !== '') {
    createResult = 1;
    let testXmlFile = `${xmlDirPath}/testFile.xml`
    try {
      let fileXml = fs.openSync(testXmlFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(fileXml.fd, XML_FILE_CONTENT);
      LogUtils.e(TAG, 'test write xml file ok');
      let content = await fileUtils.parseXmlToPref(testXmlFile);
      LogUtils.e(TAG, 'test after write xml file ok, test get content:' + content);
    } catch (error) {
      LogUtils.e(TAG, `test write xml file ${testXmlFile} error:${error?.code}`);
    }
  }

  let dbDirPath = createTestDir(context, true);
  LogUtils.e(TAG, `test create db dir:${dbDirPath}`);
  if (dbDirPath === '') {
    LogUtils.e(TAG, `test create db file ${dbDirPath} failed`);
    return createResult;
  }
  createResult = createResult + CreateFileResult.CREATE_DB_OK;
  let rdb = await getRdbStoreHelper(context, `${RestoreConstants.OLD_DATABASE_NAME}`, dbDirPath);
  if (rdb) {
    LogUtils.i(TAG, 'test create db getRdbStoreHelper ok');
  } else {
    LogUtils.e(TAG, 'test create db getRdbStoreHelper fail');
    let testDbXmlFile = `${dbDirPath}/testFile.xml`
    try {
      let fileXml = fs.openSync(testDbXmlFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(fileXml.fd, XML_FILE_CONTENT);
      LogUtils.e(TAG, 'test write db test xml file ok');
    } catch (error) {
      LogUtils.e(TAG, `test write db test xml file ${testDbXmlFile} error:${error?.code}`);
    }
  }
  return createResult;
}

export default function FileUtilsTest() {
  let isPrefInitSuccess: boolean = false;
  let isPrepareXmlFileOk = false;
  let isPrepareDbFileOk = false;
  let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
  let testContext: common.Context = abilityDelegator.getAppContext();
  beforeAll(async () => {
    LogUtils.i(TAG, 'beforeAll');
  })
  afterAll(async () => {
    LogUtils.i(TAG, 'afterAll');
  })
  describe('FileUtilsTest', () => {
    it('FileUtilsTest_testInvalidParam', 0, async () => {
      await testInvalidContext();
    })
    it('FileUtilsTest_testValidContextInvalidParam', 0, async () => {
      await prepare(testContext, isPrefInitSuccess, isPrepareXmlFileOk, isPrepareDbFileOk);
    })
    it('FileUtilsTest_000', 0, async () => {
      await fileUtilsTest_000(testContext);
    })
    it('FileUtilsTest_001', 0, async () => {
      await fileUtilsTest_001(testContext);
    })
  })
}

async function testInvalidContext() {
  LogUtils.i(TAG, 'testInvalidContext start');
  let result = await fileUtils.parseXmlToPref('');
  LogUtils.i(TAG, 'testInvalidContext start result:' + result);
  expect(!result).assertTrue();

  let result2 = await fileUtils.isFileAccessibleSync('');
  LogUtils.i(TAG, 'testInvalidContext start result2:' + result2);
  expect(!result2).assertTrue();

  let result3 = await fileUtils.copyFilesByDir('', '');
  let result4 = await fileUtils.copyFilesByDir('', '', true);
  LogUtils.i(TAG, 'testInvalidContext start result3:' + result3 + ' result4:' + result4);
  expect(result3 && result4).assertFalse();
}

async function prepare(testContext: common.Context, isPrefInitSuccess: boolean,
  isPrepareXmlFileOk: boolean, isPrepareDbFileOk: boolean) {
  LogUtils.i(TAG, 'prepare');
  isPrefInitSuccess = await prefUtils.init(testContext);
  LogUtils.i(TAG, `prepare isPrefInitSuccess:${isPrefInitSuccess}`);
  let createFileResult = await prepareFile(testContext);
  isPrepareXmlFileOk = createFileResult === CreateFileResult.CREATE_XML_OK
    || createFileResult === CreateFileResult.CREATE_ALL_OK;
  isPrepareDbFileOk = createFileResult === CreateFileResult.CREATE_DB_OK
    || createFileResult === CreateFileResult.CREATE_ALL_OK;
  LogUtils.i(TAG, 'PrefUtilsTest prepare createFileResult:' + createFileResult
    + ', isPrepareXmlFileOk:' + isPrepareXmlFileOk + ', isPrepareDbFileOk:' + isPrepareDbFileOk);
  expect(isPrepareXmlFileOk).assertTrue();
  expect(isPrepareDbFileOk).assertTrue();
}

async function fileUtilsTest_000(context: common.Context) {
  LogUtils.i(TAG, 'FileUtilsTest_000 start test');
  let isSuccess = await contactsRdbHelper.restoreContactsFromDb(context);
  LogUtils.i(TAG, 'FileUtilsTest_000 isSuccess:' + isSuccess);
  expect(!isSuccess).assertFalse();
}

async function fileUtilsTest_001(context: common.Context) {
  LogUtils.i(TAG, 'FileUtilsTest_001 start');
  let isSuccess = await contactsRdbHelper.restoreContactsFromDb(context);
  LogUtils.i(TAG, 'PrefUtilsTest_001 isSuccess1:' + isSuccess);
  expect(!isSuccess).assertFalse();
}
