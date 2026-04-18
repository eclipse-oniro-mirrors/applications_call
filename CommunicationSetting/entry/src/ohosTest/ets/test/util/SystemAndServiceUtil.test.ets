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
import { describe, it, expect } from '@ohos/hypium'
import SysServiceListDataSource, {
  SysAndServiceInfo,
  SysServiceCategoryManager
} from '../../../../main/ets/util/SystemAndServiceUtil'
import bundleManager from '@ohos.bundle.bundleManager';

export default function SystemAndServiceUtilTest() {
  describe('SystemAndServiceUtilTest', () => {

    it('SystemAndServiceUtilBasicTest', 0, () => {
      let sysServiceListDataSource = new SysServiceListDataSource();
      let sysServiceList: Map<number, number> = new Map<number, number>();
      sysServiceList.set(1099, 100); // uid 1099 is in category system 0
      let sysServiceCategoryManager = new SysServiceCategoryManager(sysServiceList);
      let sysArray = sysServiceCategoryManager.sysAndServiceArray;
      sysServiceListDataSource.refresh(sysArray);
      expect(sysServiceListDataSource.getData(0)?.sysServiceInfo).assertDeepEquals(sysArray[0]);
      expect(sysServiceListDataSource.getData(10)).assertUndefined();
      expect(sysArray.length).assertEqual(1);
      expect(sysArray[0].getCategoryIndex()).assertEqual(0);
      expect(sysArray[0].getFlowText()).assertEqual('100.00 B');
      expect(sysServiceListDataSource.totalCount()).assertEqual(1);
      expect(sysServiceListDataSource.getAllData()).assertEqual(sysArray);

      let infoA = new SysAndServiceInfo(0, 0, $r('app.string.category_system'));
      infoA.addFlow(100);
      expect(infoA.flow).assertEqual(100);
      let infoB = new SysAndServiceInfo(300, 1, $r('app.string.category_general_service'));
      expect(SysAndServiceInfo.compare(infoA, infoB)).assertEqual(200);
    })

    it('SystemAndServiceUtilTest_addCategoryFlows', 0, async () => {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let uid = bundleInfo.appInfo.uid;
      let sysServiceListDataSource = new SysServiceListDataSource();
      let sysServiceList: Map<number, number> = new Map<number, number>();
      sysServiceList.set(1099, 100); // uid 1099 is in category system 0
      sysServiceList.set(uid, 200)
      let sysServiceCategoryManager = new SysServiceCategoryManager(sysServiceList);
      sysServiceCategoryManager.sysAndServiceArray.forEach((data) => {
        if (data.getCategoryIndex() === uid) {
          expect(data.getFlowText()).assertEqual('200')
        } else {
          expect(data.getFlowText()).assertEqual('300.00 B')
        }
      })
    })

  })
}