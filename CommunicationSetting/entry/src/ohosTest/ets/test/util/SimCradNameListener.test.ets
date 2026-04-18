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
import { SimCradNameListener } from '../../../../main/ets/util/SimCradNameListener';
import { radio, sim } from '@kit.TelephonyKit';
import { SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil';

export default function SimCradNameListenerTest() {
  describe('SimCradNameListenerTest', () => {

    it('SimCradNameListenerBasicTest', 0, async () => {
      let simcradnamelistener: SimCradNameListener = new SimCradNameListener();

      if (simcradnamelistener.getMaxSimCount() === 0) {
        let result = simcradnamelistener.isValidOfSlotId(-1);
        expect(result).assertEqual(false);
      } else {
        let result = simcradnamelistener.isValidOfSlotId(0);
        expect(result).assertEqual(true);
        simcradnamelistener.addSimCardStatusChangeListener(() => {
        });
        simcradnamelistener.unregisterListenter();

        try {
          simcradnamelistener.isSimActive(SLOT_1);
          simcradnamelistener.getShowName(SLOT_1);
          simcradnamelistener.update(SLOT_1);
          simcradnamelistener.getNetName(SLOT_1);
          simcradnamelistener.handleNoActiveOrException(SLOT_1);
          simcradnamelistener.isSimActive(100);
          simcradnamelistener.getShowName(100);
          simcradnamelistener.update(100);
          simcradnamelistener.getNetName(100);
          await sim.isSimActive(100);
          await sim.getShowName(100);
          await sim.getSimState(100);
          await radio.getOperatorName(100);
        } catch (e) {
        }
        let result1 = simcradnamelistener.isValidOfSlotId(-1);
        expect(result1).assertEqual(false);
      }

    });

  });
}