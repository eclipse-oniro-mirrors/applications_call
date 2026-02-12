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

import { image } from '@kit.ImageKit';
import { Context } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { LogUtil } from '../util/LogUtil';
import { ThemeUtils } from './ThemeUtils';
import { ThemeIcon } from './ThemeModel';

const ICONS: string = '/icons';
const OTHERS_ICONS: string = '/other_icons';
const ZERO: number = 0;
const CENTER_SIZE: number = 2;

const TAG: string = 'ThemeResourceCache';

export class ThemeResourceCache {
  private static idThemeIconMap: Map<string, PixelMap | undefined> = new Map;
  private static mContext: Context;
  private bundleNameList: string[] = [];
  // 当前使能的主题路径
  private currentThemePath: string | undefined;
  // 当前使能的主题资源里面是否存在 icons目录
  private isExistIcons: boolean = false;
  // 当前使能的主题资源 other默认图片是否存在
  private isExistOtherIcons: boolean = false;
  // 当前使能主题的默认背景图片 pixelMap
  private backPixelMap: image.PixelMap | undefined;
  private settings: RenderingContextSettings | undefined;
  private offCanvas: OffscreenCanvas | undefined;
  private offContext: OffscreenCanvasRenderingContext2D | undefined;
  // 应用图标缩放尺寸值
  private scaleSize: number = 25;
  private static themeResource: ThemeResourceCache | undefined;

  /**
   * 共享单例
   *
   * @returns 共享单例接口对象
   */
  static themeResourceCache(): ThemeResourceCache {
    if (!ThemeResourceCache.themeResource) {
      ThemeResourceCache.themeResource = new ThemeResourceCache();
    }
    return ThemeResourceCache.themeResource;
  }

  private initData(): void {
    // 获取当前使能的主题目录
    this.currentThemePath = ThemeUtils.getActivatingThemePath();
    if (!this.currentThemePath) {
      LogUtil.warn(`${TAG} the flag file does not exist.`);
      return;
    }
    // 判断主题资源包里面icons是否存在
    if (!ThemeUtils.isFileExists(this.currentThemePath + ICONS)) {
      LogUtil.warn(`${TAG} the icons file does not exist.`);
      return;
    }
    this.isExistIcons = true;
    this.bundleNameList = ThemeUtils.getFileList(this.currentThemePath + ICONS);
    // 判断主题默认图片资源是否存在
    if (!ThemeUtils.isFileExists(this.currentThemePath + ICONS + OTHERS_ICONS)) {
      LogUtil.warn(`${TAG} the other icons file does not exist.`);
      return;
    }
    LogUtil.info(`${TAG} initData end.`);
    this.isExistOtherIcons = true;
    this.loadBackGroundImage();
  }

  /**
   * 初始化主题
   *
   * @param context 上下文
   */
  public initActivatingTheme(context: Context): void {
    ThemeResourceCache.mContext = context;
    this.initData();
  }

  /**
   * 获取主题资源默认图片配置
   */
  private loadBackGroundImage(): void {
    try {
      const backGroundPath = this.currentThemePath + ICONS + OTHERS_ICONS + '/bg.png';
      this.backPixelMap = ThemeUtils.getFilePixelMapSync(backGroundPath);
      if (!this.backPixelMap) {
        LogUtil.warn(`${TAG} loadBackGroundImage backPixelMap is null.`);
        return;
      }
      let backWidth = this.backPixelMap.getImageInfoSync().size.width;
      let backHeight = this.backPixelMap.getImageInfoSync().size.height;
      this.settings = new RenderingContextSettings(true);
      this.offCanvas = new OffscreenCanvas(backWidth, backHeight);
    } catch (err) {
      LogUtil.error(`${TAG} loadBackGroundImage fail ${err?.message}, code ${err?.code}`);
    }
  }

  /**
   * 获取合成图标数据
   *
   * @param forePixelMap 前背景图标
   * @returns 合成图标
   */
  private async getComposePixelMap(forePixelMap: image.PixelMap | undefined): Promise<image.PixelMap | undefined> {
    if (!this.offCanvas) {
      LogUtil.warn(`${TAG} getComposePixelMap Canvas is null`);
      return undefined;
    }
    if (!forePixelMap || !this.backPixelMap) {
      LogUtil.warn(`${TAG} getComposePixelMap failed, forePixelMap is ${forePixelMap}, backPixelMap is ${this.backPixelMap}`);
      return undefined;
    }
    let composeIcon: image.PixelMap | undefined = undefined;
    try {
      // ASTC(sut)格式不能直接处理数据,需要转换RGBA
      if (forePixelMap.getImageInfoSync().pixelFormat.valueOf() === image.PixelMapFormat.ASTC_4x4) {
        await forePixelMap.convertPixelFormat(image.PixelMapFormat.RGBA_8888);
        if (forePixelMap.getImageInfoSync().pixelFormat.valueOf() !== image.PixelMapFormat.RGBA_8888) {
          LogUtil.warn(`${TAG} getComposePixelMap ASTC convert RGBA failed`);
          return undefined;
        }
      }
      this.offContext = this.offCanvas.getContext('2d', this.settings);
      this.offContext.clearRect(ZERO, ZERO, this.offCanvas.width, this.offCanvas.height);
      // 获取缩放前的宽高值
      let foreWidth = forePixelMap.getImageInfoSync().size.width;
      let foreHeight = forePixelMap.getImageInfoSync().size.height;
      // 计算宽高的缩放倍数
      let scaleX = 0;
      if (foreWidth !== 0) {
        scaleX = (this.offCanvas.width - this.scaleSize) / foreWidth;
      }
      let scaleY = 0;
      if (foreHeight !== 0) {
        scaleY = (this.offCanvas.height - this.scaleSize) / foreHeight;
      }
      // 缩放应用图标
      forePixelMap.scaleSync(scaleX, scaleY);
      // 获取缩放后的宽高值
      foreWidth = forePixelMap.getImageInfoSync().size.width;
      foreHeight = forePixelMap.getImageInfoSync().size.height;
      // 绘制后背景图标
      this.offContext.drawImage(this.backPixelMap, ZERO, ZERO, this.offCanvas.width, this.offCanvas.height);
      // 绘制前背景图标(应用裁剪成圆形图标)
      const radius = Math.min(foreWidth, foreHeight) / CENTER_SIZE;
      this.offContext.beginPath();
      this.offContext.arc(this.offCanvas.width / CENTER_SIZE, this.offCanvas.height / CENTER_SIZE, radius, ZERO,
        Math.PI * CENTER_SIZE);
      this.offContext.closePath();
      this.offContext.clip();
      this.offContext.drawImage(forePixelMap, this.scaleSize / CENTER_SIZE, this.scaleSize / CENTER_SIZE, foreWidth,
        foreHeight);
      // 返回合成图标
      composeIcon = this.offContext.getPixelMap(ZERO, ZERO, this.offCanvas.width, this.offCanvas.height);
      LogUtil.info(`${TAG} getComposePixelMap success ${composeIcon}`);
    } catch (err) {
      LogUtil.error(`${TAG} getComposePixelMap failed: ${err?.message}`);
    }
    return composeIcon;
  }

