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
import { beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import { LogUtil } from '../../../../main/ets/util/LogUtil';
import MyAbilityStage from '../../../../main/ets/application/MyAbilityStage';

const TAG: string = 'MyAbilityStage';

export default function MyAbilityStageTest() {
  describe('MyAbilityStageTest', () => {
    let abilityStage: MyAbilityStage;
    beforeEach(() => {
      abilityStage = new MyAbilityStage();
    })
    it('testOnCreateLogsOnCreation', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.info);
      abilityStage.onCreate();
      mocker.verify('info', [TAG, 'onCreate']).once();
      mocker.clear(LogUtil);
    })
    it('testOnDestroyLogsOnDestruction', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.info);
      abilityStage.onDestroy();
      mocker.verify('info', [TAG, 'onDestroy']).once();
      mocker.clear(LogUtil);
    })
  })
}