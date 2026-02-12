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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import dataShare from '@ohos.data.dataShare';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { sleep } from './Sleep';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import data_preferences from '@ohos.data.preferences';
import { UriUseClass } from '../../../../../main/ets/common/struct/RecorderStruct';
import recordDatabaseHelper from '../../../../../main/ets/common/utils/DatabaseHelper';
import relationalStore from '@ohos.data.relationalStore';
import { CallSettingConstant } from '../../../../../main/ets/common/constant/CallSettingConstant';

let recordDatabase = recordDatabaseHelper.getInstance();

let DatabaseHelperTest_getCallUserInfo_01 = async () => {
  let callNumber: string = '17314984771';
  let dataShareHelper: dataShare.DataShareHelper;
  dataShare.createDataShareHelper(GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT), Constant.CONTACT_URI,
    async (err, res) => {
      dataShareHelper = res;
      let data: ValuesBucket = {
        'detail_info': callNumber,
        'type_id': '5',
        'is_deleted': '0'
      }
      dataShareHelper.insert(Constant.CONTACT_URI, data);
      await sleep(1000);
      let condition = new dataSharePredicates.DataSharePredicates();
      condition.equalTo('detail_info', callNumber);
      condition.and();
      condition.equalTo('type_id', '5');
      condition.and();
      condition.equalTo('is_deleted', '0');
      let resultSet = await dataShareHelper.query(Constant.CONTACT_URI, condition, ['display_name']);
      expect(resultSet.rowCount).assertEqual(0);
      resultSet.close();
      let contacts: string = await recordDatabase.getCallUserInfo(GlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT), callNumber);
      expect(contacts).assertEqual(callNumber);
      await sleep(1000);
      dataShareHelper.delete(Constant.CONTACT_URI, condition);
    })
  await sleep(2000);
}

let DatabaseHelperTest_getDatabaseInfo_01 = async () => {
  let uri: string = '/path/to/some';
  let preferences = await data_preferences.getPreferences(GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT), 'initDBPreferences');
  recordDatabase.getDatabaseInfo(uri, GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT));
  await sleep(1000);
  recordDatabase.InitForDB(GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT));
  let dbStatus = await preferences.get('isInit', false);
  expect(dbStatus).assertEqual(true);
}

let DatabaseHelperTest_getDatabaseInfo_02 = async () => {
  let uri: string = '/path/to/some';
  let result = await recordDatabase.getDatabaseInfo(uri, GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT));
  if (!result) {
    return;
  }
  let uriUse = uri.split('/').reverse();
  let value: UriUseClass = {
    dbUse: uriUse[1] + '.db',
    tableUse: uriUse[0],
    type: uriUse[2]
  };
  expect(result.dbUse).assertEqual(value.dbUse);
  expect(result.tableUse).assertEqual(value.tableUse);
  expect(result.type).assertEqual(value.type);
}

let DatabaseHelperTest_initMigrationDB = async () => {
  let result = await recordDatabase.initMigrationDB(GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT));
  expect(result).assertTrue();
}

export default function DatabaseHelperTest() {
  describe('DatabaseHelperTest', () => {
    it('DatabaseHelperTest_getCallUserInfo_01', 0, async () => {
      await DatabaseHelperTest_getCallUserInfo_01();
    })
    //if分支
    it('DatabaseHelperTest_getDatabaseInfo_01', 0, async () => {
      await DatabaseHelperTest_getDatabaseInfo_01();
    })
    it('DatabaseHelperTest_getDatabaseInfo_02', 0, async () => {
      await DatabaseHelperTest_getDatabaseInfo_02();
    })
    it('DatabaseHelperTest_initMigrationDB', 0, async () => {
      await DatabaseHelperTest_initMigrationDB();
    })
  })
}
