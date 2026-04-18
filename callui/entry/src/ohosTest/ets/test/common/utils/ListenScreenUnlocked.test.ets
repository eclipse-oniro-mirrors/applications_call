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
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from "@ohos/hypium";
import { ListenScreenUnlocked } from "../../../../../main/ets/common/utils/ListenScreenUnlocked";
import LogUtils from "../../../../../main/ets/common/utils/LogUtils";
import { BusinessError, commonEventManager } from "@kit.BasicServicesKit";

export default function ListenScreenUnlockedTest() {
  describe('addSubscriber_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    let addSubscriber_test_01 = async () => {
      let listenscreenunlocked: ListenScreenUnlocked = ListenScreenUnlocked.getInstance();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturnNothing();
      let result = await listenscreenunlocked.addSubscriber();
      mocker.ignoreMock(LogUtils, LogUtils.i);
      expect(result == null).assertTrue();
    }

    let addSubscriber_test_02 = async () => {
      let listenscreenunlocked: ListenScreenUnlocked = ListenScreenUnlocked.getInstance();
      let mocker: MockKit = new MockKit();
      let mockfuncLogI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      let mockfuncLogE: Function = mocker.mockFunc(LogUtils, LogUtils.e);
      let mockUnsubscribe: Function = mocker.mockFunc(listenscreenunlocked, listenscreenunlocked.unsubscribe);
      when(mockfuncLogI)(ArgumentMatchers.anyString).afterReturnNothing();
      when(mockfuncLogE)(ArgumentMatchers.anyString).afterReturnNothing();
      when(mockUnsubscribe)().afterReturnNothing();
      let result = await listenscreenunlocked.addSubscriber();
      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(LogUtils, LogUtils.e);
      mocker.ignoreMock(listenscreenunlocked, listenscreenunlocked.unsubscribe);
      expect(result == null).assertTrue();
    }

    it('addSubscriber_test', 0, async () => {
      await addSubscriber_test_01();
      await addSubscriber_test_02();
    });
  });
}

