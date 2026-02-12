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

import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import LogUtils from '../utils/HiLog';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';

const TAG = 'LocationData';
const GET_TOKEN_ID_FAILED = -1;

/**
 * get tokenID
 *
 * @param {function} callback - callback with data
 */
export async function getTokenId(callback: Function): Promise<void> {
  let tokenId: number;
  try {
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
    callback(tokenId);
  } catch (err) {
    callback(GET_TOKEN_ID_FAILED);
    LogUtils.e(TAG, `Failed to get bundle info for self. Code is ${(err as BusinessError).code}` +
      `, message is ${(err as BusinessError).message}`);
  }
}

async function checkAccessToken(permission: Permissions, callback: (result: abilityAccessCtrl.GrantStatus) => void) {
  let atManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus;
  try {
    getTokenId((tokenId: number) => {
      grantStatus = atManager.verifyAccessTokenSync(tokenId, permission);
      LogUtils.i(TAG, `checkAccessToken success, data->${grantStatus}`);
      callback(grantStatus);
    });
  } catch (err) {
    LogUtils.e(TAG, `getBundleInfoForSelf failed, code is ${err.code}, message is ${err.message}`);
    callback(-1);
  }
}

/**
 * check location permission
 *
 * @param {function} callback - callback result
 */
export async function checkLocationPermission(callback: (res: boolean) => void) {
  const permissions: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
  checkAccessToken(permissions[0], (grantStatus) => {
    LogUtils.i(TAG, `grantStatus:` + grantStatus);
    if (!grantStatus) {
      callback(true);
    } else {
      callback(false);
    }
  });
}