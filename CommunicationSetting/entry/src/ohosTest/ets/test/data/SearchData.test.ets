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
import { SearchInfo } from '../../../../main/ets/data/SearchData'

export default function SearchDataTest() {
  describe('SearchDataTest', () => {
    it('SearchData', 0, () => {
      let searchInfo = new SearchInfo(1, 1, 1);
      expect(searchInfo.pageIndex).assertEqual(1);
      expect(searchInfo.slotId).assertEqual(1);
      expect(searchInfo.networkType).assertEqual(1);
      expect(searchInfo.isSlotIdDefault()).assertFalse();
      expect(searchInfo.isTrafficManager()).assertFalse();
      expect(searchInfo.isNetworkAccess()).assertTrue();
      expect(searchInfo.isDataRankings()).assertFalse();
      expect(searchInfo.isSystemAndServices()).assertFalse();
      expect(searchInfo.isModeMobile()).assertFalse();
      expect(searchInfo.isModeWlan()).assertTrue();
      expect(searchInfo.isNetworkTypeValueAble()).assertTrue();
      expect(searchInfo.getNetworkType()).assertEqual(1);
    })
  })
}