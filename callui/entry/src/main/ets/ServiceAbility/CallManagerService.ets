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

/**
 * @file: call manager service
 */
import CallServiceProxy from '../model/CallServiceProxy';
import TelephonyCall from './TelephonyApi';
import commonEventManager from '@ohos.commonEventManager';
import LogUtils from '../common/utils/LogUtils';
import CallManager from '../model/CallManager';
import { VibrationUtils } from '../common/utils/VibrationUtils';
import CallStateConst from '../common/constant/CallStateConst';
import call from '@ohos.telephony.call';
import Method from '../common/utils/Method';
import DefaultCallData, {
  callDataToSafeString,
  VoipCallAttribute,
  CallDataPatch,
  callDataPatcher
} from '../common/struct/TypeUtils';
import { BusinessError } from '@ohos.base';
import { observer as telObserver } from '@kit.TelephonyKit';
import Want from '@ohos.app.ability.Want';
import audio from '@ohos.multimedia.audio';
import BannerNotificationManager, { ID } from '../model/BannerNotificationManager';
import IdlServiceExtProxy from '../idl/idl_service_ext_proxy';
import { CallListStruct, RecordInputData } from '../common/struct/RecordingStruct';
import Recording from '../common/utils/Recording';
import AudioDeviceManager from '../model/audio/AudioDeviceManager';
import AudioDeviceType, { audioObj } from '../model/audio/AudioDeviceType';
import BottomViewModel from '../viewmodel/BottomViewModel';
import CallDataManager from '../model/CallDataManager';
import * as Constants from '../common/utils/Constants';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import {
  ImsCallModeInfo,
  offImsCallModeChange,
  offCallSessionEvent,
  onCallSessionEvent,
  offPeerDimensionsChange,
  onImsCallModeChange,
  onPeerDimensionsChange,
  PeerDimensionsDetail,
  setPreviewWindowApi,
  ImsCallMode
} from '../common/utils/VideoCallApi';
import VideoCallManager from '../model/VideoCallManager';
import {
  RECORDER_DISABLED_STATUS,
  RECORDER_START_STATUS,
  RECORDER_STOP_STATUS
} from '../common/constant/CallRecorderConst';
import screenLock from '@ohos.screenLock';
import { CallEventUtil } from '../common/utils/CallEventUtil';
import { HashMap } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { StartOptions } from '@kit.AbilityKit';
import { ExternalCallModel } from '../model/ExternalCallModel';
import { settings, usbManager } from '@kit.BasicServicesKit';
import { isIncomingCall, isVideoCall, getCallById, shouldShowVideoRing,
  getVideoRingPath } from '../common/utils/CallListHelper';
import { isScreenLocked } from '../common/utils/DeviceTypeUtils';
import { CallFaultEventUtil } from '../common/utils/ReportUtils/CallFaultEventUtil';
import VideoCameraHelper from '../common/struct/VideoCameraHelper';
import { HiCarDeviceInfo, HiCarUtils } from '../common/utils/HiCarUtils';
import { getActiveSimCount } from '../model/SimManager';
import IncomingComVM from '../viewmodel/IncomingComVM';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import notificationManager from '@ohos.notificationManager';
import CallUtils, { CallUtils as CallUtilsClass } from '../common/utils/CallUtils';
import { isRTLHandle } from '../common/utils/LanguageUtils';
import { HiCarManager } from '../model/HiCarManager';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { TimeOutManager } from '../model/TimeOutManager';
import { LeatherManager } from '../leatheruiextability/LeatherManager';
import { preferences } from '@kit.ArkData';
import { ListenScreenUnlocked } from '../common/utils/ListenScreenUnlocked';
import Utils from '../common/utils/utils';
import { fileNameString } from '../common/utils/CallLabelUtils';
import { display, window } from '@kit.ArkUI';
import { VisionGlassConstants } from '../common/constant/VisionGlassConstants';
import { getContactInfo } from '../model/ContactManager';
import bundleManager from '@ohos.bundle.bundleManager';
import { NumberMarkManager } from '../model/NumberMarkService';
import { ProximityUtils } from '../common/utils/ProximityUtils';
import { aVPlayerStatePlaying, VideoController } from '../controller/VideoController';
import { DisplayMode } from '../common/utils/ReportUtils/DisplayMode';
// import { collaborationServiceManager } from '@kit.ServiceCollaborationKit';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import {DataShareResultSet} from '@kit.ArkData';
import hiTraceChain from '@ohos.hiTraceChain';
import sim from '@ohos.telephony.sim';
import { ContactsData } from '../common/utils/ContactsData';
import { getNumberMarkInfoTask } from '../numberMark/PhoneNumberMarkInfo';
import NumberMarkUtil from '../numberMark/NumberMarkUtil';

const TAG = 'CallManagerService';
const CALL_BUNDLE_NAME = 'com.ohos.callui';
const ABILITY_NAME_EXTERNAL = 'com.ohos.callui.ExternalCallAbility';
const BANNER_HIDE_EVENT = 'sysui_window_state_change';
const WINDOW_TYPE_BANNER = 'banner_pannel';
const CREATOR_BUNDLE_NAME = 'creatorBundleName';
const CALL_UI_CALL_CLICK = 'callui.event.click';
const SCREEN_OFF_EVENT = 'usual.event.SCREEN_OFF';
const SCREEN_ON_EVENT = 'usual.event.SCREEN_ON';
const VOICE_CONTROL_EVENT = 'usual.event.CALL_UI_REPORT_SWITCH_STATE_CHANGE';
const NEW_CALLING_EVENT = 'event.custom.ims.ACTION_SCREENSHARE_STATUS_CHANGED';
const VOICE_CONTROL_BROADCAST_SWITCH_ON = '0';
const VOICE_CONTROL_SWITCH_ON = '1';
const VOICE_CONTROL_CONNECT_KEY = 'isConnectVoiceAssistant';
const VOICE_CONTROL_CONTROL_SWITCH_KEY = 'incoming_call_voice_control_switch';
const VOICE_CONTROL_BROADCAST_SWITCH_KEY = 'incoming_call_voice_broadcast_switch';
const SETTING_SATELLITE_SERVICE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const QUERY_SATELLITE_MODE_HYACINTH_KEY = 'satellite_mode_switch_hyacinth';
const PUBLISHER_NAME = 'publisher_name';
const REMOTE_OBJECT_SEND_REQUEST = 'remote_object_send_request';
const events =
  [CALL_UI_CALL_CLICK, SCREEN_OFF_EVENT, SCREEN_ON_EVENT, BANNER_HIDE_EVENT, VOICE_CONTROL_EVENT, NEW_CALLING_EVENT];
const ANTIFRAUD_BUNDLE_NAME = 'com.hicorenational.antifraud.hmy';
const ANTIFRAUD_APP_ID = '6917560993344198571';
const BEST_MIND_BUNDLE_NAME = 'com.bestmind.antifraud.hmy';
const BEST_MIND_APP_ID = '6917579204242408693';
const REPEAT_CALL_NOT_BLOCK_REASON_ID = 1003;
const ANTI_FRAUD_SWITCH_ON = '1';

export let soundzoneSupport = false;

/**
 * class CallManagerService
 */
export default class CallManagerService {
  private mTelephonyCall: TelephonyCall = new TelephonyCall();
  private callData?: DefaultCallData = undefined;
  private callList: DefaultCallData[] = [];
  private context?: common.ServiceExtensionContext;
  private UIContext?: common.UIAbilityContext;
  private static sCallManagerService: CallManagerService;
  private mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  private bannerNotificationManager?: BannerNotificationManager;
  private mIsNotifiesSubscribed: boolean = false;
  private subscriber?: commonEventManager.CommonEventSubscriber;
  private isEventSubscribed: boolean = false;
  private voipCallMap: HashMap<number, DefaultCallData> = new HashMap();
  private currentVoipCallId: number | undefined = undefined;
  private isInOobe = false;
  private isAnsweredByPhone = false;
  private appSubscriber?: commonEventManager.CommonEventSubscriber;
  private isAppSubscribed: boolean = false;
  private audioDeviceChangeInfo: audioObj = AudioDeviceType.audioDeviceType;
  private coverModel: boolean | undefined;
  // private startUIAbilityInHiCar: () => void = () => {
  //   // When an outgoing call is made, the call page needs to be pulled from the HiCar.
  //   HiCarUtils.getHiCarDeviceInfo().then((deviceInfo: HiCarDeviceInfo | undefined) => {
  //     if (deviceInfo === undefined || !deviceInfo.connectStatus || Number(deviceInfo.displayId) === -1) {
  //       LogUtils.i(TAG, 'hicar dev is not connect');
  //       return;
  //     }
  //     this.context?.startAbility({
  //       bundleName: Constants.CALL_BUNDLE_NAME,
  //       abilityName: Constants.HICAR_CALL_ABILITY_NAME
  //     }, {
  //       displayId: Number(deviceInfo.displayId)
  //     }).then(() => {
  //       LogUtils.i(TAG, 'callUI service startHiCarAbility done');
  //     }).catch((err: BusinessError) => {
  //       LogUtils.e(TAG, `callUI service startHiCarAbility err: ${err.message}`);
  //     });
  //   });
  // }

  public static getInstance(): CallManagerService {
    if (!CallManagerService.sCallManagerService) {
      CallManagerService.sCallManagerService = new CallManagerService();
    }
    return CallManagerService.sCallManagerService;
  }

  public constructor() {
  }

  public init(context: common.ServiceExtensionContext): void {
    this.mTelephonyCall = new TelephonyCall;
    this.context = context;
    this.clearData();
    ListenScreenUnlocked.getInstance().isUserUnlocked();
    this.addRegisterListener();
    this.addSubscriber();
    this.defaultOpenNotification();
    this.bannerNotificationManager = BannerNotificationManager.getInstance();
    ReportUtil.getInstance();
    ExternalCallModel.getInstance().registerFoldStatusChange();
    this.queryIsInOobe();
    this.handlegetSimCount();
    isRTLHandle();
    {
      try {
        let getSoundzoneSupport = systemParameterEnhance.getSync('const.multimedia.audio.fwk_soundzone.enable', 'false');
        soundzoneSupport = (getSoundzoneSupport === 'true');
      } catch (error) {
        LogUtils.e(TAG, 'Get soundzoneSupport error!');
      }
    }
    this.addSubscribeServiceState();
    this.registerSimStateChange();
  }

