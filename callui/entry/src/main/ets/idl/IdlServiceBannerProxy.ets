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

import rpc from '@ohos.rpc';
import { BusinessError } from '@ohos.base';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'IdlServiceBannerProxy';
const RPC_TIME: number = 1000;

export const CALL_BUNDLE_NAME = 'com.ohos.callsetting';

const CALL_ABILITY_NAME_BANNER: string = 'com.ohos.callsetting.CallBannerAbility';

export default class IdlServiceBannerProxy {
  private static readonly COMMAND_START_DIALOG = 1;
  private proxy: rpc.RemoteObject;

  constructor(proxy: rpc.RemoteObject) {
    this.proxy = proxy;
  }

  bannerFirstStart(): void {
    let option = new rpc.MessageOption();
    option.setWaitTime(RPC_TIME);
    let data = rpc.MessageSequence.create();
    let reply = rpc.MessageSequence.create();
    data.writeInt(3)
    data.writeString('bundleName');
    data.writeString(CALL_BUNDLE_NAME);
    data.writeString('abilityName');
    data.writeString(CALL_ABILITY_NAME_BANNER);
    data.writeString('parameters');
    data.writeString('{\"ability.want.params.uiExtensionType\":\"sysDialog/common\"}');

    LogUtils.i(TAG, 'bannerFirstStart');
    this.proxy.sendMessageRequest(IdlServiceBannerProxy.COMMAND_START_DIALOG, data, reply, option).then(
      result => {
        LogUtils.i(TAG, `startdialog success ${result.errCode} ${result.reply.readInt()}`);
      },
      (error: BusinessError) => LogUtils.i(TAG, `startdialog error` + error.code)
    ).finally(() => {
      data.reclaim();
      reply.reclaim();
    });
    return;
  }
}

