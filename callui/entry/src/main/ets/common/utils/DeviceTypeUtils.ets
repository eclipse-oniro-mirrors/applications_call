/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import LogUtils from './LogUtils';
import deviceInfo from '@ohos.deviceInfo'
import { screenLock } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import * as Constants from './Constants';

const TAG = 'DeviceTypeUtils';

/**
 * Get deviceType info
 *
 * @return { String } deviceTypeInfo
 */
export function getDeviceTypeInfo() {
  const deviceTypeInfo = deviceInfo.deviceType;
  return deviceTypeInfo;
}

/**
 * Get isTablet
 *
 * @return { Boolean } isTablet
 */
export function isTablet() {
  const deviceTypeInfo = getDeviceTypeInfo();
  const isTablet = deviceTypeInfo === 'tablet';
  LogUtils.i(TAG, 'the value of the isTablet is :' + isTablet);
  return isTablet;
}

export function isScreenLocked(): boolean {
  try {
    return screenLock.isLocked();
  } catch (err) {
    LogUtils.e(TAG, 'isScreenLocked failed, error code: ' + err.code);
    return false;
  }
}

/**
 * get app version
 *
 * @return string, app version
 */
export async function getVersionName(callback: Function): Promise<void> {
  let version: string;
  let bundleInfo: bundleManager.BundleInfo =
    await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  version = bundleInfo.versionName;
  callback(version);
}

export function isPhone() {
  const deviceTypeInfo = getDeviceTypeInfo();
  const isPhone = deviceTypeInfo === 'phone';
  LogUtils.i(TAG, 'the value of the isPhone is :' + isPhone);
  return isPhone;
}

export function getFoldTypeInfo() {
  try {
    const foldType = systemParameterEnhance.getSync(Constants.FOLD_PRODUCT_TYPE_KEY, '0,0,0,0');
    LogUtils.i(TAG, `get foldType:${foldType}`);
    const result = foldType.split(',');
    if (Array.isArray(result) && result.length > 0) {
      return Number(result[0]);
    }
    return 0;
  } catch (err) {
    LogUtils.e(TAG, `get foldType err:${err?.code}`);
  }
  return 0;
}

/**
 * Get isTwoInOne
 *
 * @return { Boolean } isTwoInOne
 */
export function isTwoInOne() {
  const deviceTypeInfo = getDeviceTypeInfo();
  const isTwoInOne = deviceTypeInfo === '2in1';
  LogUtils.i(TAG, 'the value of the isTwoInOne is :' + isTwoInOne);
  return isTwoInOne;
}