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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit, when,
  ArgumentMatchers } from '@ohos/hypium';
import LogUtils from '../../../../main/ets/common/utils/LogUtils';
import common from '@ohos.app.ability.common';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import * as Constants from '../../../../main/ets/common/utils/Constants';
import BackupExtension from '../../../../main/ets/backup/BackupExtension';
import { BackupExtensionContext, BundleVersion } from '@kit.CoreFileKit';
import { copyDataHelper } from '../../../../main/ets/backup/CopyDataHelper';
import fs, { WriteOptions } from '@ohos.file.fs';
import RejectMsgModel from '../../../../main/ets/backup/model/RejectMsgModel';
import ServiceExtensionContext from '@ohos.app.ability.common';
import CallSettingPresenter from '../../../../main/ets/backup/presenter/CallSettingPresenter';

const TAG = 'BackupExtensionTest';

export default function BackupExtensionTest() {
  let testContext = AppStorage.get<common.UIAbilityContext>('testAbility');
  describe('BackupExtensionTest', () => {
    beforeAll(() => {
      LogUtils.d(TAG, 'enter BackupExtensionTest');
    })
    it('BackupExtensionTest_02', 0, () => {
      BackupExtensionTest_02(testContext);
    })
    it('BackupExtensionTest_01', 0, async () => {
      await BackupExtensionTest_01();
    })
    it('BackupExtensionTest_03', 0, async () => {
      await BackupExtensionTest_03();
    })
    it('BackupExtensionTest_04', 0, async () => {
      await BackupExtensionTest_04();
    })
    it('BackupExtensionTest_05', 0, async () => {
      await BackupExtensionTest_05();
    })
    it('BackupExtensionTest_06', 0, async () => {
      await BackupExtensionTest_06();
    })
    it('BackupExtensionTest_07', 0, async () => {
      await BackupExtensionTest_07();
    })
  })
}

async function BackupExtensionTest_04() {
  let testContext = AppStorage.get<common.Context>('BackupExtensionAbility') as BackupExtensionContext;
  LogUtils.i(TAG, 'test 01 start');
  let backupSrv = new BackupExtension();
  backupSrv.context = testContext;
  await backupSrv.onBackup();
  let backupDir = '';
  try {
    backupDir = backupSrv.getBackupDir();
    LogUtils.i(TAG, 'test onRestore get backupDir:' + backupDir);
  } catch (err) {
    LogUtils.e(TAG, 'test onRestore getBackupDir err:' + JSON.stringify(err));
  }

  LogUtils.i(TAG, 'test 01 mock start');
  let mocker: MockKit = new MockKit();
  let callSettingPresenter = CallSettingPresenter.getInstance();
  let callSettingFun: Function = mocker.mockFunc(callSettingPresenter, callSettingPresenter.copyFiles);
  when(callSettingFun)(ArgumentMatchers.anyBoolean).afterReturn(true);

  let versionInfo: BundleVersion = {
    code: 100,
    name: '99.99.99.999'
  }
  await backupSrv.onRestore(versionInfo);

  mocker.clearAll();
  LogUtils.i(TAG, 'test 01 mock cleared');
  expect(backupDir === '').assertFalse();
}

async function BackupExtensionTest_05() {
  LogUtils.i(TAG, 'test 01 start');
  let backupSrv = new BackupExtension();
  await backupSrv.onBackup();
  let backupDir = '';
  try {
    backupDir = backupSrv.getBackupDir();
    LogUtils.i(TAG, 'test onRestore get backupDir:' + backupDir);
  } catch (err) {
    LogUtils.e(TAG, 'test onRestore getBackupDir err:' + JSON.stringify(err));
  }
  let versionInfo: BundleVersion = {
    code: 100,
    name: '99.99.99.999'
  }
  await backupSrv.onRestore(versionInfo);
  LogUtils.i(TAG, 'test 01 mock cleared');
  expect(backupDir === '').assertTrue();
}

