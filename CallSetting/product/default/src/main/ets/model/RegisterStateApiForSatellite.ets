/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

/**
 * @file: RegisterStateApiForSatellite
 */
import observer from '@ohos.telephony.observer';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { dataShare, DataShareResultSet } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { SATELLITE_SERVICE_CONTEXT } from '../common/constant/CallSettingsConstant';
import ServiceExtensionContext from '@ohos.app.ability.common';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import common from '@ohos.app.ability.common';

const TAG = 'RegisterStateApiForSatellite';

const SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const ON_SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true' +
  '&key=airplane_mode';
const QUERY_AIRPLANE_MODE_KEY = 'settings.telephony.airplanemode';

let dataShareHelper: dataShare.DataShareHelper;

/**
 * Monitor the SIM card status
 *
 * @param {function} callBack - call-back
 */
export function registerSimStateChange(slotId: number, callBack: Function) {
  return observer.on('simStateChange', {slotId: slotId}, (simStateData) => {
    LogUtils.i(TAG, 'registerSimStateChange: then ' + JSON.stringify(simStateData))
    callBack(simStateData);
    return simStateData
  });
}

export function unRegisterSimStateChange() {
  LogUtils.i(TAG, 'unRegisterSimStateChange');
  return observer.off('simStateChange');
}

/**
 * Monitor the call state
 *
 * @param {function} callBack - call-back
 */
export function onCallStateChange(callBack: Function) {
  return observer.on('callStateChange', (callStateInfo) => {
    callBack(callStateInfo);
    LogUtils.i(TAG, 'registerCallStateChange: then ' + callStateInfo.state)
    return callStateInfo
  });
}

export function offCallStateChange() {
  LogUtils.i(TAG, 'unregisterCallStateChange');
  return observer.off('callStateChange');
}

/**
 * Monitor the Signal info
 *
 * @param slotId
 * @param {function} callBack - call-back
 * @returns signalInfo
 */
export function onSignalInfoChange(slotId: number, callBack: Function) {
  return observer.on('signalInfoChange', {slotId: slotId}, (signalInfo) => {
    callBack(signalInfo);
    LogUtils.i(TAG, 'registerSignalInfoChange: then ' + signalInfo.values())
    return signalInfo
  });
}

export function offSignalInfoChange() {
  LogUtils.i(TAG, 'offSignalInfoChange');
  return observer.off('signalInfoChange');
}

/**
 * Monitor the network state
 *
 * @param slotId
 * @param {function} callBack - call-back
 * @returns network state
 */
export function onNetworkStateChange(slotId: number, callBack: Function) {
  return observer.on('networkStateChange', {slotId: slotId}, (networkState) => {
    LogUtils.i(TAG, 'onNetworkStateChange: then ' + JSON.stringify(networkState))
    callBack(networkState);
    return networkState
  });
}

export function offNetworkStateChange() {
  LogUtils.i(TAG, 'offNetworkStateChange');
  return observer.off('networkStateChange');
}

/**
 * add AirPlaneMode Listener.
 */
export function addAirPlaneModeListener(callback: Function) {
  LogUtils.i(TAG, 'addAirPlaneModeListener');
  try {
    dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT),
      SETTING_AIRPLANE_MODE_URI, (err, data) => {
        if (err != undefined) {
          LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + err.code + ', message: ' + err.message);
          return;
        }
        dataShareHelper = data;
        dataShareHelper.on('dataChange', ON_SETTING_AIRPLANE_MODE_URI, () => {
          LogUtils.i(TAG, 'addAirPlaneModeListener dataChange');
          queryAirPlaneMode(callback);
        });
      });
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + error.code + ', message: ' + error.message);
  }
}

/**
 * remove AirPlaneMode Listener.
 */
export function removeAirPlaneModeListener() {
  LogUtils.i(TAG, 'removeAirPlaneModeListener');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'removeAirPlaneModeListener dataShareHelper null');
    return;
  }
  try {
    dataShareHelper.off('dataChange', ON_SETTING_AIRPLANE_MODE_URI);
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    LogUtils.e(TAG, 'removeAirPlaneModeListener error: code: ' + error.code + ', message: ' + error.message);
  }
}

/**
 * query AirPlaneMode.
 */
export function queryAirPlaneMode(callback: Function) {
  LogUtils.i(TAG, 'queryAirPlaneMode');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'queryAirPlaneMode dataShareHelper null');
    callback(-1);
    return;
  }
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', QUERY_AIRPLANE_MODE_KEY);
  try {
    // ID, KEYWORD, VALUE
    dataShareHelper.query(ON_SETTING_AIRPLANE_MODE_URI, condition, []).then((data: DataShareResultSet) => {
      LogUtils.i(TAG, 'queryAirPlaneMode query succeed');
      if (data.goToFirstRow()) {
        LogUtils.i(TAG, 'queryAirPlaneMode query succeed return key');
        callback(data.getLong(data.getColumnIndex('VALUE')));
      } else {
        callback(-1);
      }
      data.close();
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'queryAirPlaneMode query in error: err: ' + JSON.stringify(err));
      callback(-1);
    });
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    LogUtils.e(TAG, 'queryAirPlaneMode query out error: code: ' + error.code + ', message: ' + error.message);
    callback(-1);
  }
}

export async function getAirPlaneMode(context: common.ServiceExtensionContext) {
  LogUtils.i(TAG, 'getAirPlaneMode');
  let res: number = -1;
  let shareHelper = await dataShare.createDataShareHelper(context, SETTING_AIRPLANE_MODE_URI);
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', QUERY_AIRPLANE_MODE_KEY);
  let data: DataShareResultSet | undefined = undefined;
  try {
    data = await shareHelper.query(ON_SETTING_AIRPLANE_MODE_URI, condition, []);
    LogUtils.i(TAG, 'getAirPlaneMode query succeed');
    if (data.goToFirstRow()) {
      LogUtils.i(TAG, 'queryAirPlaneMode query succeed return key');
      res = data.getLong(data.getColumnIndex('VALUE'));
    }
  } catch (err) {
    LogUtils.e(TAG, `getAirPlaneMode error: code: ${err?.code}, message: ${err?.message}`);
  } finally {
    if (data !== undefined) {
      data.close();
    }
  }
  return res;
}