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

import LogUtils from './LogUtils';
import display from '@ohos.display';
import measure from '@ohos.measure';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import observer from '@ohos.arkui.observer';
import { DisplayUtil } from './DisplayUtil';
import { common } from '@kit.AbilityKit';
import { GlobalContextHelper } from './GlobalContextHelper';
import { CALL_ABILITY_CONTEXT } from './Constants';
import SplitScreenManager from '../../model/SplitScreenManager';
import ScreenAdapterUtils from './ScreenAdapterUtils';
import { window } from '@kit.ArkUI';
import { isTwoInOne } from './DeviceTypeUtils';
import Window from '@ohos.window';
import { TrifoldManager } from './TrifoldManager';
import { getWindowDensity } from './WindowApi';
import CallManagerService from '../../ServiceAbility/CallManagerService';
import * as Constants from '../utils/Constants';
import { AppBtnStyleData, AppFuncBtnStyleData, AppWindowStyleData } from '../struct/TypeUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { JSON } from '@kit.ArkTS';
import { ProximityUtils } from './ProximityUtils';

const TAG = 'CallColumnUtils';

/**
 * 宽度断点
 */
export enum AppWidthBp {
  // 初始值
  DEFAULT = 0,
  // 0 - 600 4C
  SMALL = 1,
  // 600 - 840 8C
  MEDIUM = 2,
  // 840 - 1440 12C
  LARGE = 3,
  // > 1440 12C
  X_LARGE = 4
}

/**
 * 高度断点
 */
export enum AppHeightBp {
  // 初始值
  DEFAULT = 0,
  // < 960vp
  SMALL = 1,
  // 960vp - 1920vp
  MEDIUM = 2,
  // > 1920vp
  LARGE = 3
}

/**
 * @file: Tools
 */

