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

import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import settings from '@ohos.settings';

const SETTINGS_DATA_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const SETTINGSDATA_KEY: string = 'settings.telephony.callnotifytype';
const NUMBER_IDENTITY_KEY: string = 'settings.telephony.number_identity_switch';
const TAG = 'queryAddData';

let dataShareHelper: dataShare.DataShareHelper;

export default class QueryAddData {
  addCallMergeListener(value: string) {
    try {
      dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        SETTINGS_DATA_URI, (err, data) => {
          if (err !== undefined) {
            LogUtils.e(TAG, `createDataShareHelper error: code: ${err.code}, message: ${err.message} `);
            return;
          }
          LogUtils.i(TAG, 'createDataShareHelper succeed, data : ' + JSON.stringify(data));
          dataShareHelper = data;
          this.queryCallMerge(value);
        });
    } catch (err) {
      LogUtils.e(TAG, `createDataShareHelper error: code: ${(err as BusinessError).code}, ` +
        `message: ${(err as BusinessError).code}.message} `);
    }
  }

  async getValue(daHelper: dataShare.DataShareHelper | undefined, callBack: (val: string) => void) {
    if (daHelper === undefined) {
      daHelper = await dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        SETTINGS_DATA_URI);
      LogUtils.i(TAG, 'DAHelperDAHelperDAHelper ' + daHelper);
    }
    let columns = ['*'];
    let dataShares = new dataSharePredicates.DataSharePredicates();
    dataShares.equalTo('KEYWORD', 'settings.telephony.calllogmergetype');
    let resultSet = await daHelper.query(SETTINGS_DATA_URI, dataShares, columns);
    if (resultSet && resultSet.goToLastRow()) {
      let getData: string = resultSet.getString(resultSet.getColumnIndex('VALUE'));
      resultSet.close();
      callBack(getData);
    }
  }

  queryCallMerge(value: string) {
    if (!dataShareHelper) {
      LogUtils.e(TAG, 'createDataShareHelper is null');
      return;
    }
    let columns = ['*'];
    let selectsEq = new dataSharePredicates.DataSharePredicates();
    selectsEq.equalTo('KEYWORD', 'settings.telephony.calllogmergetype');
    const queryData: ValuesBucket = {
      KEYWORD: 'settings.telephony.calllogmergetype',
      VALUE: value,
    }
    try {
      dataShareHelper.query(SETTINGS_DATA_URI, selectsEq, columns, (err, data) => {
        if (err !== undefined) {
          LogUtils.e(TAG, `dataShareHelper is  error: code: ${err.code}, message: ${err.message} `);
          return;
        }
        if (data.rowCount !== 0) {
          LogUtils.i(TAG, 'query succeed, rowCount : ' + data.rowCount);
          dataShareHelper.update(SETTINGS_DATA_URI, selectsEq, queryData, (err, data) => {
            if (err !== undefined) {
              LogUtils.e(TAG, `update error: code: ${err.code}, message: ${err.message} `);
            } else {
              LogUtils.i(TAG, 'query succeed, rowCount : ' + data);
            }
          });
        } else {
          dataShareHelper.insert(SETTINGS_DATA_URI, queryData).then((data) => {
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
    };
  }

  async queryCallNotifiesType(callBack: (val: string) => void) {
    try {
      settings.getValue(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        SETTINGSDATA_KEY).then((data) => {
        LogUtils.i(TAG, `queryCallNotifiesType success, promise: data->${JSON.stringify(data)}`);
        callBack(data);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `queryCallNotifiesType fail, promise: err->${JSON.stringify(error)}`);
        callBack(CallSettingsConstant.FULL_SCREEN);
      });
    } catch (error) {
      LogUtils.e(TAG, `queryCallNotifiesType fail, err: ${JSON.stringify(error)}`);
      callBack(CallSettingsConstant.FULL_SCREEN);
    }
  }

  async setCallCallNotifiesType(value: string): Promise<boolean | BusinessError> {
    return new Promise((resolve, reject) => {
      try {
        settings.setValue(CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
          SETTINGSDATA_KEY, value).then((data) => {
          resolve(data);
        }).catch((error: BusinessError) => {
          reject(error);
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  async queryNumberIdentitySwitch(callBack: (val: string) => void) {
    try {
      settings.getValue(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        NUMBER_IDENTITY_KEY).then((data) => {
        LogUtils.i(TAG, `queryNumberIdentitySwitch success, promise: data->${JSON.stringify(data)}`);
        callBack(data);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `queryNumberIdentitySwitch fail, promise: err->${JSON.stringify(error)}`);
        callBack(CallSettingsConstant.NUMBER_IDENTITY_CLOSE);
      });
    } catch (error) {
      LogUtils.e(TAG, `queryNumberIdentitySwitch fail, err: ${JSON.stringify(error)}`);
      callBack(CallSettingsConstant.NUMBER_IDENTITY_CLOSE);
    }
  }

  getWifiCallingSwitchState(context: Context, key: string): string {
    const defValue = CallSettingsConstant.WIFI_CALLING_SWITCH_OFF;
    const result: string = settings.getValueSync(context, key, defValue, settings.domainName.USER_PROPERTY);
    return result;
  }

  getWifiCallingImsMode(context: Context, key: string): string {
    const defValue = CallSettingsConstant.WIFI_CALLING_IMS_MODE_WIFI;
    const result: string = settings.getValueSync(context, key, defValue, settings.domainName.USER_PROPERTY);
    return result;
  }
}

