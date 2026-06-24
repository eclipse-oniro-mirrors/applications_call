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
import common from '@ohos.app.ability.common';
import rpc from '@ohos.rpc';
import Want from '@ohos.app.ability.Want';
import bundleManager from '@ohos.bundle.bundleManager';
import IServiceProxy from './IServiceProxy';
import LogUtils from '../common/utils/LogUtils';

const TAG: string = 'RemoteService';

export class RemoteService {
  private remoteObj: rpc.IRemoteObject | null = null;
  private proxy: IServiceProxy | null = null;
  private connectionCode: number | undefined;
  private context: common.ServiceExtensionContext | null = null;
  public constructor(context: Context) {
    this.context = context as common.ServiceExtensionContext;
  }

  public async getProxy(want: Want): Promise<IServiceProxy> {
    return new Promise<IServiceProxy>((resolve, reject) => {
      if (!this.context) {
        let error: Record<string, string | number> = {
          'message': 'context is empty'
        };
        return reject(error);
      }
      try {
        this.connectionCode = this.context?.connectServiceExtensionAbility(want, {
          onConnect: (elementName: bundleManager.ElementName, remote: rpc.IRemoteObject): void => {
            this.remoteObj = remote;
            this.proxy = new IServiceProxy(remote);
            LogUtils.i(TAG, 'onConnect')
            resolve(this.proxy);
          },
          onDisconnect: (elementName: bundleManager.ElementName): void => {
            this.clean();
          },
          onFailed: (code: number): void => {
            this.clean();
            let error: Record<string, string | number> = {
              'code': code,
              'message': 'getProxy failed'
            };
            reject(error);
          }
        });
      } catch (err) {
      }
    }).finally(() => {
      this.disConnect();
    });
  }

  private clean(): void {
    this.remoteObj = null;
    this.proxy = null;
  }

  public disConnect(): void {
    if (!this.context) {
      return;
    }
    try {
      this.context.disconnectServiceExtensionAbility(this.connectionCode as number);
    } catch (err) {
    }
  }
}