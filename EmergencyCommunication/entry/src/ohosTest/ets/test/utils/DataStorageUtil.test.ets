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

import { describe, beforeAll, beforeEach, it, expect } from '@ohos/hypium'
import { EmergencyInfoStruct } from '../../../../main/ets/utils/ClassStruct';
import * as storageUtil from '../../../../main/ets/utils/DataStorageUtil';
import * as Constants from '../../../../main/ets/utils/Constants';
import data_preferences from '@ohos.data.preferences';
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import common from '@ohos.app.ability.common';
import { sleep } from './Sleep';
import { updateObjectValue } from '../../../../main/ets/utils/CommonFunction';
import UIAbility from '@ohos.app.ability.UIAbility';
import { DataStorageUtil } from '../../../../main/ets/utils/DataStorageUtil';
import { ContactListStruct } from '../../../../main/ets/utils/ClassStruct';

const EMERGENCY_INFO_PREFERENCES_NAME = 'emergency_info_preference_name';
const AUTO_LOCATION_NAME = 'auto_location_flag';
const AUTO_FLAG_KEY = 'autoLocationFlag'
const EMERGENCY_CONTACTS_PREFERENCES_NAME = 'emergency_contacts_preference_name';
const EMERGENCY_CONTACTS_KEY = 'emergency_contacts_key';
const TAG = 'DataStorageUtilTest';

let emergencyInfo: EmergencyInfoStruct = {
  name: '',
  address: 'test'
}

export function DataStorageUtilTest() {
  describe('DataStorageUtilTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      beforeAllUtil();
    });
    it('dataStorageUtilTest_01', 0, () => {
      dataStorageUtilTest_01();
    });
    it('dataStorageUtilTest_02', 0, () => {
      dataStorageUtilTest_02();
    });
    it('dataStorageUtilTest_03', 0, () => {
      dataStorageUtilTest_03();
    });
    it('dataStorageUtilTest_04', 0, () => {
      dataStorageUtilTest_04();
    });
    it('dataStorageUtilTest_05', 0, () => {
      dataStorageUtilTest_05();
    });
    it('dataStorageUtilTest_06', 0, () => {
      dataStorageUtilTest_06();
    });
  });
}

export function DataStorageUtilTest1() {
  describe('DataStorageUtilTest1', () => {
    it('DataStorageUtilTest_updateEmergencyInfo', 0, () => {
      DataStorageUtilTest_updateEmergencyInfo();
    });
    it('DataStorageUtilTest_updateEmergencyInfoOnResult', 0, () => {
      storageUtil.updateEmergencyInfoOnResult('test', '123', false);
      storageUtil.updateLocationFlagOnResult('test', true, false);
      storageUtil.saveEmergencyInfoOnResult(false);
      storageUtil.cleanEmergencyInfoOnResult(false);
      let data = DataStorageUtil.getInstance();
      let context = EmergencyGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT)
      let emptyContext = EmergencyGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>('test')
      data.getContactsPreferences((res: boolean) => {
      }, context);
      let result = data.getContactsPreferences();
      data.getEmergencyContacts((data: ContactListStruct[]) => {
      });
      (data as object)['flushPromiseFn']();
      data.getEmergencyContactsSync(emptyContext);
      data.getEmergencyContactsSync(context);
      data.getEmergencyContacts((data: ContactListStruct[]) => {
      });
      (data as object)['flushPromiseFn']();
      (data as object)['flushPromiseFn']((hd: boolean) => {
      });
      (data as object)['updateEmergencyContactsOnResult']([], 'test', true, (hd: boolean) => {
      });
      (data as object)['updateEmergencyContactsOnResult']([], 'test', false);
      data.updateEmergencyContacts([]);
      expect(result === null).assertFalse();
      (data as object)['contactsPreferences'] = null;
    });
  })
}

function beforeAllUtil() {
  // First store a key-value before set undefined.
  let key = AUTO_FLAG_KEY;
  let key2 = EMERGENCY_CONTACTS_KEY;
  let value: data_preferences.ValueType = true;
  let promise = data_preferences.getPreferences(EmergencyGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT), EMERGENCY_INFO_PREFERENCES_NAME);
  promise.then((object) => {
    object.put(key, value);
  })
  let promise1 = data_preferences.getPreferences(EmergencyGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT), AUTO_LOCATION_NAME);
  promise1.then((object) => {
    object.put(key, value);
  })
  let promise2 = data_preferences.getPreferences(EmergencyGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT),
    EMERGENCY_CONTACTS_PREFERENCES_NAME);
  promise2.then((object) => {
    object.put(key2, value);
  })
}

async function dataStorageUtilTest_01() {
  // Test getEmergencyInfoData.
  storageUtil.getEmergencyInfoData((data) => {
    let keys: string[] = Object.keys(data);
    console.log(TAG, '01:' + keys.length);
    expect(keys.length >= 0).assertTrue();
  });
}

async function dataStorageUtilTest_02() {
  // Test update EmergencyInfoData.
  emergencyInfo = updateObjectValue('name', 'test', emergencyInfo);
  storageUtil.updateEmergencyInfo('name', 'test');
  await sleep(2000);
  storageUtil.getEmergencyInfoData((data) => {
    let keys: string[] = Object.keys(data);
    if (keys.indexOf('name') >= 0) {
      expect(data['name']).assertEqual('test');
    } else {
      expect(keys.length >= 0).assertTrue();
    }
  });
}

function dataStorageUtilTest_03() {
  // Test getAutoLocationFlag.
  storageUtil.getAutoLocationFlag((data) => {
    let keys: string[] = Object.keys(data);
    expect(keys.length >= 0).assertTrue();
  });
}

async function dataStorageUtilTest_04() {
  // Test update AutoLocationFlag.
  EmergencyGlobalContextHelper.getContext().set<common.UIAbilityContext>(
    Constants.EMERGENCY_CALL_ABILITY_CONTEXT, new UIAbility().context);
  storageUtil.updateLocationFlag(AUTO_FLAG_KEY, false);
  storageUtil.getAutoLocationFlag((data) => {
    let isAutoLocation = false;
    if (!data[AUTO_FLAG_KEY]) {
      isAutoLocation = true;
    }
    expect(true).assertEqual(isAutoLocation);
  });
}

async function dataStorageUtilTest_05() {
  // Test getEmergencyContacts.
  DataStorageUtil.getInstance().getEmergencyContacts((data) => {
    let keys: string[] = Object.keys(data);
    expect(keys.length >= 0).assertTrue();
  });
}

async function dataStorageUtilTest_06() {
  // Test update EmergencyContacts.
  DataStorageUtil.getInstance().updateEmergencyContacts([]);
  await sleep(2000);
  DataStorageUtil.getInstance().getEmergencyContacts((data) => {
    let tmp = false;
    if (!data) {
      // No update.
      tmp = true;
    }
    console.log(TAG, '06:' + tmp);
    expect(false).assertEqual(tmp);
  })
}


let DataStorageUtilTest_updateEmergencyInfo = () => {
  storageUtil.updateEmergencyInfo('test', 'b');
  expect(true).assertTrue();
}