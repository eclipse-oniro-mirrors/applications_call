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

import insightIntent from '@ohos.app.ability.insightIntent';
import { LogUtils } from '@ohos/common/CommonIndex';
import SatelliteUtils from '../../common/utils/SatelliteUtils';
import { IntentCodeConstants, ERROR_MSG } from '../constant/IntentCodeConstant';
import { MobileDataUtil } from '../util/MobileDataUtil';

const TAG: string = 'IntentSwitchAdaptor'

const SWITCH_ON: number = 0;
const SWITCH_OFF: number = 1;

/**
 * Query Switch Status Method Mapping
 */
const switchStatusFunRecord: Record<string, Function> = {
  'mobile_data': MobileDataUtil.getCellularDataState,
  'skycom_satellite_communications': SatelliteUtils.getSkycomSatelliteState,
  'changlian_beidou_satellite_news': SatelliteUtils.getBeidouSatelliteState
};

/**
 * Method mapping for enabling the configuration item
 */
const setSwitchOnFunRecord: Record<string, Function> = {
  'mobile_data': MobileDataUtil.enableCellularData,
}

/**
 * Method mapping for disabling the configuration item switch
 */
const setSwitchOffFunRecord: Record<string, Function> = {
  'mobile_data': MobileDataUtil.disableCellularData,
}

/**
 * Intention Framework Operation Setting Switch Transfer Class
 *
 * @since 2024-05-28
 */
export class IntentSwitchAdaptor {
  private constructor() {
  }

  /**
   * get Setting Switch state
   *
   * @param itemName switch item name
   * @param appBundleName app bundle name
   * @returns
   */
  static async getSettingSwitch(itemName: string, appBundleName: string): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `getSettingSwitch,itemName: ${itemName}, appBundleName: ${appBundleName} `);
    let switchFlag: number = await IntentSwitchAdaptor.getSwitchStatus(itemName) ? SWITCH_ON : SWITCH_OFF;
    let rsp: Record<string, Object> = {
      'itemName': itemName,
      'appBundleName': appBundleName,
      'switchFlag': switchFlag,
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp
    }
    return defaultRsp;
  }

  /**
   * set switch state
   *
   * @param itemName switch item name
   * @param appBundleName app bundle name
   * @param switchFlag switch state 0:on, 1: off
   * @returns
   */
  static async setSettingSwitch(itemName: string, appBundleName: string,
    switchFlag: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG,
      `setSettingSwitch, itemName: ${itemName}, switchFlag: ${switchFlag}, appBundleName: ${appBundleName}`);
    let rsp: Record<string, Object> = {
      'itemName': itemName,
      'switchFlag': switchFlag,
      'appBundleName': appBundleName,
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp,
    }
    let switchState: boolean = await IntentSwitchAdaptor.getSwitchStatus(itemName);
    if (switchFlag === SWITCH_ON) {
      if (switchState) {
        LogUtils.i(TAG, `switch: ${itemName} has already turn on`);
        return defaultRsp;
      } else {
        if (await IntentSwitchAdaptor.setSwitchOn(itemName)) {
          LogUtils.i(TAG, ` switch: ${itemName} turn on success`);
          return defaultRsp;
        }
      }
    } else if (switchFlag === SWITCH_OFF) {
      if (!switchState) {
        LogUtils.i(TAG, ` switch: ${itemName} has already turn off`);
        return defaultRsp;
      } else {
        if (await IntentSwitchAdaptor.setSwitchOff(itemName)) {
          LogUtils.i(TAG, ` switch: ${itemName} turn off success`);
          return defaultRsp;
        }
      }
    } else {
      LogUtils.e(TAG, ` switch: ${itemName} unkown state`);
    }
    let errorRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED]
      },
    }
    return errorRsp;
  }

  /**
   * get switch state
   *
   * @param itemName switch item name
   */
  static async getSwitchStatus(itemName: string): Promise<boolean> {
    let switchStatus: boolean = await switchStatusFunRecord[itemName]()
    LogUtils.i(TAG, ` Get setting switch status, itemName: ${itemName}, status: ${JSON.stringify(switchStatus)}`);
    return switchStatus;
  }

  /**
   * turn on switch
   *
   * @param itemName switch item name
   */
  static async setSwitchOn(itemName: string): Promise<boolean> {
    let turnOnRsp: boolean = await setSwitchOnFunRecord[itemName]();
    LogUtils.i(TAG, ` Turn on setting switch, itemName: ${itemName}, operation rsp: ${JSON.stringify(turnOnRsp)}`);
    return turnOnRsp;
  }

  /**
   * turn off switch
   *
   * @param itemName switch item name
   */
  static async setSwitchOff(itemName: string): Promise<boolean> {
    let turnOffRsp: boolean = await setSwitchOffFunRecord[itemName]();
    LogUtils.i(TAG, ` Turn off setting switch, itemName: ${itemName}, operation rsp: ${JSON.stringify(turnOffRsp)}`);
    return turnOffRsp;
  }
}


