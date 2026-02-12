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
import { CallSettingGlobalContextHelper } from '@ohos/common';
import { describe, it, expect } from '@ohos/hypium'
import {
  addRegisterDistributedStateListener,
  queryDistributedState,
  removeRegisterDistributedStateListener } from '../../../../../main/ets/common/utils/DistributeUtils';
import { common } from '@kit.AbilityKit';
import { CALL_SETTING_ABILITY_CONTEXT } from '../../../../../main/ets/common/constant/CallSettingsConstant';
import { sleep } from './Sleep';

export default function DistributeUtilsTest() {
  describe('DistributeUtilsTest', () => {
    it('DistributeUtilsTest_01', 0, async (done: Function) => {
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CALL_SETTING_ABILITY_CONTEXT);
      removeRegisterDistributedStateListener();
      queryDistributedState(context, (data: string) => {
      });
      await sleep(1000);
      addRegisterDistributedStateListener(context, (data: string) => {
      });
      await sleep(1000);
      removeRegisterDistributedStateListener();
      queryDistributedState(context, (data: string) => {
      });
      done();
    })
  })
}