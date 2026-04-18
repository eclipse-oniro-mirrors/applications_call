/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { ThreadWorkerGlobalScope } from '@ohos.worker';
import { RunInWorkerMethod } from '../constants/CommonConstants';
import SettingsDataModel, { settingsDataParam } from '../model/SettingsDataModel';
import { LogUtil } from '../util/LogUtil';
import WorkerTask from './WorkerTask';

import { WorkerType } from './WorkFactory';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import WorkerWrapper from './WorkerWrapper';

const TAG = 'DataWorkerWrapper'

export default class DataWorkerWrapper extends WorkerWrapper {
  private static sInstance: DataWorkerWrapper | null = null;

  private constructor() {
    super()
  }

  static getInstance() {
    if (DataWorkerWrapper.sInstance == null || DataWorkerWrapper.sInstance.mWorker == null) {
      LogUtil.info(TAG, 'make DataWorkerWrapper.');
      DataWorkerWrapper.sInstance = new DataWorkerWrapper();
    }
    return DataWorkerWrapper.sInstance;
  }

  getWorkerType(): WorkerType {
    return WorkerType.DataWorker;
  }
}

export class DataWorkerTask extends WorkerTask {
  private static sInstance: DataWorkerTask | null = null;
  private mSettingsDataModel: SettingsDataModel = new SettingsDataModel();

  private constructor(workerPort: ThreadWorkerGlobalScope) {
    super(workerPort);
  }

  static getInstance(workerPort: ThreadWorkerGlobalScope) {
    if (DataWorkerTask.sInstance == null || DataWorkerTask.sInstance.workerPort == null) {
      DataWorkerTask.sInstance = new DataWorkerTask(workerPort);
    }
    return DataWorkerTask.sInstance;
  }

  public runInWorker(request: string, callBack: Function, param?: Record<string, Object>) {
    switch (request) {
      case RunInWorkerMethod.insertSettingsInfoByCondition:
        LogUtil.info(TAG, 'worker request received: ' + request);
        this.mSettingsDataModel.insertSettingsInfoByCondition((param as Record<string, ValuesBucket>).valueBucket,
          (res: Object) => {
            LogUtil.info(TAG, `insertSettingsInfoByCondition result: ${JSON.stringify(res).length}`);
            if (callBack) {
              callBack(res);
            }
          }, (param as Record<string, Context>).context);
        break;
      case RunInWorkerMethod.deleteSettingsInfoByCondition:
        LogUtil.info(TAG, 'worker request received: ' + request);
        this.mSettingsDataModel.deleteSettingsInfoByCondition((param as Record<string, settingsDataParam>).actionData,
          (res: Object) => {
            LogUtil.info(TAG, `deleteSettingsInfoByCondition result: ${JSON.stringify(res).length}`);
            if (callBack) {
              callBack(res);
            }
          }, (param as Record<string, Context>).context);
        break;
      case RunInWorkerMethod.updateSettingsInfoByCondition:
        this.mSettingsDataModel.updateSettingsInfoByCondition((param as Record<string, settingsDataParam>).actionData,
          (param as Record<string, ValuesBucket>).valueBucket, (res: Object) => {
            LogUtil.info(TAG, `updateSettingsInfoByCondition result: ${JSON.stringify(res).length}`);
            if (callBack) {
              callBack(res);
            }
          }, (param as Record<string, Context>).context);
        break;
      case RunInWorkerMethod.querySettingsInfoByCondition:
        LogUtil.info(TAG, 'worker request received: ' + request);
        this.mSettingsDataModel.querySettingsInfoByCondition((param as Record<string, settingsDataParam>).actionData,
          (res: Object) => {
            LogUtil.info(TAG, `querySettingsInfoByCondition result: ${JSON.stringify(res).length}`);
            if (callBack) {
              callBack(res);
            }
          }, (param as Record<string, Context>).context);
        break;
      default:
        this.runInWorkerMore(request, callBack, param);
        break;
    }
  }

  public runInWorkerMore(request: string, callBack: Function, param?: Record<string, settingsDataParam>) {
    LogUtil.info(TAG, `runInWorkerMore`);
    switch (request) {
      case RunInWorkerMethod.querySettingsInfoByBeginningCondition:
        LogUtil.info(TAG, 'worker request received: ' + request);
        this.mSettingsDataModel
          .querySettingsInfoByBeginningCondition((param as Record<string, settingsDataParam>).actionData,
            (res: Object) => {
              LogUtil.info(TAG, `querySettingsInfoByBeginningCondition result: ${JSON.stringify(res).length}`);
              if (callBack) {
                callBack(res);
              }
            }, (param as Record<string, Context>).context);
        break;
      case RunInWorkerMethod.querySettingsInfoByEndCondition:
        LogUtil.info(TAG, 'worker request received: ' + request);
        this.mSettingsDataModel
          .querySettingsInfoByEndCondition((param as Record<string, settingsDataParam>).actionData,
            (res: Object) => {
              LogUtil.info(TAG, `querySettingsInfoByEndCondition result: ${JSON.stringify(res).length}`);
              if (callBack) {
                callBack(res);
              }
            }, (param as Record<string, Context>).context);
        break;
      default:
        LogUtil.warn(TAG, `not allow!!!`);
        break;
    }
  }
}