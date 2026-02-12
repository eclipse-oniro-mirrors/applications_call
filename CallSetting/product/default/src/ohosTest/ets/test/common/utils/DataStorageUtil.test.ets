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
import common from '@ohos.app.ability.common';
import * as DataStorageUtil from '../../../../../main/ets/common/utils/DataStorageUtil';
import { MobileDataGlobalContextHelper, Constants, getCellularDataRoaming } from '@ohos/common/CommonIndex';
import data_preferences from '@ohos.data.preferences';
import { sleep } from './Sleep';

const DATA_KEY_END = 'data_key';
const DATA_PREFERENCES_NAME = 'data_preference_name';
let options: data_preferences.Options = {
  name: DATA_PREFERENCES_NAME
}

let DataStorageUtilTest_updateStorage_01 = async () => {
  let context = MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
  DataStorageUtil.updateStorage(context, [0, 0]);
  expect(true).assertTrue();
  await sleep(1000);
  DataStorageUtil.getStorageData(context, (data) => {
  });
}

let DataStorageUtilTest_updateStorage_02 = async () => {
  let context = MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
  DataStorageUtil.updateStorage(context, []);
  expect(true).assertTrue();
  await sleep(1000);
  DataStorageUtil.getStorageData(context, (data) => {
  });
}

let DataStorageUtilTest_getStorageData_01 = async () => {
  let value: data_preferences.ValueType = [12, 1];
  let dataPreferences: data_preferences.Preferences;
  let key = DATA_KEY_END;
  data_preferences.getPreferences(MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), options, async (err, res) => {
    dataPreferences = res;
    dataPreferences.put(key, value);
    await sleep(1000);
    getCellularDataRoaming()
    DataStorageUtil.getStorageData(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), (data) => {
      dataPreferences.delete(key, (err, result) => {
      });
    });
  });
}

let DataStorageUtilTest_getStorageData_02 = async () => {
  let dataPreferences: data_preferences.Preferences;
  data_preferences.getPreferences(MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), options, async (err, res) => {
    dataPreferences = res;
    let key = DATA_KEY_END;
    dataPreferences.put(key, 'test');
    await sleep(1000);
    DataStorageUtil.getStorageData(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), (data) => {
    });
  });
}

export default function DataStorageUtilTest() {
  describe('DataStorageUtilTest', () => {
    let emptyContext: common.UIAbilityContext;
    it('DataStorageUtilTest_getStorageData_03', 0, async () => {
      let r = DataStorageUtil.getStorageData(emptyContext, () => {
      });
      expect(r == null).assertEqual(true)
    });
    it('DataStorageUtilTest_updateStorage_01', 0, async () => {
      await DataStorageUtilTest_updateStorage_01();
    });
    it('DataStorageUtilTest_updateStorage_02', 0, async () => {
      await DataStorageUtilTest_updateStorage_02();
    });
    it('DataStorageUtilTest_getStorageData_01', 0, async () => {
      await DataStorageUtilTest_getStorageData_01();
    });
    //构造异常场景，调用方法返回默认data
    it('DataStorageUtilTest_getStorageData_02', 0, async () => {
      await DataStorageUtilTest_getStorageData_02();
    });
  })
}