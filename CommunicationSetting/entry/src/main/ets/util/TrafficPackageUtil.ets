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
import { SlotIdMapSimIdInterface } from '../constants/CommonConstants';
import AppInfoListPresenter from '../presenter/AppInfoListPresenter';
import { LogUtil } from './LogUtil';
import StringUtil from './StringUtil';
import myCommon from '@ohos.app.ability.common';
import { HashMap } from '@kit.ArkTS';

const TAG = 'TrafficPackageUtil';

/**
 * Card slot 1.
 */
export const SLOT_1 = 0;

/**
 * Card slot 2.
 */
export const SLOT_2 = 1;

export const LIMIT_TRAFFIC_NOSET = -1;

export const START_DATE_NOSET = -1;

export interface PackageConfigurationInterface {
  unlimitedTrafficEnable: number;
  monthlyLimitedTraffic: number;
  monthlyStartDate: number;
}

export interface SimCardInfo {
  isSimCard: boolean;
  slotIndex: number;
  cardName: string;
}

export interface PackageUsageInterface {
  startDate: number;
  day: number;
  flow: number;
}

export interface PackageStartAndDateInterface {
  startDate: Date;
  endDate: Date;
}

export interface AllPackageUsageInterface {
  usage: PackageUsageInterface[];
  totalFlow: number,
  simId: number
}

export interface TrafficCommondInterface {
  config: PackageConfigurationInterface,
  usageInfo: AllPackageUsageInterface,
  idMap: SlotIdMapSimIdInterface
}

export enum PackageUsageStatus {
  PACKNONE = 0,
  PACKNORMALUSAGE = 1,
  PACKOUTLIMIT = 2,
}

export class TrafficDataCacheUtil {
  private static sInstance: TrafficDataCacheUtil | undefined;
  private dataCacheHashMap: HashMap<number, HashMap<string, PackageUsageInterface>> = new HashMap();

  public static getInstance(): TrafficDataCacheUtil {
    if (TrafficDataCacheUtil.sInstance == null) {
      LogUtil.info('TrafficDataCacheUtil', 'TrafficDataCacheUtil getInstance');
      TrafficDataCacheUtil.sInstance = new TrafficDataCacheUtil();
    }
    return TrafficDataCacheUtil.sInstance;
  }

  private getCacheKey(simId: number, startDate: number) {
    return simId.toString() + '_' + startDate.toString();
  }

  cacheAllUsageInfoData(usageInfo: AllPackageUsageInterface): void {
    if (usageInfo === null || usageInfo === undefined) {
      return;
    }
    let simId = usageInfo.simId;
    if (this.dataCacheHashMap.hasKey(simId) === false) {
      this.dataCacheHashMap.set(simId, new HashMap());
    }
    let simCacheHashMap = this.dataCacheHashMap.get(simId);
    usageInfo.usage.forEach((usage: PackageUsageInterface) => {
      let key = this.getCacheKey(simId, usage.startDate);
      simCacheHashMap.set(key, usage);
    })
  }

  cacheUsageInfoData(simId: number, usage: PackageUsageInterface): void {
    if (usage === null || usage === undefined) {
      return;
    }
    if (this.dataCacheHashMap.hasKey(simId) === false) {
      this.dataCacheHashMap.set(simId, new HashMap());
    }
    let simCacheHashMap = this.dataCacheHashMap.get(simId);
    let key = this.getCacheKey(simId, usage.startDate);
    simCacheHashMap.set(key, usage);
  }

  queryCachedUsageInfoData(simId: number, startDate: number): PackageUsageInterface | null {
    if (this.dataCacheHashMap.hasKey(simId) === false) {
      this.dataCacheHashMap.set(simId, new HashMap());
    }
    let simCacheHashMap = this.dataCacheHashMap.get(simId);
    let key = this.getCacheKey(simId, startDate);
    if (simCacheHashMap.hasKey(key)) {
      return simCacheHashMap.get(key);
    } else {
      return null;
    }
  }

  clearAllCachedData() {
    this.dataCacheHashMap.clear();
  }
}

export class TrafficPackageUtil {
  public static getMaxDayOfYearMonth(year: number, month: number): number {
    let date = new Date(year, month, 1);
    date.setMonth(date.getMonth() + 1);
    date.setDate(0);
    return date.getDate();
  }

  public static getPackageStartAndDate(minDuration: number, startDay?: number): PackageStartAndDateInterface {
    let currentDate = new Date();
    let dayOfMonth = currentDate.getDate();
    let month = currentDate.getMonth();
    let year = currentDate.getFullYear();
    let startDate: Date;
    let endDate: Date;
    LogUtil.info(TAG,
      `currentDate year:${currentDate.getFullYear()},
      month: ${currentDate.getMonth()},dayOfMonth: ${currentDate.getDate()}`)
    if (startDay === undefined) { // 没有设置套餐，从当月1号开始
      startDate = new Date(year, month, 1);
    } else {
      let maxDay = TrafficPackageUtil.getMaxDayOfYearMonth(year, month);
      let realStartDay = Math.min(startDay, maxDay);
      LogUtil.info(TAG, `realStartDay:${realStartDay}, dayOfMonth:${maxDay}`)
      if (dayOfMonth < realStartDay) { // 套餐开始日期为15号但是今天是5号的情况,也就是从上个月开始算
        if (month === 0) { // 当前月份为1月的情况，套餐开始月份则为上一年的12月startDay号
          startDate = new Date(year - 1, 11, realStartDay);
        } else {
          let prevMaxDay = TrafficPackageUtil.getMaxDayOfYearMonth(year, month - 1);
          startDate = new Date(year, month - 1, Math.min(startDay, prevMaxDay));
        }
      } else {
        startDate = new Date(year, month, realStartDay);
      }
    }
    let afterDate = new Date(startDate);
    afterDate.setDate(startDate.getDate() + minDuration);
    let todayEndDate = new Date(year, month, dayOfMonth + 1);
    endDate = afterDate >= todayEndDate ? afterDate : todayEndDate;
    LogUtil.info(TAG, `startDate :${startDate}, endDate: ${endDate}`)
    return ({ startDate: startDate, endDate: endDate });
  }

