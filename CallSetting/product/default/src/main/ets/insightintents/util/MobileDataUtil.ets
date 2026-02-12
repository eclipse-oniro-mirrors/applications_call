/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
  isCellularDataEnabled,
  enableCellularData,
  disableCellularData,
  getCellularDataRoaming,
  disableCellularDataRoamingCard,
  enableCellularDataRoamingCard,
  enableImsSwitchCardOne,
  enableImsSwitchCardTwo,
  disableImsSwitchCardOne,
  disableImsSwitchCardTwo,
  isImsSwitchEnabled,
  Constants
} from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';
import Settings from '@ohos.settings';
import { getSimState, isSimActive } from '../../common/model/getSimStateApi';
import sim from '@ohos.telephony.sim';

const TAG = 'MobileDataUtil';
const AIR_PLANE_MODE: string = 'settings.telephony.airplanemode';
const AIR_PLANE_MODE_DEFAULT_VAL: string = '0';

const SIM_STATE: Record<string, number> = {
  'SIM_STATE_UNKNOWN': 0,
  'SIM_STATE_NOT_PRESENT': 1,
  'SIM_STATE_LOCKED': 2,
  'SIM_STATE_NOT_READY': 3,
  'SIM_STATE_READY': 4,
  'SIM_STATE_LOADED': 5
};

const SIM_ONE_SLOT_ID: number = 0;
const SIM_TWO_SLOT_ID: number = 1;

/**
 * Mobile data setting item, switch operation tool class
 *
 * @since 2024-05-30
 */
export class MobileDataUtil {
  private constructor() {
  }

  /**
   * Get Airplane Mode Status
   */
  static isAirplaneActive(): boolean {
    let value: string = Settings.getValueSync((AppStorage.get<common.Context>('pageContext') as common.Context),
      AIR_PLANE_MODE, AIR_PLANE_MODE_DEFAULT_VAL);
    LogUtils.i(TAG, 'isAirplaneActive success: value:' + value);
    return !(value === AIR_PLANE_MODE_DEFAULT_VAL);
  }

  /**
   * Obtaining the Mobile Data Switch Status
   */
  static async getCellularDataState(): Promise<boolean> {
    LogUtils.i(TAG, 'getCellularDataState');
    let result: boolean;
    try {
      result = await isCellularDataEnabled();
    } catch (e) {
      LogUtils.e(TAG, 'getCellularDataState error');
      return Promise.reject(new Error('getCellularDataState error'))
    }
    return result;
  }

