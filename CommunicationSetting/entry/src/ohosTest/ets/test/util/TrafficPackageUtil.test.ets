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
import { ArgumentMatchers, describe, expect, it, MockKit, when } from "@ohos/hypium";
import {
  AllPackageUsageInterface,
  PackageStartAndDateInterface,
  PackageUsageInterface,
  SLOT_1,
  TrafficPackageUtil
} from "../../../../main/ets/util/TrafficPackageUtil";
import StringUtil from "../../../../main/ets/util/StringUtil";
import myCommon from '@ohos.app.ability.common';
import AppInfoListPresenter from "../../../../main/ets/presenter/AppInfoListPresenter";
import { LogUtil } from "../../../../main/ets/util/LogUtil";
import { TAG_NAME } from "../../../../main/ets/constants/CommonConstants";

export default function TrafficPackageTest() {
  describe('TrafficPackageUtilUtilTest_testSuite', () => {
    it('AppStorageUtilsTest_getMaxDayOfYearMonth', 0, () => {
      let now = new Date();
      now.setHours(0, 0, 0, 0);
      expect(TrafficPackageUtil.getMaxDayOfYearMonth(now.getFullYear(), now.getMonth()))
        .assertLargerOrEqual(now.getDate());
    });

    it('should_return_correct_start_and_end_date_when_startDay_is_undefined', 0, () => {
      let minDuration: number = 7;
      let startDay: number | undefined = undefined;
      let result: PackageStartAndDateInterface = TrafficPackageUtil.getPackageStartAndDate(minDuration, startDay);
      let currentDate: Date = new Date();
      let dayOfMonth: number = currentDate.getDate();
      let month: number = currentDate.getMonth();
      let year: number = currentDate.getFullYear();
      let expectedStartDate: Date = new Date(year, month, 1);
      let expectedEndDate: Date = new Date(year, month, Math.max(dayOfMonth + 1, 1 + minDuration));

      expect(result.startDate.getTime()).assertEqual(expectedStartDate.getTime());
      expect(result.endDate.getTime()).assertEqual(expectedEndDate.getTime());
    });

    it('should_return_correct_start_and_end_date_when_startDay_is_set_and_today_is_startDay', 0, () => {
      let minDuration: number = 7;
      let startDay: number = 10;
      let result: PackageStartAndDateInterface = TrafficPackageUtil.getPackageStartAndDate(minDuration, startDay);
      let currentDate: Date = new Date();
      let dayOfMonth: number = currentDate.getDate();
      let month: number = currentDate.getMonth();
      let year: number = currentDate.getFullYear();

      let maxDay = TrafficPackageUtil.getMaxDayOfYearMonth(year, month);
      let realStartDay = Math.min(startDay, maxDay);
      let expectedStartDate: Date;
      if (dayOfMonth < realStartDay) { // 套餐开始日期为15号但是今天是5号的情况,也就是从上个月开始算
        if (month === 0) { // 当前月份为1月的情况，套餐开始月份则为上一年的12月startDay号
          expectedStartDate = new Date(year - 1, 11, realStartDay);
        } else {
          let prevMaxDay = TrafficPackageUtil.getMaxDayOfYearMonth(year, month - 1);
          expectedStartDate = new Date(year, month - 1, Math.min(startDay, prevMaxDay));
        }
      } else {
        expectedStartDate = new Date(year, month, realStartDay);
      }
      let expectedEndDate = new Date(expectedStartDate);
      expectedEndDate.setDate(expectedStartDate.getDate() + minDuration);
      let todayEndDate = new Date(year, month, dayOfMonth + 1);
      expectedEndDate = expectedEndDate >= todayEndDate ? expectedEndDate : todayEndDate;

      expect(result.startDate.getTime()).assertEqual(expectedStartDate.getTime());
      expect(result.endDate.getTime()).assertEqual(expectedEndDate.getTime());
    });

    it('should_return_correct_start_and_end_date_when_startDay_is_set_and_today_is_before_startDay', 0, () => {
      let minDuration: number = 7;
      let startDay: number = 1;
      let result: PackageStartAndDateInterface = TrafficPackageUtil.getPackageStartAndDate(minDuration, startDay);
      let currentDate: Date = new Date();
      let dayOfMonth: number = currentDate.getDate();
      let month: number = currentDate.getMonth();
      let year: number = currentDate.getFullYear();
      if (month === 0) {
        let maxDay = TrafficPackageUtil.getMaxDayOfYearMonth(year - 1, 11);
        let expectedStartDate: Date = new Date(year - 1, 11, startDay);
        let expectedEndDate: Date = new Date(year, month, Math.max(startDay + minDuration, maxDay + dayOfMonth));
        expect(result.startDate.getTime()).assertEqual(expectedStartDate.getTime());
        expect(result.endDate.getTime()).assertEqual(expectedEndDate.getTime());
      } else {
        let maxDay = TrafficPackageUtil.getMaxDayOfYearMonth(year, month);
        let realStartDay = Math.min(maxDay, startDay);
        let expectedStartDate: Date =
          new Date(year, (startDay > dayOfMonth ? month - 1 : month), realStartDay);
        let expectedEndDate = new Date(expectedStartDate);
        expectedEndDate.setDate(expectedStartDate.getDate() + minDuration);
        let todayEndDate = new Date(year, month, dayOfMonth + 1);
        expectedEndDate = expectedEndDate >= todayEndDate ? expectedEndDate : todayEndDate;
        expect(result.startDate.getTime()).assertEqual(expectedStartDate.getTime());
        expect(result.endDate.getTime()).assertEqual(expectedEndDate.getTime());
      }

    });


    it('getTrafficPackageUsageDetails', 0, async () => {
      let mockResult: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 100
      };
      let minDuration: number = 7;
      let appinfolistpresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(appinfolistpresenter, appinfolistpresenter.getAllAppTrafficsOfCellular);

      when(mockfunc)(ArgumentMatchers.any).afterReturn(mockResult);

      let result = await TrafficPackageUtil.getTrafficPackageUsageDetails(SLOT_1, minDuration);
      expect(result.usage.length).assertLargerOrEqual(minDuration);
      expect(result.totalFlow).assertLargerOrEqual(result.usage.length * 100);
      expect(result.simId).assertEqual(SLOT_1)
    });

    it('getTrafficPackageUsageDetailWithCallBack', 0, async () => {
      let mockResult: PackageUsageInterface = {
        startDate: 1,
        day: 1,
        flow: 100
      };
      let minDuration: number = 7;
      let appinfolistpresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(appinfolistpresenter, appinfolistpresenter.getAllAppTrafficsOfCellular);

      when(mockfunc)(ArgumentMatchers.any).afterReturn(mockResult);

      TrafficPackageUtil.getTrafficPackageUsageDetailWithCallBack(SLOT_1, minDuration, undefined,
        (result: AllPackageUsageInterface) => {
          expect(result.usage.length).assertLargerOrEqual(0);
          expect(result.totalFlow).assertLargerOrEqual(100);
          expect(result.simId).assertEqual(SLOT_1)
        }, (result: AllPackageUsageInterface) => {
          expect(result.usage.length).assertLargerOrEqual(0);
          expect(result.totalFlow).assertLargerOrEqual(100);
          expect(result.simId).assertEqual(SLOT_1)
        });

    });

    it('getAllTrafficYLabels', 0, () => {
      let minDuration: number = 7;
      let result = TrafficPackageUtil.getAllTrafficYLabels(minDuration, 1);
      expect(result.length).assertLargerOrEqual(minDuration);
      expect(result[0]).assertEqual('1');
      let today = new Date().getDate();
      expect(result[result.length - 1])
        .assertEqual(today >= minDuration ?
        StringUtil.convertResourceToString($r('app.string.today'), getContext() as myCommon.UIAbilityContext) :
        minDuration.toString())
    });

    it('isSameDayTest01', 0, () => {
      let date1 = new Date();
      let date2 = new Date();
      expect(TrafficPackageUtil.isSameDay(date1, date2)).assertTrue()
    });

    it('isSameDayTest02', 0, () => {
      let date1 = new Date();
      let date2 = new Date();
      date2.setDate(date2.getDate() + 1);
      expect(TrafficPackageUtil.isSameDay(date1, date2)).assertFalse()
    });
  })
}