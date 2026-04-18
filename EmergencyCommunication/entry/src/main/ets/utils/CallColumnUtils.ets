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

import LogUtils from './HiLog';
import display from '@ohos.display';
import measure from '@ohos.measure';
import { isTablet } from './DeviceTypeUtils';

const TAG = 'CallColumnUtils';

/**
 * @file: Tools
 */

export default class CallColumnUtils {
  private static sCallColumnUtils: CallColumnUtils;

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
    // Calculate px to vp
    let windowWidthVp = 0;
    try {
      windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
    } catch (e) {
      LogUtils.e(TAG, 'updateBreakpoint error: ' + JSON.stringify(e));
    }
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
      LogUtils.i(TAG, 'updateBreakpoint to ' + newBp);
      AppStorage.setOrCreate('curBp', curBp);
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
   * return item space
   *
   * @param { string } curBp
   * @return { Resource } resource
   */
  public getItemSpace(curBp: string): Resource {
    if (curBp === 'sm') {
      return $r('sys.float.padding_level4');
    }
    if (curBp === 'md') {
      return $r('sys.float.padding_level6');
    }
    return $r('sys.float.padding_level8');
  }

  /**
   * return padding space
   *
   * @param { string } curBp
   * @return { Resource } resource
   */
  public getPaddingSpace(curBp: string, divideScreen: boolean): Resource {
    if (curBp === 'xs' || curBp === 'sm') {
      return $r('sys.float.padding_level8');
    }
    if (divideScreen) {
      return $r('sys.float.padding_level12');
    } else {
      if (curBp === 'md') {
        return $r('sys.float.padding_level12');
      }
      return $r('sys.float.padding_level16');
    }
  }

  /**
   * Determine whether the text is displayed in two lines in the landscape mode of the folded screen
   *
   * @param { string } address
   * @return { boolean } true/false
   */
  public getAddressTwoLineShow(address: string | undefined): boolean {
    let num = px2vp(measure.measureText({
      textContent: address,
      fontSize: 16,
      fontWeight: FontWeight.Regular
    }));
    if (num > 564) {
      return true;
    } else {
      return false;
    }
  }
  /**
   * Dual-SIM dialing keyboard margin
   *
   * @param { string } curBp
   * @return { number | Resource } number | Resource
   */
  public getDualSimPadding(curBp: string): number | Resource {
    if (curBp === 'sm') {
      return $r('sys.float.padding_level8');
    } else if (curBp === 'md') {
      return 67;
    } else {
      return 82;
    }
  }

  /**
   * Dual-SIM dialing keyboard Width
   *
   * @param { string } curBp
   * @return { number | Resource } number | Resource
   */
  public getDualSimButtonWidth(curBp: string): number {
    if (curBp === 'sm') {
      return 116;
    } else if (curBp === 'md') {
      return 140;
    } else {
      return 238
    }
  }

  /**
   * get NaviPadding Space
   *
   * @param direction
   * @returns resource
   */
  getNaviPaddingSpace(direction: string): Resource {
    if (isTablet()) {
      return $r('app.float.emc_margin_level12');
    } else {
      if (direction === 'left') {
        return $r('sys.float.margin_left')
      } else if (direction === 'right') {
        return $r('sys.float.margin_right')
      } else {
        return $r('app.float.emc_margin_level8');
      }
    }
  }

}