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
import { describe, expect, it } from '@ohos/hypium';
import { HdsHandledResult, HDSUtil } from '../../../../main/ets/util/HDSUtil';
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo';
import { bundleManager } from '@kit.AbilityKit';
import VibrationUtils, { VibrationEffect } from '../../../../main/ets/util/VibrationUtils';


export default function HDSUtilTest() {
  describe('HDSUtilTest', () => {
    it('HDSUtilTest_hdsIconsHandle01', 0, async () => {
      let appInfos: AppInfo[] = [];
      let result: HdsHandledResult = await HDSUtil.hdsIconsHandle(appInfos, getContext());
      expect(result.apps.length).assertEqual(0);
    })

    it('HDSUtilTest_hdsIconsHandle02', 0, async () => {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo1 = new AppInfo(bundleInfo.appInfo.name, bundleInfo.appInfo.uid, 0, bundleManager.BundleType.APP);
      appInfo1.flow = 100;
      let appInfo2 = new AppInfo(bundleInfo.appInfo.name, bundleInfo.appInfo.uid, 0, bundleManager.BundleType.APP);
      appInfo2.flow = 200;
      appInfo2.isRubbishData = true;
      appInfo2.isCompatibleApp = true;
      let appInfos: AppInfo[] = [appInfo1, appInfo2];
      let result: HdsHandledResult = await HDSUtil.hdsIconsHandle(appInfos, getContext());
      VibrationUtils.onceVibration(VibrationEffect.Light);
      VibrationUtils.onceVibration('error params');
      expect(result.apps.length).assertEqual(appInfos.length - 1);
      expect(result.apps[0].bundleName).assertEqual(appInfo1.bundleName);
      expect(result.apps[0].flow).assertEqual(appInfo1.flow);
      expect(result.mergeFlows).assertEqual(200);
    })

  })
}