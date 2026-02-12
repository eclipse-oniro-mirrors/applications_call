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

import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogUtil } from '../util/LogUtil';
import { ThemeDescription } from './ThemeModel';

const TAG: string = 'ThemeThemeUtils : ';
const THEME_PATH_A: string = '/data/themes/a/app';
const THEME_PATH_B: string = '/data/themes/b/app';
const FLAG: string = '/flag';
const RESOURCES_NAM_LENGTH = 31;

/**
 * 文件操作工具类
 *
 * @since 2025-06-03
 */
export class ThemeUtils {
  /**
   * 文件或目录是否存在
   *
   * @param path路径
   * @returns true:存在 false:不存在
   */
  public static isFileExists(path: string): boolean {
    let exist: boolean = false;
    if (!path) {
      LogUtil.warn(`${TAG} isFileExists is null`);
      return exist;
    }
    try {
      exist = fs.accessSync(path);
      LogUtil.info(`${TAG} isFileExists exist is ${exist}`);
    } catch (e) {
      LogUtil.error(`${TAG} isFileExists error: ${e?.code}, ${e?.message}`);
    }
    return exist;
  }

  /**
   * 判断路径是否是目录
   *
   * @param path路径
   * @returns true:是目录 false:不是目录
   */
  public static isDir(path: string): boolean {
    try {
      if (!ThemeUtils.isFileExists(path)) {
        LogUtil.warn(`${TAG} isDir path is null`);
        return false;
      }
      return fs.statSync(path).isDirectory();
    } catch (e) {
      LogUtil.error(`${TAG} isDir error: ${e?.code}, ${e?.message}`);
      return false;
    }
  }

  /**
   * 读取文件
   *
   * @param path 路径
   * @returns json content
   */
  public static async readFile(path: string): Promise<string | undefined> {
    try {
      return await fs.readText(path);
    } catch (e) {
      LogUtil.error(`${TAG} textOfFile error: ${e?.code}, ${e?.message}`);
      return undefined;
    }
  }

  /**
   * 获取目录下所有文件路径
   *
   * @param path 路径
   * @returns file List
   */
  public static getFileList(path: string): string[] {
    try {
      return fs.listFileSync(path);
    } catch (e) {
      LogUtil.error(`${TAG} getFileList error: ${e.toString()}`);
      return [];
    }
  }

  /**
   * 同步获取应用沙箱路径的 pixelMap
   *
   * @param path 文件路径
   * @returns pixelMap图片
   */
  public static getFilePixelMapSync(path: string): image.PixelMap | undefined {
    if (!path) {
      LogUtil.warn(`${TAG} getFilePixelMap filepath is null.`);
      return undefined;
    }
    let imageSource = image.createImageSource(path);
    let pixelMap: image.PixelMap;
    if (imageSource) {
      LogUtil.info(`${TAG} filePixelMapSync imageSource not null`);
      let decodingOptions: image.DecodingOptions = {
        editable: false,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      };
      try {
        pixelMap = imageSource.createPixelMapSync(decodingOptions);
        ThemeUtils.addName(pixelMap, 'PixelMapUtil_getFilePixelMapSync');
        return pixelMap;
      } catch (err) {
        LogUtil.error(`${TAG} getFilePixelMap failed: ${err?.message}`);
        return undefined;
      } finally {
        ThemeUtils.releaseSrc(imageSource, 'getFilePixelMap');
      }
    } else {
      LogUtil.warn(`${TAG} getFilePixelMap imageSource is null!`);
    }
    return undefined;
  }

  /**
   * 给图片资源设置别名
   *
   * @param map 资源
   * @param name 图片名称会被截断，取index: 0 ~ 30的子字符串
   * @param isActive 状态
   */
  public static addName(map: image.PixelMap, name: string, isActive?: boolean): void {
    LogUtil.info(`${TAG} addName in`);
    if (!map) {
      LogUtil.warn(`${TAG} addName map is null`);
      return;
    }
    try {
      map.setMemoryNameSync(name.substring(0, Math.min(RESOURCES_NAM_LENGTH, name.length)));
      if (isActive) {
        LogUtil.info(`${TAG} set memoryNameSync to ${name} succeed`);
      }
    } catch (error) {
      if (isActive) {
        LogUtil.error(`${TAG} set memoryNameSync to ${name} failed, error ${error?.message}`);
      }
    }
  }

