/**
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

import Want from '@ohos.app.ability.Want';
import ServiceExtension from '@ohos.app.ability.ServiceExtensionAbility';
import CallManagerService from './CallManagerService';
import rpc from '@ohos.rpc';
import LogUtils from '../common/utils/LogUtils';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import ServiceExtensionContext from '@ohos.app.ability.common';
import * as Constants from '../common/utils/Constants'
import { ConfigurationConstant, Configuration } from '@kit.AbilityKit';

const TAG = 'CallUIServiceAbility';

export default class ServiceAbility extends ServiceExtension {
  public callManagerService?: CallManagerService;
  private lastMode: ConfigurationConstant.ColorMode | undefined = undefined;

  onCreate(): void {
    LogUtils.i(TAG, 'onCreate callUI service');
    hiTraceMeter.startTrace('serviceonCreate', 1001);
    GlobalContextHelper.getContext()
      .set<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT, this.context);
    this.callManagerService = CallManagerService.getInstance();
    this.callManagerService.init(this.context);
    hiTraceMeter.finishTrace('serviceonCreate', 1001);
  }

  onConnect(want: Want): Stub {
    LogUtils.i(TAG, 'onConnect callUI service');
    return new Stub('ServiceAbility');
  }

  onConfigurationUpdated(config: Configuration) {
    // darkMode：0， lightMode：1
    if (this.lastMode !== config?.colorMode) {
      GlobalContextHelper.getContext()
        .set<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT, this.context);
      LogUtils.i(TAG, `color mode: ${this.context?.config?.colorMode} => ${config.colorMode}`);
      this.callManagerService?.updateBannerNotification(
        config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      this.lastMode = config.colorMode;
    } else {
      LogUtils.i(TAG, 'config.colorMode = ' + config?.colorMode);
    }
  }

  onDisconnect(): void {
    LogUtils.i(TAG, 'onDisconnect callUI service');
  }

  onRequest(want: Want, startId: number): void {
    LogUtils.i(TAG, 'onRequest callUI service');
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy callUI service');
    this.callManagerService?.onDisconnected();
    AppStorage.delete('isSuperPrivacy');
    // this.callManagerService?.unsubscribeServiceState();
    this.callManagerService?.unRegisterSimStateChange();
  }
}


class Stub extends rpc.RemoteObject {
  constructor(descriptor: string) {
    super(descriptor);
  }
}