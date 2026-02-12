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
import { AppInfo } from './AppInfo';
import i18n from '@ohos.i18n';
import statistics from '@ohos.net.statistics';
import sim from '@ohos.telephony.sim';
import { LogUtil } from '../util/LogUtil';
import {
  ABROAD_BUNDLE_NAME,
  ABROAD_OLD_BUNDLE_NAME,
  ABROAD_TOTAL_UID,
  DAYS_29,
  DELAY,
  DROI_BUNDLE_NAME,
  DROI_OLD_BUNDLE_NAME,
  DROI_UID,
  DUARTION_DAY_30,
  DUARTION_HOUR_24,
  HOURS_23,
  MILLISECOND_1000
} from '../constants/CommonConstants';
import { PackageUsageInterface } from '../util/TrafficPackageUtil';
import { MonthOrDailyDataResult } from '../pagesComponents/ChartComponent';

/**
 * Binds data to components and provides interfaces.
 */
const TAG: string = 'PageViewModel'
const DAY_SECOND = 60 * 60 * 24;
const transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latin');
const transliterator2: i18n.Transliterator = i18n.Transliterator.getInstance('Latin-ASCII');

export class PageViewModel {
  appTrafficCompare(a: AppInfo, b: AppInfo) {
    if (!a || !b) {
      LogUtil.error('appTrafficCompare', 'invalid parameter in app traffic compare');
      return 0;
    }
    if (a.flow !== b.flow) {
      return b.flow - a.flow;
    }
    return a.label.localeCompare(b.label);
  }

  sysListCompare(a: [number, number], b: [number, number]) {
    if (!a || !b) {
      LogUtil.error('sysListCompare', 'invalid parameter in app sysList compare');
      return 0;
    }
    if (a[1] !== b[1]) {
      return b[1] - a[1];
    }
    return b[0] - a[0];
  }

  appAlphabetCompare(a: AppInfo, b: AppInfo) {
    if (!a || !b) {
      LogUtil.error('appAlphabetCompare', 'invalid parameter in app alphabet compare');
      return 0;
    }
    if (!transliterator || !transliterator2) {
      LogUtil.error('appAlphabetCompare', 'transliterator is null');
      return 0;
    }
    let aLabel = transliterator.transform(a.label);
    let aLabelTrans = transliterator2.transform(aLabel).toUpperCase();
    let bLabel = transliterator.transform(b.label);
    let bLabelTrans = transliterator2.transform(bLabel).toUpperCase();
    return aLabelTrans.localeCompare(bLabelTrans);
  }

  getFirstLetter(label: string) {
    if (!transliterator || !transliterator2) {
      LogUtil.error('getFirstLetter', 'transliterator is null');
      return '#';
    }
    let aLabel = transliterator.transform(label);
    let aLabelTrans = transliterator2.transform(aLabel);
    if (!aLabelTrans) {
      return '#';
    }
    if (!/^[a-zA-Z]$/.test(aLabelTrans[0])) {
      return '#';
    }
    return aLabelTrans[0].toUpperCase();
  }

  hasTwoSimCard() {
    if (sim.hasSimCardSync(0) && sim.hasSimCardSync(1)) {
      return true;
    }
    return false;
  }

  existSimCard() {
    if (sim.hasSimCardSync(0) || sim.hasSimCardSync(1)) {
      return true;
    }
    return false;
  }

  async getAppFlow(bundleName: string, networkType: number, uid: number, duration: number,
    slotId: number, requestTimes: number): Promise<MonthOrDailyDataResult> {
    let simId = 0;
    try {
      let accountInfo = await sim.getSimAccountInfo(slotId);
      simId = accountInfo.simId;
    } catch (err) {
      LogUtil.error(TAG,
        `slot id : ${slotId}, sim card info failed, promise: err->${err?.code} message: ${err?.message}`);
    }
    let flowDuration = this.getAppFlowDuration(duration);
    let network: statistics.NetworkInfo = {
      type: networkType,
      startTime: flowDuration.startTime,
      endTime: flowDuration.endTime,
      simId: simId,
    };
    const uids = [uid];
    if (bundleName === DROI_BUNDLE_NAME || bundleName === DROI_OLD_BUNDLE_NAME) {
      uids.push(DROI_UID);
    }
    if (bundleName === ABROAD_BUNDLE_NAME || bundleName === ABROAD_OLD_BUNDLE_NAME) {
      uids.push(ABROAD_TOTAL_UID);
    }
    let result: MonthOrDailyDataResult = {
      networkType: networkType,
      requestTimes: requestTimes,
      datesList: [],
      chartDate: []
    };
    try {
      let infoSequenceArray: statistics.NetStatsInfoSequence[] = [];
      for (let uid of uids) {
        let infoSequence = await statistics.getTrafficStatsByUidNetwork(uid, network);
        infoSequenceArray.push(infoSequence);
      }
      result = this.handleGetAppFlowResult(infoSequenceArray, duration, networkType, requestTimes);
    } catch (err) {
      LogUtil.error(TAG, ` ${uids.toString()} flow add error code: ${err?.code} message: ${err?.message}`);
    }
    return result;
  }

