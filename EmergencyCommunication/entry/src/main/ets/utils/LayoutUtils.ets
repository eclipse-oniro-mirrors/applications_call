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
import { isTablet } from './DeviceTypeUtils';
import measure from '@ohos.measure';
import LogUtils from './HiLog';

const TAG = 'LayoutUtils';

export interface ScreenInfo {
  width: number,
  height:number
}

export default class LayoutUtils {
  constructor() {
  }

  /**
   * Obtain the gridCount of dialogs
   *
   * @param { string } curBp
   * @param { number } ratio
   * @return { number } gridCount
   */
  public static getDialogGridCount(curBp: string, ratio: number) {
    if (curBp && ratio) {
      if (curBp === 'sm') {
        return ratio > (9 / 16) ? 3 : 4;
      } else if (curBp === 'md') {
        return ratio > (3 / 4) ? 4 : 5;
      } else if (curBp === 'lg') {
        return ratio > (4 / 3) ? 5 : 6;
      }
    }
    if (isTablet()) {
      return 6;
    }
    return 4;
  }

  /**
   * Obtain the alignment of dialogs
   *
   * @param { string } curBp
   * @return { DialogAlignment } alignment
   */
  public static getDialogAlignment(curBp: string) {
    return curBp === 'sm' ? DialogAlignment.Default : DialogAlignment.Center;
  }

  /**
   *Fit Plate Spacing
   *
   * @param { direction } padding direction
   * @return { adaptableTabletPadding } padding
   */
  public static getAdaptableTabletPadding(direction: string) {
    if (isTablet()) {
      return $r('app.float.emc_margin_level12');
    } else {
      if (direction === 'right') {
        return $r('sys.float.margin_right')
      } else {
        return $r('sys.float.margin_left')
      }
    }
  }

  /**
   * 获取字体大小
   * @param name 字体大小的字符串
   * @param curBp 断点类型
   * @returns 字体大小
   */
  public getDisplayNameForAutoSize(name: ResourceStr | string | undefined, curBp: string): string {
    let fontSize = 30;
    let size: number = (curBp === 'sm' || curBp === 'xs') ? 16 : curBp === 'md' ? 24 : 32;
    let windowSize: ScreenInfo | undefined = AppStorage.get('windowSizeChangeMd');
    if (windowSize === null || windowSize === undefined) {
      LogUtils.i(TAG, 'getDisplayNameForAutoSize window size is null');
      return `${fontSize}vp`;
    }
    let widthVp = (px2vp(windowSize?.width) - size * 2);
    if (curBp === 'md' || curBp === 'lg') {
      let gridWidth = (widthVp - (this.getGridCount(curBp) - 1) * this.getRowSpace(curBp)) / this.getGridCount(curBp);
      widthVp = widthVp - (gridWidth + this.getRowSpace(curBp)) * (curBp === 'md' ? 2 : 4);
    }
    const minFontSize = AppStorage.get('isNewFoldPhoneInnerFullScreen') ? 18 : 20;
    do {
      let num = px2vp(measure.measureText({
        textContent: name,
        fontSize: `${fontSize}vp`,
        fontWeight: 600
      }));
      if (num < widthVp) {
        break;
      }
    } while (--fontSize > minFontSize);
    return `${fontSize}vp`;
  }

 /**
   * 获取栅格个数
   *
   * @param { string } 断点类型
   * @return { number } 栅格个数
   */
  public getGridCount(curBp: string): number {
    if (curBp === 'sm' || curBp === 'xs') {
      return 4;
    }
    if (curBp === 'md') {
      return 8;
    }
    return 12;
  }

  /**
   * 获取栅格间距
   *
   * @param { string } 断点类型
   * @return { number } 栅格间距
   */
  public getRowSpace(curBp: string): number {
    if (curBp === 'sm' || curBp === 'xs') {
      return 8;
    }
    if (curBp === 'md') {
      return 12;
    }
    return 16;
  }
}