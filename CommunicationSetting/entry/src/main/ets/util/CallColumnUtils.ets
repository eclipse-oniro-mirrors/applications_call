/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import display from '@ohos.display';
import { LogUtil } from './LogUtil';
import { isTablet } from './DeviceUtil';

const TAG = 'CallColumnUtils';

/**
 * @file: Tools
 */

export default class CallColumnUtils {
  private static sCallColumnUtils: CallColumnUtils;

  public display: display.Display | undefined = undefined;

  public static getInstance(): CallColumnUtils {
    if (CallColumnUtils.sCallColumnUtils == null) {
      CallColumnUtils.sCallColumnUtils = new CallColumnUtils();
    }
    return CallColumnUtils.sCallColumnUtils;
  }

  /**
   * Update breakpoint based on the current window size
   *
   * @param { number } windowWidth
   */
  public updateBreakpoint(windowWidth: number) {
    let curBp = AppStorage.get<string>('curBp');
    try {
      let windowWidthVp = -1;
      let displayDensity = display.getDefaultDisplaySync();
      if (windowWidth === -1) {
        windowWidthVp = displayDensity.width / (displayDensity.densityDPI / 160);
      } else {
        windowWidthVp = windowWidth / (displayDensity.densityDPI / 160);
      }
      // Calculate px to vp
      let newBp: string = '';
      if (windowWidthVp < 320) {
        newBp = 'xs';
      } else if (windowWidthVp < 600) {
        newBp = 'sm';
      } else if (windowWidthVp < 840) {
        newBp = 'md';
      } else {
        newBp = 'lg';
      }
      if (curBp !== newBp) {
        curBp = newBp;
        // Update the breakpoint
        LogUtil.info(TAG, 'updateBreakpoint to ' + newBp);
        AppStorage.setOrCreate('curBp', curBp);
      }
    } catch (err) {
      LogUtil.error(TAG, `updateBreakpoint error: ${err?.code} ${err?.message}`);
    }
  }

  /**
   * Obtain the gridCount of dialogs
   *
   * @param { string } curBp
   * @param { number } ratio
   * @return { number } gridCount
   */
  public getDialogGridCount(curBp: string, ratio: number) {
    if (curBp && ratio) {
      if (curBp === 'sm') {
        return ratio > (9 / 16) ? 3 : 4;
      } else if (curBp === 'md') {
        return ratio > (3 / 4) ? 4 : 5;
      } else if (curBp === 'lg') {
        return ratio > (4 / 3) ? 5 : 6;
      }
    }
    return 4;
  }

  /**
   * Obtain the alignment of dialogs
   *
   * @param { string } curBp
   * @return { DialogAlignment } alignment
   */
  public getDialogAlignment(curBp: string) {
    return curBp === 'sm' ? DialogAlignment.Default : DialogAlignment.Center;
  }
  
  /**
   * return padding space
   *
   * @param { string } curBp
   * @return { Resource } resource
   */
  public getPaddingSpace(curBp: string): Resource {
    if (curBp === 'xs' || curBp === 'sm') {
      return $r('sys.float.padding_level8');
    }
    if (curBp === 'md') {
      return $r('sys.float.padding_level12');
    }
    return $r('sys.float.padding_level16');
  }

  getNaviPaddingSpace(direction: string): Resource {
    if (isTablet()) {
      return $r('app.float.value_24');
    } else {
      if (direction === 'left') {
        return $r('sys.float.margin_left')
      } else if (direction === 'right') {
        return $r('sys.float.margin_right')
      } else {
        return $r('app.float.dialog_menu_font_size');
      }
    }
  }

  /**
   * return row space
   *
   * @param { string } curBp
   * @return { Resource } resource
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

  public getGridCount(curBp: string): number {
    if (curBp === 'sm' || curBp === 'xs') {
      return 4;
    }
    if (curBp === 'md') {
      return 8;
    }
    return 12;
  }
}
