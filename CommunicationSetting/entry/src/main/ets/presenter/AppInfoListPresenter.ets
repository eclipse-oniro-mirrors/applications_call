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
import AppInfoListDataSource from '../viewmodel/AppInfoListDataSource';
import PageViewModel from '../viewmodel/PageViewModel';
import { sim } from '@kit.TelephonyKit';
import { AppInfo } from '../viewmodel/AppInfo';
import { BusinessError } from '@kit.BasicServicesKit';
import { policy, statistics } from '@kit.NetworkKit';
import {
  ATOMIC_SERVICE,
  DELAY,
  getFlowText,
  UNINSTALLED_APPS_UID,
  ORI_APP_INDEX,
  ABROAD_BUNDLE_NAME,
  ABROAD_OLD_BUNDLE_NAME,
  ABROAD_TOTAL_UID,
  DROI_BUNDLE_NAME,
  DROI_OLD_BUNDLE_NAME,
  DROI_UID,
  DEFAULT_USERID,
  COMPATIBLE_APP_CODE_PATH,
  INNER_DROI_BUNDLE_NAME,
  INNER_ABROAD_BUNDLE_NAME,
  INNER_BROWSER_BUNDLE_NAME,
  PRIVATE_SPACE_BUNDLE_NAME,
  PRIVATE_SPACE_UID,
  MAIN_SPACE_UID,
  ABROAD_HOTSPOT_UID,
  EASY_ZHUOYI_INSTALL_SOURCE
} from '../constants/CommonConstants';
import bundleManager from '@ohos.bundle.bundleManager';
import { LogUtil } from '../util/LogUtil';
import launcherBundleResource from '@ohos.bundle.launcherBundleManager';
import { HDSUtil } from '../util/HDSUtil';
import { PackageUsageInterface } from '../util/TrafficPackageUtil';
import { JSON } from '@kit.ArkTS';
import StringUtil from '../util/StringUtil';

const TAG = 'AppInfoListPresenter';
const MIN_APP_UID = 10000;

export interface AllAppInfoList {
  slotId: number;
  appList: AppInfo[];
  sysServiceList: Map<number, number>;
  uninstalledAppsFlows: number;
}

export default class AppInfoListPresenter {
  private static sInstance: AppInfoListPresenter | undefined;
  public appListShow: AppInfoListDataSource = new AppInfoListDataSource();
  private droiAddFlows: number = 0;
  private userID = DEFAULT_USERID;
  public allLauncherAppList: AppInfoListDataSource = new AppInfoListDataSource();
  private abroadFlows: number = 0;

  public static getInstance(): AppInfoListPresenter {
    if (AppInfoListPresenter.sInstance == null) {
      LogUtil.info(TAG, 'AppInfoList getInstance');
      AppInfoListPresenter.sInstance = new AppInfoListPresenter();
    }
    return AppInfoListPresenter.sInstance;
  }

  async getAllLauncherAbilityInfo(): Promise<launcherBundleResource.LauncherAbilityInfo[]> {
    let allLauncherBundleLabelList: launcherBundleResource.LauncherAbilityInfo[] = [];
    try {
      allLauncherBundleLabelList = await launcherBundleResource.getAllLauncherAbilityInfo(this.userID);
    } catch (error) {
      LogUtil.error(TAG, `allLauncherBundleLabelList catch error: ${error?.message}`);
    }
    return allLauncherBundleLabelList;
  }

