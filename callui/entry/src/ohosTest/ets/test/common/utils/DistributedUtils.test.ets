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

import { describe, it, expect, beforeAll, beforeEach, afterEach, afterAll } from '@ohos/hypium';
import { settings } from '@kit.BasicServicesKit';
import {
  CALL_ABILITY_CONTEXT,
  CALL_SERVICE_CONTEXT,
  DISTRIBUTED_CALL_SMS_SHARING_SINK,
  DISTRIBUTE_CALL_SOURCE_SMS,
  DISTRIBUTE_MODEM_DEVICE_NAME,
  DISTRIBUTE_MODEM_STATE,
  DISTRIBUTE_SINK_CALL,
  DISTRIBUTE_SOURCE_CALL } from '../../../../../main/ets/common/utils/Constants';
import {
  addRegisterDistributedChange,
  checkDistributedDevice,
  checkDistributedSinkSmsState, checkDistributedState,
  registerDistributeSmsObserver,
  unRegisterDistributedChange,
  unRegisterDistributeSmsObserver } from '../../../../../main/ets/common/utils/DistributeUtils';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import { common } from '@kit.AbilityKit';

let checkDistributedState_test_01 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  let distributeState = settings.getValueSync(context, DISTRIBUTE_MODEM_STATE, '');
  checkDistributedState();
  let isSourceDistributeCall = AppStorage.get<boolean>('isDistributeSource') ?? false;
  expect(isSourceDistributeCall).assertEqual(distributeState === DISTRIBUTE_SOURCE_CALL);
}

let checkDistributedState_test_02 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  let distributeState = settings.getValueSync(context, DISTRIBUTE_MODEM_STATE, '');
  checkDistributedState();
  let isSinkDistributeCall = AppStorage.get<boolean>('isDistributeSink') ?? false;
  expect(isSinkDistributeCall).assertEqual(distributeState === DISTRIBUTE_SINK_CALL);
}

let checkDistributedState_test_03 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  AppStorage.setOrCreate('isDistributeSink', false);
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  checkDistributedState();
  let isSinkDistributeCall = AppStorage.get<boolean>('isDistributeSink') ?? false;
  expect(isSinkDistributeCall).assertEqual(false);
  if (!context) {
    return;
  }
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

let checkDistributedState_test_04 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  AppStorage.setOrCreate('isDistributeSink', false);
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  checkDistributedState();
  let isSourceDistributeCall = AppStorage.get<boolean>('isDistributeSource') ?? false;
  expect(isSourceDistributeCall).assertEqual(false);
  if (!context) {
    return;
  }
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

let checkDistributedSinkSmsState_test_01 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  let distributeSourceSms = Number(settings.getValueSync(context, DISTRIBUTE_CALL_SOURCE_SMS, '0'));
  let distributeSinkSms = Number(settings.getValueSync(context, DISTRIBUTED_CALL_SMS_SHARING_SINK, '0'));
  checkDistributedSinkSmsState();
  let isDistributeSmsEnable = AppStorage.get<boolean>('distributeSmsEnable') ?? false;
  expect(isDistributeSmsEnable).assertEqual(distributeSourceSms === 1 && distributeSinkSms === 1);
}

let checkDistributedSinkSmsState_test_02 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  AppStorage.setOrCreate('distributeSmsEnable', false);
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  checkDistributedSinkSmsState();
  let isDistributeSmsEnable = AppStorage.get<boolean>('distributeSmsEnable') ?? false;
  expect(isDistributeSmsEnable).assertEqual(false);
  if (!context) {
    return;
  }
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

let checkDistributedDevice_test_01 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!context) {
    return;
  }
  let distributeDeviceName = settings.getValueSync(context, DISTRIBUTE_MODEM_DEVICE_NAME, '');
  GlobalContextHelper.getContext().set(CALL_ABILITY_CONTEXT, context);
  checkDistributedDevice();
  let deviceName: string = AppStorage.get<string>('distributeDeviceName') as string;
  expect(distributeDeviceName).assertEqual(deviceName);
}

