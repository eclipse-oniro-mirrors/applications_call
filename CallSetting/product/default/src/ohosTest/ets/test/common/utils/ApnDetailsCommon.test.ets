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
import sim from '@ohos.telephony.sim';
import {
  ApnProxy,
  DetailsCommon,
  SharedPreferencesUtils,
  DataShareEnum,
  MobileDataGlobalContextHelper,
  Constants
} from '@ohos/common/CommonIndex';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import dataShare from '@ohos.data.dataShare';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import common from '@ohos.app.ability.common';
import { sleep } from './Sleep';
import data_preferences from '@ohos.data.preferences';

let uri: string = 'datashare:///com.ohos.pdpprofileability/net/pdp_profile';
let detail = new DetailsCommon();

let ApnDetailsCommonTest_ApnProxy = () => {
  let apnProxy = new ApnProxy();
  let proxy = apnProxy.proxy;
  let port = apnProxy.port;
  expect(proxy).assertEqual('');
  expect(port).assertEqual('');
}

let ApnDetailsCommonTest_getArray = () => {
  let detailsCommon = new DetailsCommon();
  let arr = detailsCommon.getArray();
  expect(arr.length).assertEqual(20);
}

let ApnDetailsCommonTest_initData_01 = () => {
  let detailsCommon = new DetailsCommon();
  detailsCommon.initData();
  expect(detailsCommon.mcc.description).assertEqual('');
}

let ApnDetailsCommonTest_initData_02 = () => {
  let detailsCommon = new DetailsCommon();
  detailsCommon.mccmnc = '12345';
  detailsCommon.initData();
  expect(detailsCommon.simMcc).assertEqual(detailsCommon.mccmnc.slice(0, 3));
  expect(detailsCommon.simMnc).assertEqual(detailsCommon.mccmnc.slice(3, 5));
}

let ApnDetailsCommonTest_editData_01 = async () => {
  let name = 'editData_01_test' + new Date().getTime();
  let detailsCommon = new DetailsCommon();
  let profile_id: number;
  let dataShareHelper: dataShare.DataShareHelper;
  let da = new dataSharePredicates.DataSharePredicates();
  let data: ValuesBucket = {
    'profile_name': name
  }
  da.equalTo('profile_name', name);
  dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), uri, async (err, res) => {
    dataShareHelper = res;
    dataShareHelper.insert(uri, data);
    await sleep(2000);
    dataShareHelper.query(uri, da, ['*'], async (err, queryData) => {
      profile_id = queryData.getLong(queryData.getColumnIndex('profile_id'));
      let ipList = ['IP', 'IPV6', 'IPV4V6'];
      let apnProIndex = ipList.indexOf(queryData.getString(DataShareEnum.apn_protocol)) > -1 ?
      ipList.indexOf(queryData.getString(DataShareEnum.apn_protocol)) : 0;
      let apnRoamProIndex = ipList.indexOf(queryData.getString(DataShareEnum.apn_roam_protocol)) > -1 ?
      ipList.indexOf(queryData.getString(DataShareEnum.apn_roam_protocol)) : 0;
      detailsCommon.editData(profile_id);
      await sleep(1000);
      expect(detailsCommon.profileID).assertEqual(queryData.getLong(DataShareEnum.profile_id));
      expect(detailsCommon.name.description).assertEqual(queryData.getString(DataShareEnum.profile_name));
      expect(detailsCommon.apn.description).assertEqual(queryData.getString(DataShareEnum.apn));
      expect(detailsCommon.userName.description).assertEqual(queryData.getString(DataShareEnum.auth_user));
      expect(detailsCommon.passWord.description).assertEqual(queryData.getString(DataShareEnum.auth_pwd));
      expect(detailsCommon.server.description).assertEqual(queryData.getString(DataShareEnum.server));
      expect(detailsCommon.mmsc.description).assertEqual(queryData.getString(DataShareEnum.home_url));
      expect(detailsCommon.mcc.description).assertEqual(queryData.getString(DataShareEnum.mcc));
      expect(detailsCommon.mnc.description).assertEqual(queryData.getString(DataShareEnum.mnc));
      expect(detailsCommon.authenticationType.description).assertEqual(queryData.getLong(DataShareEnum.auth_type));
      expect(detailsCommon.apnType.description).assertEqual(queryData.getString(DataShareEnum.apn_types));
      expect(detailsCommon.apnProtocol.description).assertEqual(apnProIndex);
      expect(detailsCommon.apnRoamingAgreement.description).assertEqual(apnRoamProIndex);
      expect(detailsCommon.apnState.description).assertEqual(queryData.getString(DataShareEnum.is_roaming_apn));
      expect(detailsCommon.mvnoValue.description).assertEqual(queryData.getString(DataShareEnum.mvno_match_data));
      expect(detailsCommon.isDefault).assertEqual(queryData.getLong(DataShareEnum.edited));
      queryData.close();
    });
  });
}

