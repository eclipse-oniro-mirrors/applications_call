/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { CustPhoneNetworkStruct, CustWearableNetworkStruct, OperatorConfigUtils } from '@ohos/cust';
import { describe, expect, it } from '@ohos/hypium';
import { sim } from '@kit.TelephonyKit';
import { CustConstants } from '@ohos/cust/src/main/ets/config/CustConstants';

export default function OperatorConfigUtilsTest() {
  describe('OperatorConfigUtilsTest', () => {
    it('OperatorConfigUtilsTest_CustPhoneNetworkStruct', 0, (done: Function) => {
      OperatorConfigUtils.getInstance().initOperatorConfig();

      let errorNetworkStruct: CustPhoneNetworkStruct = new CustPhoneNetworkStruct();
      (OperatorConfigUtils.getInstance() as object)['mOperatorConfigMap'] = null;
      OperatorConfigUtils.getInstance().setCustParam(errorNetworkStruct, 0);
      (OperatorConfigUtils.getInstance() as object)['mOperatorConfigMap'] = new Map();
      OperatorConfigUtils.getInstance().setCustParam(errorNetworkStruct, 0);

      let errorMap: Map<number, Array<sim.OperatorConfig> | undefined> = new Map();
      errorMap.set(0, undefined);
      (OperatorConfigUtils.getInstance() as object)['mOperatorConfigMap'] = errorMap;
      OperatorConfigUtils.getInstance().setCustParam(errorNetworkStruct, 0);

      let arr: Array<sim.OperatorConfig> = new Array();
      arr.push({ field: CustConstants.VOLTE_SUPPORTED_BOOL, value: 'true' });
      arr.push({ field: CustConstants.HIDE_IMS_SWITCH_BOOL, value: 'true' });
      arr.push({ field: CustConstants.CARRIER_NETWORKMODE_HIDE_BOOL, value: 'true' });
      arr.push({ field: CustConstants.CARRIER_LTE_SWITCH_BOOL, value: 'true' });
      arr.push({ field: CustConstants.CARRIER_NR_SWITCH_SHOW_BOOL, value: 'true' });
      arr.push({ field: CustConstants.DATA_ROAMING_OPTION, value: '1' });

      let map: Map<number, Array<sim.OperatorConfig>> = new Map();
      map.set(0, arr);
      map.set(1, arr);
      (OperatorConfigUtils.getInstance() as object)['mOperatorConfigMap'] = map;

      let custPhoneNetworkStructOne: CustPhoneNetworkStruct = new CustPhoneNetworkStruct();
      OperatorConfigUtils.getInstance().setCustParam(custPhoneNetworkStructOne, 0);
      expect(custPhoneNetworkStructOne.isSupportVolte).assertTrue();

      let custPhoneNetworkStructTwo: CustPhoneNetworkStruct = new CustPhoneNetworkStruct();
      OperatorConfigUtils.getInstance().setCustParam(custPhoneNetworkStructTwo, 1);
      expect(custPhoneNetworkStructTwo.isSupportVolte).assertTrue();
      done();
    })
    it('OperatorConfigUtilsTest_CustWearableNetworkStruct', 0, (done: Function) => {
      OperatorConfigUtils.getInstance().getRoamingOptionValue();

      let arr: Array<sim.OperatorConfig | undefined> = new Array();
      arr.push({ field: CustConstants.VOLTE_SUPPORTED_BOOL, value: 'true' });
      arr.push({ field: CustConstants.HIDE_IMS_SWITCH_BOOL, value: 'true' });
      arr.push({ field: CustConstants.CARRIER_NETWORKMODE_HIDE_BOOL, value: 'true' });
      arr.push({ field: CustConstants.CARRIER_LTE_SWITCH_BOOL, value: 'true' });
      arr.push({ field: CustConstants.CARRIER_NR_SWITCH_SHOW_BOOL, value: 'true' });
      arr.push({ field: CustConstants.DATA_ROAMING_OPTION, value: '1' });
      arr.push({ field: 'configDemo', value: '1' });
      arr.push(undefined);

      let map: Map<number, Array<sim.OperatorConfig | undefined>> = new Map();
      map.set(0, arr);
      (OperatorConfigUtils.getInstance() as object)['mOperatorConfigMap'] = map;

      let custWearableNetworkStruct: CustWearableNetworkStruct = new CustWearableNetworkStruct();
      OperatorConfigUtils.getInstance().setCustWearableParam(custWearableNetworkStruct);
      expect(custWearableNetworkStruct.isSupportDataRoamingExtend).assertTrue();
      expect(OperatorConfigUtils.getInstance().getRoamingOptionValue()).assertEqual('1');
      done();
    })
    it('OperatorConfigUtilsTest_error', 0, (done: Function) => {
      OperatorConfigUtils.getInstance().getRoamingOptionValue();
      (OperatorConfigUtils.getInstance() as object)['mCustPhoneNetworkCardOne'] = undefined;
      (OperatorConfigUtils.getInstance() as object)['mCustPhoneNetworkCardTwo'] = undefined;

      (OperatorConfigUtils.getInstance() as object)['setVolteSupportBool']('false', 0);
      (OperatorConfigUtils.getInstance() as object)['setVolteSupportBool']('false', 1);

      (OperatorConfigUtils.getInstance() as object)['setHideImsSwitchBool']('false', 0);
      (OperatorConfigUtils.getInstance() as object)['setHideImsSwitchBool']('false', 1);

      (OperatorConfigUtils.getInstance() as object)['setCarrierNetworkModeHideBool']('false', 0);
      (OperatorConfigUtils.getInstance() as object)['setCarrierNetworkModeHideBool']('false', 1);

      (OperatorConfigUtils.getInstance() as object)['setCarrierLteSwitchBool']('false', 0);
      (OperatorConfigUtils.getInstance() as object)['setCarrierLteSwitchBool']('false', 1);

      (OperatorConfigUtils.getInstance() as object)['setCarrierNrSwitchShowBool']('false', 0);
      (OperatorConfigUtils.getInstance() as object)['setCarrierNrSwitchShowBool']('false', 1);

      (OperatorConfigUtils.getInstance() as object)['setWearableDataRoaming'](undefined);
      (OperatorConfigUtils.getInstance() as object)['setWearableDataRoaming']('5');

      expect((OperatorConfigUtils.getInstance() as object)['mCustPhoneNetworkCardOne']).assertEqual(undefined);
      expect((OperatorConfigUtils.getInstance() as object)['mCustPhoneNetworkCardTwo']).assertEqual(undefined);
      done();
    })
  })
}