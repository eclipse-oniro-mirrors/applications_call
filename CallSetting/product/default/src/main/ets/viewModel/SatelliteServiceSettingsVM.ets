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
import { LogUtils, CallSettingGlobalContextHelper, SatelliteSimCardInfoStruct } from '@ohos/common/CommonIndex';
import { getActiveSimInfo, getActiveSimInfoAsync, getIMSI, isSupportPlmn } from '../model/SimManager';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import TipsJumpUtils, { FUN_NAME_SATELLITE, FUN_NAME_HYACINTH } from '../common/utils/PlaySkillsJumpUtils';
import { common, Want } from '@kit.AbilityKit';
import {
  getMaxSimCount,
  registerAccountInfoChange,
  registerSimStateChangeForSlotId,
  unRegisterAccountInfoChange,
  unRegisterSimStateChange
} from '../model/RegisterSimStateApi';
import {
  getHyacinthPreferences,
  getPreferences,
  setShowName,
  getShowNameBySatelliteType
} from '../model/SatelliteServiceSettingModel';
import { Queue } from '@kit.ArkTS';
import CommonEventManager from '@ohos.commonEventManager';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import {
  SatelliteType,
  SATELLITE_KEY_SLOT_ID,
  SATELLITE_TOAST_AIRPLANE_CODE,
  SATELLITE_TOAST_DURATION,
  SATELLITE_TOAST_OFF_CODE
} from '../common/constant/SatelliteSearchConst';

const TAG = 'SatelliteToggleSelectedVM';

let primarySubscriberQueue: Queue<CommonEventManager.CommonEventSubscriber> = new Queue();

let satelliteToastInfo: CommonEventManager.CommonEventSubscribeInfo = {
  events: ['event.custom.satellite.ACTION_SATELLITE_TOAST',
  'event.custom.ims.ACTION_IMPU_READY'],
  publisherPermission: 'ohos.permission.SET_TELEPHONY_STATE'
};

export default class SatelliteServiceSettingsVM {
  private static mSatelliteServiceSettingsVM: SatelliteServiceSettingsVM;
  public simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  public hyacinthSimCardInfoList: SatelliteSimCardInfoStruct[] = [];
  private isSimActive: boolean = false;
  private isSim1Active: boolean = false;
  private isSim2Active: boolean = false;
  public simActiveState: (arg: boolean) => void = (arg) => {
  };
  public isStartSatelliteService: boolean = false;
  public satelliteType: number = SatelliteType.TIAN_TONG; // 默认天通

  public static getInstance(satelliteType: number = SatelliteType.TIAN_TONG): SatelliteServiceSettingsVM {
    if (!SatelliteServiceSettingsVM.mSatelliteServiceSettingsVM) {
      SatelliteServiceSettingsVM.mSatelliteServiceSettingsVM = new SatelliteServiceSettingsVM();
    }
    SatelliteServiceSettingsVM.mSatelliteServiceSettingsVM.satelliteType = satelliteType;
    LogUtils.i(TAG, `getInstance type: ${SatelliteServiceSettingsVM.mSatelliteServiceSettingsVM.satelliteType}`);
    return SatelliteServiceSettingsVM.mSatelliteServiceSettingsVM;
  }

  aboutToAppear(satelliteType: number = SatelliteType.TIAN_TONG): void {
    this.satelliteType = satelliteType;
    this.registerData();
  }

  setSimCardName() {
    if (this.simCardInfoList === undefined || this.simCardInfoList === null || this.simCardInfoList.length === 0) {
      let showValue = $r('app.string.satellite_service_no_sim_card')
      AppStorage.setOrCreate(getShowNameBySatelliteType(this.satelliteType), showValue);
      return;
    } else {
      setShowName(this.simCardInfoList, this.satelliteType);
    }
  }

