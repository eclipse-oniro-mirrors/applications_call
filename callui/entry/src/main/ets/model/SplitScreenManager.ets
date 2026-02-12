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

import window from '@ohos.window';
import { display } from '@kit.ArkUI';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import LogUtils from '../common/utils/LogUtils';
import DefaultCallData from '../common/struct/TypeUtils';
import { isIncomingCall } from '../common/utils/CallListHelper';
import { isPhone, isTablet, isTwoInOne } from '../common/utils/DeviceTypeUtils';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { TrifoldManager } from '../common/utils/TrifoldManager';

const TAG = 'SplitScreenManager';
const ONE_HALF = 1 / 2;
const ONE_THREE = 1 / 3;
const TWO_THREE = 2 / 3;

export enum SplitScreenType {
  DEFAULT = 0,
  SMALL = 1,
  MEDIUM = 2,
  BIG = 3
}

/**
 * class SplitScreenManager
 */
export default class SplitScreenManager {
  private static splitScreenManager: SplitScreenManager;
  public fullScreenHeight: number = 0;
  public fullScreenWidth: number = 0;
  public screenWidth: number = 0;
  public screenHeight: number = 0;
  public windowStatusType = window.WindowStatusType.UNDEFINED;
  public orientation = display.Orientation.PORTRAIT;
  public isTabletDevice: null | boolean = null;
  public isPhoneDevice: null | boolean = null;
  public isTwoInOneDevice: null | boolean = null;

  /**
   * create splite screen manager
   *
   * @returns {Object} - SplitScreenManager object
   */
  public static getInstance(): SplitScreenManager {
    if (!SplitScreenManager.splitScreenManager) {
      SplitScreenManager.splitScreenManager = new SplitScreenManager();
    }
    return SplitScreenManager.splitScreenManager;
  }

  getWindowWidth(): number {
    return this.screenWidth;
  }

  public isPhone(): boolean {
    if (this.isPhoneDevice === null) {
      this.isPhoneDevice = isPhone();
    }
    return this.isPhoneDevice;
  }

  public isTablet(): boolean {
    if (this.isTabletDevice === null) {
      this.isTabletDevice = isTablet();
    }
    return this.isTabletDevice;
  }

  public isTwoInOne(): boolean {
    if (this.isTwoInOneDevice === null) {
      this.isTwoInOneDevice = isTwoInOne();
    }
    return this.isTwoInOneDevice;
  }

  public isExpandedStatus(): boolean {
    try {
      return (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED ||
        display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED);
    } catch (error) {
      LogUtils.e(TAG, 'An exception occurs in the getFoldStatus method of display.');
      return false;
    }
  }

  updateWindowStatusType(type: WindowStatusType) {
    LogUtils.i(TAG, 'updateWindowStatusType ' + type);
    this.windowStatusType = type;
  }

  updateScreenSize(width: number, height: number) {
    this.screenWidth = width;
    this.screenHeight = height;

    let displayInfo = CallColumnUtils.getInstance().display;
    if (displayInfo !== undefined) {
      this.fullScreenWidth = displayInfo.width;
      this.fullScreenHeight = displayInfo.height;
      this.orientation = displayInfo.orientation;
    }
    LogUtils.i(TAG, `updateScreenSize width：${width}, fullWidth:${this.fullScreenWidth},
      height: ${height}, fullHeight:${this.fullScreenHeight} type: ${this.getSplitScreenType()}`);

    let splitScreenType: SplitScreenType = this.getSplitScreenType();
    AppStorage.setOrCreate('SplitScreenType', splitScreenType);
    AppStorage.setOrCreate('SplitScreenHeight', this.screenHeight);
    if (splitScreenType > SplitScreenType.DEFAULT && ScreenAdapterUtils.isNewFoldPhone && !this.isLandscape()) {
      // 新折叠竖屏分屏模式-仅内屏支持,外屏不支持分屏
      AppStorage.setOrCreate('newFoldSplitPortraitScreenType', splitScreenType);
      LogUtils.i(TAG, `newFoldSplitPortraitScreenType splitScreenType:${splitScreenType}`);
    } else {
      AppStorage.setOrCreate('newFoldSplitPortraitScreenType', SplitScreenType.DEFAULT);
      LogUtils.i(TAG, `newFoldSplitPortraitScreenType DEFAULT`);
    }
  }