  /**
   * Get current audio device info.
   */
  // instrument ignore next
  registerAudioChange() {
    LogUtils.i(TAG, 'register audio change start');
    AudioDeviceManager.getInstance().registerAudioDeviceChange((audioDeviceInfo: audioObj) => {
      if (!audioDeviceInfo) {
        return;
      }
      let isHangUp: boolean | undefined = AppStorage.get('hangUp');
      if (isHangUp) {
        LogUtils.i(TAG, 'it is already in hangup status, just ignore');
        return;
      }
      this.audioDeviceChangeInfo = audioDeviceInfo;
      AudioDeviceManager.getInstance().updateAudioDevice(audioDeviceInfo);
    })
  }

  unRegisterAudioChange(): void {
    try {
      AudioDeviceManager.getInstance().unRegisterAudioChange();
    } catch (err) {
      LogUtils.e(TAG, `unRegisterAudioChange err = ${JSON.stringify(err)}`);
    }
  }

  /**
   * 清除实况订阅标记
   */
  public clearNotifiesSubscribed(): void {
    this.mIsNotifiesSubscribed = false;
  }

  /**
   * 订阅系统实时视图通知
   */
  public addNotifiesSubscriber() {
    if (this.mIsNotifiesSubscribed) {
      return;
    }
    LogUtils.i(TAG, 'addNotifiesSubscriber start')

    let subscriber: notificationManager.SystemLiveViewSubscriber = {
      onResponse: (callId: number, option: notificationManager.ButtonOptions) => {
        let actionType = option.buttonName;
        LogUtils.i(TAG, 'addNotifiesSubscriber onResponseCallback: option' +
        JSON.stringify(option) + ' callId: ' + callId);
        this.onAction(actionType, callId);
      }
    }
    try {
      notificationManager.subscribeSystemLiveView(subscriber);
      this.mIsNotifiesSubscribed = true;
    } catch (error) {
      LogUtils.e(TAG, 'when subscribeSystemLiveView got exception: ' + JSON.stringify(error));
    }
  }

