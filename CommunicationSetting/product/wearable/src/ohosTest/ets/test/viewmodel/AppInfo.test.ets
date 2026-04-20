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

import { ArgumentMatchers, beforeAll, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { LogUtil } from '../../../../main/ets/util/LogUtil';
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo';
import { UNKNOWN_BUNDLE_TYPE } from '../../../../main/ets/constants/Constants';

export default function AppInfoTest() {
  describe('AppInfoTest', () => {
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;
    let appIndex: number = 0;
    let bundleType: number = 0;
    beforeAll(() => {
    })
    it('AppInfoBasicTest', 0, () => {
      let appInfo = new AppInfo(bundleName, uid, appIndex, bundleType, {
        allowWiFi: false, allowCellular: true
      });
      expect(AppInfo.appInfoChecked(appInfo)).assertTrue();
      expect(appInfo.bundleName).assertEqual(bundleName);
      expect(appInfo.uid).assertEqual(uid);
      expect(appInfo.flow).assertEqual(0);
      expect(appInfo.flowText).assertEqual('0.00B');
      expect(appInfo.mobileAccess).assertTrue();
      expect(appInfo.wifiAccess).assertFalse();
    })
    it('appInfoCheckedTest', 0, () => {
      let appInfo = new AppInfo('', -1, 0, 0);
      expect(AppInfo.appInfoChecked(appInfo)).assertFalse();
      appInfo.bundleName = 'communication';
      expect(AppInfo.appInfoChecked(appInfo)).assertTrue();
      appInfo.label = 'app';
      appInfo.img = undefined;
      expect(AppInfo.appInfoChecked(appInfo)).assertFalse();
      appInfo.img = $r('app.media.app_icon');
      expect(AppInfo.appInfoChecked(appInfo)).assertTrue();
    })
    it('appInfoCreateTest', 0, () => {
      let appInfo = AppInfo.createWithFlow('com.ohos.communicationsetting', -1, 1024, 0);
      expect(appInfo.bundleName).assertEqual('com.ohos.communicationsetting');
      expect(appInfo.flowText).assertEqual('1.00KB');
      expect(AppInfo.appInfoChecked(appInfo)).assertTrue();
      appInfo.bundleName = 'communication';
      expect(AppInfo.appInfoChecked(appInfo)).assertTrue();
      appInfo.label = 'app';
      appInfo.img = undefined;
      expect(AppInfo.appInfoChecked(appInfo)).assertFalse();
      appInfo.img = $r('app.media.app_icon');
      expect(AppInfo.appInfoChecked(appInfo)).assertTrue();
    })
    it('appInfoGetApplicationInfoTest', 0, () => {
      let appInfo = AppInfo.createWithFlow('com.ohos.communicationsetting', -1, 0, 0);
      appInfo.getApplicationInfo();
      expect(appInfo.label).assertEqual('');
    })
    it('getApplicationInfoTestWhenUidIsNOtOne', 0, () => {
      let appInfo: ESObject = new AppInfo('bundleNameTest', -1, 2, 3);
      let mocker = new MockKit();
      let mockLogUtil: ESObject = mocker.mockFunc(LogUtil, LogUtil.warn);
      when(mockLogUtil)(ArgumentMatchers.any).afterReturn(undefined);
      appInfo.getApplicationInfo();
      mocker.ignoreMock(LogUtil, LogUtil.warn);
      mocker.clearAll();
    })
    it('getApplicationInfoTestWhenBundleTypeOne', 0, () => {
      let appInfo: ESObject = new AppInfo('bundleNameTest', 1, 2, 3);
      let mocker = new MockKit();
      let mockLogUtil: ESObject = mocker.mockFunc(LogUtil, LogUtil.info);
      when(mockLogUtil)(ArgumentMatchers.any).afterReturn(undefined);
      appInfo.label = 'labelTest';
      appInfo.img = 'imgTest';
      appInfo.bundleType = UNKNOWN_BUNDLE_TYPE;
      appInfo.getApplicationInfo();
      appInfo.bundleType = 5;
      appInfo.getApplicationInfo();
      mocker.ignoreMock(LogUtil, LogUtil.info);
      mocker.clearAll();
    })
    it('getApplicationInfoTestWhenBundleType', 0, () => {
      let appInfo: AppInfo = new AppInfo('bundleNameTest', 1, 2, UNKNOWN_BUNDLE_TYPE);
      let mocker = new MockKit();
      let appInfo1 = AppInfo.createWithFlow('com.ohos.communicationsetting', 1, 0, 0);
      let mockLogUtil = mocker.mockFunc(LogUtil, LogUtil.info);
      when(mockLogUtil)(ArgumentMatchers.any).afterReturn(undefined);
      appInfo.bundleType = UNKNOWN_BUNDLE_TYPE;
      appInfo1.getApplicationInfo();
      mocker.ignoreMock(LogUtil, LogUtil.info);
      mocker.clearAll();
    })
    it('appInfoCheckedTestWhenAppUndefined', 0, () => {
      let appInfo: ESObject = undefined;
      expect(AppInfo.appInfoChecked(appInfo)).assertFalse();
    })
  })
}