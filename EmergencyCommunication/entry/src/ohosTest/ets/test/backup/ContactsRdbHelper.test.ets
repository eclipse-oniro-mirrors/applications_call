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

import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium'
import * as Constants from '../../../../main/ets/utils/Constants';
import LogUtils from '../../../../main/ets/utils/HiLog';
import rdb from '@ohos.data.relationalStore';
import { contactsRdbHelper } from '../../../../main/ets/backup/ContactsRdbHelper';
import * as RestoreConstants from '../../../../main/ets/backup/RestoreConstants';
import common from '@ohos.app.ability.common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { prefUtils } from '../../../../main/ets/backup/PrefUtils';
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import { preferences } from '@kit.ArkData';
import { Driver } from '@kit.TestKit';

const BUNDLE_NAME = 'com.ohos.emergencycommunication';
const CALL_ABILITY_NAME = 'com.ohos.emergencycommunication.EmergencyCallAbility';
const DELAY_TIME = 1000;
const TEST_PREF_KEY_TEST = 'TEST_RESTORE_KEY';

const CREATE_CONTACT_DATA = `CREATE TABLE IF NOT EXISTS [data]( ` +
  `[${RestoreConstants.COL_DATA_ID}] INTEGER PRIMARY KEY AUTOINCREMENT, ` +
  `[${RestoreConstants.COL_RAW_ID}] INTEGER, ` +
  `[${RestoreConstants.COL_DATA1}] TEXT, ` +
  `[${RestoreConstants.COL_MIMETYPE}] INTEGER)`;

const TEST_CONTACT1_NUMBER: rdb.ValuesBucket = {
  '_id' : 1, 'raw_contact_id': 1, 'data1': '138 0000 0000', 'mimetype_id': 5
};
const TEST_CONTACT1_NAME: rdb.ValuesBucket = {
  '_id' : 2, 'raw_contact_id': 1, 'data1': 'TestName1', 'mimetype_id': 7
};
const TEST_CONTACT2_NUMBER: rdb.ValuesBucket = {
  '_id' : 8, 'raw_contact_id': 1, 'data1': '138 1111 1111', 'mimetype_id': 5,
};

async function addContactsInfo(rdb: rdb.RdbStore | undefined): Promise<boolean> {
  if (rdb) {
    try {
      await rdb.insert('data', TEST_CONTACT1_NUMBER);
      await rdb.insert('data', TEST_CONTACT1_NAME);
      await rdb.insert('data', TEST_CONTACT2_NUMBER);
      LogUtils.i(TAG, 'test create db insert data ok');
    } catch (error) {
      LogUtils.e(TAG, 'test create db insert data error:' + error?.code);
      return false;
    }
    LogUtils.i(TAG, 'test addContactsInfo ok');
    return true;
  }
  LogUtils.w(TAG, 'test addContactsInfo get rdb failed');
  return false;
}

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

const TAG = 'test_ContactsRdbHelper';

export default function ContactsRdbHelperTest() {
  let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
  let testContext: common.Context = abilityDelegator.getAppContext();
  beforeAll(async () => {
    LogUtils.i(TAG, `beforeAll get context:${testContext}`);
  })
  beforeEach(async () => {
    LogUtils.i(TAG, `beforeEach get context:${testContext}`);
  })
  describe('ContactsRdbHelperTest', () => {
    it('ContactsRdbHelperTest_000', 0, async () => {
      LogUtils.i(TAG, 'Test_000 enter');
      await testEmptyContext(testContext);
    })
    it('ContactsRdbHelperTest_001', 0, async () => {
      await getCtxAndInitPref(testContext);
      await contactsRdbHelperTest_001(testContext);
    })
  })
}

export async function testEmptyContext(context: common.Context): Promise<void> {
  let beforeDbStatus: boolean = await prefUtils.getStatus(RestoreConstants.DB_READ_STATUS_KEY, false) as boolean;
  LogUtils.i(TAG, `testEmptyContext check beforeDbStatus:${beforeDbStatus}`);
  let testEmptyContext = EmergencyGlobalContextHelper.getContext().getValue<common.Context>('testGetContext');
  let testEmptyContextResult = await contactsRdbHelper.restoreContactsFromDb(testEmptyContext);
  LogUtils.i(TAG, `testEmptyContext testEmptyContextResult:${testEmptyContextResult}`);
  expect(testEmptyContextResult).assertFalse();
}

export async function contactsRdbHelperTest_001(context: common.Context): Promise<void> {
  let rdb = await getRdbStoreHelper(context, `${RestoreConstants.OLD_DATABASE_NAME}`);
  if (rdb) {
    await addContactsInfo(rdb);
  }
  let result1 = await contactsRdbHelper.restoreContactsFromDb(context);
  LogUtils.i(TAG, `PrefUtilsTest_000 result1:${result1}`);
  expect(result1).assertFalse();

  await prefUtils.saveParsedOldInfoToPref(RestoreConstants.OLD_EM_CONTACTS_KEY, '8');
  let result2 = await contactsRdbHelper.restoreContactsFromDb(context);
  LogUtils.i(TAG, `PrefUtilsTest_000 result2:${result2}`);
  expect(result1).assertFalse();
}

export async function getCtxAndInitPref(testContext: common.Context, isClearAllPref?: boolean): Promise<void> {
  let isPrefInitSuccess = await prefUtils.init(testContext);
  let isCanGetTestVal = await prefUtils.getStatus(TEST_PREF_KEY_TEST, true) as boolean;
  LogUtils.i(TAG, `getCtxAndInitPref isCanGetTestVal:${isCanGetTestVal} isContextInvalid:${!testContext}`);
  if (!isCanGetTestVal) {
    LogUtils.i(TAG, 'getCtxAndInitPref try init pref again');
    isPrefInitSuccess = await prefUtils.init(testContext);
    if (!isPrefInitSuccess) {
      LogUtils.i(TAG, 'getCtxAndInitPref try start ability to get context');
      await startCallAbility();
      testContext = EmergencyGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT) as common.Context;
      isPrefInitSuccess = await prefUtils.init(testContext);
      if (!isPrefInitSuccess) {
        LogUtils.i(TAG, 'getCtxAndInitPref get test ui ability context failed');
      } else {
        LogUtils.i(TAG, 'getCtxAndInitPref by start ability success');
      }
    }
  }

  if (isPrefInitSuccess) {
    await clearPref(testContext);
    LogUtils.e(TAG, 'getCtxAndInitPref clear end');
  }
}

export async function startCallAbility(): Promise<void> {
  let want: Want = {
    bundleName: BUNDLE_NAME,
    abilityName: CALL_ABILITY_NAME
  }
  LogUtils.i(TAG, 'startCallAbility from abilityDelegator');
  let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
  abilityDelegator.startAbility(want);
  let driver = Driver.create();
  await driver.delayMs(DELAY_TIME);
}

export async function clearPref(context: common.Context) {
  LogUtils.e(TAG, 'clearPref start');
  let restorePref = await preferences.getPreferences(context, RestoreConstants.RESTORE_INFO_PREF_NAME);
  restorePref?.clearSync();
  let emInfoPref = await preferences.getPreferences(context, RestoreConstants.NEW_EM_INFO_PREF_NAME);
  emInfoPref?.clearSync();
  let contactPref = await preferences.getPreferences(context, RestoreConstants.NEW_EM_CONTACTS_PREF_NAME);
  contactPref?.clearSync();
  LogUtils.e(TAG, 'clearPref clear end');
}
