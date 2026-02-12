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
import deviceInfo from '@ohos.deviceInfo';
import { LogUtil } from './LogUtil';
import { sim } from '@kit.TelephonyKit';
import { display } from '@kit.ArkUI';
import { osAccount } from '@kit.BasicServicesKit';
import { DEFAULT_USERID } from '../constants/CommonConstants';

const TAG = 'DeviceUtil';

/**
 * 获取当前用户ID
 *
 * @returns number 用户ID
 */
export async function getActivatedAccountLocalId(): Promise<number> {
  let accountId: number = DEFAULT_USERID;
  try {
    let osAccountManager = osAccount.getAccountManager();
    const accountIds: number[] = await osAccountManager.getActivatedOsAccountLocalIds();
    if (accountIds.length > 0) {
      accountId = accountIds[0];
    }
  } catch (error) {
    LogUtil.error('getActivatedAccountLocalId', 'getActivatedOsAccountLocalIds failed');
  }
  return accountId;
}

export function isTablet(): boolean {
  const deviceType: string = deviceInfo.deviceType;
  return deviceType === 'tablet';
}

export function IsWiFiOnly() {
  let wifiOnly = true;
  try {
    if (sim.getMaxSimCount() > 0) {
      wifiOnly = false;
    }
  } catch (e) {
    LogUtil.error(TAG, `getMaxSimCount error code: ${e?.code}, error message: ${e?.message}`);
  }
  return wifiOnly;
}

/**
 * 当前设备是否为竖屏
 *
 * @return true: 竖屏  false: 横屏
 */
export function isDevicePortrait(): boolean {
  try {
    const orientation: display.Orientation = display.getDefaultDisplaySync().orientation;
    if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
      return false;
    }
  } catch (err) {
    LogUtil.error(TAG, `isDevicePortrait failed. error: ${err?.code} ${err?.message}`);
  }
  return true;
}

/**
 * 当前设备是否为折叠屏
 *
 * @returns boolean
 */
export function isFoldable() {
  let foldable: boolean = false;
  try {
    foldable = display.isFoldable();
  } catch (exception) {
    console.error('Failed to check is foldable or not. Code: ' + JSON.stringify(exception));
  }
  return foldable;
}