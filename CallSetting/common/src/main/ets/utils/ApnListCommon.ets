/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import sim from '@ohos.telephony.sim';
import common from '@ohos.app.ability.common';
import { LogUtils } from './LogUtils';
import { MobileDataGlobalContextHelper } from './MobileDataGlobalContextHelper';
import { MobileDataSharedPreferencesUtils } from './SharedPreferencesUtils';
import { DataStorage } from './ApnDataStorageCommon';
import { Constants } from './Constants';
import preferences from '@ohos.data.preferences';
import { DataShareEnum } from '../model/ApnData';
import { DataListClass } from '../model/ApnTypes';
import { BusinessError } from '@ohos.base';
import { radio } from '@kit.TelephonyKit';
import { isCellularDataEnabled } from '../model/MobileDataStatus';
import { dataShare } from '@kit.ArkData';
import { ReportUtil } from './ReportUtil';
import { systemParameterEnhance } from '@kit.BasicServicesKit';

const TAG = 'apnListCommon';
const regexDefault = new RegExp('default', 'i');
const regexMms = new RegExp('mms', 'i');
const EFL_FORBIDDEN = 'const.telephony.efl_forbidden';
const EFL_WORD = '5g';

export class ApnListCommon {
  public cardType: number = -1;
  public dataStorage: DataStorage = new DataStorage();
  public dataList: DataListClass[] = [];
  public mmsDataList: DataListClass[] = [];
  public mccmnc: string = '';
  public sharedPreferences: MobileDataSharedPreferencesUtils;
  public selectCommon: number = -1;
  public simId: number = -1;

