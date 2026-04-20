/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import { MigrationCommand, StartMigrationCallBack } from '../common/constant/MigrationConstant';
import { RPCInfoConstant } from '../common/constant/RPCInfoConstant';
import LogUtils from '../common/utils/LogUtils';
import { MigrationServiceHelper } from './MigrationServiceHelper';

const TAG = 'MigrationServiceExtStub';

export default class MigrationServiceExtStub extends rpc.RemoteObject {
  constructor(des: string) {
    super(des);
  }

  // Can return only after the function ends.
  // During a test, the switch does not wait for the method to end and prints the onRemoteMessageRequest end log
  // So return in the case.
  async onRemoteMessageRequest(
    code: number, data: rpc.MessageSequence, reply: rpc.MessageSequence, options: rpc.MessageOption): Promise<boolean> {
    let interfaceToken = data.readInterfaceToken();
    if (interfaceToken !== RPCInfoConstant.VALIDATE_STRING) {
      LogUtils.e(TAG, 'interfaceToken invalidate');
      reply.writeInt(RPCInfoConstant.TOKEN_ERROR_CODE);
      reply.writeString(RPCInfoConstant.TOKEN_ERROR_MESSAGE);
      return true;
    }
    LogUtils.i(TAG, `onRemoteMessageRequest start code: ${code}`);
    switch (code) {
      case MigrationCommand.STOP_MIGRATION: {
        this.stopServiceCase(reply);
        return true;
      }
      case MigrationCommand.START_MIGRATION: {
        MigrationServiceHelper.handleRegister(data);
        this.startServiceCase(data, reply);
        return true;
      }
      case MigrationCommand.PAUSE_MIGRATION: {
        this.pauseServiceCase(reply);
        return true;
      }
      case MigrationCommand.RESUME_MIGRATION: {
        MigrationServiceHelper.handleRegister(data);
        this.resumeServiceCase(reply);
        return true;
      }
      default: {
        LogUtils.i(TAG, `invalid request code: ${code}`);
        break;
      }
    }
    LogUtils.i(TAG, 'onRemoteMessageRequest end');
    return true;
  }

  stopServiceCase(reply: rpc.MessageSequence) {
    this.stopMigrationService();
    reply.writeInt(RPCInfoConstant.SUCCESS_STATUS_CODE);
    reply.writeString(RPCInfoConstant.SUCCESS_STATUS_MESSAGE);
  }

  startServiceCase(data: rpc.MessageSequence, reply: rpc.MessageSequence) {
    this.startMigrationService((code, message) => {
      reply.writeInt(code);
      reply.writeString(message);
      LogUtils.i(TAG, `startServiceCase code: ${code}, message: ${message}`);
    });
    LogUtils.i(TAG, 'startServiceCase end');
  }

  pauseServiceCase(reply: rpc.MessageSequence) {
    this.pauseMigrationService();
    reply.writeInt(RPCInfoConstant.SUCCESS_STATUS_CODE);
    reply.writeString(RPCInfoConstant.SUCCESS_STATUS_MESSAGE);
  }

  resumeServiceCase(reply: rpc.MessageSequence) {
    this.resumeMigrationService((code, message) => {
      reply.writeInt(code);
      reply.writeString(message);
      LogUtils.i(TAG, `resumeServiceCase code: ${code}, message: ${message}`);
    });
    LogUtils.i(TAG, 'resumeServiceCase end');
  }

  stopMigrationService() {
    return;
  }

  startMigrationService(callback: StartMigrationCallBack): void {
    return;
  }

  pauseMigrationService() {
    return;
  }

  resumeMigrationService(callback: StartMigrationCallBack): void {
    return;
  }
}
