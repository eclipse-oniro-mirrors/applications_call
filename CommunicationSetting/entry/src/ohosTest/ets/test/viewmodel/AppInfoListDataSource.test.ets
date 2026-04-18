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
import { describe, beforeAll, it, expect } from '@ohos/hypium'
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo'
import AppInfoListDataSource from '../../../../main/ets/viewmodel/AppInfoListDataSource'
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../testability/TestAbility'

export default function AppInfoListDataSourceTest() {
  describe('AppInfoListDataSourceTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;
    let appIndex: number = 0;
    let bundleType: number = 0;
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('AppInfoListDataSourceBasicTest', 0, () => {
      let listResource = new AppInfoListDataSource();
      let appArray: Array<AppInfo> = [];
      let app = new AppInfo(bundleName, uid, appIndex, bundleType);
      appArray.push(app);
      listResource.refresh(appArray);
      expect(listResource.getData(-1)).assertUndefined();
      expect(JSON.stringify(listResource.getData(0))).assertEqual(JSON.stringify({index:0, appInfo: app}));
      expect(listResource.totalCount()).assertEqual(1);
      expect(listResource.getAllData()).assertEqual(appArray);
    })
    it('refreshAccessByUidTest', 0, () => {
      let listResource = new AppInfoListDataSource();
      let appArray: Array<AppInfo> = [];
      let app = new AppInfo(bundleName, uid, appIndex, bundleType);
      appArray.push(app);
      listResource.refresh(appArray);
      listResource.refreshAccessByUid(uid, false, false);
      let result = listResource.getAllData()[0];
      expect(result.wifiAccess).assertFalse();
      expect(result.mobileAccess).assertFalse();
    })
    it('getDataTest01', 0, () => {
      let listResource = new AppInfoListDataSource();
      const result = listResource.getData(0);
      expect(result).assertEqual(undefined);
    });
    it('getDataTest02', 0, () => {
      let listResource = new AppInfoListDataSource();
      let appArray: Array<AppInfo> = [];
      let app = new AppInfo(bundleName, uid, appIndex, bundleType);
      appArray.push(app);
      listResource.refresh(appArray);
      const result = listResource.getData(0)?.appInfo;
      expect(result?.uid).assertEqual(uid);
      expect(result?.bundleName).assertEqual(bundleName);
      expect(result?.appIndex).assertEqual(appIndex);
      expect(result?.bundleType).assertEqual(bundleType);
    });
    it('getDataTest03', 0, () => {
      let listResource = new AppInfoListDataSource();
      const result = listResource.getData(-1);
      expect(result).assertEqual(undefined);
    });
    it('getDataTest04', 0, () => {
      let listResource = new AppInfoListDataSource();
      const result = listResource.getData(2);
      expect(result).assertEqual(undefined);
    });
    it('totalCount01', 0, () => {
      let listResource = new AppInfoListDataSource();
      const result = listResource.totalCount();
      expect(result).assertEqual(0);
    });
    it('totalCount02', 0, () => {
      let listResource = new AppInfoListDataSource();
      let appArray: Array<AppInfo> = [];
      let app = new AppInfo(bundleName, uid, appIndex, bundleType);
      appArray.push(app);
      listResource.refresh(appArray);
      const result = listResource.totalCount();
      expect(result).assertEqual(1);
    });
  })
}