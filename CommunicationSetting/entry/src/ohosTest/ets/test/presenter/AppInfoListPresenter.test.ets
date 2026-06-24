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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium'
import AppInfoListPresenter from '../../../../main/ets/presenter/AppInfoListPresenter';
import { LogUtil } from '../../../../main/ets/util/LogUtil';
import AppInfoListDataSource from '../../../../main/ets/viewmodel/AppInfoListDataSource';
import launcherBundleResource from '@ohos.bundle.launcherBundleManager';
import {
  ABROAD_BUNDLE_NAME,
  ABROAD_OLD_BUNDLE_NAME,
  ABROAD_TOTAL_UID,
  DEFAULT_USERID,
  DROI_BUNDLE_NAME,
  DROI_OLD_BUNDLE_NAME,
  DROI_UID,
  ORI_APP_INDEX,
  UNINSTALLED_APPS_UID,
  UNKNOWN_BUNDLE_TYPE
} from '../../../../main/ets/constants/CommonConstants';
import { bundleManager } from '@kit.AbilityKit';
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo';
import { statistics } from '@kit.NetworkKit';
import { SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil';

export default function AppInfoListPresenterTest() {
  describe('AppInfoListPresenterTest', () => {
    let appInfoListPresenter: AppInfoListPresenter;
    let appListShow: AppInfoListDataSource;
    const TAG = 'AppInfoListPresenter';
    beforeEach(() => {
      appInfoListPresenter = new AppInfoListPresenter();
      appListShow = new AppInfoListDataSource();
      let appInfo1 = new AppInfo(`1`, 1, 1, 1);
      let appInfo2 = new AppInfo(`2`, 2, 2, 2);
      appListShow.refresh([appInfo1, appInfo2]);
      appInfoListPresenter.appListShow = appListShow;
    })


    it('AudioRecorderService_totalCountTest', 0, () => {
      expect(typeof appInfoListPresenter.allLauncherAppList.totalCount())
        .assertEqual(typeof AppInfoListPresenter.getInstance().allLauncherAppList.totalCount());
    })

    it('should_return_allLauncherAbilityInfo_when_getAllLauncherAbilityInfo_success', 0, async () => {
      let allLauncherBundleLabelList = await launcherBundleResource.getAllLauncherAbilityInfo(DEFAULT_USERID);
      let mockResult: launcherBundleResource.LauncherAbilityInfo[] = [];
      if (allLauncherBundleLabelList) {
        let applicationInfo = allLauncherBundleLabelList[0].applicationInfo;
        mockResult = [
          {
            labelId: 1,
            iconId: 2,
            userId: 100,
            elementName: {
              bundleName: 'com.example.app',
              abilityName: 'abilityName'
            },
            installTime: 0,
            applicationInfo: applicationInfo
          }
        ];
      }
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(appInfoListPresenter, appInfoListPresenter.getAllLauncherAbilityInfo);

      when(mockfunc)(ArgumentMatchers.any).afterReturn(mockResult);

      const result = await appInfoListPresenter.getAllLauncherAbilityInfo();
      expect(result.length).assertEqual(1);
      expect(result[0].labelId).assertEqual(1);
      expect(result[0].iconId).assertEqual(2);
      expect(result[0].userId).assertEqual(100);
      expect(result[0].installTime).assertEqual(0);
      expect(result[0].elementName.bundleName).assertEqual('com.example.app');
      expect(result[0].elementName.abilityName).assertEqual('abilityName');
      mocker.ignoreMock(appInfoListPresenter, appInfoListPresenter.getAllLauncherAbilityInfo);
      mocker.clear(appInfoListPresenter);
    });

    it('should_return_empty_array_when_getAllLauncherAbilityInfo_throws_error', 0, async () => {
      let appinfolistpresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
      let mocker: MockKit = new MockKit();

      let mockfunc: Function = mocker.mockFunc(appinfolistpresenter, appinfolistpresenter.getAllLauncherAbilityInfo);
      when(mockfunc)(ArgumentMatchers.any).afterThrow(`error`);

      try {
        await appinfolistpresenter.getAllLauncherAbilityInfo();
      } catch (e) {
        LogUtil.info(TAG, `json error = ${JSON.stringify(e)}`)
        expect(e).assertEqual('error');
      }
      mocker.ignoreMock(appinfolistpresenter, appinfolistpresenter.getAllLauncherAbilityInfo);
      mocker.clear(appinfolistpresenter);
    });

    it('AppInfoListPresenterTest_getAppInfos', 0, async () => {
      appInfoListPresenter.getAppInfos(false, (appsInfo: bundleManager.ApplicationInfo[]) => {
        expect(appsInfo.length).assertLarger(0)
      })
    })

    it('AppInfoListPresenterTest_getAllApps', 0, async () => {
      appInfoListPresenter.getAllApps(true, true, (appsInfo: bundleManager.ApplicationInfo[]) => {
        expect(appsInfo.length).assertLarger(1)
      })
    })

    it('AppInfoListPresenterTest_refreshAccessByUid', 0, () => {
      let uid: number = 2;
      let wifiAccess: boolean = true;
      let mobileAccess: boolean = false;
      appInfoListPresenter.refreshAccessByUid(uid, wifiAccess, mobileAccess);
      let appInfo = appInfoListPresenter.appListShow.getData(1)?.appInfo as AppInfo;
      expect(appInfo.uid).assertEqual(uid);
      expect(appInfo.wifiAccess).assertEqual(wifiAccess);
      expect(appInfo.mobileAccess).assertEqual(mobileAccess);
    })

    it('AppInfoListPresenterTest_pushDroi', 0, () => {
      try {
        let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let uid = bundleManager.getApplicationInfoSync(DROI_BUNDLE_NAME, flag).uid;
        let appInfo = appInfoListPresenter.pushDroi();
        expect(appInfo?.bundleName).assertEqual(DROI_BUNDLE_NAME);
        expect(appInfo?.appIndex).assertEqual(ORI_APP_INDEX);
        expect(appInfo?.uid).assertEqual(uid);
      } catch (e) {
        let mocker: MockKit = new MockKit();
        mocker.mockFunc(LogUtil, LogUtil.error);
        mocker.verify('error', [TAG, 'get new name failed: ']).times(0);
        mocker.clear(LogUtil);
      }

    })

    it('AppInfoListPresenterTest_pushOldDroi', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.error);
      try {
        let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let uid = bundleManager.getApplicationInfoSync(DROI_OLD_BUNDLE_NAME, flag).uid;
        let appInfo = appInfoListPresenter.pushDroi();
        expect(appInfo?.bundleName).assertEqual(DROI_OLD_BUNDLE_NAME);
        expect(appInfo?.appIndex).assertEqual(ORI_APP_INDEX);
        expect(appInfo?.uid).assertEqual(uid);
      } catch (e) {
        mocker.verify('error', [TAG, 'get old name failed: ']).times(0);
        mocker.clear(LogUtil);
      }
    })

    it('AppInfoListPresenterTest_pushAbroad', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.error);
      try {
        let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let uid = bundleManager.getApplicationInfoSync(ABROAD_BUNDLE_NAME, flag).uid;
        let appInfo = appInfoListPresenter.pushAbroad();
        expect(appInfo?.bundleName).assertEqual(ABROAD_BUNDLE_NAME);
        expect(appInfo?.appIndex).assertEqual(ORI_APP_INDEX);
        expect(appInfo?.uid).assertEqual(uid);
      } catch (e) {
        mocker.verify('error', [TAG, 'get new name failed: ']).times(0);
        mocker.clear(LogUtil);
      }
    })

    it('AppInfoListPresenterTest_pushPldAbroad', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.error);
      try {
        let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let uid = bundleManager.getApplicationInfoSync(ABROAD_OLD_BUNDLE_NAME, flag).uid;
        let appInfo = appInfoListPresenter.pushAbroad();
        expect(appInfo?.bundleName).assertEqual(ABROAD_OLD_BUNDLE_NAME);
        expect(appInfo?.appIndex).assertEqual(ORI_APP_INDEX);
        expect(appInfo?.uid).assertEqual(uid);
      } catch (e) {
        mocker.verify('error', [TAG, 'get new name failed: ']).times(0);
        mocker.clear(LogUtil);
      }
    })

    it('AppInfoListPresenterTest_countFlows', 0, () => {
      let txBytes = 10;
      let rxBytes = 10;
      let data = {
        txBytes: txBytes,
        rxBytes: rxBytes
      } as statistics.NetStatsInfo;
      expect(appInfoListPresenter.countFlows(data)).assertEqual(txBytes + rxBytes);
    })

    it('AppInfoListPresenterTest_isNormalApp', 0, () => {
      expect(appInfoListPresenter.isNormalApp(DROI_UID, 0)).assertEqual(false);
      expect(appInfoListPresenter.isNormalApp(ABROAD_TOTAL_UID, 0)).assertEqual(false);
      expect(appInfoListPresenter.isNormalApp(1000, 0)).assertEqual(true);
    })

    it('AppInfoListPresenterTest_checkNormalAppByName', 0, () => {
      expect(appInfoListPresenter.checkNormalAppByName(DROI_BUNDLE_NAME, 0)).assertEqual(false);
      expect(appInfoListPresenter.checkNormalAppByName(DROI_OLD_BUNDLE_NAME, 0)).assertEqual(false);
      expect(appInfoListPresenter.checkNormalAppByName(ABROAD_BUNDLE_NAME, 0)).assertEqual(false);
      expect(appInfoListPresenter.checkNormalAppByName(ABROAD_OLD_BUNDLE_NAME, 0)).assertEqual(false);
      expect(appInfoListPresenter.checkNormalAppByName('1000', 0)).assertEqual(true);
    })

    it('AppInfoListPresenterTest_createAppInfo01', 0, () => {
      let bundleName = 'com.example.app';
      let uid = 1000;
      let flow = 1000;
      let appIndex = ORI_APP_INDEX;
      let getAppInfo = false;
      let appInfo = appInfoListPresenter.createAppInfo(bundleName, uid, flow, appIndex, getAppInfo);
      expect(appInfo.bundleName).assertEqual(bundleName);
      expect(appInfo.uid).assertEqual(uid);
      expect(appInfo.flow).assertEqual(flow);
      expect(appInfo.appIndex).assertEqual(appIndex);
      expect(appInfo.bundleType).assertEqual(UNKNOWN_BUNDLE_TYPE);
    })

    it('AppInfoListPresenterTest_checkOtherApps01', 0, () => {
      appInfoListPresenter.initData();
      let appInfo1 = new AppInfo(`1`, 1, 1, 1);
      let appInfo2 = new AppInfo(`2`, 2, 2, 2);
      let appArray = [appInfo1, appInfo2];
      expect(appInfoListPresenter.checkOtherApps(appArray).length).assertEqual(appArray.length);
    })

    it('AppInfoListPresenterTest_checkOtherApps02', 0, () => {
      appInfoListPresenter.initData();
      let appInfo1 = new AppInfo(`1`, 1, 1, 1);
      let appInfo2 = new AppInfo(`2`, 2, 2, 2);
      let appArray = [appInfo1, appInfo2];
      appInfoListPresenter.isNormalApp(DROI_UID, 100);
      let app = appInfoListPresenter.pushDroi();
      let resultLength = appArray.length;
      if (app) {
        expect(appInfoListPresenter.checkOtherApps(appArray).length).assertEqual(resultLength + 1);
      } else {
        expect(appInfoListPresenter.checkOtherApps(appArray).length).assertEqual(resultLength);
      }
    })

    it('AppInfoListPresenterTest_checkOtherApps03', 0, () => {
      appInfoListPresenter.initData();
      let appInfo1 = new AppInfo(`1`, 1, 1, 1);
      let appInfo2 = new AppInfo(`2`, 2, 2, 2);
      let appArray = [appInfo1, appInfo2];
      appInfoListPresenter.isNormalApp(ABROAD_TOTAL_UID, 100);
      let app = appInfoListPresenter.pushAbroad();
      let resultLength = appArray.length;
      if (app) {
        expect(appInfoListPresenter.checkOtherApps(appArray).length).assertEqual(resultLength + 1);
      } else {
        expect(appInfoListPresenter.checkOtherApps(appArray).length).assertEqual(resultLength);
      }
    })

    it('AppInfoListPresenterTest_transmitAppTrafficInfo', 0, async () => {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let selfUid = bundleInfo.appInfo.uid;
      let statusInfo1: statistics.NetStatsInfo = {
        rxBytes: 100,
        txBytes: 100,
        rxPackets: 0,
        txPackets: 0
      }

      let uninstallUid = UNINSTALLED_APPS_UID;
      let compatibleUid = DROI_UID;
      let sysServiceUid = 0;
      let exceptionUid = UNINSTALLED_APPS_UID - 1000;
      let mockData: Map<string, object> = new Map();
      mockData.set(selfUid.toString(), statusInfo1);
      mockData.set(uninstallUid.toString(), statusInfo1);
      mockData.set(compatibleUid.toString(), statusInfo1);
      mockData.set(sysServiceUid.toString(), statusInfo1);
      mockData.set(exceptionUid.toString(), statusInfo1);
      appInfoListPresenter.initData();
      let result = await appInfoListPresenter.transmitAppTrafficInfo(SLOT_1, mockData);
      expect(result.appList.length).assertLargerOrEqual(1);
      expect(result.appList[0].uid).assertEqual(selfUid);
      expect(result.uninstalledAppsFlows).assertEqual(200);
      expect(result.sysServiceList.get(sysServiceUid)).assertEqual(200);
    })

    it('getAllAppTrafficsOfCellular', 0, async () => {
      let startDate = new Date(0);
      let endDate = new Date(0);
      endDate.setDate(startDate.getDate() + 1);
      let result = await appInfoListPresenter.getAllAppTrafficsOfCellular(10000, startDate, endDate);
      expect(result.startDate).assertEqual(startDate.getTime());
      expect(result.day).assertEqual(startDate.getDate());
    })
  })
}