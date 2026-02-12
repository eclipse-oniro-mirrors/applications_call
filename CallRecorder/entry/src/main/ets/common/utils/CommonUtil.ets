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
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import ability from '@ohos.ability.ability';
import LogUtils from './LogUtils';
import i18n from '@ohos.i18n';
import { BusinessError } from '@ohos.base';
import { deviceInfo } from '@kit.BasicServicesKit';
import { Device } from '../constant/MigrationConstant';

const TAG: string = 'CommonUtil';

export function terminateSelfWithResult(statusUse: boolean): UIExtensionContentSession {
  let session: UIExtensionContentSession = LocalStorage.getShared()
    .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  let parameters: Record<string, string> = {
    'contactObjects': JSON.stringify(statusUse)
  };
  let want: Record<string, Record<string, string>> = {
    'parameters': parameters
  };
  let result: ability.AbilityResult = {
    'resultCode': 0,
    'want': want
  };
  session?.terminateSelfWithResult(result).then((data) => {
    LogUtils.i(TAG, 'terminateSelfCallBack');
  });
  return session;
}

/**
 * format phone number, eg: '12312341234' -> '123 1234 1234'
 *
 * @param { string } phoneNumber
 */
export function formatPhoneNum(phoneNumber: string): string {
  try {
    let countryId = i18n.System.getSystemRegion();
    let phoneNumberFormat = new i18n.PhoneNumberFormat(countryId);
    let isNumberValid: boolean = phoneNumberFormat.isValidNumber(phoneNumber);
    let formatNumber = isNumberValid ? phoneNumberFormat.format(phoneNumber) : phoneNumber;
    return formatNumber;
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    LogUtils.e(TAG, `formatPhoneNum failed, error code: ${err.code}.`);
  }
  return phoneNumber;
}

export function isPhone() {
  let isPhone = deviceInfo.deviceType === Device.PHONE;
  LogUtils.i(TAG, 'the value of the isPhone is :' + isPhone);
  return isPhone;
}

export function isTablet() {
  let isTablet = deviceInfo.deviceType === Device.TABLET;
  LogUtils.i(TAG, 'the value of the isTablet is :' + isTablet);
  return isTablet;
}

export async function sleep(ms: number) {
  return new Promise<void>(resolve => {
    setTimeout(resolve, ms);
  })
}