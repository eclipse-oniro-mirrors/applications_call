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
import {
  describe,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import IdlFilePermissionExtImpl from '../../../../main/ets/filePermissionExt/idl_file_permission_ext_impl';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../main/ets/common/constant/Constant';
import { RPCInfoConstant } from '../../../../main/ets/common/constant/RPCInfoConstant';
import { FileUtils } from '../../../../main/ets/common/utils/FileUtils';

let file_permission_ext_implTest_startMigrationServiceFunc_01 = async (testContext: Context) => {
  let filePermissionExtImpl: IdlFilePermissionExtImpl = new IdlFilePermissionExtImpl(testContext);
  await filePermissionExtImpl.allCallRecorderFilePermissionChange((errCode, message) => {
    expect(errCode).assertEqual(RPCInfoConstant.FILE_ERROR_CODE);
  });
};

let file_permission_ext_implTest_startMigrationServiceFunc_02 = async (testContext: Context) => {
  let filePermissionExtImpl: IdlFilePermissionExtImpl = new IdlFilePermissionExtImpl(testContext);
  let mocker: MockKit = new MockKit();
  let dir = '/storage/Users/currentUser/Sounds';
  let mockGetCallRecordDir: Function = mocker.mockFunc(FileUtils, FileUtils.getCallRecordMigrationDir);
  when(mockGetCallRecordDir)(ArgumentMatchers.any).afterReturn(dir);
  await filePermissionExtImpl.allCallRecorderFilePermissionChange((errCode, message) => {
    expect(message).assertEqual(RPCInfoConstant.FILE_ERROR_MESSAGE);
  });
  mocker.ignoreMock(FileUtils, FileUtils.getCallRecordGroupDir);
};


export default function file_permission_ext_implTest() {
  describe('file_permission_ext_implTest', () => {
    let testContext: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('file_permission_ext_implTest_startMigrationServiceFunc_01', 0, async () => {
      file_permission_ext_implTest_startMigrationServiceFunc_01(testContext);
    })
    it('file_permission_ext_implTest_startMigrationServiceFunc_02', 0, async () => {
      file_permission_ext_implTest_startMigrationServiceFunc_02(testContext);
    });
  });
}