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
import common from '@ohos.app.ability.common';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import { sleep } from './Sleep';

let GlobalContextHelperTest_all = () => {
  let obj: Object = new Object();
  GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  expect(true).assertEqual(true);
  sleep(1000);
  GlobalContextHelper.getContext().set('test', obj);
  expect(true).assertEqual(true);
  sleep(1000);
}

export default function GlobalContextHelperTest() {
  describe('GlobalContextHelperTest', () => {
    it('GlobalContextHelperTest_all', 0, () => {
      GlobalContextHelperTest_all();
    });
  })
}