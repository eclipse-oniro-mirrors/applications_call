/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { describe, it, expect } from '@ohos/hypium';
import Utils from '../../../main/ets/common/utils/utils';
import { BannerResourceManager, DarkResIcon } from '../../../main/ets/model/BannerResourceManager';

export default function BannerResourceManagerTest() {
  describe('BannerResourceManagerTest', () => {
    it('createDarkResIcon', 0, () => {
      BannerResourceManagerTest_createDarkResIcon();
    })
  })
}

let BannerResourceManagerTest_createDarkResIcon = () => {
  let bannerResourceManager: BannerResourceManager = new BannerResourceManager(Utils.getInstance().getContext());
  let darkResIcon: DarkResIcon = bannerResourceManager.createDarkResIcon(0, '1', undefined, 3, true);
  let darkResMapOld: DarkResIcon[] = [
    {
      resId: 0,
      light: '1',
      size: 3,
      hasDark: true
    }
  ];
  let darkResMapNew: DarkResIcon[] = [darkResIcon];
  expect(darkResMapOld[0].resId).assertEqual(darkResMapNew[0].resId);
  expect(darkResMapOld[0].dark).assertUndefined();
  expect(darkResMapNew[0].dark).assertUndefined();
}