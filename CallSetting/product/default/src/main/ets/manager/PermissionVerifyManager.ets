/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import { bundleManager } from '@kit.AbilityKit';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'PermissionVerifyManager';

// white list map
const whiteListMap = new Map<string, WhiteListData[]>([
  ['SatelliteUiExtentionAbility', [
    {
      bundleName: 'com.ohos.callsetting',
      appIdentifier: '5765880207853200721'
    },
    {
      bundleName: 'com.ohos.meetime',
      appIdentifier: '949945480907860672'
    },
    {
      bundleName: 'com.ohos.meetimeservice',
      appIdentifier: '1171817433862777600'
    },
    {
      bundleName: 'com.ohos.mms',
      appIdentifier: '5765880207853068793'
    }]
  ]
]);

export class PermissionVerifyManager {
  private static permissionVerifyManager: PermissionVerifyManager;

  private constructor() {
  }

  /**
   * Get instance
   *
   * @returns instance
   */
  public static getInstance(): PermissionVerifyManager {
    if (!PermissionVerifyManager.permissionVerifyManager) {
      PermissionVerifyManager.permissionVerifyManager = new PermissionVerifyManager();
    }

    return PermissionVerifyManager.permissionVerifyManager;
  }

  /**
   * Check caller want params
   *
   * @param abilityName ability name
   * @param callerBundleName caller bundle name
   * @returns true/false
   */
  public checkCallerWantParams(abilityName: string, callerBundleName: string | undefined): boolean {
    if (!callerBundleName) {
      LogUtils.w(TAG, 'The caller bundle name is invalid, reject.');
      return false;
    }

    // get the white list map by ability name
    const whiteListData: WhiteListData[] = whiteListMap.get(abilityName) as WhiteListData[];
    const bundleInfo =
      bundleManager.getBundleInfoSync(callerBundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO);
    if (whiteListData && whiteListData.length && bundleInfo && bundleInfo.signatureInfo) {
      return whiteListData.some(item => item.bundleName === callerBundleName &&
        item.appIdentifier === bundleInfo.signatureInfo.appIdentifier)
    } else {
      LogUtils.i(TAG, 'The caller bundle is not result, reject.');
      return false;
    }
  }
}

export class WhiteListData {
  public bundleName?: string;
  public appIdentifier?: string;
}