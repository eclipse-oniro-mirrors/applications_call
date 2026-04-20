/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import DefaultCallData from '../common/struct/TypeUtils';
import LogUtils from '../common/utils/LogUtils';
import * as Constants from '../common/utils/Constants';
import {
  getPrimaryIncomingCall,
  isDisconnectCall,
  isIncomingCall,
  isSilencedCall,
  isVideoCall
} from '../common/utils/CallListHelper';
import IncomingComVM from '../viewmodel/IncomingComVM';
import CallUtils from '../common/utils/CallUtils';
import CallServiceProxy from './CallServiceProxy';
import { ExternalIconResource, IconTypes } from './ExternalResourceManager';
import BottomViewModel from '../viewmodel/BottomViewModel';
import * as DeviceTypeConst from '../common/constant/DeviceTypeConst';
import CallManagerService from '../ServiceAbility/CallManagerService';
import CallDataManager from './CallDataManager';
import AudioDeviceManager from './audio/AudioDeviceManager';
import display from '@ohos.display';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { power } from '@kit.BasicServicesKit';
import settings from '@ohos.settings';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import { common } from '@kit.AbilityKit';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import Utils from '../common/utils/utils';
import ScreenAdapterUtils, { FoldPhoneTypeValue } from '../common/utils/ScreenAdapterUtils';
import { ProximityUtils } from '../common/utils/ProximityUtils';
import { window } from '@kit.ArkUI';

const TAG = 'ExternalCallModel';

export class ExternalCallModel {
  private static sExternalCallModel: ExternalCallModel;
  public static sIsPsd: boolean = ExternalCallModel.getProductType() === 'PSD';
  private mVideoTipsDialog?: CustomDialogController;
  private mIsListenFoldStatus: boolean = false;
  private mIsSmallExternalDevice: boolean = ExternalCallModel.isSmallExternalDevice();
  private mCurFoldStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  private mLastAnsweredCallId: number = Constants.INVALID_NUM;
  private mExternalWindowObj: window.Window | undefined = undefined;
  public mIsExternalBackground: boolean = true;

  /**
   * Get ExternalCallModel object
   *
   * @return { Object } ExternalCallModel
   */
  public static getInstance(): ExternalCallModel {
    if (!ExternalCallModel.sExternalCallModel) {
      ExternalCallModel.sExternalCallModel = new ExternalCallModel();
    }
    return ExternalCallModel.sExternalCallModel;
  }

  /**
   * When press external left button
   */
  public static onLeftMethod() {
    ExternalCallModel.doOperation(AppStorage.get(Constants.EXTERNAL_LEFT_ICON) as ExternalIconResource);
  }

  /**
   * When press external right button
   */
  public static onRightMethod() {
    ExternalCallModel.doOperation(AppStorage.get(Constants.EXTERNAL_RIGHT_ICON) as ExternalIconResource);
  }

  /**
   * When press external bottom button
   */
  public static onBottomMethod() {
    ExternalCallModel.doOperation(AppStorage.get(Constants.EXTERNAL_BOTTOM_ICON) as ExternalIconResource);
  }

  private static doOperation(iconRes: ExternalIconResource) {
    let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
    switch (iconRes.id) {
      case IconTypes.MUTE_RINGER:
        CallUtils.muteRinger(isIncomingCall(callData.callState));
        break;
      case IconTypes.REJECT:
        IncomingComVM.getInstance()?.onReject();
        ReportUtil.getInstance().reportExternalIncomingClickReject();
        break;
      case IconTypes.HANGUP:
        BottomViewModel.getInstance().hangUpCall(callData.callId, CallDataManager.getInstance().callList.length);
        CallUtils.reportHangupCount();
        ReportUtil.getInstance().reportHangupExternal();
        break;
      case IconTypes.CS_ANSWER:
        IncomingComVM.getInstance()?.onAnswer(false);
        ExternalCallModel.getInstance().onAnswered(Constants.ANSWERED_TYPE_VOICE, callData.callId);
        break;
      case IconTypes.VIDEO_ANSWER:
        IncomingComVM.getInstance()?.onAnswer(true);
        ExternalCallModel.getInstance().onAnswered(Constants.ANSWERED_TYPE_VIDEO, callData.callId);
        break;
      case IconTypes.SET_MUTE_WHITE:
        CallServiceProxy.getInstance()?.setMuted();
        break;
      case IconTypes.CANCEL_MUTE_WHITE:
        CallServiceProxy.getInstance()?.cancelMuted();
        break;
      default:
        LogUtils.e(TAG, 'doOperation invalid method : ' + iconRes.id);
    }
  }

  /**
   * When press audio button
   *
   * @param audioDeviceController
   * @param expandDialogController
   * @param hasMultiDevice
   */
  public static handleAudioPressed(audioDeviceController: CustomDialogController,
    expandDialogController: CustomDialogController, hasMultiDevice: boolean): void {
    if (hasMultiDevice) {
      audioDeviceController.open();
    } else {
      expandDialogController.open();
    }
  }

