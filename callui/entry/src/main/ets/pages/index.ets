/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import lazy { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import FuncBtnGroup from '../common/components/FuncBtnGroup';
import BottomBtn from '../common/components/BottomBtn';
import Keyboard from '../common/components/Keyboard';
import IncomingCom from '../common/components/IncomingCom';
import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import * as Constants from '../common/utils/Constants';
import CallDataManager from '../model/CallDataManager';
import CallCard from '../common/components/CallCard';
import DefaultCallData, {
  AppBtnStyleData,
  AppWindowStyleData,
  callDataToSafeString
} from '../common/struct/TypeUtils';
import CallTimeListStruct from '../common/struct/CallTimeListStruct';
import BottomViewModel from '../viewmodel/BottomViewModel';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { postDialProceed, registerPostDialDelayCallback, unRegisterPostDialDelay } from '../presenter/DtmfPresenter';
import curves from '@ohos.curves';
import common from '@ohos.app.ability.common';
import IncomingAnimation from '../common/animation/IncomingAnimation';
import lazy { LockIncomingAnimation } from '../common/animation/LockIncomingAnimation';
import CallUtils from '../common/utils/CallUtils';
import lazy { ConferenceDetail } from '../common/components/ConferenceDetail';
import call from '@ohos.telephony.call';
import emitter from '@ohos.events.emitter';
import { isTablet, isTwoInOne } from '../common/utils/DeviceTypeUtils';
import BannerNotificationManager from '../model/BannerNotificationManager';
import RbtRingToneXComponent from '../common/components/RbtRingToneXComponent';
import lazy { VideoXComponent } from '../common/components/VideoXComponent';
import lazy { ImsCallMode, VideoStateType } from '../common/utils/VideoCallApi';
import {
  canShowVideoCallUi,
  getVideoRingPath,
  isIncomingCall,
  isSameAccountId,
  isVideoCall,
  setSystemBarEnable,
  setWindowLayoutFullScreenApi,
  shouldShowRbtView,
  shouldShowVideoRing
} from '../common/utils/CallListHelper';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import VideoCallManager from '../model/VideoCallManager';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { ScreenInfo } from '../common/struct/CallUiDataStruct';
import { CallFaultEventUtil } from '../common/utils/ReportUtils/CallFaultEventUtil';
import lazy { StrangeNumberHandlerPanel } from '../common/components/StrangeNumberHandlerPanel';
import lazy { NumberMarkManager } from '../model/NumberMarkService';
import Utils from '../common/utils/utils';
import lazy { VoiceControlTip } from '../common/components/VoiceControlTip';
import { startBackgroundRunning, stopBackgroundRunning } from '../model/BackgoundTask';
import SplitScreenManager, { SplitScreenType } from '../model/SplitScreenManager';
import { TimeOutManager } from '../model/TimeOutManager';
import { WallpaperHelper } from '../common/utils/WallpaperHelper';
import { BehaviorDotting } from '../common/utils/ReportUtils/BehaviorDotting';
import { AttributeUpdater } from '@ohos.arkui.modifier';
import { CALL_RISK_DETECTED} from '../common/utils/Constants';
import { ProximityUtils } from '../common/utils/ProximityUtils';
import { uiEffect, displaySync, effectKit } from '@kit.ArkGraphics2D';
import AudioDeviceManager from '../model/audio/AudioDeviceManager';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { aVPlayerStatePlaying, VideoController } from '../controller/VideoController';
import { SystemMode } from '../common/utils/SystemMode';
import { componentUtils, display, window, promptAction } from '@kit.ArkUI';
import lazy { LevelMode } from '@kit.ArkUI';
import EmptyWindowForDialog from '../common/utils/EmptyWindowForDialog';
import { createSubscriber, subscribeEvent, unSubscribeEvent } from '../common/utils/CommonEventUtils';
import { commonEventManager } from '@kit.BasicServicesKit';
import { EVENT_SATELLITE_CALL_HANGUP } from '../common/constant/CallSettingConst';
import { DisplayMode } from '../common/utils/ReportUtils/DisplayMode';
import { VirtualScreenBlockManager } from '../model/VirtualScreenBlockManager';
import { BusinessError } from '@ohos.base';
import Recording from '../common/utils/Recording';
import { isNeedNotePadRestore, NOTEPAD_DISABLE_NOT_SUMMARY } from '../common/utils/CheckRestoresUtils';
import { hiSysEvent } from '@kit.PerformanceAnalysisKit';

const TAG = 'CallUIMainIndex';
const DEFAULT_CALL_STATUS: number = -1;
const WATTER_RIPPLE_FADEOUT_COUNT: number = 3;
const FOLD_DISPLAY_MODE_ALL_EXPANDED: number = 5;
const FIRST_AGREE_POLICY = 'INTELLIGENT_AGREE_POLICY';

class ImageModifier extends AttributeUpdater<ImageAttribute, ImageInterface> {
  initializeModifier(instance: ImageAttribute): void {
  }
}

/**
 * @file: Main interface
 */
@Entry
@Component
struct Index {
  modifier: ImageModifier = new ImageModifier()
  @State @Watch('getBtnCallState') callData: DefaultCallData = new DefaultCallData();
  @StorageLink('isShowVideoKeyBoard') @Watch('isShowKeyboardChange') isShowKeyboard: boolean = false;
  @StorageLink('surfaceId') @Watch('surfaceIdChange') surfaceId: string = '';
  @StorageLink('isRbtError') @Watch('isRbtChange') isRbtError: boolean = false;
  @State @Watch('getCallCount') callList: Array<DefaultCallData> = [];
  @State callTimeList: Array<CallTimeListStruct> = [];
  private mCallDataManager?: CallDataManager;
  @StorageProp('curBp') @Watch('updateCurBp') curBp: string = '';
  @State hasMultiDevice: boolean = false;
  @StorageLink('hangUp') mHangup: boolean = false;
  @StorageLink('onAnswer') isAnswer: boolean = false;
  @StorageLink('lockAnswerOn') lockAnswerOn: boolean = false;
  @StorageLink(Constants.STRANGE_NUMBER_CALL_DATA) strangeNumberCallData: DefaultCallData | null = null;
  @StorageLink('callEventChange') @Watch('initEventChangeAction')
  callEventChange: number = Constants.EVENT_DEFAULT_CALL_FAILED;
  @State callListCount: number = 0;
  @State hasConference: boolean = false;
  @State showConferenceDetail: boolean = false;
  @State translateName: string = '0';
  @State translateTime: string = '0';
  @State contactAppear: boolean = true;
  @State funcBtnAppear: boolean = true;
  @State incomingFuncBtnAppear: boolean = true;
  @State wallpaperBg: PixelMap | undefined = undefined;
  @State satelliteWallpaperBg: Resource = $r('app.media.satellite_wallpaper');
  @State isIncomingState: boolean = false;
  private mBottomVM: BottomViewModel = BottomViewModel.getInstance();
  private postDialStr: string = '';
  private oldLength: number = 0;
  private callStateOffset: number = 21; // call state offset
  private keyBoradOrFuncBtnBottomSpace: number = 35;
  @State onPageShowTimes: boolean = false;
  @State isShowSmallScreen: boolean = true;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('navigationHeight') navigationHeight: number = 0;
  @StorageLink('navigationHeight') airbarHeight: number = 0;
  @State showRbtView: boolean = false;
  @StorageProp('acceptVideoCallDialog') @Watch('voiceToVideoDialogChange') acceptVideoCallDialog: boolean = false;
  @Provide lightUpdate: boolean = true;
  @Provide foldChange: boolean = false;
  @Provide isConferenceMode: boolean = false;
  @Provide screenreaderStatus: boolean = false;
  @StorageLink('windowSizeChangeMd') @Watch('windowSizeChange') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @StorageLink('LandscapeOrPortrait') @Watch('getWallpaper') landscapeOrPortrait: number = 1;
  @StorageLink('FoldStatus') @Watch('getWallpaper') @Watch('refreshVideoSize') foldStatus: number = 0;
  @StorageLink('isShowSmartWindow') isShowSmartWindow: boolean = false;
  @StorageLink('isSmartWindowSplitScreen') isSmartWindowSplitScreen: boolean = false;
  @State landScapeKeyBoardHeight: number = 0;
  private primaryTitle: ResourceStr = '';
  public message: ResourceStr = '';
  @State isPanelShown: boolean = true;
  @State panelHiddenTimer: number = -1;
  @Provide lightClipState: boolean = true;
  @State isSmartWindowAndFoldableStatus: Boolean = false;
  @State callType: number = -1;
  @Provide callId: number = -1;
  @State accountId: number = -1;
  @State videoRingPath: string = '';
  @State contactAvatar?: PixelMap | null = null;
  @State @Watch('stopVideoPlayByState') callState: number = -1;
  @State videoState: number = -1;
  @State isHoldVideoUx?: boolean = false;
  @State isVoiceMailNumber?: boolean = false;
  @State uiAlpha: number = Constants.ALPHA_NO;
  private curStatusTimeId: number = -1;
  private refreshUIExTimeId: number = -1;
  @StorageLink(Constants.VOICE_CONTROL_SWITCH) voiceControlSwitch: boolean = false;
  @StorageLink('SplitScreenType') @Watch('changeSplitScreenType') splitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @StorageLink('isNewFoldPhoneExternalScreen') @Watch('onFoldStatusChange') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('SplitScreenHeight') splitHeight: number = 0;
  @StorageLink('isNewFoldPhoneInnerFullScreen') isNewFoldPhoneInnerFullScreen: boolean = false;
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @State timeOutManager: TimeOutManager = TimeOutManager.getInstance();

  private xComponentController: XComponentController = new XComponentController();
  private playVideoModel?: VideoController = VideoController.getInstance();
  private videoSurfaceID: string = '';
  private sizeUpdateCallback: Function | undefined;
  private videoSize: ScreenInfo = {
    width: 0,
    height: 0
  }
  @State showVideoComponent: boolean = false;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('appWindow') appWindow: AppWindowStyleData = {
    maxWidth: undefined,
    maxHeight: undefined
  };
  @StorageLink('appBtnStyle') appBtnStyle: AppBtnStyleData = {
    btnWidth: 64,
    rowsGap: 20
  };
  @StorageLink('btnBottomGap') btnBottomGap: number = 0;
  private splitManager = SplitScreenManager.getInstance();
  private postDialDelayCallBack = (data: string | null) => {
    if (data) {
      this.postDialStr = data;
      this.openDTMFDialog?.open();
    }
  }
  @StorageLink('isPickup') @Watch('isPickupChange') isPickup: boolean = false;
  @StorageLink('screenOff') @Watch('isScreenOffChange') screenOff: boolean = false;
  private satelliteCallHangupEvent?: commonEventManager.CommonEventSubscriber;
  private powerSaveEvent?: commonEventManager.CommonEventSubscriber;
  private updateCurBp() {
    this.foldChange = true;
  }

  private displaySyncObj: displaySync.DisplaySync = displaySync.create();
  private filter: uiEffect.Filter = uiEffect.createFilter();
  private callActiveWaterRippleDisappearTimer: number = -1;
  private callActiveNotShowWaterRipple: boolean = false;
  private waterRippleShowDelayTimer: number = -1;
  private waterRippleFadeoutCount: number = 0;
  private showDelayTimerActive: boolean = true;
  private callback = (isCurEarpiece: boolean) => {
    this.isEarpiece = isCurEarpiece;
  };
  private range: ExpectedFrameRateRange = {
    min: 25,
    max: 30,
    expected: 30
  };
  private waterRippleMin: number = 0.1;
  private waterRippleMax: number = 0.8;
  private waterRippleStep: number = 0.007;
  private newcallData: DefaultCallData = new DefaultCallData();
  private proxyComponent: UIExtensionProxy | null = null;
  private assistantStartTime: number = 0;
  @State isEarpiece: boolean = AudioDeviceManager.getInstance().isCurEarpiece();
  @State isShowWaterRipple: boolean = false;
  @State waterRippleProgress: number = this.waterRippleMin;
  @StorageLink('assistantAlarmShowType') assistantAlarmShowType: number = DEFAULT_CALL_STATUS;
  @State isSummaryAlarmShow: boolean = false;
  @State largestColor: Color | string = Color.Black;
  @StorageLink('isAddVirtualScreenBlocklist')
  @Watch('addVirtualScreenBlockList') isAddVirtualScreenBlocklist: boolean = true;

  private setSafeWaterRipple(value: boolean) {
    if (!this.showDelayTimerActive && this.isShowWaterRipple != value) {
      this.isShowWaterRipple = value
      LogUtils.i(TAG, 'setSafeWaterRipple ' + this.isShowWaterRipple);
    }
  }

  isShowKeyboardChange() {
    LogUtils.i(TAG, `check is show keyboard`);
    const scale: number = vp2px(1);
    if (!this.hasConference || this.callList.length === 1) {
      const translateY: string = (0 - scale * this.callStateOffset) + 'px';
      this.translateTime = this.isShowKeyboard ? isTablet() ? '-40px' : translateY : '0';
    }
  }

  private addVirtualScreenBlockList() {
    LogUtils.i(TAG, `isAddVirtualScreenBlocklist:${this.isAddVirtualScreenBlocklist}`);
    try {
      let windowObj =
        (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync();
      if (this.isAddVirtualScreenBlocklist) {
        VirtualScreenBlockManager.getInstance().addVirtualScreenBlocklist(windowObj);
      } else {
        VirtualScreenBlockManager.getInstance().removeVirtualScreenBlocklist(windowObj);
      }
    } catch (err) {
      LogUtils.e(TAG, `isAddVirtualScreenBlocklistChange failed. Code:${err?.code}, message:${err?.message}`);
    }
  }

  isPickupChange() {
    if (this.isPickup) {
      if (this.isNewFoldPhoneExternalScreen && !this.isShowWaterRipple &&
        (this.callData.callState === CallStateConst.CALL_STATUS_ALERTING ||
          this.callData.callState === CallStateConst.CALL_STATUS_INCOMING)) {
        this.waterRippleFadeoutCount = 0;
        this.setSafeWaterRipple(true);
      }
      this.isPickup = false;
    }
  }

  initDisplaySync(): void {
    this.displaySyncObj.setExpectedFrameRateRange(this.range);
    this.displaySyncObj.on('frame', (data) => {
      this.waterRippleProgress += this.waterRippleStep;
      if (!this.canShowWaterRipple()) {
        this.waterRippleProgress = this.waterRippleMin;
        return;
      }
      if (this.waterRippleFadeoutCount === 0 || this.waterRippleProgress > this.waterRippleMax) {
        this.waterRippleProgress = this.waterRippleMin;
        this.waterRippleFadeoutCount ++;
      }
      if (this.waterRippleFadeoutCount > WATTER_RIPPLE_FADEOUT_COUNT) {
        this.setSafeWaterRipple(false);
      }
    });
    this.displaySyncObj.start();
  }

  isScreenOffChange() {
    LogUtils.i(TAG, 'screen off ' + this.screenOff);
    if (this.screenOff) {
      this.setSafeWaterRipple(false);
    } else {
      this.setShowWaterRipple();
    }
  }

    acceptVideoCallDialogController?: CustomDialogController | undefined = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.voiceToVideoConfirmMsg'),
      primaryButton: {
        value: $r('app.string.rejectVideo'),
        action: () => {
          VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_AUDIO_ONLY,
            updatedCall => {
              // Clear the imsCallMode manually if we rejected the upgrade request.
              // Tele will not notify this state again because the state is not changed.
              updatedCall.imsCallMode = ImsCallMode.CALL_MODE_AUDIO_ONLY;
            });
          LogUtils.i(TAG, `video call reject`);
          AppStorage.setOrCreate('acceptVideoCallDialog', false);
        }
      },
      secondaryButton: {
        value: $r('app.string.accept'),
        fontColor: SystemMode.getInstance().isModePenglai() ? $r('sys.color.font_on_tertiary') :
        $r('sys.color.ohos_id_text_color_active'),
        action: () => {
          if (SystemMode.getInstance().isModePenglai()) {
            try {
              promptAction.showToast({
                message: $r('app.string.not_support_toast'),
                duration: 2000
              });
            } catch (e) {
              LogUtils.e(TAG, 'showToast error' + e.message);
            }
            VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_AUDIO_ONLY,
              updatedCall => {
                updatedCall.imsCallMode = ImsCallMode.CALL_MODE_AUDIO_ONLY;
              });
            LogUtils.i(TAG, `video call accept pl`);
            AppStorage.setOrCreate('acceptVideoCallDialog', false);
            return
          }
          VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_SEND_RECEIVE,
            updatedCall => {
              // Set the videoState to TYPE_VIDEO_BIDIRECTIONAL to get a better performance
              updatedCall.videoState = VideoStateType.TYPE_VIDEO_BIDIRECTIONAL;
            });
          LogUtils.i(TAG, `video call accept`);
          AppStorage.setOrCreate('acceptVideoCallDialog', false);
          BehaviorDotting.getInstance().updatedCallTypeDotting(this.callData, 'inactive');
        }
      }
    }),
    autoCancel: false,
    onWillDismiss: (action: DismissDialogAction) => {
      LogUtils.i(TAG, 'action.reason:' + action.reason);
      if (action.reason === DismissReason.CLOSE_BUTTON) {
        action.dismiss();
      }
    },
      levelMode: LevelMode.EMBEDDED
  });
  openMessageDialog?: CustomDialogController | undefined = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: this.primaryTitle,
      content: this.message,
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          LogUtils.i(TAG, 'AlertDialog combineConference action');
          this.primaryTitle = '';
          this.message = '';
        }
      }
    })
  })

  openDTMFDialog?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog(
      {
        content: $r('app.string.DTMF_DIALOG_INFO', this.postDialStr),
        primaryButton: {
          value: $r('app.string.DTMF_CANCEL'),
          action: () => {
            postDialProceed(this.callId, false);
          }
        },
        secondaryButton: {
          value: $r('app.string.DTMF_CONFIRM'),
          action: () => {
            postDialProceed(this.callId, true);
          }
        },
      }
    )
  })

  aboutToAppear(): void {
    hiTraceMeter.startTrace('aboutToAppear', 1003);
    LogUtils.i(TAG, 'aboutToAppear');
    if (this.isNewFoldPhoneExternalScreen) {
      setWindowLayoutFullScreenApi(true);
      setSystemBarEnable(false);
    }
    BannerNotificationManager.enableBannerNotification(false);
    this.callTimeList = [];
    CallDataManager.getInstance().init(this.callData, this.callList, this.callTimeList);
    this.newcallData = this.callData;
    this.mCallDataManager = CallDataManager.getInstance();
    this.clearDisconnectedCallIfPossible();
    this.hasMultiDevice = this.mBottomVM.getMultiDeviceState();
    this.mBottomVM.addMultiDeviceListener((bol: boolean) => {
      this.hasMultiDevice = bol;
    });
    this.mCallDataManager.addTimeUpdateCallback((callTimeList: CallTimeListStruct[]) => {
      this.callTimeList = callTimeList;
    });
    registerPostDialDelayCallback(this.postDialDelayCallBack);
    this.wallpaperBg = WallpaperHelper.getInstance().getWallpaper();
    emitter.on(Constants.WALLPAPER_EVENT, () => {
      LogUtils.i(TAG,`callui wallpaper: update success`);
      this.wallpaperBg = WallpaperHelper.getInstance().getWallpaper();
      this.setLargestColor();
    })
    emitter.on(Constants.UPDATE_VIDEO_RINGTONE_EVENT, () => {
      LogUtils.i(TAG,`callui video ringtone: update success`);
      this.updateAvPlayerFd();
    })
    if (this.acceptVideoCallDialog) {
      this.voiceToVideoDialogChange();
    }
    // need to hide current banner notification.
    this.updateNotification();
    if (this.callType === CallStateConst.TYPE_SATELLITE) {
      ProximityUtils.keepScreenOn(true);
      if (this.callData.callDirection === CallStateConst.CALL_DIRECTION_OUTGOING) {
        Utils.getInstance().showToast($r('app.string.disableChangedToEarpiece'), 2000);
      }
      this.subscribeCallHangupEvent();
    }

    CallColumnUtils.getInstance().addDensityUpdateObserver(this.getUIContext());
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      this.mBottomVM.addIsCurEarpieceListener(this.callback);
      this.initDisplaySync();
      ProximityUtils.registerAcc();
      ProximityUtils.registerGyr();
    }
    if (this.callData?.callState === CallStateConst.CALL_STATUS_INCOMING) {
      ReportUtil.getInstance().reportIncomingDisplay(DisplayMode.FULLSCREEN, Constants.SUCCESS);
    } else if (this.callData?.callState === CallStateConst.CALL_STATUS_DIALING) {
      ReportUtil.getInstance().reportOutgoingDisplay(DisplayMode.FULLSCREEN, Constants.SUCCESS);
    }
    // bind current js instance
    LogUtils.i(TAG, 'aboutToAppear end');
    hiTraceMeter.finishTrace('aboutToAppear', 1003);
    if (this.isIncomingState && this.callData.videoState === VideoStateType.TYPE_VIDEO_BIDIRECTIONAL &&
    SystemMode.getInstance().isModePenglai()) {
      try {
        promptAction.showToast({
          message: $r('app.string.not_support_toast'),
          duration: 2000
        });
      } catch (e) {
        LogUtils.e(TAG, 'showToast error' + e.message);
      }
    }
    this.addVirtualScreenBlockList();
    this.subscribePowerSaveEvent();
  }

  private setLargestColor() {
    try {
      effectKit.createColorPicker(this.wallpaperBg).then(colorPicker => {
        const color = colorPicker.getLargestProportionColor();
        this.largestColor = `#${this.numberToHex(color.alpha)}${this.numberToHex(color.red)}` +
          `${this.numberToHex(color.green)}${this.numberToHex(color.blue)}`;
      }).catch((reason: BusinessError) => {
        LogUtils.e(TAG, `Error: ${reason?.message}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `createColorPicker fail, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  private numberToHex(colorHex: number): string {
    return colorHex.toString(16).padStart(2, '0');
  }

  refreshingData(): void {
    this.callType = this.callData.callType;
    this.contactAvatar = this.callData.contactAvatar;
    this.callState = this.callData.callState;
    this.videoState = this.callData.videoState;
    this.isHoldVideoUx = this.callData.isHoldVideoUx;
    this.isVoiceMailNumber = this.callData.isVoiceMailNumber;
    this.callId = this.callData.callId;
    this.uiAlpha =
      this.callState === CallStateConst.CALL_STATUS_DISCONNECTED ? Constants.ALPHA_HAVE : Constants.ALPHA_NO;
    if (this.strangeNumberCallData && this.callId !== -1 && this.callId !== this.strangeNumberCallData.callId) {
      NumberMarkManager.getInstance().abortNumberMark('call data updated');
    }
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      this.setShowWaterRipple();
      if (this.callState === CallStateConst.CALL_STATUS_ACTIVE) {
        ProximityUtils.unRegisterAcc();
        ProximityUtils.unRegisterGyr();
        if (this.callActiveWaterRippleDisappearTimer === -1) {
          this.callActiveWaterRippleDisappearTimer = setTimeout(() => {
            this.callActiveNotShowWaterRipple = true;
            this.setSafeWaterRipple(false);
          }, 60000)
          LogUtils.i(TAG, 'one min timer')
        }
      }
    }
  }

  private onFoldStatusChange(): void {
    this.setShowWaterRipple();
    if (this.isNewFoldPhoneExternalScreen) {
      setWindowLayoutFullScreenApi(true);
      setSystemBarEnable(false);
    } else if (canShowVideoCallUi(this.callState, this.videoState, this.isHoldVideoUx)) {
      setWindowLayoutFullScreenApi(true);
      setSystemBarEnable(true);
    } else {
      setWindowLayoutFullScreenApi(false);
      setSystemBarEnable(true);
    }
  }

  // 根据电话状态，判断是否需要停止视频声音
  stopVideoPlayByState() {
    LogUtils.i(TAG, 'stopVideoPlayByState this.callState' + this.callState)
    if (!isIncomingCall(this.callState)) {
      this.playVideoModel!.stopRinging();
    }
  }

  onPageShow() {
    hiTraceMeter.startTrace('onPageShow', 1004);
    LogUtils.i(TAG, 'onPageShow');
    this.lightUpdate = true;
    AppStorage.setOrCreate<boolean>('onPageShow', true);
    this.getWallpaper();
    this.mCallDataManager?.refreshCallTime();
    stopBackgroundRunning();
    BannerNotificationManager.getInstance().setIsStartingAbility(false);
    BannerNotificationManager.getInstance().sendNotification(true);
    if (this.callState === CallStateConst.CALL_STATUS_DIALING) {
      ReportUtil.getInstance().reportPrivacyIndicator();
    }
    CallFaultEventUtil.getInstance().onPageFinishCallEvent();
    if (this.curStatusTimeId !== -1) {
      clearTimeout(this.curStatusTimeId);
    }
    ProximityUtils.updateProximityLock();
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      this.waterRippleShowDelayTimer = setTimeout(() => {
        this.showDelayTimerActive = false;
        this.setShowWaterRipple();
      }, 500)
    }
    LogUtils.i(TAG, 'onPageShow end');
    hiTraceMeter.finishTrace('onPageShow', 1004);
  }

  voiceToVideoDialogChange(): void {
    LogUtils.i(TAG, `voiceToVideoDialogChange acceptVideoCallDialog ${this.acceptVideoCallDialog}`);
    if (this.acceptVideoCallDialog) {
      ProximityUtils.wakeUpScreen(true);
    }
    this.acceptVideoCallDialog ? this.acceptVideoCallDialogController?.open() :
    this.acceptVideoCallDialogController?.close();
  }

  initEventChangeAction() {
    if (this.callEventChange === Constants.EVENT_DEFAULT_CALL_FAILED) {
      return;
    }
    if (this.callEventChange === Constants.EVENT_HOLD_CALL_FAILED ||
      this.callEventChange === Constants.EVENT_SWAP_CALL_FAILED) {
      LogUtils.i(TAG, 'initNotSupportHold, dialog open');
      this.message = $r('app.string.not_support_hold');
      // incoming & active 打点
      ReportUtil.getInstance().reportDualcardHoldFailed();
    } else if (this.callEventChange === call.CallAbilityEventId.EVENT_COMBINE_CALL_FAILED) {
      this.setCombineFailedMessage();
    } else if (this.callEventChange === call.CallAbilityEventId.EVENT_SPLIT_CALL_FAILED) {
      this.message = $r('app.string.separate_conference_failed');
    }
    this.callEventChange = Constants.EVENT_DEFAULT_CALL_FAILED;
    if (this.message || this.primaryTitle) {
      this.openMessageDialog?.open();
    }
  }

  private setCombineFailedMessage() {
    this.message = $r('app.string.combine_conference_failed');
  }

  onPageHide() {
    LogUtils.i(TAG, 'onPageHide');
    this.isShowWaterRipple = false;
    AppStorage.setOrCreate<boolean>('onPageShow', false);
    if (!this.mHangup || this.callState !== CallStateConst.CALL_STATUS_DISCONNECTED ||
      this.callState !== CallStateConst.CALL_STATUS_DISCONNECTING) {
      this.updateNotification();
    }
    CallUtils.muteRinger(this.isIncomingState);
    if (this.callState === CallStateConst.CALL_STATUS_ACTIVE ||
      this.callState === CallStateConst.CALL_STATUS_HOLDING) {
      ReportUtil.getInstance().reportCallInBackground(this.callType === CallStateConst.TYPE_VOIP ? 1 : 0);
    }
    ProximityUtils.updateProximityLock();
    NumberMarkManager.getInstance().completeNumberMark('page hide');
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      if (this.waterRippleShowDelayTimer !== -1) {
        clearTimeout(this.waterRippleShowDelayTimer);
        this.showDelayTimerActive = true;
      }
    }
    this.releaseMemory();
    LogUtils.i(TAG, 'onPageHide end');
  }

  releaseMemory() {
    this.curStatusTimeId = setTimeout(() => {
      let curStatus = AppStorage.get<boolean>('onPageShow');
      if (curStatus) {
        LogUtils.e(TAG, `onPageHide releaseMemory curStatus ${curStatus}`);
        clearTimeout(this.curStatusTimeId);
        return;
      }
      LogUtils.i(TAG, `releaseMemory curStatusTimeId: ${this.curStatusTimeId}`);
      WallpaperHelper.getInstance().release();
      this.wallpaperBg = undefined;
      this.modifier.updateConstructorParams(ImageContent.EMPTY);
      animateToImmediately({}, () => {});
    }, 800);
  }

  updateNotification() {
    const callState = this.callState;
    const callId = this.callId;
    LogUtils.i(TAG, 'updateNotification ' + callState + ' callId = ' + callId);
    if (callState !== CallStateConst.CALL_STATUS_DISCONNECTED &&
      callState !== DEFAULT_CALL_STATUS && callId > 0) {
      if (this.mCallDataManager?.hasAliveCall()) {
        startBackgroundRunning();
      }
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    if (AppStorage.get('hasBeenToFrontOrBackend') || AppStorage.get('onIndexPage')) {
      ReportUtil.getInstance().reportHangupCallSuccess(DisplayMode.FULLSCREEN);
    } else {
      ReportUtil.getInstance().reportHangupCallSuccess(DisplayMode.CAPSULE);
    }
    stopBackgroundRunning();
    emitter.off(Constants.WALLPAPER_EVENT_ID);
    emitter.off(Constants.UPDATE_VIDEO_RINGTONE_EVENT_ID)
    WallpaperHelper.getInstance().release();
    LogUtils.i(TAG, `accept video call dialog close`);
    this.acceptVideoCallDialogController?.close();
    unRegisterPostDialDelay();
    CallColumnUtils.getInstance().removeDensityUpdateObserver(this.getUIContext());
    this.mBottomVM.removeMultiDeviceListener();
    CallDataManager.getInstance().removeTimeUpdateListener();
    this.acceptVideoCallDialogController = undefined;
    this.openMessageDialog = undefined;
    this.openDTMFDialog = undefined;
    this.isShowWaterRipple = false;
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      this.mBottomVM.removeIsCurEarpieceListener(this.callback);
      this.displaySyncObj.off('frame', () => {
      });
      this.displaySyncObj.stop();
      ProximityUtils.unRegisterAcc();
      ProximityUtils.unRegisterGyr();
      if (this.callActiveWaterRippleDisappearTimer !== -1) {
        clearTimeout(this.callActiveWaterRippleDisappearTimer);
        this.callActiveNotShowWaterRipple = false;
      }
    }
    this.waterRippleFadeoutCount = 0;
    if (this.sizeUpdateCallback !== undefined) {
      this.playVideoModel?.removeSizeUpdateCallback(this.sizeUpdateCallback)
    }
    this.playVideoModel?.releasePlay();
    EmptyWindowForDialog.getInstance().killDialogContainerWindow();
    if (this.callType === CallStateConst.TYPE_SATELLITE) {
      unSubscribeEvent(this.satelliteCallHangupEvent);
    }
    try {
      let windowObj =
        (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync();
      VirtualScreenBlockManager.getInstance().removeVirtualScreenBlocklist(windowObj);
    } catch (err) {
      LogUtils.i(TAG, `getMainWindowSync error code: ${err?.code}, msg: ${err?.message}`);
    }
    SystemMode.getInstance().unSubscribeEvent(this.powerSaveEvent);
  }

  onBackPress() {
    LogUtils.i(TAG, 'onBackPress');
    if (this.isIncomingState) {
      return true;
    }
    if (this.isShowKeyboard) {
      LogUtils.i(TAG, 'onBackPress Collapse Keyboard');
      this.showKeyboard();
      return true;
    }
    return false;
  }

  /**
   * method to control the display of DTMF keyboard
   *
   * parent component pass by value child component
   */
  public showKeyboard() {
    this.lightUpdate = true;
    this.isShowKeyboard = !this.isShowKeyboard;
    this.contactAppear = false;
    this.funcBtnAppear = false;
    this.incomingFuncBtnAppear = false;
    ReportUtil.getInstance().reportCallInterfaceClickBtn('keyboard', this.isShowKeyboard);
  }

  getBtnCallState() {
    this.refreshingData();
    this.showRbtView = shouldShowRbtView(this.callData) && !SystemMode.getInstance().isModePenglai();
    // For multi call case, the ANSWER state should be considered as incoming state
    // For video call case, the ANSWER state should be considered as active state
    let currentIncoming = isIncomingCall(this.callState, this.callListCount > 1 && !isVideoCall(this.videoState));
    this.showPanel();
    this.proxyComponent?.send({ 'callData': this.callData });
    if (this.isIncomingState === currentIncoming && this.callList.length === this.oldLength) {
      // Ignore if nothing updated
      return;
    }

    if (currentIncoming) {
      this.isShowKeyboard = false;
      this.translateName = '0';
      this.translateTime = '0';
      this.contactAppear = true;
      this.funcBtnAppear = true;
      this.incomingFuncBtnAppear = false;
      this.showConferenceDetail = false;
    } else if (this.callList.length <= 1 && this.oldLength > 1) {
      this.isShowKeyboard = false;
      this.translateName = '0';
      this.translateTime = '0';
      this.contactAppear = true;
    }

    this.isIncomingState = currentIncoming;
    this.oldLength = this.callList.length;
  }

  getWallpaper() {
    if (AppStorage.get('onPageShow')) {
      WallpaperHelper.getInstance().getWallpaperData();
    }
  }

  clearDisconnectedCallIfPossible() {
    if (this.callList === undefined || this.callList.length === 0) {
      return;
    }
    let index: number = -1;
    while ((index =
      this.callList.findIndex((v: DefaultCallData) => (v.callState === CallStateConst.CALL_STATUS_DISCONNECTED ||
        v.callState === -1) && v.callId !== this.callData.callId)) !== -1) {
      LogUtils.i(TAG, 'to be deleted call is' + callDataToSafeString(this.callList[index]));
      let callId = this.callList[index].callId;
      this.callList.splice(index, 1);
      if ((index = this.callTimeList.findIndex((v: CallTimeListStruct) => v.callId === callId)) !== -1) {
        this.callTimeList.splice(index, 1);
      }
    }
  }

  surfaceIdChange() {
    VideoCallManager.getInstance().surfaceIdChange(this.surfaceId);
  }

  isRbtChange() {
    if (this.isRbtError) {
      this.clearTimeOut();
      this.isPanelShown = true;
    }
  }

  windowSizeChange() {
    this.isSmartWindowAndFoldable();
    if (this.isApplyNewStyle) {
      LogUtils.i(TAG, `foldChange true`);
      this.foldChange = true;
    }
  }

  refreshVideoSize() {
    let componentWidth: number = componentUtils.getRectangleById('xComponentId').size.width;
    let componentHeight: number = componentUtils.getRectangleById('xComponentId').size.height;
    let componentRatio: number = componentWidth / componentHeight;
    let videoWith = this.videoSize.width;
    let videoHeight = this.videoSize.height;
    let videoRatio: number = videoWith / videoHeight;
    let finalWith: number = videoWith;
    let finalHeight: number = videoHeight;
    if (componentRatio > 1 && videoRatio > 1 || componentRatio < 1 && videoRatio < 1) {
      let ratio = Math.max(componentWidth / videoWith, componentHeight / videoHeight);
      finalWith = videoWith * ratio;
      finalHeight = videoHeight * ratio;
      this.xComponentController.setXComponentSurfaceRect({
        surfaceWidth: componentWidth, // 单位px
        surfaceHeight: componentHeight // 单位px
      });
    } else if (componentRatio > 1 && videoRatio < 1 || componentRatio < 1 && videoRatio > 1) {
      // 屏幕宽度大于高度， 视频宽度小于高度， 高度填充，宽度左右剩余黑边
      let ratio = Math.min(componentWidth / videoWith, componentHeight / videoHeight);
      finalWith = videoWith * ratio;
      finalHeight = videoHeight * ratio;
      this.xComponentController.setXComponentSurfaceRect({
        surfaceWidth: finalWith, // 单位px
        surfaceHeight: finalHeight // 单位px
      });
    }
  }

  changeSplitScreenType() {
    if (!SplitScreenManager.getInstance().callBottomKeyboardBtnEnable(this.splitScreenType) && this.isShowKeyboard) {
      this.showKeyboard();
    }
  }

  getCallCount() {
    this.getBtnCallState();
    let hasConference: boolean = false;
    let callCount = 0;
    for (let i = 0; i < this.callList.length; i++) {
      let curCallData = this.callList[i];
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        if (!hasConference) {
          hasConference = true;
          callCount++;
        }
      } else {
        callCount++;
      }
    }
    this.hasConference = hasConference;
    this.callListCount = callCount;
  }

  isShowSetNumberMark(): boolean {
    return this.strangeNumberCallData !== null;
  }

  private paddingBottom(isNewFoldPhoneExternalScreen: boolean): number {
    if (isNewFoldPhoneExternalScreen) {
      return 0;
    }
    if (this.splitManager.isPhoneSpliteScreen(this.splitScreenType)) {
      return 0;
    }
    if (canShowVideoCallUi(this.callState, this.videoState, this.isHoldVideoUx)) {
      if (this.isShowSetNumberMark()) {
        return 64 - this.navigationHeight;
      }
      return 0;
    }
    return 0;
  }

  rowsGap(): number {
    if (this.isApplyNewStyle && this.appBtnStyle.rowsGap) {
      let rowsGap: number = this.appBtnStyle.rowsGap;
      return rowsGap;
    }
    let rowsGapNum = CallColumnUtils.getInstance().rowsGap(this.windowSizeChangeMd, this.isShowSmartWindow,
      this.statusBarHeight, this.airbarHeight, this.curBp,
      this.isSmartWindowSplitScreen);
    return rowsGapNum;
  }

  funcButtonAndKeyboardHeight(isNewFoldPhoneExternalScreen: boolean): number {
    if (this.isApplyNewStyle && this.appWindow.maxHeight && this.appBtnStyle.btnWidth) {
      let funcButtonAndKeyboardHeight: number = this.appBtnStyle.btnWidth * 4 + this.appBtnStyle.rowsGap * 3;
      return funcButtonAndKeyboardHeight;
    }
    if (isNewFoldPhoneExternalScreen) {
      if (this.isShowKeyboard) {
        return 176;
      }
      return 87;
    }
    let height = CallColumnUtils.getInstance().gridHeight(this.windowSizeChangeMd, this.isShowSmartWindow,
      this.statusBarHeight, this.airbarHeight, this.curBp, this.isSmartWindowSplitScreen);
    return height;
  }

  isSmartWindowAndFoldable() {
    let isFoldable = (DisplayUtil.isFoldable() && (this.curBp === 'sm') && DisplayUtil.getScreenFoldStatus() === 2);
    let isSplitStatus = SplitScreenManager.getInstance().isSplitScreenStatus();
    if (this.isShowSmartWindow && !isSplitStatus && isFoldable) {
      this.isSmartWindowAndFoldableStatus = true;
    } else {
      this.isSmartWindowAndFoldableStatus = false;
    }
    return this.isSmartWindowAndFoldableStatus;
  }

  private showPanel() {
    this.isPanelShown = true;
    this.clearTimeOut();
    if (!this.isIncomingState && this.showRbtView && !this.isShowKeyboard && !this.isRbtError) {
      LogUtils.i(TAG, 'showPanel');
      this.addPanelHiddenTimer();
    }
  }

  private updatePanelStatus(isChange: boolean) {
    LogUtils.i(TAG, 'updateFuncBtnStatus isChange: ' + isChange)
    this.clearTimeOut();
    if (this.isIncomingState || !this.showRbtView || this.isShowKeyboard) {
      return;
    }
    if (this.isRbtError) {
      return
    }
    if (isChange) {
      this.isPanelShown = !this.isPanelShown;
    }
    if (this.isPanelShown) {
      this.addPanelHiddenTimer();
    }
  }

  private addPanelHiddenTimer() {
    this.panelHiddenTimer = setTimeout(() => {
      this.isPanelShown = false;
      this.panelHiddenTimer = -1;
    }, 5000)
  }

  private clearTimeOut() {
    if (this.panelHiddenTimer !== -1) {
      clearTimeout(this.panelHiddenTimer);
      this.panelHiddenTimer = -1;
    }
  }

  private getCallNormalPercent(percent: number): number {
    return CallColumnUtils.getInstance().getCallNormalPercent(this.windowSizeChangeMd,
      this.isShowSmallScreen,
      this.statusBarHeight,
      this.airbarHeight,
      percent);
  }

  private getCommonCallCardHeight(): number {
    if (this.isApplyNewStyle) {
      return 40;
    }
    if (this.splitManager.isSpliteCallHeightPercent(this.splitHeight, this.isShowSetNumberMark()) &&
      !this.isIncomingState) {
      return this.splitManager.getCommonCallCardHeightPercent();
    }
    if (this.isSmartWindowAndFoldable()) {
      return this.getCallNormalPercent(30);
    }
    return this.getCallNormalPercent(40);
  }

  private getVoiceBottom(isNewFoldPhoneExternalScreen: boolean): number {
    if (this.isApplyNewStyle) {
      return 0;
    }
    if (isNewFoldPhoneExternalScreen) {
      return 32;
    }
    if (this.splitManager.isPhoneSpliteScreen(this.splitScreenType)) {
      // 新折叠竖屏分屏,距离底部16vp,导航条28vp
      if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT && this.navigationHeight > 0) {
        return 44 - this.navigationHeight;
      }
      return 24;
    }
    if (isTwoInOne()) {
      return 64;
    }
    return this.keyBoradOrFuncBtnBottomSpace;
  }

  isHideVoiceControlTips(): boolean {
    LogUtils.i(TAG, `isHideVoiceControlTips, callListCount: ${this.callListCount}`);
    return this.isNewFoldPhoneExternalScreen && (this.isShowKeyboard || this.callListCount >= 2);
  }

  getCallCardHeight() {
    if (this.isNewFoldPhoneExternalScreen) {
      if (this.isShowKeyboard) {
        return '26vp';
      }
      return 'calc((100% - 32vp) * 0.45)';
    }
    if (this.isNewFoldPhoneInnerFullScreen) {
      if (this.isShowKeyboard) {
        return 'calc((100% - 48vp) * 0.4)';
      }
      return 'calc((100% - 68vp) * 0.4)';
    }
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return 'auto';
    }
    return `${this.getCommonCallCardHeight()}%`;
  }

  getVoiceBottomUIJustifyContent() {
    if ((this.isNewFoldPhoneExternalScreen && !this.isShowKeyboard) || this.isNewFoldPhoneInnerFullScreen) {
      return FlexAlign.SpaceBetween
    }
    return FlexAlign.End;
  }

  setShowWaterRipple() {
    if (this.isNewFoldPhoneExternalScreen && !this.callActiveNotShowWaterRipple &&
      (this.callData.callState === CallStateConst.CALL_STATUS_ALERTING ||
        this.callData.callState === CallStateConst.CALL_STATUS_INCOMING ||
        this.callData.callState === CallStateConst.CALL_STATUS_ACTIVE)) {
      this.waterRippleFadeoutCount = 0;
      this.setSafeWaterRipple(true);
    } else {
      this.setSafeWaterRipple(false);
    }
  }

  canShowWaterRipple() {
    let bool = this.isShowWaterRipple && this.isEarpiece;
    return bool;
  }

  @Builder
  commonCallCard() {
    CallCard({
      callData: $callData,
      callType: $callType,
      callState: $callState,
      contactAvatar: $contactAvatar,
      isShowKeyboard: this.isShowKeyboard,
      callList: $callList,
      callTimeList: $callTimeList,
      translateName: this.translateName,
      translateTime: this.translateTime,
      contactAppear: this.contactAppear,
      showConferenceDetail: $showConferenceDetail,
      callListCount: this.callListCount,
    })
      .margin({ top: (this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? '12vp' : 0 })
      .height(this.getCallCardHeight())
      .visibility(SplitScreenManager.getInstance().commonCallCard(this.isShowSetNumberMark(), this.splitScreenType))
      .opacity(this.uiAlpha)
  }

  @Builder
  strangeNumberHandler() {
    StrangeNumberHandlerPanel({
      callData: $strangeNumberCallData,
    })
      .margin({
        bottom: this.getNumberHandlerBottom()
      })
  }

  private getNumberHandlerBottom() {
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      if (this.newFoldSplitPortraitScreenType === 1) {
        return 0;
      }
      return -16;
    }
    return this.isNewFoldPhoneExternalScreen ? -21 : -23;
  }

  private async updateAvPlayerFd() {
    LogUtils.i(TAG, 'updateAvPlayerFd is called, this.accountId = ' + this.accountId);
    if (this.callListCount <= 1) {
      return;
    }
    if (this.accountId === this.callData.accountId &&
      this.videoRingPath === this.callData.extraParams?.['VideoRingPath'] as string) {
      LogUtils.i(TAG, 'updateAvPlayerFd, same accountId and videoRingPath, return');
      return;
    }
    if (shouldShowVideoRing(this.callData) && this.videoSurfaceID !== '') {
      this.accountId = this.callData.accountId;
      this.videoRingPath = this.callData.extraParams?.['VideoRingPath'] as string;
      let fileFd: number = await getVideoRingPath(this.callData);
      if (fileFd !== Constants.INVALID_NUM) {
        if (this.playVideoModel?.getAvPlayerState() === aVPlayerStatePlaying) {
          await this.playVideoModel?.releasePlayAnyway();
        }
        this.playVideoModel?.playVideoByFd(fileFd, CallUtils.isDoNotDisturb(this.callData), this.accountId,
          this.xComponentController?.getXComponentSurfaceId());
        this.showVideoComponent = true;
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center}) {
      if (this.voiceControlSwitch &&
        !this.splitManager.isSplitScreen(this.splitScreenType)) {
        Row() {
          VoiceControlTip({
            callList: $callList,
            callData: $callData
          })
            .enabled(false)
            .width('100%')
            .height('100%')
        }
        .height(24)
        .position({ x: 0, y: 0 })
        .zIndex(20)
        .accessibilityLevel('no-hide-descendants')
        .visibility(this.isHideVoiceControlTips() ? Visibility.None : Visibility.Visible)
      }
      this.buildBackground()
      this.showRbtViewFunc();
      if (shouldShowVideoRing(this.callData)) {
        this.showLocalVideoFunc();
      }
      this.showMaskingLayerFunc(false)
      this.mainlyView();

      this.waterRippleView()
    }
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }

  private shouldEnableAccessibility(): string {
    if (this.isIncomingState) return 'no';
    if (!this.showRbtView) return 'no';
    if (this.isShowKeyboard) return 'no';
    if (this.isRbtError) return 'no';
    return 'yes';
  }

  @Builder
  showLocalVideoFunc() {
    Column() {
      XComponent({
        type: XComponentType.SURFACE,
        controller: this.xComponentController,
      }).onLoad(async () => {
        LogUtils.i(TAG, 'onLoad is called, is called ');
        this.videoSurfaceID = this.xComponentController.getXComponentSurfaceId();
        this.accountId = this.callData.accountId;
        this.videoRingPath = this.callData.extraParams?.['VideoRingPath'] as string;
        this.sizeUpdateCallback = ((curWith: number, curHeight: number) => {
          this.videoSize.width = curWith;
          this.videoSize.height = curHeight;
          this.refreshVideoSize();
        });
        this.playVideoModel?.addSizeUpdateCallback(this.sizeUpdateCallback);
        if (this.playVideoModel?.getAvPlayerState() === aVPlayerStatePlaying &&
          this.playVideoModel?.getAccountId() === this.accountId) {
          this.playVideoModel.updateSurfaceId(this.videoSurfaceID);
        } else {
          if (this.playVideoModel?.getAvPlayerState() === aVPlayerStatePlaying) {
            await this.playVideoModel?.releasePlayAnyway();
          }
          let fileFd: number = await getVideoRingPath(this.callData);
          if (fileFd !== Constants.INVALID_NUM) {
            this.showVideoComponent = true;
            this.playVideoModel?.playVideoByFd(fileFd, CallUtils.isDoNotDisturb(this.callData), this.accountId,
              this.videoSurfaceID);
            return;
          }
          try {
            LogUtils.i(TAG, 'onLoad, invalid video fd, play default ringing');
            call.sendCallUiEvent(this.callData.callId, 'EVENT_INVALID_VIDEO_FD');
          } catch (err) {
            LogUtils.e(TAG, `onLoad, send callui event fail: ${err.code}`);
          }
          this.showVideoComponent = false;
        }
      }).onSizeChange(() => {
        // 记录内部的高度
        this.refreshVideoSize();
      })
        .id('xComponentId')
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onDisAppear(() => {
      LogUtils.i(TAG, 'XComponent onDisAppear is called');
      if (this.sizeUpdateCallback) {
        this.playVideoModel?.removeSizeUpdateCallback(this.sizeUpdateCallback);
      }
      this.showVideoComponent = false;
      this.videoSurfaceID = '';
      this.playVideoModel?.releasePlayAnyway();
    })
    .onAppear(() => {
      LogUtils.i(TAG, 'XComponent onAppear is called');
      this.showVideoComponent = true;
    })
    .visibility(this.showVideoComponent ? Visibility.Visible : Visibility.None)
    .width(px2vp(this.windowSizeChangeMd.width)).height(px2vp(this.windowSizeChangeMd.height))
  }

  @Builder
  penglaiBackGround() {
    Column()
      .backgroundColor($r('app.color.black'))
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildBackground() {
    if (SystemMode.getInstance().isModePenglai()) {
      this.penglaiBackGround()
    } else if (this.callType === CallStateConst.TYPE_SATELLITE) {
      Image(this.satelliteWallpaperBg)
        .backgroundExtend()
    } else if (this.contactAvatar && this.callData.contactAvatarColor && !this.isConferenceMode &&
      !this.isShowSetNumberMark() && !canShowVideoCallUi(this.callState, this.videoState) && !this.isVoiceMailNumber) {
      Image(this.contactAvatar)
        .backgroundExtend()
      Column()
        .width('100%')
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .backgroundEffect({
          radius: 75,
          saturation: 1.4,
          brightness: 1.0,
          color: this.callData.contactAvatarColor,
          adaptiveColor: AdaptiveColor.DEFAULT,
          blurOptions: { grayscale: [20, 20] },
          policy: BlurStyleActivePolicy.ALWAYS_ACTIVE
        }, { disableSystemAdaptation: true })
    } else {
      Image(this.wallpaperBg)
        .attributeModifier(this.modifier)
        .backgroundExtend()
        .backgroundColor(this.largestColor)
    }
  }

  @Builder
  waterRippleView() {
    if (this.canShowWaterRipple()) {
      Row() {
      }
      .width('50%')
      .height('50%')
      .position({ x: 0, y: 0 })
      .visibility(Visibility.Visible)
      .backgroundFilter(this.filter.waterRipple(this.waterRippleProgress, 3, 0.8, 1, 1))
      .enabled(false)
    }
  }

  @Builder
  mainlyView() {
    if (this.showConferenceDetail) {
      ConferenceDetail({
        callList: $callList,
        showConferenceDetail: $showConferenceDetail,
        callListCount: $callListCount,
      })
        .opacity(this.uiAlpha)
    } else {
      this.normalCallUI();
    }
  }

  @Builder
  showMaskingLayerFunc(isBackgroundColor: boolean) {
    if (this.callType !== CallStateConst.TYPE_SATELLITE) {
      Column()
        .backgroundColor(isBackgroundColor ? $r('app.color.background_color') :
          (this.showVideoComponent ? $r('app.color.video_ring_call_bg_color') : $r('app.color.normal_call_bg_color')))
        .height('100%')
        .width('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
    }
  }

  @Builder
  showRbtViewFunc() {
    if (this.showRbtView) {
      Column() {
        RbtRingToneXComponent({
          videoState: $videoState,
          callState: $callState,
          callId: $callId
        })
          .width('100%')
          .height('100%');
      }
      .width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
    }
  }

  @Builder
  normalCallUI() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (canShowVideoCallUi(this.callState, this.videoState, this.isHoldVideoUx)) {
        this.showVideoCallUI();
      } else {
        this.showVoiceCallUI();
      }
      if (this.isIncomingState) {
        IncomingCom({
          callList: $callList,
          callData: $callData,
        })
          .margin({ bottom: 0 });
      }

      if (this.timeOutManager.isAnsweredTimeOut) {
        Text($r('app.string.answeredTimeout'))
          .fontSize($r('app.float.call_incoming_body_m_font'))
          .fontColor($r('sys.color.font_on_primary'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height($r('app.float.call_incoming_body_m_height'))
          .lineHeight($r('app.float.call_incoming_body_m_height'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({
            bottom: this.isShowSmartWindow ? $r('app.float.margin_bottom_smart_window') :
            $r('app.float.margin_bottom_window')
          })
      }
    }
    .padding({
      bottom: this.paddingBottom(this.isNewFoldPhoneExternalScreen)
    })
    .width('100%')
    .height('100%')
    .constraintSize({
      maxWidth: !this.isShowSetNumberMark() && this.isApplyNewStyle ? this.appWindow.maxWidth : undefined,
      maxHeight: !this.isShowSetNumberMark() && this.isApplyNewStyle ? this.appWindow.maxHeight :
      CallColumnUtils.maxHeight
    })
    .onClick(() => {
      this.updatePanelStatus(true);
    })
    .accessibilityLevel('no')
  }

  @Builder
  showVoiceCallUI() {
    Column() {
      this.commonCallCard();

      Stack({ alignContent: Alignment.BottomEnd }) {
        this.voiceBottomUI()
      }
      .margin({ bottom: this.getVoiceBottom(this.isNewFoldPhoneExternalScreen) })
      .layoutWeight(1)
      .height(this.isNewFoldPhoneExternalScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ?
        'auto' : `${100 - this.getCommonCallCardHeight()}%`)
      .onClick(() => {
        this.updatePanelStatus(true);
      })
      .accessibilityLevel(this.shouldEnableAccessibility())
    }
    .layoutWeight(1)
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.opacity(canShowVideoCallUi(this.callState, this.videoState, this.isHoldVideoUx) ? 0 : 1)
          .animation({
            duration: 200,
            delay: 0,
            curve: curves.interpolatingSpring(0, 1, 342, 37)
          }),
        TransitionEffect.opacity(0)
          .animation({ curve: curves.interpolatingSpring(0, 1, 342, 37) })
      )
    )
    .width('100%')
  }

  @Builder
  voiceBottomUI() {
    if ((!this.isIncomingState && !this.isShowSetNumberMark())) {
      Column() {
        this.funcButtonAndKeyboard();
        this.bottomButtonsView();
      }
      .justifyContent(this.getVoiceBottomUIJustifyContent())
      .visibility(this.isPanelShown ? Visibility.Visible : Visibility.Hidden)
      .height('100%')
      .margin({
        bottom: this.getVoiceBottomGap()
      })
      .id('callui_voiceBottomUI_Column')
      .opacity(this.uiAlpha)
    }

    if (!this.isIncomingState && this.isAnswer && !this.isShowSetNumberMark()) {
      if (this.lockAnswerOn) {
        LockIncomingAnimation({ isVideoCall: isVideoCall(this.videoState) }).hitTestBehavior(HitTestMode.Transparent)
          .margin({
            bottom: this.getVoiceBottomGap()
          });
      } else {
        IncomingAnimation()
          .margin({
            bottom: this.getVoiceBottomGap()
          });
      }
    }
    if (this.isShowSetNumberMark()) {
      this.strangeNumberHandler();
    }
  }

  getVoiceBottomGap(): number {
    if (this.isApplyNewStyle) {
      return this.btnBottomGap;
    }
    return 0;
  }

  @Builder
  bottomButtonsView() {
    BottomBtn({
      callData: $callData,
      callList: $callList,
      callState: $callState,
      hasMultiDevice: $hasMultiDevice,
      isAnswer: $isAnswer,
      callListCount: $callListCount,
      onItemTouch: () => {
        this.showKeyboard();
      },
      touchStatusCallBack: (isTouchDown) => {
        isTouchDown ? this.clearTimeOut() : this.updatePanelStatus(false);
      }
    })
      .margin({ bottom: 0 })
  }

  @Builder
  showVideoCallUI() {
    if (this.callState === CallStateConst.CALL_STATUS_DISCONNECTING ||
      this.callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
      // For video call end, show page with call card.
      Column() {
        this.commonCallCard();
      }
      .width('100%')
      .height('100%');
      if (this.isShowSetNumberMark()) {
        this.strangeNumberHandler();
      }
    } else {
      VideoXComponent({
        callData: $callData,
        callId: $callId,
        callState: $callState,
        videoState: $videoState,
        callList: $callList,
        hasMultiDevice: $hasMultiDevice,
        callTimeList: $callTimeList,
        contactAppear: this.contactAppear,
        callListCount: this.callListCount,
      })
        .width('100%')
        .height('100%');
    }
  }

  @Builder
  funcButtonAndKeyboard() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (!this.isShowKeyboard) {
        FuncBtnGroup({
          callData: $callData,
          callList: $callList,
          callListCount: $callListCount,
          hasConference: this.hasConference,
          touchStatusCallBack: (isTouchDown) => {
            isTouchDown ? this.clearTimeOut() : this.updatePanelStatus(false);
          }
        })
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.opacity(this.incomingFuncBtnAppear ? 1 : 0)
                .animation({
                  duration: this.funcBtnAppear ? 230 : 200,
                  delay: this.funcBtnAppear ? 30 : 50,
                  curve: Curve.Sharp
                })
                .combine(
                  TransitionEffect.translate({ y: this.funcBtnAppear ? '0px' : '-200px' })
                    .animation({ curve: curves.interpolatingSpring(0, 1, 342, 37) })),
              TransitionEffect.OPACITY.animation({ duration: 100, curve: Curve.Sharp })
                .combine(
                  TransitionEffect.translate({ y: '-200px' })
                    .animation({ curve: curves.interpolatingSpring(0, 1, 480, 44) }))
            )
          );
      } else {
        Keyboard({ callId: $callId })
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.Sharp, delay: 50 })
                .combine(TransitionEffect.translate({ y: '1298px' })
                  .animation({ curve: curves.interpolatingSpring(0, 1, 480, 44) })),
              TransitionEffect.OPACITY.animation({ duration: 150, curve: Curve.Sharp }).combine(
                TransitionEffect.translate({ y: '1298px' })
                  .animation({ curve: curves.interpolatingSpring(0, 1, 342, 37) }))
            )
          );
      }
    }
    .clip(this.lightClipState)
    .height(this.getFuncButtonAndKeyHeight())
    .visibility(SplitScreenManager.getInstance().callFuncBtnsVisibility(this.splitScreenType))
    .margin({
      bottom: this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ? 17 : this.rowsGap()
    })
    .id('callui_funcButtonAndKeyboard_Stack')
  }

  private getFuncButtonAndKeyHeight(): Length {
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return 'auto';
    }
    return this.isNewFoldPhoneInnerFullScreen ? this.isShowKeyboard ? 'calc(100% - 76vp)' : 'calc(100% - 81vp)' :
    this.funcButtonAndKeyboardHeight(this.isNewFoldPhoneExternalScreen);
  }

  private async subscribeCallHangupEvent() {
    this.satelliteCallHangupEvent = await createSubscriber(EVENT_SATELLITE_CALL_HANGUP);
    subscribeEvent(async (data?: string) => {
      LogUtils.i(TAG, 'subscribeCallHangupEvent' + this.callType);
      if (this.callType === CallStateConst.TYPE_SATELLITE) {
        BottomViewModel.getInstance().hangUpCall(this.callData.callId, CallDataManager.getInstance().callList.length);
      }
    }, this.satelliteCallHangupEvent);
  }

  public async subscribePowerSaveEvent(): Promise<void> {
    this.powerSaveEvent = await SystemMode.getInstance().subscribePowerSaveEvent(() => {
      if (SystemMode.getInstance().isOutdoorTravel()) {
        AppStorage.setOrCreate('isOutdoorTravel', true);
      } else {
        AppStorage.setOrCreate('isOutdoorTravel', false);
      }
    });
  }
}

@Extend(Image)
function backgroundExtend() {
  .draggable(false)
  .hoverEffect(HoverEffect.None)
  .interpolation(ImageInterpolation.High)
  .objectFit(ImageFit.Cover)
  .height('100%')
  .width('100%')
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
}