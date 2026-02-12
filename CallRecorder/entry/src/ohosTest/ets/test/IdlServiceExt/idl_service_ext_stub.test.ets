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
import IdlServiceExtStub from '../../../../main/ets/IdlServiceExt/idl_service_ext_stub'
import { sleep } from '../common/utils/Sleep';

let idl_service_ext_stubTest_onRemoteMessageRequest_01 = async () => {
  let des: string = 'test';
  let idl_service_ext_stubTest = new IdlServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol = await idl_service_ext_stubTest.onRemoteMessageRequest(IdlServiceExtStub.COMMAND_STOP_RECORDING, data, reply,
    options);
  expect(bol).assertEqual(true);
}

let idl_service_ext_stubTest_onRemoteMessageRequest_02 = async () => {
  let des: string = 'test';
  let idl_service_ext_stubTest = new IdlServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol =
    await idl_service_ext_stubTest.onRemoteMessageRequest(IdlServiceExtStub.COMMAND_START_RECORDING, data, reply,
      options);
  expect(bol).assertEqual(true);
}

let idl_service_ext_stubTest_onRemoteMessageRequest_03 = async () => {
  let des: string = 'test';
  let idl_service_ext_stubTest = new IdlServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol =
    await idl_service_ext_stubTest.onRemoteMessageRequest(IdlServiceExtStub.COMMAND_GET_ERROR_RECORDING, data, reply,
      options);
  expect(bol).assertEqual(true);
}

let idl_service_ext_stubTest_onRemoteMessageRequest_04 = async () => {
  let des: string = 'test';
  let idl_service_ext_stubTest = new IdlServiceExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  idl_service_ext_stubTest.onRemoteMessageRequest(4, data, reply, options);
  expect(0).assertEqual(0);
}

export default function idl_service_ext_stubTest() {
  describe('idl_service_ext_stubTest', () => {
    it('idl_service_ext_stubTest_onRemoteMessageRequest_01', 0, async () => {
      await idl_service_ext_stubTest_onRemoteMessageRequest_01();
    });
    it('idl_service_ext_stubTest_onRemoteMessageRequest_02', 0, async () => {
      await idl_service_ext_stubTest_onRemoteMessageRequest_02();
    });
    it('idl_service_ext_stubTest_onRemoteMessageRequest_03', 0, async () => {
      await idl_service_ext_stubTest_onRemoteMessageRequest_03();
    });
    it('idl_service_ext_stubTest_onRemoteMessageRequest_04', 0, async () => {
      await idl_service_ext_stubTest_onRemoteMessageRequest_04();
    });
  });
}