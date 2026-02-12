/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import LogUtils from './LogUtils';

const TAG = 'QuerySettingsDataHelper';
let dataShareHelper: dataShare.DataShareHelper;
const SETTINGS_DATA_SECURE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/USER_SETTINGSDATA_SECURE_100?Proxy=true';
const SETTINGS_DATA_OPEN_KEY = 'enable_record_auto_key';
const SETTINGS_DATA_OJECT_KEY = 'enable_all_numbers_key';
const KEYWORD_CONST = 'KEYWORD';
const VALUE_CONST = 'VALUE';
const columns = ['*'];

export default class QuerySettingsDataHelper {
  /**
   * get the value of enable_record_auto_key from settingdata.db
   *
   * @param context
   * @param datashareHleper to connect settingsdata
   *
   */
  async queryIsOpenValue(context: common.Context, dAHelper: dataShare.DataShareHelper | undefined,
                         callBack: (val: number) => void) {
    try {
      if (dAHelper === undefined) {
        dAHelper = await dataShare.createDataShareHelper(context, SETTINGS_DATA_SECURE_URI);
      }
      let openDataShares = new dataSharePredicates.DataSharePredicates();
      openDataShares.equalTo(KEYWORD_CONST, SETTINGS_DATA_OPEN_KEY);
      let resultSet = await dAHelper.query(SETTINGS_DATA_SECURE_URI, openDataShares, columns);
      if (resultSet && resultSet.goToFirstRow()) {
        let openData: number = resultSet.getLong(resultSet.getColumnIndex(VALUE_CONST));
        LogUtils.i(TAG, `getData:${openData}`);
        callBack(openData);
      }
      resultSet?.close();
    } catch (err) {
      LogUtils.e(TAG, `queryIsOpenValue error:${JSON.stringify(err)}`);
    }
  }

  /**
   *get the value of enable_all_numbers_key from settingdata.dy
   *
   * @param context
   * @param datashareHleper to connect settingsdata
   */
  async queryObjectValue(context: common.Context, dAHelper: dataShare.DataShareHelper | undefined,
                         callBack: (data: string) => void) {
    try {
      if (dAHelper === undefined) {
        dAHelper = await dataShare.createDataShareHelper(context, SETTINGS_DATA_SECURE_URI);
      }
      let objectDataShares = new dataSharePredicates.DataSharePredicates();
      objectDataShares.equalTo(KEYWORD_CONST, SETTINGS_DATA_OJECT_KEY);
      let resultSet = await dAHelper.query(SETTINGS_DATA_SECURE_URI, objectDataShares, columns);
      if (resultSet && resultSet.goToFirstRow()) {
        let odjectData: string = resultSet.getString(resultSet.getColumnIndex(VALUE_CONST));
        LogUtils.i(TAG, `odjectData length:${odjectData.length}`);
        callBack(odjectData);
      }
      resultSet?.close();
    } catch (err) {
      LogUtils.e(TAG, `queryIsOpenValue error:${JSON.stringify(err)}`);
    }
  }
}