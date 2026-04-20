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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect} from '@ohos/hypium'
import rpc from '@ohos.rpc'
import { MigrationServiceHelper } from '../../../../main/ets/migrationServiceExt/MigrationServiceHelper';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import { Constant } from '../../../../main/ets/common/constant/Constant';
import common from '@ohos.app.ability.common';
import { MigrationProgress } from '../../../../main/ets/common/struct/MigrationStruct';
import { relationalStore } from '@kit.ArkData';
import { MigrationConstant } from '../../../../main/ets/common/constant/MigrationConstant';
import { RecordLog } from '../../../../main/ets/common/struct/RecorderStruct';

let migrationServiceHelperTestForRPCData = () => {
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  data.writeRemoteObject(new rpc.RemoteObject('progress_callback'))
  let ret = MigrationServiceHelper.handleRegister(data);
  expect(ret === undefined).assertTrue();

  let code = 1;
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();

  let result = MigrationServiceHelper.send2Client(code, data, reply, options);
  expect(result === undefined).assertTrue();
}

let migrationServiceHelperTest_setPauseMigrationProgress = (testContext: Context) => {
  let info = new MigrationProgress();
  let ret = MigrationServiceHelper.setPauseMigrationProgress(testContext, info);
  expect(ret === undefined).assertTrue();
}

let migrationServiceHelperTest_getPauseMigrationProgress = (testContext: Context) => {
  let ret = MigrationServiceHelper.getPauseMigrationProgress(testContext);
  expect(ret != undefined).assertTrue();
}

let migrationServiceHelperTest_clearPauseMigrationProgress = (testContext: Context) => {
  let ret = MigrationServiceHelper.clearPauseMigrationProgress(testContext);
  expect(ret === undefined).assertTrue();
}

let migrationServiceHelperTest_sendMigrationProgress = () => {
  let info = new MigrationProgress();
  let ret = MigrationServiceHelper.sendMigrationProgress(info);
  expect(ret === undefined).assertTrue();
}

let migrationServiceHelperTest_setMigrationSignal = async (testContext: Context) => {
  let autoBackupConfig: relationalStore.StoreConfig = {
    name: MigrationConstant.DATABASE,
    securityLevel: relationalStore.SecurityLevel.S1,
    haMode: relationalStore.HAMode.MAIN_REPLICA,
    allowRebuild: true
  }
  let store = await relationalStore.getRdbStore(testContext, autoBackupConfig);
  let info = new MigrationProgress();
  let ret = MigrationServiceHelper.setMigrationSignal(store, info);
  expect(ret === undefined).assertTrue();
}

let migrationServiceHelperTest_buildAndInsertMigrationRecords = async (testContext: Context) => {
  let record = new RecordLog();
  record.filePath = '/data/storage/el2/group/ce8bb522-f6ac-3c7c-cd6e-f6494b9a0519/CallRecord/aaaaaa.m4a';
  record.displayName = 'aaaaaa';
  let record1 = new RecordLog();
  record1.filePath = '/data/storage/el2/group/ce8bb522-f6ac-3c7c-cd6e-f6494b9a0519/CallRecord/bbbbbb.amr';
  record1.displayName = 'bbbbbb';
  let prefix = '/storage/Users/currentUser/Sounds/'
  let ret = await MigrationServiceHelper.buildAndInsertMigrationRecords(testContext, [record, record1], prefix);
  expect(ret.length).assertEqual(2);
}

let migrationServiceHelperTest_queryNotMigratedRecord = async (testContext: Context) => {
  let ret = await MigrationServiceHelper.queryNotMigratedRecord(testContext);
  expect(ret.length).assertEqual(0);
}

let migrationServiceHelperTest_queryNotMigratedRecordLog = async (testContext: Context) => {
  let prefix = '/storage/Users/currentUser/Sounds/'
  let ret = await MigrationServiceHelper.queryNotMigratedRecordLog(testContext, prefix);
  expect(ret.length).assertEqual(0);
}

let migrationServiceHelperTest_batchUpdateRecordLogDisplayNameWithSuffix = async (testContext: Context) => {
  let m4aFilePaths = ['/data/storage/el2/group/ce8bb522-f6ac-3c7c-cd6e-f6494b9a0519/CallRecord/aaaaaa.m4a'];
  let amrFilePaths = ['/data/storage/el2/group/ce8bb522-f6ac-3c7c-cd6e-f6494b9a0519/CallRecord/bbbbbb.amr'];
  let ret = await MigrationServiceHelper.batchUpdateRecordLogDisplayNameWithSuffix(testContext, m4aFilePaths,
    amrFilePaths);
  expect(ret === undefined).assertTrue();
}

export default function MigrationServiceHelperTest() {
  describe('MigrationServiceHelperTest', () => {
    let testContext: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('migrationServiceHelperTestForRPCData', 0, () => {
      migrationServiceHelperTestForRPCData();
    });
    it('migrationServiceHelperTest_setPauseMigrationProgress', 0, () => {
      migrationServiceHelperTest_setPauseMigrationProgress(testContext);
    });
    it('migrationServiceHelperTest_getPauseMigrationProgress', 0, () => {
      migrationServiceHelperTest_getPauseMigrationProgress(testContext);
    });
    it('migrationServiceHelperTest_clearPauseMigrationProgress', 0, () => {
      migrationServiceHelperTest_clearPauseMigrationProgress(testContext);
    });
    it('migrationServiceHelperTest_sendMigrationProgress', 0, () => {
      migrationServiceHelperTest_sendMigrationProgress();
    });
    it('migrationServiceHelperTest_setMigrationSignal', 0, () => {
      migrationServiceHelperTest_setMigrationSignal(testContext);
    });
    it('migrationServiceHelperTest_buildAndInsertMigrationRecords', 0, () => {
      migrationServiceHelperTest_buildAndInsertMigrationRecords(testContext);
    });
    it('migrationServiceHelperTest_queryNotMigratedRecord', 0, () => {
      migrationServiceHelperTest_queryNotMigratedRecord(testContext);
    });
    it('migrationServiceHelperTest_queryNotMigratedRecordLog', 0, () => {
      migrationServiceHelperTest_queryNotMigratedRecordLog(testContext);
    });
    it('migrationServiceHelperTest_batchUpdateRecordLogDisplayNameWithSuffix', 0, () => {
      migrationServiceHelperTest_batchUpdateRecordLogDisplayNameWithSuffix(testContext);
    });
  });
}