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
import { DrawableDescriptor } from '@kit.ArkUI';
import { LogUtil } from '../util/LogUtil';
import StringUtil from '../util/StringUtil';
import { bundleResourceManager, common } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager';
import {
  ORI_APP_INDEX,
  UNKNOWN_BUNDLE_TYPE,
  getFlowText,
  DROI_BUNDLE_NAME,
  DROI_OLD_BUNDLE_NAME,
  ABROAD_BUNDLE_NAME,
  ABROAD_OLD_BUNDLE_NAME,
  ABROAD_TOTAL_UID,
  DROI_UID,
  PRIVATE_SPACE_UID,
  MAIN_SPACE_UID,
  INNER_DROI_BUNDLE_NAME,
  ABROAD_HOTSPOT_UID
} from '../constants/CommonConstants';
import { policy } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { IsWiFiOnly } from '../util/DeviceUtil';
import { GlobalContext } from '../entryability/CommunicationSettingAbility';

const TAG = 'AppInfo';

export class AppInfo {
  public bundleName: string = '';
  public appIndex: number = ORI_APP_INDEX;
  public bundleType: number = UNKNOWN_BUNDLE_TYPE;
  public label: string = '';
  public uid: number = -1;
  public flow: number = 0;
  public flowText: string[] = ['0.00', 'B'];
  public wifiAccess: boolean = true;
  public mobileAccess: boolean = true;
  public img?: PixelMap | Resource | DrawableDescriptor = $r('app.media.app_icon');
  public mobilePolicyApp: boolean = false;
  public wlanPolicyApp: boolean = false;
  public isCompatibleApp: boolean = false;
  public isRubbishData: boolean = false;
  public installSource: string = '';

  constructor(bundleName: string, uid: number, appIndex: number, bundleType: number,
    netAccess?: policy.NetworkAccessPolicy) {
    this.bundleName = bundleName;
    this.uid = uid;
    this.appIndex = appIndex;
    this.bundleType = bundleType;
    if (netAccess !== undefined) {
      this.wifiAccess = netAccess.allowWiFi as boolean;
      this.mobileAccess = netAccess.allowCellular as boolean;
      this.wlanPolicyApp = false;
      this.mobilePolicyApp = false;
      if (netAccess['alwaysAllowWiFi']) {
        this.wlanPolicyApp = netAccess['alwaysAllowWiFi'] as boolean;
      }
      if (netAccess['alwaysAllowCellular']) {
        this.mobilePolicyApp = netAccess['alwaysAllowCellular'] as boolean;
      }
    }
  }

  static createWithFlow(bundleName: string, uid: number, flow: number, appIndex: number) {
    let app = new AppInfo(bundleName, uid, appIndex, UNKNOWN_BUNDLE_TYPE);
    app.flow = flow;
    app.flowText = getFlowText(app.flow);
    return app;
  }

  static appInfoChecked(app: AppInfo) {
    if (!app) {
      LogUtil.error(TAG, 'app not exist');
      return false;
    }
    if (StringUtil.isEmpty(app.bundleName)) {
      LogUtil.error(TAG, 'app bundle name not exist ' + app.uid);
      return false;
    }
    if (app.img === undefined) {
      LogUtil.error(TAG, 'app img not exist ' + app.label);
      return false;
    }
    return true;
  }

  getApplicationInfo() {
    // 移动热点 默认允许移动和wlan权限且不允许修改
    if (this.isHotSpot()) {
      LogUtil.info(TAG, `getApplicationInfo------- ${this.uid}`)
      let context = GlobalContext.getContext().getObject('rankPageContext');
      this.label =
        StringUtil.convertResourceToString($r('app.string.hotspot_name'), context as common.UIAbilityContext);
      this.img = $r('app.media.hotspot_icon');
      this.wifiAccess = true;
      this.mobileAccess = true;
      this.wlanPolicyApp = true;
      this.mobilePolicyApp = true;
      return;
    }
    if (this.uid === -1) {
      return;
    }
    let bundleFlags = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_WITH_DRAWABLE_DESCRIPTOR |
    bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
    try {
      let resourceInfo = bundleResourceManager.getBundleResourceInfo(this.bundleName, bundleFlags, this.appIndex);
      this.label = resourceInfo.label;
      if (this.isCompatibleApp) {
        this.bundleType = bundleManager.BundleType.APP;
      } else if (this.bundleType === UNKNOWN_BUNDLE_TYPE) {
        let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let appInfoOrigin = bundleManager.getApplicationInfoSync(this.bundleName, flag);
        this.bundleType = appInfoOrigin.bundleType;
      }
    } catch (err) {
      LogUtil.error(TAG, 'bundleName ' + this.bundleName + ' getBundleResourceInfo failed: ' + err);
    }
  }

