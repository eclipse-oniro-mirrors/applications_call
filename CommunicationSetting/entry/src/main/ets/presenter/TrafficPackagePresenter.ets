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
import { LogUtil } from '../util/LogUtil';
import {
  AllPackageUsageInterface,
  LIMIT_TRAFFIC_NOSET,
  PackageConfigurationInterface,
  SLOT_1,
  START_DATE_NOSET,
  TrafficCommondInterface,
  TrafficPackageUtil
} from '../util/TrafficPackageUtil';
import { HashMap } from '@kit.ArkTS';
import { sim } from '@kit.TelephonyKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fetchFullKeyWord, QueryName, TAG_NAME } from '../constants/CommonConstants';
import SettingsDataService, { resType } from '../service/SettingsDataService';
import { settingsDataParam } from '../model/SettingsDataModel';

const TAG = 'TrafficPackagePresenter';
const MAX_RETRY_TIMES = 3;

export default class TrafficPackagePresenter {
  private static sInstance: TrafficPackagePresenter | undefined;
  private id2IdMap: HashMap<number, number> = new HashMap();
  private trafficConfigMap: HashMap<number, PackageConfigurationInterface> = new HashMap();
  private trafficPackageUsageMap: HashMap<number, AllPackageUsageInterface> = new HashMap();
  private isLoadingSimCardOne: boolean = false;
  private isLoadingSimCardTwo: boolean = false;
  private retryGetSimIdTimes = 0;
  private timeoutId: number = -1;

  public static getInstance(): TrafficPackagePresenter {
    if (TrafficPackagePresenter.sInstance == null) {
      LogUtil.info(TAG, 'TrafficPackagePresenter getInstance');
      TrafficPackagePresenter.sInstance = new TrafficPackagePresenter();
    }
    return TrafficPackagePresenter.sInstance;
  }


  isLoadingSlotIdData(slotId: number): boolean {
    if (slotId === SLOT_1) {
      return this.isLoadingSimCardOne;
    } else {
      return this.isLoadingSimCardTwo;
    }
  }

  setSlotIdStartLoadingStatus(slotId: number): void {
    if (slotId === SLOT_1) {
      this.isLoadingSimCardOne = true;
    } else {
      this.isLoadingSimCardTwo = true;
    }
  }

  setSlotIdFinishLoadingStatus(slotId: number): void {
    if (slotId === SLOT_1) {
      this.isLoadingSimCardOne = false;
    } else {
      this.isLoadingSimCardTwo = false;
    }
  }

  querySimId(slotId: number = 0, callback: Function): void {
    let simId = 0;
    if (this.id2IdMap.hasKey(slotId)) {
      simId = this.id2IdMap.get(slotId);
      LogUtil.info(TAG, `query simid use cache`)
      callback(simId);
    } else {
      sim.getSimAccountInfo(slotId).then(accountInfo => {
        this.retryGetSimIdTimes = 0;
        simId = accountInfo.simId;
        LogUtil.info(TAG, `query simid result success`)
        callback(simId);
        this.id2IdMap.set(slotId, simId)
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG, `query simid fail, error code: ${err.code}, message: ${err.message}.`)
        if (this.retryGetSimIdTimes === MAX_RETRY_TIMES) {
          this.retryGetSimIdTimes = 0;
          callback(simId);
        } else {
          LogUtil.error(TAG, `query simid fail, retry querySimId`)
          if (this.timeoutId !== -1) {
            clearTimeout(this.timeoutId);
          }
          this.timeoutId = setTimeout(() => {
            this.retryGetSimIdTimes = this.retryGetSimIdTimes + 1;
            this.querySimId(slotId, callback);
          }, 500);
        }
      });
    }
  }

  queryTrafficConfig(simId: number = 0, callback: Function): void {
    if (this.trafficConfigMap.hasKey(simId)) {
      let config = this.trafficConfigMap.get(simId);
      // 起始日期待定：this.startDate = config.monthlyStartDate === START_DATE_NOSET ? undefined : config.monthlyStartDate;
      callback(config);
    } else {
      let actionData: settingsDataParam = {};
      actionData.KEYWORD = TAG_NAME + simId;
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(actionData, (res: resType) => {
        LogUtil.info(TAG, 'queryTrafficConfig' + JSON.stringify(res))
        let config = TrafficPackagePresenter.handleDBaseData(simId, res.abilityResult);
        this.trafficConfigMap.set(simId, config);
        callback(config);
      }, getContext(this));
    }
  }

  static handleDBaseData(simId: number, abilityResult?: settingsDataParam[]): PackageConfigurationInterface {
    let unlimitedTrafficEnable = 0;
    let monthlyLimitedTraffic = LIMIT_TRAFFIC_NOSET;
    let monthlyStartDate = START_DATE_NOSET;
    if (abilityResult) {
      abilityResult.forEach((resultObj) => {
        if (!resultObj.KEYWORD) {
          LogUtil.error(TAG, 'handleDBaseData error')
          return
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(simId, QueryName.unlimited_traffic_enable)) {
          unlimitedTrafficEnable = Number(resultObj.VALUE);
        } else if (resultObj.KEYWORD === fetchFullKeyWord(simId, QueryName.monthly_limited_traffic)) {
          monthlyLimitedTraffic = Number(resultObj.VALUE);
        } else if (resultObj.KEYWORD === fetchFullKeyWord(simId, QueryName.monthly_start_date)) {
          monthlyStartDate = Math.floor(Number(resultObj.VALUE));
        }
      })
    }
    return {
      unlimitedTrafficEnable: unlimitedTrafficEnable,
      monthlyLimitedTraffic: monthlyLimitedTraffic,
      monthlyStartDate: monthlyStartDate
    } as PackageConfigurationInterface;
  }

  queryCachedTrafficUseData(simId: number = 0): AllPackageUsageInterface | null {
    if (this.trafficPackageUsageMap.hasKey(simId)) {
      let useData = this.trafficPackageUsageMap.get(simId);
      return useData;
    } else {
      return null;
    }
  }

  refreshData(slotId: number, simId: number, startDay: number | undefined, callback: Function): void {
    TrafficPackageUtil.getTrafficPackageUsageDetails(simId, 7, startDay)
      .then((result: AllPackageUsageInterface) => {
        callback(result);
      })
  }

  cacheData(data: TrafficCommondInterface) {
    let slotId = data.idMap.slotId;
    let simId = data.idMap.simId;
    this.id2IdMap.set(slotId, simId);
    this.trafficConfigMap.set(simId, data.config);
    this.trafficPackageUsageMap.set(simId, data.usageInfo);
  }


  clearCacheData(slotId: number, simId: number): void {
    if (this.id2IdMap.hasKey(slotId)) {
      this.id2IdMap.remove(slotId);
    }
    if (this.trafficConfigMap.hasKey(simId)) {
      this.trafficConfigMap.remove(simId);
    }
    if (this.trafficPackageUsageMap.hasKey(simId)) {
      this.trafficPackageUsageMap.remove(simId);
    }
  }

  clearAllCacheData(): void {
    this.id2IdMap.clear();
    this.trafficConfigMap.clear();
    this.trafficPackageUsageMap.clear();
  }
}