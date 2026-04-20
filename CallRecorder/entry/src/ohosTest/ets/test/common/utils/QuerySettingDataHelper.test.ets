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
import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import dataShare from '@ohos.data.dataShare';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import QuerySettingsDataHelper from '../../../../../main/ets/common/utils/QuerySettingDataHelper';
import { sleep } from './Sleep';

const SETTINGS_DATA_SECURE_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/USER_SETTINGSDATA_SECURE_100?Proxy=true';

let querySettingsDataHelper = new QuerySettingsDataHelper();
let QuerySettingDataHelperTest_queryIsOpenValue = () => {
  let testContext = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  querySettingsDataHelper.queryIsOpenValue(testContext, undefined, (val) => {
    expect(val >= 0).assertTrue();
  });
}

let QuerySettingDataHelperTest_queryIsOpenValue_02 = async () => {
  let testContext = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let dAHelper = await dataShare.createDataShareHelper(testContext, SETTINGS_DATA_SECURE_URI);
  querySettingsDataHelper.queryIsOpenValue(testContext, dAHelper, (val) => {
    expect(val >= 0).assertTrue();
  });
}

let QuerySettingDataHelperTest_queryObjectValue = () => {
  let testContext = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  querySettingsDataHelper.queryObjectValue(testContext, undefined, (data) => {
    expect(true).assertTrue();
  });
}

let QuerySettingDataHelperTest_queryObjectValue_02 = async () => {
  let testContext = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let dAHelper = await dataShare.createDataShareHelper(testContext, SETTINGS_DATA_SECURE_URI);
  querySettingsDataHelper.queryObjectValue(testContext, dAHelper, (data) => {
    expect(data.length >= 0).assertTrue();
  });
}

export default function QuerySettingDataHelperTest() {
  describe('QuerySettingDataHelperTest', () => {
    it('QuerySettingDataHelperTest_queryIsOpenValue', 0, () => {
      QuerySettingDataHelperTest_queryIsOpenValue();
    });
    it('QuerySettingDataHelperTest_queryIsOpenValue_02', 0, () => {
      QuerySettingDataHelperTest_queryIsOpenValue_02();
    });
    it('QuerySettingDataHelperTest_queryObjectValue', 0, () => {
      QuerySettingDataHelperTest_queryObjectValue();
    });
    it('QuerySettingDataHelperTest_queryObjectValue_02', 0, () => {
      QuerySettingDataHelperTest_queryObjectValue_02();
    });
  })
}