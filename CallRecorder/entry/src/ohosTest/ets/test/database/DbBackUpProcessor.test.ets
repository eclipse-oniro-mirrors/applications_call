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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '../../../../../oh_modules/@ohos/hypium'
import { FileUtils } from '../../../../main/ets/common/utils/FileUtils';
import DbBackUpProcessor from '../../../../main/ets/database/DbBackUpProcessor'
import { common } from '@kit.AbilityKit';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import { Constant } from '../../../../main/ets/common/constant/Constant';

export default function DbBackUpProcessorTest() {
  let DbBackUpProcessorTest_startBackUp_01 = async (context: Context) => {
    let mocker: MockKit = new MockKit();
    let mockfunc = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
    when(mockfunc)(ArgumentMatchers.any).afterReturn(false);
    let result = await DbBackUpProcessor.getInstance().startBackUp(context);
    expect(result).assertEqual('dest dir not exist');
    mocker.ignoreMock(FileUtils, FileUtils.isFileExist);
    mocker.clearAll();
  }
  let DbBackUpProcessorTest_startBackUp_02 = async (context: Context) => {
    let testContext =
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    let NEXT2HMOS = 'next2hmos';
    let destDbDir = testContext.filesDir + '/' + NEXT2HMOS;
    let mocker: MockKit = new MockKit();
    let mockfunc = mocker.mockFunc(FileUtils, FileUtils.isFileExist);
    when(mockfunc)(destDbDir).afterReturn(true);
    let result = await DbBackUpProcessor.getInstance().startBackUp(context);
    expect(result).assertEqual('dest dir not exist');
    mocker.ignoreMock(FileUtils, FileUtils.isFileExist);
    mocker.clearAll();
  }
  let DbBackUpProcessorTest_startBackUp_03 = async (context: Context) => {
    let result = await DbBackUpProcessor.getInstance().startBackUp(context);
    expect(result).assertEqual('');
  }

  describe('DbBackUpProcessorTest', () => {
    let testContext1: common.Context;
    let testContext =
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
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
    it('DbBackUpProcessorTest_startBackUp_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await DbBackUpProcessorTest_startBackUp_01(testContext);
    })
    it('DbBackUpProcessorTest_startBackUp_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await DbBackUpProcessorTest_startBackUp_02(testContext);
    })
    it('DbBackUpProcessorTest_startBackUp_03', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await DbBackUpProcessorTest_startBackUp_03(testContext);
    })
    it('DbBackUpProcessorTest_startBackUp_04', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let result = await DbBackUpProcessor.getInstance().startBackUp(testContext1);
      expect(result).assertEqual('invalid context');
    })
  })
}