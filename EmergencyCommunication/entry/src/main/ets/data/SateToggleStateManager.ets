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

import LogUtils from '../utils/HiLog';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import common from '@ohos.app.ability.common';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import { BusinessError } from '@ohos.base';
import { ValuesBucket } from '@kit.ArkData';
import systemparameter from '@ohos.systemParameterEnhance';

const SETTING_SATELLITE_SERVICE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const ON_SETTING_SATELLITE_SERVICE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const QUERY_AIRPLANE_MODE_KEY = 'satellite_mode_switch';
const TAG = 'SateToggleSateManager';

let dataShareHelper: dataShare.DataShareHelper;

export async function addSatelliteToggleStateListener(callback: (data: number) => void) {
  LogUtils.i(TAG, 'addSatelliteToggleStateListener');
  try {
    dataShare.createDataShareHelper(EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT),
      SETTING_SATELLITE_SERVICE_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err != undefined) {
          LogUtils.e(TAG, 'addSatelliteToggleStateListener error: code: ' + err.code + ', message: ' + err.message);
          return;
        }
        dataShareHelper = data;
        try {
          dataShareHelper.on('dataChange', ON_SETTING_SATELLITE_SERVICE_URI, () => {
            LogUtils.i(TAG, 'addSatelliteToggleStateListener dataChange success');
            querySatellite(callback);
          });
          querySatellite(callback);
        } catch (err) {
          let error = err as BusinessError;
          LogUtils.e(TAG, 'addSatelliteToggleStateListener error: code: ' + error.code + ', message: ' + error.message);
        }
      });
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'addSatelliteToggleStateListener createDataShareHelper error: code: ' + error.code + ', message: ' + error.message);
  }
}

export async function removeSatelliteToggleStateListener() {
  LogUtils.i(TAG, 'removeSatelliteToggleStateListener');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'removeSatelliteToggleStateListener dataShareHelper null');
    return;
  }
  try {
    dataShareHelper.off('dataChange', ON_SETTING_SATELLITE_SERVICE_URI, () => {
      LogUtils.i(TAG, 'removeSatelliteToggleStateListener dataChange');
    });
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'removeSatelliteToggleStateListener error: code: ' + error.code + ', message: ' + error.message);
  }
}

export async function querySatellite(callback: (data: number) => void) {
  LogUtils.i(TAG, 'querySatellite');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'querySatellite dataShareHelper null');
    return;
  }
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', QUERY_AIRPLANE_MODE_KEY);
  try {
    dataShareHelper.query(ON_SETTING_SATELLITE_SERVICE_URI, condition, []).then((data) => {
      LogUtils.i(TAG, 'querySatellite query succeed');
      if (data && data.goToFirstRow()) {
        let value = data.getLong(data.getColumnIndex('VALUE'));
        LogUtils.i(TAG, `querySatellite query succeed return key ${value}`);
        callback(value);
        // Close DataShareResultSet will save resource.
        data.close();
        return;
      }
      data?.close();
      callback(0);
    }).catch((err: BusinessError) => {
      callback(0);
      LogUtils.e(TAG, 'querySatellite query in error: err:' + JSON.stringify(err));
    });
  } catch (err) {
    let error = err as BusinessError;
    callback(0);
    LogUtils.e(TAG, 'querySatellite query out error: code:' + error.code + ', message: ' + error.message);
  }
}