  getAppInfos(showCompatibleApp: boolean, callback: Function) {
    let allAppsInfo: bundleManager.ApplicationInfo[] = [];
    try {
      // 获取全部应用信息(系统应用、桌面应用)
      bundleManager.getAllApplicationInfo(bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT,
        (err, systemAppsInfo) => {
          if (err) {
            LogUtil.error(TAG, `get all applications failed: ${(err as BusinessError).message} ` +
              `code: ${(err as BusinessError).code}`);
            callback(allAppsInfo);
            return;
          }
          allAppsInfo = allAppsInfo.concat(systemAppsInfo);
          if (showCompatibleApp === false) {
            callback(allAppsInfo);
          } else {
            // 获取兼容性应用信息
            bundleManager.getAllBundleInfo(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION, this.userID,
              (subErr, bundleAppsInfos) => {
                if (subErr) {
                  LogUtil.error(TAG, `get bundle applications failed: ${(subErr as BusinessError).message} ` +
                    `code: ${(subErr as BusinessError).code}`);
                  callback(allAppsInfo);
                  return;
                }
                bundleAppsInfos.forEach((value) => {
                  let isCompatibleApp =
                    value.appInfo.codePath === COMPATIBLE_APP_CODE_PATH && value.appInfo.systemApp === false &&
                      (value.appInfo.installSource === INNER_DROI_BUNDLE_NAME ||
                        value.appInfo.installSource === INNER_ABROAD_BUNDLE_NAME);
                  let isExtraSystemAPP = value.name === INNER_BROWSER_BUNDLE_NAME;
                  if (isCompatibleApp || isExtraSystemAPP) {
                    allAppsInfo.push(value.appInfo);
                  }
                })
                callback(allAppsInfo);
              });
          }
        });
    } catch (e) {
      LogUtil.error(TAG,
        `get all applications failed: ${(e as BusinessError).message} code: ${(e as BusinessError).code}`);
    }
  }

  getAllApps(showSystem: boolean, showCompatibleApp: boolean, callback: Function) {
    this.getAppInfos(showCompatibleApp, async (appsInfo: bundleManager.ApplicationInfo[]) => {
      // 桌面应用
      let allLauncherBundleLabelList: launcherBundleResource.LauncherAbilityInfo[] =
        await this.getAllLauncherAbilityInfo();
      let allNetAccess: policy.UidNetworkAccessPolicy | undefined = undefined;
      try {
        allNetAccess = await policy.getNetworkAccessPolicy();
      } catch (e) {
        LogUtil.error(TAG, `get all NetworkAccessPolicy failed, error code: ${e?.code}, message: ${e?.message}`);
      }
      let appList: AppInfo[] = [];
      for (const value of appsInfo) {
        const item = allLauncherBundleLabelList.find((item) => item.applicationInfo.name === value.name);
        // showCompatibleApp: true: 展示兼容性应用
        // showSystem: true: 展示桌面应用、元服务和兼容性应用， false: 只展示桌面应用和元服务
        let condition = showSystem || item || value.bundleType === ATOMIC_SERVICE ||
          (value.codePath === COMPATIBLE_APP_CODE_PATH && showCompatibleApp);
        if (condition) {
          try {
            let netAccess: policy.NetworkAccessPolicy | undefined = undefined;
            if (value.codePath === COMPATIBLE_APP_CODE_PATH) {
              netAccess = await policy.getNetworkAccessPolicy(value.uid);
            } else {
              netAccess = allNetAccess === undefined ? undefined : allNetAccess[value.uid.toString()];
            }
            let appInfo = new AppInfo(value.name, value.uid, value.appIndex, value.bundleType, netAccess);
            if (value.codePath === COMPATIBLE_APP_CODE_PATH) {
              appInfo.isCompatibleApp = true;
              appInfo.installSource = value.installSource;
            }
            if (!AppInfo.appInfoChecked(appInfo)) {
              LogUtil.error(TAG, 'get application infomation failed ');
            }
            let anomalousPolicy: number = 0;
            if (appInfo.wlanPolicyApp && !appInfo.wifiAccess) {
              appInfo.wifiAccess = true;
              anomalousPolicy += 1;
            }
            if (appInfo.mobilePolicyApp && !appInfo.mobileAccess) {
              appInfo.mobileAccess = true;
              anomalousPolicy += 1;
            }
            if (anomalousPolicy > 0) {
              let accessPolicy: policy.NetworkAccessPolicy = {
                allowWiFi: appInfo.wifiAccess,
                allowCellular: appInfo.mobileAccess,
              }
              try {
                policy.setNetworkAccessPolicy(appInfo.uid, accessPolicy, false)
              } catch (e) {
                LogUtil.error(TAG, `policy error: ${(e as BusinessError).message} code: ${(e as BusinessError).code}`);
              }
            }
            appList.push(appInfo);
          } catch (e) {
            LogUtil.error(TAG, `get net access failed, error code ${e?.code}, error message ${e?.message}`);
          }
        }
      }
      let result: AppInfo[] = [];
      try {
        let handleResult = await HDSUtil.hdsIconsHandle(appList, getContext(this));
        if (handleResult) {
          result = handleResult.apps;
        }
      } catch (e) {
        result = appList;
        LogUtil.error(TAG, `icon handle failed: ${e?.code}, message: ${e?.message}`);
      }
      result.sort(PageViewModel.appAlphabetCompare);
      callback(result);
    })
  }