  /**
   * Obtains the status of the data roaming switch.
   *
   * @param slotId
   * @returns
   */
  static async getCellularDataRoamingEnabled(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, 'getCellularDataRoamingEnabled');
    let result: boolean;
    try {
      result = await getCellularDataRoaming(slotId);
    } catch (e) {
      LogUtils.e(TAG, 'getCellularDataRoamingEnabled error');
      return Promise.reject(new Error('getCellularDataRoamingEnabled error'))
    }
    return result;
  }

  /**
   * Obtains the SIM card status of a card slot.
   */
  static async getSlotSimState(slotId: number): Promise<number> {
    LogUtils.i(TAG, `getSlotSimState slotId is: ${slotId}`);
    return await getSimState(slotId);
  }


  /**
   * Whether the card in the specified slot is activated
   *
   * @param simState sim card state
   * @param slotId slot id, card one : 0, card two : 1
   * @returns
   */
  static async getSimStateDataCardActive(simState: number, slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `getSimStateDataCardActive slotId ${slotId} simState is ${simState}`);
    if (SIM_STATE.SIM_STATE_LOADED != simState && SIM_STATE.SIM_STATE_READY != simState) {
      LogUtils.i(TAG, `getSimStateDataCardActive simState is : ${JSON.stringify(simState)}`);
      return false;
    }
    let result: boolean;
    try {
      result = await isSimActive(slotId);
    } catch (e) {
      LogUtils.e(TAG, `getSimStateDataCardActive sim${slotId} is unActive`);
      result = false;
    }
    return result;
  }

  /**
   * Disable Cellular Data Services
   *
   * @returns
   */
  static async disableCellularData(): Promise<boolean> {
    LogUtils.i(TAG, 'disableCellularData');
    let result: boolean = true;
    try {
      await disableCellularData();
    } catch (e) {
      LogUtils.e(TAG, 'disableCellularData error');
      result = false;
    }
    return result;
  }

  /**
   * Check cellular data service
   *
   * @returns
   */
  static async checkCellularDataIsActive(): Promise<boolean> {
    LogUtils.i(TAG, 'checkCellularDataIsActive');
    let slotOneSimState = await MobileDataUtil.getSlotSimState(SIM_ONE_SLOT_ID);
    let isSlotOneActive = await MobileDataUtil.getSimStateDataCardActive(slotOneSimState, SIM_ONE_SLOT_ID);
    let slotTwoSimState = await MobileDataUtil.getSlotSimState(SIM_TWO_SLOT_ID);
    let isSlotTwoActive = await MobileDataUtil.getSimStateDataCardActive(slotTwoSimState, SIM_TWO_SLOT_ID);
    let isActive = isSlotOneActive || isSlotTwoActive;
    return isActive;
  }

  /**
   * Enable cellular data service
   *
   * @returns
   */
  static async enableCellularData(): Promise<boolean> {
    LogUtils.i(TAG, 'enableCellularData');
    let result: boolean = true;
    try {
      await enableCellularData();
    } catch (e) {
      LogUtils.e(TAG, 'enableCellularData error');
      result = false;
    }
    return result;
  }

  /**
   * Check Data Roaming Service
   *
   * @param slotId slot id
   * @returns
   */
  static async checkCellularDataRoamingIsActive(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, 'checkCellularDataRoamingIsActive');
    let slotTwoSimState = await MobileDataUtil.getSlotSimState(slotId);
    return await MobileDataUtil.getSimStateDataCardActive(slotTwoSimState, slotId);
  }

  /**
   * Turn off mobile data roaming
   *
   * @param slotId slot id
   * @returns
   */
  static async disableCellularDataRoaming(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `disableCellularDataRoaming slotId ${slotId}`);
    return await disableCellularDataRoamingCard(slotId);
  }

  /**
   * Turn on mobile data roaming
   *
   * @param slotId slot id
   * @returns
   */
  static async enableCellularDataRoaming(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `enableCellularDataRoaming slotId ${slotId}`);
    return await enableCellularDataRoamingCard(slotId);
  }

  /**
   * Check ims switch is support
   *
   * @param slotId slot id
   * @returns
   */
  static async checkImsSwitchIsSupport(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `checkImsSwitchIsSupport slotId ${slotId}`);
    try {
      const simConfigs = await sim.getOperatorConfigs(slotId);
      let volteIsSupport: boolean = true;
      let volteIsHide: boolean = false;
      simConfigs.forEach((configItem: sim.OperatorConfig) => {
        if (configItem.field === 'volte_supported_bool') {
          volteIsSupport = configItem.value === 'true';
        } else if (configItem.field === 'hide_ims_switch_bool') {
          volteIsHide = configItem.value === 'true';
        }
      });
      LogUtils.i(TAG, `get ims config volte_supported:${volteIsSupport} hide_ims_switch:${volteIsHide}`);
      return volteIsSupport && !volteIsHide;
    } catch (error) {
      LogUtils.e(TAG, `is show volte err: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * Obtains the status of the ims switch.
   *
   * @param slotId
   * @returns
   */
  static getImsSwitch(slotId: number): boolean {
    LogUtils.i(TAG, 'getImsSwitch slotId ${slotId}');
    return isImsSwitchEnabled(slotId);
  }

  /**
   * Set ims switch status
   *
   * @param slotId slot id, card one : 0, card two : 1
   * @param switchStatus true: enable false: disable
   * @returns
   */
  static setImsSwitch(slotId: number, switchStatus: boolean) {
    if (switchStatus) {
      slotId === Constants.SLOT_ID_ONE ? enableImsSwitchCardOne() : enableImsSwitchCardTwo();
    } else {
      slotId === Constants.SLOT_ID_ONE ? disableImsSwitchCardOne() : disableImsSwitchCardTwo();
    }
  }
}
