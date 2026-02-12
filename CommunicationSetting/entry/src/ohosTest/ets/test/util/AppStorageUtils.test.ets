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
import { describe, it, expect } from '@ohos/hypium';
import { MAX_SIM_COUNT } from '../../../../main/ets/constants/CommonConstants';
import { SimInfo } from '../../../../main/ets/data/SimInfo';
import { AppStorageUtils } from '../../../../main/ets/util/AppStorageUtils';
import { SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil';

export default function AppStorageUtilsTest() {
  describe('AppStorageUtilsTest_testSuite', () => {

    it('AppStorageUtilsTest_updateSimInfo', 0, async () => {
      let simInfo = new SimInfo(SLOT_1);
      simInfo.hasSimCard = true;
      simInfo.operatorName = '中国移动';
      AppStorageUtils.updateSimInfo(SLOT_1, simInfo);
      let result = AppStorage.get(`${AppStorageUtils.SIM_INFO}${SLOT_1}`) as SimInfo;
      expect(result).assertDeepEquals(simInfo);
    });


    it('AppStorageUtilsTest_checkSimCount', 0, async () => {
      AppStorageUtils.updateSimCount(MAX_SIM_COUNT);
      let result = AppStorageUtils.getSimCount();
      expect(result).assertEqual(MAX_SIM_COUNT);
    });
  })
}
