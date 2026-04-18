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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { FileUtils } from '../../../../../main/ets/common/utils/FileUtils'
import { common } from '@kit.AbilityKit'
import Utils from '../../../../../main/ets/common/utils/utils'
import { fileIo as fs } from '@kit.CoreFileKit';

export default function FileUtilsTest() {
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
      let emptyContext: common.Context | undefined = undefined;
      let result = FileUtils.getGroupDirFromPref(emptyContext);
      expect(result).assertEqual('');
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      result = FileUtils.getGroupDirFromPref(textContext);
      if (result == '') {
        expect(result).assertEqual('');
      } else {
        expect(result).assertEqual('test');
      }
    })
    it('FileUtilsTest_getCallSettingGroupDir_01', 0, async () => {
      FileUtils.groupDir = '';
      let emptyContext: common.Context | undefined = undefined;
      let result = await FileUtils.getCallSettingGroupDir(emptyContext);
      expect(result).assertEqual('')
    })
    it('FileUtilsTest_getCallSettingGroupDir_02', 0, async () => {
      FileUtils.groupDir = 'test';
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let result = await FileUtils.getCallSettingGroupDir(textContext);
      expect(result).assertEqual('test')
    })
    it('FileUtilsTest_getCallSettingGroupDir_03', 0, async () => {
      FileUtils.groupDir = 'test';
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let result = await FileUtils.getCallSettingGroupDir(textContext);
      expect(result).assertEqual('test')
    })
    it('FileUtilsTest_getCallSettingGroupDir_04', 0, async () => {
      FileUtils.groupDir = '';
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      FileUtils.setGroupDirToPref('test', textContext);
      let result = await FileUtils.getCallSettingGroupDir(textContext);
      expect(result).assertEqual('test')
    })
    it('FileUtilsTest_getCallSettingGroupDir_05', 0, async () => {
      FileUtils.groupDir = 'test';
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      FileUtils.setGroupDirToPref('', textContext);
      let result = await FileUtils.getCallSettingGroupDir(textContext);
      expect(result).assertEqual('test')
    })
    it('FileUtilsTest_setGroupDirToPref', 0, () => {
      let emptyContext: common.Context | undefined = undefined;
      let result = FileUtils.setGroupDirToPref('test', emptyContext);
      expect(result == null).assertTrue();
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      result = FileUtils.setGroupDirToPref('test', textContext);
      expect(result == null).assertTrue();
    })
    it('FileUtilsTest_mkDirSync_01', 0, () => {
      let result = FileUtils.mkDirSync('/test');
      expect(result).assertFalse();
    })
    it('FileUtilsTest_mkDirSync_02', 0, () => {
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let pathDir = textContext.filesDir;
      let dirPath = pathDir + "/test";
      let result = FileUtils.mkDirSync(dirPath)
      fs.rmdirSync(dirPath)
      expect(result).assertTrue();
    })
    it('FileUtilsTest_replaceAudioFileDir_01', 0, () => {
      let result = FileUtils.replaceAudioFileDir(1, '');
      expect(result).assertEqual('');
    })
    it('FileUtilsTest_replaceAudioFileDir_02', 0, () => {
      let result = FileUtils.replaceAudioFileDir(1, '/test');
      expect(result).assertEqual('/test');
    })
    it('FileUtilsTest_replaceAudioFileDir_03', 0, () => {
      let result = FileUtils.replaceAudioFileDir(2, '/test');
      expect(result).assertEqual('test/test');
    })
    it('FileUtilsTest_replaceAudioFileDir_04', 0, () => {
      let result = FileUtils.replaceAudioFileDir(3, '');
      expect(result).assertEqual('');
    })
    it('FileUtilsTest_modifyDbFileNameForNext2Next_01', 0, () => {
      let result = FileUtils.modifyDbFileNameForNext2Next('test_call_manager.db');
      expect(result).assertEqual('test_old_call_manager.db');
    })
    it('FileUtilsTest_modifyDbFileNameForNext2Next_02', 0, () => {
      let result = FileUtils.modifyDbFileNameForNext2Next('test_call_manager.dbd');
      expect(result).assertEqual('test_call_manager.dbd');
    })
    it('FileUtilsTest_findCallSettingInSubDir_01', 0, () => {
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let pathDir = textContext.filesDir;
      let dirPath = pathDir + "/testDir";
      fs.mkdirSync(dirPath);
      let result = FileUtils.findCallSettingInSubDir(dirPath);
      fs.rmdirSync(dirPath);
      expect(result).assertEqual('/data/storage/el2/base/haps/callui_test/files/testDir');
    })
    it('FileUtilsTest_findCallSettingInSubDir_02', 0, () => {
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let pathDir = textContext.filesDir;
      let dirPath = pathDir + "/CallSetting";
      let dirPath1 = dirPath + "/test";
      fs.mkdirSync(dirPath);
      fs.mkdirSync(dirPath1);
      let result = FileUtils.findCallSettingInSubDir(dirPath);
      fs.rmdirSync(dirPath);
      expect(result).assertEqual('/data/storage/el2/base/haps/callui_test/files/CallSetting');
    })
    it('FileUtilsTest_findCallSettingInSubDir_03', 0, () => {
      let result = FileUtils.findCallSettingInSubDir('');
      expect(result).assertEqual('');
    })
    it('FileUtilsTest_getSandboxAppPath', 0, () => {
      let result = FileUtils.getSandboxAppPath();
      expect(result).assertEqual('/data/themes/b/app/');
    })
    it('FileUtilsTest_getFileName', 0, () => {
      let result = FileUtils.getFileName('data/storage.text');
      expect(result).assertEqual('storage.text');
      let result2 = FileUtils.getFileName('storage');
      expect(result2).assertEqual('');
    })
    it('FileUtilsTest_getFileNameNoSuffix', 0, () => {
      let result = FileUtils.getFileNameNoSuffix('storage.text');
      expect(result).assertEqual('storage');
      let result2 = FileUtils.getFileNameNoSuffix('storage');
      expect(result2).assertEqual('');
    })
    it('FileUtilsTest_getNoFileNamePath', 0, () => {
      let result = FileUtils.getNoFileNamePath('data/storage.text');
      expect(result).assertEqual('data/');
      let result2 = FileUtils.getNoFileNamePath('storage');
      expect(result2).assertEqual('');
    })
  })
}