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
import SettingsDataModel, { settingsDataParam } from '../model/SettingsDataModel';
import { LogUtil } from '../util/LogUtil';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { ResultCode, RunInWorkerMethod } from '../constants/CommonConstants';
import { GlobalContext } from '../entryability/CommunicationSettingAbility';
import WorkerWrapper from '../workers/WorkerWrapper';

export interface resType {
  code: number,
  abilityResult: settingsDataParam[],
}

interface ParamType {
  valueBucket: ValuesBucket,
  context: Context
  actionData: settingsDataParam
}

const TAG: string = 'SettingsDataService';

export default class SettingsDataService {
  private static instance: SettingsDataService;
  private mSettingsDataModel: SettingsDataModel = new SettingsDataModel();

  public static getInstance(): SettingsDataService {
    if (SettingsDataService.instance == null) {
      SettingsDataService.instance = new SettingsDataService();
    }
    return SettingsDataService.instance;
  }

  public insertSettingsInfo(valueBucket: ValuesBucket, callback: Function, context: Context): void {
    if (GlobalContext.getContext().getObject('DataWorker') != null) {
      LogUtil.warn(TAG, `insertSettingsInfo`);
      (GlobalContext.getContext().getObject('DataWorker') as WorkerWrapper)
        .sendRequest(RunInWorkerMethod.insertSettingsInfoByCondition, {
          valueBucket: valueBucket,
          context: context
        } as ParamType, (res?: Object) => {
          if (callback) {
            callback(res);
          }
        });
    } else {
      this.mSettingsDataModel.insertSettingsInfoByCondition(valueBucket, callback as Function, context);
    }
  }

  public deleteSettingsInfo(actionData: settingsDataParam, callback: Function | null, context: Context): void {
    if (GlobalContext.getContext().getObject('DataWorker') != null) {
      (GlobalContext.getContext().getObject('DataWorker') as WorkerWrapper)
        .sendRequest(RunInWorkerMethod.deleteSettingsInfoByCondition, {
          actionData: actionData,
          context: context
        } as ParamType, (res?: Object) => {
          if (callback) {
            callback(res);
          }
        });
    } else {
      this.mSettingsDataModel.deleteSettingsInfoByCondition(actionData, callback, context);
    }
  }

  /**
   * 需根据具体KEYWORD更新数据
   */
  public updateSettingsInfo(actionData: settingsDataParam, valueBucket: ValuesBucket,
    callback: Function, context: Context): void {
    if (GlobalContext.getContext().getObject('DataWorker') != null) {
      (GlobalContext.getContext().getObject('DataWorker') as WorkerWrapper)
        .sendRequest(RunInWorkerMethod.updateSettingsInfoByCondition, {
          actionData: actionData,
          valueBucket: valueBucket,
          context: context
        } as ParamType, (res?: Object) => {
          if (callback) {
            callback(res);
          }
        });
    } else {
      this.mSettingsDataModel.updateSettingsInfoByCondition(actionData, valueBucket, callback as Function, context);
    }
  }

  /**
   * 查询固定SIM卡对应信息
   */
  public querySettingsInfo(actionData: settingsDataParam, callback: Function, context: Context): void {
    if (GlobalContext.getContext().getObject('DataWorker') != null) {
      (GlobalContext.getContext().getObject('DataWorker') as WorkerWrapper)
        .sendRequest(RunInWorkerMethod.querySettingsInfoByCondition, {
          actionData: actionData,
          context: context
        } as ParamType, (res?: Object) => {
          callback(res);
        });
    } else {
      this.mSettingsDataModel.querySettingsInfoByCondition(actionData, callback as Function, context);
    }
  }

  /**
   * 模糊查询特定KeyWord对应所有SIM卡信息
   */
  public querySettingsInfoByBeginningCondition(actionData: settingsDataParam, callback: Function,
    context: Context): void {
    if (GlobalContext.getContext().getObject('DataWorker') != null) {
      (GlobalContext.getContext().getObject('DataWorker') as WorkerWrapper)
        .sendRequest(RunInWorkerMethod.querySettingsInfoByBeginningCondition, {
          actionData: actionData,
          context: context
        } as ParamType, (res?: Object) => {
          callback(res);
        });
    } else {
      this.mSettingsDataModel.querySettingsInfoByBeginningCondition(actionData, callback as Function, context);
    }
  }

  /**
   * 模糊查询特定SIM卡对应所有信息
   */
  public querySettingsInfoByEndCondition(actionData: settingsDataParam, callback: Function, context: Context): void {
    if (GlobalContext.getContext().getObject('DataWorker') != null) {
      (GlobalContext.getContext().getObject('DataWorker') as WorkerWrapper)
        .sendRequest(RunInWorkerMethod.querySettingsInfoByEndCondition, {
          actionData: actionData,
          context: context
        } as ParamType, (res?: Object) => {
          callback(res);
        });
    } else {
      this.mSettingsDataModel.querySettingsInfoByEndCondition(actionData, callback as Function, context);
    }
  }

  /**
   * 按照具体信息查询，存在则更新，不存在则新增
   */
  public insertOrUpdate(actionData: settingsDataParam, valueBucket: ValuesBucket, callback: Function,
    context: Context): void {
    this.querySettingsInfo(actionData, (res: resType) => {
      if (res?.code !== ResultCode.SUCCESS) {
        LogUtil.warn(TAG, 'insertOrUpdate, query database Error');
        return;
      }
      if (res?.abilityResult?.length !== 0) {
        this.updateSettingsInfo(actionData, valueBucket, callback, context);
      } else {
        this.insertSettingsInfo(valueBucket, callback, context);
      }
    }, context);
  }
}