  getSplitScreenType(): SplitScreenType {
    if (this.fullScreenWidth <= 0 || this.fullScreenHeight <= 0) {
      return SplitScreenType.DEFAULT;
    }
    // full screen
    if (this.screenWidth === this.fullScreenWidth &&
      this.screenHeight === this.fullScreenHeight) {
      LogUtils.i(TAG, `getSplitScreenType DEFAULT`);
      return SplitScreenType.DEFAULT;
    }
    if (this.windowStatusType == window.WindowStatusType.SPLIT_SCREEN && !isTwoInOne()) {
      // newFormFoldPhone
      if (ScreenAdapterUtils.isNewFoldPhone) {
        LogUtils.i(TAG, `getSplitScreenType isNewFormFoldPhone`);
        return this.getIphoneSplitScreenType();
      }
      // tablet
      if (this.isTablet()) {
        LogUtils.i(TAG, `getSplitScreenType tablet`);
        return this.getIpadSplitScreenType();
      }
      // foldable expanded
      if (DisplayUtil.isFoldable()) {
        LogUtils.i(TAG, `getSplitScreenType foldable`);
        return this.getFoldableSplitScreenType();
      }
      // landscape
      LogUtils.i(TAG, `getSplitScreenType landscape`);
      return this.getIphoneSplitScreenType();
    }
    LogUtils.i(TAG, `getSplitScreenType no SPLIT_SCREEN`);
    return SplitScreenType.DEFAULT;
  }

  // Tablet
  public getIpadSplitScreenType(): SplitScreenType {
    return this.calculateSplitScreenType();
  }

  // Foldable
  public getFoldableSplitScreenType(): SplitScreenType {
    if (this.fullScreenHeight <= 0) {
      return SplitScreenType.DEFAULT;
    }
    return this.calculateSplitScreenType(true);
  }

