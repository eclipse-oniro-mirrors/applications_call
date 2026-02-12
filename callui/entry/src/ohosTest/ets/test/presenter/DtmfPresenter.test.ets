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
import { describe, it, expect } from '@ohos/hypium'
import {
  postDialProceed,
  registerPostDialDelayCallback, unRegisterPostDialDelay } from '../../../../main/ets/presenter/DtmfPresenter'

export default function DtmfPresenterTest() {
  describe('DtmfPresenterTest', () => {
    it('unRegisterPostDialDelayTest_01', 0, () => {
      let result = unRegisterPostDialDelay();
      expect(result == null).assertTrue();
    })
    it('registerPostDialDelayCallback', 0, () => {
      let Test = (res: string | null) => {
      }
      registerPostDialDelayCallback(Test);
      let result = registerPostDialDelayCallback(Test);
      expect(result == null).assertTrue();
    })
    it('unRegisterPostDialDelayTest_02', 0, () => {
      let result = unRegisterPostDialDelay();
      expect(result == null).assertTrue();
    })
    it('postDialProceedTest_02', 0, () => {
      let result = postDialProceed(0, true);
      expect(result == null).assertTrue();
    })
  })
}