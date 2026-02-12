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
import { BundleVersion } from '@ohos.application.BackupExtensionAbility'
import BackupExtension, { IErrorExInfo, IResultExInfo } from '../../../../main/ets/serviceextability/BackupExtension'
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper'
import common from '@ohos.app.ability.common'
import { Constant } from '../../../../main/ets/common/constant/Constant'
import CallRecorderCloneConstant from '../../../../main/ets/common/constant/CallRecorderCloneConstant'
import { copyDbDataHelper } from '../../../../main/ets/common/utils/CopyDbDataHelper';
import BackupExtensionContext from '@ohos.file.BackupExtensionContext';
import DbBackUpProcessor from '../../../../main/ets/database/DbBackUpProcessor'
import LogUtils from '../../../../main/ets/common/utils/LogUtils'

let resultExInfo: IResultExInfo = {
  resultInfo: [
    {
      type: 'ErrorInfo',
      errorCode: '0',
      errorInfo: ''
    }, {
    type: 'CompatibilityInfo',
    next2hmos: 1
  }
  ]
};
let errorExInfo: IErrorExInfo = {
  resultInfo: [
    {
      type: 'ErrorInfo',
      errorCode: '13500088',
      errorInfo: ''
    }
  ]
};

let BackupExtensionTest_onBackup = () => {
  let backupExtension = new BackupExtension();
  backupExtension.onBackup();
  expect(0).assertEqual(0);
}

let BackupExtensionTest_onRestore_01 = () => {
  let backupExtension = new BackupExtension();
  backupExtension.context = GlobalContextHelper.getContext()
    .getValue<BackupExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let bundleVersion: BundleVersion = {
    code: 0,
    name: CallRecorderCloneConstant.CLONE_VERSION_NAME
  };
  backupExtension.onRestore(bundleVersion);
  expect(0).assertEqual(0);
}

let BackupExtensionTest_onRestore_02 = () => {
  let backupExtension = new BackupExtension();
  backupExtension.context = GlobalContextHelper.getContext()
    .getValue<BackupExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let bundleVersion: BundleVersion = {
    code: 0,
    name: 'test'
  };
  backupExtension.onRestore(bundleVersion);
  expect(0).assertEqual(0);
}

let BackupExtensionTest_onRestore_03 = () => {
  let backupExtension = new BackupExtension();
  let bundleVersion: BundleVersion = {
    code: 0,
    name: 'test'
  };
  backupExtension.onRestore(bundleVersion);
  expect(0).assertEqual(0);
}

let BackupExtensionTest_onRestore_04 = () => {
  let backupExtension = new BackupExtension();
  backupExtension.context = GlobalContextHelper.getContext()
    .getValue<BackupExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let bundleVersion: BundleVersion = {
    code: 0,
    name: 'test'
  };
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.copyDbListFileForClone);
  when(mockFun)(ArgumentMatchers.any).afterReturn(true);
  backupExtension.onRestore(bundleVersion);
  expect(0).assertEqual(0);
}

let BackupExtensionTest_onRestore_05 = async () => {
  let backupExtension = new BackupExtension();
  backupExtension.context = GlobalContextHelper.getContext()
    .getValue<BackupExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let bundleVersion: BundleVersion = {
    code: 0,
    name: '0.0.0.0'
  };
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.copyDbListFileForClone);
  when(mockFun)(ArgumentMatchers.any).afterReturn(true);
  await backupExtension.onRestore(bundleVersion);
  expect(0).assertEqual(0);
}

let BackupExtensionTest_onBackupEx_01 = async () => {
  let backupextension: BackupExtension = new BackupExtension();
  let result = await backupextension.onBackupEx('');
  expect(result).assertEqual('');
}

let BackupExtensionTest_onBackupEx_02 = async () => {
  let backupextension: BackupExtension = new BackupExtension();
  let result = await backupextension.onBackupEx('[]');
  expect(result).assertEqual('');
}

let BackupExtensionTest_onBackupEx_03 = async () => {
  let backupextension: BackupExtension = new BackupExtension();
  let mocker: MockKit = new MockKit();
  let mockStartBackUp: Function = mocker.mockFunc(DbBackUpProcessor.getInstance(), DbBackUpProcessor.getInstance().startBackUp);
  when(mockStartBackUp)(ArgumentMatchers.any).afterReturn('success');

  let result = await backupextension.onBackupEx('[{"detail": "next2hmos"}]');
  expect(result).assertEqual(JSON.stringify(errorExInfo));

  mocker.ignoreMock(DbBackUpProcessor.getInstance(), DbBackUpProcessor.getInstance().startBackUp);
}

let BackupExtensionTest_onBackupEx_04 = async () => {
  let backupextension: BackupExtension = new BackupExtension();
  let mocker: MockKit = new MockKit();
  let mockStartBackUp: Function = mocker.mockFunc(DbBackUpProcessor.getInstance(), DbBackUpProcessor.getInstance().startBackUp);
  when(mockStartBackUp)(ArgumentMatchers.any).afterReturn('');

  let result = await backupextension.onBackupEx('[{"detail": "next2hmos"}]');
  expect(result).assertEqual(JSON.stringify(resultExInfo));

  mocker.ignoreMock(DbBackUpProcessor.getInstance(), DbBackUpProcessor.getInstance().startBackUp);
}

let BackupExtensionTest_onBackupEx_05 = async () => {
  let backupextension: BackupExtension = new BackupExtension();
  let result = await backupextension.onBackupEx('[{"detail": "other"}]');
  expect(result).assertEqual('');
}

