/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import { DataShareHelper } from './ContactsModel';
import { DatabaseUri } from '../data/CommonData';
import LogUtils from '../utils/HiLog';
import { DataShareResultSet } from '@kit.ArkData';

const TAG = 'SatelliteModel';

const TIAN_TONG_SATELLITE_CONNECT_STATUS_TRUE = 4;

/**
 * 监听天通卫星连接状态
 * @param context
 * @param callback
 */
export async function addTianTongConnectStateListener(context: Context, callback: () => void) {
  LogUtils.i(TAG, 'addTianTongConnectStateListener');
  let dataShareHelper:ESObject = await DataShareHelper.getInstance().initTianTongSatelliteDBHelper(context);
  try {
    dataShareHelper?.on('dataChange', DatabaseUri.SETTING_SATELLITE_STATUS_URI, () => {
      LogUtils.i(TAG, 'addTianTongConnectStateListener dataChange');
      callback();
    });
  } catch (err) {
    LogUtils.e(TAG, 'addTianTongConnectStateListener error: code: ' + err?.code + ', message: ' + err?.message);
  }
}

export async function removeTianTongConnectStateListener() {
  LogUtils.i(TAG, 'removeTianTongConnectStateListener');
  let dataShareHelper:ESObject = DataShareHelper.getInstance().getCallSettingDbHelper();
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'removeTianTongConnectStateListener dataShareHelper null');
    return;
  }
  try {
    dataShareHelper.off('dataChange', DatabaseUri.SETTING_SATELLITE_STATUS_URI);
  } catch (err) {
    LogUtils.e(TAG, 'removeTianTongConnectStateListener error: code: ' + err?.code + ', message: ' + err?.message);
  }
}

export async function queryTianTongSatelliteConnectState(context: Context) {
  LogUtils.i(TAG, 'queryTianTongSatelliteConnectState ');
  let dataShareHelper:ESObject = await DataShareHelper.getInstance().initTianTongSatelliteDBHelper(context);
  let isSatelliteConnected: boolean = false;
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'queryTianTongSatelliteConnectState dataShareHelper null');
    return isSatelliteConnected;
  }
  let condition = new dataSharePredicates.DataSharePredicates();
  let resultSet: null | DataShareResultSet = null;
  try {
    resultSet = await dataShareHelper.query(DatabaseUri.SETTING_SATELLITE_STATUS_URI, condition, ['*'])
      .catch((e: BusinessError) => {
        LogUtils.e(TAG, `queryTianTongSatelliteConnectState query error: ${e?.code} ${e?.message}`);
        return null;
      });
    if (!resultSet) {
      LogUtils.e(TAG, 'queryTianTongSatelliteConnectState resultSet empty');
      return isSatelliteConnected;
    }
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      let value:ESObject = resultSet.getLong(0);
      isSatelliteConnected = value === TIAN_TONG_SATELLITE_CONNECT_STATUS_TRUE ? true : false;
    }
  } catch (e) {
    LogUtils.e(TAG, `queryTianTongSatelliteConnectState error: ${e?.code} ${e?.message}`);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  return isSatelliteConnected;
}

export const querySatelliteLocationData = async (context: Context) => {
  let dataHelper:ESObject = await DataShareHelper.getInstance().initTianTongSatelliteDBHelper(context);
  if (!dataHelper) {
    LogUtils.e(TAG, `querySatelliteLocationData: dataHelper empty`);
    return null;
  }
  let resultSet: null | DataShareResultSet = null;
  try {
    let condition: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    let satelliteUri: string = DatabaseUri.SETTING_SATELLITE_LOCATION_URI;
    resultSet = await dataHelper.query(satelliteUri, condition, ['*'])
      .catch((e: BusinessError) => {
        LogUtils.e(TAG, `querySatelliteLocationData: query fail, error: ${e?.code} ${e?.message}`);
        return null;
      });
    if (!resultSet) {
      LogUtils.e(TAG, 'querySatelliteLocationData: resultSet empty');
      return null;
    }
    let value: string = '';
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      value = resultSet.getString(0);
    }
    return value;
  } catch (e) {
    LogUtils.e(TAG, `querySatelliteLocationData error: ${e?.code} ${e?.message}`);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  return null;
}

export const formatLocationDataOfTianTong = (location: string): string => {
  if (!location) {
    return '';
  }
  let symbolIndex: number = location.indexOf('.');
  if (symbolIndex > 0 && location.length > symbolIndex + 7) {
    return location.substring(0, symbolIndex + 7);
  }
  return location;
}