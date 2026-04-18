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

import { describe, it, expect } from '@ohos/hypium';
import * as SatelliteLocation from '../../../../../main/ets/common/utils/SatelliteLocation';
import SatelliteSearchManager from '../../../../../main/ets/manager/SatelliteSearchManager';
import common from '@ohos.app.ability.common';
import { MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';
import { sleep } from './Sleep';

let context = MobileDataGlobalContextHelper.getContext()
  .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);

let SatelliteLocationTest_formatKvStoreData = async () => {
  let location: string = SatelliteSearchManager.getInstance().getLocationLongitude() +
    '_' + SatelliteSearchManager.getInstance().getLocationLatitude();
  SatelliteLocation.formatKvStoreData(context, location, () => {
    expect(true).assertTrue();
  });
  await sleep(2000);
  SatelliteLocation.formatKvStoreData(context, 'test', () => {
    expect(true).assertTrue();
  });
}
let SatelliteLocationTest_updateLocation = async () => {
  let result = SatelliteLocation.updateLocation();
  expect(result == null).assertTrue()
}
let SatelliteLocationTest_updateStatus = async () => {
  let result = SatelliteLocation.updateStatus();
  expect(result == null).assertTrue()
}
export default function SatelliteLocationTest() {
  describe('SatelliteLocationTest', () => {
    it('SatelliteLocationTest_formatKvStoreData', 0, () => {
      SatelliteLocationTest_formatKvStoreData();
    });
    it('SatelliteLocationTest_updateLocation', 0, () => {
      SatelliteLocationTest_updateLocation();
    });
    it('SatelliteLocationTest_updateStatus', 0, () => {
      SatelliteLocationTest_updateStatus();
    });
  });
}