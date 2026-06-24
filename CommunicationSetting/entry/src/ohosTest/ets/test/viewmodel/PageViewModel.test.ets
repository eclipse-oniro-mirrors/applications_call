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
import PageViewModel from '../../../../main/ets/viewmodel/PageViewModel'
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../testability/TestAbility';
import { sim } from '@kit.TelephonyKit';
import { PackageUsageInterface } from '../../../../main/ets/util/TrafficPackageUtil';

export default function PageViewModelTest() {
  describe('PageViewModelTest', () => {
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
    it('AppTrafficCompare01', 0, () => {
      let app1 = new AppInfo(bundleName, uid, appIndex, bundleType);
      app1.flow = 0;
      let app2 = new AppInfo(bundleName, uid, appIndex, bundleType);
      app2.flow = 2;
      let result = PageViewModel.appTrafficCompare(app1, app2);
      expect(result).assertEqual(2);
    })
    it('AppTrafficCompare02', 0, () => {
      let app1 = new AppInfo(bundleName, uid, appIndex, bundleType);
      let app2 = new AppInfo(bundleName, uid, appIndex, bundleType);
      let result = PageViewModel.appTrafficCompare(app1, app2);
      expect(result).assertEqual(0);
    })
    it('AppAlphabetCompare03', 0, () => {
      let app1 = new AppInfo(bundleName, uid, appIndex, bundleType);
      let app2 = new AppInfo(bundleName, uid, appIndex, bundleType);
      let result = PageViewModel.appAlphabetCompare(app1, app2);
      expect(result).assertEqual(0);
    })
    it('AppTrafficCompare04', 0, () => {
      let app1: AppInfo | null = null;
      let app2: AppInfo | null = null;
      try {
        let result = PageViewModel.appTrafficCompare(app1!, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('AppTrafficCompare05', 0, () => {
      let app1: AppInfo | null = null;
      let app2: AppInfo = new AppInfo(bundleName, uid, appIndex, bundleType);
      try {
        let result = PageViewModel.appTrafficCompare(app1!, app2);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('AppTrafficCompare06', 0, () => {
      let app2: AppInfo | null = null;
      let app1: AppInfo = new AppInfo(bundleName, uid, appIndex, bundleType);
      try {
        let result = PageViewModel.appTrafficCompare(app1, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('sysListCompare01', 0, () => {
      let app1: [number, number] | null = null;
      let app2: [number, number] | null = null;
      try {
        let result = PageViewModel.sysListCompare(app1!, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('sysListCompare02', 0, () => {
      let app1: [number, number] | null = null;
      let app2: [number, number] = [0, 0];
      try {
        let result = PageViewModel.sysListCompare(app1!, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('sysListCompare03', 0, () => {
      let app2: [number, number] | null = null;
      let app1: [number, number] = [0, 0];
      try {
        let result = PageViewModel.sysListCompare(app1, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('sysListCompare04', 0, () => {
      let app2: [number, number] = [1, 2];
      let app1: [number, number] = [0, 0];
      let result = PageViewModel.sysListCompare(app1, app2);
      expect(result).assertEqual(2);
    })
    it('sysListCompare05', 0, () => {
      let app2: [number, number] = [1, 2];
      let app1: [number, number] = [0, 2];
      let result = PageViewModel.sysListCompare(app1, app2);
      expect(result).assertEqual(1);
    })
    it('sysListCompare06', 0, () => {
      let app1: [number, number] = [0, 2];
      let app2: [number, number] = [0, 2];
      let result = PageViewModel.sysListCompare(app1, app2);
      expect(result).assertEqual(0);
    })
    it('sysListCompare07', 0, () => {
      let app1: [number, number] = [1, 2];
      let app2: [number, number] = [0, 0];
      let result = PageViewModel.sysListCompare(app1, app2);
      expect(result).assertEqual(-2);
    })
    it('sysListCompare08', 0, () => {
      let app1: [number, number] = [1, 2];
      let app2: [number, number] = [0, 2];
      let result = PageViewModel.sysListCompare(app1, app2);
      expect(result).assertEqual(-1);
    })

    it('appAlphabetCompare01', 0, () => {
      let app1: AppInfo | null = null;
      let app2: AppInfo | null = null;
      try {
        let result = PageViewModel.appAlphabetCompare(app1!, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('appAlphabetCompare02', 0, () => {
      let app1 = new AppInfo(bundleName, uid, appIndex, bundleType);
      let app2 = new AppInfo(bundleName, uid, appIndex, bundleType);
      let result = PageViewModel.appAlphabetCompare(app1, app2);
      expect(result).assertEqual(0);
    })
    it('appAlphabetCompare03', 0, () => {
      let app1: AppInfo | null = null;
      let app2: AppInfo = new AppInfo(bundleName, uid, appIndex, bundleType);
      try {
        let result = PageViewModel.appAlphabetCompare(app1!, app2);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('appAlphabetCompare04', 0, () => {
      let app2: AppInfo | null = null;
      let app1: AppInfo = new AppInfo(bundleName, uid, appIndex, bundleType);
      try {
        let result = PageViewModel.appAlphabetCompare(app1, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('GetFirstLetter01', 0, () => {
      let result = PageViewModel.getFirstLetter('测试');
      expect(result).assertEqual('C');
    })
    it('GetFirstLetter02', 0, () => {
      let result = PageViewModel.getFirstLetter('%1验证');
      expect(result).assertEqual('#');
    })
    it('GetFirstLetter03', 0, () => {
      let param: string | null = null;
      let result = PageViewModel.getFirstLetter(param!);
      expect(result).assertEqual('#');
    })
    it('hasTwoSimCard', 0, () => {
      let hasTwoSimCard: boolean = false;
      try {
        hasTwoSimCard = sim.hasSimCardSync(0) && sim.hasSimCardSync(1);
      } catch (e) {
      }
      if (hasTwoSimCard) {
        expect(PageViewModel.hasTwoSimCard()).assertEqual(true);
      } else {
        expect(PageViewModel.hasTwoSimCard()).assertEqual(false);
      }
    })
    it('existSimCard01', 0, () => {
      let existSimCard: boolean = false;
      try {
        existSimCard = (sim.hasSimCardSync(0) || sim.hasSimCardSync(1));
      } catch (e) {
      }
      if (existSimCard) {
        expect(PageViewModel.existSimCard()).assertEqual(true);
      } else {
        expect(PageViewModel.existSimCard()).assertEqual(false);
      }
    })

    it('traficeUseCompare01', 0, () => {
      let app1: PackageUsageInterface | null = null;
      let app2: PackageUsageInterface | null = null;
      try {
        let result = PageViewModel.traficeUseCompare(app1!, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('traficeUseCompare02', 0, () => {
      let app1: PackageUsageInterface | null = null;
      let app2: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 1
      };
      try {
        let result = PageViewModel.traficeUseCompare(app1!, app2);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('traficeUseCompare03', 0, () => {
      let app2: PackageUsageInterface | null = null;
      let app1: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 1
      };
      try {
        let result = PageViewModel.traficeUseCompare(app1, app2!);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('traficeUseCompare04', 0, () => {
      let app1: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 1
      };
      let app2: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 1
      };
      try {
        let result = PageViewModel.traficeUseCompare(app1, app2);
        expect(result).assertEqual(0);
      } catch (e) {
      }
    })
    it('traficeUseCompare05', 0, () => {
      let app1: PackageUsageInterface = {
        startDate: 3,
        day: 1,
        flow: 1
      };
      let app2: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 1
      };
      try {
        let result = PageViewModel.traficeUseCompare(app1, app2);
        expect(result).assertEqual(2);
      } catch (e) {
      }
    })
    it('traficeUseCompare06', 0, () => {
      let app1: PackageUsageInterface = {
        startDate: 3,
        day: 2,
        flow: 1
      };
      let app2: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 4
      };
      try {
        let result = PageViewModel.traficeUseCompare(app1, app2);
        expect(result).assertEqual(2);
      } catch (e) {
      }
    })
    it('getAppFlow', 0, async () => {
      const result = await PageViewModel.getAppFlow('someBundleName', 1, 123, 30, 0, 1);
      expect(result.networkType).assertEqual(1);
    });
    it('getAppFlow01', 0, async () => {
      let result = await PageViewModel.getAppFlow('com.test.test', 0, 0, 30, 1, 1);
      expect(result.networkType).assertEqual(0);
    })
    it('getAppFlow02', 0, async () => {
      let result = await PageViewModel.getAppFlow('com.test.test', 0, 0, 30, 1, 1);
      expect(result.networkType).assertEqual(0);
    })
  })
}