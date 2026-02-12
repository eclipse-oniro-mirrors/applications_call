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

import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  when,
  MockKit,
  ArgumentMatchers
} from '@ohos/hypium';
import { Driver } from '@kit.TestKit';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import LogUtils from '../../../../main/ets/utils/HiLog';
import { prefUtils } from '../../../../main/ets/backup/PrefUtils';
import * as RestoreConstants from '../../../../main/ets/backup/RestoreConstants';
import * as Constants from '../../../../main/ets/utils/Constants';
import RestoreUtils from '../../../../main/ets/backup/RestoreUtils';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import preferences from '@ohos.data.preferences';
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';

const BUNDLE_NAME = 'com.ohos.emergencycommunication';
const SERVICE_ABILITY_NAME = 'BackupExtensionAbility';
const CALL_ABILITY_NAME = 'com.ohos.emergencycommunication.EmergencyCallAbility';
const DELAY_TIME = 1000;
const TEST_PREF_KEY_TEST = 'TEST_RESTORE_KEY';
const TEST_PREF_KEY_VAL = 'TEST_RESTORE_VAL';

const TAG = 'test_RestoreUtils';

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

export async function startBackService(): Promise<void> {
  let want: Want = {
    bundleName: BUNDLE_NAME,
    abilityName: SERVICE_ABILITY_NAME
  }
  LogUtils.i(TAG, 'startBackService from abilityDelegator');
  let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
  abilityDelegator.startAbility(want);
  let driver = Driver.create();
  await driver.delayMs(DELAY_TIME);
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

export async function clearPref(context: common.Context) {
  LogUtils.e(TAG, 'clearPref start');
  let restorePref = await preferences.getPreferences(context, RestoreConstants.RESTORE_INFO_PREF_NAME);
  restorePref?.clearSync();
  let emInfoPref = await preferences.getPreferences(context, RestoreConstants.NEW_EM_INFO_PREF_NAME);
  emInfoPref?.clearSync();
  let contactPref = await preferences.getPreferences(context, RestoreConstants.NEW_EM_CONTACTS_PREF_NAME);
  contactPref?.clearSync();
  LogUtils.e(TAG, 'clearPref clear end');
  expect(true).assertTrue();
}

export default function RestoreUtilsTest() {
  let testContext: common.Context
  let restore = RestoreUtils.getInstance();
  let mocker: MockKit = new MockKit();
  beforeAll(() => {
    testContext = EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT);
  })
  beforeEach(async () => {
    LogUtils.i(TAG, `beforeEach get context:${testContext}`);
  });
  describe('RestoreUtilsTest', () => {
    it('RestoreUtilsTest_testEmptyContext', 0, async () => {
      await testEmptyContext();
    });
    it('RestoreUtilsTest_getCtxAndInitPref', 0, async () => {
      await getCtxAndInitPref(testContext);
    });
    it('RestoreUtilsTest_end', 0, async () => {
      await clearPref(testContext);
    });
    it('RestoreUtilsTest_init', 0, async () => {
      await (restore as object)['init'](testContext);
      await restore.startRestore(testContext, '');
      await restore.startRestore(testContext, '0.0.0.0.1.1');
      let mockFunc = mocker.mockFunc(prefUtils, prefUtils.init);
      when(mockFunc)(testContext).afterReturn(false);
      await (restore as object)['init'](testContext);
      mocker.ignoreMock(prefUtils, prefUtils.init);
      let mockFunc1 = mocker.mockFunc(prefUtils, prefUtils.getStatus);
      await (restore as object)['startProcess'](testContext);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(2);
      let mockFunc2 = mocker.mockFunc(restore, (restore as object)['parseXmlToPref']);
      when(mockFunc2)(ArgumentMatchers.any).afterReturn(new Promise<string>((resolve: Function, reject: Function) => {
        resolve(false);
      }));
      await (restore as object)['startProcess'](testContext);
      await (restore as object)['parseXmlToPref'](testContext);
      await restore.checkNeedContinueRestore(testContext);
      when(mockFunc1)(ArgumentMatchers.any).afterReturn(0);
      await restore.checkNeedContinueRestore(testContext);
      mocker.ignoreMock(restore, (restore as object)['parseXmlToPref']);
      mocker.ignoreMock(prefUtils, prefUtils.getStatus);
    });
  });
}