export default class CallColumnUtils {
  private static sCallColumnUtils: CallColumnUtils;
  public static readonly maxWidth: number = 480;
  public static readonly maxHeight: number = 960;
  public display: display.Display | undefined = undefined;
  private splitManager: SplitScreenManager = SplitScreenManager.getInstance();
  public decorHeight = 0;
  public appWidthBp: AppWidthBp = AppWidthBp.DEFAULT;
  public appHeightBp: AppHeightBp = AppHeightBp.DEFAULT;

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
  public updateBreakpoint(windowWidth: number, windowObj?: Window.Window) {
    let curBp = AppStorage.get<string>('curBp');
    // Calculate px to vp
    try {
      let displayId = windowObj?.getWindowProperties()?.displayId;
      // instrument ignore else
      if (displayId === undefined) {
        this.display = display.getDefaultDisplaySync();
      } else {
        this.display = display.getDisplayByIdSync(displayId);
      }
    } catch (error) {
      LogUtils.e(TAG, 'updateBreakpoint failed ');
    }
    // instrument ignore else
    if (windowWidth <= 0) {
      LogUtils.w(TAG, `updateBreakpoint windowWidth is invalid use display width: ${this.display?.width}`);
      if (this.display?.width) {
        windowWidth = this.display?.width;
      } else {
        return;
      }
    }
    LogUtils.i(TAG, `display density:${this.display?.densityPixels}`);
    let dpi = getWindowDensity(windowObj);
    if (dpi === null || dpi === undefined || dpi === 0 || this.display?.id) {
      dpi = ((this.display?.densityDPI || 160) / 160);
    }
    LogUtils.i(TAG, `density:${dpi}`);
    let windowWidthVp = windowWidth / dpi;
    let newBp: string = '';
    if (windowWidthVp < 320) {
      if (ScreenAdapterUtils.isNewFormFoldPhone()) {
        newBp = 'sm';
      } else {
        newBp = 'xs';
      }
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
  public getItemSpace(curBp: string, isNewFoldPhoneExternalScreen: boolean = false): Resource {
    if (isNewFoldPhoneExternalScreen) {
      return $r('sys.float.padding_level2');
    }
    if (curBp === 'sm' || curBp === 'xs') {
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
  public getPaddingSpace(curBp: string): Resource {
    if (curBp === 'sm' || curBp === 'xs') {
      return $r('sys.float.padding_level8');
    }
    if (curBp === 'md') {
      return $r('sys.float.padding_level12');
    }
    return $r('sys.float.padding_level16');
  }


  public getKeyBordMarginSpace(curBp: string): Resource {
    if (curBp === 'sm' || curBp === 'xs') {
      return $r('sys.float.padding_level16');
    }
    if (curBp === 'md') {
      return $r('sys.float.padding_level24');
    }
    return $r('sys.float.padding_level32');
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

  public getVideoKeyBoardRowSpace(curBp: string): number {
    if (curBp === 'sm' || curBp === 'xs') {
      return 0;
    }
    return 8;
  }

  public getVideoSmall(curBp: string, windowSizeWidth: number, windowSizeHeight: number): number {
    let minWidth = Math.min(windowSizeWidth, windowSizeHeight) / 4.5;
    let width = Math.floor(minWidth / 8) * 8;
    return width;
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

  /**
   * Auto Size Name Text
   * The default font size is 48. If the name text exceeds one line, the font size decreases gradually.
   * The minimum font size is 30. The minimum font size of new form fold phone is 22.
   * @param name
   * @param curBp
   * @returns
   */
  public getDisplayNameForAutoSize(name: ResourceStr | undefined, curBp: string,
    isVideo: boolean = false, isConference: boolean = false): string {
    let fontSize = 38;
    let size: number = (curBp === 'sm' || curBp === 'xs') ? 16 : curBp === 'md' ? 24 : 32;
    let subSpace: number = (size * 2 + (isConference ? 16 : 0));
    let windowSize: ScreenInfo | undefined = AppStorage.get('windowSizeChangeMd');
    if (!windowSize) {
      LogUtils.i(TAG, 'getDisplayNameForAutoSize window size is null');
      return `${fontSize}vp`;
    }
    let widthVp = (px2vp(windowSize?.width) - size * 2 - subSpace);
    if (!isVideo) {
      if (curBp === 'md' || curBp === 'lg') {
        let gridWidth = (widthVp - (this.getGridCount(curBp) - 1) * this.getRowSpace(curBp)) / this.getGridCount(curBp);
        widthVp = widthVp - (gridWidth + this.getRowSpace(curBp)) * (curBp === 'md' ? 2 : 4);
      }
    }
    widthVp = widthVp * 0.7;
    const minFontSize = AppStorage.get('isNewFoldPhoneInnerFullScreen') ? 22 : 30;
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
    let splitFontSize = SplitScreenManager.getInstance().getAutoNickFontSize();
    if (splitFontSize.length > 0) {
      return splitFontSize;
    }
    return `${fontSize}vp`;
  }

  public getGridWidth(curBp: string): number {
    let splitManager = SplitScreenManager.getInstance();
    let screenWidth = 0;
    if (splitManager.isTableSplitScreen() &&
      splitManager.getWindowWidth() > 0) {
      LogUtils.i(TAG, 'getGridWidth isTableSplitScreen');
      screenWidth = px2vp(splitManager.getWindowWidth());
    } else {
      LogUtils.i(TAG, 'getGridWidth display width');
      screenWidth = px2vp(this.display?.width);
    }
    let paddingSize: number = (curBp === 'sm' || curBp === 'xs') ? 16 : curBp === 'md' ? 24 : 32;
    let gridCount: number = this.getGridCount(curBp);
    let rowSpaceSize: number = this.getRowSpace(curBp);
    let gridWidth = (screenWidth - (paddingSize * 2) - (rowSpaceSize * (gridCount - 1))) / gridCount;
    return gridWidth;
  }

  addDisplayChange() {
    try {
      display.on('change', (id: number) => {
        try {
          this.display = display.getDefaultDisplaySync();
        } catch (error) {
          LogUtils.e(TAG, 'Error getting default display');
          return;
        }
        let orientation = this.display?.orientation;
        LogUtils.i(TAG, 'display orientation: ' + orientation);
        let rotation = this.display.rotation;
        LogUtils.i(TAG, 'display rotation: ' + rotation);
        if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
          AppStorage.setOrCreate<number>('LandscapeOrPortrait', 0);
        } else {
          AppStorage.setOrCreate<number>('LandscapeOrPortrait', 1);
        }
        AppStorage.setOrCreate<number>('CurrentOrientation', orientation);
        const rotationCache = AppStorage.get<number>('rotation')
        if (rotationCache !== rotation && rotationCache !== undefined) {
          LogUtils.i(TAG, `rotationCache: ${rotationCache} rotation: ${rotation}}`);
          ProximityUtils.updateProximityLock();
        }
        AppStorage.setOrCreate<number>('rotation', rotation);
        //判断是否连接眼镜，放开DPI限制
        this.isGlassDisplay();
      })
    } catch (error) {
      LogUtils.e(TAG, 'An exception occurs in the on method of display.');
    }
  }

  removeDisplayChange() {
    try {
      display.off('change');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to removeDisplayChange');
    }
  }

  /**
   * 根据是否有眼镜屏幕，放开DPI限制
   */
  private async isGlassDisplay(): Promise<void> {
    try {
      let displayID = await CallManagerService.getInstance().getVisionGlassDisplayId();
      let context = GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT)
      context?.windowStage?.setDefaultDensityEnabled(!displayID);
    } catch (err) {
      LogUtils.e(TAG, `changeDPI wrong:${JSON.stringify(err)}`);
    }
  }

  public getUiMaxWidth(curBp: string, gutter: number): number {
    let screenWidth: number = 0;
    try {
      screenWidth = display.getDefaultDisplaySync().width;
    } catch (error) {
      LogUtils.e(TAG, 'An exception occurs in the getDefaultDisplaySync method of display.');
      return 0;
    }
    screenWidth = px2vp(screenWidth);
    let paddingSize: number = curBp === 'sm' || curBp === 'xs' ? 16 : curBp === 'md' ? 24 : 32;
    let gridCount: number = this.getGridCount(curBp);
    let singleWidth = (screenWidth - (paddingSize * 2) - (gutter * (gridCount - 1))) / gridCount;
    let realGridCount: number = (curBp === 'sm' || curBp === 'xs') ? 4 : curBp === 'md' ? 6 : 8;
    let uiMaxWidth = realGridCount * singleWidth + (realGridCount - 1) * gutter
    return uiMaxWidth;
  }

  public getTextWidth(textStr: string | Resource, fontSize: number | string | Resource): number {
    const textWidthVp = px2vp(measure.measureText({
      textContent: textStr,
      fontSize: fontSize
    }));
    return textWidthVp;
  }

  public splitTextIntoLines(text: string, fontSize: number | string | Resource, maxWidth: number): string[] {
    let lines: string[] = [];
    let currentLine = '';
    for (let i = 0; i < text.length; i++) {
      let char = text[i];
      let newLine = currentLine + char;
      if (this.getTextWidth(newLine, fontSize) <= maxWidth) {
        currentLine = newLine;
      } else {
        lines.push(currentLine);
        currentLine = char;
      }
    }
    lines.push(currentLine);
    return lines;
  }

  addDensityUpdateObserver(context: UIContext) {
    try {
      observer.on('densityUpdate', context, (densityInfo: observer.DensityInfo) => {
        if (!densityInfo) {
          return;
        }
        LogUtils.i(TAG, 'densityUpdate: ' + densityInfo.density);
        AppStorage.setOrCreate<number>('Density', densityInfo.density);
      });
    } catch (error) {
      LogUtils.e(TAG, `addDensityUpdateObserver error :${JSON.stringify(error)}`);
    }
  }

  removeDensityUpdateObserver(context: UIContext) {
    try {
      observer.off('densityUpdate', context);
    } catch (error) {
      LogUtils.e(TAG, `removeDensityUpdateObserver error :${JSON.stringify(error)}`);
    }
  }

  private needFolwLateWidth(curBp: string, isShowSmartWindow: boolean, isSmartWindowSplitScreen?: boolean): boolean {
    return (curBp === 'lg' && !isTwoInOne()) ||
      (TrifoldManager.getInstance().isTrifold() &&
        !SplitScreenManager.getInstance().isSplitScreenStatus() && !isShowSmartWindow && !isSmartWindowSplitScreen);
  }

  public rowsGap(windowSizeChangeMd: ScreenInfo, isShowSmartWindow: boolean, statusBarHeight: number,
    airbarHeight: number, curBp: string, isSmartWindowSplitScreen: boolean): number {
    let windowSizeChangeMdHeight: number = windowSizeChangeMd.height;
    if (this.needFolwLateWidth(curBp, isShowSmartWindow, isSmartWindowSplitScreen)) {
      let isBig = windowSizeChangeMd.width > windowSizeChangeMd.height;
      windowSizeChangeMdHeight = isBig ? windowSizeChangeMd.height : windowSizeChangeMd.width;
    }
    let phoneHeight = px2vp(windowSizeChangeMdHeight);
    let appHeight = this.getAppHeight(phoneHeight, statusBarHeight, airbarHeight);
    let bottomSpaceHeight = this.getCallBottomHeight();
    let sp: number = appHeight * 0.6 - bottomSpaceHeight - (64 * 5);
    if (isShowSmartWindow && !isSmartWindowSplitScreen) {
      if (DisplayUtil.isFoldable() && (curBp === 'sm' || curBp === 'xs') && DisplayUtil.getScreenFoldStatus() === 2) {
        sp = (appHeight - bottomSpaceHeight) * 0.7 - (64 * 5);
      } else {
        sp = (appHeight - bottomSpaceHeight) * 0.6 - (64 * 5);
      }
    }
    let rowsGapNum = 0;
    if (sp > 0) {
      rowsGapNum = sp / 4;
    }
    let splitRowGap = this.splitManager.getCallFuncRowsGap(appHeight, 64, bottomSpaceHeight);
    if (splitRowGap > 0) {
      rowsGapNum = splitRowGap;
    }
    LogUtils.i(TAG, `rowsGapNum value is ${rowsGapNum}`);
    return rowsGapNum;
  }

  public gridHeight(windowSizeChangeMd: ScreenInfo, isShowSmartWindow: boolean, statusBarHeight: number,
    airbarHeight: number, curBp: string, isSmartWindowSplitScreen: boolean): number {
    let windowSizeChangeMdHeight: number = windowSizeChangeMd.height;
    if (this.needFolwLateWidth(curBp, isShowSmartWindow, isSmartWindowSplitScreen)) {
      let isBig = windowSizeChangeMd.width > windowSizeChangeMd.height;
      windowSizeChangeMdHeight = isBig ? windowSizeChangeMd.height : windowSizeChangeMd.width;
    }
    let phoneHeight = px2vp(windowSizeChangeMdHeight);
    let appHeight = this.getAppHeight(phoneHeight, statusBarHeight, airbarHeight);
    let bottomSpaceHeight = this.getCallBottomHeight();
    let rowGap = this.rowsGap(windowSizeChangeMd, isShowSmartWindow, statusBarHeight, airbarHeight, curBp,
      isSmartWindowSplitScreen);
    let height = appHeight * 0.6 - bottomSpaceHeight - rowGap - 64;
    if (isShowSmartWindow) {
      if ((DisplayUtil.isFoldable() && (curBp === 'sm' || curBp === 'xs') && DisplayUtil.getScreenFoldStatus() === 2) &&
        !this.splitManager.isSplitScreenStatus()) {
        height = (appHeight - bottomSpaceHeight) * 0.7 - rowGap - 64;
      } else {
        height = (appHeight - bottomSpaceHeight) * 0.6 - rowGap - 64;
      }
    }
    let splitHeight = this.splitManager.getCallFuncHeight(appHeight, 64, bottomSpaceHeight, rowGap);
    if (splitHeight > 0) {
      height = splitHeight;
    }
    return height;
  }

  private getCallBottomHeight(): number {
    if (isTwoInOne()) {
      return 64;
    }
    return 35;
  }

  private getAppHeight(phoneHeight: number, statusBarHeight: number, airbarHeight: number) {
    let appHeight = phoneHeight - statusBarHeight - airbarHeight;
    if (isTwoInOne()) {
      appHeight = appHeight - this.decorHeight;
    }
    return appHeight;
  }

  getWindowDecorHeight(window: window.Window): number {
    try {
      this.decorHeight = window.getWindowDecorHeight();
      LogUtils.i(TAG, `getWindowDecorHeight of window decor: ${this.decorHeight}`);
      return this.decorHeight;
    } catch (exception) {
      LogUtils.e(TAG, `getWindowDecorHeight fail of window decor.`);
      return this.decorHeight;
    }
  }

  setWindowLimit(window: window.Window) {
    try {
      if (!this.judgeIsApplyNewStyle()) {
        return;
      }
      let windowLimits = window.getWindowLimits();
      // 窗口最小宽度为400vp
      let minWidth = Math.round(vp2px(400));
      let minHeight = Math.round(vp2px(777));
      windowLimits.minWidth = minWidth;
      windowLimits.minHeight = minHeight;
      LogUtils.i(TAG, `setWindowLimit, minWidth: ${minWidth},minHeight:${minHeight}`);
      let promise = window.setWindowLimits(windowLimits);
      promise.then((data) => {
        LogUtils.i(TAG, 'Succeeded in changing the window limits');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `Failed to setWindowLimits. err code: ${err.code}, message: ${err.message}`);
      });
    } catch (exception) {
      LogUtils.e(TAG, `Failed to setWindowLimits. Cause code: ${exception.code}, message: ${exception.message}`);
    }
  }

  getCallNormalPercent(windowSize: ScreenInfo,
    isShowSmartWindow: boolean,
    statusBarHeight: number,
    airbarHeight: number,
    percent: number): number {
    if (isShowSmartWindow) {
      let phoneHeight = px2vp(windowSize.height);
      let appHeight = this.getAppHeight(phoneHeight, statusBarHeight, airbarHeight);
      let bottomHeight = this.getCallBottomHeight();
      if (appHeight > 0) {
        return (appHeight - bottomHeight) * percent / appHeight;
      }
    }
    return percent;
  }

  clearFontCollection() {
    import('@ohos.graphics.text').then((text) => {
      LogUtils.i(TAG, 'clearFontCollection')
      let fontCollection = text.default.FontCollection.getGlobalInstance();
      fontCollection.clearCaches();
    })
  }

  windowSizeChange(width: number, height: number, windowObj: Window.Window) {
    try {
      // 目前只针对pc展开态适配
      let isApplyNewStyle: boolean = this.judgeIsApplyNewStyle();
      LogUtils.i(TAG, `windowSizeChange isApplyNewStyle:${isApplyNewStyle}`);
      AppStorage.setOrCreate('isApplyNewStyle', isApplyNewStyle);
      if (!isApplyNewStyle) {
        return;
      }
      let appWidthVp: number = px2vp(width);
      let appHeightVp: number = px2vp(height);
      this.appWidthBp = this.getAppWidthBpByWidth(appWidthVp);
      this.appHeightBp = this.getAppHeightBpByHeight(appHeightVp);
      LogUtils.i(TAG, `windowSizeChange appWidthBp:${this.appWidthBp}, appHeightBp:${this.appHeightBp}`);
      let area = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      let statusBarHeight = px2vp(area.topRect.height);
      let bottomArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      let indicatorHeight = px2vp(bottomArea.bottomRect.height);

      // 窗口变化根据新规则进行布局规则计算
      let appWindow: AppWindowStyleData = new AppWindowStyleData();
      let appBtnStyle: AppBtnStyleData = new AppBtnStyleData();
      let funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();
      this.initAppWindow(appWidthVp, this.appWidthBp, this.appHeightBp, appWindow);
      this.initAppBtnStyle(this.appHeightBp, appBtnStyle);
      this.initBottomBtnBottomGap(appHeightVp, appWindow, appBtnStyle, statusBarHeight, indicatorHeight);
      this.initBottomBtnColumnGap(appWindow, appBtnStyle);
      this.initFuncBtnStyle(this.appHeightBp, funcBtnStyle);
    } catch (exception) {
      LogUtils.e(TAG, `windowSizeChange error code:${exception?.code}`);
    }
  }

  initAppWindow(windowWidth: number, appWidthBp: AppWidthBp, appHeightBp: AppHeightBp, appWindow: AppWindowStyleData) {
    // 通话内容区域宽度，最大宽度960vp
    appWindow.maxWidth = 960;

    appWindow.appWidth = windowWidth;
    switch (appWidthBp) {
      // 4C
      case AppWidthBp.DEFAULT:
      case AppWidthBp.SMALL:
        break;
      // 8C margin=24vp,gutter=12vp,内容区域：[6C+7Gutter]
      case AppWidthBp.MEDIUM:
        let oneGridColumnWidth = (windowWidth - (24 * 2) - (12 * 7)) / 8;
        let uiWidth = Math.round(6 * oneGridColumnWidth + 7 * 12);
        appWindow.appWidth = uiWidth;
        break;
      // 12C margin=32vp,gutter=16vp,内容区域：[6C+7Gutter]
      case AppWidthBp.LARGE:
        let oneGridColumnWidthLarge = (windowWidth - (32 * 2) - (16 * 11)) / 12;
        let uiWidthLarge = Math.round(6 * oneGridColumnWidthLarge + 7 * 16);
        appWindow.appWidth = uiWidthLarge;
        break;
      // 12C
      case AppWidthBp.X_LARGE:
        appWindow.appWidth = windowWidth;
        break;
    }
    LogUtils.i(TAG, `initAppWindow appWidth:${appWindow.appWidth}`);
    let minWidth = Math.min(appWindow.appWidth, appWindow.maxWidth);
    appWindow.appWidth = minWidth;
    appWindow.maxWidth = minWidth;

    // 通话内容区域最大高度
    switch (appHeightBp) {
      case AppHeightBp.DEFAULT:
        appWindow.maxHeight = undefined;
        break;
      case AppHeightBp.SMALL:
        appWindow.maxHeight = undefined;
        break;
      case AppHeightBp.MEDIUM:
        appWindow.maxHeight = 960;
        break;
      case AppHeightBp.LARGE:
        appWindow.maxHeight = 1280;
        break;
    }
    LogUtils.i(TAG, `initAppWindow maxWidth:${appWindow.maxWidth}, maxHeight:${appWindow.maxHeight}`);
    AppStorage.setOrCreate('appWindow', appWindow);
  }

  // instrument ignore next
  initBottomBtnBottomGap(windowHeight: number, appWindow: AppWindowStyleData, appBtnStyle: AppBtnStyleData,
    statusBarHeight: number, indicatorHeight: number) {
    let appHeight = this.getAppHeight(windowHeight, statusBarHeight, indicatorHeight);
    if (appWindow.maxHeight && appWindow.maxHeight > 0 && appHeight > appWindow.maxHeight) {
      appHeight = appWindow.maxHeight;
    }
    let btnBottomGap = appHeight * 0.6 - (appBtnStyle.btnWidth * 5) - (appBtnStyle.rowsGap * 4);
    // 按键距离窗口底部的最小间距48vp
    btnBottomGap = Math.max(Math.floor(btnBottomGap / 2), 48);
    LogUtils.i(TAG, `initBottomBtnBottomGap btnBottomGap:${btnBottomGap}, appHeight:${appHeight}`);
    AppStorage.setOrCreate('btnBottomGap', btnBottomGap);
  }

  // instrument ignore next
  initBottomBtnColumnGap(appWindow: AppWindowStyleData, appBtnStyle: AppBtnStyleData) {
    let appWidth = appWindow.appWidth ?? 0;
    let btnLeftGap = Math.floor((appWidth - (appBtnStyle.btnWidth * 3) ) / 4);
    if (btnLeftGap < 0) {
      btnLeftGap = 0
    }
    LogUtils.i(TAG, `initBottomBtnColumnGap btnLeftGap:${btnLeftGap},appWidth:${appWidth}`);
    AppStorage.setOrCreate('btnLeftGap', btnLeftGap);
  }

  // instrument ignore next
  judgeIsApplyNewStyle(): boolean {
    // 目前仅针对折叠pc进行适配
    if (!isTwoInOne() || !DisplayUtil.isFoldable()) {
      return false;
    }
    return true;
  }

  // instrument ignore next
  initAppBtnStyle(appHeightBp: AppHeightBp, appBtnStyle: AppBtnStyleData) {
    // 按钮样式
    switch (appHeightBp) {
      case AppHeightBp.DEFAULT:
      case AppHeightBp.SMALL:
        appBtnStyle.btnWidth = 64;
        appBtnStyle.rowsGap = 20;

        // 按钮样式
        appBtnStyle.innerSymbolColor = 'font_on_primary';
        appBtnStyle.innerSymbolSize = '28vp';
        appBtnStyle.outerLabelTextColor = 'font_on_secondary';
        appBtnStyle.outerLabelTextSize = '14vp';
        appBtnStyle.outerLabelTextWeight = FontWeight.Regular;
        appBtnStyle.btnLabelTextGap = '4vp';

        appBtnStyle.dtmfTopMargin = '12vp';
        appBtnStyle.dtmfTopTextColor = 'font_on_primary';
        appBtnStyle.dtmfTopTextSize = '24vp';
        appBtnStyle.dtmfTopTextWeight = FontWeight.Bold;

        // *和#
        appBtnStyle.dtmfTopSymbolTextSize = '24vp';
        appBtnStyle.dtmfTopSymbolTextLineHeight = '24vp';
        appBtnStyle.dtmfTopSymbolTextWeight = FontWeight.Regular;

        appBtnStyle.dtmfBottomTextColor = 'font_on_secondary';
        appBtnStyle.dtmfBottomTextSize = '10vp';
        appBtnStyle.dtmfBottomTextLineHeight = '14vp';
        appBtnStyle.dtmfBottomTextWeight = FontWeight.Regular;

        appBtnStyle.dtmfBottomPlusSize = '14vp';
        appBtnStyle.dtmfBottomPlusLineHeight = '14vp';

        appBtnStyle.dtmfBottomSymbolTextSize = '14vp';
        appBtnStyle.dtmfBottomSymbolTextLineHeight = '14vp';
        // dtmfTopMargin 12 + dtmfTopTextSize24 + 2vp
        appBtnStyle.dtmfBottomTopGap = '38vp';
        break;
      case AppHeightBp.MEDIUM:
        appBtnStyle.btnWidth = 80;
        appBtnStyle.rowsGap = 24;

        // 按钮样式
        appBtnStyle.innerSymbolColor = 'font_on_primary';
        appBtnStyle.innerSymbolSize = '36vp';
        appBtnStyle.outerLabelTextColor = 'font_on_secondary';
        appBtnStyle.outerLabelTextSize = '14vp';
        appBtnStyle.outerLabelTextWeight = FontWeight.Regular;
        appBtnStyle.btnLabelTextGap = '4vp';

        appBtnStyle.dtmfTopMargin = '15vp';
        appBtnStyle.dtmfTopTextColor = 'font_on_primary';
        appBtnStyle.dtmfTopTextSize = '30vp';
        appBtnStyle.dtmfTopTextWeight = FontWeight.Bold;

        // *和#
        appBtnStyle.dtmfTopSymbolTextSize = '30vp';
        appBtnStyle.dtmfTopSymbolTextLineHeight = '30vp';
        appBtnStyle.dtmfTopSymbolTextWeight = FontWeight.Regular;

        appBtnStyle.dtmfBottomTextColor = 'font_on_secondary';
        appBtnStyle.dtmfBottomTextSize = '12vp';
        appBtnStyle.dtmfBottomTextLineHeight = '16vp';
        appBtnStyle.dtmfBottomTextWeight = FontWeight.Regular;
        appBtnStyle.dtmfBottomPlusSize = '16vp';
        appBtnStyle.dtmfBottomPlusLineHeight = '16vp';

        appBtnStyle.dtmfBottomSymbolTextSize = '16vp';
        appBtnStyle.dtmfBottomSymbolTextLineHeight = '16vp';
        // dtmfTopMargin 15 + dtmfTopTextSize30 + 4vp
        appBtnStyle.dtmfBottomTopGap = '49vp';
        break;
      case AppHeightBp.LARGE:
        appBtnStyle.btnWidth = 120;
        appBtnStyle.rowsGap = 40;

        // 按钮样式
        appBtnStyle.innerSymbolColor = 'font_on_primary';
        appBtnStyle.innerSymbolSize = '48vp';
        appBtnStyle.outerLabelTextColor = 'font_on_secondary';
        appBtnStyle.outerLabelTextSize = '20vp';
        appBtnStyle.outerLabelTextWeight = FontWeight.Regular;
        appBtnStyle.btnLabelTextGap = '8vp';

        appBtnStyle.dtmfTopMargin = '20vp';
        appBtnStyle.dtmfTopTextColor = 'font_on_primary';
        appBtnStyle.dtmfTopTextSize = '48vp';
        appBtnStyle.dtmfTopTextWeight = FontWeight.Bold;
        // *和#
        appBtnStyle.dtmfTopSymbolTextSize = '48vp';
        appBtnStyle.dtmfTopSymbolTextLineHeight = '48vp';
        appBtnStyle.dtmfTopSymbolTextWeight = FontWeight.Regular;

        appBtnStyle.dtmfBottomTextColor = 'font_on_secondary';
        appBtnStyle.dtmfBottomTextSize = '18vp';
        appBtnStyle.dtmfBottomTextLineHeight = '24vp';
        appBtnStyle.dtmfBottomTextWeight = FontWeight.Regular;
        appBtnStyle.dtmfBottomPlusSize = '24vp';
        appBtnStyle.dtmfBottomPlusLineHeight = '24vp';

        appBtnStyle.dtmfBottomSymbolTextSize = '24vp';
        appBtnStyle.dtmfBottomSymbolTextLineHeight = '24vp';
        // dtmfTopMargin 20 + dtmfTopTextSize48 + 8vp
        appBtnStyle.dtmfBottomTopGap = '76vp';
        break;
    }
    AppStorage.setOrCreate('appBtnStyle', appBtnStyle);
    LogUtils.i(TAG, `initAppBtnStyle appBtnStyle:${JSON.stringify(appBtnStyle)}`);
  }

  // instrument ignore next
  initFuncBtnStyle(appHeightBp: AppHeightBp, funcBtnStyle: AppFuncBtnStyleData) {
    // 功能按键按钮样式
    switch (appHeightBp) {
      case AppHeightBp.DEFAULT:
      case AppHeightBp.SMALL:
        funcBtnStyle.btnWidth = 64;
        funcBtnStyle.rowsGap = 20;

        funcBtnStyle.innerIconWidth = '28vp';
        funcBtnStyle.outerTextSize = '14vp';
        funcBtnStyle.outerTextHeight = '19vp';
        funcBtnStyle.btnLabelGap = 4;
        // btnWidth * 2 + btnLabelGap * 2 + outerTextHeight * 2 + rowsGap
        funcBtnStyle.funcBtnGroupHeight = 194;
        funcBtnStyle.incomingIconWidth = '24vp';
        break;
      case AppHeightBp.MEDIUM:
        funcBtnStyle.btnWidth = 80;
        funcBtnStyle.rowsGap = 24;

        funcBtnStyle.innerIconWidth = '36vp';
        funcBtnStyle.outerTextSize = '14vp';
        funcBtnStyle.outerTextHeight = '19vp';
        funcBtnStyle.btnLabelGap = 4;
        // btnWidth * 2 + btnLabelGap * 2 + outerTextHeight * 2 + rowsGap
        funcBtnStyle.funcBtnGroupHeight = 230;
        funcBtnStyle.incomingIconWidth = '32vp';
        break;
      case AppHeightBp.LARGE:
        funcBtnStyle.btnWidth = 120;
        funcBtnStyle.rowsGap = 40;

        funcBtnStyle.innerIconWidth = '48vp';
        funcBtnStyle.outerTextSize = '20vp';
        funcBtnStyle.outerTextHeight = '27vp';
        funcBtnStyle.btnLabelGap = 8;
        // btnWidth * 2 + btnLabelGap * 2 + outerTextHeight * 2 + rowsGap
        funcBtnStyle.funcBtnGroupHeight = 350;
        funcBtnStyle.incomingIconWidth = '40vp';
        break;
    }
    AppStorage.setOrCreate('funcBtnStyle', funcBtnStyle);
    LogUtils.i(TAG, `initFuncBtnStyle funcBtnStyle:${JSON.stringify(funcBtnStyle)}`);
  }

  // instrument ignore next
  private getAppWidthBpByWidth(width: number): AppWidthBp {
    if (width < 600) {
      return AppWidthBp.SMALL;
    } else if (width <= 840) {
      return AppWidthBp.MEDIUM;
    } else if (width <= 1440) {
      return AppWidthBp.LARGE;
    } else if (width > 1440) {
      return AppWidthBp.X_LARGE;
    }
    return AppWidthBp.DEFAULT;
  }

  // instrument ignore next
  private getAppHeightBpByHeight(height: number): AppHeightBp {
    if (height < 960) {
      return AppHeightBp.SMALL;
    } else if (height <= 1920) {
      return AppHeightBp.MEDIUM;
    } else if (height > 1920) {
      return AppHeightBp.LARGE;
    }
    return AppHeightBp.DEFAULT;
  }
}