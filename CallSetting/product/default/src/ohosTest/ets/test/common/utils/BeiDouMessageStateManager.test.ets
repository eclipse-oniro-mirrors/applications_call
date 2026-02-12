/**
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

import { describe, it } from '@ohos/hypium';
import {
  addBeiDouMessageSateListener,
  insertBeiDouMessage,
  queryBeiDouMessageState,
  removeBeiDouMessageSateListener
} from '../../../../../main/ets/common/utils/BeiDouMessageStateManager';
import { CallSettingGlobalContextHelper } from '@ohos/common';
import { common } from '@kit.AbilityKit';
import { CALL_SETTING_ABILITY_CONTEXT } from '../../../../../main/ets/common/constant/CallSettingsConstant';
import { sleep } from './Sleep';

export default function BeiDouMessageStateManagerTest() {
  describe('BeiDouMessageStateManagerTest', () => {
    let callContext =
      CallSettingGlobalContextHelper.getContext().getValue<common.UIAbilityContext>(CALL_SETTING_ABILITY_CONTEXT)
    it('BeiDouMessageStateManagerTest_notHelper', 0, async (done: Function) => {
      removeBeiDouMessageSateListener();
      queryBeiDouMessageState(callContext, 'is_smc_enabled', (data: number) => {
      });
      insertBeiDouMessage('is_smc_enabled', '1', callContext);
      await sleep(1000);
      done();
    });

    it('BeiDouMessageStateManagerTest_addBeiDouMessageSateListener', 0, async (done: Function) => {
      addBeiDouMessageSateListener(callContext, (data: number) => {
      });
      insertBeiDouMessage('is_smc_enabled', '1', callContext);
      await sleep(1000);
      queryBeiDouMessageState(callContext, 'is_smc_enabled', (data: number) => {
      });
      removeBeiDouMessageSateListener();
      done();
    });
  });
}