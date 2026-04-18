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
import { emitter } from '@kit.BasicServicesKit';
import {
  DataUnit,
  EMITTER_NOTICE_EVENT_ID,
  EMITTER_RESET_MONTH_LIMIT_NOTICE_EVENT_ID,
  fetchFullKeyWord,
  ONE_GB,
  ONE_MB,
  QueryName,
  ResultCode,
  SlotId,
  SlotIdMapSimIdInterface
} from '../constants/CommonConstants';
import { LIMIT_TRAFFIC_NOSET } from '../util/TrafficPackageUtil';
import { sim } from '@kit.TelephonyKit';
import { settingsDataParam } from '../model/SettingsDataModel';
import SettingsDataService, { resType } from '../service/SettingsDataService';
import { LogUtil } from '../util/LogUtil';
import StringUtil from '../util/StringUtil';
import { ValuesBucket } from '@kit.ArkData';
import DotUtil from '../util/Dot/DotUtils';
import { DialogOperationState } from '../util/Dot/DotCommon';
import TrafficController from '../Controller/TrafficController';
import { common } from '@kit.AbilityKit';
import SettingsSearchUtils from '../util/SettingsSearchUtils';
import { GlobalContext } from '../entryability/CommunicationSettingAbility';
import Intl from '@ohos.intl';
import I18n from '@ohos.i18n';
import PageViewModel from './PageViewModel';
import { cardInfo } from '../util/SimCradNameListener';

const TAG: string = 'TrafficDisplayViewModel'

export enum TrafficDispalyStatus {
  DEFAULT = -1,
  CLOSE = 0,
  OPEN = 1
}

export class TrafficDisplayViewModel {
  private context: Context =
    GlobalContext.getContext().getObject('rankPageContext') != null ?
      (GlobalContext.getContext().getObject('rankPageContext') as Context) : getContext();
  public currentSlotId = SlotId.DEFAULT;
  public currentSimId = 0;
  public trafficDisplayStatus: TrafficDispalyStatus = TrafficDispalyStatus.DEFAULT;

  constructor(slotId: number) {
    this.currentSlotId = slotId;
  }

  public addTrafficPackageOberser() {
    LogUtil.info(TAG, `addTrafficPackageOberser`)
    emitter.on({
      eventId: EMITTER_RESET_MONTH_LIMIT_NOTICE_EVENT_ID,
    }, (data: emitter.EventData) => {
      this.parseEmitData(data?.data?.params as SlotIdMapSimIdInterface);
    })
  }

  public removeTrafficPackageOberser() {
    LogUtil.info(TAG, `removeTrafficPackageOberser`)
    emitter.off(EMITTER_RESET_MONTH_LIMIT_NOTICE_EVENT_ID);
  }

  public async fetchTrafficDisplayStatus() {
    try {
      let accountInfo = await sim.getSimAccountInfo(this.currentSlotId);
      let simId = accountInfo?.simId ?? 0;
      this.currentSimId = simId;
      let actionData: settingsDataParam = {
        KEYWORD: fetchFullKeyWord(this.currentSimId, QueryName.show_traffic)
      };
      LogUtil.info(TAG, `fetch traffic display status: ${simId}`);
      SettingsDataService.getInstance().querySettingsInfo(actionData, (res: resType) => {
        this.handleTrafficDisplayDBData(res.abilityResult);
      }, this.context);
    } catch (e) {
      LogUtil.error(TAG, `fetch traffic display fail code: ${e?.code}, message: ${e?.message}`);
      this.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
    }
  }

  public changeCurrentSlotId(slotId: SlotId) {
    LogUtil.info(TAG, `change current slotId: ${slotId}`);
    this.currentSlotId = slotId;
    this.fetchTrafficDisplayStatus();
  }

