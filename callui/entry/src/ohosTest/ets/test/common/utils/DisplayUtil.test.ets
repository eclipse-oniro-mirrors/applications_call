/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { DisplayUtil } from '../../../../../main/ets/common/utils/DisplayUtil';
import { sleep } from '../../Utils';

let DisplayUtilTest_getScreenFoldStatus01 = async () => {
  let num: number = DisplayUtil.getScreenFoldStatus();
  await sleep(100);
  expect(num === 0).assertTrue();
}

export default function UtilDisplayUtilTest() {
  describe('UtilDisplayUtilTest', () => {
    it('getScreenFoldStatus01', 0, async () => {
      DisplayUtilTest_getScreenFoldStatus01();
    })
  })
}