  public getNetworkText(): Resource {
    if (IsWiFiOnly()) {
      if (this.wifiAccess) {
        return $r('app.string.allow_WLAN');
      }
      return $r('app.string.forbid');
    }

    if (this.mobileAccess && this.wifiAccess) {
      return $r('app.string.allow_mobile_data_and_WLAN');
    }
    if (this.mobileAccess) {
      return $r('app.string.allow_mobile_data');
    }
    if (this.wifiAccess) {
      return $r('app.string.allow_WLAN');
    }
    return $r('app.string.forbid');
  }

  public changeMobileAccess(access: boolean, appInfo: AppInfo) {
    // 蜂窝网络联网权限和当前value相同不需要更新
    if (this.mobileAccess === access) {
      return;
    }
    if (!appInfo?.mobilePolicyApp) {
      this.mobileAccess = access;
      this.setNetworkAccess();
    }
  }

  public changeWifiAccess(access: boolean, appInfo: AppInfo) {
    // wlan网络联网权限和当前value相同不需要更新
    if (this.wifiAccess === access) {
      return;
    }
    if (!appInfo?.wlanPolicyApp) {
      this.wifiAccess = access;
      this.setNetworkAccess();
    }
  }

  public checkShowNetworkType(): boolean {
    if (this.isCompatibleApp && (this.isDroi() || this.isAbroad()) == false) {
      return false;
    }
    return true;
  }

  private isDroi() {
    return (this.bundleName === DROI_BUNDLE_NAME || this.bundleName === DROI_OLD_BUNDLE_NAME || this.uid === DROI_UID);
  }

  private isAbroad() {
    return (this.bundleName === ABROAD_BUNDLE_NAME || this.bundleName === ABROAD_OLD_BUNDLE_NAME ||
      this.uid === ABROAD_TOTAL_UID);
  }

  public isHotSpot() {
    return this.uid === ABROAD_HOTSPOT_UID;
  }
  private setNetworkAccess() {
    let accessPolicy: policy.NetworkAccessPolicy = {
      allowWiFi: this.wifiAccess,
      allowCellular: IsWiFiOnly() ? this.wifiAccess : this.mobileAccess,
    };
    LogUtil.info(TAG,`set network access wifi: ${accessPolicy.allowWiFi}, cellular: ${accessPolicy.allowCellular}`);
    policy.setNetworkAccessPolicy(this.uid, accessPolicy).catch((e: BusinessError) => {
      LogUtil.error(TAG, `policy error: ${(e.message)} code: ${(e.code)}`);
    });

    let uid = this.uid;
    let setNetworkAccessAgain = false;
    if (this.bundleName === DROI_BUNDLE_NAME || this.bundleName === DROI_OLD_BUNDLE_NAME) {
      uid = DROI_UID;
      setNetworkAccessAgain = true;
    } else if (this.bundleName === ABROAD_BUNDLE_NAME || this.bundleName === ABROAD_OLD_BUNDLE_NAME) {
      uid = ABROAD_TOTAL_UID;
      setNetworkAccessAgain = true;
    }
    if (setNetworkAccessAgain) {
      LogUtil.info(TAG,`set dr and an access wifi: ${accessPolicy.allowWiFi}, cellular: ${accessPolicy.allowCellular}`);
      policy.setNetworkAccessPolicy(uid, accessPolicy).catch((e: BusinessError) => {
        LogUtil.error(TAG, `set compatible app policy error: ${(e.message)} code: ${(e.code)}, uid: ${uid}`);
      });
    }
  }

  public isPrivateOrMainSpace(): boolean {
    return this.uid === PRIVATE_SPACE_UID || this.uid === MAIN_SPACE_UID;
  }

  public isMainSpace(): boolean {
    return this.uid === MAIN_SPACE_UID;
  }

  public isShowDroidBadge(): boolean {
    return this.installSource === INNER_DROI_BUNDLE_NAME;
  }
}