let checkDistributedDevice_test_02 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  AppStorage.setOrCreate('distributeDeviceName', '');
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  checkDistributedDevice();
  let deviceName: string = AppStorage.get<string>('distributeDeviceName') as string;
  expect(deviceName).assertEqual('');
  if (!context) {
    return;
  }
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

let unRegisterDistributeSmsObserver_test_01 = () => {
  let result = unRegisterDistributeSmsObserver();
  expect(result == undefined).assertTrue();
}

let unRegisterDistributeSmsObserver_test_02 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  let result = unRegisterDistributeSmsObserver();
  expect(result == undefined).assertTrue();
  if (!context) {
    return;
  }
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

let registerDistributeSmsObserver_test_01 = () => {
  let result = registerDistributeSmsObserver();
  expect(result == undefined).assertTrue();
}

let registerDistributeSmsObserver_test_02 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  let result = registerDistributeSmsObserver();
  expect(result == undefined).assertTrue();
  if (!context) {
    return;
  }
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

let addRegisterDistributedChange_test_01 = () => {
  let result = addRegisterDistributedChange();
  expect(result == undefined).assertTrue();
}

let addRegisterDistributedChange_test_02 = () => {
  let context = GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  let result = addRegisterDistributedChange();
  expect(result == undefined).assertTrue();
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

let unRegisterDistributedChange_test_01 = () => {
  let result = unRegisterDistributedChange();
  expect(result == undefined).assertTrue();
}

let unRegisterDistributedChange_test_02 = () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  GlobalContextHelper.getContext().remove(CALL_ABILITY_CONTEXT);
  GlobalContextHelper.getContext().remove(CALL_SERVICE_CONTEXT);
  let result = unRegisterDistributedChange();
  expect(result == undefined).assertTrue();
  if (!context) {
    return;
  }
  GlobalContextHelper.getContext().set<common.UIAbilityContext>(CALL_ABILITY_CONTEXT, context);
  GlobalContextHelper.getContext().set(CALL_SERVICE_CONTEXT, context);
}

export default function DistributedUtilsTest() {
  describe('DistributedUtilsTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('checkDistributedState_test_01', 0, () => {
      checkDistributedState_test_01();
    })
    it('checkDistributedState_test_02', 0, () => {
      checkDistributedState_test_02();
    })
    it('checkDistributedState_test_03', 0, () => {
      checkDistributedState_test_03();
    })
    it('checkDistributedState_test_04', 0, () => {
      checkDistributedState_test_04();
    })
    it('checkDistributedSinkSmsState_test_01', 0, () => {
      checkDistributedSinkSmsState_test_01();
    })
    it('checkDistributedSinkSmsState_test_02', 0, () => {
      checkDistributedSinkSmsState_test_02();
    })
    it('checkDistributedDevice_test_01', 0, () => {
      checkDistributedDevice_test_01();
    })
    it('checkDistributedDevice_test_02', 0, () => {
      checkDistributedDevice_test_02();
    })
    it('unRegisterDistributeSmsObserver_test_01', 0, () => {
      unRegisterDistributeSmsObserver_test_01();
    })
    it('unRegisterDistributeSmsObserver_test_02', 0, () => {
      unRegisterDistributeSmsObserver_test_02();
    })
    it('registerDistributeSmsObserver_test_01', 0, () => {
      registerDistributeSmsObserver_test_01();
    })
    it('registerDistributeSmsObserver_test_02', 0, () => {
      registerDistributeSmsObserver_test_02();
    })
    it('addRegisterDistributedChange_test_01', 0, () => {
      addRegisterDistributedChange_test_01();
    })
    it('addRegisterDistributedChange_test_02', 0, () => {
      addRegisterDistributedChange_test_02();
    })
    it('unRegisterDistributedChange_test_01', 0, () => {
      unRegisterDistributedChange_test_01();
    })
    it('unRegisterDistributedChange_test_02', 0, () => {
      unRegisterDistributedChange_test_02();
    })
  })
}