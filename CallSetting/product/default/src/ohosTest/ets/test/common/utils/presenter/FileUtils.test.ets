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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { FileUtils } from '../../../../../../main/ets/common/utils/presenter/FileUtils';
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';

export default function FileUtilsTest() {
  let emptyContext: undefined = undefined;
  let CALL_SETTING_ABILITY_CONTEXT = 'callSettingsAbilityContext';
  let context: common.Context = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(CALL_SETTING_ABILITY_CONTEXT);
  const DIR_NAME_CALLSETTING = 'CallSetting';
  describe('FileUtilsTest', () => {
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
    it('FileUtilsTest_getGroupDirFromPref', 0, () => {
      let r = FileUtils.getGroupDirFromPref(emptyContext);
      expect(r).assertEqual('');
      r = FileUtils.getGroupDirFromPref(context);
    })
    it('FileUtilsTest_setGroupDirToPref', 0, () => {
      let r = FileUtils.setGroupDirToPref('test', emptyContext);
      expect(r == null).assertEqual(true);
      r = FileUtils.setGroupDirToPref('test', context);
      expect(r == null).assertEqual(true);
    })
    it('FileUtilsTest_getCallSettingGroupDir', 0, async () => {
      let r = await FileUtils.getCallSettingGroupDir(emptyContext);
      expect(r).assertEqual('');
      r = await FileUtils.getCallSettingGroupDir(context);
      expect(r).assertEqual('test');
      FileUtils.groupDir !== ''
      r = await FileUtils.getCallSettingGroupDir(context);
      expect(r).assertEqual('test');
    })
    it('FileUtilsTest_mkDirSync', 0, () => {
      let fileDir = context.filesDir;
      let testDir = fileDir + '/test001dir'
      let r = FileUtils.mkDirSync(testDir);
      r = FileUtils.mkDirSync(testDir);
      fs.rmdirSync(testDir);
      expect(r).assertEqual(false);
    })
    it('FileUtilsTest_replaceAudioFileDir', 0, () => {
      let r = FileUtils.replaceAudioFileDir(1, '');
      r = FileUtils.replaceAudioFileDir(1, 'test');
      r = FileUtils.replaceAudioFileDir(2, 'test/test');
      expect(r).assertEqual('testtest/');
    })
    it('FileUtilsTest_modifyDbFileNameForNext2Next', 0, () => {
      let oldDbPath = 'test.db';
      let testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
      expect(testResult === oldDbPath).assertTrue();

      oldDbPath = 'call_setting.db';
      testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
      expect(testResult === 'old_call_setting.db').assertTrue();

      oldDbPath = 'call_setting.db-shm';
      testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
      expect(testResult === 'old_call_setting.db-shm').assertTrue();

      oldDbPath = 'call_setting.db-wal';
      testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
      expect(testResult === 'old_call_setting.db-wal').assertTrue();

      let oldPath0 = 'test.m4a';
      let testResult0 = FileUtils.modifyDbFileNameForNext2Next(oldPath0);
      expect(testResult0 === oldPath0).assertTrue();
    })
    it('FileUtilsTest_findCallSettingInSubDir', 0, () => {
      let filePath = context.filesDir;
      let testPath0 = filePath + '/' + 'test_subdir_0';
      FileUtils.mkDirSync(testPath0);
      FileUtils.findCallSettingInSubDir(testPath0);
      let testPathA = filePath + '/' + DIR_NAME_CALLSETTING;
      FileUtils.mkDirSync(testPathA);
      let testResultA = FileUtils.findCallSettingInSubDir(filePath);
      expect(testResultA === testPathA).assertFalse();
      let testPathB = filePath + '/' + DIR_NAME_CALLSETTING + '/';
      FileUtils.mkDirSync(testPathB);
      FileUtils.findCallSettingInSubDir(testPathB);
      let testPath1 = '';
      let testResult1 = FileUtils.findCallSettingInSubDir(testPath0);
      fs.rmdirSync(testPath0);
      fs.rmdirSync(testPathA);
      expect(testResult1 === testPath1).assertFalse();
    })

  })
}