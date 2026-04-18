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
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import DotUtils from '../../../../main/ets/util/Dot/DotUtils';
import { PackageUsageStatus, SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil';
import { bundleManager } from '@kit.AbilityKit';
import { NetworkType } from '../../../../main/ets/constants/CommonConstants';
import {
  DialogOperationState,
  NewToggleState,
  PolicyDialogUsersOperation,
  ToggleState
} from '../../../../main/ets/util/Dot/DotCommon';
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo';

export default function DotUtil() {
  describe('DotUtilTest', () => {
    let dotUtil: DotUtils;
    beforeEach(() => {
      dotUtil = DotUtils.getInstance();
      dotUtil.setUnitTestPropetry();
    })
    it('DotUtilBasicTest', 0, async () => {
      dotUtil.versionNumber = 'test';
      dotUtil.updateCommunicationSettingVersion();
      dotUtil.versionNumber = '';
      dotUtil.reportTotalTrafficDetails(0, undefined, PackageUsageStatus.PACKNONE, ['0 B']);
      dotUtil.reportTotalTrafficDetails(0, 2, PackageUsageStatus.PACKNONE, ['0 B']);
      dotUtil.reportQuotaNotificationPageStatus(SLOT_1, 100, 100, 100);
      dotUtil.reportPackageSettingsPageStatus(SLOT_1, 100, '100', 100);
      dotUtil.reportAllowWirelessDataDialog(PolicyDialogUsersOperation.WLAN_ONLY);
      dotUtil.reportDisableMobileDataDialog(PolicyDialogUsersOperation.WLAN_ONLY);
      dotUtil.reportClickMoreTrafficSettings();
      dotUtil.reportClickPackageSettings(SLOT_1);
      dotUtil.reportClickQuotaNotification(SLOT_1);
      dotUtil.reportClickUnlimitedTrafficToggle(SLOT_1, NewToggleState.OK);
      dotUtil.reportClickPackageQuota(SLOT_1);
      dotUtil.reportPackageQuotaDialog(SLOT_1, PolicyDialogUsersOperation.WLAN_ONLY, '200', 'kb');
      dotUtil.reportClickStartDateOfMonth(SLOT_1);
      dotUtil.reportStartDataDialog(SLOT_1, DialogOperationState.OK, 30);
      dotUtil.reportClickMonthlyTrafficExceed(SLOT_1);
      dotUtil.reportWhenTrafficExceedDialog(SLOT_1, DialogOperationState.CANCEL);
      dotUtil.reportClickMonthlyTrafficRemind(SLOT_1, 80);
      dotUtil.reportClickDailyUsedTrafficRemind(SLOT_1, 80);
      dotUtil.reportChangeWlanNetworkToggle('com.example.app', ToggleState.CLOSE);
      dotUtil.reportChangeMobileDataNetworkToggle('com.example.app', ToggleState.CLOSE);

      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      expect(bundleInfo.versionName).assertEqual(dotUtil.versionNumber);
    })

    it('DotUtilReportSystemAndServiceDataRankStatus', 0, async () => {
      let sysServiceList: Map<number, number> = new Map();
      sysServiceList.set(0, 0);
      sysServiceList.set(1, 1);
      dotUtil.reportSystemAndServiceDataRankStatus(sysServiceList, NetworkType.MOBILE);
      dotUtil.reportSystemAndServiceDataRankStatus(sysServiceList, NetworkType.WLAN);
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      expect(bundleInfo.versionName).assertEqual(dotUtil.versionNumber);
    })

    it('DotUtilDotStatisticDetails', 0, async () => {
      dotUtil.dotStatisticDetails([new AppInfo('', -1, 0, 0)], NetworkType.MOBILE);
      dotUtil.dotStatisticDetails([new AppInfo('', -1, 0, 0)], NetworkType.WLAN);
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      expect(bundleInfo.versionName).assertEqual(dotUtil.versionNumber);
    })

  });

}