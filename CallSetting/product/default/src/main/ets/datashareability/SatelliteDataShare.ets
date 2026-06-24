/*
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

/**
 * @file: SatelliteDataShare
 */
import { LogUtils } from '@ohos/common/CommonIndex';
import { dataShare, ValuesBucket } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'SatelliteDataShare';

const SETTING_SATELLITE_URI = 'datashare:///com.ohos.callsetting.satellitedatashareAbility';
const SETTING_SATELLITE_NUMBER_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.number';

let dataShareHelper: dataShare.DataShareHelper;

/**
 * insert number.
 */
export async function insertSatelliteNumber(context: Context, number: string) {
  LogUtils.i(TAG, 'insertSatelliteNumber is called');
  if (!dataShareHelper) {
    dataShareHelper = await dataShare.createDataShareHelper(context, SETTING_SATELLITE_URI);
  }
  const queryData: ValuesBucket = {
    'number': !number ? '' : number,
  }
  try {
    dataShareHelper?.insert(SETTING_SATELLITE_NUMBER_URI, queryData).then((data) => {
      LogUtils.i(TAG, 'insert succeed');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `Insert is error: code: ${err?.code}, message: ${err?.message} `);
    });
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + error.code + ', message: ' + error.message);
  }
}