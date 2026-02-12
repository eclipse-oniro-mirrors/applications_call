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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import rpc from '@ohos.rpc'
import MigrationServiceExtStub from '../../../../main/ets/migrationServiceExt/MigrationServiceExtStub'
import { MigrationCommand } from '../../../../main/ets/common/constant/MigrationConstant';
import { RPCInfoConstant } from '../../../../main/ets/common/constant/RPCInfoConstant';

let migrationServiceExtStubTest_onRemoteMessageRequest_01 = async () => {
  let des: string = 'test';
  let migrationServiceExtStubTest = new MigrationServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  data.writeInterfaceToken(RPCInfoConstant.VALIDATE_STRING);
  data.writeRemoteObject(new rpc.RemoteObject('progress_callback'));
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol = await migrationServiceExtStubTest.onRemoteMessageRequest(MigrationCommand.START_MIGRATION, data, reply,
    options);
  expect(bol).assertEqual(true);
}

let migrationServiceExtStubTest_onRemoteMessageRequest_02 = async () => {
  let des: string = 'test';
  let migrationServiceExtStubTest = new MigrationServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  data.writeInterfaceToken(RPCInfoConstant.VALIDATE_STRING);
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol =
    await migrationServiceExtStubTest.onRemoteMessageRequest(MigrationCommand.STOP_MIGRATION, data, reply, options);
  expect(bol).assertEqual(true);
}

let migrationServiceExtStubTest_onRemoteMessageRequest_03 = async () => {
  let des: string = 'test';
  let migrationServiceExtStubTest = new MigrationServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  data.writeInterfaceToken(RPCInfoConstant.VALIDATE_STRING);
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol =
    await migrationServiceExtStubTest.onRemoteMessageRequest(MigrationCommand.PAUSE_MIGRATION, data, reply, options);
  expect(bol).assertEqual(true);
}

let migrationServiceExtStubTest_onRemoteMessageRequest_04 = async () => {
  let des: string = 'test';
  let migrationServiceExtStubTest = new MigrationServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  data.writeInterfaceToken(RPCInfoConstant.VALIDATE_STRING);
  data.writeRemoteObject(new rpc.RemoteObject('progress_callback'));
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol =
    await migrationServiceExtStubTest.onRemoteMessageRequest(MigrationCommand.RESUME_MIGRATION, data, reply, options);
  expect(bol).assertEqual(true);
}

export default function MigrationServiceExtStubTest() {
  describe('MigrationServiceExtStubTest', () => {
    it('migrationServiceExtStubTest_onRemoteMessageRequest_01', 0, async () => {
      await migrationServiceExtStubTest_onRemoteMessageRequest_01();
    });
    it('migrationServiceExtStubTest_onRemoteMessageRequest_02', 0, async () => {
      await migrationServiceExtStubTest_onRemoteMessageRequest_02();
    });
    it('migrationServiceExtStubTest_onRemoteMessageRequest_03', 0, async () => {
      await migrationServiceExtStubTest_onRemoteMessageRequest_03();
    });
    it('migrationServiceExtStubTest_onRemoteMessageRequest_04', 0, async () => {
      await migrationServiceExtStubTest_onRemoteMessageRequest_04();
    });
  });
}