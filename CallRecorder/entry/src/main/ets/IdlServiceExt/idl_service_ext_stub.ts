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
import type { StartRecordingCallBack, RecordingGetIsErrorCallBack } from './i_idl_service_ext';
import rpc from '@ohos.rpc';
import type { RecordInputParameter } from '../common/struct/idlStruct';

const TAG = 'idl_service_ext_stub';

export default class IdlServiceExtStub extends rpc.RemoteObject {
  constructor(des: string) {
    super(des);
  }

  // Can return only after the function ends.
  // During a test, the switch does not wait for the method to end and prints the onRemoteMessageRequest end log
  // So return in the case.
  async onRemoteMessageRequest(
    code: number, data: rpc.MessageSequence, reply: rpc.MessageSequence, options: rpc.MessageOption): Promise<boolean> {
    console.log(TAG + 'onRemoteMessageRequest start code=' + code);
    switch (code) {
      case IdlServiceExtStub.COMMAND_STOP_RECORDING: {
        await this.stopServiceCase(reply);
        return true;
      }
      case IdlServiceExtStub.COMMAND_START_RECORDING: {
        await this.startServiceCase(data, reply);
        return true;
      }
      case IdlServiceExtStub.COMMAND_GET_ERROR_RECORDING: {
        await this.getErrorServiceCase(reply);
        return true;
      }
      default: {
        console.log(TAG + 'invalid request code' + code);
        break;
      }
    }
    console.log(TAG + 'onRemoteMessageRequest end');
    return true;
  }

  async getErrorServiceCase(reply: rpc.MessageSequence): Promise<void> {
    this.getErrorService((code, message) => {
      reply.writeInt(code);
      reply.writeString(message);
      console.log(TAG + 'startServiceCase code' + code + 'message' + message);
    });
  }

  async stopServiceCase(reply: rpc.MessageSequence): Promise<void> {
    await this.stopService();
    reply.writeInt(0);
  }

  async startServiceCase(data: rpc.MessageSequence, reply: rpc.MessageSequence): Promise<void> {
    let accountNumber = data.readString();
    let startTime = data.readLong();
    let mode = data.readInt();
    let callList = data.readStringArray();
    let callTimeList = data.readLongArray();
    let fileNameStr = data.readString();
    this.startRecordingService({
      accountNumber: accountNumber,
      startTime: startTime,
      mode: mode,
      callList: callList,
      callTimeList: callTimeList,
      fileNameStr: fileNameStr
    }, (code, message) => {
      reply.writeInt(code);
      reply.writeString(message);
      console.log(TAG + 'startServiceCase code' + code + 'message' + message);
    });
    console.log(TAG + 'startServiceCase end');
  }

  async stopService(): Promise<void> {
    return;
  }

  startRecordingService(params: RecordInputParameter, callback: StartRecordingCallBack): void {
    return;
  }

  getErrorService(callback: RecordingGetIsErrorCallBack): void {
    return;
  }

  static readonly COMMAND_STOP_RECORDING = 1;
  static readonly COMMAND_START_RECORDING = 2;
  static readonly COMMAND_GET_ERROR_RECORDING = 3;

  static readonly RECORDING_AUTO = 0;
  static readonly RECORDING_MANUAL = 1;
  static readonly RECORDING_MEETING = 2;

  static readonly RECORDING_ALL = 0;
  static readonly RECORDING_SO = 1;
  static readonly RECORDING_VN = 0;
  static readonly RECORDING_NA = 2;
  static readonly RECORDING_NK = 3;
}

