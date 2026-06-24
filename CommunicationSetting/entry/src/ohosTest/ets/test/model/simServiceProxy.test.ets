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
import { describe, expect, it } from '@ohos/hypium'
import { SimServiceProxy } from '../../../../main/ets/model/simServiceProxy'
import { SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil'
import sim from '@ohos.telephony.sim'

export default function SimServiceProxyTest() {
  describe('SimServiceProxyTest', () => {
    it('SimServiceProxyStateAndActiveStatusTest', 0, async () => {
      let proxy = new SimServiceProxy()
      let simStatus = await proxy.getSimState(SLOT_1);
      let expectStatus = sim.getSimStateSync(SLOT_1);
      expect(simStatus).assertEqual(expectStatus);
      proxy.getShowName(SLOT_1);
      let isActive = await proxy.isSimActive(SLOT_1);
      let expectIsActive = sim.isSimActiveSync(SLOT_1);
      expect(expectIsActive).assertEqual(isActive);
    })
  })
}