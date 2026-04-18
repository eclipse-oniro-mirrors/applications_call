/**
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
  LogUtils,
  CallSettingGlobalContextHelper,
  SatelliteSimCardInfoStruct,
  sharedPreferencesUtils,
  Constants
} from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import data_preferences from '@ohos.data.preferences';
import { getString } from '../common/utils/Utils';
import { getMaxSimCount } from './RegisterSimStateApi';
import { HYACINTH_SIM_SHOW_NAME, SatelliteType } from '../common/constant/SatelliteSearchConst';
import SatelliteSearchManager from '../manager/SatelliteSearchManager';
import { insertBeiDouMessage } from '../common/utils/BeiDouMessageStateManager';
import { settings } from '@kit.BasicServicesKit';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { phoneFormat, simIdFormat } from '../common/utils/SimIdFormat';

const TAG = 'SatelliteServiceSettingModel'

export function getPreferences(callback: (simData: string[]) => void) {
  let context = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
  sharedPreferencesUtils.init(context);
  sharedPreferencesUtils.getFromPreferences(CallSettingsConstant.SATELLITE_DIALOG_TIPS.SATELLITE_DIALOG_TIPS, [])
    .then((data: data_preferences.ValueType) => {
      let simData: string[] = data as string[];
      LogUtils.i(TAG, `getPreferences ${simData.length}`)
      if (simData.length) {
        callback(simData);
      } else {
        callback([]);
      }
    })
}

export function getHyacinthPreferences(callback: (simData: string[]) => void) {
  try {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    sharedPreferencesUtils.init(context);
    sharedPreferencesUtils.getFromPreferences(CallSettingsConstant.HYACINTH_DIALOG_TIPS.HYACINTH_DIALOG_TIPS, [])
      .then((data: data_preferences.ValueType) => {
        let simData: string[] = data as string[];
        LogUtils.i(TAG, `getHyacinthPreferences ${simData.length}`)
        callback(simData);
      }).catch((err: Error) => {
        LogUtils.e(TAG, `getFromPreferences error. ${err?.message}`);
      })
  } catch (error) {
    LogUtils.e(TAG, `[Crash] getHyacinthPreferences failed: ${error.message}\n${error.stack}`);
  }
}

export function getShowName(simInfo: SatelliteSimCardInfoStruct): string | Resource {
  let simId = simInfo?.slotId === 0 ? 1 : 2;
  const simLabelIndex: number = simInfo?.simLabelIndex ?? simId;
  if (simInfo.isEsim) {
    return simInfo?.showNumber ?
    $r('app.string.satellite_service_esim_showname', simIdFormat(simLabelIndex),
      `\u202D${phoneFormat(simInfo.showNumber)}\u202C`) :
    $r('app.string.satellite_service_esim_showname', simIdFormat(simLabelIndex),
      getString($r('app.string.satellite_service_no_phone_number')));
  }
  return simInfo?.showNumber ?
  $r('app.string.satellite_service_showname', simIdFormat(simLabelIndex), `\u202D${phoneFormat(simInfo.showNumber)}\u202C`) :
  $r('app.string.satellite_service_showname', simIdFormat(simLabelIndex),
    getString($r('app.string.satellite_service_no_phone_number')));
}

export function getShowNameByContext(context: Context, simInfo: SatelliteSimCardInfoStruct): string {
  let simId = simInfo?.slotId === 0 ? 1 : 2;
  const simLabelIndex: number = simInfo?.simLabelIndex ?? simId;
  if (simInfo.isEsim) {
    return simInfo?.showNumber ?
    context?.resourceManager.getStringSync($r('app.string.satellite_service_esim_showname'),
      simIdFormat(simLabelIndex),
      `\u202D${phoneFormat(simInfo.showNumber)}\u202C`) :
    context?.resourceManager.getStringSync($r('app.string.satellite_service_esim_showname'),
      simIdFormat(simLabelIndex),
      getString($r('app.string.satellite_service_no_phone_number')));
  }
  return simInfo?.showNumber ?
  context?.resourceManager.getStringSync($r('app.string.satellite_service_showname'), simIdFormat(simLabelIndex),
    `\u202D${phoneFormat(simInfo.showNumber)}\u202C`) :
  context?.resourceManager.getStringSync($r('app.string.satellite_service_showname'), simIdFormat(simLabelIndex),
    getString($r('app.string.satellite_service_no_phone_number')));
}

export function setShowName(simCardInfoList: SatelliteSimCardInfoStruct[], satelliteType: number) {
  let showValue: Resource | string = $r('app.string.satellite_service_no_sim_card');
  let maxSimCount: number = getMaxSimCount();
  if (maxSimCount < 2) {
    showValue = simCardInfoList[0] === undefined ? $r('app.string.APN_Not_set') : simCardInfoList[0].showNumber;
    AppStorage.setOrCreate(getShowNameBySatelliteType(satelliteType), '\u202D' + showValue + '\u202C');
    return;
  }
  if (simCardInfoList.length === 2) {
    let simInfo = simCardInfoList.find((simInfo: SatelliteSimCardInfoStruct) => {
      if (satelliteType === SatelliteType.HYACINTH) {
        return simInfo.isHyacinthChecked;
      } else {
        return simInfo.isChecked;
      }
    });
    LogUtils.i(TAG, `setShowName simInfo is undefined ${simInfo === undefined}`);
    if (simInfo === undefined) {
      showValue = $r('app.string.APN_Not_set');
    } else {
      showValue = getShowName(simInfo);
    }
  } else {
    showValue = getShowName(simCardInfoList[0]);
  }
  AppStorage.setOrCreate(getShowNameBySatelliteType(satelliteType), showValue);
}

export function getShowNameBySatelliteType(satelliteType: number): string {
  return satelliteType === SatelliteType.TIAN_TONG ? 'showName': HYACINTH_SIM_SHOW_NAME;
}

/**
 * 获取SIM卡显示名称
 * @param simCardInfoList SIM卡数组
 * @returns  显示名称
 */