  public refreshAccessByUid(uid: number, wifiAccess: boolean, mobileAccess: boolean) {
    this.appListShow.refreshAccessByUid(uid, wifiAccess, mobileAccess);
  }

  public refreshItemAccessByUid(uid: number, wifiAccess: boolean, mobileAccess: boolean) {
    this.refreshAccessByUid(uid, wifiAccess, mobileAccess);
    this.allLauncherAppList.changeAccessByUid(uid, wifiAccess, mobileAccess);
  }

  async getAllAppTraffics(networkType: number = 0, slotId: number = 0, callBack?: Function) {
    let simId = 0;
    LogUtil.info(TAG, 'getAllAppTraffics start')
    await sim.getSimAccountInfo(slotId).then(accountInfo => {
      simId = accountInfo.simId;
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, 'slot id : ' + slotId + ` getSimAccountInfo failed, promise: err->${JSON.stringify(err)}`);
    });
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    let network: statistics.NetworkInfo = {
      type: networkType,
      startTime: Math.floor(firstDayOfMonth.getTime() / 1000),
      endTime: Math.floor(Date.now() / 1000) + DELAY,
      simId: simId,
    };
    await statistics.getTrafficStatsByNetwork(network)
      .then(async (data: object) => {
        LogUtil.info(TAG, JSON.stringify(network) + ' traffic rank ' + JSON.stringify(data).length);
        let rank: Map<string, object> = new Map<string, object>(Object.entries(data));
        let allAppInfoList = await this.transmitAppTrafficInfo(slotId, rank);
        allAppInfoList.appList.sort(PageViewModel.appTrafficCompare);
        LogUtil.info(TAG, `appList length: ${allAppInfoList.appList.length}`);
        if (callBack) {
          callBack(allAppInfoList);
        }
      })
      .catch((err: Error) => {
        LogUtil.error(TAG, `get traffic stats by network failed, error message: ${err?.message}`);
      });
  }

  async getAllAppTrafficsOfCellular(simId: number = 0, startDate: Date, endDate: Date): Promise<PackageUsageInterface> {
    let startTime = Math.floor(startDate.getTime() / 1000);
    let endTime = Math.floor(endDate.getTime() / 1000);
    let network: statistics.NetworkInfo = {
      type: 0,
      startTime: startTime,
      endTime: endTime,
      simId: simId,
    };
    try {
      let data = await statistics.getTrafficStatsByNetwork(network);
      let statsInfos: Map<string, object> = new Map<string, object>(Object.entries(data));
      let totalFlows = 0;
      for (const item of statsInfos) {
        let flows: object = item[1];
        let flow = this.countFlows(flows);
        totalFlows += flow
      }
      return {
        startDate: startDate.getTime(),
        day: startDate.getDate(),
        flow: totalFlows
      } as PackageUsageInterface;

    } catch (e) {
      LogUtil.error(TAG, `getAllAppTrafficsOfCellular failed, error code: ${e?.code}, message: ${e?.message}`);
      return {
        startDate: startDate.getTime(),
        day: startDate.getDate(),
        flow: 0
      } as PackageUsageInterface;
    }
  }

  private isCreatedPrivateOrMainSpaceApp(uid: number, flow: number, appList: AppInfo[]): boolean {
    if (flow <= 0) {
      return false;
    }
    let userId = AppStorage.get<number>('userID');
    let app: AppInfo | undefined = undefined
    if (userId === DEFAULT_USERID || userId === 0) {
      if (uid === PRIVATE_SPACE_UID) {
        app = this.createAppInfo(PRIVATE_SPACE_BUNDLE_NAME, PRIVATE_SPACE_UID, flow, 0, true);
      }
    } else {
      if (uid === MAIN_SPACE_UID) {
        app = this.createAppInfo('', MAIN_SPACE_UID, flow, 0, false);
        app.label = StringUtil.resource2String($r('app.string.owner_of_device'), getContext(this));
      }
    }
    if (app) {
      appList.push(app);
      return true;
    }
    return false;
  }

  public pushDroi(): AppInfo | undefined {
    let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
    let uid = -1;

    try {
      let appInfoOrigin = bundleManager.getApplicationInfoSync(DROI_BUNDLE_NAME, flag);
      uid = appInfoOrigin.uid;
      return this.createAppInfo(DROI_BUNDLE_NAME, uid, this.droiAddFlows, ORI_APP_INDEX, true);
    } catch (err) {
      LogUtil.error(TAG, 'get new name failed: ');
    }
    try {
      let appInfoOrigin = bundleManager.getApplicationInfoSync(DROI_OLD_BUNDLE_NAME, flag);
      uid = appInfoOrigin.uid;
      return this.createAppInfo(DROI_OLD_BUNDLE_NAME, uid, this.droiAddFlows, ORI_APP_INDEX, true);
    } catch (err) {
      LogUtil.error(TAG, 'get old name failed: ');
    }
    return;
  }

  public pushAbroad(): AppInfo | undefined {
    let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
    let uid = -1;
    try {
      let appInfoOrigin = bundleManager.getApplicationInfoSync(ABROAD_BUNDLE_NAME, flag);
      uid = appInfoOrigin.uid;
      return this.createAppInfo(ABROAD_BUNDLE_NAME, uid, this.abroadFlows, ORI_APP_INDEX, true);
    } catch (err) {
      let error = err as BusinessError;
      LogUtil.error(TAG, `get abroad new name failed, error code: ${error.code}, message: ${error.message}`);
    }
    try {
      let appInfoOrigin = bundleManager.getApplicationInfoSync(ABROAD_OLD_BUNDLE_NAME, flag);
      uid = appInfoOrigin.uid;
      return this.createAppInfo(ABROAD_OLD_BUNDLE_NAME, uid, this.abroadFlows, ORI_APP_INDEX, true);
    } catch (err) {
      let error = err as BusinessError;
      LogUtil.error(TAG, `get abroad old name failed, error code: ${error.code}, message: ${error.message}`);
    }
    return;
  }

  public countFlows(flows: object) {
    let flow: Map<string, object> = new Map<string, object>(Object.entries(flows));
    return Number(flow.get('txBytes') ? flow.get('txBytes') : 0) +
    Number(flow.get('rxBytes') ? flow.get('rxBytes') : 0);
  }

  /**
   * 检查是否是普通app,单独计算非普通app流量
   * @param { number } uid - Indicates the UID of an application.
   * @param { number } flow - Traffic used.
   * @returns { boolean } true: normal app uid.
   */
  public isNormalApp(uid: number, flow: number): boolean {
    if (uid === DROI_UID) {
      this.droiAddFlows += flow;
      return false;
    }
    if (uid === ABROAD_TOTAL_UID) {
      this.abroadFlows += flow;
      return false;
    }
    return true;
  }

  /**
   * 检查是否是普通app,单独计算非普通app流量
   * @param { string } bundleName - Indicates the bundleName of an application.
   * @param { number } flow - Traffic used.
   * @returns { boolean } true: normal app name.
   */
  public checkNormalAppByName(bundleName: string, flow: number): boolean {
    if (bundleName === DROI_BUNDLE_NAME || bundleName === DROI_OLD_BUNDLE_NAME) {
      this.droiAddFlows += flow;
      return false;
    }
    if (bundleName === ABROAD_BUNDLE_NAME || bundleName === ABROAD_OLD_BUNDLE_NAME) {
      this.abroadFlows += flow;
      return false;
    }
    return true;
  }

  public async transmitAppTrafficInfo(slotId: number, data: Map<string, object>): Promise<AllAppInfoList> {
    let appListTemp: AppInfo[] = [];
    this.initData();
    let totalFlows = 0;
    let sysServiceList: Map<number, number> = new Map<number, number>();
    let uninstalledAppsFlows: number = 0;
    for (const item of data) {
      let uidString: string = item[0];
      let flows: object = item[1];
      let uid = Number(uidString);
      let flow = this.countFlows(flows);
      totalFlows += flow;
      if (uid === ABROAD_HOTSPOT_UID) {
        let appInfo = this.createAppInfo('', uid, flow, ORI_APP_INDEX, true);
        appListTemp.push(appInfo);
        continue;
      }
      if (uid === UNINSTALLED_APPS_UID) {
        uninstalledAppsFlows = flow;
        continue;
      }
      if (!this.isNormalApp(uid, flow)) {
        continue;
      }
      if (uid <= MIN_APP_UID) {
        sysServiceList.set(uid, flow);
        continue;
      }
      if (this.isCreatedPrivateOrMainSpaceApp(uid, flow, appListTemp)) {
        continue;
      }
      let bundleName = '';
      try {
        bundleName = bundleManager.getBundleNameByUidSync(uid);
      } catch (err) {
        LogUtil.error(TAG, `bundle name failed, error code: ${err?.code}, message: ${err?.message}, uid: ${uid}, flow : ${flow}`);
        sysServiceList.set(uid, flow);
        continue;
      }
      if (!this.checkNormalAppByName(bundleName, flow)) {
        continue;
      }
      let isCompatibleApp: boolean = false;
      let appIndex = ORI_APP_INDEX;
      let installSource: string = '';
      try {
        let res = await bundleManager.getAppCloneIdentity(uid);
        appIndex = Number(res.appIndex);
      } catch (err) {
        sysServiceList.set(uid, flow);
        LogUtil.error(TAG,
          `getAppCloneIdentity failed, error code: ${err?.code}, uid: ${uid}, message: ${err?.message}. flow : ${flow}`);
      }
      let bundleInfo = this.queryBundleInfoSync(bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
        this.userID);
      if (bundleInfo !== undefined) {
        installSource = bundleInfo.appInfo.installSource;
        isCompatibleApp = bundleInfo.appInfo.codePath === EASY_ZHUOYI_INSTALL_SOURCE;
      }
      let appInfo = this.createAppInfo(bundleName, uid, flow, appIndex);
      appInfo.isCompatibleApp = isCompatibleApp;
      if (isCompatibleApp) {
        appInfo.bundleType = bundleManager.BundleType.APP;
        appInfo.installSource = installSource;
      }
      if (!AppInfo.appInfoChecked(appInfo)) {
        LogUtil.error(TAG, `app infomation failed uid: ${uid},flow: ${flow}`);
        sysServiceList.set(uid, flow);
        continue;
      }
      appListTemp.push(appInfo);
    }
    appListTemp = this.checkOtherApps(appListTemp);
    let appList: AppInfo[] = [];
    try {
      let handleResult = await HDSUtil.hdsIconsHandle(appListTemp, getContext(this));
      LogUtil.info(TAG, 'mergeFlows: ' + handleResult.mergeFlows);
      appList = handleResult.apps;
    } catch (e) {
      appList = appListTemp;
      LogUtil.error(TAG, `icon handle failed: ${e?.code}, message: ${e?.message}`);
    }
    let allNetAccess: policy.UidNetworkAccessPolicy;
    try {
      allNetAccess = await policy.getNetworkAccessPolicy();
    } catch (e) {
      LogUtil.error(TAG, `get all NetworkAccessPolicy failed, error code: ${e?.code}, message: ${e?.message}`);
      return {
        slotId: slotId,
        appList: appList,
        sysServiceList: sysServiceList,
        uninstalledAppsFlows: uninstalledAppsFlows
      };
    }
    if (allNetAccess) {
      for (let app of appList) {
        if (app.isCompatibleApp) {
          try {
            let netAccess = await policy.getNetworkAccessPolicy(app.uid);
            if (netAccess?.allowWiFi !== undefined) {
              app.wifiAccess = netAccess.allowWiFi;
            }
            if (netAccess?.allowCellular !== undefined) {
              app.mobileAccess = netAccess.allowCellular;
            }
          } catch (e) {
            LogUtil.error(TAG,
              `get compatible app net access failed, error code: ${e?.code}, message: ${e?.message}, uid: ${app?.uid}, label: ${app?.label}`);
          }
        } else {
          try {
            let netAccess = allNetAccess[app.uid];
            if (netAccess?.allowWiFi !== undefined) {
              app.wifiAccess = netAccess.allowWiFi;
            }
            if (netAccess?.allowCellular !== undefined) {
              app.mobileAccess = netAccess.allowCellular;
            }
          } catch (e) {
            LogUtil.error(TAG,
              `get net access failed, error code: ${e?.code}, message: ${e?.message}, uid: ${app?.uid}, label: ${app?.label}`);
          }
        }
      }
    }
    LogUtil.log(TAG, 'total flows: ' + JSON.stringify(getFlowText(totalFlows)));
    return {
      slotId: slotId,
      appList: appList,
      sysServiceList: sysServiceList,
      uninstalledAppsFlows: uninstalledAppsFlows
    };
  }

  private queryBundleInfoSync(bundleName: string, bundleFlags: number,
    userId: number): bundleManager.BundleInfo | undefined {
    let bundleInfo: bundleManager.BundleInfo | undefined = undefined;
    LogUtil.info(TAG, 'query bundle info start');
    try {
      bundleInfo =
        bundleManager.getBundleInfoSync(bundleName, bundleFlags,
          userId);
    } catch (error) {
      LogUtil.error(TAG,
        `get bundle info failed, bundleName: ${bundleName}, error code: ${error?.code},message: ${error?.message}`);
    }
    LogUtil.info(TAG, 'query bundle info finish');
    return bundleInfo;
  }

  /**
   * 初始化系统服务流量列表和几个特殊流量项的值
   */
  public initData() {
    this.droiAddFlows = 0;
    this.abroadFlows = 0;
  }

  public createAppInfo(bundleName: string, uid: number, flow: number, appIndex: number, getAppInfo?: boolean) {
    let appInfo = AppInfo.createWithFlow(bundleName, uid, flow, appIndex);
    if (getAppInfo) {
      appInfo.getApplicationInfo();
    }
    return appInfo;
  }

  public checkOtherApps(appList: AppInfo[]) {
    if (this.droiAddFlows !== 0) {
      let app = this.pushDroi();
      if (app) {
        appList.push(app);
      }
    }
    if (this.abroadFlows !== 0) {
      let app = this.pushAbroad();
      if (app) {
        appList.push(app);
      }
    }
    return appList;
  }
}