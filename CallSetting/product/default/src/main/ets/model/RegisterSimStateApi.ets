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

/**
 * @file: registerSimStateApi
 */
import observer from '@ohos.telephony.observer';
import { LogUtils, MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';
import sim from '@ohos.telephony.sim';
import dataShare from '@ohos.data.dataShare';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

const TAG = 'registerSimStateAPi';
let dataShareHelper: dataShare.DataShareHelper | undefined;
let dataRoamingShareHelper1: dataShare.DataShareHelper | undefined;
let dataRoamingShareHelper2: dataShare.DataShareHelper | undefined;

/**
 * Path of cellular_data_enable in the database
 */
const ON_SETTING_CELLULAR_DATA_ENABLE_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key=cellular_data_enable';
/**
 * Path of cellular_data_roaming_enable in the database
 */
const ON_SETTING_CELLULAR_DATA_ROAMING_ENABLE1_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key=cellular_data_roaming_enable1';

const ON_SETTING_CELLULAR_DATA_ROAMING_ENABLE2_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key=cellular_data_roaming_enable2';

let simCount: number = -1;

/**
 * Monitor the SIM card status
 *
 * @param {function} callBack - call-back
 * @param {string} slotId - card The slot id
 */
export function registerSimStateChangeForSlotId(slotId: number, callBack: Function) {
  return observer.on('simStateChange', {
    slotId: slotId
  }, (callStateInfo) => {
    LogUtils.i(TAG, 'registerSimStateChangeForSlotId: then ' + JSON.stringify(callStateInfo))
    callBack(callStateInfo);
    return callStateInfo
  });
}

export function registericcAccountInfoChange(callBack: Function) {
  return observer.on('iccAccountInfoChange', () => {
    callBack();
    return;
  });
}

export function registerSimStateChange(callBack: Function) {
  return observer.on('simStateChange', (callStateInfo) => {
    LogUtils.i(TAG, 'registerSimStateChange: then ' + JSON.stringify(callStateInfo))
    if (callStateInfo.state === 4 || callStateInfo.state === 5) {
      callBack(true);
    } else {
      callBack(false);
    }
    return callStateInfo;
  });
}

export function unRegisterSimStateChange() {
  return observer.off('simStateChange', () => {
    LogUtils.i(TAG, 'unRegisterSimStateChange');
  });
}

export function registerCallStateChange(options: observer.ObserverOptions, callBack: Function) {
  return observer.on('callStateChange', options, (data: observer.CallStateInfo) => {
    callBack(data);
  });
}

export function unRegisterCallStateChange() {
  return observer.off('callStateChange', () => {
    LogUtils.i(TAG, 'unRegisterCallStateChange');
  });
}

export function registerNetworkStateChange(slotId: number, callBack: Function) {
  return observer.on('networkStateChange', {
    slotId: slotId
  }, (netWorkStateInfo) => {
    LogUtils.i(TAG, 'registernetworkStateChange callBack.');
    callBack(netWorkStateInfo);
  });
}

export function unRegisterNetworkStateChange() {
  return observer.off('networkStateChange', () => {
    LogUtils.i(TAG, 'unRegisterNetworkStateChange');
  });
}

export function registerAccountInfoChange(callBack: Function) {
  return observer.on('iccAccountInfoChange', () => {
    LogUtils.i(TAG, 'on iccAccountInfoChange success');
    callBack();
  });
}

export function unRegisterAccountInfoChange() {
  return observer.off('iccAccountInfoChange', () => {
    LogUtils.i(TAG, 'unRegisterAccountInfoChange');
  });
}

/**
 * add CellularDataSettingChange Listener.
 */
export function registerCellularDataSettingChange(callback: Function) {
  LogUtils.i(TAG, 'registerCellularDataSettingChange');
  try {
    dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT),
      ON_SETTING_CELLULAR_DATA_ENABLE_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err !== undefined) {
          LogUtils.e(TAG, 'registerCellularDataSettingChange error: code: ' + err.code + ', message: ' + err.message);
          return;
        }
        dataShareHelper = data;
        try {
          dataShareHelper.on('dataChange', ON_SETTING_CELLULAR_DATA_ENABLE_URI, () => {
            LogUtils.i(TAG, 'registerCellularDataSettingChange dataChange');
            callback();
          });
          LogUtils.i(TAG, 'registerCellularDataSettingChange success');
        } catch (err) {
          let error: BusinessError = err as BusinessError;
          LogUtils.e(TAG, 'registerCellularDataSettingChange error: code: ' + error.code + ', message: ' +
          error.message);
        }
      });
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    LogUtils.e(TAG, 'registerCellularDataSettingChange error: code: ' + error.code + ', message: ' + error.message);
  }
}

