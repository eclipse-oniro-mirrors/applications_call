/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import type {
  StartRecordingCallBack,
  StopRecordingCallBack,
  IIdlServiceExt,
  RecordingGetIsErrorCallBack
} from './i_idl_service_ext';
import rpc from '@ohos.rpc';
import LogUtils from '../common/utils/LogUtils';
import type { BusinessError } from '@ohos.base';

const TAG = 'idl_service_ext_proxy';
const RPC_TIME: number = 1000;
const UNKNOWN_STATUS_CODE: number = 1000;

export default class IdlServiceExtProxy implements IIdlServiceExt {
  constructor(proxy) {
    this.proxy = proxy;
  }

  recordingStop(data: number, callback: StopRecordingCallBack): void {
    let _option = new rpc.MessageOption();
    let _data = rpc.MessageSequence.create();
    let _reply = rpc.MessageSequence.create();
    _data.writeInt(data);
    this.proxy.sendMessageRequest(IdlServiceExtProxy.COMMAND_STOP_RECORDING, _data, _reply, _option).then((result) => {
      try {
        if (result.errCode === 0) {
          let _errCode = result.reply.readInt();
          let _returnValue = undefined;
          if (_errCode === 0) {
            _returnValue = result.reply.readString();
          }
          callback(_errCode, _returnValue);
        } else {
          LogUtils.i(TAG, 'sendMessageRequest failed, errCode: ' + result.errCode);
        }
      } catch (err) {
        let error = err as BusinessError;
        LogUtils.e(TAG, 'queryAirPlaneMode query out error: code: ' + error.code + ', message: ' + error.message);
      }
    }).finally(() => {
      _data.reclaim();
      _reply.reclaim();
    });
  }

  recordingStart(params, callback: StartRecordingCallBack): void {
    let accountNumber: string = params.accountNumber;
    let startTime: number = params.startTime;
    let mode: number = params.mode;
    let _option = new rpc.MessageOption();
    let fileNameStr = params.fileNameStr;
    _option.setWaitTime(RPC_TIME);
    _option.setAsync(false);
    LogUtils.i(TAG, 'isAsync' + _option.isAsync());
    let _data = rpc.MessageSequence.create();
    let _reply = rpc.MessageSequence.create();
    _data.writeString(accountNumber);
    _data.writeLong(startTime);
    _data.writeInt(mode);
    let callListResult = [];
    let callTimeListResult = [];
    if (mode === IdlServiceExtProxy.COMMAND_START_RECORDING) {
      let callList = params.callList;
      for (let i = 0; i < callList.length; i++) {
        callListResult.push(callList[i].accountNumber);
        callTimeListResult.push(callList[i].startTime);
      }
    }
    _data.writeStringArray(callListResult);
    _data.writeLongArray(callTimeListResult);
    _data.writeString(fileNameStr);
    this.proxy.sendMessageRequest(IdlServiceExtProxy.COMMAND_START_RECORDING, _data, _reply, _option)
      .then((result) => {
        if (result.errCode === 0) {
          let _code = result.reply.readInt();
          let _message = result.reply.readString();
          callback(_code, _message);
        } else {
          callback(UNKNOWN_STATUS_CODE, 'network error');
        }
      }).finally(() => {
      _data.reclaim();
      _reply.reclaim();
    });
  }

  recordingGetIsError(callback: RecordingGetIsErrorCallBack): void {
    let _option = new rpc.MessageOption();
    _option.setWaitTime(RPC_TIME);
    _option.setAsync(false);
    let _data = rpc.MessageSequence.create();
    let _reply = rpc.MessageSequence.create();
    this.proxy.sendMessageRequest(IdlServiceExtProxy.COMMAND_GET_ERROR_RECORDING, _data, _reply, _option)
      .then((result) => {
        if (result.errCode === 0) {
          let _code = result.reply.readInt();
          let _message = result.reply.readString();
          callback(_code, _message);
        } else {
          callback(UNKNOWN_STATUS_CODE, 'network error');
        }
      }).finally(() => {
      _data.reclaim();
      _reply.reclaim();
    });
  }

  static readonly COMMAND_STOP_RECORDING = 1;
  static readonly COMMAND_START_RECORDING = 2;
  static readonly COMMAND_GET_ERROR_RECORDING = 3;

  static readonly RECORDING_AUTO = 0;
  static readonly RECORDING_MANUAL = 1;
  static readonly RECORDING_MEETING = 2;
  private proxy: rpc.RemoteObject;
}

