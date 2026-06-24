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
import Want from '@ohos.app.ability.Want';
import { GlobalContextHelper } from './GlobalContextHelper';
import ServiceExtensionContext from '@ohos.app.ability.common';
import * as Constants from './Constants';
import LogUtils from './LogUtils';
import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import IdlServiceBannerProxy from '../../idl/IdlServiceBannerProxy';
import rpc from '@ohos.rpc';
import { isTwoInOne } from './DeviceTypeUtils';

const TAG = 'Banner_Class';
let preferences: dataPreferences.Preferences | null = null;
let mServiceBannerProxy: IdlServiceBannerProxy | undefined;

export default class Banner {
  private static sInstance: Banner;

  static getInstance() {
    if (Banner.sInstance == null) {
      Banner.sInstance = new Banner();
    }
    return Banner.sInstance;
  }

  public getFirstStartStatus() {
    let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
    let options: dataPreferences.Options = {
      name: 'needShowBannerGuide'
    };
    try {
      preferences = dataPreferences.getPreferencesSync(serviceContext, options);
      let result = preferences.getSync('needShowBannerGuide', true);
      LogUtils.i(TAG, 'getFirstStartStatus preferences needShowBannerGuide = ' + result);
      return result;
    } catch (err) {
      LogUtils.e(TAG, `getPreferencesSync failed, err: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  setFirstStartStatus() {
    if (!preferences) {
      LogUtils.i(TAG, 'getPreferences Fail');
      return;
    }
    preferences.putSync('needShowBannerGuide', false);
    preferences.flush();
  }

  jumpToBannerGuide() {
    let isFirstBanner = this.getFirstStartStatus();
    if (!isFirstBanner || isTwoInOne()) {
      LogUtils.i(TAG, 'not firstBanner or isTwoInOne');
      return;
    }
    let want: Want = {
      bundleName: 'com.ohos.sceneboard',
      abilityName: 'com.ohos.sceneboard.systemdialog'
    };
    let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
    let serviceContextScope = this;
    serviceContext.startAbility(want).then(() => {
      LogUtils.i(TAG, 'jumpToBannerGuide, startAbility success');
      serviceContextScope.setFirstStartStatus();
      let connectionId: number = serviceContext?.connectServiceExtensionAbility(want, {
        onConnect(elementName, remote: rpc.IRemoteObject) {
          LogUtils.i(TAG, `onConnect callback`);
          if (remote === null) {
            LogUtils.w(TAG, `onConnect remote is null`);
            return;
          }
          mServiceBannerProxy = new IdlServiceBannerProxy(remote as rpc.RemoteObject);
          mServiceBannerProxy.bannerFirstStart();
        },
        onDisconnect(elementName) {
          LogUtils.i(TAG, 'onDisconnect callback');
          mServiceBannerProxy = undefined;
        },
        onFailed(code: number) {
          LogUtils.e(TAG, 'onFailed callback code' + code);
          mServiceBannerProxy = undefined;
        }
      });
      LogUtils.i(TAG, 'bannerStart connectionId:' + connectionId);
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, 'jumpToBannerGuide, failed Cause: ' + JSON.stringify(error.code));
    });
  }
}