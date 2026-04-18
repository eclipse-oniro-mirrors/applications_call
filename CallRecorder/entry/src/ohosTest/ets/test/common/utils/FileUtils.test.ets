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
} from '@ohos/hypium'
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import LogUtils from '../../../../../main/ets/common/utils/LogUtils';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import { DIR_NAME_CALLRECORD, FileUtils, RECORD_DIR_ON_DUAL } from '../../../../../main/ets/common/utils/FileUtils';
import preferences from '@ohos.data.preferences';
import { abilityDelegatorRegistry } from '@kit.TestKit';

const TAG: string = 'FileUtilsTest';

export default function FileUtilsTest() {
  let context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  describe('FileUtilsTest', () => {
    LogUtils.i(TAG, 'enter FileUtilsTest');
    beforeAll(() => {
      LogUtils.i(TAG, 'enter FileUtilsTest beforeAll');
    });
    afterAll(() => {
      LogUtils.i(TAG, 'afterAll exist FileUtilsTest');
    });
    it('FileUtilTest_getGroupDirFromPref_01', 0, () => {
      getGroupDirFromPref_01(context);
    });
    it('FileUtilTest_setGroupDirToPref_01', 0, () => {
      setGroupDirToPref_01(context);
    });
    it('FileUtilTest_mkDirSync_01', 0, () => {
      mkDirSync_01(context);
    });
    it('FileUtilTest_replaceAudioFileDir_01', 0, () => {
      replaceAudioFileDir_01();
    });
    it('FileUtilTest_modifyDbFileNameForNext2Next_01', 0, () => {
      modifyDbFileNameForNext2Next_01();
    });
    it('FileUtilTest_findCallRecordInSubDir_01', 0, () => {
      findCallRecordInSubDir_01(context);
    });
    it('FileUtilTest_getCallRecordGroupDir_01', 0, async () => {
      await getCallRecordGroupDir_01(context);
    });
    it('FileUtilTest_getCallRecordMigrationDir', 0, () => {
      getCallRecordMigrationDirTest();
    });
    it('FileUtilTest_getDistinctFileNameFromDir', 0, () => {
      getDistinctFileNameFromDirTest();
    });
  })
}

let getCallRecordMigrationDirTest = () => {
  let testResult = FileUtils.getCallRecordMigrationDir();
  expect(testResult != null).assertTrue();
};

let getDistinctFileNameFromDirTest = () => {
  let tmpDir = 'tmp';
  let fileName1 = 'test.m4a';
  let fileName2 = 'test 1.m4a';
  let fileName3 = 'test 2.m4a';
  let files = [fileName1, fileName2, fileName3];
  let mocker: MockKit = new MockKit();
  let mockGetFileListSync: Function = mocker.mockFunc(FileUtils, FileUtils.getFileListSync);
  when(mockGetFileListSync)(ArgumentMatchers.any).afterReturn(files);
  let ret = FileUtils.getDistinctRecordFileNameFromDir(fileName1, tmpDir);
  expect(ret).assertEqual('test 3.m4a');
}

let getCallRecordGroupDir_01 = async (context: common.Context) => {
  LogUtils.i(TAG, 'getCallRecordGroupDir_01 start');
  setGroupDir('test01');
  let testResult = await FileUtils.getCallRecordGroupDir();
  LogUtils.i(TAG, 'getCallRecordGroupDir_01 testResult 01:' + testResult);
  expect(testResult === 'test01').assertTrue();

  setGroupDir('');
  FileUtils.setGroupDirToPref('', context);
  let testResult02 = await FileUtils.getCallRecordGroupDir();
  LogUtils.i(TAG, 'getCallRecordGroupDir_01 testResult 02:' + testResult02);

  setGroupDir('');
  let normalPath = await FileUtils.getCallRecordGroupDir(context);
  LogUtils.i(TAG, 'getCallRecordGroupDir_01 testResult 03 normalPath:' + normalPath);
};

let getGroupDirFromPref_01 = (context: common.Context) => {
  let badContext = abilityDelegatorRegistry.getAbilityDelegator().getAppContext();
  let badResult = FileUtils.getGroupDirFromPref(badContext);
  LogUtils.i(TAG, 'getGroupDirFromPref_01 badResult:' + badResult);

  let validContext = context;
  let validResult = FileUtils.getGroupDirFromPref(validContext);
  LogUtils.i(TAG, 'getGroupDirFromPref_01 validResult:' + validResult);

  let testEmptyContextResult = FileUtils.getGroupDirFromPref();
  LogUtils.i(TAG, 'getGroupDirFromPref_01 testEmptyContextResult:' + testEmptyContextResult);
  expect(testEmptyContextResult === '').assertTrue();
};