let ApnDetailsCommonTest_getProxyPort = async () => {
  let detailsCommon = new DetailsCommon();
  detailsCommon.getProxyPort([]);
  expect(true).assertTrue();
  await sleep(1000);
  detailsCommon.getProxyPort(['1', '2', '3']);
  expect(true).assertTrue();
}

let ApnDetailsCommonTest_saveData_01 = async () => {
  let name = 'saveData_01_test' + new Date().getTime();
  let detailsCommon = new DetailsCommon();
  let dataShareHelper: dataShare.DataShareHelper;
  let condition = new dataSharePredicates.DataSharePredicates();
  detailsCommon.profileID = -1;
  detailsCommon.name.description = 'ApnDetailsCommonTest_' + name;
  condition.equalTo('profile_name', 'ApnDetailsCommonTest_' + name);
  dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), uri, async (err, res) => {
    dataShareHelper = res;
    dataShareHelper.query(uri, condition, ['*'], (err, data) => {
      expect(data.rowCount).assertEqual(0);
      data.close();
    });
    await detailsCommon.saveData();
    await sleep(4000);
    dataShareHelper.query(uri, condition, ['*'], (err, queryData) => {
      expect(queryData.rowCount).assertEqual(1);
      queryData.close();
    });
    await sleep(2000);
    dataShareHelper.delete(uri, condition, (err, result) => {
      expect(err).assertEqual(undefined);
    });
  });
}

let ApnDetailsCommonTest_saveData_02 = async () => {
  let name = 'saveData_02_test' + new Date().getTime();
  let dataShareHelper: dataShare.DataShareHelper;
  let detailsCommon = new DetailsCommon();
  let condition = new dataSharePredicates.DataSharePredicates();
  dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), uri, async (err, res) => {
    dataShareHelper = res;
    let insertData: ValuesBucket = {
      'profile_name': name
    }
    dataShareHelper.insert(uri, insertData);
    await sleep(2000);
    condition.equalTo('profile_name', name);
    dataShareHelper.query(uri, condition, ['*'], (err, data) => {
      expect(data.rowCount).assertEqual(1);
      detailsCommon.profileID = data.getLong(data.getColumnIndex('profile_id'));
      data.close();
    });
    await sleep(2000);
    detailsCommon.mvnoType.description = '0';
    detailsCommon.saveData();
    let da = new dataSharePredicates.DataSharePredicates();
    da.equalTo('profile_name', name);
    await sleep(2000);
    dataShareHelper.query(uri, da, ['*'], (err, queryData) => {
      expect(queryData.getString(queryData.getColumnIndex('mvno_type'))).assertEqual('');
      queryData.close();
    });
    dataShareHelper.delete(uri, da, (err, result) => {
      expect(err).assertEqual(undefined);
    });
  });
}

let ApnDetailsCommonTest_deleteData = () => {
  let detailsCommon = new DetailsCommon();
  detailsCommon.cardType = 0;
  detailsCommon.deleteData();
  expect(true).assertTrue();
}

let ApnDetailsCommonTest_deleteData_01 = async () => {
  let sharedPreferencesUtils = new SharedPreferencesUtils();
  let detailsCommon = new DetailsCommon();
  let name = 'deleteData' + new Date().getTime();
  let dataShareHelper: dataShare.DataShareHelper;
  let condition = new dataSharePredicates.DataSharePredicates();
  let icc = await sim.getSimIccId(0);
  dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), uri, async (err, res) => {
    dataShareHelper = res;
    let insertData: ValuesBucket = {
      'profile_name': name
    }
    dataShareHelper.insert(uri, insertData);
    await sleep(2000);
    condition.equalTo('profile_name', name);
    dataShareHelper.query(uri, condition, ['*'], (err, queryData) => {
      detailsCommon.profileID = queryData.getLong(queryData.getColumnIndex('profile_id'));
      queryData.close();
    });
    sharedPreferencesUtils.saveToPreferences('selectAPN_common_' + icc, detailsCommon.profileID);
    detailsCommon.deleteData();
    await sleep(2000);
    let dataPreferences: data_preferences.Preferences;
    data_preferences.getPreferences(MobileDataGlobalContextHelper.getContext()
      .getValue(Constants.SETTINGS_ABILITY_CONTEXT), 'selectAPN_common_' + icc, (err, result) => {
      dataPreferences = result;
      dataPreferences.get('selectAPN_common_' + icc, 2, (err, getData) => {
        expect(getData.valueOf()).assertEqual(-1);
      });
      dataShareHelper.delete(uri, condition, (err, deleteData) => {
        expect(err).assertEqual(undefined);
      });
    });
  });
}

