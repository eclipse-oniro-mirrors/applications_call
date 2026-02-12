/*
 * Copyright (c) 2024-2025 Huawei Device Co., Ltd.
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

// import { PafBundleInfo, PafEngine, Region, Settings } from '@hms-paf/ui-widget-base-v2';
import { bundleManager, common, UIExtensionContentSession } from '@kit.AbilityKit';
import { LogUtils } from '@ohos/common';
import { CALL_UI_BUNDLE_NAME } from './CommonFunUtil';
import { window } from '@kit.ArkUI';

const TAG = 'PafEngineUtils';
const DEFAULT_VERSION_NAME = '1.0.0.1';

export async function pafInit(windowStage: window.WindowStage, context: common.UIAbilityContext) {
  const versionName = await getBundleInfoByBundleName(CALL_UI_BUNDLE_NAME);
  // PafEngine.init(windowStage, context, getPafSettings(versionName, $r('sys.color.background_secondary')));
}

export async function pafInitForUIExtension(session: UIExtensionContentSession, context: common.UIExtensionContext) {
  const versionName = await getBundleInfoByBundleName(CALL_UI_BUNDLE_NAME);
  // PafEngine.initForUIExtension(session, context,
  //   getPafSettings(versionName, $r('app.color.color_bind_sheet_background')));
}

// function getPafSettings(versionName: string, backgroundSecondary: ResourceColor): Settings {
//   return {
//     config: {
//       region: Region.CN
//     },
//     titleBarBlur: true,
//     sceneTag: CALL_UI_BUNDLE_NAME,
//     bundleInfo: getBundleInfo(versionName),
//     customColors: {
//       backgroundSecondary: backgroundSecondary
//     }
//   };
// }

// function getBundleInfo(versionName: string): PafBundleInfo {
//   return {
//     label: $r('app.string.app_about_name'),
//     icon: $r('app.media.ic_app_about_icon'),
//     description: $r('app.string.app_about_name'),
//     versionName: versionName
//   };
// }

/**
 * get version name
 *
 * @param bundleName string
 */
async function getBundleInfoByBundleName(bundleName: string): Promise<string> {
  try {
    let bundleInfo =
      await bundleManager.getBundleInfo(bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    if (bundleInfo && bundleInfo.versionName) {
      return bundleInfo.versionName;
    }
  } catch (err) {
    LogUtils.e(TAG, `getBundleInfo fail, code: ${err?.code}, message: ${err?.message}`);
  }
  return DEFAULT_VERSION_NAME;
}