  constructor() {
    this.sharedPreferences = new MobileDataSharedPreferencesUtils();
    this.sharedPreferences.init(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT));
    this.dataStorage.preferApnCallback = (error: BusinessError, changeInfo: dataShare.ChangeInfo) => {
      let cardType = AppStorage.get('cardType') as number;
      if (cardType !== undefined) {
        this.cardType = cardType;
      }
      this.getPreferApn();
    };
  }

  async initSim(slotId: number) {
    if (slotId < 0 || slotId > sim.getMaxSimCount()) {
      return false;
    }
    this.cardType = slotId;
    AppStorage.setOrCreate('cardType', slotId);
    let info = await sim.getSimAccountInfo(this.cardType)
    if (info) {
      this.simId = info.simId;
      LogUtils.i(TAG, 'initSim, slotId:' + slotId + ', simId:' + this.simId)
      return true;
    }
    return false;
  }

  async getSelectApn() {
    if (this.cardType === -1) {
      return;
    }
    let icc = await sim.getSimIccId(this.cardType);
    await this.sharedPreferences.getFromPreferences('selectAPN_common_' + icc, -1)
      .then((data: preferences.ValueType) => {
        if (data !== -1) {
          this.selectCommon = data as number;
          AppStorage.setOrCreate('selectId', this.selectCommon);
        }
      });
  }

  async getSelectApnVal() {
    LogUtils.i(TAG, 'getSelectApnVal_' + this.cardType);
    if (this.cardType === -1) {
      return -1;
    }
    let icc = await sim.getSimIccId(this.cardType);
    let data = await this.sharedPreferences.getFromPreferences('selectAPN_common_' + icc, -1);
    return data as number;
  }

  getSelectApnItem() {
    return this.dataList.find(item => item.id === this.selectCommon)
  }

  isNeedToSetDefaultApnCommon(cardType: number) {
    try {
      radio.getPrimarySlotId((error, value) => {
        if (error) {
          LogUtils.e(TAG, 'getPrimarySlotId error:' + JSON.stringify(error));
        } else {
          LogUtils.i(TAG, 'getPrimarySlotId data:' + JSON.stringify(value));
          this.setDefalutApnCommon(cardType, value);
        }
      });
    } catch (error) {
      LogUtils.i(TAG, 'getPrimarySlotId catch:' + JSON.stringify(error));
    }
  }

  private setDefalutApnCommon(cardType: number, value: number) {
    if (value === cardType && this.dataList.length > 0) {
      this.selectApnCommon(this.dataList[0].id);
    }
  }

  private setDefaultApnNameByCellularData() {
    isCellularDataEnabled()?.then((data: boolean) => {
      if (data) {
        // For Primary Sim Card to set default apn name.
        this.isNeedToSetDefaultApnCommon(this.cardType);
      }
    }).catch((error: BusinessError) => {
      LogUtils.i(TAG, 'isCellularDataEnabled error catch' + JSON.stringify(error));
    });
  }

  async selectApnCommon(value: number) {
    LogUtils.i(TAG, 'selectApnCommon_' + value);
    if (this.cardType === -1) {
      return;
    }
    if (value === this.selectCommon) {
      return;
    }
    this.selectCommon = value;
    AppStorage.setOrCreate('selectId', this.selectCommon);
    let icc = await sim.getSimIccId(this.cardType);
    await this.sharedPreferences.saveToPreferences('selectAPN_common_' + icc, this.selectCommon);
    // select a APN means user wants to set as prefer.
    this.setPreferApn();
    // 选择apn打点
    ReportUtil.getInstance().reportSelectApn(this.selectCommon, this.cardType);
  }

  public setPreferApn() {
    sim.getSimAccountInfo(this.cardType).then(async (data: sim.IccAccountInfo) => {
      const simId = Number(data['simId']);
      if (simId === undefined || null) {
        return;
      }
      LogUtils.i(TAG, 'this.selectCommon:' + JSON.stringify(this.selectCommon));
      await this.dataStorage.initData();
      await this.dataStorage.preferApnDataUpdate(simId, this.selectCommon);
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, `getSimAccountInfo err, promise: err->${JSON.stringify(err)}`);
    });
  }

  public getPreferApn() {
    sim.getSimAccountInfo(this.cardType).then(async (data: sim.IccAccountInfo) => {
      const simId = Number(data['simId']);
      if (simId === undefined || null) {
        return;
      }
      await this.dataStorage.initData();
      this.dataStorage.preferApnDataQuery(simId).then((value) => {
        LogUtils.i(TAG, 'preferAPN value(profileId):' + value);
        if (value === -1) {
          this.setDefaultApnNameByCellularData();
        } else {
          this.selectCommon = value;
          AppStorage.setOrCreate('selectId', this.selectCommon);
          sim.getSimIccId(this.cardType).then((icc) => {
            this.sharedPreferences.saveToPreferences('selectAPN_common_' + icc, this.selectCommon);
          })
        }
      });
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, `getSimAccountInfo err, promise: err->${JSON.stringify(err)}`);
    });
  }

  async getMccmnc() {
    LogUtils.i(TAG, '[slotId]' + JSON.stringify(this.cardType));
    await sim.getSimOperatorNumeric(this.cardType).then(res => {
      this.mccmnc = res;
      LogUtils.i(TAG, '[getSimOperatorNumeric]' + JSON.stringify(res));
    })
  }

  getDataShareInfo(data: DataShareResultSet) {
    let dataArr: DataListClass[] = [];
    let dunDataArr: DataListClass[] = [];
    // 获取是否显示5g的开关
    const isForbidden = systemParameterEnhance.getSync(EFL_FORBIDDEN, 'false') === 'true';
    data.goToFirstRow();
    do {
      // 禁止显示5G,是预制APN且name,apn包含5g字样,则进行过滤
      if (isForbidden && data.getLong(DataShareEnum.edited) === 0 &&
        this.isItemEfl(data.getString(DataShareEnum.profile_name), data.getString(DataShareEnum.apn))) {
        // 判断是预制APN且包含5G,数据进行过滤不显示
        LogUtils.i(TAG, `APN data has been filtered: ${data.getString(DataShareEnum.profile_name)}`)
        continue;
      }
      let pushData: DataListClass = new DataListClass();
      pushData.id = data.getLong(DataShareEnum.profile_id);
      pushData.title = data.getString(DataShareEnum.profile_name);
      pushData.apnTypes = data.getString(DataShareEnum.apn_types);
      pushData.msg = data.getString(DataShareEnum.apn);
      pushData.isDefault = data.getLong(DataShareEnum.edited);
      if (pushData.apnTypes === 'dun') {
        dunDataArr.push(pushData);
      } else {
        dataArr.push(pushData);
      }
    } while (data.goToNextRow());
    this.sortArr(dataArr);
    this.sortArr(dunDataArr);
    dataArr = dataArr.concat(dunDataArr);
    return dataArr;
  }

  isItemEfl(name: string, apn: string) {
    // 判断非空且包含efl信息
    return !this.isEmpty(name) && name.toLowerCase().indexOf(EFL_WORD) !== -1 ||
      !this.isEmpty(apn) && apn.toLowerCase().indexOf(EFL_WORD) !== -1
  }

  isEmpty(str: string): boolean {
    return str === undefined || str === '';
  }

  async getAllApnList() {
    if (this.mccmnc === '') {
      return;
    }
    let res: DataListClass[] = [];
    let mmsres: DataListClass[] = [];
    await this.dataStorage.initData();
    let da = new dataSharePredicates.DataSharePredicates();
    da.equalTo('mccmnc', this.mccmnc)
      .and()
      .beginWrap()
      .beginWrap()
      .beginWrap()
      .like('apn_types', '%default%')
      .or()
      .like('apn_types', '%mms%')
      .or()
      .like('apn_types', '%dun%')
      .or()
      .like('apn_types', '%bip0%')
      .or()
      .equalTo('apn_types', '')
      .endWrap()
      .and()
      .equalTo('edited', 0)
      .endWrap()
      .or()
      .equalTo('edited', 1)
      .endWrap();
    let data = await this.dataStorage.dataQuery(this.simId, da);
    if (data && data.rowCount !== 0) {
      res = res.concat(this.getDataShareInfo(data));
      mmsres = mmsres.concat(res);
      this.setMmsApnDataList(mmsres);
      this.setDefaultApnDataList(res);
    } else {
      this.mmsDataList = [];
      this.dataList = [];
    }
    data?.close();
  }

  private setDefaultApnDataList(res: DataListClass[]) {
    for (let i = 0; i < res.length; i++) {
      const ele = res[i];
      if (regexMms.test(ele.apnTypes) && !regexDefault.test(ele.apnTypes)) {
        res.splice(i, 1);
        i--;
      }
    }
    this.dataList = res;
  }

  private setMmsApnDataList(mmsres: DataListClass[]) {
    for (let i = 0; i < mmsres.length; i++) {
      let ele = mmsres[i];
      if (!regexMms.test(ele.apnTypes) || regexDefault.test(ele.apnTypes)) {
        mmsres.splice(i, 1);
        i--;
      }
    }
    this.mmsDataList = mmsres;
  }

  sortArr(arr: DataListClass[]) {
    arr.sort((a: DataListClass, b: DataListClass) => {
      let compare = a.isDefault - b.isDefault;
      if (compare !== 0) {
        return compare;
      }
      const titleA = a.title.toUpperCase();
      const titleB = b.title.toUpperCase();
      const msgA = a.msg.toUpperCase();
      const msgB = b.msg.toUpperCase();
      if (titleA < titleB) {
        return -1;
      }
      if (titleA > titleB) {
        return 1;
      }
      if (titleA === titleB) {
        if (msgA < msgB) {
          return -1;
        }
        if (msgA > msgB) {
          return 1;
        }
      }
      return 0;
    })
    return arr;
  }

  async dataReset() {
    await this.dataStorage.initData();
    await this.dataStorage.dataReset(this.simId);
    await this.getAllApnList();
    this.isNeedToSetDefaultApnCommon(this.cardType);
    return true;
  }

  async deleteData(profileId: number) {
    let icc = await sim.getSimIccId(this.cardType);
    await this.sharedPreferences.getFromPreferences('selectAPN_common_' + icc, -1)
      .then((data: preferences.ValueType) => {
        if (data === profileId) {
          this.sharedPreferences.saveToPreferences('selectAPN_common_' + icc, -1);
        }
      });
    await this.dataStorage.dataDelete(profileId);
  }
}