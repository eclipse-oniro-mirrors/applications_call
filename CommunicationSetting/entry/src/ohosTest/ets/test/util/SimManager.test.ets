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
import { SimManager } from '../../../../main/ets/util/SimManager';
import { sim } from '@kit.TelephonyKit';
import { SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil';
import { beforeEach } from '@ohos/hypium/src/main/interface';
import { AppStorageUtils } from '../../../../main/ets/util/AppStorageUtils';
import { SimInfo } from '../../../../main/ets/data/SimInfo';

export default function SimManagerTest() {
  describe('SimManagerTest', () => {
    let simManager: SimManager;
    beforeEach(() => {
      simManager = SimManager.getInstance();
    })

    it('SimManagerTest_getInstance', 0, () => {
      let simManager1: SimManager = SimManager.getInstance();
      expect(simManager).assertDeepEquals(simManager1);
    });

    it('SimManagerTest_init', 0, () => {
      let slotCount = 0;
      try {
        slotCount = sim.getMaxSimCount();
      } catch (e) {
      }
      simManager.init();
      simManager.destroy();
      expect(simManager.slotCount).assertEqual(slotCount);
    });

    it('SimManagerTest_hasSimCard', 0, async () => {
      simManager.hasSimCard(SLOT_1);
      let hasSimCard = false;
      try {
        hasSimCard = await sim.hasSimCard(SLOT_1);
      } catch (e) {
      }
      let result = AppStorage.get(`${AppStorageUtils.SIM_INFO}${SLOT_1}`) as SimInfo;
      expect(result.hasSimCard).assertEqual(hasSimCard);
    });

  });
}