  /**
   * Check whether have conference call
   */
  public static checkConferenceCall(): boolean {
    let callList = CallDataManager.getInstance().callList;
    if (callList.length <= 1) {
      return false;
    }
    for (let i = 0; i < callList.length; i++) {
      let curCallData = callList[i];
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Set video tips dialog object
   */
  public setVideoTipsDialog(videoTipsDialog: CustomDialogController): void {
    LogUtils.i(TAG, 'setVideoTipsDialog');
    this.mVideoTipsDialog = videoTipsDialog;
  }

  /**
   * Show video tips dialog
   */
  public showVideoTipsDialog(): void {
    let isHaveExternalAudioDevice = AudioDeviceManager.getInstance().isExternalAudioDeviceSupport();
    let isSpeaker = AudioDeviceManager.getInstance().isCurSpeaker();
    if (!isHaveExternalAudioDevice && !isSpeaker) {
      LogUtils.i(TAG, 'showVideoTipsDialog not show for not speaker');
      return;
    }
    if (!this.isSmallExternalAndFolded()) {
      LogUtils.i(TAG, 'showVideoTipsDialog not show for unfold');
      return;
    }
    let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
    if (!callData || isDisconnectCall(callData) || isIncomingCall(callData.callState)) {
      LogUtils.i(TAG, 'showVideoTipsDialog not show for invalid call');
      return;
    }
    LogUtils.i(TAG, 'showVideoTipsDialog');
    if (isVideoCall(callData.videoState)) {
      LogUtils.i(TAG, 'showVideoTipsDialog start');
      this.mVideoTipsDialog?.open();
    }
  }

  /**
   * When answer the call on external screen
   *
   * @param answeredType
   * @param answeredCallId
   */
  public onAnswered(answeredType: string, answeredCallId: number): void {
    LogUtils.i(TAG, `onAnswered answeredType:${answeredType}`);
    let isSuperPrivacy: boolean | undefined = AppStorage.get('isSuperPrivacy');
    if (answeredType === Constants.ANSWERED_TYPE_VIDEO && !isSuperPrivacy) {
      this.mVideoTipsDialog?.open();
    } else if (answeredType === Constants.ANSWERED_TYPE_VOICE) {
      this.checkAndOpenSpeaker(true);
    }
    this.mLastAnsweredCallId = answeredCallId;
    ReportUtil.getInstance().reportExternalIncomingCallAccept();
  }

  /**
   * Register fold status change
   */
  public registerFoldStatusChange(): void {
    if (this.mIsListenFoldStatus) {
      LogUtils.i(TAG, 'is already registered');
      return;
    }
    LogUtils.i(TAG, `registerFoldStatusChange isSmallExternalDevice:${this.mIsSmallExternalDevice}`);
    if (!this.mIsSmallExternalDevice) {
      return;
    }
    this.mIsListenFoldStatus = true;

    try {
      this.refreshFoldStatus(display.getFoldStatus());
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        this.onFoldStatusChanged(foldStatus);
      })
    } catch (error) {
      LogUtils.e(TAG, `listen foldStatusChange error:${JSON.stringify(error)}`);
    }
  }

  private refreshFoldStatus(foldState: display.FoldStatus): void {
    LogUtils.i(TAG, `refreshFoldStatus:${foldState}`);
    if (foldState !== display.FoldStatus.FOLD_STATUS_UNKNOWN) {
      this.mCurFoldStatus = foldState;
    }
  }

  /**
   * On fold status change
   */
  public onFoldStatusChanged(newFoldState: display.FoldStatus): void {
    let lastFoldStatus = this.mCurFoldStatus;
    LogUtils.i(TAG, `onFoldStatusChanged newStatus:${newFoldState} lastFoldStatus:${lastFoldStatus}`);
    if (lastFoldStatus === newFoldState) {
      return;
    }

    this.refreshFoldStatus(newFoldState);
    if (lastFoldStatus === display.FoldStatus.FOLD_STATUS_UNKNOWN) {
      LogUtils.i(TAG, 'first time get fold status, in fact not change fold status');
      return;
    }

    ProximityUtils.updateProximityLock();
    if (newFoldState === display.FoldStatus.FOLD_STATUS_FOLDED) {
      CallDataManager.getInstance().callList.forEach((callData) => {
        LogUtils.i(TAG, `FOLD_STATUS_FOLDED callId:${callData.callId} type:${callData.callType}`);
        if (isDisconnectCall(callData)) {
          return;
        }
        if (isIncomingCall(callData.callState, false)) {
          CallUtils.muteRinger(true);
          CallManagerService.getInstance().startExternalAbility();
          return;
        }
        if (AudioDeviceManager.getInstance().isCurEarpiece()) {
          BottomViewModel.getInstance().hangUpCall(callData.callId, CallDataManager.getInstance().callList.length);
        } else {
          CallManagerService.getInstance().startExternalAbility();
        }
      });
    } else if (lastFoldStatus == display.FoldStatus.FOLD_STATUS_FOLDED &&
      (newFoldState == display.FoldStatus.FOLD_STATUS_EXPANDED ||
        newFoldState == display.FoldStatus.FOLD_STATUS_HALF_FOLDED)) {
      this.minimizeExternalWindow();
      let callData = getPrimaryIncomingCall(CallDataManager.getInstance().callList);
      if (!callData) {
        return;
      }
      AppStorage.setOrCreate('foldStatus', newFoldState);
      let isVoiceCall: boolean = !isVideoCall(callData.videoState);
      if (this.isOpenToAnswerModeOn() && isVoiceCall && !isSilencedCall(callData)) {
        LogUtils.i(TAG, `onFoldStatusChanged auto answer`);
        IncomingComVM.getInstance().onAnswer(false);
      }
    }
  }