async function BackupExtensionTest_06() {
  LogUtils.i(TAG, 'test 01 start');
  let backupSrv = new BackupExtension();
  await backupSrv.onBackup();
  let backupDir = '';
  try {
    backupDir = backupSrv.getBackupDir();
    LogUtils.i(TAG, 'test onRestore get backupDir:' + backupDir);
  } catch (err) {
    LogUtils.e(TAG, 'test onRestore getBackupDir err:' + JSON.stringify(err));
  }
  let versionInfo: BundleVersion = {
    code: 100,
    name: '99.99.99.999'
  }
  await backupSrv.onRestoreEx(versionInfo, '');
  LogUtils.i(TAG, 'test 01 mock cleared');
  expect(backupDir === '').assertTrue();
}

async function BackupExtensionTest_07() {
  LogUtils.i(TAG, 'test 07 start');
  let backupSrv = new BackupExtension();
  await backupSrv.onBackup();
  let backupDir = '';
  try {
    backupDir = backupSrv.getBackupDir();
    LogUtils.i(TAG, 'test onRestore get backupDir:' + backupDir);
  } catch (err) {
    LogUtils.e(TAG, 'test onRestore getBackupDir err:' + JSON.stringify(err));
  }
  let result = await backupSrv.makeResultInfo('');
  LogUtils.i(TAG, 'test 07 mock cleared');
  expect(result.startsWith('{')).assertTrue();
}

async function BackupExtensionTest_01() {
  LogUtils.i(TAG, 'test 01 start');
  let backupSrv = new BackupExtension();
  await backupSrv.onBackup();

  let backupDir = '';
  try {
    backupDir = backupSrv.getBackupDir();
    LogUtils.i(TAG, 'test onRestore get backupDir:' + backupDir);
  } catch (err) {
    LogUtils.e(TAG, 'test onRestore getBackupDir err:' + JSON.stringify(err));
  }

  LogUtils.i(TAG, 'test 01 mock start');
  let mocker: MockKit = new MockKit();
  let mockGetBackupDirResult: Function = mocker.mockFunc(backupSrv, backupSrv.getBackupDir);
  when(mockGetBackupDirResult)(ArgumentMatchers.any).afterReturn('BackupTest_001_testBackupDir');
  let mockCopyListFileResult: Function = mocker.mockFunc(copyDataHelper, copyDataHelper.copyListFile);
  when(mockCopyListFileResult)(ArgumentMatchers.matchRegexs(new RegExp(/^BackupTest_001_/))).afterReturn(true);

  let versionInfo: BundleVersion = {
    code: 100,
    name: '0.0.0.0'
  }
  await backupSrv.onRestore(versionInfo);

  when(mockCopyListFileResult)(ArgumentMatchers.matchRegexs(new RegExp(/^BackupTest_001_/))).afterReturn(false);
  await backupSrv.onRestore(versionInfo);

  let testContext = AppStorage.get<common.Context>('BackupExtensionAbility') as BackupExtensionContext;
  let versionInfo2: BundleVersion = {
    code: 100,
    name: '1.0.0.0'
  }
  backupSrv.context = testContext;
  await backupSrv.onRestore(versionInfo2);
  mocker.clearAll();
  LogUtils.i(TAG, 'test 01 mock cleared');
  expect(backupDir === '').assertTrue();
  LogUtils.i(TAG, 'test 01 end');
}

function BackupExtensionTest_02(context?: common.UIAbilityContext) {
  if (!context) {
    return;
  }
  LogUtils.i(TAG, 'test 02 start');
  let fileDir = context.filesDir;
  let dbDir = context.databaseDir;
  let longPath = createExtraLongFilePath(fileDir, dbDir);

  copyDataHelper.copyListFile('', '');
  copyDataHelper.copyListFile(fileDir, '');
  copyDataHelper.copyListFile(fileDir, dbDir);
  copyDataHelper.copyListFile(longPath, dbDir);

  copyDataHelper.copyFiles('', '');
  let testFilesUnderFileDir = fileDir + '/test_02_dir';
  let testFileDirUnderFileDir = fileDir + '/test_02_dir/test_02_sub_dir';
  let testFileUnderTestFileDir = 'test_02_test_xml.xml';
  mkDir(testFilesUnderFileDir);
  mkDir(testFileDirUnderFileDir);
  mkFile(testFilesUnderFileDir, testFileUnderTestFileDir);
  let copyResult = copyDataHelper.copyFiles(testFilesUnderFileDir, dbDir);
  expect(copyResult).assertTrue();

  copyDataHelper.getSrcDirListFile(fileDir);
  copyDataHelper.getSrcDirListFile(longPath);
  let test01 = copyDataHelper.getSrcDirListFile('/x/no_exist');
  expect(test01.length >= 0).assertTrue();
  LogUtils.i(TAG, 'test 02 end');
}

