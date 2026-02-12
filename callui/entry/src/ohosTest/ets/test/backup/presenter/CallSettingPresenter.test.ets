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
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from "@ohos/hypium";
import CallSettingModel from "../../../../../main/ets/backup/presenter/CallSettingModel";
import CallSettingPresenter from "../../../../../main/ets/backup/presenter/CallSettingPresenter";
import LogUtils from "../../../../../main/ets/common/utils/LogUtils";
import BackupExtension from "../../../../../main/ets/backup/BackupExtension";
import { copyDbDataHelper } from "../../../../../main/ets/backup/presenter/CopyDbDataHelper";
import { common } from "@kit.AbilityKit";

export default function CallSettingPresenterTest() {
  describe('migrateDbFile_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('migrateDbFile_test', 0, async () => {
      let callsettingpresenter: CallSettingPresenter = CallSettingPresenter.getInstance();
      let mocker: MockKit = new MockKit();
      let callSettingModel: CallSettingModel = new CallSettingModel();
      let mockStartCloneHm2Next: Function = mocker.mockFunc(callSettingModel, callSettingModel.startCloneHm2Next);
      when(mockStartCloneHm2Next)(ArgumentMatchers.any).afterReturn(Promise.resolve());
      let backupSrv = new BackupExtension();
      let result = await callsettingpresenter.migrateDbFile(backupSrv.context);
      expect(result == null).assertTrue();
      mocker.ignoreMock(callSettingModel, callSettingModel.startCloneHm2Next);
    });

    it('should_return_true_when_context_is_not_null_or_undefined_and_copy_succeeds', 0, async () => {
      let callsettingpresenter: CallSettingPresenter = new CallSettingPresenter();
      let mocker: MockKit = new MockKit();
      let backupSrv = new BackupExtension();
      let mockfuncLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      let mockfuncCopyDbDataHelperInitDirs: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.initDirs);
      let mockfuncCopyDbDataHelperCopyDbListFileForClone: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.copyDbListFileForClone);

      when(mockfuncLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();
      when(mockfuncCopyDbDataHelperInitDirs)(ArgumentMatchers.any).afterReturnNothing();
      when(mockfuncCopyDbDataHelperCopyDbListFileForClone)(ArgumentMatchers.anyBoolean).afterReturn(true);

      const result = await callsettingpresenter.copyFiles('clonePath', 'applicationContextPath', backupSrv.context, 'backupDir');
      expect(result).assertEqual(false);

      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(copyDbDataHelper, copyDbDataHelper.initDirs);
      mocker.ignoreMock(copyDbDataHelper, copyDbDataHelper.copyDbListFileForClone);
    });

    it('should_return_false_when_context_is_not_null_or_undefined_and_copy_fails', 0, async () => {
      let callsettingpresenter: CallSettingPresenter = new CallSettingPresenter();
      let mocker: MockKit = new MockKit();
      let testContext = AppStorage.get<common.Context>('BackupExtensionAbility');
      let mockfuncLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      let mockfuncCopyDbDataHelperInitDirs: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.initDirs);
      let mockfuncCopyDbDataHelperCopyDbListFileForClone: Function = mocker.mockFunc(copyDbDataHelper, copyDbDataHelper.copyDbListFileForClone);
      when(mockfuncLogUtils)(ArgumentMatchers.anyString).afterReturnNothing();
      when(mockfuncCopyDbDataHelperInitDirs)(ArgumentMatchers.any).afterReturnNothing();
      when(mockfuncCopyDbDataHelperCopyDbListFileForClone)(ArgumentMatchers.anyString).afterReturn(false);

      const result = await callsettingpresenter.copyFiles('clonePath', 'applicationContextPath', testContext as common.Context, 'backupDir');
      expect(result).assertEqual(false);

      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(copyDbDataHelper, copyDbDataHelper.initDirs);
      mocker.ignoreMock(copyDbDataHelper, copyDbDataHelper.copyDbListFileForClone);
    });

  });
}