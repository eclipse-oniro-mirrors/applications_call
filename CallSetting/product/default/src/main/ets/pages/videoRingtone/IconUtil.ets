/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import type { BusinessError } from '@ohos.base';
import { bundleManager, bundleResourceManager } from '@kit.AbilityKit';
import configPolicy from '@ohos.configPolicy';
import fileuri from '@ohos.file.fileuri';
import fs from '@ohos.file.fs';
import resourceManager from '@ohos.resourceManager';
import { StringUtil } from '../../common/utils/StringUtil';
import { Constants, LogUtils } from '@ohos/common';
import { FileUtils } from '../../common/utils/presenter/FileUtils';

const TAG: string = 'IconUtil';
const APP_BUNDLE_NAMES: Record<string, string> = {
  'settings': 'com.ohos.settings',
  'clock': 'com.ohos.clock',
  'gallery': 'com.ohos.photos',
  'camera': 'com.ohos.camera',
}

export enum IconWantType {
  DEFAULT = 0,
  CURRENT = 1,
}

export interface IconWantParams {
  appName: string,
  type: IconWantType,
}

export class IconUtil {

  /**
   * 根据应用名获取对应的图标的图片路径
   *
   * @param params IconWantParams类型传参，包括应用名以及想获取的图标类型
   * @returns 图标的图片路径
   */
  public static getBundleCurrentIcon(params: IconWantParams): Promise<string> {
    return new Promise(async (resolve) => {
      try {
        if (!params || !params.appName || !params.type) {
          LogUtils.e(TAG, 'params is invalid');
          resolve('');
          return;
        }
        const bundleName: string = APP_BUNDLE_NAMES[params.appName];
        const icon: string = bundleResourceManager.getBundleResourceInfo(bundleName,
          bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_WITH_ICON).icon;
        resolve(icon);
      } catch (err) {
        LogUtils.e(TAG,
          `error in getIconLayered, message: ${err?.message}, code: ${err?.code}, appName: ${params.appName}`);
        resolve('');
      }
    })
  }


  /**
   * 根据应用名获取当前A/B目录中对于的图标资源
   *
   * @param params IconWantParams类型传参，包括应用名以及想获取的图标类型
   * @returns 前置、后置图标路径数组
   */
  public static getThemeIconPath(params: IconWantParams): Promise<string[] | undefined> {
    return new Promise(async (resolve) => {
      try {
        const themeIconPath: string = `${FileUtils.getSandboxAppPath()}${Constants.ICONS}`;
        if (!fs.accessSync(themeIconPath)) {
          LogUtils.e(TAG, `getCurrentThemeIcon iconPath not exists`);
          resolve(undefined);
          return;
        }
        resolve(IconUtil.getIconUris(themeIconPath, params.appName));
      } catch (err) {
        LogUtils.e(TAG, `error in getCurrentThemeIconPath, ${err?.code}, ${err?.message}, appName: ${params.appName}`);
        resolve(undefined);
      }
    });
  }

  /**
   * 获取对应路径下前置、后置图标路径
   *
   * @param path 路径
   * @param appName 应用名
   * @returns 前置、后置图标路径数组
   */
  public static getIconUris(path: string, appName: string): Promise<string[]> {
    return new Promise((resolve, reject) => {
      try {
        const bundlePath: string = `${path}${Constants.FILE_SEPARATOR}${APP_BUNDLE_NAMES[appName]}`;
        let backUri: string = '';
        const pngBackPath: string = `${bundlePath}${Constants.ICON_BACK_PATH}${Constants.FORMAT_PNG}`;
        const webpBackPath: string = `${bundlePath}${Constants.ICON_BACK_PATH}${Constants.FORMAT_WEBP}`;
        if (fs.accessSync(pngBackPath)) {
          backUri = fileuri.getUriFromPath(pngBackPath);
        } else {
          backUri = fileuri.getUriFromPath(webpBackPath);
        }
        let foreUri: string = '';
        const pngForePath: string = `${bundlePath}${Constants.ICON_FORE_PATH}${Constants.FORMAT_PNG}`;
        const webpForePath: string = `${bundlePath}${Constants.ICON_FORE_PATH}${Constants.FORMAT_WEBP}`;
        if (fs.accessSync(pngForePath)) {
          foreUri = fileuri.getUriFromPath(pngForePath);
        } else {
          foreUri = fileuri.getUriFromPath(webpForePath);
        }
        resolve([backUri, foreUri]);
      } catch (err) {
        LogUtils.e(TAG, `error in getIconUris, ${err?.code}, ${err?.message}, appName: ${appName}`);
        reject(err);
      }
    })
  }

  /**
   * 获取预置图标中默认一套的图标资源
   *
   * @param params IconWantParams类型传参，包括应用名以及想获取的图标类型
   * @returns 前置、后置图标路径数组
   */
  public static getDefaultPresetIconPath(params: IconWantParams): Promise<string[] | undefined> {
    return new Promise(async (resolve) => {
      try {
        let iconDir = '';
        await configPolicy.getOneCfgFile(Constants.ICON_RESOURCE_SRC).then((value: string) => {
          iconDir = value;
        }).catch((error: BusinessError) => {
          LogUtils.w(TAG, 'getOneCfgFile promise ' + error);
        });
        const defaultIconPath: string = `${iconDir}/Icon_01/icons`;
        resolve(IconUtil.getIconUris(defaultIconPath, params.appName));
      } catch (err) {
        LogUtils.e(TAG, `error in getDefaultPresetIconPath, ${err?.code}, ${err?.message}, appName: ${params.appName}`);
        resolve(undefined);
      }
    });
  }

  /**
   * 获取图标资源 来源顺序: 应用bundle信息、A/B目录资源、预置目录中资源
   *
   * @param params IconWantParams类型传参，包括应用名以及想获取的图标类型
   * @returns 图标PixelMap或者前置、后置图标路径数组
   */
  public static getIconData(params: IconWantParams): Promise<string | string[] | undefined> {
    return new Promise(async (resolve, reject) => {
      try {
        const bundleCurrentIcon: string = await IconUtil.getBundleCurrentIcon(params);
        if (StringUtil.isEmpty(bundleCurrentIcon)) {
          LogUtils.i(TAG, 'getIconData, bundleCurrentIcon is valid');
          resolve(bundleCurrentIcon);
          return;
        }
        LogUtils.w(TAG, `getIconData, pixelamp is undefined, try getThemeIconPath, appName: ${params.appName}`);
        const themeIconPath: string[] | undefined = await IconUtil.getThemeIconPath(params);
        if (themeIconPath) {
          resolve(themeIconPath);
          return;
        }
        LogUtils.w(TAG,
          `getIconData, themeIconPath is undefined, try getDefaultPresetIconPath, appName: ${params.appName}`);
        resolve(await IconUtil.getDefaultPresetIconPath(params));
      } catch (err) {
        LogUtils.e(TAG, `error in getIconData, ${err?.code}, ${err?.message}, appName: ${params.appName}`);
        reject(err);
      }
    });
  }
}