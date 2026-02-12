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

import policy from '@ohos.net.policy';
import bundleResourceManager from '@ohos.bundle.bundleResourceManager';
import bundleManager from '@ohos.bundle.bundleManager';
import { getFlowText, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE } from '../constants/Constants';
import { LogUtil } from '../util/LogUtil';

const TAG: string = 'AppInfo: ';

/**
 * 应用数据类
 *
 * @since 2024-07-09
 */
export class AppInfo {
  public bundleName: string = '';
  public label: string = '';
  public appIndex: number = ORI_APP_INDEX;
  public uid?: number;
  public bundleType: number = UNKNOWN_BUNDLE_TYPE;
  public flow: number = 0;
  public flowText: string = '0.00B';
  public wifiAccess: boolean = true;
  public mobileAccess: boolean = true;
  public img?: PixelMap | Resource | DrawableDescriptor = $r('app.media.app_icon');

  constructor(bundleName: string, uid: number, appIndex: number, bundleType: number,
    netAccess?: policy.NetworkAccessPolicy) {
    this.bundleName = bundleName;
    this.uid = uid;
    this.appIndex = appIndex;
    this.bundleType = bundleType;
    if (netAccess !== undefined) {
      this.wifiAccess = netAccess.allowWiFi as boolean;
      this.mobileAccess = netAccess.allowCellular as boolean;
    }
  }

  public getApplicationInfo(): void {
    if (this.uid === -1) {
      LogUtil.warn(`${TAG} getApplicationInfo uid is undefined`);
      return;
    }
    let bundleFlags: number = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_WITH_DRAWABLE_DESCRIPTOR |
    bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
    try {
      let resourceInfo: bundleResourceManager.BundleResourceInfo =
        bundleResourceManager.getBundleResourceInfo(this.bundleName, bundleFlags, this.appIndex);
      this.label = resourceInfo?.label;
      this.img = resourceInfo?.drawableDescriptor;
      LogUtil.info(`${TAG} getApplicationInfo label ${this.label}`);
      if (this.bundleType === UNKNOWN_BUNDLE_TYPE) {
        let flag : ESObject = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let appInfoOrigin:ESObject = bundleManager.getApplicationInfoSync(this.bundleName, flag);
        this.bundleType = appInfoOrigin.bundleType
      }
    } catch (err) {
      LogUtil.error(`${TAG} getApplicationInfo err.code ${err.code}, msg: ${err.message}`);
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
      LogUtil.warn(`${TAG} app not exist`);
      return false;
    }
    if (!app.bundleName) {
      LogUtil.warn(`${TAG} app bundle name not exist ${app.uid}`);
      return false;
    }
    if (!app.img) {
      LogUtil.warn(`${TAG} app img not exist ${app.label}`);
      return false;
    }
    return true;
  }
}