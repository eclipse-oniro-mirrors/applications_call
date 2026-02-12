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

import common from '@ohos.app.ability.common';
import IPresenter from './IPresenter';
import CallRecorderModel from '../../model/CallRecorderModel';
import CallRecorderCloneConstant from '../../constant/CallRecorderCloneConstant';
import LogUtils from '../LogUtils';
import { copyDbDataHelper } from '../CopyDbDataHelper';

const TAG = 'CallRecorderPresenter';

export default class CallRecorderPresenter implements IPresenter {
  private static instance: CallRecorderPresenter;
  private static callRecorderModel: CallRecorderModel;

  public static getInstance(): CallRecorderPresenter {
    if (!CallRecorderPresenter.instance) {
      CallRecorderPresenter.instance = new CallRecorderPresenter();
    }
    return CallRecorderPresenter.instance;
  }

  init(): void {
    CallRecorderPresenter.callRecorderModel = new CallRecorderModel();
  }

  async migrateDbFile(context?: common.Context) {
    if (context == undefined) {
      return;
    }
    if (AppStorage.has('MigrateType')) {
      let migrateType: string | undefined = AppStorage.get('MigrateType');
      if (migrateType == CallRecorderCloneConstant.UPGRADE_VERSION_NAME) {
        await CallRecorderPresenter.callRecorderModel.startMigrateHMOS2NEXT(context);
      } else if (migrateType == CallRecorderCloneConstant.CLONE_VERSION_NAME) {
        await CallRecorderPresenter.callRecorderModel.startCloneHm2Next(context);
      } else {
        await CallRecorderPresenter.callRecorderModel.startMigrateNext2Next(context);
      }
    }
  }

  async copyFiles(clonePath: string, applicationContextPath: string, context: common.Context, backupDir: string) {
    await copyDbDataHelper.initDirs(context);
    let migType: string = AppStorage.get<string>('MigrateType') ?? '';
    LogUtils.i(TAG, 'migrate copyFiles start migType:' + migType);
    if (migType == CallRecorderCloneConstant.UPGRADE_VERSION_NAME) {
      await copyDbDataHelper.copyAudioFiles(`${backupDir}${CallRecorderCloneConstant.HMOS2NEXT_UPGRADE_AUDIO_PATH}`);
    } else if (migType == CallRecorderCloneConstant.CLONE_VERSION_NAME) {
      LogUtils.i(TAG, `CLONE_VERSION_NAME copy audio file in db copy flow`);
    } else {
      await copyDbDataHelper.copyAudioFiles(`${backupDir}${CallRecorderCloneConstant.NEXT2NEXT_CLONE_AUDIO_PATH}`);
      await copyDbDataHelper.copyAudioFiles(`${backupDir}${CallRecorderCloneConstant.NEXT2NEXT_CLONE_AUDIO_PATH2}`);
      await copyDbDataHelper.copyAudioFiles(`${backupDir}${CallRecorderCloneConstant.NEXT2NEXT_CLONE_AUDIO_PATH3}`);
    }
    return await copyDbDataHelper.copyDbListFileForClone(`${backupDir}${clonePath}`, applicationContextPath + '/rdb');
  }

  async copyGroupAudioFileBeforeBackup(context: common.Context) {
    await copyDbDataHelper.delOldAndCopyNewAudioFiles(context);
  }
}
