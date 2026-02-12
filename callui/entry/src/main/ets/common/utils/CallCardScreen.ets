/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

/**
 * @file: Header information display component
 */
import { DisplayUtil } from '../utils/DisplayUtil';
import { display } from '@kit.ArkUI';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import { Context } from '@kit.AbilityKit';
import { isPhone } from '../utils/DeviceTypeUtils';
import LogUtils from './LogUtils';

const TAG = 'CallCardScreen';

let getDisplaySize: display.Display | null;

export default class CallCardScreen {
  public static context: Context
  private static sCallCardScreen: CallCardScreen

  public static getInstance(): CallCardScreen {
    if (!CallCardScreen.sCallCardScreen) {
      CallCardScreen.sCallCardScreen = new CallCardScreen();
    }
    return CallCardScreen.sCallCardScreen;
  }

  constructor() {
    try {
      getDisplaySize = display.getDefaultDisplaySync();
      LogUtils.i(TAG, `get displaySize success`);
    } catch (error) {
      getDisplaySize = null;
      LogUtils.i(TAG, `get displaySize fail`);
    }
  }

  public getImageWidth(widthSource: Resource, windowSizeChangeMd: ScreenInfo, landscapeOrPortrait: number,
    curBp: string): number {
    let width = getContext(CallCardScreen.context)?.resourceManager.getNumber(widthSource);
    let windowHeight = landscapeOrPortrait === 0 ? getDisplaySize?.width : getDisplaySize?.height;
    if (DisplayUtil?.getScreenFoldStatus() === 2 || (isPhone() && landscapeOrPortrait === 0)) {
      return (width / px2vp(windowHeight)) * px2vp(windowSizeChangeMd.height);
    }
    return 110;
  }

  public getInstanceCallHeight(value: Resource, windowSizeChangeMd: ScreenInfo, landscapeOrPortrait: number = -1) {
    let displaySize = getDisplaySize?.height;
    if ((DisplayUtil?.getScreenFoldStatus() === 2 || isPhone()) && landscapeOrPortrait === 0) {
      displaySize = getDisplaySize?.width;
    }
    return `${(getContext(CallCardScreen.context)?.resourceManager
      .getNumber(value) / px2vp(displaySize)) * px2vp(windowSizeChangeMd.height)}`;
  }

  public getInstanceCallWidth(value: Resource, windowSizeChangeMd: ScreenInfo) {
    return `${(getContext(CallCardScreen.context)?.resourceManager
      .getNumber(value) / px2vp(getDisplaySize?.width)) * px2vp(windowSizeChangeMd.width)}`;
  }

  /**
   * get screen FoldStatus
   *
   * isShowSmartWindow: 是否悬浮窗； statusBarHeight：悬浮窗中窗状态; isConferenceMode： 会议模式
   */
  public callLableTop(isShowSmartWindow: boolean, statusBarHeight: number, isShowKeyboard: boolean,
    isConferenceMode: boolean): string | Resource {
    if (isShowSmartWindow) {
      if (DisplayUtil?.isFoldable() && DisplayUtil?.getScreenFoldStatus() === 2) {
        if (isShowKeyboard || isConferenceMode) {
          return statusBarHeight ? '0vp' : $r('app.float.funbtn_image_width');
        }
        return $r('app.float.calling_photo_top');
      }
      return statusBarHeight ? (isConferenceMode ? '35vp' : '45vp') : $r('app.float.calling_photo_top');
    }
    return $r('app.float.calling_name_top');
  }

  /**
   * get screen FoldStatus
   *
   * isShowSmartWindow: 是否悬浮窗； statusBarHeight：悬浮窗中窗状态; windowSizeChangeMd: 窗口大小
   */
  public callImageTop(isShowSmartWindow: boolean, statusBarHeight: number,
    windowSizeChangeMd: ScreenInfo, landscapeOrPortrait: number): string | Resource {
    if (isShowSmartWindow) {
      if (DisplayUtil?.isFoldable()) {
        if (DisplayUtil?.getScreenFoldStatus() === 1) {
          return statusBarHeight ? `${statusBarHeight}` : this.getInstanceCallHeight($r('app.float.calling_photo_top'),
            windowSizeChangeMd);
        } else if (DisplayUtil?.getScreenFoldStatus() === 2) {
          return this.isHasFold(statusBarHeight, landscapeOrPortrait);
        } else {
          LogUtils.i(TAG, 'callImageTop screen fold status not 1 or 2.');
        }
      } else {
        return statusBarHeight ? this.setLandscapeOrPortraitSize(landscapeOrPortrait) :
          `${this.getInstanceCallHeight($r('app.float.calling_photo_top'), windowSizeChangeMd)}`;
      }
    }
    return $r('app.float.calling_photo_top');
  }

  setLandscapeOrPortraitSize(landscapeOrPortrait: number) {
    if (isPhone() && landscapeOrPortrait === 0) {
      return '10';
    }
    return '22';
  }

  public callImageBottom(isShowSmartWindow: boolean, statusBarHeight: number, windowSizeChangeMd: ScreenInfo,
    landscapeOrPortrait: number):
  string | Resource {
    if (isShowSmartWindow) {
      if (DisplayUtil?.isFoldable()) {
        if (DisplayUtil?.getScreenFoldStatus() === 1) {
          return this.getInstanceCallWidth($r('app.float.wh_value_24'),
            windowSizeChangeMd);
        } else if (DisplayUtil?.getScreenFoldStatus() === 2) {
          return this.getInstanceCallHeight($r('app.float.wh_value_24'), windowSizeChangeMd, landscapeOrPortrait);
        } else {
          LogUtils.i(TAG, 'callImageBottom screen fold status not 1 or 2.');
        }
      } else {
        return this.getInstanceCallHeight($r('app.float.wh_value_24'), windowSizeChangeMd, landscapeOrPortrait);
      }
    }
    return $r('app.float.wh_value_24');
  }

  public isHasFold(statusBarHeight: number, landscapeOrPortrait: number): string | Resource {
    if (statusBarHeight) {
      return landscapeOrPortrait === 0 ? `5vp` : `10vp`;
    }
    return `20vp`;
  }

  public MultiContactTop(isShowSmartWindow: boolean, statusBarHeight: number): string | Resource {
    if (isShowSmartWindow) {
      if (DisplayUtil?.isFoldable() && DisplayUtil?.getScreenFoldStatus() === 2) {
        if (statusBarHeight) {
          return `${statusBarHeight - 10}vp`;
        }
        return `40vp`;
      }
      return statusBarHeight ? `${44 - statusBarHeight}vp` : `${statusBarHeight}vp`;
    }
    return $r('app.float.call_list_top');
  }
}