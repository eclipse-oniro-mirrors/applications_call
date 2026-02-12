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
import { data, sim } from '@kit.TelephonyKit';
import { LogUtil } from './LogUtil';
import {
  EMITTER_PRELOAD_CALLBACK_EVENT_ID,
  EMITTER_PRELOAD_TOTAL_CALLBACK_EVENT_ID,
  SlotIdMapSimIdInterface,
  TAG_NAME
} from '../constants/CommonConstants';
import { settingsDataParam } from '../model/SettingsDataModel';
import SettingsDataService, { resType } from '../service/SettingsDataService';
import {
  AllPackageUsageInterface,
  START_DATE_NOSET,
  TrafficCommondInterface,
  TrafficPackageUtil
} from './TrafficPackageUtil';
import json from '@ohos.util.json';
import { emitter } from '@kit.BasicServicesKit';
import PageViewModel from '../viewmodel/PageViewModel';
import { taskpool } from '@kit.ArkTS';
import TrafficPackagePresenter from '../presenter/TrafficPackagePresenter';

const TAG = 'TrafficPackagePreloadUtil';

@Sendable
export class TrafficDataStroageUtil {
  public trafficeUseDetail?: string;
  public trafficeTotalUseDetail?: string;
  public isNeedPreload: boolean = true;
  private static sInstance: TrafficDataStroageUtil | undefined;

  public static getInstance(): TrafficDataStroageUtil {
    if (TrafficDataStroageUtil.sInstance == null) {
      LogUtil.info('TrafficDataStroageUtil', 'TrafficPackagePreloadUtil getInstance');
      TrafficDataStroageUtil.sInstance = new TrafficDataStroageUtil();
    }
    return TrafficDataStroageUtil.sInstance;
  }

  getTrafficeUseDetail(): TrafficCommondInterface | undefined {
    LogUtil.info('TrafficDataStroageUtil', `getTrafficeUseDetail: ${this.trafficeUseDetail}`)
    let trafficeUseDetail = this.trafficeUseDetail;
    if (trafficeUseDetail) {
      return JSON.parse(trafficeUseDetail) as TrafficCommondInterface;
    } else {
      return undefined;
    }
  }

  getTrafficeTotalUseDetail(): TrafficCommondInterface | undefined {
    LogUtil.info('TrafficDataStroageUtil', `getTrafficeUseDetail: ${this.trafficeTotalUseDetail}`)
    let trafficeTotalUseDetail = this.trafficeTotalUseDetail;
    if (trafficeTotalUseDetail) {
      return JSON.parse(trafficeTotalUseDetail) as TrafficCommondInterface;
    } else {
      return undefined;
    }
  }

  setTrafficeUseDetail(trafficeUseDetail: string) {
    this.trafficeUseDetail = trafficeUseDetail;
  }

  setTrafficeTotalUseDetail(trafficeTotalUseDetail: string) {
    this.trafficeTotalUseDetail = trafficeTotalUseDetail;
  }


}

export class TrafficPackagePreloadUtil {
  public static preQueryTrafficUseDetail(context: Context) {
    if (!PageViewModel.existSimCard()) {
      TrafficDataStroageUtil.getInstance().isNeedPreload = false;
      return
    }
    try {
      let trafficUseTask: taskpool.Task =
        new taskpool.Task(asyncQueryTrafficUseDetail, context, TrafficDataStroageUtil.getInstance());
      taskpool.execute(trafficUseTask, taskpool.Priority.HIGH).then((value: Object) => {
        LogUtil.info(TAG, 'taskpool end' + json.stringify(value))
      });
    } catch (e) {
      LogUtil.error(TAG, `taskpool: error code: ${e.code}, info: ${e.message}`);
    }
  }
}

@Concurrent
export async function asyncQueryTrafficUseDetail(context: Context, dataStorage: TrafficDataStroageUtil) {
  const TAG = 'TASKPOOLHANDLE';
  LogUtil.info(TAG, 'asyncQueryTrafficUseDetail start');
  let slotId = data.getDefaultCellularDataSlotIdSync();
  let simId = 0;
  try {
    let accountInfo = await sim.getSimAccountInfo(slotId);
    simId = accountInfo.simId;
  } catch (err) {
    LogUtil.error(TAG, `getSimAccountInfo failed  err: ${err?.code} message: ${err?.message}`);
  }
  //
  let actionData: settingsDataParam = {};
  actionData.KEYWORD = TAG_NAME + simId;
  LogUtil.error(TAG, `getSimAccountInfo con: ${json.stringify(actionData)}`);
  SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(actionData, (res: resType) => {
    LogUtil.info(TAG, 'queryTrafficConfig' + JSON.stringify(res))
    let configuration = TrafficPackagePresenter.handleDBaseData(simId, res.abilityResult);
    let startDate = configuration.monthlyStartDate === START_DATE_NOSET ? undefined : configuration.monthlyStartDate;
    TrafficPackageUtil.getTrafficPackageUsageDetailWithCallBack(simId, 7, startDate,
      (result: AllPackageUsageInterface) => {
        let resultData: TrafficCommondInterface = {
          idMap: {
            slotId: slotId,
            simId: simId
          } as SlotIdMapSimIdInterface,
          config: configuration,
          usageInfo: result
        }
        dataStorage.trafficeTotalUseDetail = JSON.stringify(resultData);
        let event: emitter.InnerEvent = {
          eventId: EMITTER_PRELOAD_TOTAL_CALLBACK_EVENT_ID,
          priority: emitter.EventPriority.HIGH
        };

        let eventData: emitter.EventData = {
          data: resultData
        }
        emitter.emit(event, eventData);
      }, (result: AllPackageUsageInterface) => {
        let resultData: TrafficCommondInterface = {
          idMap: {
            slotId: slotId,
            simId: simId
          } as SlotIdMapSimIdInterface,
          config: configuration,
          usageInfo: result
        }
        dataStorage.trafficeUseDetail = JSON.stringify(resultData);
        let event: emitter.InnerEvent = {
          eventId: EMITTER_PRELOAD_CALLBACK_EVENT_ID,
          priority: emitter.EventPriority.HIGH
        };
        let eventData: emitter.EventData = {
          data: resultData
        }
        emitter.emit(event, eventData);
        LogUtil.info(TAG, 'asyncQueryTrafficUseDetail end');
      })

  }, context);


}
