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
import CallSettingModel from './CallSettingModel';
import { copyDbDataHelper } from './CopyDbDataHelper';
import LogUtils from '../../common/utils/LogUtils';

const TAG = 'CallSettingPresenter';
export default class CallSettingPresenter {
  private static instance: CallSettingPresenter;
  private callSettingModel: CallSettingModel = new CallSettingModel();

  public static getInstance(): CallSettingPresenter {
    if (!CallSettingPresenter.instance) {
      CallSettingPresenter.instance = new CallSettingPresenter();
    }
    return CallSettingPresenter.instance;
  }

  async migrateDbFile(context: common.Context) {
    try {
      await this.callSettingModel.startCloneHm2Next(context);
    } catch (err) {
      LogUtils.e(TAG, `migrateDbFile err:${JSON.stringify(err)}`);
    }
  }

  async copyFiles(clonePath: string, applicationContextPath: string, context: common.Context, backupDir: string) {
    if (context == null || context == undefined) {
      LogUtils.i(TAG, 'current context is null or undefined');
      return false;
    }
    await copyDbDataHelper.initDirs(context);
    return copyDbDataHelper.copyDbListFileForClone(`${backupDir}${clonePath}`, applicationContextPath + '/rdb');
  }
}