  /**
   * 图片相关类资源释放
   *
   * @param imageSource 待释放的图片资源对象类
   * @param methodName 调用释放资源的方法名称
   */
  private static async releaseSrc(imageSource: image.ImageSource | image.ImagePacker | image.PixelMap,
    methodName: string): Promise<void> {
    LogUtil.info(`${TAG} releaseSrc in ${methodName}`);
    try {
      if (imageSource) {
        await imageSource.release();
      }
    } catch (err) {
      LogUtil.error(`${TAG} Failed catch ${err?.message}, code ${err?.code}`);
    }
  }

  /**
   * 解析主题目录配置文件
   *
   * @param 读取每个预制主题里面的 description.json配置信息
   * @returns ThemeDescription | undefined
   */
  public static async readThemeDescription(descriptionPath: string): Promise<ThemeDescription | undefined> {
    if (!ThemeUtils.isFileExists(descriptionPath)) {
      LogUtil.warn(`${TAG} readThemeDescription no Exist`);
      return undefined;
    }
    let descriptionFileContent: string | undefined;
    try {
      descriptionFileContent = await fs.readText(descriptionPath);
      LogUtil.info(`${TAG} descriptionFileContent readText success`);
    } catch (e) {
      LogUtil.error(`${TAG} textOfFile error: ${e?.code}, ${e?.message}`);
      return undefined;
    }
    if (descriptionFileContent) {
      try {
        let cfg: object | null = JSON.parse(descriptionFileContent);
        let themeDescription: ThemeDescription = new ThemeDescription();
        themeDescription.id = cfg?.['id'];
        themeDescription.title = cfg?.['title'];
        return themeDescription;
      } catch (e) {
        LogUtil.error(`${TAG} readThemeDescription catch exception. err:${e?.code}, ${e?.message}`);
      }
    }
    return undefined;
  }

  /**
   * 读取图片转化为PixelMap
   *
   * @param filePath 图片沙箱路径
   * @returns PixelMap | null
   */
  public static async readImage(filePath: string): Promise<PixelMap | null> {
    let file: fs.File | undefined = undefined;
    let imageSourceApi: image.ImageSource | undefined = undefined;
    try {
      file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      imageSourceApi = image.createImageSource(file.fd);
      let pixelMap: image.PixelMap = await imageSourceApi.createPixelMap();
      if (!pixelMap) {
        LogUtil.warn(`${TAG} readImage pixelMap is null`);
        return null;
      }
      return pixelMap;
    } catch (err) {
      LogUtil.error(`${TAG} readImage error: code: ${err?.code} message: ${err?.message}`);
    } finally {
      if (imageSourceApi) {
        imageSourceApi.release().then(() => {
          LogUtil.info(`${TAG} readImage release imageSource success.`);
        }).catch((err: BusinessError) => {
          LogUtil.error(`${TAG} readImage release imageSource error: ${err?.code} message: ${err?.message}`);
        })
      }
      if (file) {
        try {
          fs.closeSync(file.fd);
        } catch (e) {
          LogUtil.error(`${TAG} readImage file close error ${e?.message}`);
        }
      }
    }
    return null;
  }

  /**
   * 获取使能的主题路径
   *
   * @returns 使能主题file
   */
  public static getActivatingThemePath(): string | undefined {
    if (ThemeUtils.isFileExists(THEME_PATH_A + FLAG)) {
      return THEME_PATH_A;
    } else if (ThemeUtils.isFileExists(THEME_PATH_B + FLAG)) {
      return THEME_PATH_B;
    } else {
      LogUtil.warn(`${TAG} the flag file does not exist.`);
      return undefined;
    }
  }
}