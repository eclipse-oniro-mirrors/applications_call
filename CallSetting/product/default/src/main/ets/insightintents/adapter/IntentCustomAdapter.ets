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
import { IntentCodeConstants, ERROR_MSG } from '../constant/IntentCodeConstant';
import { MobileDataUtil } from '../util/MobileDataUtil';

const TAG: string = 'IntentCustomAdaptor: '

const SWITCH_ON: number = 0;
const SWITCH_OFF: number = 1;

/**
 * Intention Framework Operation Setting Switch Transfer Class - Customized Setting Intention
 *
 * @since 2024-05-29
 */
export class IntentCustomAdaptor {
  private constructor() {
  }

  /**
   * check date roaming switch
   *
   * @param slotId slotId
   * @returns
   */
  static async checkDateRoamingSwitch(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `checkDateRoamingSwitch intent slotId is ${slotId}`);
    let isActive: boolean = await MobileDataUtil.checkCellularDataRoamingIsActive(slotId);
    return IntentCustomAdaptor.getExecuteResultByAirplane(slotId, isActive);
  }

  /**
   * get data roaming switch state
   *
   * @param slotId slotId
   * @returns
   */
  static async getDataRoamingSwitch(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `getDataRoamingSwitch intent slotId is ${slotId}`);
    let switchFlag: number = await MobileDataUtil.getCellularDataRoamingEnabled(slotId) ? SWITCH_ON : SWITCH_OFF;
    let rsp: Record<string, Object> = {
      'slotId': slotId,
      'switchFlag': switchFlag,
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp
    }
    return defaultRsp;
  }

  /**
   * set data roaming switch state
   *
   * @param slotId slotId
   * @param switchFlag  0： on； 1：off
   * @returns
   */
  static async setDataRoamingSwitch(slotId: number, switchFlag: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `setDataRoamingSwitch, slotId: ${slotId}, switchFlag: ${switchFlag}`);
    let rsp: Record<string, Object> = {
      'slotId': slotId,
      'switchFlag': switchFlag
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp,
    }
    let isSwitchOn: boolean = await MobileDataUtil.getCellularDataRoamingEnabled(slotId);
    if (switchFlag === SWITCH_ON) {
      if (isSwitchOn) {
        LogUtils.i(TAG, `DataRoamingSwitch: ${slotId} has already turn on`);
        return defaultRsp;
      } else {
        if (await MobileDataUtil.enableCellularDataRoaming(slotId)) {
          LogUtils.i(TAG, ` DataRoamingSwitch: ${slotId} turn on success`);
          return defaultRsp;
        }
      }
    } else if (switchFlag === SWITCH_OFF) {
      if (!isSwitchOn) {
        LogUtils.i(TAG, ` DataRoamingSwitch: ${slotId} has already turn off`);
        return defaultRsp;
      } else {
        if (await MobileDataUtil.disableCellularDataRoaming(slotId)) {
          LogUtils.i(TAG, ` DataRoamingSwitch: ${slotId} turn off success`);
          return defaultRsp;
        }
      }
    } else {
      LogUtils.e(TAG, ` DataRoamingSwitch: ${slotId} unkown state`);
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
   * check Ims switch
   *
   * @param slotId slotId
   * @returns insightIntent result
   */
  static async checkImsSupport(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `checkImsSupport intent slotId is ${slotId}`);
    let isActive: boolean = await MobileDataUtil.checkImsSwitchIsSupport(slotId);
    return IntentCustomAdaptor.getExecuteResultByAirplane(slotId, isActive);
  }


  /**
   * get Ims switch state
   *
   * @param slotId slotId
   * @returns insightIntent result
   */
  static getImsSwitch(slotId: number): insightIntent.ExecuteResult {
    LogUtils.i(TAG, `getImsSwitch intent slotId is ${slotId}`);
    let switchFlag: number = MobileDataUtil.getImsSwitch(slotId) ? SWITCH_ON : SWITCH_OFF;
    let rsp: Record<string, Object> = {
      'slotId': slotId,
      'switchFlag': switchFlag,
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp
    }
    return defaultRsp;
  }

  /**
   * set Ims switch state
   *
   * @param slotId slotId
   * @param switchFlag  0： on； 1：off
   * @returns insightIntent result
   */
  static setImsSwitch(slotId: number, switchFlag: number): insightIntent.ExecuteResult {
    LogUtils.i(TAG, `setImsSwitch, slotId: ${slotId}, switchFlag: ${switchFlag}`);
    let rsp: Record<string, Object> = {
      'slotId': slotId,
      'switchFlag': switchFlag
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp,
    }
    let isSwitchOn: boolean = MobileDataUtil.getImsSwitch(slotId);
    let switchStatus: boolean = switchFlag === SWITCH_ON;
    if (switchStatus != isSwitchOn) {
      MobileDataUtil.setImsSwitch(slotId, switchStatus);
    } else {
      LogUtils.i(TAG, `ImsSwitch: ${slotId} has already ${switchFlag}`);
    }
    return defaultRsp;
  }

  private static getExecuteResultByAirplane(slotId: number, isActive: boolean): insightIntent.ExecuteResult {
    let code: number = IntentCodeConstants.DEFAULT_CODE_SUCCESS;
    let isSupport: boolean = true;
    if (!isActive) {
      code = IntentCodeConstants.NO_SIM_CARD;
      isSupport = false;
      return IntentCustomAdaptor.buildExecuteResult(slotId, code, isSupport);
    }
    let isAirPlaneActive: boolean = MobileDataUtil.isAirplaneActive();
    if (isAirPlaneActive) {
      code = IntentCodeConstants.LIMITED_BY_AIRPLANE_MODE;
      isSupport = false;
      return IntentCustomAdaptor.buildExecuteResult(slotId, code, isSupport);
    }
    return IntentCustomAdaptor.buildExecuteResult(slotId, code, isSupport);
  }

  private static buildExecuteResult(slotId: number, code: number, isSupport: boolean): insightIntent.ExecuteResult {
    let rsp: insightIntent.ExecuteResult = {
      code: code,
      result: {
        'slotId': slotId,
        'isSupport': isSupport
      }
    }
    return rsp;
  }
}


