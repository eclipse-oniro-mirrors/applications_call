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
import { getFlowText } from '../../../../main/ets/constants/Constants';

export default function CommonConstantsTest() {
  describe('CommonConstantsTest', () => {
    it('getFlowText', 0, () => {
      let flow0 = getFlowText(12.771);
      expect(flow0).assertEqual('12.77B');
      let flow1 = getFlowText(12.7 * 1024);
      expect(flow1).assertEqual('12.70KB');
      let flow2 = getFlowText(12 * Math.pow(1024, 2));
      expect(flow2).assertEqual('12.00MB');
      let flow3 = getFlowText(1 * Math.pow(1024, 3));
      expect(flow3).assertEqual('1.00GB');
      let flow4 = getFlowText(12 * Math.pow(1024, 4));
      expect(flow4).assertEqual('12.00TB');
      let flow5 = getFlowText(1.1 * Math.pow(1024, 5));
      expect(flow5).assertEqual('1126.40TB');
    })
  })
}