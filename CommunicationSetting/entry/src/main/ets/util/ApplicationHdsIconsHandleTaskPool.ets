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
// import { hdsDrawable } from '@kit.UIDesignKit';
import { LogUtil } from './LogUtil';
import { bundleResourceManager } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { ABROAD_HOTSPOT_UID, UNKNOWN_BUNDLE_TYPE } from '../constants/CommonConstants';
import { AppInfo } from '../viewmodel/AppInfo';
import { HDSUtil } from './HDSUtil';
import { LayeredDrawableDescriptor } from '@kit.ArkUI';

@Concurrent
export function iconsOneByOneProc(appList: AppInfo[], context: Context): AppInfo[] {
  let bundleFlags: number = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_WITH_DRAWABLE_DESCRIPTOR |
  bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_WITH_LABEL;
  // 设置获取mask的方式
  let layeredDrawableDescriptor: LayeredDrawableDescriptor;
  let mask: PixelMap;
  try {
    layeredDrawableDescriptor =
      bundleResourceManager.getBundleResourceInfo('com.ohos.settings',
        bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_WITH_DRAWABLE_DESCRIPTOR)
        .drawableDescriptor as LayeredDrawableDescriptor;
    mask = layeredDrawableDescriptor.getPixelMap();
  } catch (err) {
    layeredDrawableDescriptor =
      context.resourceManager.getDrawableDescriptor($r('app.media.drawable').id) as LayeredDrawableDescriptor;
    mask = layeredDrawableDescriptor.getPixelMap();
    LogUtil.error('ApplicationHdsIconsHandleTaskPool',
      ` Failed to startAbility. Code: ${err.code}, message: ${err.message}`)
  }
  for (let index: number = 0; index < appList.length; index++) {
    let appInfo: AppInfo = appList[index];
    if (appInfo.uid === ABROAD_HOTSPOT_UID) {
      continue;
    }
    let pixelMap: PixelMap | undefined;
    try {
      let bundleResourceInfo =
        bundleResourceManager.getBundleResourceInfo(appInfo.bundleName, bundleFlags, appInfo.appIndex);
      appInfo.label = bundleResourceInfo.label;
      if (appInfo.bundleType === UNKNOWN_BUNDLE_TYPE) {
        let flag = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let appInfoOrigin = bundleManager.getApplicationInfoSync(appInfo.bundleName, flag);
        appInfo.bundleType = appInfoOrigin.bundleType;
      }

      if (appInfo.bundleType === bundleManager.BundleType.ATOMIC_SERVICE) {
        appInfo.img = bundleResourceInfo.drawableDescriptor.getPixelMap();
        continue;
      }
      let drawableDescriptor = bundleResourceInfo.drawableDescriptor;
      let result: PixelMap | undefined = undefined;
      let bundleName = appInfo.bundleName;
      if (appInfo.isCompatibleApp) {
        // 在线主题场景要注意下，兼容应用的图标传给hds的bundleName最好加个_xxx的后缀，保证都走模板处理流程
        bundleName = bundleName + '_xxx';
      }
      if (drawableDescriptor instanceof LayeredDrawableDescriptor) {
        // result =
        //   hdsDrawable.getHdsLayeredIcon(bundleName, drawableDescriptor as LayeredDrawableDescriptor, 48, true);
        // appInfo.img = result;
      } else {
        // pixelMap = drawableDescriptor.getPixelMap();
        // result = hdsDrawable.getHdsIcon(bundleName, pixelMap, HDSUtil.defaultSize, mask, true);
        // appInfo.img = result;
        // pixelMap.release();
      }
    } catch (error) {
      if (appInfo.isCompatibleApp) {
        appInfo.isRubbishData = true;
      }
      pixelMap?.release();
      LogUtil.error('AppHdsIconLoaderManagerTaskPool',
        `AppListLoaderTaskPool : iconsOneByOneProc getBundleResourceInfo errmsg: ${error?.message}`);
    }
  }
  LogUtil.info('AppHdsIconLoaderManagerTaskPool',
    `AppListLoaderTaskPool : iconsOneByOneProc proc appList len: ${appList.length}`);
  if (mask) {
    mask.release();
  }
  return appList;
}