  /**
   * add callui app subscriber
   */
  // instrument ignore next
  async addSubscriber(): Promise<void> {
    LogUtils.i(TAG, 'addSubscriber');
    if (this.isEventSubscribed) {
      return;
    }
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: events,
      publisherPermission: 'ohos.permission.GET_TELEPHONY_STATE'
    };
    commonEventManager.createSubscriber(subscribeInfo).then((res) => {
      this.subscriber = res;
      try {
        LogUtils.i(TAG, 'subscribeBannerHideEvent subscribe');
        commonEventManager.subscribe(this.subscriber, (err, data) => {
          if ((err && err.code !== 0) || data === undefined) {
            LogUtils.i(TAG, 'addSubscriber commonEvent.subscribe failed err :' + JSON.stringify(err));
            return;
          }
          let event = data.event;
          LogUtils.i(TAG, 'subscribe event:' + JSON.stringify(event));
          switch (event) {
            case CALL_UI_CALL_CLICK:
              const callId: number = data.parameters?.callId;
              const btnType: string = data.parameters?.btnType;
              this.btnclickAgent(callId, btnType);
              break;
            case SCREEN_OFF_EVENT:
              this.screenOffEventManager();
              break;
            case SCREEN_ON_EVENT:
              this.screenOnEventManager();
              break;
            case BANNER_HIDE_EVENT:
              if (data.parameters !== undefined && data.parameters['window'] === WINDOW_TYPE_BANNER) {
                let isShow: boolean = data.parameters['isShow'];
                let id: string = data.parameters['id'];
                let creatorBundleName: string = data.parameters[CREATOR_BUNDLE_NAME];
                LogUtils.i(TAG, `isShow=${isShow} id=${id} bundle=${creatorBundleName} cLen=${this.callList.length}`);
                if (isShow === false && (creatorBundleName === Constants.CALL_BUNDLE_NAME ||
                  creatorBundleName === this.voipCallMap.get(parseInt(id))?.voipCallAttribute?.voipBundleName)) {
                  if ((this.callData?.callState === CallStateConst.CALL_STATUS_INCOMING ||
                    this.callData?.callState === CallStateConst.CALL_STATUS_WAITING) && this.callList.length < 2) {
                    CallServiceProxy.getInstance().muteRinger();
                  }
                  BannerNotificationManager.enableBannerNotification(false);
                }
              }
              break;
            default:
              break;
          }
        });
        this.isEventSubscribed = true;
      } catch (err) {
        LogUtils.e(TAG, 'subscribe err:' + err);
      }
    });
  }

  screenOffEventManager() {
    if ((this.callData?.callState === CallStateConst.CALL_STATUS_INCOMING ||
      this.callData?.callState === CallStateConst.CALL_STATUS_WAITING)) {
      let powerClickFlag: boolean | undefined = AppStorage.get('powerClickFlag');
      AppStorage.setOrCreate('powerClickFlag', !powerClickFlag);
      let callType: number = CallUtils.getUECallType(this.callData);
      ReportUtil.getInstance().reportClickPowerToScreenOff(callType);
    }
    if (this.callData && isVideoCall(this.callData.videoState as number)) {
      VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_VIDEO_PAUSED);
      setPreviewWindowApi(this.callData.callId, '');
    }
    AppStorage.setOrCreate('screenOff', true);
    NumberMarkManager.getInstance().completeNumberMark('screen off');
  }

  screenOnEventManager() {
    let isForeground: boolean = AppStorage.get('onPageShow') as boolean;
    let cameraStatus: number | undefined = AppStorage.get('cameraState');
    if (this.callData && isVideoCall(this.callData.videoState) &&
      isForeground && cameraStatus === VideoCameraHelper.CAMERA_STATE_OPEN) {
      VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_SEND_RECEIVE);
      LogUtils.i(TAG, 'addCallEventListener_setPreviewWindowApi');
      let surfaceId: string | undefined = AppStorage.get('surfaceId');
      setPreviewWindowApi(this.callData.callId, surfaceId);
    } else if (this.callData && isVideoCall(this.callData.videoState) &&
      cameraStatus === VideoCameraHelper.CAMERA_STATE_MANUAL_CLOSED) {
      VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_SEND_RECEIVE);
    }
    AppStorage.setOrCreate('screenOff', false);
    this.updateCallTime();
  }

  /**
   * click button agent
   *
   * @param { number } callId - call id
   * @param { string } btnType - button type
   */
  btnclickAgent(callId: number, btnType: string): void {
    LogUtils.i(TAG, 'btnclickAgent btnType :' + btnType);
    this.getMapObj(btnType, callId);
  }

  getMapObj(typeKey: string, callId: number): void {
    if (typeKey === CallStateConst.TEXT_INCOMING_CALL_ANSWER) {
      CallServiceProxy.getInstance()?.acceptCall(callId, false);
      if (this.callData) {
        this.startAbility(this.callData);
      }
    }
    if (typeKey === CallStateConst.TEXT_INCOMING_CALL_REJECT) {
      CallServiceProxy.getInstance()?.rejectCall(callId);
    }
    if (typeKey === CallStateConst.TEXT_IN_CALL_HANG_UP) {
      CallServiceProxy.getInstance()?.hangUpCall(callId);
    }
    this.bannerNotificationManager?.cancelNotification(callId);
  }

  onAction(actionType: string, actionId: number): void {
    let callData: DefaultCallData | undefined;
    if (actionId === ID) {
      callData = CallDataManager.getInstance().getForegroundCall();
    } else { // (actionId === VOIP_ID)
      callData = this.voipCallMap.get(actionId);
    }
    if (callData === undefined) {
      LogUtils.i(TAG, 'can not get callData, just ignore');
      return;
    }
    let callId = callData.callId;
    let isVoipCall = callData.callType === CallStateConst.TYPE_VOIP;
    if (actionType === CallStateConst.TEXT_INCOMING_CALL_ANSWER) {
      LogUtils.i(TAG, 'onAction answer call');
      this.callNotifiesFromSettingsData(callData);
      ReportUtil.getInstance().reportIsDualCardAnotherAnswer(callData.accountId);
    } else if (actionType === CallStateConst.TEXT_INCOMING_CALL_ANSWER_VIDEO) {
      this.onActionAnswerVideoCall(callData, actionId);
      ReportUtil.getInstance().reportNotifyBannerClickVideoAnswer(callData.callType);
    } else if (actionType === CallStateConst.TEXT_INCOMING_CALL_REJECT) {
      this.onActionRejectCall(callData);
    } else if (actionType === CallStateConst.TEXT_IN_CALL_HANG_UP) {
      if (!isVoipCall && CallDataManager.getInstance().callList.length === 1) {
        AppStorage.setOrCreate('hasBeenToFrontOrBackend', AppStorage.get('onPageShow'));
        AppStorage.setOrCreate('hangUp', true);
      }
      ReportUtil.getInstance().reportHangupCallSuccess(DisplayMode.BANNER);
      CallServiceProxy.getInstance().hangUpCall(callId);
      ReportUtil.getInstance().reportNotifyBarHangUp(CallUtils.getUECallType(callData));
      LogUtils.i(TAG, 'onAction hangup call');
    } else if (actionType === CallStateConst.TEXT_IN_CALL_MUTE) {
      if (isVoipCall && CallDataManager.getInstance().getForegroundLiveCall()) {
        LogUtils.i(TAG, 'there is live carrier call, ignore voip mute request');
        return;
      }
      CallServiceProxy.getInstance()?.setMuted();
      ReportUtil.getInstance()
        .reportNotifyBarMuteOrNot(Constants.UE_MUTE_STATE.MUTE, CallUtils.getUECallType(callData));
      LogUtils.i(TAG, 'onAction mute change');
    } else if (actionType === CallStateConst.TEXT_IN_CALL_UN_MUTE) {
      this.handleUnmuteAction(callData);
    } else if (actionType === CallStateConst.TEXT_IN_CALL_AUDIO_SPEAKER) {
      if (isVoipCall && CallDataManager.getInstance().getForegroundLiveCall()) {
        LogUtils.i(TAG, 'there is live carrier call, ignore voip speaker switch request');
        return;
      }
      LogUtils.i(TAG, 'onAction speaker switch');
      this.mBottomViewModel.setButtonAudioDevice(callData.callId, callData.callType, true);
    } else if (actionType === CallStateConst.TEXT_IN_CALL_UN_HOLD_ON) {
      LogUtils.i(TAG, 'onAction hold on switch');
      CallServiceProxy.getInstance()?.unHoldCall(callId);
    } else {
      LogUtils.i(TAG, 'onAction do nothing');
    }
  }

  private handleUnmuteAction(callData: DefaultCallData) {
    if (CallUtils.isVoipCall(callData)) {
      this.handleUnmuteActionOfVoipCall(callData);
      return;
    }
    this.cancelMuted(callData);
  }

  private handleUnmuteActionOfVoipCall(callData: DefaultCallData) {
    const hasMicPermission = callData.voipCallAttribute?.hasMicPermission;
    LogUtils.i(TAG, `hasMicPermission: ${hasMicPermission}`);
    if (CallDataManager.getInstance().getForegroundLiveCall()) {
      LogUtils.i(TAG, 'there is live carrier call, ignore voip unmute request');
      return;
    }
    if (!hasMicPermission) {
      this.handleUnmuteActionWhenNotHasMicPermission(callData);
      return;
    }
    this.cancelMuted(callData);
  }

  cancelMuted(callData: DefaultCallData) {
    let ueCallType = CallUtils.getUECallType(callData);
    CallServiceProxy.getInstance()?.cancelMuted();
    ReportUtil.getInstance().reportNotifyBarMuteOrNot(Constants.UE_MUTE_STATE.UNMUTE, ueCallType);
    LogUtils.i(TAG, 'onAction un-mute change');
  }

  // instrument ignore next
  private handleUnmuteActionWhenNotHasMicPermission(callData: DefaultCallData) {
    if (isScreenLocked()) {
      try {
        screenLock.unlock((err: BusinessError, isUnlock: boolean) => {
          LogUtils.i(TAG, `isUnlock: ${isUnlock}`)
          if (!isUnlock) {
            LogUtils.i(TAG, 'screen is locked');
            return;
          }
          this.startAbilityWhenUnlocked(callData);
        });
      } catch (exception) {
        LogUtils.e(TAG, `screen unlock failed, err: ${JSON.stringify(exception)}`);
      }
    } else {
      this.startAbilityWhenUnlocked(callData);
    }
  }

  private startAbilityWhenUnlocked(callData: DefaultCallData) {
    BannerNotificationManager.enableBannerNotification(false);
    this.bannerNotificationManager?.sendBannerNotification(callData);
    CallEventUtil.sendDropdownWindowEvent();
    this.startAbility(callData);
    this.cancelMuted(callData);
  }

  private answerVoipVideoCall(callData: DefaultCallData, actionId: number) {
    if (isScreenLocked()) {
      this.unlockAndAnswerVoipVideoCall(callData);
      return;
    }

    this.bannerNotificationManager?.sendBannerNotification(callData);
    if (this.canAnswerVoipCall(callData)) {
      CallServiceProxy.getInstance()?.acceptCall(callData.callId, true);
    }
    CallEventUtil.sendDropdownWindowEvent();
    this.startAbility(callData);
  }

  // instrument ignore next
  private unlockAndAnswerVoipVideoCall(callData: DefaultCallData) {
    try {
      screenLock.unlock((err: BusinessError, isUnlock: boolean) => {
        if (!isUnlock) {
          LogUtils.i(TAG, 'screen is locked');
          return;
        }

        LogUtils.i(TAG, 'screen is unlocked, now answer voip video');
        if (this.canAnswerVoipCall(callData)) {
          CallServiceProxy.getInstance()?.acceptCall(callData.callId, true);
        }

        CallEventUtil.sendDropdownWindowEvent();
        this.startAbility(callData);
      });
    } catch (exception) {
      LogUtils.e(TAG, 'screen is locked err :' + JSON.stringify(exception));
    }
  }

  private canAnswerVoipCall(callData: DefaultCallData) {
    return callData.voipCallAttribute && CallUtils.isSubProcessMode(callData.voipCallAttribute) ||
      callData.voipCallAttribute?.hasMicPermission;
  }

  private onActionAnswerVideoCall(callData: DefaultCallData, actionId: number) {
    LogUtils.i(TAG, 'onAction answer video call');
    let isSuperPrivacy: boolean | undefined = AppStorage.get('isSuperPrivacy');
    BannerNotificationManager.enableBannerNotification(false);
    if (callData.callType === CallStateConst.TYPE_VOIP) {
      this.answerVoipVideoCall(callData, actionId);
    } else {
      CallServiceProxy.getInstance()?.acceptCall(callData.callId, true);
      if (!isSuperPrivacy) {
        this.bannerNotificationManager?.sendBannerNotification(callData);
      }
      this.startAbility(callData);
    }
  }

  private onActionRejectCall(callData: DefaultCallData) {
    LogUtils.i(TAG, 'onAction reject call');
    if (callData.callType !== CallStateConst.TYPE_VOIP && CallDataManager.getInstance().callList.length === 1) {
      AppStorage.setOrCreate('hasBeenToFrontOrBackend', AppStorage.get('onPageShow'));
      AppStorage.setOrCreate('hangUp', true);
    }
    let playVideoModel: VideoController = VideoController.getInstance();
    playVideoModel?.releasePlay();
    CallServiceProxy.getInstance().rejectCall(callData.callId);
    ReportUtil.getInstance().reportIncomingDisplay(DisplayMode.BANNER, Constants.SUCCESS);
    ReportUtil.getInstance().reportNotifyBarReject(CallUtils.getUECallType(callData));
  }

  // Setting the display logic under the page banner
  private async callNotifiesFromSettingsData(callData: DefaultCallData) {
    const callList = CallDataManager.getInstance().callList;
    if (callList.length === 2 && !isVideoCall(callData.videoState)) {
      CallServiceProxy.getInstance()?.hangUpActiveCallWhenVoiceToVideoCall(callList);
    }
    if (callData.callType !== CallStateConst.TYPE_VOIP) {
      CallServiceProxy.getInstance().acceptCall(callData.callId, false);
      let isMapNavigation = await Utils.isMapNavigation();
      const patch: CallDataPatch = callDataPatcher.createPatch({
        callId: callData.callId,
        isMapNavigation: isMapNavigation
      })
      callDataPatcher.apply(callData, patch, 'add isMapNavigation');
      CallDataManager.getInstance().updateCallerInfo(patch);
    } else {
      this.answerVoipCall(callData);
    }
    ReportUtil.getInstance().reportIncomingDisplay(DisplayMode.BANNER, Constants.SUCCESS);
    ReportUtil.getInstance().reportNotifyBarAnswered(CallUtils.getUECallType(callData));
  }

  private handleBannerNotificationAndStartAbility(callData: DefaultCallData) {
    BannerNotificationManager.enableBannerNotification(false);
    this.bannerNotificationManager?.sendBannerNotification(callData);
    CallEventUtil.sendDropdownWindowEvent();
    this.startAbility(callData);
  }

  private answerVoipCall(callData: DefaultCallData) {
    let callId = callData.callId;
    let isConferenceCall = callData.voipCallAttribute?.isConferenceCall;
    let videoState = callData.videoState;
    let otherBundle = callData.voipCallAttribute?.voipBundleName === 'com.tencent.wechat';

    // 子进程
    if (callData.voipCallAttribute && CallUtils.isSubProcessMode(callData.voipCallAttribute)) {
      this.bannerNotificationManager?.cancelVoipNotification(this.callList, callId);
      CallServiceProxy.getInstance().acceptCall(callData.callId, false);
      this.startAbility(callData);
      return;
    }

    // 主进程，需要判断是否有麦克风权限
    if (callData.voipCallAttribute?.hasMicPermission) {
      const isOtherConferenceCall = !videoState && isConferenceCall && otherBundle;
      if (isOtherConferenceCall) {
        if (isScreenLocked()) {
          this.unlockAndAnswerVoipCall(callData, true)
          return;
        }
        this.handleBannerNotificationAndStartAbility(callData);
      } else {
        this.bannerNotificationManager?.cancelVoipNotification(this.callList, callId);
        this.sendVoipEvent(CallEventUtil.EVENT_SUCCESS, callData);
      }
      CallServiceProxy.getInstance().acceptCall(callData.callId, false);
    } else {
      if (isScreenLocked()) {
        this.unlockAndAnswerVoipCall(callData, false);
      } else {
        this.handleBannerNotificationAndStartAbility(callData);
      }
    }
  }

  private unlockAndAnswerVoipCall(callData: DefaultCallData, isStartAbility: boolean) {
    try {
      screenLock.unlock((err: BusinessError, isUnlock: boolean) => {
        if (!isUnlock) {
          LogUtils.i(TAG, 'screen is locked');
          return;
        }
        // 拉起界面后要直接接听
        if (isStartAbility) {
          BannerNotificationManager.enableBannerNotification(false);
          this.bannerNotificationManager?.sendBannerNotification(callData);
          CallServiceProxy.getInstance().acceptCall(callData.callId, false);
        }
        CallEventUtil.sendDropdownWindowEvent();
        this.startAbility(callData);
      });
    } catch (exception) {
      LogUtils.e(TAG, 'screen is locked err :' + JSON.stringify(exception));
    }
  }

  /**
   * add register listener
   */
  addRegisterListener(): void {
    this.addRegisterKeyChange();
    CallColumnUtils.getInstance().addDisplayChange();
    this.addNotifiesSubscriber();
    this.registerCallStateListener();
    this.getCallEventData();
    this.addOnCallSessionEvent();
    this.addImsCallModeChange();
    this.addPeerDimensionsChangeListener();
    this.addCoverModeChange();
  }

  addCoverModeChange() {
    try {
      if (!this.context) {
        return
      }
      settings.registerKeyObserver(this.context, Constants.COVER_WINDOW_SHOWING, settings.domainName.DEVICE_SHARED,
        (err, val) => {
          this.checkCoverMode();
          ProximityUtils.updateProximityLock();
        });
    } catch (error) {
      LogUtils.e(TAG, 'Error in Cover Mode Change');
    }
  }

  public getCoverModel() {
    return this.coverModel;
  }

  public setCoverModel(model: boolean) {
    this.coverModel = model;
  }

  checkCoverMode() {
    let coverModel = settings.getValue(this.context, Constants.COVER_WINDOW_SHOWING, settings.domainName.DEVICE_SHARED);
    coverModel.then((data: string) => {
      LogUtils.i(TAG, `cover model is ${data}`);
      this.setCoverModel(data === 'true');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `get cover model error：${err.code}`);
    })
  }

  addRegisterKeyChange() {
    this.checkScreenReaderState();
    try {
      settings.registerKeyObserver(this.context, Constants.ACCESSIBILITY_SCREEN_READER,
        settings.domainName.DEVICE_SHARED, () => {
          this.checkScreenReaderState();
        });
    } catch (error) {
      LogUtils.e(TAG, 'Error in registering key observer');
    }
  }

  checkScreenReaderState() {
    let str = settings.getValueSync(this.context, Constants.ACCESSIBILITY_SCREEN_READER, 'false');
    let screenReaderStatus = str === '1';
    AppStorage.setOrCreate('screenReaderStatus', screenReaderStatus);
    LogUtils.i(TAG, 'screenReaderStatus:' + JSON.stringify(screenReaderStatus));
  }

  private checkNumberIdentitySwitch(): boolean {
    return settings.getValueSync(this.context, Constants.NUMBER_IDENTITY_KEY, 'false') === ANTI_FRAUD_SWITCH_ON;
  }

  addPeerDimensionsChangeListener(): void {
    try {
      onPeerDimensionsChange((value: PeerDimensionsDetail) => {
        VideoCallManager.getInstance().handlePeerDimensionsChange(value);
      });
    } catch (error) {
      LogUtils.i(TAG, `addPeerDimensionsChangeListener error :${JSON.stringify(error)}`);
    }
  }

  addImsCallModeChange(): void {
    try {
      onImsCallModeChange(
        (imsCallModeInfo: ImsCallModeInfo) => {
          let updatedCall = CallDataManager.getInstance().callList.find(v => v.callId === imsCallModeInfo.callId);
          if (!updatedCall) {
            // Ignore if the updated call is not in call list
            return;
          }
          VideoCallManager.getInstance().handleImsCallModeChange(imsCallModeInfo, updatedCall);
          this.publishData(updatedCall);
        }
      )
    } catch (err) {
      LogUtils.i(TAG, `addImsCallModeChange error :${err?.code}`);
    }
  }

  addOnCallSessionEvent(): void {
    try {
      onCallSessionEvent(
        (data) => {
          VideoCallManager.getInstance().onCallSessionEvent(data);
        }
      )
    } catch (err) {
      LogUtils.i(TAG, `addOnCallSessionEvent error :${err?.code}`);
    }
  }

  private async handleStartAbilityCase(callData: DefaultCallData) {
    if (callData.callType === CallStateConst.TYPE_VOIP) {
      return;
    }
    let call = getCallById(CallDataManager.getInstance().callList, callData.callId);
    if (call) {
      callData = call;
    }
    await this.getVisionGlassDisplayId(callData);
    if (CallDataManager.getInstance().hasAnyAliveCall()) {
      this.startAbility();
    } else if (callData.callState === CallStateConst.CALL_STATUS_DIALING) {
      if (AppStorage.get<boolean>('isDistributeSource') &&
        callData.extraParams?.['isDistributedDeviceDialing'] &&
        callData.extraParams?.['isDistributedDeviceDialing'] === 'true') {
        LogUtils.i(TAG, 'DistributedDeviceDialing is true!');
        BannerNotificationManager.enableBannerNotification(false);
        this.bannerNotificationManager?.sendBannerNotification(callData, true);
      } else {
        this.bannerNotificationManager?.setIsStartingAbility(true);
        this.bannerNotificationManager?.setReady(true);
        // outgoing call first using the full screen dialing
        this.startAbility();
      }
      ReportUtil.getInstance().reportDualCallPoint(callData);
    } else {
      this.startBannerOrAbility(callData);
    }
    if (CallDataManager.getInstance().hasAliveCall() && ExternalCallModel.getInstance().isSmallExternalAndFolded()) {
      this.startExternalAbility();
    }
  }

  /**
   * get callData
   *
   * @param { Object } callData - Object
   */
  getCallData(callData: DefaultCallData): void {
    hiTraceMeter.startTrace('getCallData', 1456);
    const callId: number = callData.callId;
    const newState: number = callData.callState;
    const blockReason = callData.extraParams?.['blockReason'];
    if (blockReason == REPEAT_CALL_NOT_BLOCK_REASON_ID && newState === CallStateConst.CALL_STATUS_INCOMING) {
      LogUtils.i(TAG, `getCallData: blockReason: ${blockReason}`);
      ReportUtil.getInstance().reportCallBlockReason(Number(blockReason));
    }
    if (newState === CallStateConst.CALL_STATUS_ACTIVE) {
      callData.isAnswered = true;
    }
    TimeOutManager.getInstance().answeredTimeOutListener(callData);
    if (newState === CallStateConst.callStateObj.CALL_STATUS_ANSWER && !CallUtils.isVoipCall(callData)) {
      if (!ProximityUtils.isInfraredProximitySensor()) {
        ProximityUtils.updateProximityLock(callData);
      }
      if (AppStorage.get<boolean>('isDistributeSource')) {
        this.isAnsweredByPhone = true;
      }
      let callList = CallDataManager.getInstance().callList;
      if (callList?.length > 1 || !AppStorage.get<boolean>('isSupportAnswerStatus')) {
        AppStorage.setOrCreate('isStartAutoAnswerService', false);
        return;
      }
    }
    const targetObj = this.getCallDataByCallId(callId);
    let oldState: number = -1;
    if (targetObj) {
      oldState = targetObj.callState;
      LogUtils.i(TAG, 'getCallData: CallStateChange: ' + oldState + ' => ' + newState + ', id: ' + callId);
      const numberLocation = callData.numberLocation;
      const markContent = callData.numberMarkInfo.markContent;
      if ((targetObj.numberLocation === '' && numberLocation !== '') ||
        (targetObj.numberMarkInfo.markContent === '' && markContent !== '')) {
        LogUtils.i(TAG, 'need update numberLocation');
        this.updateCallList(callData);
        this.automateFunctions(callData, oldState);
        return;
      }
      ReportUtil.getInstance().reportCallInActive(callData, oldState, newState);
      this.handleCallVibration(callData, oldState, newState);
    }
    if (this.bannerNotificationManager?.isHeadUpEnabled(CallUtils.isVoipCall(callData)) && this.callData &&
      this.callData.callId === callData.callId && !shouldShowVideoRing(this.callData) &&
    shouldShowVideoRing(callData) && VideoController.getInstance().getAvPlayerState() !== aVPlayerStatePlaying) {
      this.playingVideoRing(callData);
    }

    // 查询号码标记信息：呼入和呼出通话都需要查询
    // 呼出通话包括 DIALING 和 ALERTING 状态
    // DISCONNECTED 状态下也需要查询，因为系统 API 返回的数据中不包含应用层标记信息
    if (callData.callState === CallStateConst.CALL_STATUS_INCOMING || 
        callData.callState === CallStateConst.CALL_STATUS_DIALING ||
        callData.callState === CallStateConst.CALL_STATUS_ALERTING ||
        callData.callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
      // 判断当前是否有有效标记 (-1 通常代表无标记) 或者标记内容为空
      if (!callData.numberMarkInfo || (callData.numberMarkInfo.markType as number) === -1 ||
          !callData.numberMarkInfo.markContent || callData.numberMarkInfo.markContent === '') {

        const callTypeStr = callData.callState === CallStateConst.CALL_STATUS_INCOMING ? 'incoming' : 
                           (callData.callState === CallStateConst.CALL_STATUS_DIALING ? 'outgoing(dialing)' : 
                           (callData.callState === CallStateConst.CALL_STATUS_ALERTING ? 'outgoing(alerting)' : 'disconnected'));
        LogUtils.i(TAG, `[AutoQuery] No mark for ${callTypeStr} call ${callData.accountNumber}. Querying...`);

        if (!this.context) {
          return
        }
        getNumberMarkInfoTask(this.context, callData.accountNumber).then((res) => {
          LogUtils.i(TAG, `[AutoQuery] Result: ${JSON.stringify(res)}`);

          if (res && res.markType && res.markType !== '0') {
            if (!this.context) {
              LogUtils.i(TAG,'!this.context')
              return
            }
            // 1. 获取最新的 callData 对象（防止在此期间电话挂断了）
            let currentCall = this.getCallDataByCallId(callData.callId);
            if (currentCall) {
              LogUtils.i(TAG, `[AutoQuery] Updating call list with mark info: markType=${res.markType}, markContent=${res.markContent}`);

              // 2. 类型转换与赋值 (注意 String 转 Number)
              // 优先使用从数据库查询到的 markContent，如果为空则使用资源文件中的默认值
              currentCall.numberMarkInfo.markType = parseInt(res.markType as string);
              currentCall.numberMarkInfo.markContent = res.markContent && res.markContent !== '' ? 
                res.markContent : NumberMarkUtil.getNumberMarkInfo(this.context, res.markType as string);
              currentCall.numberMarkInfo.markCount = res.markCount as number;
              currentCall.numberMarkInfo.markSource = res.markSource;
              currentCall.numberMarkInfo.isCloud = res.isCloud;
              currentCall.numberMarkInfo.markDetails = res.markDetails;

              LogUtils.i(TAG, `[AutoQuery] After update: markType=${currentCall.numberMarkInfo.markType}, markContent=${currentCall.numberMarkInfo.markContent}`);

              this.updateCallList(currentCall);
              
              // 3. 如果当前通话就是查询的通话，更新 this.callData 以触发界面刷新
              if (this.callData && this.callData.callId === currentCall.callId) {
                this.setCallData(currentCall.callState, currentCall);
              }
            } else {
              LogUtils.w(TAG, `[AutoQuery] Call ${callData.callId} not found, may be disconnected`);
            }
          } else {
            LogUtils.i(TAG, `[AutoQuery] No mark data found in DB.`);
          }
        }).catch((err:BusinessError) => {
          LogUtils.e(TAG, `[AutoQuery] Failed: ${JSON.stringify(err)}`);
        })
      }
    }

    this.setCallData(newState, callData);
    this.updateCallList(callData);
    const callState: number = callData.callState;
    // single call or dialing pull up the application
    let isStartAbility: boolean = (oldState !== newState) && ((callState === CallStateConst.CALL_STATUS_INCOMING) ||
      (callState === CallStateConst.CALL_STATUS_WAITING) || (callState === CallStateConst.CALL_STATUS_DIALING)) ||
      (oldState === -1 && callState !== CallStateConst.CALL_STATUS_DISCONNECTED);
    if ((isStartAbility &&
      (CallUtils.isSosWithOutCallUiAbility(callData) !== CallUtilsClass.HIDE_CALL_PAGE_WHEN_SOS_CALL)) ||
      CallUtils.isSosWithOutCallUiAbility(callData) === CallUtilsClass.DISPLAY_CURRENT_CALL_PAGE) {
      LogUtils.i(TAG, 'handleStartAbilityCase:');
      this.handleStartAbilityCase(callData);
    } else if (callState !== CallStateConst.CALL_STATUS_DISCONNECTING) {
      this.updateCallDataIfPossible(callData);
    }
    let callCountResult: CallListStruct = this.getCallCount();
    try {
      if (callCountResult.callCount === 1 && oldState === CallStateConst.CALL_STATUS_ACTIVE && callData.callState ===
      CallStateConst.CALL_STATUS_DISCONNECTING && !isScreenLocked()) {
        let bannerImport = import('../common/utils/Banner');
        bannerImport.then((banner) => {
          banner.default.getInstance().jumpToBannerGuide();
        });
      }
    } catch (exception) {
      LogUtils.e(TAG, 'screenLock isLocked catch err:' + JSON.stringify(exception));
    }

    if ((oldState === CallStateConst.CALL_STATUS_INCOMING || oldState === CallStateConst.CALL_STATUS_WAITING) &&
      callState === CallStateConst.CALL_STATUS_ACTIVE) {
      let callObj = getCallById(CallDataManager.getInstance().callList, callData.callId);
      if (callObj?.isMapNavigation) {
        setTimeout(async () => {
          LogUtils.i(TAG, 'call active isMapNavigation: ' + callObj!.isMapNavigation);
          callObj!.isMapNavigation = await Utils.isMapNavigation();
          if (callObj!.isMapNavigation) {
            this.mBottomViewModel.setMapNavigationAudioDevice();
          }
        }, 0);
      }
      ReportUtil.getInstance().reportPrivacyIndicator();
    }
    this.automateFunctions(callData, oldState);
    if (AppStorage.get<boolean>('isDistributeSource') && !this.isAnsweredByPhone &&
      oldState === CallStateConst.CALL_STATUS_INCOMING && newState === CallStateConst.CALL_STATUS_ACTIVE) {
      let mainAbility =
        GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT);
      if (mainAbility && !mainAbility.isTerminating()) {
        LogUtils.i(TAG, 'getCallData: minimize by distribute source ');
        ProximityUtils.minimize();
      }
      this.isAnsweredByPhone = false;
    }
    /**
     * 1.oldState等于incoming并且newState不等于incoming（排除同一路来电多次上报incoming的场景）
     * 2.双卡同时来电（两路同时上报incoming），如果已经有计时器，则清除计时器，否则设置标记位，标记不自动接听
     */
    if ((oldState === CallStateConst.CALL_STATUS_INCOMING && newState !== CallStateConst.CALL_STATUS_INCOMING) ||
      (this.callList.length > 1 && newState === CallStateConst.CALL_STATUS_INCOMING)) {
      AppStorage.setOrCreate('isStartAutoAnswerService', false);
    }
    if (!CallDataManager.getInstance().hasIncomingCall()) {
      VideoController.getInstance()?.releasePlayAnyway();
    }
    hiTraceMeter.finishTrace('getCallData', 1456);
  }

  private async automateFunctions(callData: DefaultCallData, oldState: number) {
    await this.autoRecord(callData, oldState);
  }

  async playingVideoRing(callData: DefaultCallData) {
    let ringFd: number = await getVideoRingPath(callData);
    LogUtils.i(TAG, 'playingVideoRing playVideoByUrl is called, ringFd = ' + ringFd);
    if (ringFd !== Constants.INVALID_NUM) {
      let playVideoModel: VideoController = VideoController.getInstance();
      playVideoModel?.playVideoByFd(ringFd, CallUtils.isDoNotDisturb(callData), callData.accountId);
    } else {
      try {
        LogUtils.i(TAG, 'playingVideoRing, invalid video fd, play default ringing');
        call.sendCallUiEvent(callData.callId, 'EVENT_INVALID_VIDEO_FD');
      } catch (err) {
        LogUtils.e(TAG, `playingVideoRing, send callui event fail: ${err.code}`);
      }
    }
  }

  handleCallVibration(callData: DefaultCallData, oldState: number, newState: number) {
    if (callData.callType === CallStateConst.TYPE_VOIP) {
      return;
    }
    let newStateFlag: boolean = newState === CallStateConst.CALL_STATUS_DISCONNECTED ||
      newState === CallStateConst.CALL_STATUS_DISCONNECTING;
    let oldStateFlag: boolean = oldState === CallStateConst.CALL_STATUS_ACTIVE ||
      oldState === CallStateConst.CALL_STATUS_HOLDING || oldState === CallStateConst.CALL_STATUS_ALERTING;
    if (newStateFlag && oldStateFlag && !AppStorage.get<boolean>('hangUp')) {
      VibrationUtils.getInstance().getRingerMode((value: audio.AudioRingMode) => {
        if (value !== audio.AudioRingMode.RINGER_MODE_NORMAL) {
          VibrationUtils.getInstance().onceVibration();
        }
      })
    }
    if ((oldState === CallStateConst.CALL_STATUS_DIALING || oldState === CallStateConst.CALL_STATUS_ALERTING) &&
      newState === CallStateConst.CALL_STATUS_ACTIVE) {
      VibrationUtils.getInstance().onceVibration();
      ExternalCallModel.getInstance().showVideoTipsDialog();
    }
  }

  private setCallData(newState: number, callData: DefaultCallData): void {
    if (callData.callType == CallStateConst.TYPE_VOIP) {
      if (newState === CallStateConst.CALL_STATUS_DISCONNECTED) {
        this.voipCallMap.remove(callData.callId);
      } else {
        this.voipCallMap.set(callData.callId, callData);
      }
    } else {
      if (newState === CallStateConst.CALL_STATUS_ACTIVE) {
        // GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.VOIP_ABILITY_CONTEXT)?.
        // terminateSelf().then(() => {
        //   LogUtils.i(TAG, 'calluiAbility terminateSelf because call answer');
        // });
      }
      this.callData = callData;
    }
  }

  /**
   * start or stop record on new CallData
   * @param newCallData new CallData
   * @param exCallData ex CallData
   */
  async autoRecord(newCallData: DefaultCallData, exCallState: number) {
    if (newCallData.callType === CallStateConst.TYPE_VOIP) {
      LogUtils.i(TAG, 'TYPE_VOIP call not record');
      return;
    }
    if (newCallData.callState === CallStateConst.CALL_STATUS_ACTIVE && !AppStorage.get<boolean>('recorderFirstInit')) {
      let isError: boolean = await Recording.getInstance().recordingGetIsError();
      LogUtils.i(TAG, 'autoRecord is error' + isError);
      if (isError) {
        return;
      }
    }
    if (AppStorage.get<string>('recorderStatus') !== undefined && AppStorage.get<string>('recorderStatus') ===
      RECORDER_DISABLED_STATUS) {
      LogUtils.i(TAG, 'status change recorder disabled');
      return;
    }
    LogUtils.i(TAG, 'no error continue start');
    let recordCallId: number = Recording.getInstance().getRecordCallId();
    let isRecordCall: boolean = recordCallId === newCallData.callId;
    LogUtils.i(TAG, `autoRecord: ${recordCallId}, ${newCallData.callId}`);
    if ((newCallData.callState === CallStateConst.CALL_STATUS_ACTIVE &&
      exCallState === CallStateConst.CALL_STATUS_HOLDING) ||
      (newCallData.callState === CallStateConst.CALL_STATUS_HOLDING &&
        exCallState === CallStateConst.CALL_STATUS_ACTIVE)) {
      Recording.getInstance().changeRecorderStatus();
    } else if (isRecordCall && newCallData.callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
      this.autoStopRecord(newCallData);
    } else if (!isRecordCall && newCallData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      this.autoStartRecord(newCallData, exCallState);
    }
  }

  autoStartRecord(newCallData: DefaultCallData, exCallState: number) {
    if (exCallState !== CallStateConst.CALL_STATUS_ALERTING && exCallState !== CallStateConst.CALL_STATUS_DIALING &&
      exCallState !== CallStateConst.CALL_STATUS_INCOMING && exCallState !== CallStateConst.CALL_STATUS_WAITING &&
      exCallState !== CallStateConst.CALL_STATUS_ANSWER) {
      LogUtils.i(TAG, `autoStartRecord fail exCallState=${exCallState}`);
      return;
    }
    let callCountResult: CallListStruct = this.getCallCount();
    if (callCountResult.callCount > 1) {
      Recording.getInstance().autoStartAnotherRecord(newCallData);
      return;
    }
    let recorderStatus: boolean = AppStorage.get<string>('recorderStatus') === RECORDER_START_STATUS;
    if (recorderStatus) {
      LogUtils.i(TAG, `autoStartRecord fail, now is started`);
      return;
    }
    let call = getCallById(CallDataManager.getInstance().callList, newCallData.callId);
    if (call) {
      newCallData = call;
    }
    let fileNameStr: string = fileNameString(newCallData);
    let sendParams: RecordInputData = {
      callId: newCallData.callId,
      accountNumber: newCallData.accountNumber.toString(),
      mode: IdlServiceExtProxy.RECORDING_MANUAL,
      startTime: newCallData.startTime,
      fileNameStr: fileNameStr
    };
    Recording.getInstance().isDesignateNumber(sendParams);
  }

  autoStopRecord(newCallData: DefaultCallData) {
    Recording.getInstance().autoStopById(newCallData.callId);
  }

  getCallCount() {
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
    let result: CallListStruct = {
      callCount: callCount,
      hasConference: hasConference
    }
    return result;
  }

  /**
   * service disconnected
   *
   * @return void
   */
  public onDisconnected(): void {
    Recording.getInstance().recordingStop(RECORDER_STOP_STATUS);
    this.removeRegisterListener();
    if (this.callData === undefined || (this.callData !== undefined && this.callData.callState === 6)) {
      return;
    }
    this.callData!.callState = CallStateConst.CALL_STATUS_DISCONNECTED;
    CallDataManager.getInstance().disconnectClearInfo();
    this.clearData();
  }

  startBannerOrAbility(callData: DefaultCallData): void {
    BannerNotificationManager.isStartCallNotifies(callData,
      async (isStartCallNotifiesStatus: boolean) => {
        LogUtils.i(TAG, 'startBannerOrAbility isStartCallNotifiesStatus ' + JSON.stringify(isStartCallNotifiesStatus));
        this.bannerNotificationManager?.setReady(true);
        if (isStartCallNotifiesStatus) {
          if (this.bannerNotificationManager?.isHeadUpEnabled(false) && shouldShowVideoRing(callData)) {
            this.playingVideoRing(callData);
          }
          CallFaultEventUtil.getInstance().startCallBannerNotification();
          this.bannerNotificationManager?.sendBannerNotification(callData, true);
        } else {
          BannerNotificationManager.enableBannerNotification(false);
          CallFaultEventUtil.getInstance().startCallFullScreen(callData);
          this.bannerNotificationManager?.setIsStartingAbility(true);
          this.startAbility(callData);
        }
      });
  }

  /**
   * start ability
   *
   * @param { Object } callData - Object
   */
  startAbility(callData?: DefaultCallData): void {
    let want: Want = this.generateWantAgent(callData);
    if (callData?.callType !== CallStateConst.TYPE_VOIP) {
      this.startUIAbility(want);
      if (callData === undefined) {
        const timer = setTimeout(() => {
          // this.startUIAbilityInHiCar();
          clearTimeout(timer);
        }, 100);
      }
      return;
    }
    if (this.currentVoipCallId == undefined || callData?.voipCallAttribute?.extensionId === '') {
      this.startUIAbility(want, callData);
    } else {
      AppStorage.setOrCreate('callData', callData);
    }
    this.currentVoipCallId = callData?.callId;
  }

  /**
   * 获取眼镜displayId，如果没有连接眼镜或者连接眼镜时通过手机界面打电话，返回默认的displayId，否则，返回眼镜displayId。
   * @returns
   */
  public getVisionGlassDisplayId(callData?: DefaultCallData): Promise<number> {
    return new Promise<number>((resolve) => {
      // 获取默认屏幕对象
      try {
        let defaultDisplay: display.Display = display.getDefaultDisplaySync();
        if (callData?.callState === CallStateConst.CALL_STATUS_DIALING &&
          callData?.extraParams?.['dialByGlass'] !== true) {
          LogUtils.i(TAG, 'dialByGlass is undefined');
          AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, false);
          AppStorage.setOrCreate(VisionGlassConstants.SHOW_IN_VISION_GLASS, false);
          resolve(defaultDisplay?.id);
          return;
        }
        if (!this.isHaveVisionGlass()) {
          AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, false);
          AppStorage.setOrCreate(VisionGlassConstants.SHOW_IN_VISION_GLASS, false);
          resolve(defaultDisplay?.id);
          return;
        }
        display.getAllDisplays((err: BusinessError, data: Array<display.Display>) => {
          if (err.code) {
            LogUtils.e(TAG, 'getAllDisplays wrong');
            AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, false);
            AppStorage.setOrCreate(VisionGlassConstants.SHOW_IN_VISION_GLASS, false);
            resolve(defaultDisplay?.id);
            return;
          }
          let glassDisplay = data?.find((item) => item.id === 1);
          if (glassDisplay === undefined) {
            AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, false);
            AppStorage.setOrCreate(VisionGlassConstants.SHOW_IN_VISION_GLASS, false);
            LogUtils.i(TAG, 'glassDisplay undefined');
            resolve(defaultDisplay?.id);
            return;
          }
          LogUtils.i(TAG, 'VisionGlass is connected.');
          AppStorage.setOrCreate(VisionGlassConstants.CONNECT_VISION_GLASS, true);
          resolve(glassDisplay?.id);
          return;
        });
      } catch (error) {
        LogUtils.e(TAG, `get default display error:${JSON.stringify(error)}`);
      }
    })
  }

  /**
   * 通过usb判断是否有眼镜连接，如果没有连接眼镜返回false，反之返回true。
   * @returns
   */
  private isHaveVisionGlass(): boolean {
    try {
      let usbDevices: usbManager.USBDevice[] = usbManager.getDevices();
      if (!usbDevices?.length) {
        LogUtils.w(TAG, 'no usbDevices.');
        return false;
      }
      let usbDevice: usbManager.USBDevice | undefined =
        usbDevices?.find(device => device.vendorId.toString() === VisionGlassConstants.VISION_GLASS_VENDOR_ID &&
          device.productId.toString() === VisionGlassConstants.VISION_GLASS_PRODUCT_ID)
      if (usbDevice === undefined) {
        LogUtils.w(TAG, 'no usbDevice.');
        return false;
      }
      return true;
    } catch (err) {
      LogUtils.e(TAG, `usb wrong :${err.stack}+${err.message}`);
      return false;
    }
  }

  private startUIAbility(want: Want, callData?: DefaultCallData) {
    let displayId = Number(AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS));
    this.context?.startAbility(want, {
      displayId: displayId
    }).then(() => {
      LogUtils.i(TAG, 'callUI service startAbility done');
      if (callData?.callType === CallStateConst.TYPE_VOIP) {
        LogUtils.i(TAG, 'ready to send voip event')
        this.sendVoipEvent(CallEventUtil.EVENT_SUCCESS, callData);
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'callUI service startAbility err :' + JSON.stringify(err));
      if (callData?.callType === CallStateConst.TYPE_VOIP) {
        this.sendVoipEvent(CallEventUtil.EVENT_FAIL, callData);
      }
      CallFaultEventUtil.getInstance().startAbilityErrorEvent(err.code);
    });
  }

  startExternalAbility(): void {
    let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
    if (callData === undefined) {
      LogUtils.e(TAG, 'external call data is undefined');
      return;
    }
    IncomingComVM.getInstance().initData(callData, CallDataManager.getInstance().callList);
    let externalContext =
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.EXTERNAL_CALL_ABILITY_CONTEXT);
    let isExternalCtxValid = (externalContext && !externalContext.isTerminating());
    let isInBackground: boolean =
      ExternalCallModel.isSmallExternalDevice() && ExternalCallModel.getInstance().mIsExternalBackground;
    LogUtils.i(TAG, `startExternalAbility contextValid:${isExternalCtxValid} isInBackground:${isInBackground}`);
    if (isExternalCtxValid) {
      ExternalCallModel.getInstance().showVideoTipsDialog();
    }
    if (!isExternalCtxValid || isInBackground) {
      let want: Want = {
        bundleName: CALL_BUNDLE_NAME,
        abilityName: ABILITY_NAME_EXTERNAL,
        parameters: {
          'ability.params.backToOtherMissionStack': true,
        }
      };
      let options: StartOptions = {
        displayId: Constants.SMALL_EXTERNAL_DISPLAY_ID
      };
      this.context?.startAbility(want, options).then(() => {
        LogUtils.i(TAG, 'callUI service startExternalAbility done');
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'callUI service startExternalAbility err :' + JSON.stringify(err));
      });
    }
  }

  public generateWantAgent(callData?: DefaultCallData) {
    let want: Want = {
      bundleName: Constants.CALL_BUNDLE_NAME,
      abilityName: Constants.CALL_ABILITY_NAME,
      parameters: {
        'ability.params.backToOtherMissionStack': true,
      }
    };
    if (callData?.callType !== CallStateConst.TYPE_VOIP) {
      return want;
    }

    return this.generateVoipWantAgent(want, callData);
  }

  private generateVoipWantAgent(want: Want, callData: DefaultCallData): Want {
    LogUtils.i(TAG, 'generateWantAgent in voip call ');

    if (callData?.voipCallAttribute?.extensionId == '') {
      want.bundleName = callData?.voipCallAttribute?.voipBundleName;
      want.abilityName = callData?.voipCallAttribute?.abilityName;
      if (want.parameters !== undefined) {
        want.parameters.VoIPCallId = callData?.voipCallAttribute?.voipCallId;
        want.parameters.isFromCallKit = true;
        want.parameters['ohos.extra.param.key.appCloneIndex'] = callData?.voipCallAttribute?.appIndex;
      }
    } else {
      want.bundleName = Constants.CALL_BUNDLE_NAME;
      want.abilityName = Constants.CALL_ABILITY_NAME_VOIP;
      if (want.parameters !== undefined) {
        want.parameters.callData = callData;
      }
    }

    return want;
  }

  /**
   * update callList
   */
  updateCallList(callData: DefaultCallData): void {
    const callId: number = callData?.callId!;
    const callState: number = callData?.callState!;
    const targetObj = this.callList.find((v) => v.callId === callId);
    let newCallData: DefaultCallData = new DefaultCallData();
    if (targetObj) {
      // 保护标记信息：如果旧的 targetObj 有有效的标记信息，而新的 callData 没有或标记无效，则保留旧的标记
      const hasOldMark = targetObj.numberMarkInfo && 
                         (targetObj.numberMarkInfo.markType as number) !== -1 && 
                         (targetObj.numberMarkInfo.markType as number) !== 0 &&
                         targetObj.numberMarkInfo.markContent && 
                         targetObj.numberMarkInfo.markContent !== '';
      
      // 检查新的 callData 是否有有效的标记信息（包括检查 numberMarkInfo 是否为 undefined）
      const hasNewMark = callData.numberMarkInfo && 
                         (callData.numberMarkInfo.markType as number) !== -1 && 
                         (callData.numberMarkInfo.markType as number) !== 0 &&
                         callData.numberMarkInfo.markContent && 
                         callData.numberMarkInfo.markContent !== '';
      
      if (hasOldMark && !hasNewMark) {
        LogUtils.i(TAG, `[Protect] Preserving local mark info: markType=${targetObj.numberMarkInfo.markType}, content=${targetObj.numberMarkInfo.markContent}, newMarkType=${callData.numberMarkInfo?.markType}, newMarkContent=${callData.numberMarkInfo?.markContent}`);

        // 确保 callData.numberMarkInfo 存在
        if (!callData.numberMarkInfo) {
          callData.numberMarkInfo = { markContent: '', markType: -1, markCount: -1 };
        }
        
        // 把本地的标记信息，强制赋值给新来的数据包,这样下面合并的时候，就会保留归属地(新的) + 标记(旧的)
        callData.numberMarkInfo.markType = targetObj.numberMarkInfo.markType;
        callData.numberMarkInfo.markContent = targetObj.numberMarkInfo.markContent;
        callData.numberMarkInfo.markCount = targetObj.numberMarkInfo.markCount;
        callData.numberMarkInfo.markSource = targetObj.numberMarkInfo.markSource;
        callData.numberMarkInfo.isCloud = targetObj.numberMarkInfo.isCloud;
        callData.numberMarkInfo.markDetails = targetObj.numberMarkInfo.markDetails;
      }

      LogUtils.i(TAG, `[Debug] Update Call: ID=${callId}`);
      LogUtils.i(TAG, `[Debug] Old State: ${targetObj.callState}, New State: ${callData.callState}`);
      Method.assign(newCallData, targetObj);
      if (targetObj.callType === CallStateConst.TYPE_VOIP) {
        Method.assign(newCallData, callData);
        let voipCallAttribute: VoipCallAttribute = new VoipCallAttribute();
        Method.assign(voipCallAttribute, targetObj.voipCallAttribute);
        Method.assign(voipCallAttribute, callData.voipCallAttribute);
        newCallData.voipCallAttribute = voipCallAttribute;
        targetObj.voipCallAttribute!.isExpired = true;
        ProximityUtils.updateProximityLock(newCallData);
      } else {
        Method.assign(newCallData, callData);
      }
      
      // 在 Method.assign 之后，再次保护标记信息，确保不会被覆盖
      if (hasOldMark && !hasNewMark) {
        LogUtils.i(TAG, `[Protect] After assign, preserving mark info: markType=${targetObj.numberMarkInfo.markType}, content=${targetObj.numberMarkInfo.markContent}`);
        if (!newCallData.numberMarkInfo) {
          newCallData.numberMarkInfo = { markContent: '', markType: -1, markCount: -1 };
        }
        newCallData.numberMarkInfo.markType = targetObj.numberMarkInfo.markType;
        newCallData.numberMarkInfo.markContent = targetObj.numberMarkInfo.markContent;
        newCallData.numberMarkInfo.markCount = targetObj.numberMarkInfo.markCount;
        newCallData.numberMarkInfo.markSource = targetObj.numberMarkInfo.markSource;
        newCallData.numberMarkInfo.isCloud = targetObj.numberMarkInfo.isCloud;
        newCallData.numberMarkInfo.markDetails = targetObj.numberMarkInfo.markDetails;
      }
      
      this.callList[this.callList.findIndex((v) => v.callId === callId)] = newCallData;
    } else {
      Method.assign(newCallData, callData);
      this.callList.push(newCallData);
      if (this.callList.length == 1) {
        LogUtils.i(TAG, 'need register audio change');
        this.registerAudioChange();
        if (AppStorage.has('isLeatherManagerRequestSCB') === false) {
          LeatherManager.requestSCB('addAppCoverItemView')
        }
      }
    }
    if (callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
      const index = this.callList.findIndex((v) => v.callId === callId);
      this.callList.splice(index, 1);
      if (this.callList.length == 0) {
        LogUtils.i(TAG, 'need unregister audio change');
        this.unRegisterAudioChange();
        if (AppStorage.get('isLeatherManagerRequestSCB') === true) {
          if (AppStorage.has('isLeatherManagerRequestSCB')) {
            AppStorage.delete('isLeatherManagerRequestSCB');
          }
          let leatherPreferencesOptions: preferences.Options = { name: 'LeatherPagePreferences' };
          preferences.deletePreferences(this.context, leatherPreferencesOptions, (err: BusinessError) => {
            LeatherManager.requestSCB('removeAppCoverItemView');
            if (err) {
              LogUtils.e(TAG, 'deletePreferences error');
            }
          })
        }
      }
    }
    if (callState !== CallStateConst.CALL_STATUS_DISCONNECTING) {
      if (newCallData.callType === CallStateConst.TYPE_VOIP) {
        this.publishData(newCallData);
        new ContactsData().reportIncomingOrOutgoingCallInfo(newCallData);
      } else {
        this.publishData(callData);
      }
    }
    if ((AppStorage.get<boolean>('isDistributeSource') ?? false)) {
      AudioDeviceManager.getInstance().updateAudioDevice(this.audioDeviceChangeInfo);
    }
  }

  /**
   * update audio for voip call
   */
  updateAudioForVoipCall(callData: DefaultCallData): void {
    const callId: number = callData?.callId!;
    const targetObj = this.callList.find((v) => v.callId === callId);
    let newCallData: DefaultCallData = new DefaultCallData();
    if (targetObj) {
      Method.assign(newCallData, targetObj);
      let voipCallAttribute: VoipCallAttribute = new VoipCallAttribute();
      Method.assign(voipCallAttribute, targetObj.voipCallAttribute);
      newCallData.voipCallAttribute = voipCallAttribute;
      targetObj.voipCallAttribute!.isExpired = true;
      this.callList[this.callList.findIndex((v) => v.callId === callId)] = newCallData;
      BannerNotificationManager.getInstance().sendBannerNotification(newCallData);
      ProximityUtils.updateProximityLock(newCallData);
    }
  }

  /**
   * update callTime
   */
  async updateCallTime() {
    let onPageShow: boolean | undefined = AppStorage.get('onPageShow');
    let onExternalPageShow: boolean | undefined = AppStorage.get('onExternalPageShow');
    const onHiCarPageShow: boolean = HiCarManager.getInstance().getIsHiCarPageShow();
    if (onPageShow || onExternalPageShow || onHiCarPageShow) {
      LogUtils.i(TAG, 'screenOn updateCallTime');
      CallDataManager.getInstance().refreshCallTime();
    }
  }

  /**
   * commonEvent publish data
   *
   * @param { Object } callData - Object
   */
  publishData(callData: DefaultCallData): void {
    if (!callData) {
      LogUtils.w(TAG, 'Trying to publish an invalid data!');
      return;
    }

    LogUtils.i(TAG, 'publishData: ' + callDataToSafeString(callData));
    CallManager.getInstance().update(callData, this.currentVoipCallId);
    if (callData.callState === CallStateConst.CALL_STATUS_DISCONNECTED && this.currentVoipCallId === callData.callId) {
      this.currentVoipCallId = undefined;
    }
  }

  /**
   * unsubscribe
   */
  unsubscribe(): void {
    if (this.subscriber) {
      try {
        commonEventManager.unsubscribe(this.subscriber, (err) => {
          if (err && err.code !== 0) {
            LogUtils.i(TAG, 'unsubscribe commonEvent.unsubscribe err:' + JSON.stringify(err));
          }
        });
      } catch (error) {
        LogUtils.e(TAG, 'unsubscribe try error' + error);
      }
      this.subscriber = undefined;
      this.isEventSubscribed = false;
    }
  }

  getCallDataByCallId(callId: number) {
    let targetObj = this.callList.find((v: DefaultCallData) => v.callId === callId);
    return targetObj;
  }

  getForegroundVoipCall(): DefaultCallData | undefined {
    // No call!
    if (this.callList.length === 0) {
      return undefined;
    }
    let foregroundCall: DefaultCallData | undefined;
    for (let i = 0; i < this.callList.length; i++) {
      let callData = this.callList[i];
      if (callData.callType !== CallStateConst.TYPE_VOIP) {
        continue;
      }
      if (callData.callState === CallStateConst.CALL_STATUS_ACTIVE ||
        callData.callState === CallStateConst.CALL_STATUS_DIALING) {
        foregroundCall = callData;
        return foregroundCall;
      }
      if (callData.callState === CallStateConst.CALL_STATUS_INCOMING ||
        callData.callState === CallStateConst.CALL_STATUS_WAITING) {
        foregroundCall = callData;
        continue;
      }
    }
    return foregroundCall;
  }

  removeCoverModeChange() {
    if (!this.context) {
      return
    }
    settings.unregisterKeyObserver(this.context, Constants.COVER_WINDOW_SHOWING,
      settings.domainName.DEVICE_SHARED);
  }

  /**
   * remove register listener
   */
  removeRegisterListener(): void {
    settings.unregisterKeyObserver(this.context, Constants.ACCESSIBILITY_SCREEN_READER,
      settings.domainName.DEVICE_SHARED);
    this.mTelephonyCall?.unRegisterCallStateCallback();
    CallServiceProxy.getInstance().unRegisterCallEventCallback();
    this.bannerNotificationManager?.release();
    this.unsubscribe();
    offPeerDimensionsChange();
    offImsCallModeChange();
    offCallSessionEvent();
    ExternalCallModel.getInstance().unRegisterFoldStatusChange();
    CallColumnUtils.getInstance().removeDisplayChange();
    this.removeCoverModeChange();
  }

  /**
   * registerCallStateListener
   */
  registerCallStateListener(): void {
    try {
      this.mTelephonyCall.registerCallStateCallback((data: DefaultCallData) => {
        if (!data) {
          return;
        }
        LogUtils.i(TAG, `begin to getCallDate, callId is:${data.callId}`);

        let callId: number | null = AppStorage.get('callId') as number;
        if (callId === data.callId) {
          let curTraceId: hiTraceChain.HiTraceId | null = AppStorage.get('curTraceId') as hiTraceChain.HiTraceId;
          hiTraceChain.setId(curTraceId);
        } else {
          let curTraceId = hiTraceChain.getId();
          let traceIdIsvalid = hiTraceChain.isValid(curTraceId);
          if (!traceIdIsvalid) {
            curTraceId = hiTraceChain.begin('CallManagerService',
              hiTraceChain.HiTraceFlag.INCLUDE_ASYNC |
              hiTraceChain.HiTraceFlag.DONOT_CREATE_SPAN);
          }
          AppStorage.setOrCreate('callId', data.callId);
          AppStorage.setOrCreate('curTraceId', curTraceId);
        }
        AppStorage.setOrCreate('callStateInCeliaDisconnect', data.callState);
        this.getCallData(data);
      })
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.e(TAG, `registerCallStateCallback err = ${JSON.stringify(error.code)}`);
    }
  }

  /**
   * get CallEvent Data
   */
  // instrument ignore next
  getCallEventData(): void {
    try {
      CallServiceProxy.getInstance().registerCallEventCallback((res: call.CallEventOptions) => {
        let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
        LogUtils.i(TAG, 'initNotSupportHold callback enentId: ' + res?.eventId);
        if ((res?.eventId as number) === Constants.EVENT_SUPER_PRIVACY_MODE_ON) {
          AppStorage.setOrCreate('isSuperPrivacy', true);
          LeatherManager.getSuperPrivacy(true);
        } else if ((res?.eventId as number) === Constants.EVENT_SUPER_PRIVACY_MODE_OFF) {
          AppStorage.setOrCreate('isSuperPrivacy', false);
          LeatherManager.getSuperPrivacy(false);
        } else if ((res?.eventId as number) === Constants.EVENT_MUTE_RING && isIncomingCall(callData?.callState)) {
          callData.isRingSilenced = true;
          VideoController.getInstance()?.stopRinging();
        } else if ((res?.eventId as number) === Constants.EVENT_LOCAL_ALERTING) {
          AppStorage.setOrCreate('isRbtError', true);
        } else {
          AppStorage.setOrCreate('callEventChange', Number(res?.eventId));
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `initNotSupportHold err = ${JSON.stringify(err)}`);
    }
  }

  clearData() {
    this.callData = undefined;
    this.callList = [];
    AppStorage.delete('isLeatherManagerRequestSCB');
    AppStorage.delete('isVoipMute');
  }

  updateBannerNotification(isDark: boolean) {
    this.bannerNotificationManager?.onConfigurationUpdated(isDark);
    this.bannerNotificationManager?.sendNotification();
  }

  private updateCallDataIfPossible(callData: DefaultCallData) {
    if (callData.callType !== CallStateConst.TYPE_VOIP) {
      return;
    }
    let want = GlobalContextHelper.getContext().getValue<Want>(Constants.VOIP_ABILITY_WANT);
    if (want?.parameters && (want?.parameters?.callData !== undefined)) {
      let temp = want.parameters.callData as DefaultCallData;
      if (callData.callId === temp.callId) {
        want.parameters.callData = callData;
        GlobalContextHelper.getContext().set<Want>(Constants.VOIP_ABILITY_WANT, want);
        LogUtils.i(TAG, 'updateCallDataIfPossible');
      }
    }
  }

  private sendVoipEvent(callEvent: number, callData?: DefaultCallData): void {
    let voipBundleName = callData?.voipCallAttribute?.voipBundleName ?? '';
    let voipCallId = callData?.voipCallAttribute?.voipCallId ?? '';
    let uid = callData?.voipCallAttribute?.uid ?? 0;
    if (callData?.voipCallAttribute?.extensionId == '') {
      CallEventUtil.sendCommonEvent(CallEventUtil.getEventOptions(callEvent, voipBundleName, voipCallId, uid));
    }
  }

  private queryIsInOobe(): void {
    let deviceProvisionedPromise =
      settings.getValue(this.context, Constants.SETTINGS_DEVICE_PROVISIONED, settings.domainName.DEVICE_SHARED);
    let userSetupCompletePromise =
      settings.getValue(this.context, Constants.SETTINGS_USER_SETUP_COMPLETE, settings.domainName.USER_SECURITY);
    let isOtaFinishedPromise =
      settings.getValue(this.context, Constants.SETTINGS_IS_OTA_FINISHED, settings.domainName.USER_SECURITY);
    let isDeviceProvisioned = '0';
    let isUserSetupComplete = '0';
    let isOtaFinished = '1';
    try {
      deviceProvisionedPromise.then((data: string) => {
        isDeviceProvisioned = data ?? '0';
      }).catch((err: BusinessError) => {
        isDeviceProvisioned = '1';
        LogUtils.e(TAG, `deviceProvisionedPromise failed, code =${err.code}, message =${err.message}`);
      }).finally(() => {
        this.confirmIsInOobe(isDeviceProvisioned, isUserSetupComplete, isOtaFinished);
      });
      userSetupCompletePromise.then((data: string) => {
        isUserSetupComplete = data ?? '0';
      }).catch((err: BusinessError) => {
        isUserSetupComplete = '1';
        LogUtils.e(TAG, `userSetupCompletePromise failed, code =${err.code}, message =${err.message}`);
      }).finally(() => {
        this.confirmIsInOobe(isDeviceProvisioned, isUserSetupComplete, isOtaFinished);
      });
      isOtaFinishedPromise.then((data: string) => {
        isOtaFinished = data ?? '1';
      }).catch((err: BusinessError) => {
        isOtaFinished = '1';
        LogUtils.e(TAG, `isOtaFinishedPromise failed, code =${err.code}, message =${err.message}`);
      }).finally(() => {
        this.confirmIsInOobe(isDeviceProvisioned, isUserSetupComplete, isOtaFinished);
        const isInOta = isOtaFinished === '0';
        AppStorage.setOrCreate('isInOta', isInOta);
      });
    } catch (err) {
      LogUtils.e(TAG, 'Failed to queryIsInOobe, err: ' + JSON.stringify(err));
    }
  }

  private confirmIsInOobe(isDeviceProvisioned: string, isUserSetupComplete: string, isOtaFinished: string): void {
    this.isInOobe = !(isDeviceProvisioned === '1' && isUserSetupComplete === '1' && isOtaFinished === '1');
    AppStorage.setOrCreate('isInOobe', this.isInOobe);
  }

  public async updateHyacinthInfo() {
    LogUtils.i(TAG, 'updateHyacinthInfo');
    let condition = new dataSharePredicates.DataSharePredicates();
    condition.equalTo('KEYWORD', QUERY_SATELLITE_MODE_HYACINTH_KEY);
    let dataHelper: dataShare.DataShareHelper | undefined = undefined;
    let data: DataShareResultSet | undefined = undefined;
    try {
      dataHelper = await dataShare.createDataShareHelper(
        Utils.getInstance().getContext(), SETTING_SATELLITE_SERVICE_URI);
      data = await dataHelper.query(SETTING_SATELLITE_SERVICE_URI, condition, []);
      LogUtils.i(TAG, 'query hyacinth succeed');
      if (data.goToFirstRow()) {
        LogUtils.i(TAG, 'query hyacinth succeed return key');
        AppStorage.SetOrCreate<boolean>('isHyacinthMode', data.getLong(data.getColumnIndex('VALUE')) === 1 )
      }
    } catch (err) {
      LogUtils.e(TAG, 'query hyacinth failed');
    } finally {
      try {
        data?.close();
        dataHelper?.close();
      } catch (err) {
        LogUtils.e(TAG, `query auto record num close err: ${err.code}`);
      }
    }
  }

  private addSubscribeServiceState(): void {
    // this.subscribeServiceState((data: collaborationServiceManager.ServiceStateInfo) => {
    //   LogUtils.i(TAG, `subscribeServiceState state:${data?.state}, serviceName:${data?.serviceName}`);
    //   // 投屏hicar或流转时，协同框架中标识动效完成的serviceName，不做处理
    //   if (data.serviceName === Constants.COLLABORATION_MOTION_SERVICE) {
    //     return;
    //   }
    //   if (data.state === collaborationServiceManager.State.CONNECTED &&
    //     Constants.PROJECTION_DEVICE.includes(data.serviceName)) {
    //     AppStorage.setOrCreate('isAddVirtualScreenBlocklist', false);
    //   } else {
    //     AppStorage.setOrCreate('isAddVirtualScreenBlocklist', true);
    //   }
    // })
  }

  // private subscribeServiceState(callback: Callback<collaborationServiceManager.ServiceStateInfo>): void {
  //   try {
  //     collaborationServiceManager.subscribeServiceState((result: collaborationServiceManager.ServiceStateInfo) => {
  //       LogUtils.i(TAG, 'subscribeServiceState success');
  //       callback(result);
  //     });
  //   } catch (e) {
  //     LogUtils.e(TAG, `subscribeServiceState error code:${e?.code}, message:${e?.message}.`);
  //   }
  // }

  /**
   * 解除对协同状态的监听
   */
  // public unsubscribeServiceState(): void {
  //   try {
  //     collaborationServiceManager.unsubscribeServiceState((result: collaborationServiceManager.ServiceStateInfo) => {
  //     });
  //     LogUtils.i(TAG, 'unsubscribeServiceState success');
  //   } catch (e) {
  //     LogUtils.e(TAG, `unsubscribeServiceState error code:${e?.code}, message:${e?.message}.`);
  //   }
  // }

  /**
   * 注册SIM卡变化时间
   */
  public registerSimStateChange(): void {
    const slotCount = sim.getMaxSimCount();
    LogUtils.i(TAG, `register SimStateChange slotCount:${slotCount}`);
    try {
      for (let i = 0; i < slotCount; i++) {
        telObserver.on('simStateChange', {
          slotId: i
        }, this.handlegetSimCount);
      }
    } catch (err) {
      LogUtils.e(TAG, `on simStateChange err:${err?.message}`);
    }
  }

  private handlegetSimCount(){
    getActiveSimCount(activeSimCount => {
      LogUtils.w(TAG, `simCount is: ${activeSimCount}`);
      AppStorage.setOrCreate('simCount', activeSimCount);
    });
  }

    /**
   * 解注册SIM卡变化时间
   */
  public unRegisterSimStateChange(): void {
    try {
      telObserver.off('simStateChange', this.handlegetSimCount);
    } catch (err) {
      LogUtils.e(TAG, `off simStateChange err:${err?.message}`);
    }
  }

  /**
   * 通知开关默认开启
   */
  private defaultOpenNotification() {
    let bundle: notificationManager.BundleOption = {
      bundle: 'com.ohos.callui',
    };
    notificationManager.isNotificationEnabled(bundle).then((isOpen) => {
      if (!isOpen) {
        notificationManager.setNotificationEnable(bundle, true);
      }
    }).catch(() => {
      LogUtils.e(TAG, 'isNotificationEnabled fail');
    });
    notificationManager.getSlotFlagsByBundle(bundle).then((notificationFlag: number) => {
      LogUtils.i(TAG, 'notificationFlag is' + notificationFlag);
      if (notificationFlag !== Constants.ALL_SWITCH_ENABLE) {
        notificationManager.setSlotFlagsByBundle(bundle, Constants.ALL_SWITCH_ENABLE)
      }
    }).catch(() => {
      LogUtils.e(TAG, 'getSlotFlagsByBundle fail');
    });
  }
}
