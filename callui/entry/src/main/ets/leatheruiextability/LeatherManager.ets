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
import Want from '@ohos.app.ability.Want';
import { RemoteService } from './RemoteService';
import IServiceProxy from './IServiceProxy';
import { common, UIExtensionAbility } from '@kit.AbilityKit';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { preferences } from '@kit.ArkData';
import LogUtils from '../common/utils/LogUtils';


const TAG = 'LeatherManager'

class LeatherManager {
  public getSuperPrivacy(isSuperPrivacy: boolean) {
    let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
    const leatherPagePreferencesOptions: preferences.Options = { name: 'LeatherPagePreferences' };
    const leatherPreferencesSuperPrivacy: string = 'leatherPreferencesSuperPrivacy';
    let dataPreferences: preferences.Preferences =
      preferences.getPreferencesSync(serviceContext, leatherPagePreferencesOptions);
    dataPreferences.putSync(leatherPreferencesSuperPrivacy, isSuperPrivacy)
    dataPreferences.flush()
  }

  public requestSCB(methodName: string): void {
    const want: Want = {
      bundleName: 'com.ohos.sceneboard',
      abilityName: 'ScreenLockExtensionService'
    };

    let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
    let service = new RemoteService(serviceContext);
    LogUtils.i(TAG, 'isLeatherManagerRequestSCB')
    service.getProxy(want).then((proxy: IServiceProxy) => {
      proxy.getICallback(2, methodName, () => {
        if (methodName === 'addAppCoverItemView') {
          AppStorage.setOrCreate('isLeatherManagerRequestSCB', true)
          LogUtils.i(TAG, 'isLeatherManagerRequestSCB')
        }
      });
    }).catch((e: Error) => {
      service.disConnect();
    });
  }
}

let leatherManager = new LeatherManager();

export { leatherManager as LeatherManager }
