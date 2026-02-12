/*
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
import {
  fetchFullKeyWord,
  QueryName,
  ResultCode,
  ShowReminder,
  SlotId,
  TAG_NAME,
  UnlimitedEnable
} from '../constants/CommonConstants';
import SettingsDataService, { resType } from '../service/SettingsDataService';
import { data, sim } from '@kit.TelephonyKit';
import { LogUtil } from '../util/LogUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import PageViewModel from '../viewmodel/PageViewModel';
import { settingsDataParam } from '../model/SettingsDataModel';
import { LIMIT_TRAFFIC_NOSET } from '../util/TrafficPackageUtil';

const TAG = 'TrafficController';

export default class TrafficController {
  public static getReminderName(slotId: number) {
    if (slotId === SlotId.SLOT_1) {
      return ShowReminder.REMINDER1;
    }
    return ShowReminder.REMINDER2;
  }

  /**
   * 设置每张卡是否展示限额提醒
   * */
  showReminders() {
    let slotIds: number[] = [];
    if (PageViewModel.hasTwoSimCard()) {
      slotIds = [SlotId.SLOT_1, SlotId.SLOT_2];
    } else if (PageViewModel.existSimCard()) {
      slotIds = [data.getDefaultCellularDataSlotIdSync()];
    }
    slotIds.forEach((slotId) => {
      this.setShowReminder(slotId);
    })
  }

  private setShowReminder(slotId: number) {
    sim.getSimAccountInfo(slotId).then(accountInfo => {
      let simId = accountInfo?.simId ?? 0;
      let actionData: settingsDataParam = {
        KEYWORD: TAG_NAME + simId
      };
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(actionData, (res: resType) => {
        if (res.code === ResultCode.FAILURE || res.abilityResult.length <= 0) {
          AppStorage.setOrCreate<boolean>(TrafficController.getReminderName(slotId), false);
          return;
        }
        let unlimitedEnable: boolean = false;
        let monthlyLimitedEnale: boolean = false;
        for (let resultObj of res.abilityResult) {
          if (!resultObj.KEYWORD) {
            LogUtil.error(TAG, 'getDataPlanSettingsFromDB error')
            continue;
          }
          if (resultObj.KEYWORD === fetchFullKeyWord(simId, QueryName.unlimited_traffic_enable)) {
            unlimitedEnable = resultObj.VALUE === UnlimitedEnable.UNLIMITED_OPEN ? true : false;
            continue;
          }
          if (resultObj.KEYWORD === fetchFullKeyWord(simId, QueryName.monthly_limited_traffic)) {
            monthlyLimitedEnale = resultObj.VALUE !== LIMIT_TRAFFIC_NOSET.toString() ? true : false;
            continue;
          }
        }
        let showReminder = !unlimitedEnable && monthlyLimitedEnale;
        AppStorage.setOrCreate<boolean>(TrafficController.getReminderName(slotId), showReminder);
      }, getContext(this));
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, `get sim id failed, err.code: ${err.code}, err.msg: ${err.message}`);
    })
  }
}