  static async getTrafficPackageUsageDetails(simId: number, minDuration: number,
    startDay?: number): Promise<AllPackageUsageInterface> {
    let startAndEndDate = TrafficPackageUtil.getPackageStartAndDate(minDuration, startDay);
    let startDate = startAndEndDate.startDate;
    let endDate = startAndEndDate.endDate;
    let packageUsages: PackageUsageInterface[] = [];
    let totalFlow = 0;
    let currentDate = new Date();
    let todayTimestamp = currentDate.setHours(0, 0, 0, 0);
    for (let date = startDate; date < endDate; date.setDate(date.getDate() + 1)) {
      let start = new Date(date);
      let end = new Date(date);
      end.setDate(date.getDate() + 1);
      let startTime = startDate.getTime();
      let cacheData = TrafficDataCacheUtil.getInstance().queryCachedUsageInfoData(simId, startTime);
      let result = {
        startDate: 0,
        day: 0,
        flow: 0
      } as PackageUsageInterface;
      if (cacheData != null && (startTime !== todayTimestamp)) {
        LogUtil.info(TAG, `get appTraffics data use Cache = ${startTime}`);
        result = cacheData;
      } else {
        LogUtil.info(TAG, `get appTraffics data not use Cache = ${startTime}`);
        result = await AppInfoListPresenter.getInstance().getAllAppTrafficsOfCellular(simId, start, end);
        if (startTime !== todayTimestamp) {
          TrafficDataCacheUtil.getInstance().cacheUsageInfoData(simId, result);
        }
      }
      totalFlow = totalFlow + result.flow;
      packageUsages.push(result)
    }
    let result: AllPackageUsageInterface = {
      usage: packageUsages,
      totalFlow: totalFlow,
      simId: simId
    }
    return result;
  }

  static async getTrafficPackageUsageDetailWithCallBack(simId: number, minDuration: number,
    startDay?: number, totalCallBack?: Function, callBack?: Function) {
    let startAndEndDate = TrafficPackageUtil.getPackageStartAndDate(minDuration, startDay);
    let startDate = startAndEndDate.startDate;
    let endDate = startAndEndDate.endDate;
    let packageUsages: PackageUsageInterface[] = [];
    let totalFlow = 0;

    let result = await AppInfoListPresenter.getInstance().getAllAppTrafficsOfCellular(simId, startDate, endDate);
    let newResult: AllPackageUsageInterface = {
      usage: [],
      totalFlow: result.flow,
      simId: simId
    }
    if (totalCallBack) {
      LogUtil.info(TAG, 'totalCallBack end')
      totalCallBack(newResult);
    }

    const msPerDay = 1000 * 60 * 60 * 24;
    const date1Ms = startDate.getTime();
    const date2Ms = endDate.getTime();
    // 计算时间戳之差，并转换为天数
    const days = Math.abs(date2Ms - date1Ms) / msPerDay;
    for (let date = startDate; date < endDate; date.setDate(date.getDate() + 1)) {
      let start = new Date(date);
      let end = new Date(date);
      end.setDate(date.getDate() + 1);
      AppInfoListPresenter.getInstance().getAllAppTrafficsOfCellular(simId, start, end).then((result) => {
        totalFlow = totalFlow + result.flow;
        packageUsages.push(result)
        if (packageUsages.length === days) {
          let newResult: AllPackageUsageInterface = {
            usage: packageUsages,
            totalFlow: totalFlow,
            simId: simId
          }
          if (callBack) {
            callBack(newResult)
          }
        }
      });
    }
  }


  static getAllTrafficYLabels(minDuration: number, startDay?: number): string[] {
    let startAndEndDate = TrafficPackageUtil.getPackageStartAndDate(minDuration, startDay);
    let startDate = startAndEndDate.startDate;
    let endDate = startAndEndDate.endDate;
    let yLabels: string[] = [];
    let currentDate = new Date();
    let hasSameDay: boolean = false;
    for (let date = startDate; date < endDate; date.setDate(date.getDate() + 1)) {
      let start = new Date(date);
      if (hasSameDay === false && TrafficPackageUtil.isSameDay(currentDate, start)) {
        hasSameDay = true;
        yLabels.push(StringUtil.convertResourceToString($r('app.string.today'),
          getContext() as myCommon.UIAbilityContext))
      } else {
        yLabels.push(start.getDate().toString())
      }
    }
    return yLabels;
  }

  static isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth() &&
      date1.getDate() === date2.getDate();
  }
}