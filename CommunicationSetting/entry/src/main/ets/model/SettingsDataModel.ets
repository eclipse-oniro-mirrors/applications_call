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
import BaseModel from './BaseModel';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import dataShare from '@ohos.data.dataShare';
import { LogUtil } from '../util/LogUtil';
import DataShareHelper from './DataShareHelper';
import { ResultCode, Uri } from '../constants/CommonConstants';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import dataTable from '../constants/tableData';
import DataShareResultSet from '@ohos.data.DataShareResultSet';


const TAG = 'SettingsDataModel';

export interface settingsDataParam {
  KEYWORD?: string,
  VALUE?: string
}

export default class SettingsDataModel extends BaseModel {
  public async insertSettingsInfoByCondition(valueBucket: ValuesBucket,
    callback: Function | null, context: Context): Promise<void> {
    let dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initSettingDB(context);
    if (!dataHelper) {
      LogUtil.error(TAG, `[insertSettingsInfoByCondition] createDataShareHelper fail`);
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
      return;
    }
    dataHelper = dataHelper as dataShare.DataShareHelper;
    let managerUri = Uri.SETTINGS_DATA_URI + valueBucket.KEYWORD;
    dataHelper.insert(managerUri, valueBucket).then(res => {
      if (callback) {
        callback(this.encapsulateReturnResult(ResultCode.SUCCESS, res));
      }
    }).catch((error: BusinessError) => {
      LogUtil.error(TAG, 'insertSettingsInfoByCondition fail, error: ' + JSON.stringify(error));
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
    });
  }

  public async deleteSettingsInfoByCondition(actionData: settingsDataParam, callback: Function | null,
    context: Context): Promise<void> {
    let dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initSettingDB(context);
    if (!dataHelper) {
      LogUtil.error(TAG, `[deleteSettingsInfoByCondition] createDataShareHelper fail`);
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
      return;
    }
    let condition: dataSharePredicates.DataSharePredicates | undefined =
      this.buildQuerySettingsInfoByCondition(actionData);
    if (!condition && callback) {
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    }
    let managerUri: string = Uri.SETTINGS_DATA_URI + actionData.KEYWORD;
    dataHelper.delete(managerUri, condition).then(res => {
      if (callback) {
        callback(this.encapsulateReturnResult(ResultCode.SUCCESS, res));
      }
    }).catch((error: BusinessError) => {
      LogUtil.error(TAG, 'deleteSettingsInfoByCondition fail, error: ' + JSON.stringify(error));
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
    });
  }

  public async updateSettingsInfoByCondition(actionData: settingsDataParam, valueBucket: ValuesBucket,
    callback: Function | null, context: Context): Promise<void> {
    let dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initSettingDB(context);
    if (!dataHelper) {
      LogUtil.error(TAG, `[updateSettingsInfoByCondition] createDataShareHelper fail`);
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
      return;
    }
    let condition: dataSharePredicates.DataSharePredicates | undefined =
      this.buildQuerySettingsInfoByCondition(actionData);
    if (!condition && callback) {
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    }
    let managerUri = Uri.SETTINGS_DATA_URI + actionData.KEYWORD;
    dataHelper.update(managerUri, condition, valueBucket).then((res: number) => {
      if (callback) {
        callback(this.encapsulateReturnResult(ResultCode.SUCCESS, res));
      }
    }).catch((error: BusinessError) => {
      LogUtil.error(TAG, 'updateSettingsInfoByCondition fail, error: ' + JSON.stringify(error));
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
    });
  }

