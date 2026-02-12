/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import LogUtils from '../../utils/HiLog';

const TAG = 'BundleManagerInfo'

export class BundleManagerInfo {
  public static VERSION_NAME_EMPTY_VALUE = '1.0';

  /**
   * get app version
   *
   * @return string, app version
   */
  public static async getVersionName(defaultValue: string, callback?: (version: string) => void): Promise<string> {
    let version: string = defaultValue;
    try {
      const bundleInfo: bundleManager.BundleInfo | null =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
          .catch((e: BusinessError) => {
            LogUtils.e(TAG, `getBundleInfoForSelf error: ${e.code} ${e.message}`);
            return null;
          });
      version = bundleInfo?.versionName || defaultValue;
    } catch (err) {
      LogUtils.e(TAG, `getVersionName failed, code: ${err?.code}, message: ${err?.message}`);
    }
    if (callback) {
      callback(version);
    }
    return version;
  }

  /**
   * get app version use in sync scene
   */
  public static getVersionNameSync(defaultValue: string): string {
    let versionName = defaultValue;
    try {
      const bundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      versionName = bundleInfo.versionName;
    } catch (err) {
      LogUtils.e(TAG, ` getVersionNameSync failed, code: ${err?.code}, message: ${err?.message}`)
    }
    LogUtils.i(TAG, ' Client Version:' + versionName);
    return versionName;
  }
}

