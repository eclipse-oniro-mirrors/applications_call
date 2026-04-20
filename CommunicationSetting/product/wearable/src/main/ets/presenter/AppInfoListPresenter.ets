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

import bundle from '@ohos.bundle.bundleManager';
import statistics from '@ohos.net.statistics';
import sim from '@ohos.telephony.sim';
import { BusinessError } from '@ohos.base';
import bundleManager from '@ohos.bundle.bundleManager';
import { AppInfo } from '../viewmodel/AppInfo';
import { LogUtil } from '../util/LogUtil';
import { getFlowText, ORI_APP_INDEX, PAGE_CONTEXT } from '../constants/Constants';
import { themeResource } from '../theme/ThemeResourceCache';

const TAG: string = 'AppInfoListPresenter: ';
const DEFAULT_SLOT_ID: number = 0;
const THOUSAND: number = 1000;
const DELAY: number = 5;

/**
 * 流量排行工具类
 *
 * @since 2024-11-12
 */
export default class AppInfoListPresenter {
  private static sInstance: AppInfoListPresenter | undefined;
  private static context: Context | undefined;

  public static getInstance(): AppInfoListPresenter {
    if (!AppInfoListPresenter.sInstance) {
      LogUtil.info(`${TAG} AppInfoList getInstance`);
      AppInfoListPresenter.sInstance = new AppInfoListPresenter();
      AppInfoListPresenter.context = AppStorage.get<Context>(PAGE_CONTEXT);
      if (AppInfoListPresenter.context) {
        themeResource.initActivatingTheme(AppInfoListPresenter.context);
      }
    }
    return AppInfoListPresenter.sInstance;
  }

  public async getAllAppTraffics(networkType: number, callBack?: Function): Promise<void> {
    let simId: number = 0;
    await sim.getSimAccountInfo(DEFAULT_SLOT_ID).then(accountInfo => {
      simId = accountInfo?.simId ?? 0;
    }).catch((err: BusinessError) => {
      LogUtil.error(`${TAG} getAllAppTraffics simdId failed, err.code: ${err.code}, err.msg: ${err.message}`);
      if (callBack) {
        callBack(undefined);
      }
    });
    const now: Date = new Date();
    const firstDayOfMonth: Date = new Date(now.getFullYear(), now.getMonth(), 1);
    const startTime: number = Math.floor(firstDayOfMonth.getTime() / THOUSAND);
    const endTime: number = Math.floor(Date.now() / THOUSAND) + DELAY;
    let network: statistics.NetworkInfo = {
      type: networkType,
      startTime: startTime,
      endTime: endTime,
      simId: simId,
    };
    LogUtil.info(`${TAG} getAllAppTraffics type: ${networkType}, startTime: ${startTime}, endTime: ${endTime}`);
    await statistics.getTrafficStatsByNetwork(network).then(async (data: object) => {
      LogUtil.info(`${TAG} getTrafficStatsByNetwork`);
      const rank: Map<string, object> = new Map<string, object>(Object.entries(data));
      let appList: AppInfo[] = [];
      try {
        appList = await this.transmitAppTrafficInfo(rank);
      } catch (err) {
        LogUtil.error(`${TAG} transmitAppTrafficInfo err, message: ${(err as Error).message}`);
      }
      appList.sort(this.appTrafficCompare);
      if (callBack) {
        callBack(appList);
      }
    }).catch((err: Error) => {
      LogUtil.error(`${TAG} getAllAppTraffics err message ${err.message}`);
      if (callBack) {
        callBack(undefined);
      }
    });
  }

  private async transmitAppTrafficInfo(data: Map<string, object>): Promise<Array<AppInfo>> {
    let appList: AppInfo[] = [];
    let totalFlows: number = 0;
    for (const item of data) {
      let uidString: string = item[0];
      let flows: object = item[1];
      let uid: number = Number(uidString);
      let flow: number = this.countFlows(flows);
      totalFlows += flow;
      let bundleName: string = '';
      try {
        bundleName = bundleManager.getBundleNameByUidSync(uid);
      } catch (err) {
        LogUtil.error(`${TAG} bundle name failed, ${uid} error code: ${err?.code}, message: ${err?.message}`);
        continue;
      }

      let appIndex: number = ORI_APP_INDEX;
      try {
        let res = await bundleManager.getAppCloneIdentity(uid);
        appIndex = Number(res.appIndex);
      } catch (err) {
        LogUtil.error(`${TAG} transmitAppTrafficInfo err, ${uid} error.code: ${err.code}, message: ${err.message}.`);
        continue;
      }
      let appInfo: AppInfo = AppInfo.createWithFlow(bundleName, uid, flow, appIndex);
      appInfo.getApplicationInfo();
      if (!AppInfo.appInfoChecked(appInfo)) {
        LogUtil.error(`${TAG} transmitAppTrafficInfo app infomation failed ${uid}`);
      }
      let bundleInfo: bundle.BundleInfo | undefined = await this.getBundleInfo(bundleName, appIndex);
      let moduleName: string = bundleInfo?.appInfo?.labelResource?.moduleName ?? '';
      let iconId: number = bundleInfo?.appInfo?.iconId ?? 0;
      try {
        appInfo.img = themeResource.isThemePackagesExistence(bundleName) ? appInfo.img
          : await themeResource.getThemeDrawableDescriptor(bundleName, moduleName, iconId) ?? $r('app.media.app_icon');
      } catch (error) {
        LogUtil.error(`${TAG} transmitAppTrafficInfo theme fail ${error?.message}, code ${error?.code}`);
      }
      appList.push(appInfo);
    }
    LogUtil.log(`${TAG} total flows: ${getFlowText(totalFlows)}`);
    return appList;
  }

  private async getBundleInfo(bundleName: string, appIndex?: number): Promise<bundle.BundleInfo | undefined> {
    let bundleInfo: bundle.BundleInfo | undefined = undefined;
    try {
      bundleInfo = await bundle.getBundleInfo(bundleName,
        bundle.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION | bundle.BundleFlag.GET_BUNDLE_INFO_WITH_DISABLE);
    } catch (error) {
      LogUtil.error(`${TAG} getBundleInfo error, errcode: ${error?.code}, errmsg: ${error?.message}`);
      bundleInfo = undefined;
    }
    return bundleInfo;
  }

  private countFlows(flows: object): number {
    let flow: Map<string, object> = new Map<string, object>(Object.entries(flows));
    return Number(flow.get('txBytes') ? flow.get('txBytes') : 0) +
    Number(flow.get('rxBytes') ? flow.get('rxBytes') : 0);
  }

  private appTrafficCompare(a: AppInfo, b: AppInfo): number {
    if (!a || !b) {
      LogUtil.warn(`${TAG} appTrafficCompare app info is undefined`);
      return 0;
    }
    if (a.flow != b.flow) {
      return b.flow - a.flow
    }
    return a.label.localeCompare(b.label)
  }
}