  public haveSetMonthlyLimited(callback: (haveSet: boolean) => void) {
    let keyWord = fetchFullKeyWord(this.currentSimId, QueryName.monthly_limited_traffic);
    let actionData: settingsDataParam = {
      KEYWORD: keyWord
    };
    LogUtil.info(TAG, `query month limit value`);
    SettingsDataService.getInstance().querySettingsInfo(actionData, (res: resType) => {
      let abilityResult = res.abilityResult;
      if (res.abilityResult && res.abilityResult.length > 0) {
        abilityResult.forEach((resultObj) => {
          if (!resultObj.KEYWORD) {
            LogUtil.error(TAG, 'query month limit failed');
            callback(false);
            return;
          }
          LogUtil.info(TAG, `query month limit value key: ${resultObj.KEYWORD}, value: ${resultObj.VALUE}`);
          if (resultObj.KEYWORD === keyWord) {
            let haveSet: boolean = Number(resultObj.VALUE) !== LIMIT_TRAFFIC_NOSET;
            callback(haveSet);
          }
        })
      } else {
        callback(false);
      }

    }, this.context);
  }

  public saveTrafficDisplayStatus(isOn: boolean) {
    let actionData: settingsDataParam = {};
    let keyWord: string = fetchFullKeyWord(this.currentSimId, QueryName.show_traffic);
    actionData.KEYWORD = keyWord;
    let valueBucket: ValuesBucket = {
      'KEYWORD': keyWord,
      'VALUE': isOn ? '1' : '0'
    };
    LogUtil.info(TAG, `save show traffic value: ${isOn}`);
    SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: resType) => {
      if (res?.code === ResultCode.FAILURE) {
        LogUtil.error(TAG, 'save show traffic value error');
      }
    }, this.context);
    this.reportTrafficDisplaySwitchEvent(isOn);
  }

  public handleMonthlyLimitCancelEvent(dataLimitInput: string, dataLimitUnitSelected: DataUnit) {
    LogUtil.info(TAG, `click data limit cancel`);
    this.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
    DotUtil.getInstance()
      .reportPackageQuotaDialog(this.currentSimId, DialogOperationState.CANCEL, dataLimitInput, dataLimitUnitSelected);
  }


  public handleMonthlyLimitConfirmEvent(dataLimitInput: string, dataLimitUnitSelected: DataUnit) {
    let isReset: boolean = dataLimitInput.trim() === '';
    let value = Number(dataLimitInput);
    let actionData: settingsDataParam = {};
    if (isReset) {
      value = LIMIT_TRAFFIC_NOSET;
    } else {
      if (dataLimitUnitSelected === DataUnit.MB) {
        value = value * ONE_MB;
      } else {
        value = value * ONE_GB;
      }
    }
    let keyWord: string =
      fetchFullKeyWord(this.currentSimId, QueryName.monthly_limited_traffic);
    actionData.KEYWORD = keyWord;
    let valueBucket: ValuesBucket = {
      'KEYWORD': keyWord,
      'VALUE': value.toString()
    };
    LogUtil.info(TAG, `insert monthly limited traffic value: ${value}`);
    SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: resType) => {
      if (res?.code === ResultCode.FAILURE) {
        LogUtil.error(TAG, 'insert monthly limited traffic failed');
        this.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
        return;
      }
      if (res) {
        this.handleMonthlyLimitedTrafficData(isReset);
      }
    }, this.context)
    DotUtil.getInstance()
      .reportPackageQuotaDialog(this.currentSlotId, DialogOperationState.OK,
        isReset ? LIMIT_TRAFFIC_NOSET.toString() : dataLimitInput, dataLimitUnitSelected);
  }

  public checkNeedHandleChangeEvent(isOn: boolean): boolean {
    if (isOn && this.trafficDisplayStatus === TrafficDispalyStatus.OPEN) {
      return false;
    }
    if (!isOn && this.trafficDisplayStatus === TrafficDispalyStatus.CLOSE) {
      return false;
    }
    return true;
  }

  public getDialogTitle(): ResourceStr {
    if (PageViewModel.hasTwoSimCard()) {
      let dataLimitStr =
        StringUtil.convertResourceToString($r('app.string.data_limit'), this.context as common.UIAbilityContext);

      let title: ResourceStr
      title = StringUtil.convertResourceToStringWithArgs(cardInfo[this.currentSlotId].isSimCard ?
        cardInfo[this.currentSlotId].slotIndex === 1 ? $r('app.string.sim_card_1') :
          $r('app.string.sim_card_2') : $r('app.string.esim_card'),
        this.context as common.UIAbilityContext,
        cardInfo[this.currentSlotId].isSimCard ? dataLimitStr : `eSIM ${cardInfo[this.currentSlotId].slotIndex}`,
        dataLimitStr);
      return title.replace('(', '').replace(')', '');
    } else {
      return $r('app.string.data_limit');
    }
  }

  private reportTrafficDisplaySwitchEvent(isOn: boolean) {
    DotUtil.getInstance().reportTrafficDisplaySwitchEvent(isOn ? 1 : 0);
  }

  private handleMonthlyLimitedTrafficData(isReset: boolean) {
    let trafficDisplayEnable = isReset ? false : true;
    this.trafficDisplayStatus =
      trafficDisplayEnable ? TrafficDispalyStatus.OPEN : TrafficDispalyStatus.CLOSE;
    LogUtil.info(TAG, `save traffic display status-: ${trafficDisplayEnable}`);
    this.saveTrafficDisplayStatus(trafficDisplayEnable);
    AppStorage.setOrCreate<boolean>(TrafficController.getReminderName(this.currentSlotId), !isReset);
    this.postMessage();
    SettingsSearchUtils.enableLimitReminder(this.context as common.UIExtensionContext, !isReset);
  }

  private postMessage() {
    let event: emitter.InnerEvent = {
      eventId: EMITTER_NOTICE_EVENT_ID,
      priority: emitter.EventPriority.HIGH
    };
    let emitData: emitter.EventData = {
      data: {
        'params': {
          slotId: this.currentSlotId,
          simId: this.currentSimId,
        } as SlotIdMapSimIdInterface
      }
    }
    LogUtil.info(TAG, `post messag: ${this.currentSlotId}`);
    emitter.emit(event, emitData);
  }

  private parseEmitData(params: SlotIdMapSimIdInterface) {
    LogUtil.info(TAG,
      `receive reset month limit: ${params.simId}, ${params.slotId}, current:${this.currentSimId}, ${this.currentSlotId}`);
    if (this.currentSlotId === params.slotId) {
      this.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
    }
    let keyWord: string = fetchFullKeyWord(params.simId, QueryName.show_traffic);
    let actionData: settingsDataParam = {
      KEYWORD: keyWord
    };
    let valueBucket: ValuesBucket = {
      'KEYWORD': keyWord,
      'VALUE': '0'
    };

    SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: resType) => {
      if (res?.code === ResultCode.FAILURE) {
        LogUtil.error(TAG, 'insert traffic display close failed');
        return;
      }
    }, this.context);

  }

  private handleTrafficDisplayDBData(abilityResult?: settingsDataParam[]) {
    if (abilityResult == undefined) {
      this.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
      LogUtil.warn(TAG, `query traffic display result undefine`);
      return;
    }
    if (abilityResult.length <= 0) {
      this.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
      LogUtil.warn(TAG, `query traffic display result length 0`);
      return;
    }

    abilityResult.forEach((resultObj) => {
      if (!resultObj.KEYWORD) {
        this.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
        LogUtil.error(TAG, 'query traffic display failed');
        return;
      }
      LogUtil.info(TAG, `query traffic display key: ${resultObj.KEYWORD}, value: ${resultObj.VALUE}`);
      if (resultObj.KEYWORD === fetchFullKeyWord(this.currentSimId, QueryName.show_traffic)) {
        this.trafficDisplayStatus = resultObj.VALUE === '1' ? TrafficDispalyStatus.OPEN : TrafficDispalyStatus.CLOSE;
      }
    })
  }
}