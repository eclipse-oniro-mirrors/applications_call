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

import { observer, sim } from '@kit.TelephonyKit';
import { LogUtils, CallSettingGlobalContextHelper, SatelliteSimCardInfoStruct,
  sharedPreferencesUtils } from '@ohos/common/CommonIndex';
import { getActiveSimInfo, getIMSI, isSupportBeiDouMessageCard } from '../model/SimManager';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';

import TipsJumpUtils, { FUN_NAME_BEIDOU_MESSAGE } from '../common/utils/PlaySkillsJumpUtils';

import { common } from '@kit.AbilityKit';
import {
  getMaxSimCount,
  registerAccountInfoChange,
  registerSimStateChangeForSlotId,
  unRegisterAccountInfoChange,
  unRegisterSimStateChange
} from '../model/RegisterSimStateApi';
import { getPreferences, getSimShowName } from '../model/SatelliteServiceSettingModel';
import { Queue } from '@kit.ArkTS';
import CommonEventManager from '@ohos.commonEventManager';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import {
  SATELLITE_KEY_SLOT_ID,
  SATELLITE_TOAST_AIRPLANE_CODE,
  SATELLITE_TOAST_DURATION,
  SATELLITE_TOAST_OFF_CODE
} from '../common/constant/SatelliteSearchConst';

const TAG = 'SatelliteServiceSettingsVMForBeiDou';

let primarySubscriberQueue: Queue<CommonEventManager.CommonEventSubscriber> = new Queue();

let satelliteToastInfo: CommonEventManager.CommonEventSubscribeInfo = {
  events: ['event.custom.satellite.ACTION_SATELLITE_TOAST',
    'event.custom.ims.ACTION_IMPU_READY'],
  publisherPermission: 'ohos.permission.SET_TELEPHONY_STATE'
};

export default class SatelliteServiceSettingsVMForBeiDou {
  private static mSatelliteServiceSettingsVM: SatelliteServiceSettingsVMForBeiDou;
  public simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  private isSimActive: boolean = false;
  private isSim1Active: boolean = false;
  private isSim2Active: boolean = false;
  public simActiveState: (arg: boolean) => void = (arg) => {
  };
  public isStartSatelliteService: boolean = false;

  public static getInstance(): SatelliteServiceSettingsVMForBeiDou {
    if (!SatelliteServiceSettingsVMForBeiDou.mSatelliteServiceSettingsVM) {
      SatelliteServiceSettingsVMForBeiDou.mSatelliteServiceSettingsVM = new SatelliteServiceSettingsVMForBeiDou();
    }
    return SatelliteServiceSettingsVMForBeiDou.mSatelliteServiceSettingsVM;
  }

  aboutToAppear(): void {
    this.registerData();
  }

  initSimCardName() {
    let showValue: string | Resource;
    if (this.simCardInfoList === undefined || this.simCardInfoList === null || this.simCardInfoList.length === 0) {
      showValue = $r('app.string.satellite_service_no_sim_card')
    } else {
      showValue = getSimShowName(this.simCardInfoList);
    }
    AppStorage.setOrCreate('showNameForBeiDou', showValue);
  }

  getActiveSimInfoCT(isConnected: boolean) {
    this.simCardInfoList.splice(0, this.simCardInfoList.length);
    if (!isConnected) {
      this.initSimCardName();
      AppStorage.setOrCreate('simCardInfoListForBeiDou', this.simCardInfoList);
      return;
    }
    getActiveSimInfo((data: Array<sim.IccAccountInfo>) => {
      LogUtils.i(TAG, 'getActiveSimInfo data.length: ' + JSON.stringify(data.length));
      if (!data.length) {
        this.initSimCardName();
        LogUtils.i(TAG, 'getActiveSimInfo is null');
      } else {
        this.updateSimInfoList(data);
      }
    })
  }

  async updateSimInfoList(data: Array<sim.IccAccountInfo>) {
    for (let i = 0; i < data.length; i++) {
      let item = data[i];
      if (await isSupportBeiDouMessageCard(item.slotIndex)) {
        await this.updateShowNumber(item);
        await this.checkIMSI(item);
      }
    }
    this.handleSimCardInfo();
  }

