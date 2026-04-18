/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import dataShare from '@ohos.data.dataShare';
import { BusinessError } from '@ohos.base';
import ServiceExtensionContext from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import distributedKVStore from '@ohos.data.distributedKVStore';
import { Context } from '@kit.AbilityKit';

const TAG = 'SatelliteLocation:';
const SETTING_SATELLITE_URI = 'datashare:///com.ohos.callsetting.satellitedatashareAbility';
const SETTING_SATELLITE_LOCATION_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.location';
const SETTING_SATELLITE_STATUS_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.status';

let dataShareHelper: dataShare.DataShareHelper;

let kvManager: distributedKVStore.KVManager;

const DEFAULT_STORE_ID: string = 'defaultStoreId';

export function updateLocation() {
  LogUtils.i(TAG, 'updateLocationInfo is called');
  if (dataShareHelper === undefined) {
    dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(CallSettingsConstant.SATELLITE_SERVICE_CONTEXT),
      SETTING_SATELLITE_URI).then((data: dataShare.DataShareHelper) => {
      LogUtils.i(TAG, 'createDataShareHelper succeed, data : ' + data);
      dataShareHelper = data;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `updateLocationInfo createDataShareHelper error: code: ${err.code}, message: ${err.message} `);
    })
  }
  if (dataShareHelper !== undefined) {
    LogUtils.i(TAG, 'updateLocationInfo createDataShareHelper fail, dataShareHelper is null');
    dataShareHelper.notifyChange(SETTING_SATELLITE_LOCATION_URI);
  }
}

export function updateStatus() {
  LogUtils.i(TAG, 'updateStatus is called');
  if (dataShareHelper === undefined) {
    dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(CallSettingsConstant.SATELLITE_SERVICE_CONTEXT),
      SETTING_SATELLITE_URI).then((data: dataShare.DataShareHelper) => {
      LogUtils.i(TAG, 'createDataShareHelper succeed, data: ' + data);
      dataShareHelper = data;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `updateLocationInfo createDataShareHelper error: code: ${err.code}, message: ${err.message} `);
    })
  }
  if (dataShareHelper !== undefined) {
    LogUtils.i(TAG, 'updateLocationInfo createDataShareHelper fail, dataShareHelper is null');
    dataShareHelper.notifyChange(SETTING_SATELLITE_STATUS_URI);
  }
}

export function formatKvStoreData(context: Context, value: string, callback: Function) {
  if (kvManager) {
    getKvStore(value, callback);
  } else {
    const kvManagerConfig: distributedKVStore.KVManagerConfig = {
      context: context,
      bundleName: 'com.ohos.callsetting'
    }
    try {
      kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      LogUtils.i(TAG, 'Succeeded in creating KVManager');
      getKvStore(value, callback);
    } catch (e) {
      LogUtils.i(TAG, `Failed to create KVManager.code is ${e.code},message is ${e.message}`);
      callback(null);
    }
  }
}

function getKvStore(value: string, callback: Function) {
  let kvStore: distributedKVStore.SingleKVStore;
  try {
    const options: distributedKVStore.Options = {
      createIfMissing: true,
      encrypt: false,
      backup: false,
      autoSync: false,
      kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
      securityLevel: distributedKVStore.SecurityLevel.S1,
    };
    kvManager.getKVStore(DEFAULT_STORE_ID, options, (err: BusinessError, store: distributedKVStore.SingleKVStore) => {
      if (err) {
        LogUtils.i(TAG, `Failed to get KVStore.code is ${err.code},message is ${err.message}`);
        callback(null);
        return;
      }
      LogUtils.i(TAG, 'Succeeded in getting KVStore');
      kvStore = store;
      putAndGetStoreData(kvStore, value, callback);
    });
  } catch (e) {
    LogUtils.i(TAG, `An unexpected error occurred.code is ${e.code},message is ${e.message}`);
    callback(null);
  }
}

function putAndGetStoreData(kvStore: distributedKVStore.SingleKVStore, value: string, callback: Function) {
  let resultSet: distributedKVStore.KVStoreResultSet;
  try {

    kvStore.put(value, value, (err) => {
      if (err != undefined) {
        LogUtils.i(TAG, `Failed to put.code is ${err.code},message is ${err.message}`);
        callback(null);
        return;
      }
      LogUtils.i(TAG, 'Succeeded in putting');
      kvStore.getResultSet(value, (err, result) => {
        if (err != undefined) {
          LogUtils.i(TAG, `Failed to get resultset.code is ${err.code},message is ${err.message}`);
          return;
        }
        resultSet = result;
        callback(resultSet);
      })
    });
  } catch (e) {
    LogUtils.i(TAG, `An unexpected error occurred.code is ${e.code},message is ${e.message}`);
    callback(null);
  }
}
