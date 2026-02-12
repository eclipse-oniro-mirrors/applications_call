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
import { afterEach, beforeEach, describe, expect, it } from '@ohos/hypium';
import { Utils } from '../../../../main/ets/util/Utils';

export default function ViewUtilsTest() {
  describe('ViewUtilsTest', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('GetNormalStyleBgColor', 0, () => {
      let result = Utils.getNormalStyleBgColor(true);
      let resultId = (result.valueOf() as Resource).id;
      expect(resultId).assertEqual($r('sys.color.ohos_id_color_hover').id);
      result = Utils.getNormalStyleBgColor(false);
      expect(result).assertEqual('#00000000');
    });

    it('CheckAppIndexExists', 0, () => {
      let result = Utils.checkAppIndexExists(0);
      expect(result).assertEqual(false);
      result = Utils.checkAppIndexExists(1);
      expect(result).assertEqual(true);
    });
  });
}