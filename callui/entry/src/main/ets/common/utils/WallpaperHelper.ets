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

import { BusinessError } from '@ohos.base';
import emitter from '@ohos.events.emitter';
import wallpaper from '@ohos.wallpaper';
import LogUtils from './LogUtils';
import { getFoldTypeInfo, isPhone } from '../utils/DeviceTypeUtils';
import { DisplayUtil } from './DisplayUtil';
import * as Constants from './Constants';

const TAG = 'WallpaperHelper'

export class WallpaperHelper {
  private static sWallpaperHelper: WallpaperHelper;
  private foldType: number;
  private pixelMap: PixelMap | undefined = undefined;
  private lastFoldState?: wallpaper.FoldState = undefined;
  private lastRotateState?: wallpaper.RotateState = undefined;

  constructor() {
    this.foldType = getFoldTypeInfo();
  }

  /**
   * Get WallpaperHelper object
   *
   * @return { Object } WallpaperHelper
   */
  public static getInstance(): WallpaperHelper {
    if (!WallpaperHelper.sWallpaperHelper) {
      WallpaperHelper.sWallpaperHelper = new WallpaperHelper();
    }
    return WallpaperHelper.sWallpaperHelper;
  }

  public getWallpaper(): PixelMap | undefined {
    return this.pixelMap;
  }

  public release() {
    if (this.pixelMap) {
      this.pixelMap.release();
      this.pixelMap = undefined;
    }
    this.lastFoldState = undefined;
    this.lastRotateState = undefined;
  }

  getWallpaperData() {
    try {
      const foldState = this.getFoldState();
      const rotateState = this.getRotateState();
      if (this.lastFoldState === foldState && this.lastRotateState === rotateState) {
        return;
      }
      LogUtils.i(TAG, `callui wallpaper: FoldState is ${foldState}, RotateState is ${rotateState}`)

      wallpaper.getWallpaperByState(wallpaper.WallpaperType.WALLPAPER_SYSTEM, foldState, rotateState)
        .then((data) => {
          if (data) {
            LogUtils.i(TAG, `callui wallpaper: get success`);
            this.pixelMap = data;
            emitter.emit(Constants.WALLPAPER_EVENT);
          } else {
            this.getDefaultWallpaperData();
          }
        })
        .catch((error: BusinessError) => {
          LogUtils.e(TAG, `callui wallpaper: get failed, because: ${JSON.stringify(error)}`);
          this.getDefaultWallpaperData();
        });
      this.lastFoldState = foldState;
      this.lastRotateState = rotateState;
    } catch (error) {
      LogUtils.e(TAG, `callui wallpaper: get failed no method, because: ${JSON.stringify(error)}`);
      this.getDefaultWallpaperData();
    }
  }

  getDefaultWallpaperData() {
    wallpaper.getImage(wallpaper.WallpaperType.WALLPAPER_SYSTEM)
      .then((data) => {
        if (data) {
          LogUtils.i(TAG, `callui wallpaper: get default success`);
          this.pixelMap = data;
          emitter.emit(Constants.WALLPAPER_EVENT);
        } else {
          LogUtils.e(TAG, `callui wallpaper: get default failed`);
        }
      })
      .catch((error: BusinessError) => {
        LogUtils.e(TAG, `callui wallpaper: get default failed, because: ${JSON.stringify(error)}`);
      });
  }

  getFoldState() {
    if (isPhone()) {
      switch (this.foldType) {
        case 0:
        case 2:
          return wallpaper.FoldState.NORMAL;
        case 1:
        case 3:
        case 4:
          const state = DisplayUtil.getScreenFoldStatus();
          return (state === 2) ? wallpaper.FoldState.NORMAL : wallpaper.FoldState.UNFOLD_ONCE_STATE;
        default:
          return wallpaper.FoldState.NORMAL;
      }
    }
    return wallpaper.FoldState.NORMAL;
  }

  getRotateState(): wallpaper.RotateState {
    if (isPhone()) {
      switch (this.foldType) {
        case 0:
        case 2:
        case 4:
          return wallpaper.RotateState.PORTRAIT;
        case 1:
        case 3:
          const isPortrait = AppStorage.get('LandscapeOrPortrait') || true;
          return isPortrait ? wallpaper.RotateState.PORTRAIT : wallpaper.RotateState.LANDSCAPE;
        default:
          return wallpaper.RotateState.PORTRAIT;
      }
    }
    return AppStorage.get('LandscapeOrPortrait') ? wallpaper.RotateState.PORTRAIT : wallpaper.RotateState.LANDSCAPE;
  }
}