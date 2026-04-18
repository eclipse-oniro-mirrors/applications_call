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

import DataShareExtensionAbility from '@ohos.application.DataShareExtensionAbility';
import { AsyncCallback } from '@ohos.base';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { distributedKVStore, ValuesBucket} from '@kit.ArkData';
import * as SatelliteLocation from '../common/utils/SatelliteLocation';
import SatelliteSearchManager from '../manager/SatelliteSearchManager';
import { LogUtils, sharedPreferencesUtils } from '@ohos/common/CommonIndex';

const SETTING_SATELLITE_LOCATION_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.location';
const SETTING_SATELLITE_STATUS_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.status';
const SETTING_SATELLITE_NUMBER_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.number';

const TAG = 'SatelliteLocationDataShareAbility';
export default class SatelliteLocationDataShareAbility extends DataShareExtensionAbility {
  async query(uri: string, predicates: dataSharePredicates.DataSharePredicates,
        columns: Array<string>, callback: AsyncCallback<Object>) {
    if (uri == SETTING_SATELLITE_LOCATION_URI) {
      let location: string = SatelliteSearchManager.getInstance().getLocationLongitude() +
        '_' + SatelliteSearchManager.getInstance().getLocationLatitude();
      SatelliteLocation.formatKvStoreData(this.context,
        location, (resultSet: distributedKVStore.KVStoreResultSet) => {
          callback(undefined, resultSet);
        })
    } else if (uri == SETTING_SATELLITE_STATUS_URI) {
      let status: string = String(SatelliteSearchManager.getInstance().getCurrentStatus());
      SatelliteLocation.formatKvStoreData(this.context, status, (resultSet: distributedKVStore.KVStoreResultSet) => {
        callback(undefined, resultSet);
      })
    } else if (uri == SETTING_SATELLITE_NUMBER_URI) {
      sharedPreferencesUtils.init(getContext());
      let number: string = await sharedPreferencesUtils.getFromPreferences('SATELLITE_SELECT_NUMBER', '') as string;
      SatelliteLocation.formatKvStoreData(this.context,
        number, (resultSet: distributedKVStore.KVStoreResultSet) => {
          callback(undefined, resultSet);
        })
    }
  }

  insert(uri: string, valueBucket: ValuesBucket, callback: AsyncCallback<number, void>): void {
    LogUtils.i(TAG, 'insert is called');
    if (uri === SETTING_SATELLITE_NUMBER_URI) {
      let number: string = valueBucket ? valueBucket.number as string : '';
      if (number) {
        LogUtils.i(TAG, 'insert number success');
        sharedPreferencesUtils.init(getContext());
        sharedPreferencesUtils.saveToPreferences('SATELLITE_SELECT_NUMBER', number);
        callback(undefined, 1);
      }
    }
  }
}