  public async querySettingsInfoByCondition(actionData: settingsDataParam, callback: Function,
    context: Context): Promise<void> {
    LogUtil.info(TAG, 'querySettingsInfoByCondition');
    let dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initSettingDB(context);
    if (!dataHelper) {
      LogUtil.error(TAG, `[querySettingsInfoByCondition] createDataShareHelper fail`);
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
      return;
    }
    let managerUri: string = Uri.SETTINGS_DATA_URI + actionData.KEYWORD;
    let condition: dataSharePredicates.DataSharePredicates | undefined =
      this.buildQuerySettingsInfoByCondition(actionData);
    if (!condition) {
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    }
    dataHelper.query(managerUri, condition, ['*']).then(resultSet => {
      let resultList: settingsDataParam[] = [];
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          resultList.push(this.buildSettingsDataInfoResult(resultSet));
        }
      }
      callback(this.encapsulateReturnResult(ResultCode.SUCCESS, resultList));
      resultSet.close();
    }).catch((error: BusinessError) => {
      LogUtil.error(TAG, 'querySettingsInfoByCondition fail, error: ' + JSON.stringify(error));
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    });
  }

  public async querySettingsInfoByBeginningCondition(actionData: settingsDataParam, callback: Function,
    context: Context): Promise<void> {
    LogUtil.info(TAG, 'querySettingsInfoByBeginningCondition');
    let dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initSettingDB(context);
    if (!dataHelper) {
      LogUtil.error(TAG, `[querySettingsInfoByBeginningCondition] createDataShareHelper fail`);
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
      return;
    }
    let managerUri: string = Uri.SETTINGS_DATA_URI + actionData.KEYWORD;
    let condition: dataSharePredicates.DataSharePredicates | undefined =
      this.buildQuerySettingsInfoByBeginningCondition(actionData);
    if (!condition) {
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    }
    dataHelper.query(managerUri, condition, ['*']).then(resultSet => {
      let resultList: settingsDataParam[] = [];
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          resultList.push(this.buildSettingsDataInfoResult(resultSet));
        }
      }
      callback(this.encapsulateReturnResult(ResultCode.SUCCESS, resultList));
      resultSet.close();
    }).catch((error: BusinessError) => {
      LogUtil.error(TAG, 'querySettingsInfoByBeginningCondition fail, error: ' + JSON.stringify(error));
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    });
  }

  public async querySettingsInfoByEndCondition(actionData: settingsDataParam, callback: Function,
    context: Context): Promise<void> {
    LogUtil.info(TAG, 'querySettingsInfoByEndCondition');
    let dataHelper: dataShare.DataShareHelper | undefined = await DataShareHelper.getInstance().initSettingDB(context);
    if (!dataHelper) {
      LogUtil.error(TAG, `[querySettingsInfoByEndCondition] createDataShareHelper fail`);
      if (callback) {
        callback(this.encapsulateReturnCode(ResultCode.FAILURE));
      }
      return;
    }
    let managerUri: string = Uri.SETTINGS_DATA_URI + actionData.KEYWORD;
    let condition: dataSharePredicates.DataSharePredicates | undefined =
      this.buildQuerySettingsInfoByEndCondition(actionData);
    if (!condition) {
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    }
    dataHelper.query(managerUri, condition, ['*']).then(resultSet => {
      let resultList: settingsDataParam[] = [];
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          resultList.push(this.buildSettingsDataInfoResult(resultSet));
        }
      }
      callback(this.encapsulateReturnResult(ResultCode.SUCCESS, resultList));
      resultSet.close();
    }).catch((error: BusinessError) => {
      LogUtil.error(TAG, 'querySettingsInfoByEndCondition fail, error: ' + JSON.stringify(error));
      callback(this.encapsulateReturnCode(ResultCode.FAILURE));
    });
  }

  private buildQuerySettingsInfoByEndCondition(actionData: settingsDataParam):
    dataSharePredicates.DataSharePredicates | undefined {
    let condition: dataSharePredicates.DataSharePredicates | undefined = new dataSharePredicates.DataSharePredicates();
    if (actionData.KEYWORD != null) {
      condition.and().endsWith(dataTable.settingsData.KEYWORD, actionData.KEYWORD);
    } else {
      LogUtil.error(TAG, 'buildQuerySettingsInfoByEndCondition no keyword');
      condition = undefined;
    }
    return condition;
  }

  private buildQuerySettingsInfoByBeginningCondition(actionData: settingsDataParam):
  dataSharePredicates.DataSharePredicates | undefined {
    let condition: dataSharePredicates.DataSharePredicates | undefined = new dataSharePredicates.DataSharePredicates();
    if (actionData.KEYWORD != null) {
      condition.and().beginsWith(dataTable.settingsData.KEYWORD, actionData.KEYWORD);
    } else {
      LogUtil.error(TAG, 'buildQuerySettingsInfoByBeginningCondition no keyword');
      condition = undefined;
    }
    return condition;
  }

  private buildQuerySettingsInfoByCondition(actionData: settingsDataParam):
  dataSharePredicates.DataSharePredicates | undefined {
    let condition: dataSharePredicates.DataSharePredicates | undefined = new dataSharePredicates.DataSharePredicates();
    if (actionData.KEYWORD != null) {
      condition.equalTo(dataTable.settingsData.KEYWORD, actionData.KEYWORD);
    } else {
      LogUtil.error(TAG, 'buildQuerySettingsInfoByCondition no keyword');
      condition = undefined;
    }
    return condition;
  }

  private buildSettingsDataInfoResult(resultSet: DataShareResultSet): settingsDataParam {
    let result: settingsDataParam = {};
    result.KEYWORD = resultSet.getString(resultSet.getColumnIndex(dataTable.settingsData.KEYWORD));
    result.VALUE = resultSet.getString(resultSet.getColumnIndex(dataTable.settingsData.VALUE));
    return result;
  }
}