  // iphone
  public getIphoneSplitScreenType(): SplitScreenType {
    if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
      TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
      return SplitScreenType.MEDIUM;
    }
    return this.calculateSplitScreenType();
  }

  // Calculate screen-to-body ratio
  public calculateSplitScreenType(isFoldDevice: boolean = false): SplitScreenType {
    if (this.fullScreenHeight <= 0) {
      return SplitScreenType.DEFAULT;
    }
    let scale = this.screenHeight / this.fullScreenHeight;
    if (isFoldDevice && !ScreenAdapterUtils.isNewFormFoldPhone() && this.isFoldStatus() && this.isLandscape()) {
      LogUtils.i(TAG, `calculateSplitScreenType folded device landscape`);
      scale = this.screenWidth / this.fullScreenWidth;
    }
    LogUtils.i(TAG, `calculateSplitScreenType isFoldDevice: ${isFoldDevice} scale: ${scale}`);
    if (scale < ONE_THREE && scale > 0) {
      return SplitScreenType.SMALL;
    } else if (scale < ONE_HALF && scale > ONE_THREE) {
      return SplitScreenType.MEDIUM;
    } else if (scale < TWO_THREE && scale > ONE_HALF) {
      return SplitScreenType.BIG;
    } else {
      return SplitScreenType.DEFAULT;
    }
  }

  isSplitScreen(type: SplitScreenType) {
    LogUtils.i(TAG, `isSplitScreen type: ${type}`);
    if (this.fullScreenWidth <= 0 || this.fullScreenHeight <= 0) {
      return false;
    }
    if (this.screenWidth === this.fullScreenWidth &&
      this.screenHeight === this.fullScreenHeight) {
      return false;
    }
    if (type === SplitScreenType.DEFAULT) {
      return false;
    }
    return true;
  }

  isSplitScreenStatus(): boolean {
    if (this.windowStatusType == window.WindowStatusType.SPLIT_SCREEN) {
      return true;
    }
    return false;
  }

  callFuncBtnsVisibility(type: SplitScreenType): Visibility {
    LogUtils.i(TAG, `callFuncBtnsVisibility type: ${type}`);
    if (type === SplitScreenType.SMALL) {
      return Visibility.None;
    } else if (type === SplitScreenType.MEDIUM) {
      if (this.isTablet() || this.isTwoInOne()) {
        return Visibility.Visible;
      }
      return Visibility.None;
    } else {
      return Visibility.Visible;
    }
  }

  incomingCallFuncBtn(callList: Array<DefaultCallData>, type: SplitScreenType,
    isOsAccountUnlocked: boolean): Visibility {
    LogUtils.i(TAG, `incomingCallFuncBtn type: ${type}, isOsAccountUnlocked: ${isOsAccountUnlocked}`);
    if (!isOsAccountUnlocked) {
      return Visibility.None;
    }
    if (this.isTablet()) {
      if (type === SplitScreenType.SMALL && this.isTwoCallIncoming(callList, type)) {
        return Visibility.None;
      }
      return Visibility.Visible;
    } else {
      if (type === SplitScreenType.SMALL) {
        return Visibility.None;
      }
      if (type === SplitScreenType.MEDIUM && this.isTwoCallIncoming(callList, type)) {
        return Visibility.None;
      }
      return Visibility.Visible;
    }
  }

  callBottomKeyboardBtnEnable(type: SplitScreenType): boolean {
    LogUtils.i(TAG, `callBottomKeyboardBtnEnable type: ${type}`);
    if (type === SplitScreenType.SMALL ||
      type === SplitScreenType.MEDIUM ||
      (type === SplitScreenType.BIG && this.isPhone())) {
      return false;
    }
    return true;
  }

  commonCallCard(isShowSetNumberMark: boolean, type: SplitScreenType): Visibility {
    LogUtils.i(TAG, `commonCallCard isShowSetNumberMark: ${isShowSetNumberMark} type: ${type}`);
    if (isShowSetNumberMark &&
      type === SplitScreenType.SMALL &&
    this.isPhone()) {
      return Visibility.None;
    }
    return Visibility.Visible;
  }

  callListItem(currentData: DefaultCallData, callData: DefaultCallData, type: SplitScreenType): boolean {
    LogUtils.i(TAG, `commonCallCard currentState: ${currentData.callState} state:${callData.callState} type: ${type}`);
    if (type === SplitScreenType.DEFAULT) {
      return true;
    }
    if (isIncomingCall(currentData.callState)) {
      if (isIncomingCall(callData.callState) &&
        (type !== SplitScreenType.SMALL &&
        this.isPhone())) {
        return true;
      }
    } else {
      if (currentData.callId === callData.callId) {
        return true;
      }
    }
    return false;
  }

  callListShow(callList: Array<DefaultCallData>, type: SplitScreenType): Visibility {
    LogUtils.i(TAG, `callListShow type: ${type}`);
    if (callList.length <= 1) {
      return Visibility.Visible;
    }
    if (type === SplitScreenType.DEFAULT) {
      return Visibility.Visible;
    }
    let incomingCount = 0;
    for (let call of callList) {
      LogUtils.i(TAG, `callListShow callState: ${call.callState}`);
      if (isIncomingCall(call.callState)) {
        incomingCount += 1;
      }
    }
    if (incomingCount === 1) {
      return Visibility.None;
    }
    if (incomingCount === 2 &&
      type === SplitScreenType.SMALL &&
    this.isPhone()) {
      return Visibility.None;
    }
    return Visibility.Visible;
  }

  public isTwoCallIncoming(callList: Array<DefaultCallData>, type: SplitScreenType): boolean {
    LogUtils.i(TAG, `isTwoCallIncoming type: ${type}`);
    if (callList.length <= 1) {
      return false;
    }
    if (type === SplitScreenType.DEFAULT) {
      return false;
    }
    let incomingCount = 0;
    for (let call of callList) {
      LogUtils.i(TAG, `isTwoCallIncoming callState: ${call.callState}`);
      if (isIncomingCall(call.callState)) {
        incomingCount += 1;
      }
    }
    if (incomingCount > 1) {
      return true;
    }
    return false;
  }

  isCallHeadShow(type: SplitScreenType): boolean {
    LogUtils.i(TAG, `isCallHeadShow type: ${type}`);
    if (type === SplitScreenType.DEFAULT) {
      return true;
    }
    return false;
  }

  isNicknameOneLine(type: SplitScreenType, callData: DefaultCallData): boolean {
    LogUtils.i(TAG, `isNicknameOneLine type: ${type}`);
    if (type === SplitScreenType.SMALL) {
      return true;
    } else if (type === SplitScreenType.MEDIUM) {
      if (this.isPhone()) {
        return true;
      }
    } else if (type === SplitScreenType.BIG) {
      if (this.isPhone() && DisplayUtil.isFoldable() && !isIncomingCall(callData.callState)) {
        return true;
      }
    }
    return false;
  }

  getStrangeNumAddMenuPlacement(type: SplitScreenType): Placement {
    if (this.isPhone() && type === SplitScreenType.SMALL) {
      return Placement.RightTop;
    }
    return Placement.TopLeft;
  }

  callAssistantOutComingBtnShow(type: SplitScreenType): Visibility {
    if (!this.isSplitScreen(type)) {
      return Visibility.Visible;
    }
    if (this.isTablet() && type === SplitScreenType.BIG) {
      return Visibility.Visible;
    }
    return Visibility.None;
  }

  isTableSplitScreen(): boolean {
    if (this.isTablet() &&
      this.windowStatusType == window.WindowStatusType.SPLIT_SCREEN) {
      return true;
    }
    return false;
  }

  isPhoneSpliteScreenBig(type: SplitScreenType): boolean {
    LogUtils.i(TAG, `phoneSpliteScreenBig type: ${type}`);
    if (this.isPhone() &&
      type === SplitScreenType.BIG &&
      this.callFuncBtnsVisibility(type) === Visibility.Visible) {
      return true;
    }
    return false;
  }

  isPhoneVideoSplitScreenSmall(type: SplitScreenType): boolean {
    LogUtils.i(TAG, `isPhoneVideoSplitScreenSmall type: ${type}`);
    if (this.isPhone() &&
      type === SplitScreenType.SMALL) {
      return true;
    }
    return false;
  }

  public isLandscape(): boolean {
    LogUtils.i(TAG, `isLandscape ${this.orientation}`);
    if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
      TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
      return true;
    }
    return false;
  }

  isIncomingSpliteScreenMedium(height?: number): boolean {
    LogUtils.i(TAG, `isIncomingSpliteScreenMedium height: ${height}`);
    let type = this.getSplitScreenType();
    if (this.isPhone() && DisplayUtil.isFoldable() && this.isLandscape() && type === SplitScreenType.MEDIUM) {
      LogUtils.i(TAG, `isIncomingSpliteScreenMedium type: ${type}`);
      return true;
    }
    return false;
  }

  isIncomingPhoneSpliteScreen(height: number): boolean {
    LogUtils.i(TAG, `isIncomingPhoneSpliteScreen height: ${height}`);
    let type = this.getSplitScreenType();
    if (this.isPhoneSpliteScreen(type)) {
      return true;
    }
    if (this.isIncomingSpliteScreenMedium(height)) {
      return true;
    }
    return false;
  }

  getDisplayNameFontSize(type: SplitScreenType): string {
    LogUtils.i(TAG, `getDisplayNameFontSize type: ${type}`);
    if (type !== SplitScreenType.DEFAULT) {
      if (this.isPhone()) {
        return '30vp';
      }
    }
    return '';
  }

  isPhoneSpliteScreen(type: SplitScreenType): boolean {
    LogUtils.i(TAG, `isPhoneSpliteScreen type: ${type}`);
    if (type === SplitScreenType.DEFAULT) {
      return false;
    }
    if (this.isTablet() || this.isTwoInOne()) {
      return false;
    }
    return true;
  }

  getCommonCallCardHeightPercent(): number {
    return 30;
  }

  public getVoiceBottomHeightScale(type: SplitScreenType): number {
    if (this.isPhoneSpliteScreenBig(type)) {
      return (100 - this.getCommonCallCardHeightPercent()) / 100;
    }
    return 0;
  }

  public getCallColumnRowsGap(splitType: SplitScreenType): number {
    if (this.isTablet() && (splitType === SplitScreenType.BIG || splitType === SplitScreenType.MEDIUM)) {
      return 31;
    }
    if (this.isPhone() && splitType === SplitScreenType.BIG) {
      return 17;
    }
    return 0;
  }

  public getCallBottomSpaceHeight(type: SplitScreenType, bottomSpaceHeight: number): number {
    if (this.isPhoneSpliteScreen(type)) {
      return 24;
    } else {
      return bottomSpaceHeight;
    }
  }

  getCallFuncRowsGap(appHeight: number, btnHeight: number, bottomSpaceHeight: number): number {
    let splitType = this.getSplitScreenType();
    let initRowsGap = this.getCallColumnRowsGap(splitType);
    let funcTextHeight = 24;
    let bottomHeight = this.getCallBottomSpaceHeight(splitType, bottomSpaceHeight);
    let scale = this.getVoiceBottomHeightScale(splitType);
    if (scale > 0) {
      let rowsGap = (appHeight * scale - bottomHeight - btnHeight * 3 - funcTextHeight * 2) / 2;
      if (rowsGap > initRowsGap) {
        rowsGap = initRowsGap;
      }
      return rowsGap;
    }
    return 0;
  }

  getCallFuncHeight(appHeight: number, btnHeight: number, bottomSpaceHeight: number, rowGap: number): number {
    LogUtils.i(TAG, `getCallFuncContentHeight appHeight: ${appHeight} rowGap${rowGap}`);
    let splitType = this.getSplitScreenType();
    let scale = this.getVoiceBottomHeightScale(splitType);
    let bottomHeight = this.getCallBottomSpaceHeight(splitType, bottomSpaceHeight);
    if (scale > 0) {
      let height = appHeight * scale - bottomHeight - rowGap - btnHeight;
      return height;
    }
    return 0;
  }

  getMultiCardIncomingTextTop(type: SplitScreenType) {
    LogUtils.i(TAG, `getMultiCardIncomingTextTop type: ${type}`);
    if (this.isPhone()) {
      if (type === SplitScreenType.SMALL) {
        if (ScreenAdapterUtils.isNewFoldPhone && !this.isLandscape()) {
          return 0;
        }
        return 4;
      }
      if (type === SplitScreenType.MEDIUM || type === SplitScreenType.BIG) {
        if (ScreenAdapterUtils.isNewFoldPhone && !this.isLandscape()) {
          return 16;
        }
        return 22;
      }
    }
    if (this.isTablet()) {
      if (type === SplitScreenType.SMALL) {
        return 28;
      }
      if (type === SplitScreenType.MEDIUM) {
        return 69;
      }
      if (type === SplitScreenType.BIG) {
        return 123;
      }
    }
    return 56;
  }

  isStrangeNumberMarkButtonOneLine(type: SplitScreenType): boolean {
    LogUtils.i(TAG, `isStrangeNumberMarkButtonOneLine type: ${type}`);
    if (this.isPhone() &&
      (type === SplitScreenType.SMALL || type === SplitScreenType.MEDIUM)) {
      return true;
    } else if (this.isTablet() && type === SplitScreenType.SMALL) {
      return true;
    } else {
      return false;
    }
  }

  getStrangeNumberMarkButtonRowsGap(type: SplitScreenType): number {
    LogUtils.i(TAG, `getStrangeNumberMarkButtonRowsGap type: ${type}`);
    if (this.isPhone() &&
      (type === SplitScreenType.SMALL || type === SplitScreenType.MEDIUM)) {
      return 4;
    } else if (this.isTablet() && type === SplitScreenType.SMALL) {
      return 4;
    } else {
      return 32;
    }
  }

  isNewFoldSplitPortraitScreenType() {
    return (AppStorage.get<SplitScreenType>('newFoldSplitPortraitScreenType') ?? SplitScreenType.DEFAULT) >
    SplitScreenType.DEFAULT;
  }

  isFoldStatus() {
    let foldStatus: number = AppStorage.get('FoldStatus') ?? FoldStatus.FOLD_STATUS_EXPANDED;
    let isFold = foldStatus === FoldStatus.FOLD_STATUS_FOLDED;
    LogUtils.i(TAG, `isFlodStatus ${foldStatus}`);
    return isFold;
  }

  getMultiContactCardTop(callList: Array<DefaultCallData>, type: SplitScreenType): string {
    LogUtils.i(TAG, `getMultiContactCardTop type: ${type}`)
    if (this.callListShow(callList, type) === Visibility.None) {
      return '0vp';
    }
    if (this.isPhone()) {
      if (type === SplitScreenType.SMALL) {
        return '0vp';
      }
      if (type === SplitScreenType.MEDIUM) {
        if (this.isTwoCallIncoming(callList, type)) {
          return '0vp';
        }
        if (this.isNewFoldSplitPortraitScreenType()) {
          return '16vp';
        }
        return '22vp';
      }
      if (type === SplitScreenType.BIG) {
        if (this.isNewFoldSplitPortraitScreenType()) {
          return '16vp';
        }
        return '22vp';
      }
    }
    if (this.isTablet()) {
      if (type === SplitScreenType.SMALL) {
        return '24vp';
      }
    }
    return '56vp';
  }

  getVideoFuncBtnRowsGap(type: SplitScreenType): number {
    LogUtils.i(TAG, `getVideoFuncBtnRowsGap type: ${type}`);
    if (this.isPhoneVideoSplitScreenSmall(type)) {
      return 4;
    }
    return 0;
  }

  getAutoNickFontSize(): string {
    LogUtils.i(TAG, `getAutoNickFontSize`);
    let splitType = this.getSplitScreenType();
    let fontSize = this.getDisplayNameFontSize(splitType);
    if (fontSize.length > 0) {
      return fontSize;
    }
    return fontSize;
  }

  getContactCardTop(height: number) {
    LogUtils.i(TAG, `getContactCardTop type: ${height}`);
    let type = this.getSplitScreenType();
    if (this.isPhone()) {
      // 新折叠联系人卡片紧贴顶部栏
      if (type !== SplitScreenType.DEFAULT && ScreenAdapterUtils.isNewFoldPhone && !this.isLandscape()) {
        return 0;
      }
      if (type === SplitScreenType.SMALL) {
        return 0;
      }
      let isFoldableLand = this.isIncomingSpliteScreenMedium(height);
      if (!isFoldableLand &&
        (type === SplitScreenType.MEDIUM || type === SplitScreenType.BIG)) {
        return 22;
      }
    }
    return -1;
  }

  isContactCardTop(height: number): boolean {
    LogUtils.i(TAG, `isContactCardTop type: ${height}`);
    if (this.getContactCardTop(height) >= 0) {
      return true
    }
    return false;
  }

  isFoldableLandscapeMedum(height: number): boolean {
    let type = this.getSplitScreenType();
    if (DisplayUtil.isFoldable() && this.isLandscape() && type === SplitScreenType.MEDIUM) {
      return true;
    }
    return false
  }

  isSpliteCallHeightPercent(height: number, isNumberMark: boolean): boolean {
    let type = this.getSplitScreenType();
    if (isNumberMark && DisplayUtil.isFoldable() && this.isLandscape() && type === SplitScreenType.MEDIUM) {
      return true;
    } else if (this.isPhoneSpliteScreenBig(type)) {
      return true;
    } else {
      return false;
    }
  }
}
