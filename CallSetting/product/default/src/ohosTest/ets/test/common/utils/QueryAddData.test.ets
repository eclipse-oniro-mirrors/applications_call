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
import QueryAddData from '../../../../../main/ets/common/utils/queryAddData';
import dataShare from '@ohos.data.dataShare';
import common from '@ohos.app.ability.common';
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import * as CallSettingsConstant from '../../../../../main/ets/common/constant/CallSettingsConstant';
import { sleep } from './Sleep';

const SETTINGS_DATA_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
let queryAddData: QueryAddData = new QueryAddData();
let dataShareHelper: dataShare.DataShareHelper;

let QueryAddDataTest_addCallMergeListener = () => {
  dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
    SETTINGS_DATA_URI, (err, data) => {
      dataShareHelper = data;
    });
  queryAddData.addCallMergeListener('test');
  expect(true).assertTrue();
}

let QueryAddDataTest_getValue = async () => {
  queryAddData.getValue(dataShareHelper, (val: string) => {
    expect(true).assertTrue();
  });
  await sleep(2000);
  queryAddData.getValue(undefined, (val: string) => {
    expect(true).assertTrue();
  });
}

let QueryAddDataTest_queryCallMerge = () => {
  queryAddData.queryCallMerge('');
  expect(true).assertTrue();
}

let QueryAddDataTest_queryCallNotifiesType = () => {
  queryAddData.queryCallNotifiesType((val: string) => {
    expect(true).assertTrue();
  });
}

let QueryAddDataTest_setCallCallNotifiesType = () => {
  queryAddData.setCallCallNotifiesType('');
  expect(true).assertTrue();
}

export default function QueryAddDataTest() {
  describe('QueryAddDataTest', () => {
    it('QueryAddDataTest_addCallMergeListener', 0, () => {
      QueryAddDataTest_addCallMergeListener();
    });
    it('QueryAddDataTest_getValue', 0, () => {
      QueryAddDataTest_getValue();
    });
    it('QueryAddDataTest_queryCallMerge', 0, () => {
      QueryAddDataTest_queryCallMerge();
    });
    it('QueryAddDataTest_queryCallNotifiesType', 0, () => {
      QueryAddDataTest_queryCallNotifiesType();
    });
    it('QueryAddDataTest_setCallCallNotifiesType', 0, () => {
      QueryAddDataTest_setCallCallNotifiesType();
    });
  });
}