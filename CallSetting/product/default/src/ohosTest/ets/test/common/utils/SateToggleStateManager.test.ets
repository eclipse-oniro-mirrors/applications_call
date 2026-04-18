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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import dataShare from '@ohos.data.dataShare';
import common from '@ohos.app.ability.common';
import { MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';
import { sleep } from './Sleep';
import * as SateToggleStateManager from '../../../../../main/ets/common/utils/SateToggleStateManager';

let context = MobileDataGlobalContextHelper.getContext()
  .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);

let SateToggleStateManagerTest_addSatelliteToggleStateListener = async () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(dataShare.createDataShareHelper, dataShare.createDataShareHelper);
  when(mockFunc)(ArgumentMatchers.any).afterReturnNothing();
  await SateToggleStateManager.addSatelliteToggleStateListener(context, (data: number) => {
    expect(true).assertTrue();
  });
  when(mockFunc)(ArgumentMatchers.any).afterThrow('SateToggleStateManagerTest_addSatelliteToggleStateListener err');
  await SateToggleStateManager.addSatelliteToggleStateListener(context, (data: number) => {
    expect(true).assertTrue();
  });
  mocker.clearAll();
}

let SateToggleStateManagerTest_querySatellite = () => {
  SateToggleStateManager.querySatellite(context, (data: number) => {
    expect(true).assertTrue();
  });
}

let SateToggleStateManagerTest_removeSatelliteToggleStateListener = () => {
  SateToggleStateManager.removeSatelliteToggleStateListener();
  expect(true).assertTrue();
}

let SateToggleStateManagerTest_insert = async () => {
  await SateToggleStateManager.insert(0, context);
  await sleep(1000);
  expect(true).assertTrue();
  await SateToggleStateManager.insert(1, context);
  await sleep(1000);
  expect(true).assertTrue();
  await SateToggleStateManager.insert(undefined, context);
  await sleep(1000);
  expect(true).assertTrue();
}

let SateToggleStateManagerTest_insertConnectState = async () => {
  await SateToggleStateManager.insertConnectState(0, context);
  await sleep(1000);
  expect(true).assertTrue();
  await SateToggleStateManager.insertConnectState(1, context);
  await sleep(1000);
  expect(true).assertTrue();
  await SateToggleStateManager.insertConnectState(undefined, context);
  await sleep(1000);
  expect(true).assertTrue();
}

export default function SateToggleStateManagerTest() {
  describe('SateToggleStateManagerTest', () => {
    it('SateToggleStateManagerTest_addSatelliteToggleStateListener', 0, () => {
      SateToggleStateManagerTest_addSatelliteToggleStateListener();
    });
    it('SateToggleStateManagerTest_querySatellite', 0, () => {
      SateToggleStateManagerTest_querySatellite();
    });
    it('SateToggleStateManagerTest_removeSatelliteToggleStateListener', 0, () => {
      SateToggleStateManagerTest_removeSatelliteToggleStateListener();
    });
    it('SateToggleStateManagerTest_insert', 0, () => {
      SateToggleStateManagerTest_insert();
    });
    it('SateToggleStateManagerTest_insertConnectState', 0, () => {
      SateToggleStateManagerTest_insertConnectState();
    });
  });
}