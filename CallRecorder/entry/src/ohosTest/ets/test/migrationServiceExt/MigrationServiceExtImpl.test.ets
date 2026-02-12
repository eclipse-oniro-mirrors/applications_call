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
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import MigrationServiceExtImpl from '../../../../main/ets/migrationServiceExt/MigrationServiceExtImpl';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../main/ets/common/constant/Constant';
import { RPCInfoConstant } from '../../../../main/ets/common/constant/RPCInfoConstant';
import { MigrationConstant, MigrationProcessStatus } from '../../../../main/ets/common/constant/MigrationConstant';
import { relationalStore } from '@kit.ArkData';
import { MigrationProgress, MigrationResult } from '../../../../main/ets/common/struct/MigrationStruct';

let migrationServiceExtImplTest_startMigrationService = (testContext: Context) => {
  let serviceImpl: MigrationServiceExtImpl = new MigrationServiceExtImpl(testContext);
  serviceImpl.startMigrationService((errCode, message) => {
    expect(errCode).assertEqual(RPCInfoConstant.INTERNAL_ERROR_CODE);
  });
};

let migrationServiceExtImplTest_stopMigrationService = (testContext: Context) => {
  let serviceImpl: MigrationServiceExtImpl = new MigrationServiceExtImpl(testContext);
  serviceImpl.stopMigrationService();
  let signal = Atomics.load(MigrationServiceExtImpl.processSignal, 0);
  expect(signal).assertEqual(MigrationProcessStatus.STOP);
};

let migrationServiceExtImplTest_pauseMigrationService = (testContext: Context) => {
  let serviceImpl: MigrationServiceExtImpl = new MigrationServiceExtImpl(testContext);
  serviceImpl.pauseMigrationService();
  let signal = Atomics.load(MigrationServiceExtImpl.processSignal, 0);
  expect(signal).assertEqual(MigrationProcessStatus.PAUSE);
};

let migrationServiceExtImplTest_resumeMigrationService = (testContext: Context) => {
  let serviceImpl: MigrationServiceExtImpl = new MigrationServiceExtImpl(testContext);
  serviceImpl.resumeMigrationService((errCode, message) => {
    expect(errCode).assertEqual(RPCInfoConstant.INTERNAL_ERROR_CODE);
  });
};

let migrationServiceExtImplTest_startMigrationWorker = async (testContext: Context) => {
  let serviceImpl: MigrationServiceExtImpl = new MigrationServiceExtImpl(testContext);
  let autoBackupConfig: relationalStore.StoreConfig = {
    name: MigrationConstant.DATABASE,
    securityLevel: relationalStore.SecurityLevel.S1,
    haMode: relationalStore.HAMode.MAIN_REPLICA,
    allowRebuild: true
  }
  let store = await relationalStore.getRdbStore(testContext, autoBackupConfig);
  let result = new MigrationResult();
  serviceImpl.startMigrationWorker(result, store, [], new MigrationProgress());
  let signal = Atomics.load(MigrationServiceExtImpl.processSignal, 0);
  expect(signal).assertEqual(MigrationProcessStatus.STOP);
};

let migrationServiceExtImplTest_stopMigrationWhenOnDisconnect = (testContext: Context) => {
  let serviceImpl: MigrationServiceExtImpl = new MigrationServiceExtImpl(testContext);
  let ret = serviceImpl.stopMigrationWhenOnDisconnect();
  expect(ret === undefined).assertTrue();
};

export default function MigrationServiceExtImplTest() {
  describe('MigrationServiceExtImplTest', () => {
    let testContext: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('MigrationServiceExtImplTest_startMigrationService', 0, () => {
      migrationServiceExtImplTest_startMigrationService(testContext);
    });
    it('MigrationServiceExtImplTest_stopMigrationService', 0, () => {
      migrationServiceExtImplTest_stopMigrationService(testContext);
    });
    it('MigrationServiceExtImplTest_pauseMigrationService', 0, () => {
      migrationServiceExtImplTest_pauseMigrationService(testContext);
    });
    it('MigrationServiceExtImplTest_resumeMigrationService', 0, () => {
      migrationServiceExtImplTest_resumeMigrationService(testContext);
    });
    it('MigrationServiceExtImplTest_startMigrationWorker', 0, async () => {
      migrationServiceExtImplTest_startMigrationWorker(testContext);
    });
    it('MigrationServiceExtImplTest_stopMigrationWhenOnDisconnect', 0, () => {
      migrationServiceExtImplTest_stopMigrationWhenOnDisconnect(testContext);
    });
  });
}