  checkHasPreferences() {
    getPreferences((simData: string[]) => {
      if (simData.length) {
        let imsi = simData[3];
        let simInfo: SatelliteSimCardInfoStruct[] = this.simCardInfoList.filter((item) => item.iMsi === imsi);
        if (simInfo !== undefined) {
          simInfo[0].isChecked = true;
          this.simCardInfoList.splice(simInfo[0].slotId === 0 ? 0 : 1, 1, simInfo[0]);
          AppStorage.setOrCreate('simCardInfoListForBeiDou', this.simCardInfoList);
          let context = CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
          try {
            settings.setValueSync(context, SATELLITE_KEY_SLOT_ID, String(simInfo[0].slotId));
          } catch (err) {
            LogUtils.e(TAG, `checkHasPreferences: setValueSync error: ${err?.code} ${err?.message}`);
          }
          this.initSimCardName();
          LogUtils.i(TAG, `isHasPreferences simInfo length: ${this.simCardInfoList.length}`);
        }
      }
    })
  }

  async updateShowNumber(item: sim.IccAccountInfo) {
    LogUtils.i(TAG, 'updateShowNumber is called');
    if (!item) {
      LogUtils.e(TAG, 'updateShowNumber item is invalid');
      return;
    }
    let showNumber: string = await sim.getShowNumber(item.slotIndex);
    if (showNumber) {
      item.showNumber = showNumber;
    } else {
      showNumber = await sim.getSimTelephoneNumber(item.slotIndex);
      if (showNumber) {
        item.showNumber = showNumber;
      }
    }
  }

  async checkIMSI(item: sim.IccAccountInfo) {
    LogUtils.i(TAG, 'checkIMSI isCtCard has loaded');
    let simInfo: SatelliteSimCardInfoStruct = new SatelliteSimCardInfoStruct();
    await getIMSI(item.slotIndex, (iMsi: string) => {
      this.simStateChange(simInfo, item, iMsi);
    })
  }

  handleSimCardInfo() {
    LogUtils.i(TAG, `handleSimCardInfo simCardInfoList length: ` + JSON.stringify(this.simCardInfoList.length));
    if (this.simCardInfoList.length > 0) {
      this.isSimActive = true;
    }
    if (this.simCardInfoList.length === 1) {
      AppStorage.setOrCreate('simCardInfoListForBeiDou', this.simCardInfoList);
      this.initSimCardName();
    } else if (this.simCardInfoList.length === 2) {
      this.simCardInfoList.sort((o1: SatelliteSimCardInfoStruct, o2: SatelliteSimCardInfoStruct) => {
        return o1.slotId < o2.slotId ? -1 : 1;
      })
      AppStorage.setOrCreate('simCardInfoListForBeiDou', this.simCardInfoList);
      //End twice, and then judge whether it has been stored.
      this.checkHasPreferences();

      this.initSimCardName();
    }
  }

  simStateChange(simInfo: SatelliteSimCardInfoStruct, item: sim.IccAccountInfo, iMsi: string) {
    simInfo.slotId = item.slotIndex;
    simInfo.showNumber = item.showNumber;
    simInfo.iMsi = iMsi;
    simInfo.isEsim = item.isEsim;
    // simInfo.simLabelIndex = item.simLabelIndex;
    let targetObj = this.simCardInfoList.find((simInfo: SatelliteSimCardInfoStruct) =>
    simInfo.slotId === item.slotIndex);
    if (targetObj) {
      this.simCardInfoList[this.simCardInfoList.findIndex((v) => v.slotId === item.slotIndex)] = simInfo;
    } else {
      this.simCardInfoList.push(simInfo);
    }
    LogUtils.i(TAG, `simStateChange update simCardInfo list: ${this.simCardInfoList.length}`)
  }

  hasTwoCard(): boolean {
    return this.simCardInfoList !== undefined && this.simCardInfoList.length === 2;
  }

  registerData() {
    this.registerSimSateChange();
    this.addRegisterAccountInfoChange();
    this.subscribeSatelliteToastEvent();
  }

  registerSimSateChange() {
    try {
      // 最大卡槽数
      let maxSimCount: number = getMaxSimCount();
      LogUtils.i(TAG, `registerSimSateChange maxSimCount: ${maxSimCount}}`);
      if (maxSimCount >= 1) {
        registerSimStateChangeForSlotId(0, async (callStateInfo: observer.SimStateData) => {
          this.isSim1Active = callStateInfo?.state === sim.SimState.SIM_STATE_LOADED ||
            callStateInfo?.state === sim.SimState.SIM_STATE_READY ? true : false;
          LogUtils.i(TAG, `registerSimSateChange isSim1Active: ${this.isSim1Active}}`);
          this.isSimActive = (this.isSim1Active || this.isSim2Active);
          this.getSimListChange();
        });
      }
      if (maxSimCount >= 2) {
        registerSimStateChangeForSlotId(1, async (callStateInfo: observer.SimStateData) => {
          this.isSim2Active = callStateInfo?.state === sim.SimState.SIM_STATE_LOADED ||
            callStateInfo?.state === sim.SimState.SIM_STATE_READY ? true : false;
          LogUtils.i(TAG, `registerSimSateChange isSim2Active: ${this.isSim2Active}}`);
          this.isSimActive = (this.isSim1Active || this.isSim2Active);
          this.getSimListChange();
        });
      }
    } catch (err) {
      LogUtils.e(TAG, `addRegisterSimStateChange err = ${JSON.stringify(err)}`);
    }
  }

