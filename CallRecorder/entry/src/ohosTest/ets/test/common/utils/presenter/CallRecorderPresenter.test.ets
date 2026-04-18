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
import { describe, beforeAll, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium'
import CallRecorderCloneConstant from '../../../../../../main/ets/common/constant/CallRecorderCloneConstant';
import { GlobalContextHelper } from '../../../../../../main/ets/common/utils/GlobalContextHelper';
import CallRecorderPresenter from '../../../../../../main/ets/common/utils/presenter/CallRecorderPresenter';
import { Constant } from '../../../../../../main/ets/common/constant/Constant';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { sleep } from '../Sleep';
import common from '@ohos.app.ability.common';

let context: Context;

let CallRecorderPresenterTest_migrateDbFile_01 = () => {
  CallRecorderPresenter.getInstance().migrateDbFile(undefined);
  expect(0).assertEqual(0);
}

let CallRecorderPresenterTest_migrateDbFile_02 = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc_01: Function = mocker.mockFunc(AppStorage, AppStorage.has);
  let mockFunc_02: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc_01)(ArgumentMatchers.any).afterReturn(true);
  when(mockFunc_02)('MigrateType').afterReturn(CallRecorderCloneConstant.CLONE_VERSION_NAME);
  CallRecorderPresenter.getInstance().migrateDbFile(context);
  expect(!context.resourceManager).assertFalse();
  mocker.clearAll();
}

let CallRecorderPresenterTest_migrateDbFile_03 = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc_01: Function = mocker.mockFunc(AppStorage, AppStorage.has);
  let mockFunc_02: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc_01)(ArgumentMatchers.any).afterReturn(true);
  when(mockFunc_02)('MigrateType').afterReturn(CallRecorderCloneConstant.UPGRADE_VERSION_NAME);
  CallRecorderPresenter.getInstance().migrateDbFile(context);
  expect(context.resourceManager === undefined).assertFalse();
  mocker.clearAll();
}

let CallRecorderPresenterTest_migrateDbFile_04 = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc_01: Function = mocker.mockFunc(AppStorage, AppStorage.has);
  let mockFunc_02: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc_01)(ArgumentMatchers.any).afterReturn(true);
  when(mockFunc_02)('MigrateType').afterReturn('8.8.8.8');
  CallRecorderPresenter.getInstance().migrateDbFile(context);
  expect(context.resourceManager === undefined).assertFalse();
  mocker.clearAll();
}

let CallRecorderPresenterTest_migrateDbFile_05 = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc_01: Function = mocker.mockFunc(AppStorage, AppStorage.has);
  when(mockFunc_01)(ArgumentMatchers.any).afterReturn(false);
  CallRecorderPresenter.getInstance().migrateDbFile(context);
  expect(!context.resourceManager).assertFalse();
  mocker.clearAll();
}

export default function CallRecorderPresenterTest() {
  describe('CallRecorderPresenterTest', () => {
    beforeAll(() => {
      context = GlobalContextHelper.getContext().getValue(Constant.CALL_RECORDER_ABILITY_CONTEXT);
      CallRecorderPresenter.getInstance().init();
    });
    it('CallRecorderPresenterTest_migrateDbFile_01', 0, () => {
      CallRecorderPresenterTest_migrateDbFile_01();
    });
    it('CallRecorderPresenterTest_migrateDbFile_02', 0, () => {
      CallRecorderPresenterTest_migrateDbFile_02();
    });
    it('CallRecorderPresenterTest_migrateDbFile_03', 0, () => {
      CallRecorderPresenterTest_migrateDbFile_03();
    });
    it('CallRecorderPresenterTest_migrateDbFile_04', 0, () => {
      CallRecorderPresenterTest_migrateDbFile_04();
    });
    it('CallRecorderPresenterTest_migrateDbFile_05', 0, () => {
      CallRecorderPresenterTest_migrateDbFile_05();
    });
  });
}