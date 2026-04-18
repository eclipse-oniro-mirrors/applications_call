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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import { LogUtils, CallSettingGlobalContextHelper, ReportUtil } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import SatelliteServiceSettingsVM from '../viewModel/SatelliteServiceSettingsVM';
import { uiExtensionHost, window } from '@kit.ArkUI';
import { Configuration } from '@ohos.app.ability.Configuration';
import { getPushString } from '../common/utils/Utils';
import { EnterSatelliteNetwork } from '../common/constant/SatelliteSearchConst';
import { NotificationPosition } from '../common/data/commonData';
import SatelliteSearchManager from '../manager/SatelliteSearchManager';
import { START_REASON } from '../common/constant/CallSettingsConstant';

const TAG = 'SatelliteServiceNetworkAbility';
const TITLE_ANIMATION_DURATION: string = 'titleAnimationDuration';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class SatelliteServiceNetworkAbility extends UIExtensionAbility {
  public storage?: LocalStorage;
  private extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | null = null;

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'onSessionCreate');
    if (want?.uri !== undefined) {
      AppStorage.setOrCreate('satelliteServiceUri', want.uri.toString());
    }
    if (want?.parameters?.startReason === CallSettingsConstant.WANT_START_REASON_SEARCH) {
      if (getPushString((want.parameters.pushParams ?? '') as string) === 'SatelliteCommunication') {
        AppStorage.setOrCreate('satelliteServiceUri', 'SatelliteCommunication');
      }
    }
    if (want?.parameters?.startReason === CallSettingsConstant.WANT_START_REASON_EXTERNAL) {
      if (getPushString((want.parameters.pushParams ?? '') as string) === 'SatelliteCommunication') {
        AppStorage.setOrCreate('satelliteServiceUri', 'SatelliteCommunication');
        ReportUtil.getInstance().reportCellularNetworkNotification(NotificationPosition.NOTIFICATION_BODY);
      }
    }
    if (want?.parameters?.startReason) {
      AppStorage.setOrCreate(START_REASON, want?.parameters?.startReason);
    }
    CallSettingGlobalContextHelper.getContext()
      .set<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT, this.context);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    this.setSafeAreaInfo(session);
    localStorage.setOrCreate<UIExtensionContentSession>('ExtensionContentSession', session);
    session.loadContent('pages/SatelliteNetworkBlankPage', localStorage);
    AppStorage.setOrCreate<NavigationMode>('navigationMode', want?.parameters?.navigationMode as NavigationMode);
    this.setReceiveDataCallback(session);
  }

  onForeground(): void {
    // 从后台返回时重新请求过顶时间
    LogUtils.i(TAG, 'onForeground.');
    AppStorage.setOrCreate<boolean>('refreshOverTime', true);
  }

  /**
   * Receive setting module's split mode
   */
  private setReceiveDataCallback(session: UIExtensionContentSession) {
    try {
      session.setReceiveDataCallback((data: Record<string, Object>) => {
        if (!data) {
          LogUtils.e(TAG, 'setReceiveDataCallback get data error');
          return;
        }
        let receiveData: Record<string, Object> = data;
        LogUtils.i(TAG, `setReceiveDataCallback navigationMode: ${receiveData?.navigationMode}`);
        if (receiveData?.navigationMode !== undefined) {
          AppStorage.setOrCreate<NavigationMode>('navigationMode', receiveData.navigationMode as NavigationMode);
        }
        this.onTitleAnimationDurationChange(data?.titleAnimationDuration);
      })
    } catch (err) {
      LogUtils.e(TAG, `setReceiveDataCallback exception:${err}`);
    }
  }

  private onTitleAnimationDurationChange(titleAnimationDuration: object) {
    if (!titleAnimationDuration) {
      LogUtils.w(TAG, 'titleAnimationDuration is invalid');
      return;
    }
    LogUtils.i(TAG, `receive title AnimationTime is ${titleAnimationDuration}`);
    AppStorage.setOrCreate(TITLE_ANIMATION_DURATION, titleAnimationDuration);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
  }

  onSessionDestroy() {
    SatelliteServiceSettingsVM.getInstance().unRegisterData();
    this.removeAvoidAreaChangeLister();
    LogUtils.i(TAG, 'onSessionDestroy');
  }

  setSafeAreaInfo(session: UIExtensionContentSession): void {
    LogUtils.i(TAG, `setSafeAreaInfo`);
    let extensionWindow = session.getUIExtensionHostWindowProxy();
    this.extensionWindow = extensionWindow;
    let statusBarHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
    let naviIndicatorHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      .bottomRect.height;
    AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    AppStorage.setOrCreate<number>('naviIndicatorHeight', px2vp(naviIndicatorHeight));
    AppStorage.setOrCreate('currentLanguage', this.context.resourceManager.getConfigurationSync().locale);
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    LogUtils.i(TAG, `statusBar : ${px2vp(statusBarHeight)}, naviBar : ${px2vp(naviIndicatorHeight)}`);
    this.addAvoidAreaChangeLister();
  }

  private addAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        this.extensionWindow?.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
          LogUtils.i(TAG, `avoidAreaChange type: ${data.type}`);
          this.setWindowAvoidArea(data.type, data.area);
        });
      }
    } catch (err) {
      LogUtils.e(TAG, `add avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private setWindowAvoidArea(type: window.AvoidAreaType, area: window.AvoidArea) {
    if (type === window.AvoidAreaType.TYPE_SYSTEM) {
      let statusBarHeight = area.topRect.height;
      AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    }
  }

  private removeAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        this.extensionWindow?.off('avoidAreaChange');
      }
    } catch (err) {
      LogUtils.e(TAG, `remove avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }
}
