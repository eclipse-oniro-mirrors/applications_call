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

import { LogUtils } from '@ohos/common/CommonIndex';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import { ValuesBucket, ValueType } from '@kit.ArkData';

export const SETTING_SATELLITE_SERVICE_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';

export const ON_SETTING_SATELLITE_SERVICE_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key=is_smc_enabled';

export const QUERY_IS_SMC_ENABLED = 'is_smc_enabled';

const TAG = 'BeiDouMessageStateManager';

let dataShareHelper: dataShare.DataShareHelper;

export async function addBeiDouMessageSateListener(context: Context, callback: (data: number) => void) {
  LogUtils.i(TAG, 'addSateListener');
  try {
    dataShare.createDataShareHelper(context,
      SETTING_SATELLITE_SERVICE_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err != undefined) {
          LogUtils.e(TAG, 'addSateListener error: code: ' + err.code + ', message: ' + err.message);
          return;
        }
        dataShareHelper = data;
        try {
          dataShareHelper.on('dataChange', ON_SETTING_SATELLITE_SERVICE_URI, () => {
            LogUtils.i(TAG, 'addSateListener dataChange success');
            queryBeiDouMessageState(context, QUERY_IS_SMC_ENABLED, callback);
          });
        } catch (err) {
          let error = err as BusinessError;
          LogUtils.e(TAG, 'addSateListener error: code: ' + error.code + ', message: ' + error.message);
        }
      });
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'addSateListener createDataShareHelper error: code: ' + error.code + ', message: ' + error.message);
  }
}

export async function removeBeiDouMessageSateListener() {
  LogUtils.i(TAG, 'removeSateListener');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'removeSateListener dataShareHelper null');
    return;
  }
  try {
    dataShareHelper.off('dataChange', ON_SETTING_SATELLITE_SERVICE_URI);
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'removeSateListener error: code: ' + error.code + ', message: ' + error.message);
  }
}

export async function queryBeiDouMessageState(context: Context, keyWord: string, callback: (data: number) => void) {
  LogUtils.i(TAG, 'queryState');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'queryState dataShareHelper null');
    dataShareHelper = await dataShare.createDataShareHelper(context, SETTING_SATELLITE_SERVICE_URI);
  }
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', keyWord);
  try {
    dataShareHelper.query(ON_SETTING_SATELLITE_SERVICE_URI, condition, []).then((data) => {
      LogUtils.i(TAG, 'queryState query succeed');
      if (data.goToFirstRow()) {
        let value = data.getLong(data.getColumnIndex('VALUE'));
        LogUtils.i(TAG, `queryState query succeed return key ${value}`);
        callback(value);
      } else {
        callback(0);
      }
      data.close();
    }).catch((err: BusinessError) => {
      callback(0);
      LogUtils.e(TAG, 'queryState query in error: err:' + JSON.stringify(err));
    });
  } catch (err) {
    let error = err as BusinessError;
    callback(0);
    LogUtils.e(TAG, 'queryState query out error: code:' + error.code + ', message: ' + error.message);
  }
}

export async function insertBeiDouMessage(keyWord: string, value: ValueType, context: Context) {
  if (!dataShareHelper) {
    dataShareHelper = await dataShare.createDataShareHelper(context, SETTING_SATELLITE_SERVICE_URI);
  }
  let columns = ['*'];
  let selectsEq = new dataSharePredicates.DataSharePredicates();
  selectsEq.equalTo('KEYWORD', keyWord);
  const queryData: ValuesBucket = {
    KEYWORD: keyWord,
    VALUE: value,
  }
  try {
    dataShareHelper.query(ON_SETTING_SATELLITE_SERVICE_URI, selectsEq, columns, (err, data) => {
      if (err !== undefined) {
        LogUtils.e(TAG, `dataShareHelper is  error: code: ${err.code}, message: ${err.message} `);
        return;
      }
      if (data.rowCount !== 0) {
        LogUtils.i(TAG, 'query, succeed rowCount : ' + data.rowCount);
        dataShareHelper.update(ON_SETTING_SATELLITE_SERVICE_URI, selectsEq, queryData, (err, data) => {
          if (err !== undefined) {
            LogUtils.e(TAG, `update error: code: ${err.code}, message: ${err.message} `);
          } else {
            LogUtils.i(TAG, 'query update, rowCount : ' + data);
          }
        });
      } else {
        dataShareHelper.insert(ON_SETTING_SATELLITE_SERVICE_URI, queryData).then((data) => {
          LogUtils.i(TAG, 'Insert succeed' + data);
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `Insert is  error: code: ${err.code}, message: ${err.message} `);
        });
      }
      data.close();
    });
  } catch (err) {
    LogUtils.e(TAG, `dataShareHelper is  false: code: ${(err as BusinessError).code}.` +
      `code}, message: ${(err as BusinessError).code}.message} `);
  }
  ;
}
