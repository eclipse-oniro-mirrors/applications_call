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
 * @file: RegisterStateApiForSatellite
 */

// @ts-ignore
import satellite from '@ohos.telephony.satellite';
// @ts-ignore
import { SatelliteData, SatelliteStatus, SmcSatelliteData } from '../../manager/SatelliteSearchManager';

const TAG = 'SatelliteServiceApi';

// @ts-ignore
export async function startSatelliteService(slotId: number, satelliteType: number): number {
  console.info(TAG + ': startSatelliteService is called');
  try {
    let insertData = await satellite.startSatelliteService(slotId, satelliteType);
    console.info(TAG + ': startSatelliteService, insertData : ' + insertData);
    return insertData;
  } catch (error) {
    console.error(`SatelliteServiceApi: startSatelliteService error: code: ${error}, message: ${error}`);
    return -1;
  }
}

// @ts-ignore 接口有稳定性问题，原因是协议已日落此接口，删除其调用
export function getSatelliteHardwareSupportInfo(type: number): boolean {
  try {
    let support = satellite.getSatelliteHardwareSupportInfo(type);
    console.info(TAG + ': getSatelliteHardwareSupportInfo, insertData : ' + support);
    return support;
  } catch (error) {
    console.error(`SatelliteServiceApi: getSatelliteHardwareSupportInfo error: ${error}`);
    return true;
  }
}

// @ts-ignore
export async function stopSatelliteService(slotId: number, satelliteType: number): number {
  console.info(TAG + ': stopSatelliteService is called');
  try {
    let insertData = await satellite.stopSatelliteService(slotId, satelliteType);
    console.info(TAG + ': stopSatelliteService, insertData : ' + insertData);
    return insertData;
  } catch (error) {
    console.error(`SatelliteServiceApi: stopSatelliteService error: code: ${error}, message: ${error}`);
    return -1;
  }
}

// @ts-ignore
export function notifySatelliteInfo(callBack: Function): void {
  console.info(TAG + ': notifySatelliteInfo');
  satellite.on('notifySatelliteInfo', (satelliteInfo: satellite.SatelliteInfo) => {
    let satelliteData: SatelliteData = {
      azimuthDelta: satelliteInfo.azimuthDelta,
      pitchAngleDelta: satelliteInfo.pitchAngleDelta,
      signal: 0,
      sateIdx: satelliteInfo.sateIdx,
      sateShow: satelliteInfo.sateShow,
      availableTime: satelliteInfo.availableTime,
      guideAzimuth: satelliteInfo.guideAzimuth,
      guidePitch: satelliteInfo.guidePitch
    };
    callBack(satelliteData);
  });
}

// @ts-ignore
export function offSatelliteInfo(callBack: Function): void {
  console.info(TAG + ': offSatelliteInfo');
  return satellite.off('notifySatelliteInfo', (satelliteInfo: satellite.SatelliteInfo) => {
    console.info(TAG + ': offSatelliteInfo is called result');
    callBack();
  });
}

// @ts-ignore
export function notifySatelliteStatus(callBack: Function): void {
  console.info(TAG + ': notifyServiceStatus');
  return satellite.on('notifyServiceStatus', (serviceStatus: satellite.ServiceStatus) => {
    console.info(TAG + ': notifyServiceStatus is called result = ' + JSON.stringify(serviceStatus));
    let satelliteStatusInfo: SatelliteStatus = {
      serviceStatus: serviceStatus.status,
      convertLongitude: serviceStatus.longitude,
      convertLatitude: serviceStatus.latitude,
      cause: serviceStatus.cause,
      alignSectorPitch: serviceStatus.alignSectorPitch,
      alignSectorAzimuth: serviceStatus.alignSectorAzimuth,
      alertState: serviceStatus.alertState,
      height: serviceStatus.height,
      cellularDetectionRes: serviceStatus.cellularDetectionRes
    };
    callBack(satelliteStatusInfo);
  });
}

// @ts-ignore
export function offSatelliteStatus(callBack: Function): void {
  console.info(TAG + ': offSatelliteStatus');
  return satellite.off('notifyServiceStatus', (serviceStatus: satellite.ServiceStatus) => {
    console.info(TAG + ': offServiceStatus is called result');
    callBack();
  });
}

// @ts-ignore
export function notifySmcSatelliteInfo(callBack: Function): void {
  console.info(TAG, 'notifySmcSatelliteInfo.');
  satellite.on('notifySatelliteInfo', (satelliteInfo: satellite.SatelliteInfo) => {
    let satelliteData: SmcSatelliteData = {
      azimuthDelta: satelliteInfo.azimuthDelta,
      pitchAngleDelta: satelliteInfo.pitchAngleDelta,
      cnr: satelliteInfo.cnr,
      sateIdx: satelliteInfo.sateIdx
    };
    callBack(satelliteData);
  });
}

// @ts-ignore
export function offSmcSatelliteInfo(): void {
  console.info(TAG, 'offSmcSatelliteInfo.');
  return satellite.off('notifySatelliteInfo', (satelliteInfo: satellite.SatelliteInfo) => {
    console.info(TAG, 'offSmcSatelliteInfo is called result.');
  });
}

// @ts-ignore
export async function queryNextOverTime(): Promise<number> {
  console.info(TAG + `: queryNextOverTime begin.`);
  return new Promise(async (resolve, reject) => {
    try {
      let res = await satellite.queryNextOverTime();
      resolve(res);
    } catch (error) {
      console.error(`SatelliteServiceApi: queryNextOverTime error: code: ${error}, message: ${error}`);
      resolve(-1);
    }
  })
}

// @ts-ignore
export function notifyOverTimeInfo(callBack: Function): number {
  console.info(TAG, 'notifyOverTimeInfo begin.');
  const result = satellite.on('notifyOverTimeInfo', (timeInfoArray: [number, number][]) => {
    callBack(timeInfoArray);
    console.info(TAG, `notifyOverTimeInfo is called result. ${timeInfoArray}`);
  });
  // 接口返回1表示注册成功,其余不成功
  console.info(TAG, 'notifyOverTimeInfo result' + result);
  return result;
}

// @ts-ignore
export function offOverTimeInfo(): void {
  console.info(TAG, 'offOverTimeInfo.');
  return satellite.off('notifyOverTimeInfo', (satelliteInfo: satellite.SatelliteInfo) => {
    console.info(TAG, 'notifyOverTimeInfo is called result.');
  });
}