let setGroupDirToPref_01 = (context: common.Context) => {
  let mocker: MockKit = new MockKit();
  let func: Function = mocker.mockFunc([], preferences.getPreferencesSync);
  when(func)(ArgumentMatchers.any).afterThrow('error');
  let badContext = context;
  FileUtils.setGroupDirToPref('', badContext);
  LogUtils.i(TAG, 'setGroupDirToPref_01 badResult');
  mocker.clearAll();

  let validContext = context;
  FileUtils.setGroupDirToPref('', validContext);
  LogUtils.i(TAG, 'setGroupDirToPref_01 validResult');

  FileUtils.setGroupDirToPref('');
  LogUtils.i(TAG, 'setGroupDirToPref_01 testEmptyContextResult');
};

let mkDirSync_01 = (context: common.Context) => {
  let validContext = context;
  let fileDir = validContext.filesDir;
  let date = new Date().getTime();
  let testDir = `${fileDir}/test_dir_${date}`;
  let ret = FileUtils.mkDirSync(testDir);
  expect(ret).assertTrue();
};

let replaceAudioFileDir_01 = () => {
  let testOldPath0 = '';
  let testResult0 = FileUtils.replaceAudioFileDir(0, testOldPath0);
  expect(testResult0 === testOldPath0).assertTrue();

  testOldPath0 = 'test_path_01';
  testResult0 = FileUtils.replaceAudioFileDir(0, testOldPath0);
  expect(testResult0 === testOldPath0).assertTrue();

  let testGroupDir = '/data/storage/el2/group/faf4030c-50f6-fb0d-2ef1-000000000000/CallRecord';
  setCallRecordSoundsDir(testGroupDir);
  let testOldPath1 = 'test1.m4a';
  let testResult1 = FileUtils.replaceAudioFileDir(1, `${RECORD_DIR_ON_DUAL}/${testOldPath1}`);
  expect(testResult1 === `${testGroupDir}/${testOldPath1}`).assertTrue();

  let testOldPath2 = '/data/storage/el2/group/faf4030c-50f6-fb0d-2ef1-737d82d979d9/CallRecord/test2.m4a';
  let testResult2 = FileUtils.replaceAudioFileDir(2, testOldPath2);
  expect(testResult2.endsWith('test2.m4a')).assertTrue();
};

let modifyDbFileNameForNext2Next_01 = () => {
  let oldDbPath = 'test.db';
  let testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
  LogUtils.i(TAG, 'modifyDbFileNameForNext2Next_01 test test.db:' + testResult);
  expect(testResult === oldDbPath).assertTrue();

  oldDbPath = 'call_record.db';
  testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
  LogUtils.i(TAG, 'modifyDbFileNameForNext2Next_01 test call_record.db:' + testResult);
  expect(testResult === 'old_call_record.db').assertTrue();

  oldDbPath = 'call_record.db-shm';
  testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
  LogUtils.i(TAG, 'modifyDbFileNameForNext2Next_01 test call_record.db-shm:' + testResult);
  expect(testResult === 'old_call_record.db-shm').assertTrue();

  oldDbPath = 'call_record.db-wal';
  testResult = FileUtils.modifyDbFileNameForNext2Next(oldDbPath);
  LogUtils.i(TAG, 'modifyDbFileNameForNext2Next_01 test call_record.db-wal:' + testResult);
  expect(testResult === 'old_call_record.db-wal').assertTrue();

  let oldPath0 = 'test.m4a';
  let testResult0 = FileUtils.modifyDbFileNameForNext2Next(oldPath0);
  LogUtils.i(TAG, 'modifyDbFileNameForNext2Next_01 testResult0:' + testResult0);
  expect(testResult0 === oldPath0).assertTrue();
};

let findCallRecordInSubDir_01 = (context: common.Context) => {
  let filePath = context.filesDir;
  let testPath0 = filePath + '/' + 'test_subdir_0';
  FileUtils.mkDirSync(testPath0);
  let testResult0 = FileUtils.findCallRecordInSubDir(testPath0);
  LogUtils.i(TAG, 'findCallRecordInSubDir_01 testResult0:' + testResult0);

  let testPathA = filePath + '/' + DIR_NAME_CALLRECORD;
  FileUtils.mkDirSync(testPathA);
  let testResultA = FileUtils.findCallRecordInSubDir(filePath);
  LogUtils.i(TAG, 'findCallRecordInSubDir_01 testResultA:' + testResultA);
  expect(testResultA === testPathA).assertFalse();

  let testPathB = filePath + '/' + DIR_NAME_CALLRECORD + '/';
  FileUtils.mkDirSync(testPathB);
  let testResultB = FileUtils.findCallRecordInSubDir(testPathB);
  LogUtils.i(TAG, 'findCallRecordInSubDir_01 testResultB:' + testResultB);

  let testPath1 = '';
  let testResult1 = FileUtils.findCallRecordInSubDir(testPath0);
  LogUtils.i(TAG, 'findCallRecordInSubDir_01 testResult1:' + testResult1);
  expect(testResult1 === testPath1).assertFalse();
};

let setGroupDir = (dir: string) => {
  FileUtils.groupDir = dir;
}

let setCallRecordSoundsDir = (dir: string) => {
  FileUtils.callRecordSoundsDir = dir;
}