export function getSimShowName(simCardInfoList: SatelliteSimCardInfoStruct[]): string | Resource {
  let showValue: Resource | string = $r('app.string.satellite_service_no_sim_card');
  let maxSimCount: number = getMaxSimCount();
  if (maxSimCount < 2) {
    showValue = simCardInfoList[0] === undefined ? $r('app.string.APN_Not_set') : simCardInfoList[0].showNumber;
    return '\u202D' + showValue + '\u202C';
  }
  if (simCardInfoList.length === 2) {
    let simInfo = simCardInfoList.find((simInfo: SatelliteSimCardInfoStruct) => {
      if (SatelliteSearchManager.getInstance().isHyacinth()) {
        return simInfo.isHyacinthChecked;
      } else {
        return simInfo.isChecked;
      }
    });
    LogUtils.i(TAG, 'setShowName simInfo is undefined' + JSON.stringify(simInfo === undefined))
    if (simInfo === undefined) {
      showValue = $r('app.string.APN_Not_set');
      updateBeiDouSimSlotId(-1);
    } else {
      showValue = getShowName(simInfo);
      updateBeiDouSimSlotId(simInfo.slotId);
    }
  } else {
    showValue = getShowName(simCardInfoList[0]);
    updateBeiDouSimSlotId(simCardInfoList[0].slotId);
  }
  return showValue;
}
/*
 * 北斗卫星短信页面 选择的sim卡状态变化时通知短信更新页面提示
 * */
export function updateBeiDouSimSlotId(slotId: number) {
  if (SatelliteSearchManager.getInstance().timeOutId !== -1) {
    clearTimeout(SatelliteSearchManager.getInstance().timeOutId);
  }
  // 插拔卡场景下当前方法会多次调用，使用timeOut只发送最后一次值变化的通知，防止短信中页面多次刷新
  SatelliteSearchManager.getInstance().timeOutId = setTimeout(() => {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    LogUtils.i(TAG, 'updateBeiDouSimSlotId slotId:' + slotId);
    insertBeiDouMessage(CallSettingsConstant.BEIDOU_SIM_SLOTID, slotId, context);
    clearTimeout(SatelliteSearchManager.getInstance().timeOutId);
    SatelliteSearchManager.getInstance().timeOutId = -1;
    updateBeiDouSwitchValue();
  }, 3000);
}

/*
 * 北斗卫星开关状态变化通知mms中北斗短信页面刷新
 * */
export function updateBeiDouSwitchValue() {
  LogUtils.i(TAG, 'updateBeiDouSwitchValue');
  try {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(CallSettingsConstant
        .CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    let isOn =
      settings.getValueSync(context, Constants.BEI_DOU_SIM_SLOTID_UPDATE, Constants.TIAN_TONG_SATELLITE_STATE_CLOSE);
    settings.setValueSync(context, Constants.BEI_DOU_SIM_SLOTID_UPDATE,
      isOn === Constants.TIAN_TONG_SATELLITE_STATE_CLOSE ? Constants.TIAN_TONG_SATELLITE_STATE_OPEN :
      Constants.TIAN_TONG_SATELLITE_STATE_CLOSE);
  } catch (err) {
    LogUtils.e(TAG, `settings set bei_sou_sim_slotId_update error: ${err?.code} ${err?.message}`);
  }
}