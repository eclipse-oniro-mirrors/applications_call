/*
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

import dataSharePredicates from '@ohos.data.dataSharePredicates';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { LogUtils } from './LogUtils';
import {
  ApnAuthType,
  apnProtocolOption,
  apnRoamingAgreementOption,
  authenticationTypeOption,
  bearerSystemOption,
  DataShareEnum,
  mvnoTypeOption,
  PdpProtocol
} from '../model/ApnData';
import { DataStorage } from './ApnDataStorageCommon';
import { SubDataType } from '../model/ApnTypes';
import { MobileDataSharedPreferencesUtils } from './SharedPreferencesUtils';
import { MobileDataGlobalContextHelper } from './MobileDataGlobalContextHelper';
import common from '@ohos.app.ability.common';
import { Constants } from './Constants';
import sim from '@ohos.telephony.sim';
import preferences from '@ohos.data.preferences';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { Encrypted } from './Encrypted';

const TAG = 'ApnDetailsCommon';
const password = 'password';

export class ApnProxy {
  public proxy: string = '';
  public port: string = '';
}

const PREMADE_APN_AUPPORT_EDIT_ARRAY: string[] = [
  '62401'
];

export class DetailsCommon {
  public profileID: number = -1;
  public name: SubDataType = new SubDataType('name', $r('app.string.Apn_button_name'));
  public apn: SubDataType = new SubDataType('apn', $r('app.string.Apn_button_APN'));
  public proxy: SubDataType = new SubDataType('proxy', $r('app.string.Apn_button_proxy'));
  public port: SubDataType = new SubDataType('port', $r('app.string.Apn_button_port'), 'Number');
  public userName: SubDataType = new SubDataType('userName', $r('app.string.Apn_button_userName'));
  public passWord: SubDataType = new SubDataType('passWord', $r('app.string.Apn_button_passWord'));
  public server: SubDataType = new SubDataType('server', $r('app.string.Apn_button_server'));
  public mmsc: SubDataType = new SubDataType('mmsc', $r('app.string.Apn_button_MMSC'));
  public mmsProxy: SubDataType = new SubDataType('mmsProxy', $r('app.string.Apn_button_MMS_Proxy'));
  public mmsPort: SubDataType = new SubDataType('mmsPort', $r('app.string.Apn_button_MMS_Port'), 'Number');
  public mcc: SubDataType = new SubDataType('mcc', $r('app.string.Apn_button_MCC'));
  public mnc: SubDataType = new SubDataType('mnc', $r('app.string.Apn_button_MNC'));
  public authenticationType: SubDataType = new SubDataType('authenticationType',
    $r('app.string.Apn_button_authenticationType'), 'Radio', authenticationTypeOption, -1);
  public apnType: SubDataType = new SubDataType('apnType', $r('app.string.Apn_button_APN_Type'));
  public apnProtocol: SubDataType = new SubDataType('apnProtocol', $r('app.string.Apn_button_APN_Protocol'),
    'Radio', apnProtocolOption, PdpProtocol.IPV4);
  public apnRoamingAgreement: SubDataType = new SubDataType('apnRoamingAgreement',
    $r('app.string.Apn_button_APN_Roaming_Agreement'), 'Radio', apnRoamingAgreementOption, PdpProtocol.IPV4);
  public apnState: SubDataType = new SubDataType('apnState', $r('app.string.Apn_button_APN_State'), 'Toggle');
  public bearerSystem: SubDataType = new SubDataType('bearerSystem', $r('app.string.Apn_button_APN_bearerSystem'),
    'Checkbox', bearerSystemOption, [0]);
  public mvnoType: SubDataType = new SubDataType('mvnoType', $r('app.string.Apn_button_MVNO_Type'), 'Radio',
    mvnoTypeOption, '0');
  public mvnoValue: SubDataType = new SubDataType('mvnoValue', $r('app.string.Apn_button_MVNO_Value'));
  public isDefault: number = 0;
  public simMcc: string = '';
  public simMnc: string = '';
  public mccmnc: string = '';
  public opkey: string = '';
  public dataStorage: DataStorage = new DataStorage();
  public cardType: number = -1;
  public sharedPreferences: MobileDataSharedPreferencesUtils
  public simId: number = -1;

  constructor() {
    this.sharedPreferences = new MobileDataSharedPreferencesUtils();
    this.sharedPreferences.init(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT));
  }

  getArray() {
    let arr: SubDataType[] = [];
    arr.push(this.name, this.apn, this.proxy, this.port, this.userName, this.passWord, this.server, this.mmsc,
      this.mmsProxy, this.mmsPort, this.mcc, this.mnc, this.authenticationType, this.apnType, this.apnProtocol,
      this.apnRoamingAgreement, this.apnState, this.bearerSystem, this.mvnoType, this.mvnoValue);
    return arr;
  }

  initData() {
    this.setupSimData();
    this.mcc.description = this.simMcc;
    this.mnc.description = this.simMnc;
  }

  private setupSimData() {
    if (this.opkey && this.opkey.length >= 5) {
      this.simMcc = this.opkey.slice(0, 3);
      let first = this.opkey.search('[fF]');
      if (first == -1) {
        this.simMnc = this.opkey.slice(3);
      } else {
        this.simMnc = this.opkey.slice(3, first);
      }
    } else if (this.mccmnc.length === 5 || this.mccmnc.length === 6) {
      LogUtils.i(TAG, 'mccmnc length is: ' + this.mccmnc.length);
      this.simMcc = this.mccmnc.slice(0, 3);
      this.simMnc = this.mccmnc.slice(3);
    }
  }

  async editData(profileID: number) {
    this.setupSimData();
    let ipList = ['IP', 'IPV6', 'IPV4V6'];
    LogUtils.i(TAG + '[profile_id]', JSON.stringify(profileID));
    let da = new dataSharePredicates.DataSharePredicates();
    da.equalTo('profile_id', profileID);
    await this.dataStorage.initData();
    let data = await this.dataStorage.dataQuery(this.simId, da);
    if (data) {
      data.goToFirstRow();

      this.profileID = data.getLong(DataShareEnum.profile_id);
      this.name.description = data.getString(DataShareEnum.profile_name);
      this.opkey = data.getString(DataShareEnum.opkey);
      this.apn.description = data.getString(DataShareEnum.apn);
      let proxyIPAddress = data.getString(DataShareEnum.proxy_ip_address);

      let proxyIPAddressList = proxyIPAddress.split(':');
      if (proxyIPAddressList.length >= 2) {
        let obj = this.getProxyPort(proxyIPAddressList);
        this.proxy.description = obj.proxy;
        this.port.description = obj.port;
      }

      this.userName.description = data.getString(DataShareEnum.auth_user);
      this.passWord.description = data.getString(DataShareEnum.auth_pwd);
      await this.pwdDecode256(data);
      this.server.description = data.getString(DataShareEnum.server);
      this.mmsc.description = data.getString(DataShareEnum.home_url);
      let mmsIPAddress = data.getString(DataShareEnum.mms_ip_address);

      let mmsIPAddressList = mmsIPAddress.split(':');
      if (mmsIPAddressList.length >= 2) {
        let obj = this.getProxyPort(mmsIPAddressList);
        this.mmsProxy.description = obj.proxy;
        this.mmsPort.description = obj.port;
      }

      this.mcc.description = data.getString(DataShareEnum.mcc);
      this.mnc.description = data.getString(DataShareEnum.mnc);
      this.authenticationType.description = data.getLong(DataShareEnum.auth_type);
      this.apnType.description = data.getString(DataShareEnum.apn_types);
      let apnProIndex = ipList.indexOf(data.getString(DataShareEnum.apn_protocol)) > -1 ?
        ipList.indexOf(data.getString(DataShareEnum.apn_protocol)) : 0;
      let apnRoamProIndex = ipList.indexOf(data.getString(DataShareEnum.apn_roam_protocol)) > -1 ?
        ipList.indexOf(data.getString(DataShareEnum.apn_roam_protocol)) : 0;
      this.apnProtocol.description = apnProIndex;
      this.apnRoamingAgreement.description = apnRoamProIndex;
      this.apnState.description = data.getString(DataShareEnum.is_roaming_apn);
      let bearerSystem = data.getLong(DataShareEnum.bearing_system_type);
      this.bearerSystem.description = this.numberToArray(bearerSystem);
      LogUtils.i(TAG, '[DataShareEnum]' + JSON.stringify(data.getString(DataShareEnum.mvno_type)));
      this.mvnoType.description =
        data.getString(DataShareEnum.mvno_type) ? data.getString(DataShareEnum.mvno_type) : '0';
      this.mvnoValue.description = data.getString(DataShareEnum.mvno_match_data);
      data.close();
    }
  }

  async pwdDecode256(data: DataShareResultSet) {
    this.isDefault = data.getLong(DataShareEnum.edited);
    if (this.isDefault === 1 && data.getString(DataShareEnum.auth_pwd) != '') {
      let decrypResult = data.getString(DataShareEnum.auth_pwd);
      this.passWord.description = decrypResult.replace('"', '').replace('"', '');
    }
  }

  getProxyPort(pp: string[]): ApnProxy {
    let length = pp.length;
    let resproxy: string = '';
    let resport: string = '';

    pp.forEach((value, index) => {
      //get proxy
      if (index < length - 1) {
        if (resproxy === '') {
          resproxy += value;
        } else {
          resproxy += ':' + value;
        }
      } else { //get port
        resport = value;
      }
    })
    let res: ApnProxy = {
      proxy: resproxy,
      port: resport
    };
    return res;
  }

  async saveData() {
    if (this.profileID === -1) {
      await this.dataStorage.dataInsert(this.simId, this);
    } else {
      await this.dataStorage.dataUpdate(this.profileID, this);
    }
  }

  async deleteData() {
    let icc = await sim.getSimIccId(this.cardType);
    await this.sharedPreferences.getFromPreferences('selectAPN_common_' + icc, -1)
      .then((data: preferences.ValueType) => {
        if (data === this.profileID) {
          this.sharedPreferences.saveToPreferences('selectAPN_common_' + icc, -1);
        }
      });
    await this.dataStorage.dataDelete(this.profileID);
  }

  private numberToArray(bearerBitmask: number): number[] {
    const arr: number[] = [];
    for (let i = 0; i < 32; i++) {
      if ((bearerBitmask & (1 << i)) !== 0) {
        LogUtils.i(TAG, '[numberToArray bearerBitmask]' + JSON.stringify(i + 1));
        arr.push(i + 1);
      }
    }
    LogUtils.i(TAG, '[numberToArray bearerBitmask]' + JSON.stringify(arr));
    if (arr.length === 0) {
      arr.push(0);
    }
    return arr;
  }

  /**
   * Check Pre-made APN is support edit
   *
   * @param mccmnc
   * @returns
   */
  checkPreMadeAPNIsEdit(mccmnc: string): boolean {
    let isSupportEdit = PREMADE_APN_AUPPORT_EDIT_ARRAY.includes(mccmnc);
    return isSupportEdit;
  }
}