  getAppFlowDuration(duration: number): AppFlowDurationInterface {
    let startDate: Date = new Date();
    let endDate: Date = new Date();
    let now = new Date();
    if (duration === DUARTION_DAY_30) {
      endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
      startDate = new Date(endDate);
      startDate.setDate(endDate.getDate() - DUARTION_DAY_30);
    } else {
      endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      endDate.setHours(now.getHours() + 1, 0, 0);
      startDate = new Date(endDate);
      startDate.setHours(endDate.getHours() - DUARTION_HOUR_24, 0, 0);
    }
    let startTime = Math.floor(startDate.getTime() / MILLISECOND_1000);
    let endTime = Math.floor(endDate.getTime() / MILLISECOND_1000);
    LogUtil.info(TAG, `get app flow duration: ${duration}, startTime:${startTime}, endData: ${endTime}`)
    return { startTime: startTime, endTime: endTime };
  }

  private handleGetAppFlowResult(infoSequenceArray: statistics.NetStatsInfoSequence[], duration: number,
    networkType: number, requestTimes: number): MonthOrDailyDataResult {
    if (duration === DUARTION_DAY_30) {
      return this.handleGetMonthlyTrafficResult(infoSequenceArray, networkType, requestTimes);
    } else {
      return this.handleGetDailyTrafficResult(infoSequenceArray, networkType, requestTimes);
    }
  }

  private handleGetMonthlyTrafficResult(infoSequenceArray: statistics.NetStatsInfoSequence[], networkType: number,
    requestTimes: number): MonthOrDailyDataResult {
    let map = new Map<string, number>();
    let today = new Date();
    let fromDay = new Date(today.getFullYear(), today.getMonth(), today.getDate() - DAYS_29);
    let chartDate: number[] = [];
    for (let i = 0; i < DUARTION_DAY_30; i++) {
      let day = new Date(fromDay.getFullYear(), fromDay.getMonth(), fromDay.getDate() + i);
      map.set(day.toLocaleDateString(), 0);
      chartDate.push(day.getTime());
    }
    infoSequenceArray.forEach((infoSequence) => {
      infoSequence.forEach((info) => {
        let time = new Date(info.startTime * MILLISECOND_1000);
        let traffic = info.info.rxBytes + info.info.txBytes;
        let oldTraffic = map.get(time.toLocaleDateString());
        if (!map.has(time.toLocaleDateString())) {
          LogUtil.warn(TAG, `monthly abnormal length: ${traffic}, date: ${time.toLocaleDateString()},time = ${time}`);
        }
        if (oldTraffic) {
          traffic += oldTraffic;
        }

        map.set(time.toLocaleDateString(), traffic);
      });
    })
    let datesList: number[][] = [];
    map.forEach((value, key) => {
      let day = new Date(key);
      datesList.push([day.getDate(), value]);
    });
    return {
      networkType: networkType,
      requestTimes: requestTimes,
      datesList: datesList,
      chartDate: chartDate
    };
  }

  private handleGetDailyTrafficResult(infoSequenceArray: statistics.NetStatsInfoSequence[], networkType: number,
    requestTimes: number): MonthOrDailyDataResult {
    let map = new Map<string, number>();
    let today = new Date();
    let fromDay = new Date(today.getFullYear(), today.getMonth(), today.getDate(), today.getHours() - HOURS_23);
    let chartDate: number[] = [];
    for (let i = 0; i < DUARTION_HOUR_24; i++) {
      let day = new Date(fromDay.getFullYear(), fromDay.getMonth(), fromDay.getDate(), fromDay.getHours() + i);
      map.set(day.getHours().toString(), 0);
      chartDate.push(day.getTime());
    }
    infoSequenceArray.forEach((infoSequence) => {
      infoSequence.forEach((info) => {
        let time = new Date(info.startTime * MILLISECOND_1000);
        let traffic = info.info.rxBytes + info.info.txBytes;
        let oldTraffic = map.get(time.getHours().toString());
        if (!map.has(time.getHours().toString())) {
          LogUtil.warn(TAG, `daily abnormal length: ${traffic}, date: ${time.getHours().toString()}, time = ${time}`);
        }
        if (oldTraffic) {
          traffic += oldTraffic;
        }
        map.set(time.getHours().toString(), traffic);
      });
    })
    let datesList: number[][] = [];
    map.forEach((value, key) => {
      let hour = Number.parseInt(key);
      datesList.push([hour, value]);
    });
    return {
      networkType: networkType,
      requestTimes: requestTimes,
      datesList: datesList,
      chartDate: chartDate
    };
  }

  traficeUseCompare(a: PackageUsageInterface, b: PackageUsageInterface) {
    if (!a || !b) {
      LogUtil.error('appAlphabetCompare', 'invalid parameter in app alphabet compare');
      return 0;
    }
    return a.startDate - b.startDate;
  }

}

let pageViewModel = new PageViewModel();

export default pageViewModel as PageViewModel;

interface AppFlowDurationInterface {
  startTime: number;
  endTime: number;
}