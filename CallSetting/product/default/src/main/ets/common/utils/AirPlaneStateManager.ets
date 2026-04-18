/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import { BusinessError } from '@ohos.base';

const SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const ON_SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&' +
  'key=airplane_mode';
const QUERY_AIRPLANE_MODE_KEY = 'settings.telephony.airplanemode';
const TAG = 'AirplaneMode';

let dataShareHelper: dataShare.DataShareHelper;

export async function addAirPlaneModeListener() {
  LogUtils.i(TAG, 'addAirPlaneModeListener');
  try {
    dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext().
    getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
      SETTING_AIRPLANE_MODE_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
      if (err != undefined) {
        LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + err.code + ', message: ' + err.message);
        return;
      }
      dataShareHelper = data;
      try {
        dataShareHelper.on('dataChange', ON_SETTING_AIRPLANE_MODE_URI, () => {
          LogUtils.i(TAG, 'addAirPlaneModeListener dataChange');
          queryAirPlaneMode();
        });
        queryAirPlaneMode();
      } catch (err) {
        let error = err as BusinessError;
        LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + error.code + ', message: ' + error.message);
      }
    });
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + error.code + ', message: ' + error.message);
  }
}

export async function removeAirPlaneModeListener() {
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
    let error = err as BusinessError;
    LogUtils.e(TAG, 'removeAirPlaneModeListener error: code: ' + error.code + ', message: ' + error.message);
  }
}

export async function queryAirPlaneMode() {
  LogUtils.i(TAG, 'queryAirPlaneMode ');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'queryAirPlaneMode dataShareHelper null');
    return;
  }
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', QUERY_AIRPLANE_MODE_KEY);
  try {
    dataShareHelper.query(ON_SETTING_AIRPLANE_MODE_URI, condition, []).then((data) => {
      LogUtils.i(TAG, 'queryAirPlaneMode query succeed');
      let hasNext = data.goToFirstRow();
      while (hasNext) {
        if (data.getString(data.getColumnIndex('KEYWORD')) == QUERY_AIRPLANE_MODE_KEY) {
          LogUtils.i(TAG, 'queryAirPlaneMode query succeed return key');
          let value = data.getLong(data.getColumnIndex('VALUE'));
          AppStorage.SetOrCreate('airPlaneOn', value === 1);
          data.close();
          return;
        }
        hasNext = data.goToNextRow();
      }
      AppStorage.SetOrCreate('airPlaneOn', false);
      data.close();
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'queryAirPlaneMode query in error: err: ' + JSON.stringify(err));
    });
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'queryAirPlaneMode query out error: code: ' + error.code + ', message: ' + error.message);
  }
}