  getActiveSimInfoCT(isConnected: boolean) {
    LogUtils.i(TAG, 'splice simCardInfoList getActiveSimInfoCT');
    this.simCardInfoList.splice(0, this.simCardInfoList.length);
    if (!isConnected) {
      this.setSimCardName();
      if (this.satelliteType === SatelliteType.HYACINTH) {
        this.hyacinthSimCardInfoList = this.simCardInfoList;
        AppStorage.setOrCreate('hyacinthSimCardInfoList', this.hyacinthSimCardInfoList);
      } else {
        AppStorage.setOrCreate('simCardInfoList', this.simCardInfoList);
      }
      return;
    }
    getActiveSimInfo((data: Array<sim.IccAccountInfo>) => {
      LogUtils.i(TAG, `getActiveSimInfo data.length: ${data.length}`);
      try {
        if (data.length === 0) {
          this.setSimCardName();
          LogUtils.i(TAG, 'getActiveSimInfo is null');
        } else {
          this.updateSimInfoList(data);
        }
      } catch (error) {
        LogUtils.e(TAG, `getActiveSimInfo failed: ${error?.code}`);
      }
    })
  }

  async setActiveSimInfoCT() {
    LogUtils.i(TAG, 'splice simCardInfoList setActiveSimInfoCT');
    this.simCardInfoList.splice(0, this.simCardInfoList.length);
    let data: sim.IccAccountInfo[] = await getActiveSimInfoAsync();
    if (data.length === 0) {
      this.setSimCardName();
      LogUtils.i(TAG, 'getActiveSimInfo is null');
    } else {
      await this.updateSimInfoList(data);
    }
  }

  async updateSimInfoList(data: Array<sim.IccAccountInfo>) {
    for (let i = 0; i < data.length; i++) {
      let item = data[i];
      if (isSupportPlmn(item.slotIndex, this.satelliteType)) {
        await this.updateShowNumber(item);
        await this.checkIMSI(item);
      }
    }
    this.handleSimCardInfo();
  }

  startSatelliteService(context?: common.UIAbilityContext | common.ServiceExtensionContext) {
    LogUtils.i(TAG, 'startSatelliteService is called');
    let mContext = context ?? getContext(this) as common.UIAbilityContext;
    let want: Want = {
      bundleName: 'com.ohos.callsetting',
      abilityName: 'com.ohos.callsetting.SatelliteService',
      parameters: {
        satelliteType: this.satelliteType
      }
    };
    LogUtils.i(TAG, `satelliteType: ${this.satelliteType}`);

    mContext.startAbility(want, (err) => {
      LogUtils.e(TAG, `Failed to start satellite service. Code: ${err.code}, message: ${err.message}`);
    });
  }

  checkHasPreferences() {
    getPreferences((simData: string[]) => {
      if (simData.length) {
        let imsi = simData[3];
        let simInfo: SatelliteSimCardInfoStruct[] = this.simCardInfoList.filter((item) => item.iMsi === imsi);
        if (simInfo !== undefined) {
          simInfo[0].isChecked = true;
          LogUtils.i(TAG, 'splice simCardInfoList checkHasPreferences');
          this.simCardInfoList.splice(simInfo[0].slotId === 0 ? 0 : 1, 1, simInfo[0]);
          if (this.satelliteType === SatelliteType.HYACINTH) {
            this.hyacinthSimCardInfoList = this.simCardInfoList;
            AppStorage.setOrCreate('hyacinthSimCardInfoList', this.hyacinthSimCardInfoList);
          } else {
            AppStorage.setOrCreate('simCardInfoList', this.simCardInfoList);
          }
          let context = CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
          try {
            settings.setValueSync(context, SATELLITE_KEY_SLOT_ID, String(simInfo[0].slotId));
          } catch (err) {
            LogUtils.e(TAG, `checkHasPreferences: setValueSync error: ${err?.code} ${err?.message}`);
          }
          this.setSimCardName();
          LogUtils.i(TAG, `isHasPreferences simInfo length: ${this.simCardInfoList.length}`);
        }
      }
    })
  }

