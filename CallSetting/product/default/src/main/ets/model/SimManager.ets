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

import { Callback } from '@ohos.base';
import sim from '@ohos.telephony.sim';
import { LogUtils } from '@ohos/common/CommonIndex';
import { BusinessError } from '@ohos.base';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import { radio } from '@kit.TelephonyKit';
import { settings } from '@kit.BasicServicesKit';
import { CarrierType, SatelliteType, SATELLITE_KEY_CARRIER_TYPE } from '../common/constant/SatelliteSearchConst';

interface OperaNameNcc {
  id: number
  plmn: string
}

interface OperaMcc {
  id: number
  mcc: string
}

const TAG = 'SimManager';
const CT_OPERA_LIST: OperaNameNcc[] = [
  {
    id: 1,
    plmn: '46003'
  },
  {
    id: 2,
    plmn: '46004'
  },
  {
    id: 3,
    plmn: '46005'
  },
  {
    id: 4,
    plmn: '46011'
  },
  {
    id: 5,
    plmn: '46059'
  },
  {
    id: 6,
    plmn: '45431'
  },
  {
    id: 7,
    plmn: '45507'
  }
];

const UNICOM_OPERA_LIST: OperaNameNcc[] = [
  {
    id: 1,
    plmn: '46001'
  },
  {
    id: 2,
    plmn: '46009'
  }
];

const CHINA_MOBILE_OPERA_LIST_FOR_TIANTONG: OperaNameNcc[] = [
  {
    id: 1,
    plmn: '46000'
  },
  {
    id: 2,
    plmn: '46002'
  },
  {
    id: 3,
    plmn: '46007'
  },
  {
    id: 4,
    plmn: '46070'
  }
]

const CHINA_MOBILE_OPERA_LIST: OperaNameNcc[] = [
  {
    id: 1,
    plmn: '46000'
  },
  {
    id: 2,
    plmn: '46002'
  },
  {
    id: 3,
    plmn: '46007'
  },
  {
    id: 4,
    plmn: '46008'
  },
  {
    id: 5,
    plmn: '45412'
  },
  {
    id: 6,
    plmn: '46070'
  }
];

const OTHER_OPERA_LIST: OperaNameNcc[] = [
  {
    id: 1,
    plmn: '45400'
  },
  {
    id: 2,
    plmn: '45419'
  },
  {
    id: 3,
    plmn: '45403'
  },
  {
    id: 4,
    plmn: '45404'
  },
  {
    id: 5,
    plmn: '45406'
  },
  {
    id: 6,
    plmn: '45415'
  },
  {
    id: 7,
    plmn: '45702'
  }
];

const SUPPORT_MCC: OperaMcc[] = [
  {
    id: 1,
    mcc: '460'
  },
  {
    id: 2,
    mcc: '454'
  },
  {
    id: 3,
    mcc: '455'
  },
  {
    id: 4,
    mcc: '457'
  },
  {
    id: 5,
    mcc: '450'
  },
  {
    id: 6,
    mcc: '525'
  },
  {
    id: 7,
    mcc: '456'
  },
  {
    id: 8,
    mcc: '502'
  },
  {
    id: 9,
    mcc: '515'
  },
  {
    id: 10,
    mcc: '520'
  }
];

const STAR_OPERA_LIST: OperaNameNcc[] = [
  {
    id: 1,
    plmn: '46019'
  },
  {
    id: 2,
    plmn: '46070'
  }
];

const LOCAL_VERSION = 202410280919;

function isSimStateReady(state: number): boolean {
  return state === sim.SimState.SIM_STATE_LOADED || state === sim.SimState.SIM_STATE_READY;
}

function notifySimCount(isSimStateActive: boolean[], callback: Callback<number>) {
  let activeCount = 0;
  for (let isActive of isSimStateActive) {
    if (isActive) {
      activeCount++;
    }
  }
  callback(activeCount);
}

export async function getActiveSimCount(callback: Callback<number>) {
  const maxSimCount = sim.getMaxSimCount();
  let isSimStateActive: boolean[] = [false, false];

  try {
    for (let i = 0; i < maxSimCount; i++) {
      // Force check if just register
      isSimStateActive[i] = isSimStateReady(sim.getSimStateSync(i))
    }
  } catch (error) {
    LogUtils.e(TAG, 'Check sim count error! ' + JSON.stringify(error));
    return;
  }

  // Invoke the callback immediately to make this event sticky
  notifySimCount(isSimStateActive, callback);
}

export function getSimOperatorNumericSync(slotId: number): string {
  return sim.getSimOperatorNumericSync(slotId);
}