/**
 * add CellularDataRoamingSettingChange Listener.
 */
export function registerCellularDataRoamingSettingChange(slotId: number, callback: Function) {
  LogUtils.i(TAG, 'registerCellularDataRoamingSettingChange');
  let roamingEnableUri = '';
  if (slotId === 1) {
    roamingEnableUri = ON_SETTING_CELLULAR_DATA_ROAMING_ENABLE2_URI;
  } else {
    roamingEnableUri = ON_SETTING_CELLULAR_DATA_ROAMING_ENABLE1_URI;
  }
  try {
    dataShare.createDataShareHelper(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT),
      roamingEnableUri, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err !== undefined) {
          LogUtils.e(TAG, `registerCellularDataRoamingSettingChange error:  ${err?.code} ${err?.message}`);
          return;
        }
        if (slotId === 0) {
          dataRoamingShareHelper1 = data;
        } else {
          dataRoamingShareHelper2 = data;
        }
        try {
          data.on('dataChange', roamingEnableUri, () => {
            LogUtils.i(TAG, 'registerCellularDataRoamingSettingChange dataChange ' + slotId);
            callback();
          });
          LogUtils.i(TAG, 'registerCellularDataRoamingSettingChange success ' + slotId);
        } catch (err) {
          LogUtils.e(TAG, `registerCellularDataRoamingSettingChange error:  ${err?.code} ${err?.message}`);
        }
      });
  } catch (err) {
    LogUtils.e(TAG, `registerCellularDataRoamingSettingChange error:  ${err?.code} ${err?.message}`);
  }
}

/**
 * remove CellularDataRoamingSetting Listener.
 */
export function removeCellularDataRoamingSettingListener(slotId: number) {
  try {
    if (slotId === 0 && dataRoamingShareHelper1) {
      LogUtils.i(TAG, 'removeCellularDataRoamingSettingListener ' + slotId);
      dataRoamingShareHelper1.off('dataChange', ON_SETTING_CELLULAR_DATA_ROAMING_ENABLE1_URI);
    }
    if (slotId === 1 && dataRoamingShareHelper2) {
      LogUtils.i(TAG, 'removeCellularDataRoamingSettingListener ' + slotId);
      dataRoamingShareHelper2.off('dataChange', ON_SETTING_CELLULAR_DATA_ROAMING_ENABLE2_URI);
    }
  } catch (err) {
    LogUtils.e(TAG, `removeCellularDataRoamingSettingListener error:  ${err?.code} ${err?.message}`);
  }
}

export function unRegisterCellularDataSettingChange() {
  return observer.off('cellularDataConnectionStateChange', () => {
    LogUtils.i(TAG, 'registercellularDataConnectionStateChange');
  });
}

export function getMaxSimCount() {
  if (simCount !== -1) {
    return simCount;
  } else {
    simCount = sim.getMaxSimCount();
    return simCount;
  }
}

export function getActiveSimInfo(callback: (data: Array<sim.IccAccountInfo>) => void) {
  sim.getActiveSimAccountInfoList((err: BusinessError, data: Array<sim.IccAccountInfo>) => {
    if (err !== undefined) {
      LogUtils.i(TAG, `getActiveSimInfo callback: err}`);
      callback([]);
      return;
    }
    callback(data);
  });
}
