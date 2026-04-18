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
import {
  describe,
  beforeEach,
  afterEach,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import TrafficPackagePresenter from '../../../../main/ets/presenter/TrafficPackagePresenter';
import {
  LIMIT_TRAFFIC_NOSET,
  PackageConfigurationInterface,
  SLOT_1,
  SLOT_2,
  START_DATE_NOSET,
  TrafficCommondInterface
} from '../../../../main/ets/util/TrafficPackageUtil';
import { fetchFullKeyWord, QueryName } from '../../../../main/ets/constants/CommonConstants';
import SettingsDataService, { resType } from '../../../../main/ets/service/SettingsDataService';

export default function TrafficPackagePresenterTest() {
  describe('getInstance_testSuite', () => {
    let presenter: TrafficPackagePresenter;
    let cacheData: TrafficCommondInterface;
    beforeEach(() => {
      presenter = TrafficPackagePresenter.getInstance();
      cacheData = {
        idMap: {
          slotId: 0,
          simId: 0
        },
        config: {
          unlimitedTrafficEnable: 1,
          monthlyLimitedTraffic: 100,
          monthlyStartDate: 1
        },
        usageInfo: {
          usage: [{
            startDate: 1,
            day: 1,
            flow: 100,
          }],
          totalFlow: 100,
          simId: 0
        }
      }
    });
    afterEach(() => {

    });

    it('TrafficPackagePresenterTest_getInstance', 0, () => {
      expect(typeof presenter).assertEqual(typeof TrafficPackagePresenter.getInstance());
    });

    it('TrafficPackagePresenterTest_checkSlotIdStatus', 0, () => {
      presenter.setSlotIdStartLoadingStatus(SLOT_1);
      expect(presenter.isLoadingSlotIdData(SLOT_1)).assertTrue();
      presenter.setSlotIdFinishLoadingStatus(SLOT_1);
      expect(presenter.isLoadingSlotIdData(SLOT_1)).assertFalse();

      presenter.setSlotIdStartLoadingStatus(SLOT_2);
      expect(presenter.isLoadingSlotIdData(SLOT_2)).assertTrue();
      presenter.setSlotIdFinishLoadingStatus(SLOT_2);
      expect(presenter.isLoadingSlotIdData(SLOT_2)).assertFalse();
    });

    it('TrafficPackagePresenterTest_querySimId01', 0, async () => {
      presenter.clearAllCacheData();
      presenter.cacheData(cacheData);
      presenter.querySimId(SLOT_1, (simId: number) => {
        expect(simId).assertEqual(cacheData.idMap.simId)
      })
    });

    it('TrafficPackagePresenterTest_queryTrafficConfig01', 0, async () => {
      presenter.clearAllCacheData();
      presenter.cacheData(cacheData);
      presenter.queryTrafficConfig(cacheData.idMap.slotId, (config: PackageConfigurationInterface) => {
        let cacheConfig = cacheData.config;
        expect(cacheConfig.unlimitedTrafficEnable).assertEqual(config.unlimitedTrafficEnable);
        expect(cacheConfig.monthlyLimitedTraffic).assertEqual(config.monthlyLimitedTraffic);
        expect(cacheConfig.monthlyStartDate).assertEqual(config.monthlyStartDate);
      })
    });

    it('TrafficPackagePresenterTest_queryTrafficConfig02', 0, async () => {
      presenter.clearAllCacheData();
      let mockResult: resType = {
        code: 0,
        abilityResult: [
          { KEYWORD: QueryName.unlimited_traffic_enable, VALUE: '1' },
          { KEYWORD: QueryName.monthly_limited_traffic, VALUE: '100' },
          { KEYWORD: QueryName.monthly_start_date, VALUE: '1' },
        ]
      };
      let mocker: MockKit = new MockKit();
      let instance = SettingsDataService.getInstance();
      let mockfunc: Function = mocker.mockFunc(instance, instance.querySettingsInfoByBeginningCondition);
      when(mockfunc)(ArgumentMatchers.any).afterReturn(mockResult);
      presenter.queryTrafficConfig(SLOT_1, (config: PackageConfigurationInterface) => {
        let cacheConfig = cacheData.config;
        expect(cacheConfig.unlimitedTrafficEnable).assertEqual(config.unlimitedTrafficEnable);
        expect(cacheConfig.monthlyLimitedTraffic).assertEqual(config.monthlyLimitedTraffic);
        expect(cacheConfig.monthlyStartDate).assertEqual(config.monthlyStartDate);
      });
      mocker.ignoreMock(instance, instance.querySettingsInfoByBeginningCondition);
      mocker.clear(instance);
    });

    it('TrafficPackagePresenterTest_handleDBaseData01', 0, async () => {
      presenter.clearAllCacheData();
      let simId = 0;
      let mockResult: resType = {
        code: 0,
        abilityResult: [
          { KEYWORD: fetchFullKeyWord(simId, QueryName.unlimited_traffic_enable), VALUE: '1' },
          { KEYWORD: fetchFullKeyWord(simId, QueryName.monthly_limited_traffic), VALUE: '100' },
          { KEYWORD: fetchFullKeyWord(simId, QueryName.monthly_start_date), VALUE: '1' },
        ]
      };
      let cacheConfig = cacheData.config;
      let config = TrafficPackagePresenter.handleDBaseData(simId, mockResult.abilityResult);
      expect(cacheConfig.unlimitedTrafficEnable).assertEqual(config.unlimitedTrafficEnable);
      expect(cacheConfig.monthlyLimitedTraffic).assertEqual(config.monthlyLimitedTraffic);
      expect(cacheConfig.monthlyStartDate).assertEqual(config.monthlyStartDate);
    });

    it('TrafficPackagePresenterTest_handleDBaseData02', 0, async () => {
      presenter.clearAllCacheData();
      let mockResult: resType = {
        code: 0,
        abilityResult: [
          { VALUE: '1' },
        ]
      };
      let simId = 100000;
      let config = TrafficPackagePresenter.handleDBaseData(simId, mockResult.abilityResult);
      expect(config.unlimitedTrafficEnable).assertEqual(0);
      expect(config.monthlyLimitedTraffic).assertEqual(LIMIT_TRAFFIC_NOSET);
      expect(config.monthlyStartDate).assertEqual(START_DATE_NOSET);
    });

    it('TrafficPackagePresenterTest_queryCachedTrafficUseData01', 0, async () => {
      presenter.clearAllCacheData();
      expect(presenter.queryCachedTrafficUseData(SLOT_1)).assertNull();
    });

    it('TrafficPackagePresenterTest_queryCachedTrafficUseData02', 0, async () => {
      presenter.clearAllCacheData();
      presenter.cacheData(cacheData);
      let useData = presenter.queryCachedTrafficUseData(SLOT_1);
      expect(useData?.simId).assertEqual(cacheData.usageInfo.simId);
      expect(useData?.totalFlow).assertEqual(cacheData.usageInfo.totalFlow);
      expect(JSON.stringify(useData?.usage)).assertEqual(JSON.stringify(cacheData.usageInfo.usage));
    });

    it('TrafficPackagePresenterTest_clearCacheData', 0, () => {
      presenter.cacheData(cacheData);
      presenter.clearCacheData(SLOT_1, SLOT_1);
      expect(presenter.queryCachedTrafficUseData(SLOT_1)).assertNull();
    });

  });
}