async function testEmptyContext(): Promise<void> {
  let testEmptyContext = EmergencyGlobalContextHelper.getContext().getValue<common.Context>('testGetContext');
  await RestoreUtils.getInstance().startRestore(testEmptyContext, '');
  let emptyCtxRestoreProgress = await prefUtils.getStatus(RestoreConstants.RESTORE_PROGRESS_KEY,
    RestoreConstants.RestoreProgress.STATUS_UNKNOWN) as number;
  LogUtils.i(TAG, `testEmptyContext emptyCtxRestoreProgress:${emptyCtxRestoreProgress}`);
  expect(emptyCtxRestoreProgress === RestoreConstants.RestoreProgress.STATUS_UNKNOWN).assertFalse()

  await RestoreUtils.getInstance().checkNeedContinueRestore(testEmptyContext);
  let emptyCtxCheckedFromAbility = await prefUtils.getStatus(RestoreConstants.RESTORE_FROM_ABILITY, false) as boolean;
  LogUtils.i(TAG, `testEmptyContext emptyCtxCheckedFromAbility:${emptyCtxCheckedFromAbility}`);
  expect(!emptyCtxRestoreProgress).assertTrue()
}

async function test_000(testContext: common.Context) {
  LogUtils.i(TAG, 'Test_000 for test empty parm start');
  if (testContext) {
    await RestoreUtils.getInstance().startRestore(testContext, '');
    let test0VerVal = await prefUtils.getStatus(RestoreConstants.RESTORE_PROGRESS_KEY,
      RestoreConstants.RestoreProgress.STATUS_UNKNOWN) as number;
    LogUtils.i(TAG, `Test_000 test0VerVal:${test0VerVal}`);
    expect(RestoreConstants.RestoreProgress.RESTORE_SUCCESS !== test0VerVal).assertTrue();

    await RestoreUtils.getInstance().startRestore(testContext,
      RestoreConstants.RestoreVersion.VER_DUAL_UPGRADE_TO_SINGLE);
    let testUpgradeVerVal = await prefUtils.getStatus(RestoreConstants.RESTORE_PROGRESS_KEY,
      RestoreConstants.RestoreProgress.STATUS_UNKNOWN) as number;
    let isSuccess = (RestoreConstants.RestoreProgress.RESTORE_SUCCESS === testUpgradeVerVal);
    LogUtils.i(TAG, `Test_000 testUpgradeVerVal:${testUpgradeVerVal} isSuccess:${isSuccess}`);
    expect(isSuccess).assertTrue()

    await prefUtils.saveToPref(RestoreConstants.RESTORE_PROGRESS_KEY, RestoreConstants.RestoreProgress.INIT);
    await RestoreUtils.getInstance().checkNeedContinueRestore(testContext);
    let emptyParamCheckedFromAbility =
      await prefUtils.getStatus(RestoreConstants.RESTORE_FROM_ABILITY, false) as boolean;
    LogUtils.i(TAG, `testEmptyContext emptyParamCheckedFromAbility:${emptyParamCheckedFromAbility}`);
    expect(emptyParamCheckedFromAbility).assertTrue();
  } else {
    LogUtils.i(TAG, 'Test_000 cannot get valid context');
    expect(!testContext).assertTrue();
  }
}

async function test_001(testContext: common.Context) {
  LogUtils.i(TAG, 'test_001 test normal param for  start');
  let testStatusVal = await prefUtils.getStatus(TEST_PREF_KEY_TEST, TEST_PREF_KEY_VAL) as string;
  LogUtils.i(TAG, 'test_001 get testStatusVal' + testStatusVal);
  if (!testContext) {
    LogUtils.i(TAG, 'test_001 get context failed');
    expect(!testStatusVal).assertTrue();
    return;
  }
  expect(TEST_PREF_KEY_VAL === testStatusVal).assertTrue();

  let beginStatus = await prefUtils.getStatus(RestoreConstants.RESTORE_PROGRESS_KEY,
    RestoreConstants.RestoreProgress.STATUS_UNKNOWN) as number;
  LogUtils.i(TAG, `test_001 beginStatus:${beginStatus}`);
  await startBackService();
  let endStatus = await prefUtils.getStatus(RestoreConstants.RESTORE_PROGRESS_KEY,
    RestoreConstants.RestoreProgress.STATUS_UNKNOWN) as number;
  LogUtils.i(TAG, `test_001 endStatus:${endStatus}`);
  expect(endStatus === beginStatus).assertTrue();
}
