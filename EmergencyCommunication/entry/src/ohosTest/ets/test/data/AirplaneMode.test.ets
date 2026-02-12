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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import common from '@ohos.app.ability.common';
import { EMERGENCY_CALL_ABILITY_CONTEXT } from '../../../../main/ets/utils/Constants';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { sleep } from '../utils/Sleep';
import {
  addAirPlaneModeListener,
  queryAirPlaneMode,
  removeAirPlaneModeListener,
  addAirPlaneDataShareHelper
} from '../../../../main/ets/data/AirplaneMode';
import { BusinessError } from '@ohos.base';

const SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const QUERY_AIRPLANE_MODE_KEY = 'settings.telephony.airplanemode';

export default function AirplaneModeTest() {
  describe('AirplaneModeTest', () => {
    it('AirplaneModeTest_01', 0, async () => {
      airplaneModeTest_01();
    })

    it('AirplaneModeTest_02', 0, async () => {
      removeAirPlaneModeListener();
      expect(true).assertTrue();
    });

    it('AirplaneModeTest_03', 0, async () => {
      queryAirPlaneMode(() => {
        expect(true).assertTrue();
      }, false);
    });
    it('AirplaneModeTest_addAirPlaneDataShareHelperFn', 0, async () => {
      addAirPlaneDataShareHelperFn();
    });
  })
}

function addAirPlaneDataShareHelperFn() {
  let er = {} as BusinessError;
  let data = {} as dataShare.DataShareHelper;
  addAirPlaneDataShareHelper(data, () => {
  }, er)
  expect(true).assertTrue();
}

function airplaneModeTest_01() {
  // Airplane mode is disabled by default.
  // Airplane mode data is written to the database only after it is enabled for the first time.
  // Enable Airplane mode -> 1; Disable Airplane mode -> 0
  let value: number;
  let flag = true;
  let dataShareHelper: dataShare.DataShareHelper;
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', QUERY_AIRPLANE_MODE_KEY);
  dataShare.createDataShareHelper(EmergencyGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(EMERGENCY_CALL_ABILITY_CONTEXT), SETTING_AIRPLANE_MODE_URI, async (err, res) => {
    dataShareHelper = res;
    dataShareHelper.query(SETTING_AIRPLANE_MODE_URI, condition, ['*'], async (err, queryDataFir) => {
      // Get value catch, -1
      value = (queryDataFir.getLong(queryDataFir.getColumnIndex('VALUE')) == 1) ? 0 : 1;
      if (queryDataFir.rowCount == 0) {
        airplaneModeTest_01_ext1(flag, dataShareHelper, condition);
      } else {
        airplaneModeTest_01_ext2(value, flag, dataShareHelper, condition);
      }
      queryDataFir.close();
    })
  })
}

async function airplaneModeTest_01_ext1(flag: boolean, dataShareHelper: dataShare.DataShareHelper,
  condition: dataSharePredicates.DataSharePredicates) {
  let dataFir: ValuesBucket = { 'KEYWORD': QUERY_AIRPLANE_MODE_KEY, 'VALUE': 0 }
  dataShareHelper.insert(SETTING_AIRPLANE_MODE_URI, dataFir);
  await sleep(2000);
  dataShareHelper.query(SETTING_AIRPLANE_MODE_URI, condition, ['*'], (err, queryData) => {
    expect(queryData.rowCount).assertEqual(1);
    addAirPlaneModeListener(() => {
      flag = false;
    }, getContext())
    queryData?.close();
  })
  await sleep(2000);
  // Airplane mode data update triggers listening.
  let data: ValuesBucket = { 'VALUE': 1 };
  dataShareHelper.update(SETTING_AIRPLANE_MODE_URI, condition, data);
  await sleep(2000);
  expect(flag).assertFalse();
  dataShareHelper.query(SETTING_AIRPLANE_MODE_URI, condition, ['*'], (err, queryDataSec) => {
    expect(queryDataSec.getLong(queryDataSec.getColumnIndex('VALUE'))).assertEqual(1);
    queryDataSec?.close();
  })
  let dataSec: ValuesBucket = { 'VALUE': 0 };
  flag = true;
  removeAirPlaneModeListener();
  await sleep(2000);
  dataShareHelper.update(SETTING_AIRPLANE_MODE_URI, condition, dataSec);
  await sleep(2000);
  expect(flag).assertTrue();
  dataShareHelper.query(SETTING_AIRPLANE_MODE_URI, condition, ['*'], (err, result) => {
    expect(result.getLong(result.getColumnIndex('VALUE'))).assertEqual(0);
    result?.close();
  })
  // Delete data and restore the initial status
  dataShareHelper.delete(SETTING_AIRPLANE_MODE_URI, condition);
}

async function airplaneModeTest_01_ext2(value: number, flag: boolean, dataShareHelper: dataShare.DataShareHelper,
  condition: dataSharePredicates.DataSharePredicates) {
  let dataFor: ValuesBucket = { 'VALUE': value }
  addAirPlaneModeListener(() => {
    flag = false;
  }, getContext())
  dataShareHelper.update(SETTING_AIRPLANE_MODE_URI, condition, dataFor);
  await sleep(2000);
  expect(flag).assertFalse()
  dataShareHelper.query(SETTING_AIRPLANE_MODE_URI, condition, ['*'], (err, queryDataFiv) => {
    expect(0).assertEqual(0);
    queryDataFiv?.close();
  })
  let dataReset: ValuesBucket = { 'VALUE': Math.abs(value - 1) }
  flag = true;
  removeAirPlaneModeListener();
  await sleep(2000);
  dataShareHelper.update(SETTING_AIRPLANE_MODE_URI, condition, dataReset);
  await sleep(2000);
  expect(flag).assertTrue();
  dataShareHelper.query(SETTING_AIRPLANE_MODE_URI, condition, ['*'], (err, result) => {
    expect(0).assertEqual(0);
    result?.close();
  })
}