  addSimStateAcitveChangeListener(fn: (arg: boolean) => void): void {
    this.simActiveState = fn;
  }

  addRegisterAccountInfoChange() {
    try {
      registerAccountInfoChange(async () => {
        LogUtils.i(TAG, `registerAccountInfoChange is connected: ${this.isSimActive}}`);
        this.getSimListChange();
      })
    } catch (err) {
      LogUtils.e(TAG, `addRegisterAccountInfoChange err = ${JSON.stringify(err)}`);
    }
  }

  getSimListChange() {
    LogUtils.i(TAG, 'getSimListChange: isStartSatelliteService ' + JSON.stringify(this.isStartSatelliteService));
    if (!this.isStartSatelliteService) {
      if (this.simActiveState) {
        this.simActiveState(this.isSimActive);
      }
      LogUtils.i(TAG, 'getSimListChange: ' + JSON.stringify(this.isSimActive));
      if (this.isSimActive) {
        this.getActiveSimInfoCT(this.isSimActive);
      } else {
        this.simCardInfoList.splice(0, this.simCardInfoList.length);
        this.initSimCardName();
        AppStorage.setOrCreate('simCardInfoListForBeiDou', this.simCardInfoList);
      }
    }
  }

  jumpPhoneWidget() {
    LogUtils.i(TAG, 'jumpPhoneWidget: onclick');
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    TipsJumpUtils.jumpHome(context, '2', FUN_NAME_BEIDOU_MESSAGE);
  }

  /**
   * Register to listen to the change event of the satellite toast.
   */
  public subscribeSatelliteToastEvent() {
    CommonEventManager.createSubscriber(satelliteToastInfo, (err: BusinessError, commonEventSubscriber:
      CommonEventManager.CommonEventSubscriber) => {
      if (err) {
        LogUtils.e(TAG, 'subscribeSatelliteToastEvent: createSubscriber err=' + JSON.stringify(err));
        return;
      }
      primarySubscriberQueue.add(commonEventSubscriber);
      LogUtils.i(TAG, 'subscribeSatelliteToastEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      CommonEventManager.subscribe(commonEventSubscriber, (err: BusinessError,
        data: CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.e(TAG, 'subscribeSatelliteToastEvent: callback err=' + JSON.stringify(err));
          return;
        }
        LogUtils.i(TAG, 'subscribeSatelliteToastEvent action = ' + data?.event);
        if (data.event === 'event.custom.satellite.ACTION_SATELLITE_TOAST') {
          this.showSatelliteToast(data.code as number);
        } else if (data.event === 'event.custom.ims.ACTION_IMPU_READY') {
          this.getActiveSimInfoCT(true);
          this.getSimListChange();
        }
      });
    });
  }

  private showSatelliteToast(code: number) {
    let messageResource: Resource = $r('app.string.satellite_service_not_enabled');
    if (code === SATELLITE_TOAST_OFF_CODE) {
      messageResource = $r('app.string.satellite_service_not_enabled');
    } else if (code === SATELLITE_TOAST_AIRPLANE_CODE) {
      messageResource = $r('app.string.satellite_service_settings_airplane_mode');
    }
    promptAction.showToast({
      message: messageResource,
      duration: SATELLITE_TOAST_DURATION
    });
  }

  /**
   * Unregister the change event of the satellite toast
   */
  public unSubscribeSatelliteToastEvent() {
    try {
      let primarySubscriber = primarySubscriberQueue.pop();
      LogUtils.i(TAG, 'unSubscribeSatelliteToastEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      if (primarySubscriber === null) {
        LogUtils.e(TAG, 'unSubscribeSatelliteToastEvent primarySubscriber is null');
        return;
      }
      CommonEventManager.unsubscribe(primarySubscriber, (err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, 'unSubscribeSatelliteToastEvent failed, err = ' + JSON.stringify(err));
        }
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `unSubscribeSatelliteToastEvent failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  unRegisterData() {
    unRegisterSimStateChange();
    unRegisterAccountInfoChange();
    this.unSubscribeSatelliteToastEvent();
  }
}