export async function isSupportRegionCard(slotId: number): Promise<boolean> {
  LogUtils.i(TAG, 'isSupportRegionCard slotId = ' + slotId);
  let networkState: radio.NetworkState = await radio.getNetworkState(slotId);
  if (!networkState || !networkState.plmnNumeric || networkState.plmnNumeric.length < 3) {
    return true;
  }
  if (isSupportMcc(networkState.plmnNumeric.substring(0, 3))) {
    return true;
  }
  return false;
}

/**
 * 是否是支持北斗卫星短信的卡
 * @param slotId SIM卡ID
 * @returns 是否支持
 */
export async function isSupportBeiDouMessageCard(slotId: number): Promise<boolean> {
  LogUtils.i(TAG, 'isSupportCard slotId = ' + slotId);
  if (isSupportBeiDouPlmn(slotId)) {
    let networkState: radio.NetworkState = await radio.getNetworkState(slotId);
    if (!networkState || !networkState.plmnNumeric || networkState.plmnNumeric.length < 3) {
      return true;
    }
    if (isSupportMcc(networkState.plmnNumeric.substring(0, 3))) {
      return true;
    }
  }
  return false;
}

// satelliteType 1--天通 2--风信子
export function isSupportPlmn(slotId: number, satelliteType: number): boolean {
  let cardPlmn = getSimOperatorNumericSync(slotId);
  LogUtils.i(TAG, `isSupportPlmn is called ${satelliteType}, ${cardPlmn}`);
  if (isUnicomCard(cardPlmn)) {
    return true;
  }
  if (satelliteType === SatelliteType.HYACINTH) {
    if (isSupportOperaList(cardPlmn, STAR_OPERA_LIST)) {
      LogUtils.i(TAG, 'Star network card');
      return true;
    }
  } else {
    if (checkVersion()) {
      let plmnArray = getPlmnWhiteList();
      if (plmnArray !== undefined) {
        return isWhiteListSupport(cardPlmn, plmnArray);
      }
      return false;
    }
    if (isCtCard(cardPlmn)) {
      return true;
    }
    if (isChinaMobileCardForTiantong(cardPlmn)) {
      return true;
    }
    if (isOtherCard(cardPlmn)) {
      return true;
    }
  }
  return false;
}

export function isSupportOperaList(cardPlmn: string, operaList: OperaNameNcc[]) {
  for (let operNcc of operaList) {
    if (cardPlmn === operNcc.plmn) {
      return true;
    }
  }
  return false;
}

export function isSupportBeiDouPlmn(slotId: number): boolean {
  LogUtils.i(TAG, 'isSupportBeiDouPlmn is called');
  let cardPlmn = getSimOperatorNumericSync(slotId);
  if (checkVersion()) {
    let plmnArray = getPlmnWhiteList();
    if (plmnArray !== undefined) {
      return isWhiteListSupport(cardPlmn, plmnArray);
    }
    return false;
  }
  if (isChinaMobileCard(cardPlmn)) {
    return true;
  }
  return false;
}


function isWhiteListSupport(cardPlmn: string, plmnArray: string[]): boolean {
  let isWhiteListContain = false;
  plmnArray.forEach((plmn: string) => {
    if (cardPlmn === plmn) {
      LogUtils.i(TAG, 'support cardPlmn')
      isWhiteListContain = true;
      return;
    }
  })
  return isWhiteListContain;
}

export function isCtCard(cardPlmn: string) {
  let isCtCard: boolean = false;
  CT_OPERA_LIST.forEach((operNcc: OperaNameNcc) => {
    if (cardPlmn === operNcc.plmn) {
      LogUtils.i(TAG, 'isCtCard')
      isCtCard = true;
      return;
    }
  })
  return isCtCard;
}

export function isUnicomCard(cardPlmn: string) {
  let isUnicomCard: boolean = false;
  UNICOM_OPERA_LIST.forEach((operNcc: OperaNameNcc) => {
    if (cardPlmn === operNcc.plmn) {
      LogUtils.i(TAG, 'isUnicomCard')
      isUnicomCard = true;
      return;
    }
  })
  return isUnicomCard;
}

export function isChinaMobileCard(cardPlmn: string) {
  let isChinaMobileCard: boolean = false;
  CHINA_MOBILE_OPERA_LIST.forEach((operNcc: OperaNameNcc) => {
    if (cardPlmn === operNcc.plmn) {
      LogUtils.i(TAG, 'isChinaMobileCard')
      isChinaMobileCard = true;
      return;
    }
  })
  return isChinaMobileCard;
}

export function isOtherCard(cardPlmn: string) {
  let isOtherCard: boolean = false;
  OTHER_OPERA_LIST.forEach((operNcc: OperaNameNcc) => {
    if (cardPlmn === operNcc.plmn) {
      LogUtils.i(TAG, 'isOtherCard');
      isOtherCard = true;
      return;
    }
  })
  return isOtherCard;
}