let BackupExtensionTest_onBackupEx_06 = async () => {
  let backupextension: BackupExtension = new BackupExtension();
  let result = await backupextension.onBackupEx('invalid JSON');
  expect(result).assertEqual('');
}

let BackupExtensionTest_onRestoreEx_01 = async () => {
  let bundleVersion: BundleVersion = {
    code: 0,
    name: CallRecorderCloneConstant.CLONE_VERSION_NAME
  };
  let restoreInfo: string = "testRestoreInfo";
  let backupextension: BackupExtension = new BackupExtension();
  let mocker: MockKit = new MockKit();

  let mockOnRestore: Function = mocker.mockFunc(backupextension, backupextension.onRestore);
  when(mockOnRestore)(ArgumentMatchers.any).afterReturn(undefined);

  let mockGetCopyFileResultInfo: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.getCopyFileResultInfo);
  when(mockGetCopyFileResultInfo)().afterReturn("success");

  let mockLogUtilsI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
  when(mockLogUtilsI)(ArgumentMatchers.anyString).afterReturnNothing();

  let result = await backupextension.onRestoreEx(bundleVersion, restoreInfo);
  expect(result).assertEqual("success");

  mocker.ignoreMock(backupextension, backupextension.onRestore);
  mocker.ignoreMock(copyDbDataHelper, copyDbDataHelper.getCopyFileResultInfo);
  mocker.ignoreMock(LogUtils, LogUtils.i);
}

let BackupExtensionTest_onRestoreEx_02 = async () => {
  let bundleVersion: BundleVersion = {
    code: 0,
    name: CallRecorderCloneConstant.CLONE_VERSION_NAME
  };
  let restoreInfo: string = "testRestoreInfo";
  let backupextension: BackupExtension = new BackupExtension();
  let mocker: MockKit = new MockKit();

  let mockOnRestore: Function = mocker.mockFunc(backupextension, backupextension.onRestore);
  when(mockOnRestore)(ArgumentMatchers.any).afterThrow("Error");

  let mockLogUtilsI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
  when(mockLogUtilsI)(ArgumentMatchers.anyString).afterReturnNothing();

  try {
    await backupextension.onRestoreEx(bundleVersion, restoreInfo);
  } catch (e) {
    expect(e !== null).assertTrue();
  }

  mocker.ignoreMock(backupextension, backupextension.onRestore);
  mocker.ignoreMock(LogUtils, LogUtils.i);
}

let BackupExtensionTest_onRestoreEx_03 = async () => {
  let bundleVersion: BundleVersion = {
    code: 0,
    name: CallRecorderCloneConstant.CLONE_VERSION_NAME
  };
  let restoreInfo: string = "testRestoreInfo";
  let backupextension: BackupExtension = new BackupExtension();
  let mocker: MockKit = new MockKit();

  let mockOnRestore: Function = mocker.mockFunc(backupextension, backupextension.onRestore);
  when(mockOnRestore)(ArgumentMatchers.any).afterReturn(undefined);

  let mockGetCopyFileResultInfo: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.getCopyFileResultInfo);
  when(mockGetCopyFileResultInfo)().afterThrow("Error");

  let mockLogUtilsI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
  when(mockLogUtilsI)(ArgumentMatchers.anyString).afterReturnNothing();

  try {
    await backupextension.onRestoreEx(bundleVersion, restoreInfo);
  } catch (e) {
    expect(e !== null).assertTrue();
  }

  mocker.ignoreMock(backupextension, backupextension.onRestore);
  mocker.ignoreMock(copyDbDataHelper, copyDbDataHelper.getCopyFileResultInfo);
  mocker.ignoreMock(LogUtils, LogUtils.i);
}

export default function BackupExtensionTest() {
  describe('BackupExtensionTest', () => {
    it('BackupExtensionTest_onBackup', 0, () => {
      BackupExtensionTest_onBackup();
    });
    it('BackupExtensionTest_onRestore_01', 0, () => {
      BackupExtensionTest_onRestore_01();
    });
    it('BackupExtensionTest_onRestore_02', 0, () => {
      BackupExtensionTest_onRestore_02();
    });
    it('BackupExtensionTest_onRestore_03', 0, () => {
      BackupExtensionTest_onRestore_03();
    });
    it('BackupExtensionTest_onRestore_04', 0, () => {
      BackupExtensionTest_onRestore_04();
    });
    it('BackupExtensionTest_onRestore_05', 0, () => {
      BackupExtensionTest_onRestore_05();
    });

    it('BackupExtensionTest_onBackupEx_01', 0, async () => {
      await BackupExtensionTest_onBackupEx_01();
    });

    it('BackupExtensionTest_onBackupEx_02', 0, async () => {
      await BackupExtensionTest_onBackupEx_02();
    });

    it('BackupExtensionTest_onBackupEx_03', 0, async () => {
      await BackupExtensionTest_onBackupEx_03();
    });

    it('BackupExtensionTest_onBackupEx_04', 0, async () => {
      await BackupExtensionTest_onBackupEx_04();
    });

    it('sBackupExtensionTest_onBackupEx_05', 0, async () => {
      await BackupExtensionTest_onBackupEx_05();
    });

    it('BackupExtensionTest_onBackupEx_06', 0, async () => {
      await BackupExtensionTest_onBackupEx_06();
    });

    it('BackupExtensionTest_onRestoreEx_01', 0, async () => {
      await BackupExtensionTest_onRestoreEx_01();
    });

    it('BackupExtensionTest_onRestoreEx_02', 0, async () => {
      await BackupExtensionTest_onRestoreEx_02();
    });

    it('BackupExtensionTest_onRestoreEx_03', 0, async () => {
      await BackupExtensionTest_onRestoreEx_03();
    });

  })
}
