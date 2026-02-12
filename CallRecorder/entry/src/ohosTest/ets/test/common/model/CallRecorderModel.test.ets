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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import CallRecorderCloneConstant from '../../../../../main/ets/common/constant/CallRecorderCloneConstant';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import CallRecorderModel from '../../../../../main/ets/common/model/CallRecorderModel';
import { callRecorderDbHelper } from '../../../../../main/ets/common/utils/database/CallRecorderDbHelper';
import { ValuesBucket } from '@ohos.data.ValuesBucket';

let CallRecorderModelTest_startMigrateCallRecord = () => {
  AppStorage.setOrCreate('MigrateType', CallRecorderCloneConstant.CLONE_VERSION_NAME);
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let callRecorderModel = new CallRecorderModel();
  callRecorderModel.startMigrateCallRecord(context);
  expect(0).assertEqual(0);
}

let CallRecorderModelTest_startMigrateCallRecord_02 = () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let callRecorderModel = new CallRecorderModel();
  let mocker: MockKit = new MockKit();
  let mockFunc_01: Function = mocker.mockFunc(AppStorage, AppStorage.has);
  let mockFunc_02: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc_01)(ArgumentMatchers.any).afterReturn(true);
  when(mockFunc_02)('MigrateType').afterReturn(CallRecorderCloneConstant.UPGRADE_VERSION_NAME);
  callRecorderModel.startMigrateCallRecord(context);
  expect(!context.resourceManager).assertFalse();
  mocker.clearAll();
}

let CallRecorderModelTest_startMigrateCallRecord_03 = () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let callRecorderModel = new CallRecorderModel();
  let mocker: MockKit = new MockKit();
  let mockFunc_01: Function = mocker.mockFunc(AppStorage, AppStorage.has);
  when(mockFunc_01)(ArgumentMatchers.any).afterReturn(false);
  callRecorderModel.startMigrateCallRecord(context);
  expect(context.resourceManager === undefined).assertFalse();
  mocker.clearAll();
}

let CallRecorderModelTest_startMigrateNext2Next = () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let callRecorderModel = new CallRecorderModel();
  callRecorderModel.startMigrateNext2Next(context);
  expect(0).assertEqual(0);
}

let CallRecorderModelTest_startMigrateRecordContact = () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let callRecorderModel = new CallRecorderModel();
  callRecorderModel.startMigrateRecordContact(context);
  expect(0).assertEqual(0);
}
let CallRecorderModelTest_startMigrateRecordConfig = () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let callRecorderModel = new CallRecorderModel();
  callRecorderModel.startMigrateRecordConfig(context);
  expect(0).assertEqual(0);
}

let CallRecorderModelTest_startMigrateRecordConfig_02 = async () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  await callRecorderDbHelper.queryRecordConfig(context);
  let callRecorderModel = new CallRecorderModel();
  let mocker: MockKit = new MockKit();
  let mockFunc_01: Function = mocker.mockFunc(callRecorderDbHelper, callRecorderDbHelper.queryRecordConfig);
  when(mockFunc_01)(ArgumentMatchers.any).afterReturn(undefined);
  callRecorderModel.startMigrateRecordConfig(context);
  expect(!context.resourceManager).assertFalse();
  mocker.clearAll();
}

let CallRecorderModelTest_startMigrateRecordConfigForUp = async () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>('test');
  await callRecorderDbHelper.queryRecordConfig(context);
  let callRecorderModel = new CallRecorderModel();
  callRecorderModel.startMigrateRecordConfigForUp(context);
  expect(!context.resourceManager).assertFalse();
}

let CallRecorderModelTest_startMigrateHMOS2NEXT = () => {
  let context: Context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let callRecorderModel = new CallRecorderModel();
  callRecorderModel.startMigrateHMOS2NEXT(context);
  expect(0).assertEqual(0);
}

export default function CallRecorderModelTest() {
  describe('CallRecorderModelTest', () => {
    it('CallRecorderModelTest_startMigrateCallRecord', 0, () => {
      CallRecorderModelTest_startMigrateCallRecord();
    });
    it('CallRecorderModelTest_startMigrateCallRecord_02', 0, () => {
      CallRecorderModelTest_startMigrateCallRecord_02();
    });
    it('CallRecorderModelTest_startMigrateCallRecord_03', 0, () => {
      CallRecorderModelTest_startMigrateCallRecord_03();
    });
    it('CallRecorderModelTest_startMigrateNext2Next', 0, () => {
      CallRecorderModelTest_startMigrateNext2Next();
    });
    it('CallRecorderModelTest_startMigrateRecordContact', 0, () => {
      CallRecorderModelTest_startMigrateRecordContact();
    });
    it('CallRecorderModelTest_startMigrateRecordConfig', 0, () => {
      CallRecorderModelTest_startMigrateRecordConfig();
    });
    it('CallRecorderModelTest_startMigrateRecordConfig_02', 0, () => {
      CallRecorderModelTest_startMigrateRecordConfig_02();
    });
    it('CallRecorderModelTest_startMigrateHMOS2NEXT', 0, () => {
      CallRecorderModelTest_startMigrateHMOS2NEXT();
    });
    it('CallRecorderModelTest_startMigrateRecordConfigForUp', 0, () => {
      CallRecorderModelTest_startMigrateRecordConfigForUp();
    });
  })
}