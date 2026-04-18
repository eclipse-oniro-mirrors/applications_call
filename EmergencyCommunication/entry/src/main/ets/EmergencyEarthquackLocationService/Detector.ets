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
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import LogUtils from '../utils/HiLog';

const TAG = 'Detector';
const APPROVAL: number = 0

export default async function checkAccess() {
  let permissionsList: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION', 'ohos.permission.LOCATION_IN_BACKGROUND']
  let atManager = abilityAccessCtrl.createAtManager()
  let grantStatus: abilityAccessCtrl.GrantStatus = 1
  let tokenId: number = 0
  try {
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo
    tokenId = appInfo.accessTokenId
  } catch (err) {
    LogUtils.e(TAG, 'get BundleInfo For Self fail' + err.message)
  }
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permissionsList[0])
  } catch (err) {
    LogUtils.e(TAG, 'check Access Token fail ' + err.message)
  }
  if (grantStatus === APPROVAL) {
    LogUtils.i(TAG, 'Accessible')
    return true
  } else {
    LogUtils.i(TAG, 'Inaccessible')
    return false
  }
}