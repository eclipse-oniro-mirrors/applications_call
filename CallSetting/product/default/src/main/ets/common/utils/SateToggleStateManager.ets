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
import { DataShareResultSet, ValuesBucket } from '@kit.ArkData';
import { SatelliteType, SATELLITE_SWITCH_OFF } from '../constant/SatelliteSearchConst';

export const SETTING_SATELLITE_SERVICE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
export const ON_SETTING_SATELLITE_SERVICE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
export const QUERY_SATELLITE_MODE_KEY = 'satellite_mode_switch';
export const QUERY_SATELLITE_MODE_TIANTONG_KEY = 'satellite_mode_switch_tiantong';
export const QUERY_SATELLITE_MODE_HYACINTH_KEY = 'satellite_mode_switch_hyacinth';
const QUERY_SATELLITE_CONNECTED = 'satellite_connected';

const TAG = 'SateToggleSateManager';

let dataShareHelper: dataShare.DataShareHelper;
let mSatelliteType: SatelliteType = SatelliteType.TIAN_TONG;

export async function addSatelliteToggleStateListener(context: Context, callback: (data: number) => void,
  satelliteType: SatelliteType = SatelliteType.TIAN_TONG) {
  LogUtils.i(TAG, `addSatelliteToggleStateListener ${satelliteType}`);
  try {
    dataShare.createDataShareHelper(context,
      SETTING_SATELLITE_SERVICE_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err != undefined) {
          LogUtils.e(TAG, `addSatelliteToggleStateListener error, code: ${err?.code}, message: ${err?.message}`);
          return;
        }
        dataShareHelper = data;
        mSatelliteType = satelliteType;
        try {
          if (satelliteType === SatelliteType.TIAN_TONG) {
            dataShareHelper.on('dataChange',
              ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_TIANTONG_KEY,
              () => {
                LogUtils.i(TAG, `addSatelliteToggleStateListener dataChange success ${SatelliteType.TIAN_TONG}`);
                querySatellite(context, callback, SatelliteType.TIAN_TONG);
              });
          }
          if (satelliteType === SatelliteType.HYACINTH) {
            dataShareHelper.on('dataChange',
              ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_HYACINTH_KEY,
              () => {
                LogUtils.i(TAG, `addSatelliteToggleStateListener dataChange success ${SatelliteType.HYACINTH}`);
                querySatellite(context, callback, SatelliteType.HYACINTH);
              });
          }
        } catch (err) {
          LogUtils.e(TAG, `addSatelliteToggleStateListener error, code: ${err?.code}, message: ${err?.message}`);
        }
      });
  } catch (err) {
    LogUtils.e(TAG,
      `addSatelliteToggleStateListener createDataShareHelper error, code: ${err?.code}, message: ${err?.message}`);
  }
}

export async function removeSatelliteToggleStateListener() {
  LogUtils.i(TAG, 'removeSatelliteToggleStateListener');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'removeSatelliteToggleStateListener dataShareHelper null');
    return;
  }
  try {
    let uri = ON_SETTING_SATELLITE_SERVICE_URI + '?key=' +
      (mSatelliteType === SatelliteType.HYACINTH ? QUERY_SATELLITE_MODE_HYACINTH_KEY :
        QUERY_SATELLITE_MODE_TIANTONG_KEY);
    dataShareHelper.off('dataChange', uri);
    LogUtils.i(TAG, 'removeSatelliteToggleStateListener done');
  } catch (err) {
    LogUtils.e(TAG, `removeSatelliteToggleStateListener error, code: ${err?.code}, message: ${err?.message}`);
  }
}

export async function querySatelliteWithParam(keyword: string, context: Context) {
  LogUtils.i(TAG, `querySatelliteWithParam ${keyword}`);
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'querySatelliteWithParam dataShareHelper null');
    dataShareHelper = await dataShare.createDataShareHelper(context, SETTING_SATELLITE_SERVICE_URI);
  }
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', keyword);
  let res: number = 0;
  let data: DataShareResultSet | undefined = undefined;
  try {
    data = await dataShareHelper.query(SETTING_SATELLITE_SERVICE_URI, condition, []);
    LogUtils.i(TAG, 'querySatelliteWithParam query succeed');
    if (data.goToFirstRow()) {
      LogUtils.i(TAG, 'querySatelliteWithParam query succeed return key');
      res = data.getLong(data.getColumnIndex('VALUE'));
    }
  } catch (err) {
    LogUtils.e(TAG, `querySatelliteWithParam error, code: ${err?.code}, message: ${err?.message}`);
  } finally {
    if (data !== undefined) {
      data.close();
    }
  }
  LogUtils.i(TAG, `querySatelliteWithParam res: ${res}`);
  return res;
}

