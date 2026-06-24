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
import LogUtils from './HiLog';
import deviceInfo from '@ohos.deviceInfo'

const TAG = 'DeviceTypeUtils';
const DEVICE_MODE = 'ALN';

/**
 * Get deviceType info
 *
 * @return { String } deviceTypeInfo
 */
export function getDeviceTypeInfo() {
  const deviceTypeInfo = deviceInfo.deviceType;
  LogUtils.i(TAG, 'the value of the deviceType is :' + deviceTypeInfo);
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

/**
 * Get deviceType Version
 *
 * @return { String } displayVersion
 */
export function getDisplayVersion() {
  const displayVersion = deviceInfo.displayVersion;
  let version = displayVersion.substring(0, 3);
  LogUtils.i(TAG, 'the value of getDisplayVersion is :' + JSON.stringify(version === DEVICE_MODE));
  return version === DEVICE_MODE;
}
