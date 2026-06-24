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
import { describe, it, expect } from '@ohos/hypium';
import SatelliteLocationDataShareAbility from '../../../main/ets/datashareability/SatelliteLocationDataShareAbility';
import { dataSharePredicates, ValuesBucket } from '@kit.ArkData';
import { insertSatelliteNumber } from '../../../main/ets/datashareability/SatelliteDataShare';
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';

const SETTING_SATELLITE_LOCATION_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.location';
const SETTING_SATELLITE_STATUS_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.status';
const SETTING_SATELLITE_NUMBER_URI = 'datashare:///com.ohos.callsetting.satellitedatashareStatus.number';
let predicate: dataSharePredicates.DataSharePredicates;

export default function SatelliteLocationDataShareAbilityTest() {
  describe('SatelliteLocationDataShareAbilityTest', () => {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>('callSettingsAbilityContext');

    it('SatelliteLocationDataShareAbility_query', 0, () => {
      let sate = new SatelliteLocationDataShareAbility();
      (sate as object)['insert'](SETTING_SATELLITE_NUMBER_URI, undefined, () => {
      });
      insertSatelliteNumber(context, '123');
      sate.query(SETTING_SATELLITE_STATUS_URI, predicate, [''], () => {
      });
      sate.query(SETTING_SATELLITE_NUMBER_URI, predicate, [''], () => {
      });
      sate.query(SETTING_SATELLITE_LOCATION_URI, predicate, [''], () => {
      });
      sate.query('test', predicate, [''], () => {
      });
      let val: ValuesBucket = {
        number: 1
      }
      let val1: ValuesBucket = {}
      sate.insert(SETTING_SATELLITE_NUMBER_URI, val, () => {
      });
      sate.insert(SETTING_SATELLITE_NUMBER_URI, val1, () => {
      });
      let result = sate.insert('test', val, () => {
      });
      expect(result === null).assertFalse()
    })
  })
}