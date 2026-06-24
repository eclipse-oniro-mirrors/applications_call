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

import { describe, beforeEach, it, expect, beforeAll } from '@ohos/hypium'
import { common } from '@kit.AbilityKit';
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import * as RestoreConstants from '../../../../main/ets/backup/RestoreConstants';
import preferences from '@ohos.data.preferences';
import LogUtils from '../../../../main/ets/utils/HiLog';
import { prefUtils } from '../../../../main/ets/backup/PrefUtils';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const TAG = 'test_PrefUtils';

export default function PrefUtilsTest() {
  let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
  let testContext: common.Context = abilityDelegator.getAppContext();
  beforeAll(async () => {
    LogUtils.i(TAG, `beforeAll get context:${testContext}`);
  })
  beforeEach(async () => {
    LogUtils.i(TAG, `beforeEach get context:${testContext}`);
  })
  describe('PrefUtilsTest', () => {
    it('PrefUtilsTest_testEmptyContext', 0, async () => {
      LogUtils.i(TAG, 'Test_000 enter');
      await testEmptyContext();
    })
    it('PrefUtilsTest_000', 0, async () => {
      LogUtils.i(TAG, 'Test_000 enter');
      await test_000(testContext);
    })
    it('PrefUtilsTest_001', 0, async () => {
      await test_001(testContext);
    })
  })
}

export async function testEmptyContext(): Promise<void> {
  let testEmptyContext = EmergencyGlobalContextHelper.getContext().getValue<common.Context>('testGetContext');
  let canInit = await prefUtils.init(testEmptyContext);
  LogUtils.i(TAG, `testEmptyContext canInited:${canInit}`);
  expect(canInit).assertFalse();

  let emptyOldUriList = await prefUtils.getOldEmContactsUriList();
  LogUtils.i(TAG, `testEmptyContext emptyOldUriList:${emptyOldUriList}`);
  expect(emptyOldUriList === '').assertTrue();

  let getEmptyKeyResult = await prefUtils.getStatus('', '');
  LogUtils.i(TAG, `testEmptyContext getEmptyKeyResult:${getEmptyKeyResult}`);
  expect(getEmptyKeyResult !== '').assertTrue();

  let testKey = 'testKey';
  let testVal = 1;
  await prefUtils.saveParsedOldInfoToPref(RestoreConstants.OLD_EM_CONTACTS_KEY, testVal);
  await prefUtils.saveParsedOldInfoToPref(testKey, testVal);
  await prefUtils.saveToPref(testKey, testVal, RestoreConstants.NEW_EM_CONTACTS_PREF_NAME);
  await prefUtils.saveToPref(testKey, testVal, testKey);
  let result = await prefUtils.getStatus(testKey, testVal);
  let result2 = await prefUtils.getStatus('', '');
  LogUtils.i(TAG, `testEmptyContext getStatus result:${result} result:${result2}`);
  expect(!result2).assertTrue();
}

async function test_000(context: common.Context) {
  LogUtils.i(TAG, 'test_000 test valid context and invalid param start');
  let canInit: boolean = await prefUtils.init(context);
  LogUtils.i(TAG, `test_000 canInited:${canInit}`);
  if (canInit) {
    expect(canInit).assertTrue();
  } else {
    LogUtils.w(TAG, `test_000 can not get valid context, continue test return`);
    expect(canInit).assertFalse();
    return;
  }

  let emptyOldUriList = await prefUtils.getOldEmContactsUriList();
  LogUtils.i(TAG, `test_000 emptyOldUriList:${emptyOldUriList}`);
  expect(emptyOldUriList === '').assertFalse();
  await prefUtils.saveParsedOldInfoToPref(RestoreConstants.OLD_EM_CONTACTS_KEY, '');
  let getUriList = await prefUtils.getOldEmContactsUriList();
  LogUtils.i(TAG, `test_000 getUriList:${getUriList}`);
  expect(getUriList === '').assertTrue();

  let testUndefKey = EmergencyGlobalContextHelper.getContext().getValue<string>('testEmptyStringKey');
  LogUtils.i(TAG, `test_000 testUndefKey:${testUndefKey}`);
  await prefUtils.saveToPref(testUndefKey, '');
  let testUndefVal = EmergencyGlobalContextHelper.getContext().getValue<string>('testEmptyStringVal');
  LogUtils.i(TAG, `test_000 testUndefVal:${testUndefVal}`);
  await prefUtils.saveToPref(RestoreConstants.OLD_EM_CONTACTS_KEY, testUndefVal);

  let curStatus: preferences.ValueType | undefined = await prefUtils.getStatus(RestoreConstants.RESTORE_PROGRESS_KEY,
    RestoreConstants.RestoreProgress.INIT);
  LogUtils.i(TAG, 'test_000 curRestoreProgress:' + curStatus);
}

async function test_001(context: common.Context) {
  LogUtils.i(TAG, 'test_001 test normal param start');
  let canInit: boolean = await prefUtils.init(context);
  LogUtils.i(TAG, `test_000 canInited:${canInit}`);
  if (!canInit) {
    LogUtils.w(TAG, `test_000 can not get valid context, continue test return`);
    expect(canInit).assertFalse();
    return;
  }

  let testUriList = 'content://com.andoid.contacts/data/8';
  await prefUtils.saveParsedOldInfoToPref(RestoreConstants.OLD_EM_CONTACTS_KEY, testUriList);
  let getOldUriList = await prefUtils.getOldEmContactsUriList();
  LogUtils.i(TAG, `test_001 getOldUriList:${getOldUriList}`);
  expect(getOldUriList === testUriList).assertTrue();

  let testName = 'Andy';
  await prefUtils.saveParsedOldInfoToPref('name', testName);
  let emInfoPref = await preferences.getPreferences(context, RestoreConstants.NEW_EM_INFO_PREF_NAME);
  let getName = emInfoPref.getSync('name', '');
  LogUtils.i(TAG, `test_001 getName:${getName}`);
  expect(getName === testName).assertTrue();

  await prefUtils.saveToPref(RestoreConstants.RESTORE_PROGRESS_KEY, 'TestPref');
  await prefUtils.saveToPref(RestoreConstants.RESTORE_PROGRESS_KEY, RestoreConstants.RestoreProgress.INIT);
  let getCurStatus: number = await prefUtils.getStatus(RestoreConstants.RESTORE_PROGRESS_KEY,
    RestoreConstants.RestoreProgress.STATUS_UNKNOWN) as number;
  LogUtils.i(TAG, `test_001 getCurStatus:${getCurStatus}`);
  expect(getCurStatus === RestoreConstants.RestoreProgress.INIT).assertTrue();
}