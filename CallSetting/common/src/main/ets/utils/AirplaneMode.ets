/**
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
 * Message/AirplaneMode utils
 */
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { BusinessError } from '@ohos.base';
import { LogUtils } from './LogUtils';
import { Constants } from './Constants';
import { MobileDataGlobalContextHelper } from './MobileDataGlobalContextHelper';
import common from '@ohos.app.ability.common';

const SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const ON_SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key=airplane_mode';
const QUERY_AIRPLANE_MODE_KEY = 'settings.telephony.airplanemode';
const TAG = 'AirplaneMode';

let dataShareHelper: dataShare.DataShareHelper;

/**
 * add AirPlaneMode Listener.
 */
export function addAirPlaneModeListener(callback: Function) {
  LogUtils.i(TAG, 'addAirPlaneModeListener');
  try {
    dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext().
    getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT),
      SETTING_AIRPLANE_MODE_URI, (err, data) => {
      if (err != undefined) {
        LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + err.code + ', message: ' + err.message);
        return;
      }
      dataShareHelper = data;
      try {
        dataShareHelper.on('dataChange', ON_SETTING_AIRPLANE_MODE_URI, () => {
          LogUtils.i(TAG, 'addAirPlaneModeListener dataChange');
          queryAirPlaneMode(callback);
        });
        queryAirPlaneMode(callback);
      } catch (err) {
        let error: BusinessError = err as BusinessError;
        LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + error.code + ', message: ' + error.message);
      }
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
    dataShareHelper.off('dataChange', ON_SETTING_AIRPLANE_MODE_URI, () => {
      LogUtils.i(TAG, 'removeAirPlaneModeListener dataChange');
    });
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
