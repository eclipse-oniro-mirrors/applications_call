/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import rpc from '@ohos.rpc';
import { RPCInfoConstant } from '../common/constant/RPCInfoConstant';
import type { CallBack } from './i_idl_file_permission';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'IdlFilePermissionExtStub';

export default class IdlFilePermissionExtStub extends rpc.RemoteObject {

  public static readonly COMMAND_ALL_FILE_PERMISSION_CHANGE_ACTION = 1001;

  constructor(des: string) {
    super(des);
  }

  // Can return only after the function ends.
  // During a test, the switch does not wait for the method to end and prints the onRemoteMessageRequest end log
  // So return in the case.
  async onRemoteMessageRequest(
    code: number, data: rpc.MessageSequence, reply: rpc.MessageSequence, options: rpc.MessageOption): Promise<boolean> {
    // code：1001、修改所有通话录音文件权限
    if (code < 0 || !reply || !data) {
      reply.writeInt(RPCInfoConstant.PARAM_ERROR_CODE);
      reply.writeString(RPCInfoConstant.PARAM_ERROR_MESSAGE);
      return false;
    }
    if (data.readInterfaceToken() !== RPCInfoConstant.FILE_PERMISSION_VALIDATE_STRING) {
      LogUtils.e(TAG, 'interfaceToken invalidate');
      reply.writeInt(RPCInfoConstant.TOKEN_ERROR_CODE);
      reply.writeString(RPCInfoConstant.TOKEN_ERROR_MESSAGE);
      return false;
    }
    if (code === IdlFilePermissionExtStub.COMMAND_ALL_FILE_PERMISSION_CHANGE_ACTION) {
      try {
        await this.filePermissionChange(reply);
        return true;
      } catch (err) {
        reply.writeInt(RPCInfoConstant.ACTION_ERROR_CODE);
        reply.writeString(RPCInfoConstant.ACTION_ERROR_MESSAGE);
        LogUtils.e(TAG, `file permission change error is ${err?.message}`);
      }
    } else {
      LogUtils.i(TAG, `invalid request code is ${code}`);
    }
    LogUtils.i(TAG, 'onRemoteMessageRequest end');
    return false;
  }

  async filePermissionChange(reply: rpc.MessageSequence): Promise<void> {
    LogUtils.i(TAG, 'filePermissionChange');
    await this.allCallRecorderFilePermissionChange((code, message) => {
      reply.writeInt(code);
      reply.writeString(message);
      LogUtils.i(TAG, `filePermissionChange code is: ${code}, message is: ${message}`);
    });
  }

  async allCallRecorderFilePermissionChange(callback: CallBack): Promise<void> {
    return;
  }
}