  /**
   * 根据 bundleName查找当前的主题包是否存在
   *
   * @param bundleName 应用包名称
   * @returns true 主题包里面bundleName应用资源存在
   */
  public isThemePackagesExistence(bundleName: string): boolean {
    // 包名存在,使用定制图标
    if (this.isExistIcons && this.isExistOtherIcons) {
      if (this.bundleNameList.includes(bundleName)) {
        LogUtil.info(`${TAG} isThemePackagesExistence ${bundleName}`);
        return true;
      }
    }
    return false;
  }

  /**
   * 获取主题图片资源
   *
   * @param bundleName 包名
   * @param moduleName 模块名
   * @param iconId 图片标识符
   * @returns DrawableDescriptor 图片描述符
   */
  public async getThemeDrawableDescriptor(bundleName: string, moduleName: string,
    iconId: number): Promise<PixelMap | undefined> {
    if (!bundleName || !moduleName || iconId === 0) {
      LogUtil.warn(`${TAG} getThemeDrawableDescriptor parameters is invalid,
       bundleName:${bundleName},moduleName:${moduleName},iconId:${iconId}`);
      return undefined;
    }
    const key = bundleName + moduleName + iconId;
    let value = ThemeResourceCache.idThemeIconMap.get(key);
    // 读取缓存数据，存在则直接返回
    if (value) {
      LogUtil.info(`${TAG} getThemeDrawableDescriptor Read idThemeIconMap cache`);
      return value;
    }
    let nativeIcon: undefined | image.PixelMap = undefined;
    // 使用合成图标
    try {
      nativeIcon = await this.getImageBase64(bundleName, moduleName, iconId,
        ThemeIcon.NATIVE_ICON);
      value = await this.getComposePixelMap(nativeIcon);
    } catch (err) {
      LogUtil.error(`${TAG} getThemeDrawableDescriptor ${bundleName} compose icon failed, ${err?.message}`);
    }
    // 获取主题图标失败,再获取原生图标作为定制图标显示
    if (!value) {
      LogUtil.info(`${TAG} getThemeDrawableDescriptor ${bundleName} failed, use native icon`);
      if (nativeIcon) {
        value = nativeIcon;
      } else {
        value = await this.getImageBase64(bundleName, moduleName, iconId, ThemeIcon.NATIVE_ICON);
      }
    }
    LogUtil.info(`${TAG} getThemeDrawableDescriptor success`);
    ThemeResourceCache.idThemeIconMap.set(key, value);
    return value;
  }

  /**
   * 获取主题icon资源
   *
   * @param bundleName 包名
   * @param moduleName 模块名
   * @param iconId icon资源id
   * @param themeIconType 是否是定制主题
   * @returns icon资源
   */
  private async getImageBase64(bundleName: string, moduleName: string,
    iconId: number, themeIconType: number): Promise<undefined | image.PixelMap> {
    if (!bundleName || !moduleName || iconId === 0) {
      LogUtil.info(`${TAG} getImageBase64  parameters is invalid,
      bundleName:${bundleName},moduleName:${moduleName},iconId:${iconId}`);
      return undefined;
    }
    let strBase: undefined | image.PixelMap;
    let resMgr: resourceManager.ResourceManager | undefined;
    let contentBase64: string = '';
    try {
      LogUtil.info(`${TAG} getImageBase64 bundleName:${bundleName},moduleName:${moduleName},iconId:${iconId}`);
      resMgr = ThemeResourceCache.mContext?.createModuleResourceManager(bundleName, moduleName);
      contentBase64 = await resMgr.getMediaContentBase64(iconId);
      if (contentBase64) {
        const descriptor = resMgr.getDrawableDescriptor(iconId, undefined, themeIconType);
        strBase = descriptor.getPixelMap();
      }
      LogUtil.info(`${TAG} getImageBase64 end`);
      return strBase;
    } catch (err) {
      LogUtil.error(`${TAG} getDrawableDescriptor err ${err?.message}`);
    } finally {
      if (resMgr) {
        resMgr.release();
      }
    }
    return undefined;
  }

  /**
   * 清除主题图标缓存
   */
  public static clearThemeIcons(): void {
    ThemeResourceCache.idThemeIconMap.clear();
  }
}

/**
 * 全局单例
 */
export const themeResource: ThemeResourceCache = ThemeResourceCache.themeResourceCache();