/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import { deviceInfo } from '@kit.BasicServicesKit';

let deviceType: string = '';

/**
 * @function : needFilterEflInfo
 */
export function needFilterEflInfo(): boolean {
  let needFilterEfInfo: boolean | undefined = AppStorage.get('needFilterEflInfo');
  if (needFilterEfInfo === undefined) {
    needFilterEfInfo = getProperEnhance('const.telephony.efl_forbidden', 'false') === 'true';
    AppStorage.setOrCreate('needFilterEflInfo', needFilterEfInfo);
    return needFilterEfInfo;
  }
  return needFilterEfInfo;
}

function getProperEnhance(key: string, value: string): string {
  return SystemParameterEnhance.getSync(key, `${value}`);
}

export function getPaddingByDevice(): Resource {
  if (isTablet()) {
    return $r('sys.float.padding_level12');
  }
  return $r('sys.float.padding_level8');
}

export function isTablet(): boolean {
  let deviceTypeInfo: string = getDeviceType();
  if (deviceTypeInfo != undefined && deviceTypeInfo === 'tablet') {
    return true;
  }
  return false;
}

function getDeviceType() {
  if (deviceType === '') {
    deviceType = deviceInfo.deviceType;
    return deviceType;
  }
  return deviceType;
}
