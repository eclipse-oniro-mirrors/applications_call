/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import rpc from '@ohos.rpc';
import { IService, ICallback } from './IService';
import json from '@ohos.util.json';

const TAG: string = 'IServiceProxy';

const type: string = '2'
const bundleName: string = 'com.ohos.callui'
const abilityName: string = 'com.ohos.callui.LeatherUIExtAbility'
const uiExtensionType: string = 'sys/commonUI'
const extra: string =
  `{"type":"${type}","bundleName":"${bundleName}","abilityName":"${abilityName}","parameters":{"ability.want.params.uiExtensionType":"${uiExtensionType}"}}`

export default class IServiceProxy implements IService {
  public proxy: rpc.IRemoteObject | null = null;

  constructor(proxy: rpc.IRemoteObject) {
    this.proxy = proxy;
  }

  getICallback(requestCode: number, methodName: string, callback: ICallback): void {
    let remoteObject = new rpc.RemoteObject(TAG);
    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();
    const trans = JSON.stringify({
      method: methodName,
      extra: extra
    });
    data.writeString(trans);
    data.writeRemoteObject(remoteObject);
    if (!this.proxy) {
      return;
    }

    try {
      this.proxy.sendMessageRequest(requestCode, data, reply, option).then(result => {
        if (result.errCode === 0) {
          let errCode = result.reply.readInt();
          if (errCode !== 0) {
            callback(errCode, []);
            return;
          }
          let returnValue = result.reply.readStringArray();
          callback(errCode, returnValue);
        }
      });
    } catch (err) {
      console.info(TAG, 'err=', json.stringify(err))
    }
  }
}