function mkFile(dir: string, fileName: string) {
  try {
    let filePath = dir + '/' + fileName;
    fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
  } catch (err) {
    LogUtils.e(TAG, 'mkDir file on:' + dir + ' err:' + JSON.stringify(err));
  }
}

function mkDir(dir: string) {
  try {
    fs.mkdirSync(dir);
  } catch (err) {
    LogUtils.e(TAG, 'mkDir on:' + dir + ' err:' + JSON.stringify(err));
  }
}

function createExtraLongFilePath(oriPath1: string, oriPath2: string): string {
  let count = 100;
  let longPath = '';
  do {
    longPath = longPath + oriPath1 + oriPath2;
    count--;
  } while (count >= 0);
  LogUtils.i(TAG, 'createExtraLongFilePath len:' + longPath.length);
  return longPath;
}

async function BackupExtensionTest_03() {
  LogUtils.i(TAG, 'BackupExtensionTest_03 start');
  let testModel = new RejectMsgModel();
  let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
    .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
  try {
    LogUtils.i(TAG, 'Test_03 setXml start');
    setXml(serviceContext.preferencesDir);
    LogUtils.i(TAG, 'Test_03 setXml end');

    await testModel.migratePrefFile(serviceContext);
    expect(serviceContext !== undefined).assertTrue();
  } catch (err) {
    LogUtils.e(TAG, 'mkDir file err:' + JSON.stringify(err));
  }
}

function setXml(dir: string) {
  let fileName = 'respond_via_sms_prefszh_CN_#Hans.xml';
  let testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map>'
    + '<string name="canned_response_pref_2">抱歉，现在不方便接电话。02</string>'
    + '<string name="canned_response_pref_1">稍后给您回电话。01</string>'
    + '</map>';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefszh_CN_#Hant.xml';
  testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map>'
    + '<string name="canned_response_pref_1">稍後回電給您。ceshi 02</string>'
    + '</map>';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefszh_HK_#Hant.xml';
  testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map>'
    + '<string name="canned_response_pref_1">稍後給您回電。鈿留乂05</string>'
    + '</map>';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefsen_GB.xml';
  testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map>'
    + '<string name="canned_response_pref_1">I\'ll call you back. test 07</string>'
    + '</map>';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefsen_VB.xml';
  testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map>'
    + '<string name="canned_response_pref_1"></string>'
    + '</map>';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefsen_US.xml';
  testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map>'
    + '<string name="canned_response_pref_9"></string></map>';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefskk.xml';
  testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map>'
    + '<string name="canned_response_pref_1"></string></map>';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefsinvalid.xml';
  testStr = 'xxx';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefsbo_GB.xml';
  testStr = 'xxx';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_respond_via_sms.xml';
  testStr = 'xxx';
  writeFile(dir + '/' + fileName, testStr);
  fileName = 'respond_via_sms_prefsbo_US.xml';
  testStr = '<?xml version=\'1.0\' encoding=\'utf-8\' standalone=\'yes\' ?><map><string></string></map>';
  writeFile(dir + '/' + fileName, testStr);
}

function writeFile(filePath: string, fileContent: string) {
  try {
    let len = fileContent.length;
    LogUtils.i(TAG, 'Test_03 writeFile file:' + filePath + ', length:' + len + ' content:' + fileContent);
    let stream = fs.createStreamSync(filePath, 'w+');
    let writeOption: WriteOptions = {
      length: len,
      encoding: 'utf-8'
    };
    stream.writeSync(fileContent, writeOption);
    stream.flushSync();
    stream.closeSync();
    LogUtils.i(TAG, 'Test_03 writeFile file:' + filePath + ' success!');
  } catch (err) {
    LogUtils.e(TAG, 'writeFile file:' + filePath + ' err:' + JSON.stringify(err));
  }
}