  checkHasPreferencesForHyacinth() {
    getHyacinthPreferences((simData: string[]) => {
      if (simData.length) {
        let imsi = simData[3];
        let simInfo: SatelliteSimCardInfoStruct[] = this.simCardInfoList.filter((item) => item.iMsi === imsi);
        if (simInfo !== undefined) {
          simInfo[0].isHyacinthChecked = true;
          LogUtils.i(TAG, 'splice simCardInfoList checkHasPreferencesForHyacinth');
          this.simCardInfoList.splice(simInfo[0].slotId === 0 ? 0 : 1, 1, simInfo[0]);
          if (this.satelliteType === SatelliteType.HYACINTH) {
            this.hyacinthSimCardInfoList = this.simCardInfoList;
            AppStorage.setOrCreate('hyacinthSimCardInfoList', this.hyacinthSimCardInfoList);
          } else {
            AppStorage.setOrCreate('simCardInfoList', this.simCardInfoList);
          }
          let context = CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
          try {
            settings.setValueSync(context, SATELLITE_KEY_SLOT_ID, String(simInfo[0].slotId));
          } catch (err) {
            LogUtils.e(TAG, `checkHasPreferencesForHyacinth: setValueSync error: ${err?.code} ${err?.message}`);
          }
          this.setSimCardName();
          LogUtils.i(TAG, `isHasPreferencesForHyacinth simInfo length: ${this.simCardInfoList.length}`);
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
    LogUtils.i(TAG, 'checkIMSI isSateCard has loaded');
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
      if (this.satelliteType === SatelliteType.HYACINTH) {
        this.hyacinthSimCardInfoList = this.simCardInfoList;
        AppStorage.setOrCreate('hyacinthSimCardInfoList', this.hyacinthSimCardInfoList);
      } else {
        AppStorage.setOrCreate('simCardInfoList', this.simCardInfoList);
      }
      this.setSimCardName();
    } else if (this.simCardInfoList.length === 2) {
      this.simCardInfoList.sort((o1: SatelliteSimCardInfoStruct, o2: SatelliteSimCardInfoStruct) => {
        return o1.slotId < o2.slotId ? -1 : 1;
      })
      if (this.satelliteType === SatelliteType.HYACINTH) {
        this.hyacinthSimCardInfoList = this.simCardInfoList;
        AppStorage.setOrCreate('hyacinthSimCardInfoList', this.hyacinthSimCardInfoList);
      } else {
        AppStorage.setOrCreate('simCardInfoList', this.simCardInfoList);
      }
      //End twice, and then judge whether it has been stored.
      if (this.satelliteType === SatelliteType.HYACINTH) {
        this.checkHasPreferencesForHyacinth();
      } else {
        this.checkHasPreferences();
      }

      this.setSimCardName();
    }
  }

  simStateChange(simInfo: SatelliteSimCardInfoStruct, item: sim.IccAccountInfo, iMsi: string) {
    simInfo.slotId = item.slotIndex;
    simInfo.showNumber = item.showNumber;
    simInfo.iMsi = iMsi;
    simInfo.isEsim = item.isEsim;
    // simInfo.simLabelIndex = item.simLabelIndex;
    let targetObj = this.simCardInfoList.find((info: SatelliteSimCardInfoStruct) =>
      info.slotId === item.slotIndex);
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

  hasOneCard(): boolean {
    return this.simCardInfoList !== undefined && this.simCardInfoList.length === 1;
  }

  registerData() {
    this.registerSimSateChange();
    this.addRegisterAccountInfoChange();
    this.subscribeSatelliteToastEvent();
  }

  registerSimSateChange() {
    try {
      let maxSimCount: number = getMaxSimCount();
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

  addSimStateActiveChangeListener(fn: (arg: boolean) => void): void {
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
        LogUtils.i(TAG, 'splice simCardInfoList getSimListChange');
        this.simCardInfoList.splice(0, this.simCardInfoList.length);
        this.setSimCardName();
        if (this.satelliteType === SatelliteType.HYACINTH) {
          this.hyacinthSimCardInfoList = this.simCardInfoList;
          AppStorage.setOrCreate('hyacinthSimCardInfoList', this.hyacinthSimCardInfoList);
        } else {
          AppStorage.setOrCreate('simCardInfoList', this.simCardInfoList);
        }
      }
    }
  }

  jumpPhoneWidget() {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    LogUtils.i(TAG, `jumpPhoneWidget onclick context ${context}`);
    if (this.satelliteType === SatelliteType.HYACINTH) {
      TipsJumpUtils.jumpHome(context, '2', FUN_NAME_HYACINTH);
    } else {
      TipsJumpUtils.jumpHome(context, '2', FUN_NAME_SATELLITE);
    }
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
          this.getSimListChange();
        }
      });
    });
  }

  private showSatelliteToast(code: number) {
    let messageResource: Resource = $r('app.string.satellite_service_not_enabled');
    if (code === SATELLITE_TOAST_OFF_CODE) {
      messageResource =
        this.satelliteType === SatelliteType.TIAN_TONG ? $r('app.string.satellite_service_not_enabled') :
        $r('app.string.hyacinth_satellite_service_not_enabled');
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