export function isChinaMobileCardForTiantong(cardPlmn: string): boolean {
  for (let operNcc of CHINA_MOBILE_OPERA_LIST_FOR_TIANTONG) {
    if (cardPlmn === operNcc.plmn) {
      LogUtils.i(TAG, 'isChinaMobileCardForTiantong');
      return true;
    }
  }
  return false;
}

export function getPlmnWhiteList(): string[] | undefined {
  let whiteString: string =
    SystemParameterEnhance.getSync('persist.telephony.satellite.satellite_supported_carriers_mccmnc', '[]');
  if (!whiteString || whiteString === '[]') {
    return undefined;
  }
  whiteString = whiteString.replace('[', '').replace(']', '');
  let plmnArray = whiteString.split(',');
  return plmnArray;
}

function checkVersion(): boolean {
  let version: string = SystemParameterEnhance.getSync('persist.telephony.satellite.satellite_supported_version', '0');
  try {
    let versionNumber = Number(version);
    return versionNumber > LOCAL_VERSION;
  } catch (error) {
    LogUtils.e(TAG, 'setCallForward catch error: ' + (error as BusinessError).message);
  }
  return false;
}

function isSupportMcc(regMcc: string) {
  LogUtils.i(TAG, 'isSupportMcc regMcc =' + regMcc);
  let isSupport = false;
  if (checkVersion()) {
    let isSupportMcc: string =
      SystemParameterEnhance.getSync('persist.telephony.satellite.satellite_supported_carriers_mcc', '[]');
    LogUtils.i(TAG, 'isSupportMcc =' + isSupportMcc);
    if (!isSupportMcc || isSupportMcc === '[]') {
      return false;
    }
    isSupportMcc = isSupportMcc.replace('[', '').replace(']', '');
    let mccArray = isSupportMcc.split(',');
    mccArray.forEach((whiteMcc: string) => {
      if (whiteMcc === regMcc) {
        LogUtils.i(TAG, 'isSupportMcc is true for mcc white list');
        isSupport = true;
        return;
      }
    })
    return isSupport;
  }
  SUPPORT_MCC.forEach((supportMcc: OperaMcc) => {
    if (supportMcc.mcc === regMcc) {
      LogUtils.i(TAG, 'isSupportMcc is true for support mcc')
      isSupport = true;
      return;
    }
  })
  return isSupport;
}

export function getActiveSimInfo(callback: (data: Array<sim.IccAccountInfo>) => void) {
  sim.getActiveSimAccountInfoList((err: BusinessError, data: Array<sim.IccAccountInfo>) => {
    if (err) {
      LogUtils.i(TAG, `getActiveSimInfo callback: err->${JSON.stringify(err)}`);
      callback([]);
      return;
    }
    LogUtils.i(TAG, `getActiveSimInfo callback: data->${JSON.stringify(data?.length)}`);
    callback(data);
  });
}

export async function getActiveSimInfoAsync(): Promise<Array<sim.IccAccountInfo>> {
  try {
    let data: sim.IccAccountInfo[] = await sim.getActiveSimAccountInfoList();
    LogUtils.i(TAG, `getActiveSimInfo callback: data->${data?.length}`);
    return data;
  } catch (err) {
    LogUtils.e(TAG, `getActiveSimInfo callback: errCode: ${err?.code}, message: ${err?.message}`);
    return [];
  }
}

export async function getIMSI(slotId: number, callback: (imsi: string) => void) {
  await sim.getIMSI(slotId).then((data: string) => {
    LogUtils.i(TAG, `isOpened callback: data->${JSON.stringify(data?.length)}`);
    callback(data);
  }).catch((err: BusinessError) => {
    LogUtils.i(TAG, `isOpened callback: err->${JSON.stringify(err)}`);
    callback('');
  });
}

/**
 * 设置运营商  中国电信，中国移动，中国联通，其他
 * @param context
 * @param slotId
 */
export function saveCarrierType(context: Context, slotId: number) {
  if (!context) {
    LogUtils.e(TAG, 'saveCarrierType context is undefined');
    return;
  }
  try {
    let carrierType = getSimOperatorNumericSync(slotId);
    if (isCtCard(carrierType)) {
      settings.setValueSync(context, SATELLITE_KEY_CARRIER_TYPE, CarrierType.CARRIER_CT);
    } else if (isUnicomCard(carrierType)) {
      settings.setValueSync(context, SATELLITE_KEY_CARRIER_TYPE, CarrierType.CARRIER_UNICOM);
    } else if (isChinaMobileCard(carrierType)) {
      settings.setValueSync(context, SATELLITE_KEY_CARRIER_TYPE, CarrierType.CARRIER_CMCC);
    } else {
      settings.setValueSync(context, SATELLITE_KEY_CARRIER_TYPE, CarrierType.CARRIER_OTHER);
    }
  } catch (err) {
    LogUtils.e(TAG, `saveCarrierType error: ${err?.code} ${err?.message}`);
  }
}