  public setExternalWindow(externalWindow?: window.Window): void {
    this.mExternalWindowObj = externalWindow;
  }

  private async minimizeExternalWindow(): Promise<void> {
    if (this.mIsSmallExternalDevice) {
      try {
        await this.mExternalWindowObj?.minimize();
      } catch (err) {
        LogUtils.e(TAG, `minimize externalwindow err:${err?.code} ${err?.message}`);
      }
    }
  }

  /**
   * Unregister fold status change
   */
  public unRegisterFoldStatusChange(): void {
    if (this.mIsListenFoldStatus) {
      try {
        display.off('foldStatusChange');
        this.mIsListenFoldStatus = false;
        AppStorage.delete('foldStatus');
      } catch (exception) {
        LogUtils.e(TAG, `unRegisterFoldStatusChange error:${JSON.stringify(exception)}`);
      }
    }
  }

  /**
   * Check and open speaker
   *
   * @param isFromExternalAnswerBtn
   */
  public checkAndOpenSpeaker(isFromExternalAnswerBtn?: boolean): void {
    LogUtils.i(TAG, `checkAndOpenSpeaker isFromExternalAnswerBtn:${isFromExternalAnswerBtn}`);
    if (!isFromExternalAnswerBtn &&
      this.mLastAnsweredCallId !== AppStorage.get<DefaultCallData>(Constants.CALL_DATA)?.callId) {
      LogUtils.i(TAG, 'checkAndOpenSpeaker no need open speaker');
      return;
    }
    if (AudioDeviceManager.getInstance().isCurEarpiece() && this.isSmallExternalAndFolded()) {
      LogUtils.i(TAG, `checkAndOpenSpeaker setAudioDeviceSpeaker DEVICE_SPEAKER`);
      BottomViewModel.getInstance().setAudioDeviceSpeaker(DeviceTypeConst.DEVICE_SPEAKER);
    }
  }

  /**
   * Is small external phone and folded
   *
   * @returns { boolean } isSmallExternalDevice && isFolded
   */
  public isSmallExternalAndFolded(): boolean {
    return this.mIsSmallExternalDevice && this.isFolded();
  }

  private isFolded(): boolean {
    LogUtils.i(TAG, `isFolded mCurFoldStatus:${this.mCurFoldStatus}`);
    return this.mCurFoldStatus === display.FoldStatus.FOLD_STATUS_FOLDED;
  }

  /**
   * Check whether the device is small external device like LEM
   *
   * @returns { boolean } true means the device is external fold device like LEM.
   */
  public static isSmallExternalDevice(): boolean {
    return ScreenAdapterUtils.getFoldablePhoneProductType() === FoldPhoneTypeValue.SMALL_FOLD;
  }

  private isOpenToAnswerModeOn(): boolean {
    return this.mIsSmallExternalDevice && this.queryStatus();
  }

  private queryStatus(): boolean {
    const VALUE_ON = '1';
    try {
      let ctx = GlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT);
      let result = settings.getValueSync(ctx, 'open_phone_to_answer', '1', settings.domainName.USER_PROPERTY);
      LogUtils.i(TAG, `queryStatus result: ${result}`);
      return result === VALUE_ON;
    } catch (err) {
      LogUtils.e(TAG, `queryCallNotifiesType fail, err: ${JSON.stringify(err)}`);
      return true;
    }
  }

  /**
   * On external ability destroy
   */
  public onExternalAbilityDestroy(): void {
    if (this.isSmallExternalAndFolded()) {
      try {
        power.wakeup('wakeup_test');
      } catch (err) {
        LogUtils.e(TAG, 'wakeup failed, err: ' + JSON.stringify(err));
      }
    }
  }

  public static getProductType(): string {
    let prodType = '';
    try {
      prodType = systemParameterEnhance.getSync(Constants.PRODUCT_TYPE_KEY, '');
    } catch (err) {
      LogUtils.e(TAG, `get ${Constants.PRODUCT_TYPE_KEY} err:${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, `getProductType : ` + prodType);
    return prodType;
  }
}