/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { describe, it, expect } from '@ohos/hypium';
import rpc from '@ohos.rpc'
import IdlFilePermissionExtStub from '../../../../main/ets/filePermissionExt/idl_file_permission_ext_stub';
import { RPCInfoConstant } from '../../../../main/ets/common/constant/RPCInfoConstant';

const  COMMAND_ALL_FILE_PERMISSION_CHANGE_ACTION = 1001;

let file_permission_ext_stubTest_onRemoteMessageRequest_01 = async () => {
  let des: string = 'test';
  let file_permission_ext_stubTest = new IdlFilePermissionExtStub(des);
  let data: rpc.MessageSequence = rpc.MessageSequence.create();
  data.writeInterfaceToken(RPCInfoConstant.FILE_PERMISSION_VALIDATE_STRING);
  let reply: rpc.MessageSequence = rpc.MessageSequence.create();
  let options = new rpc.MessageOption();
  let bol = await file_permission_ext_stubTest.onRemoteMessageRequest(
    COMMAND_ALL_FILE_PERMISSION_CHANGE_ACTION, data, reply, options);
  expect(bol).assertEqual(true);
}

export default function file_permission_ext_stubTest() {
  describe('file_permission_ext_stubTest', () => {
    it('file_permission_ext_stubTest_onRemoteMessageRequest_01', 0, async () => {
      await file_permission_ext_stubTest_onRemoteMessageRequest_01();
    });
  });
}