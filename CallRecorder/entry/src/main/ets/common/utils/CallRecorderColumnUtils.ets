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
import LogUtils from './LogUtils';

/**
 * @file: Tools
 */

export default class CallRecorderColumnUtils {
  private static sCallColumnUtils: CallRecorderColumnUtils

  public static getInstance(): CallRecorderColumnUtils {
    if (CallRecorderColumnUtils.sCallColumnUtils == null) {
      CallRecorderColumnUtils.sCallColumnUtils = new CallRecorderColumnUtils();
    }
    return CallRecorderColumnUtils.sCallColumnUtils;
  }

  /**
   * Update breakpoint based on the current window size
   *
   * @param { number } windowWidth
   */

  public updateBreakpoint(windowWidth: number) {
    let curBp = AppStorage.get<string>('curBp');
    // Calculate px to vp
    try {
      let displaySync = display.getDefaultDisplaySync();
      let windowWidthVp = windowWidth / (displaySync.densityDPI / 160);
      this.updateCurbp(windowWidthVp, curBp);
    } catch (error) {
      LogUtils.e('CallRecorderColumnUtils', 'Error getting default display densityPixels');
    }
  }

  public updateCurbp(windowWidthVp: number, curBp: string | undefined) {
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
      AppStorage.setOrCreate('curBp', curBp);
    }
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
}