export async function querySatellite(context: Context, callback: (data: number) => void,
  satelliteType: SatelliteType = SatelliteType.TIAN_TONG) {
  LogUtils.i(TAG, `querySatellite ${satelliteType}`);
  try {
    let typeValue = await querySatelliteWithParam(getSatelliteModeKey(satelliteType), context);
    callback(typeValue);
  } catch (err) {
    callback(SATELLITE_SWITCH_OFF);
    LogUtils.e(TAG, `querySatellite query out error: code: ${err.code}, message: ${err.message}`);
  }
}

async function insertWithParam(keyword: string, value: number = 0, context: Context,
  uri: string = SETTING_SATELLITE_SERVICE_URI) {
  if (!dataShareHelper) {
    dataShareHelper = await dataShare.createDataShareHelper(context, SETTING_SATELLITE_SERVICE_URI);
  }
  let columns = ['*'];
  let selectsEq = new dataSharePredicates.DataSharePredicates();
  selectsEq.equalTo('KEYWORD', keyword);
  const queryData: ValuesBucket = {
    KEYWORD: keyword,
    VALUE: value,
  }
  try {
    dataShareHelper.query(ON_SETTING_SATELLITE_SERVICE_URI, selectsEq, columns, (err, data) => {
      if (err !== undefined) {
        LogUtils.e(TAG, `dataShareHelper is  error, code: ${err?.code}, message: ${err?.message}`);
        return;
      }
      if (data.rowCount !== 0) {
        LogUtils.i(TAG, 'insertWithParam query, succeed rowCount : ' + data.rowCount);
        dataShareHelper.update(uri, selectsEq, queryData, (err, data) => {
          if (err !== undefined) {
            LogUtils.e(TAG, `update error, code: ${err?.code}, message: ${err?.message}`);
          } else {
            LogUtils.i(TAG, `query update, rowCount: ${data}`);
          }
        });
      } else {
        dataShareHelper.insert(uri, queryData).then((data) => {
          LogUtils.i(TAG, 'Insert succeed' + data);
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `Insert is  error, code: ${err?.code}, message: ${err?.message}`);
        });
      }
      data.close();
    });
  } catch (err) {
    LogUtils.e(TAG, `dataShareHelper is  false, code: ${err?.code}, message: ${err?.message}`);
  }
}

export async function insert(value: number = 0, context: Context,
  satelliteType: SatelliteType = SatelliteType.TIAN_TONG) {
  LogUtils.i(TAG, `insert ${satelliteType} value${value}`);
  let uri = satelliteType === SatelliteType.TIAN_TONG ?
    ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_TIANTONG_KEY :
    ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_HYACINTH_KEY;
  await insertWithParam(getSatelliteModeKey(satelliteType), value, context, uri);
  await insertWithParam(QUERY_SATELLITE_MODE_KEY, value, context);
}

export function getSatelliteModeKey(satelliteType: SatelliteType) {
  return satelliteType === SatelliteType.TIAN_TONG ? QUERY_SATELLITE_MODE_TIANTONG_KEY :
    QUERY_SATELLITE_MODE_HYACINTH_KEY;
}

export async function insertConnectState(value: number = 0, context: Context) {
  LogUtils.i(TAG, `insertConnectState ${value}`);
  if (!dataShareHelper) {
    dataShareHelper = await dataShare.createDataShareHelper(context, SETTING_SATELLITE_SERVICE_URI);
  }
  let columns = ['*'];
  let selectsEq = new dataSharePredicates.DataSharePredicates();
  selectsEq.equalTo('KEYWORD', QUERY_SATELLITE_CONNECTED);
  const queryData: ValuesBucket = {
    KEYWORD: QUERY_SATELLITE_CONNECTED,
    VALUE: value,
  }
  try {
    dataShareHelper.query(ON_SETTING_SATELLITE_SERVICE_URI, selectsEq, columns, (err, data) => {
      if (err !== undefined) {
        LogUtils.e(TAG, `dataShareHelper is error, code: ${err?.code}, message: ${err?.message}`);
        return;
      }
      if (data.rowCount !== 0) {
        LogUtils.i(TAG, 'query, succeed rowCount : ' + data.rowCount);
        dataShareHelper.update(ON_SETTING_SATELLITE_SERVICE_URI, selectsEq, queryData, (err, data) => {
          if (err !== undefined) {
            LogUtils.e(TAG, `update error, code: ${err?.code}, message: ${err?.message}`);
          } else {
            LogUtils.i(TAG, 'query update, rowCount : ' + data);
          }
        });
      } else {
        dataShareHelper.insert(ON_SETTING_SATELLITE_SERVICE_URI, queryData).then((data) => {
          LogUtils.i(TAG, 'Insert succeed' + data);
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `Insert is error, code: ${err?.code}, message: ${err?.message}`);
        });
      }
      data.close();
    });
  } catch (err) {
    LogUtils.e(TAG, `dataShareHelper is false, code: ${err?.code}, message: ${err?.message}`);
  }
}
