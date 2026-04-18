/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import sim from '@ohos.telephony.sim';
import { LogUtils, Constants, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { BusinessError } from '@kit.BasicServicesKit';
import { CustConstants } from '../config/CustConstants';
import { radio } from '@kit.TelephonyKit';
import { CustPhoneNetworkStruct, CustWearableNetworkStruct } from '../../CustIndex';
import { common } from '@kit.AbilityKit';

const TAG = 'OperatorConfigUtils';
const ROAMING_OPTION_INVALID_VALUE = '-1';

export class OperatorConfigUtils {
  private static sInstance: OperatorConfigUtils | undefined = undefined;
  private mCustPhoneNetworkCardOne?: CustPhoneNetworkStruct;
  private mCustPhoneNetworkCardTwo?: CustPhoneNetworkStruct;
  private wearableNetworkCard?: CustWearableNetworkStruct;
  private mOperatorConfigMap: Map<number, Array<sim.OperatorConfig>> = new Map();
  private mSimCount = sim.getMaxSimCount();
  private isSetCustParam = false;

  public static getInstance(): OperatorConfigUtils {
    if (!OperatorConfigUtils.sInstance) {
      OperatorConfigUtils.sInstance = new OperatorConfigUtils();
    }
    return OperatorConfigUtils.sInstance;
  }

  public initOperatorConfig(): void {
    for (let i = 0; i < this.mSimCount; i++) {
      sim.getOperatorConfigs(i).then((data: Array<sim.OperatorConfig>) => {
        LogUtils.i(TAG, `getOperatorConfigs${i} success, promise: data->${JSON.stringify(data)}`);
        this.mOperatorConfigMap.set(i, data)
        this.refreshAppCustConfig(i);
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, `getOperatorConfigs${i} failed, promise: err->${JSON.stringify(err)}`);
      });
    }
  }

  public setCustParam(custParam: CustPhoneNetworkStruct, slotId: number): void {
    LogUtils.i(TAG, 'setCustParam slotId: ' + slotId);
    if (slotId === Constants.SLOT_ID_ONE) {
      this.mCustPhoneNetworkCardOne = custParam;
    } else {
      this.mCustPhoneNetworkCardTwo = custParam;
    }
    this.isSetCustParam = true;
    this.refreshAppCustConfig(slotId);
  }

  public setCustWearableParam(custParam: CustWearableNetworkStruct): void {
    LogUtils.i(TAG, 'setCustWearableParam switch:');
    this.wearableNetworkCard = custParam;
    this.isSetCustParam = true;
    this.refreshAppCustConfig(Constants.SLOT_ID_ONE);
  }

  private refreshAppCustConfig(slotId: number): void {
    if (!this.isSetCustParam || this.mOperatorConfigMap == null || this.mOperatorConfigMap.size < 1) {
      LogUtils.i(TAG, 'cust param is not set or mOperatorConfigMap is null');
      return;
    }
    let operatorConfigs = this.mOperatorConfigMap.get(slotId);
    if (operatorConfigs == null || operatorConfigs == undefined) {
      LogUtils.i(TAG, 'operatorConfigs is null, slotId: ' + slotId);
      return;
    }
    for (let index = 0; index < operatorConfigs.length; index++) {
      const element: sim.OperatorConfig = operatorConfigs[index];
      if (!element) {
        return;
      }
      switch (element.field) {
        case CustConstants.VOLTE_SUPPORTED_BOOL:
          this.setVolteSupportBool(element.value, slotId);
          break;
        case CustConstants.HIDE_IMS_SWITCH_BOOL:
          this.setHideImsSwitchBool(element.value, slotId);
          break;
        case CustConstants.CARRIER_NETWORKMODE_HIDE_BOOL:
          this.setCarrierNetworkModeHideBool(element.value, slotId);
          break;
        case CustConstants.CARRIER_LTE_SWITCH_BOOL:
          this.setCarrierLteSwitchBool(element.value, slotId);
          break;
        case CustConstants.CARRIER_NR_SWITCH_SHOW_BOOL:
          this.setCarrierNrSwitchShowBool(element.value, slotId);
          break;
        case CustConstants.DATA_ROAMING_OPTION:
          this.setWearableDataRoaming(element.value);
          break;
        case CustConstants.VOWIFI_SUPPORTED_BOOL:
          this.setVowifiSupported(element.value, slotId);
          break;
        default:
          break;
      }
    }
  }

  private setVolteSupportBool(value: string, slotId: number): void {
    if (slotId === Constants.SLOT_ID_ONE) {
      if (this.mCustPhoneNetworkCardOne) {
        this.mCustPhoneNetworkCardOne.isSupportVolte = (value === 'true');
      }
    } else {
      if (this.mCustPhoneNetworkCardTwo) {
        this.mCustPhoneNetworkCardTwo.isSupportVolte = (value === 'true');
      }
    }
  }

  private setHideImsSwitchBool(value: string, slotId: number): void {
    if (slotId === Constants.SLOT_ID_ONE) {
      if (this.mCustPhoneNetworkCardOne) {
        this.mCustPhoneNetworkCardOne.isHideVolte = (value === 'true');
      }
    } else {
      if (this.mCustPhoneNetworkCardTwo) {
        this.mCustPhoneNetworkCardTwo.isHideVolte = (value === 'true');
      }
    }
  }

  private setCarrierNetworkModeHideBool(value: string, slotId: number): void {
    if (slotId === Constants.SLOT_ID_ONE) {
      if (this.mCustPhoneNetworkCardOne) {
        this.mCustPhoneNetworkCardOne.isHideNetworkMode = (value === 'true');
      }
    } else {
      if (this.mCustPhoneNetworkCardTwo) {
        this.mCustPhoneNetworkCardTwo.isHideNetworkMode = (value === 'true');
      }
    }
  }

  private setCarrierLteSwitchBool(value: string, slotId: number): void {
    if (slotId === Constants.SLOT_ID_ONE) {
      if (this.mCustPhoneNetworkCardOne) {
        this.mCustPhoneNetworkCardOne.isShowLte = (value === 'true');
      }
    } else {
      if (this.mCustPhoneNetworkCardTwo) {
        this.mCustPhoneNetworkCardTwo.isShowLte = (value === 'true');
      }
    }
  }

  private setCarrierNrSwitchShowBool(value: string, slotId: number): void {
    if (slotId === Constants.SLOT_ID_ONE) {
      if (this.mCustPhoneNetworkCardOne) {
        this.mCustPhoneNetworkCardOne.isShowNr = (radio.isNrSupported() ? value === 'true' : false);
      }
    } else {
      if (this.mCustPhoneNetworkCardTwo) {
        this.mCustPhoneNetworkCardTwo.isShowNr = (radio.isNrSupported() ? value === 'true' : false);
      }
    }
  }

  private setWearableDataRoaming(value: string): void {
    LogUtils.i(TAG, `dataRoaming config is ${value}`);
    if (!value) {
      LogUtils.w(TAG, `dataRoaming config is ${value}`);
      return;
    }
    if (!CustConstants.VALID_ROAMING_VALUES.includes(value)) {
      LogUtils.i(TAG, `dataRoaming value not valid!`);
      return;
    }
    if (this.wearableNetworkCard) {
      this.wearableNetworkCard.isSupportDataRoamingExtend = true;
      this.wearableNetworkCard.mRoamingOptionValue = value;
    }
  }

  public getRoamingOptionValue(): string {
    if (this.wearableNetworkCard) {
      return this.wearableNetworkCard.mRoamingOptionValue;
    }
    return ROAMING_OPTION_INVALID_VALUE;
  }

  public setVowifiSupported(value: string, slotId: number): void {
    LogUtils.i(TAG, `setVowifiSupported value: ${value},slotId:${slotId}`);
    if (slotId === Constants.SLOT_ID_ONE && this.mCustPhoneNetworkCardOne) {
      this.mCustPhoneNetworkCardOne.isSupportVowifi = (value === 'true');
      return;
    }
    if (slotId === Constants.SLOT_ID_TWO && this.mCustPhoneNetworkCardTwo) {
      this.mCustPhoneNetworkCardTwo.isSupportVowifi = (value === 'true');
      return;
    }
  }
}