let ApnDetailsCommonTest_deleteData_02 = async () => {
  let sharedPreferencesUtils = new SharedPreferencesUtils();
  let name = 'test' + new Date().getTime();
  let preferences: data_preferences.Preferences;
  let detailsCommon = new DetailsCommon();
  let dataShareHelper: dataShare.DataShareHelper;
  let da = new dataSharePredicates.DataSharePredicates();
  let icc = await sim.getSimIccId(0);
  sharedPreferencesUtils.saveToPreferences('selectAPN_common_' + icc, 'deleteData_test');
  dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), uri, async (err, res) => {
    dataShareHelper = res;
    let data: ValuesBucket = {
      'profile_name': name
    }
    dataShareHelper.insert(uri, data);
    await sleep(2000);
    da.equalTo('profile_name', name);
    dataShareHelper.query(uri, da, ['*'], (err, queryData) => {
      expect(queryData.rowCount).assertEqual(1);
      detailsCommon.profileID = queryData.getLong(queryData.getColumnIndex('profile_id'));
      queryData.close();
    });
    await detailsCommon.deleteData();
    await sleep(2000);
    data_preferences.getPreferences(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), 'CONTACT_PREFERENCE', (err, res) => {
      preferences = res;
      preferences.delete('selectAPN_common_' + icc);
    });
    await sleep(2000);
    dataShareHelper.query(uri, da, ['*'], (err, getData) => {
      expect(getData.rowCount).assertEqual(0);
      getData.close();
    });
  });
}

export default function ApnDetailsCommonTest() {
  describe('ApnDetailsCommonTest', () => {
    it('ApnDetailsCommonTest_ApnProxy', 0, () => {
      ApnDetailsCommonTest_ApnProxy();
    });
    it('ApnDetailsCommonTest_getArray', 0, () => {
      ApnDetailsCommonTest_getArray();
    });
    it('ApnDetailsCommonTest_initData_01', 0, () => {
      ApnDetailsCommonTest_initData_01();
    });
    it('ApnDetailsCommonTest_initData_02', 0, () => {
      ApnDetailsCommonTest_initData_02();
    });
    it('ApnDetailsCommonTest_editData_01', 0, () => {
      ApnDetailsCommonTest_editData_01();
    });
    it('ApnDetailsCommonTest_getProxyPort', 0, () => {
      ApnDetailsCommonTest_getProxyPort();
    });
    it('ApnDetailsCommonTest_saveData_01', 0, () => {
      ApnDetailsCommonTest_saveData_01();
    });
    it('ApnDetailsCommonTest_saveData_02', 0, () => {
      ApnDetailsCommonTest_saveData_02();
    });
    it('ApnDetailsCommonTest_deleteData', 0, () => {
      ApnDetailsCommonTest_deleteData();
    });
    //deleteData的if分支
    it('ApnDetailsCommonTest_deleteData_01', 0, () => {
      ApnDetailsCommonTest_deleteData_01();
    });
    //data不等于this.profile_id场景
    it('ApnDetailsCommonTest_deleteData_02', 0, () => {
      ApnDetailsCommonTest_deleteData_02();
    });
    it('ApnDetailsCommonTest_setupSimData', 0, () => {
      (detail as object)["opkey"] = '1234[fF]';
      (detail as object)["setupSimData"]();
      (detail as object)["opkey"] = '123455';
      (detail as object)["setupSimData"]();
      expect(detail.opkey.length >= 0).assertTrue();
    });
    it('ApnDetailsCommonTest_getProxyPort02', 0, () => {
      let result = detail.getProxyPort(['a', 'b', '3', '4'])
      expect(result.port).assertEqual('4');
    });
    it('ApnDetailsCommonTest_saveData', 0, async () => {
      detail.profileID = 0;
      detail.saveData();
      detail.profileID = -1;
      detail.saveData();
    });
    it('ApnDetailsCommonTest_numberToArray', 0, () => {
      (detail as object)["numberToArray"](1);
      let result: number[] = (detail as object)["numberToArray"](0);
      expect(result.length >= 0).assertTrue();
    });
  })
}