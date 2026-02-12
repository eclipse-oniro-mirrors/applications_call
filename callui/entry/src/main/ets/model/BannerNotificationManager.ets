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

import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import * as Constants from '../common/utils/Constants';
import { BusinessError } from '@ohos.base';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import DefaultCallData, { callDataToSafeString, VoipCallAttribute } from '../common/struct/TypeUtils';
import resourceManager from '@ohos.resourceManager';
import Want from '@ohos.app.ability.Want';
import notificationManager from '@ohos.notificationManager';
import { Context } from '@ohos.abilityAccessCtrl';
import WantAgent from '@ohos.app.ability.wantAgent';
import hiTraceChain from '@ohos.hiTraceChain';
import { CallUiEvent } from '../common/utils/CallUiEvent';
import * as BannerNotificationProxy from '../common/utils/BannerNotificationProxy';
import { BannerResourceManager, CallStateType, DarkResIcons } from './BannerResourceManager';
import CallDataManager from './CallDataManager';
import Utils from '../common/utils/utils';
import contextConstant from '@ohos.app.ability.contextConstant';
import image from '@ohos.multimedia.image';
import BottomViewModel from '../viewmodel/BottomViewModel';
import { DEVICE_SPEAKER } from '../common/constant/DeviceTypeConst';
import { getCallById, getForegroundCall, isAliveCall } from '../common/utils/CallListHelper';
import { bundleManager, bundleResourceManager } from '@kit.AbilityKit';
import { getFormatCallLabelPrimary, getCallLabelSecondary, getCallLabelThird } from '../common/utils/CallLabelUtils';
import { isScreenLocked, isTwoInOne } from '../common/utils/DeviceTypeUtils';
import CallUtils, { CallUtils as CallUtilsClass } from '../common/utils/CallUtils';
import { CallFaultEventUtil } from '../common/utils/ReportUtils/CallFaultEventUtil';
import NotificationInfo from '../common/struct/NotificationInfo';
import AudioDeviceManager from './audio/AudioDeviceManager';
import NotificationRequestBuilder from './NotificationRequestBuilder';
import { accessibility } from '@kit.AccessibilityKit';
import { StringUtil } from '../common/utils/StringUtil';
import CallManagerService from '../ServiceAbility/CallManagerService';
import { HashMap } from '@kit.ArkTS';
import { VisionGlassConstants } from '../common/constant/VisionGlassConstants';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { SystemMode } from '../common/utils/SystemMode';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import { DisplayMode } from '../common/utils/ReportUtils/DisplayMode';

const TAG = 'BannerNotificationManager';

export const ID = 0;

const BANNER_AVATAR_SIZE_LIMIT = 192 * 1024;

export default class BannerNotificationManager {
  private context?: Context;
  private currentNotificationId: number = ID;
  private bannerResManager: BannerResourceManager;
  private static isHeadsUpEnabled = true;
  private static sBannerManager: BannerNotificationManager;
  private mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  private voipBundleName: string = '';
  private uid: number = 0;
  private mNotificationInfoCache?: NotificationInfo;
  private mIsStartingAbility: boolean = false;
  private mNotificationEvent: Promise<void> = Promise.resolve();
  private mNotificationIndex = 0;
  private mCancelList: number[] = [];
  private mVoipNotificationEvent: Promise<void> = Promise.resolve();
  private mVoipNotificationMap: HashMap<number, number> = new HashMap();
  private mIsNotificationReady = true;

  public static getInstance(): BannerNotificationManager {
    if (!BannerNotificationManager.sBannerManager) {
      BannerNotificationManager.sBannerManager = new BannerNotificationManager();
    }
    return BannerNotificationManager.sBannerManager;
  }

  constructor() {
    this.context = Utils.getInstance().getContext();
    this.bannerResManager = new BannerResourceManager(this.context);
  }

  async onConfigurationUpdated(isDark: boolean) {
    if (this.context) {
      this.bannerResManager.refreshResource(isDark);
    }
  }

  public release() {
    if (this.bannerResManager !== undefined) {
      LogUtils.i(TAG, 'need release banner resource');
      this.bannerResManager.release();
    }
    this.cancelNotification();
    this.cancelVoipNotification();
    this.voipBundleName = '';
    this.uid = 0;
    this.mNotificationInfoCache = undefined;
    this.mNotificationIndex = 0;
    this.mCancelList = [];
    this.mVoipNotificationMap.clear();
  }

  public static async isStartCallNotifies(callData: DefaultCallData, callBack: Function) {
    LogUtils.i(TAG, `isStartCallNotifies: ${callData.callId}`);
    if (callData.callState !== CallStateConst.CALL_STATUS_INCOMING && AppStorage.get<boolean>('isDistributeSink')) {
      callBack(false);
      return;
    }

    if (callData.callType === CallStateConst.TYPE_SATELLITE) {
      callBack(false);
      return;
    }

    // 连接眼镜状态下，手机来电以通知横幅的形式显示
    if (callData.callState === CallStateConst.CALL_STATUS_INCOMING &&
    AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS)) {
      BannerNotificationManager.enableBannerNotification(true);
      callBack(true);
      return;
    }

    try {
      await BannerNotificationManager.handleNormalCallNotification(callData, callBack);
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.e(TAG, `isStartCallNotifies preferences, code is ${error.code}`);
      callBack(false);
    }
  }

  private static async handleNormalCallNotification(callData: DefaultCallData, callBack: Function) {
    let context = Utils.getInstance().getContext();
    let ctx = context.getApplicationContext();
    if (!ctx) {
      LogUtils.e(TAG, 'cant get context');
      callBack(false);
      return;
    }

    ctx.area = contextConstant.AreaMode.EL1;

    if (CallUtils.isDoNotDisturb(callData)) {
      if (isTwoInOne()) {
        LogUtils.i(TAG, 'need full screen for the call isDoNotDisturb');
        callBack(false);
        return;
      }
      let isNewFoldPhoneExternalScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
      LogUtils.i(TAG, `need banner notification for the isDoNotDisturb, isNewScreen:${isNewFoldPhoneExternalScreen}`);
      if (isNewFoldPhoneExternalScreen && isScreenLocked()) {
        BannerNotificationManager.enableBannerNotification(false);
      } else {
        BannerNotificationManager.enableBannerNotification(true);
      }
      callBack(true);
      return;
    }

    let isNeedFullScreen = BannerNotificationManager.isNeedFullScreen();
    if (isNeedFullScreen) {
      LogUtils.i(TAG, 'need full screen for the call');
      callBack(false);
      return;
    }

    let isPrivacyScreenCast = Utils.getInstance().isPrivacyScreenCast();
    let isBannerNotificationMeet = await BannerNotificationManager.isBannerNotificationMeet();
    if (isPrivacyScreenCast || isBannerNotificationMeet) {
      LogUtils.i(TAG, 'need banner notification for the call');
      BannerNotificationManager.enableBannerNotification(true);
      callBack(true);
      return;
    }

    let isMapNavigation = await Utils.isMapNavigation();
    if (isMapNavigation) {
      LogUtils.i(TAG, 'map navigation need banner notification for the call');
      BannerNotificationManager.enableBannerNotification(true);
      callBack(true);
      return;
    }

    let isInOta = AppStorage.get<boolean>('isInOta') as boolean;
    if (isInOta && !isScreenLocked()) {
      BannerNotificationManager.enableBannerNotification(false);
      callBack(true);
      return;
    }

    let isShowBanner = false;
    await Utils.getInstance().getCallNotifiesFromSettingsData((configData) => {
      LogUtils.i(TAG, `isStartCallNotifies preferencesValue is ${configData}  callType is ${callData.callType}`);
      isShowBanner = configData === Constants.BANNER;
      if (isShowBanner) {
        BannerNotificationManager.enableBannerNotification(true);
      }
    });
    LogUtils.i(TAG, 'isStartCallNotifies Finish ' + isShowBanner);
    callBack(isShowBanner);
  }

  /**
   * Cancel notice
   */
  cancelNotification(callId?: number) {
    LogUtils.i(TAG, `cancel notification start ${callId}`);
    if (!callId) {
      LogUtils.i(TAG, `cancel notification start ${this.currentNotificationId}`);
      callId = this.currentNotificationId;
    }
    this.mCancelList.push(callId);
    try {
      this.mNotificationEvent = this.mNotificationEvent.then(async () => {
        LogUtils.i(TAG, `cancel notification then ${callId}`);
        try {
          await notificationManager.cancel(ID);
          if (BannerNotificationManager.getIsHeadsUpEnabled()) {
            ReportUtil.getInstance().reportHangupCallSuccess(DisplayMode.BANNER);
          }
          LogUtils.i(TAG, `cancel notification success ${callId}`);
        } catch (error) {
          this.handleCancelError(error);
        }
      });
    } catch (error) {
      this.handleCancelError(error);
    }
  }

  private handleCancelError(error: BusinessError) {
    if (error.code === 1600007) {
      LogUtils.w(TAG, 'cancel notification success already, no need to cancel again, ' + this.currentNotificationId);
    } else {
      CallFaultEventUtil.getInstance().cancelNotificationCallFaultEvent(error);
      LogUtils.e(TAG, 'cancel notification failed, ' + JSON.stringify(error));
    }
  }

  cancelVoipNotificationByCallId(callId: number) {
    this.cancelBannerNotification(callId);
  }

  cancelVoipNotification(callDataList?: DefaultCallData[], currentCallId?: number) {
    if (callDataList && callDataList.length > 0) {
      for (let i = 0; i < callDataList.length; i++) {
        let callData = callDataList[i];
        if (callData.callType === CallStateConst.TYPE_VOIP &&
          (currentCallId === undefined || callData.callId !== currentCallId)) {
          this.cancelBannerNotification(callData.callId);
        }
      }
    } else {
      this.cancelBannerNotification(this.currentNotificationId);
    }
  }

  async cancelBannerNotification(callId: number) {
    LogUtils.i(TAG, 'cancel voip notification start, callId : ' + callId);
    this.mCancelList.push(callId);
    try {
      this.mVoipNotificationEvent = this.mVoipNotificationEvent.then(async () => {
        LogUtils.i(TAG, 'cancel voip notification then ' + callId);
        try {
          await notificationManager.cancel(callId);
          LogUtils.i(TAG, 'cancel voip notification success, callId: ' + callId);
        } catch (error) {
          this.handleCancelError(error);
        }
      });
    } catch (error) {
      this.handleCancelError(error);
    }
  }

  static getIsHeadsUpEnabled(){
    return BannerNotificationManager.isHeadsUpEnabled;
  }

  static enableBannerNotification(isEnabled: boolean) {
    LogUtils.d(TAG, 'enableBannerNotification is ' + isEnabled);
    BannerNotificationManager.isHeadsUpEnabled = isEnabled;
  }

  sendNotification(forceRefresh: boolean = false) {
    let callData = getForegroundCall(CallDataManager.getInstance().callList);
    if (callData !== undefined) {
      this.sendBannerNotification(callData, forceRefresh);
    } else {
      LogUtils.i(TAG, 'no callData get, sendNotification just ignore!');
    }
  }

  private async sendVoipCallNotification(callData: DefaultCallData, index: number) {
    const callState: number = callData.callState;
    let isConferenceCall = callData.voipCallAttribute?.isConferenceCall;
    let isStartBanner: boolean = this.isNeedStartBannerForVoip(callState);
    if (!isStartBanner) {
      LogUtils.i(TAG, 'cancelNotification by call state callId:' + callData.callId);
      this.cancelVoipNotificationByCallId(callData.callId);
      return;
    }

    LogUtils.i(TAG, 'sendBannerNotification callData: ' + callDataToSafeString(callData));
    let context = this.context?.getApplicationContext() as Context;
    let resourceManager = context.resourceManager;
    try {
      let state = this.bannerResManager.getCallState(callState);
      let iconNames = await this.bannerResManager.getIconNamesByState(state, callData.videoState,
        this.getMuteState(state, callData.isEcc, true), this.getSpeakerState(state, true),
        callData.voipCallAttribute?.isVoiceAnswerSupported);
      let largeIcon: PixelMap | undefined = undefined;
      let capsuleTitle = this.getCapsuleTitle(callState, callData.callType);
      capsuleTitle = this.fixCapsuleTitleForVoipCall(callState, resourceManager, capsuleTitle, isConferenceCall);
      let bannerTitle = getFormatCallLabelPrimary(callData);
      let bannerContent = this.bannerContent(callData);

      if (callData.voipCallAttribute !== undefined) {
        if (callData.voipCallAttribute.userProfile === undefined) {
          LogUtils.i(TAG, 'this call has no userProfile, callId: ' + callData.callId);
        } else {
          let size: number = callData.voipCallAttribute.userProfile.getPixelBytesNumber();
          LogUtils.i(TAG, 'this call has userProfile, callId: ' + callData.callId + ', size: ' + size);
          if (size < BANNER_AVATAR_SIZE_LIMIT) {
            largeIcon = callData.voipCallAttribute.userProfile;
          }
        }
        bannerTitle = callData.voipCallAttribute.userName ? callData.voipCallAttribute.userName :
        resourceManager.getStringSync($r('app.string.voip_of_XX').id);

        let appName = this.getAppName(callData.voipCallAttribute);

        bannerContent = this.fixBannerContentForVoipCall(resourceManager, callData, appName, bannerContent);

        LogUtils.i(TAG, 'init for voip');
      }
      if (!bannerTitle) {
        bannerTitle = callData.accountNumber;
      }
      let requestBuilder = new NotificationRequestBuilder(callData.callId);
      requestBuilder.setWantAgent(await this.getWantAgent(callData));
      requestBuilder.setOverlayIcon(largeIcon);
      requestBuilder.setTitle(bannerTitle);
      requestBuilder.setSmallIcon(undefined);
      if (callState === CallStateConst.CALL_STATUS_HOLDING) {
        bannerContent = callData.formatNumber + ' ' + bannerContent;
      }
      requestBuilder.setText(bannerContent);
      requestBuilder.setButton(iconNames);
      requestBuilder.setCapsuleTitle(capsuleTitle);
      requestBuilder.setCapsuleIcon(await this.getCapsuleIconByState(callData));
      requestBuilder.setHeadsUpEnable(this.isHeadUpEnabled(true));
      requestBuilder.setKeepHeadsUpSticky(true);
      requestBuilder.setSimIconStatus(this.isSimIconDisplay(callData) ? (callData.accountId + 1) : 0);
      requestBuilder.setCapsuleSticky(callData.voipCallAttribute?.isCapsuleSticky);
      requestBuilder.setCapsuleHiddenWhenTerminate(false);
      requestBuilder.setSysVoipState(callState);
      requestBuilder.setButtonAccessibilityText(this.getBarriText(iconNames));
      if (!isConferenceCall && callState === CallStateConst.CALL_STATUS_ACTIVE) {
        requestBuilder.setNotificationTime(this.getCallTimeState(callData));
      }
      let requestInfo = requestBuilder.build();
      this.updateIconPriority(callData, requestInfo);
      await this.publishVoipNotification(callData, requestInfo, index);
    } catch (err) {
      CallFaultEventUtil.getInstance().finishBannerNotificationCallEventFault(callData, err.code);
      LogUtils.e(TAG, 'Failed to get resourceMgr. code =' + err.code + ', message =' + err.message);
    }
  }

  async sendBannerNotification(callData: DefaultCallData, forceRefresh: boolean = false) {
    if (CallUtils.isSosWithOutCallUiAbility(callData) === CallUtilsClass.HIDE_CALL_PAGE_WHEN_SOS_CALL) {
      return
    }
    this.currentNotificationId = callData.callId;
    let isVoipCall = callData.callType === CallStateConst.TYPE_VOIP;

    // carrier call
    if (!isVoipCall) {
      try {
        if (!this.mIsNotificationReady && CallDataManager.getInstance().isOnlyIncoming(callData)) {
          LogUtils.w(TAG, `sendCallNotification not ready.`);
          return;
        }
        const index = ++this.mNotificationIndex;
        LogUtils.i(TAG, `sendCallNotification No.${index}`);
        this.mNotificationEvent = this.mNotificationEvent.then(async () => {
          if (this.skip(index)) {
            return;
          }
          try {
            await this.sendCallNotification(callData, forceRefresh, index);
          } catch (error) {
            LogUtils.e('Bumble_Bee', `sendCallNotification fiald: ${error}`);
          }
        })
      } catch (error) {
        LogUtils.e(TAG, `NotificationEvent.then fiald: ${error}`);
      }
      return;
    }

    // voip call
    try {
      if (callData?.voipCallAttribute?.isExpired) {
        LogUtils.i(TAG, 'voip callData is expired, no need send voipCallNotification');
        return;
      }
      let index = this.mVoipNotificationMap.get(callData.callId);
      if (!index) {
        index = 0;
      }
      this.mVoipNotificationMap.set(callData.callId, ++index);
      LogUtils.i(TAG, `sendVoipCallNotification No.${index} callId:${callData.callId}`);
      this.mVoipNotificationEvent = this.mVoipNotificationEvent.then(async () => {
        if (this.skipVoip(index, callData.callId)) {
          return;
        }
        if (callData.voipCallAttribute?.uid &&
          CallUtils.getOsAccountLocalIdForUid(callData.voipCallAttribute?.uid) !==
            await CallUtils.getSysUserId()) {
          LogUtils.i(TAG, `sendVoipCallNotification userid diff. No.${index} callId:${callData.callId}`);
          return;
        }
        // 需要校验当前的abilityName是不是uiability，如果不是，则不需要发通知
        this.checkAndSendVoipNotification(callData, index)
      })
    } catch (error) {
      LogUtils.e(TAG, `sendVoipCallNotification failed: ${error}`);
    }
  }

  async checkAndSendVoipNotification(callData: DefaultCallData, index: number) {
    const voipBundleName = callData.voipCallAttribute?.voipBundleName;
    const abilityName = callData.voipCallAttribute?.abilityName;

    if (!voipBundleName || !abilityName) {
      LogUtils.e(TAG, 'voipBundleName or abilityName is null or undefined');
      return;
    }

    let wants: Want = {
      bundleName: voipBundleName,
      abilityName: abilityName
    };

    try {
      const userId = await CallUtils.getSysUserId();
      await bundleManager.queryAbilityInfo(wants, bundleManager.AbilityFlag.GET_ABILITY_INFO_DEFAULT, userId);
    } catch (err) {
      LogUtils.e(TAG, 'get uiability bundleInfo failed: ' + err?.message);
      return;
    }
    await this.sendVoipCallNotification(callData, index);
  }

  getAppName(voip: VoipCallAttribute): string {
    if (voip.appName) {
      return voip.appName;
    } else {
      let appName = this.getAppNameFromBundleName(voip.voipBundleName);
      voip.appName = appName;
      return appName;
    }
  }

  fixBannerContentForVoipCall(resourceManager: resourceManager.ResourceManager, callData: DefaultCallData,
    appName: string, bannerContent: string): string {
    let isConferenceCall = callData.voipCallAttribute?.isConferenceCall;
    const isOtherBundle = callData.voipCallAttribute?.voipBundleName === 'com.tencent.wechat';
    let mapContent: Record<string, Resource[]> = {
      'other': [$r('app.string.wechat_videoCall'), $r('app.string.wechat_multiCall'),
        $r('app.string.wechat_voiceCall')],
      'default': [$r('app.string.app_voip_incoming_video'), $r('app.string.app_voice_conference'),
        $r('app.string.app_voip_incoming_voice')]
    }
    let currentContent: Resource[] = isOtherBundle ? mapContent['other'] : mapContent['default'];
    switch (callData.callState) {
      case CallStateConst.CALL_STATUS_INCOMING:
        let videoState = callData.videoState;
        if (videoState && isConferenceCall) {
          bannerContent = resourceManager.getStringSync($r('app.string.app_video_conference').id, appName);
        } else if (videoState && !isConferenceCall) {
          bannerContent = resourceManager.getStringSync(currentContent[0].id, appName);
        } else if (!videoState && isConferenceCall) {
          bannerContent = resourceManager.getStringSync(currentContent[1].id, appName);
        } else {
          bannerContent = resourceManager.getStringSync(currentContent[2].id, appName);
        }
        break;
      case CallStateConst.CALL_STATUS_ANSWER:
        if (isConferenceCall) {
          bannerContent = resourceManager.getStringSync($r('app.string.joining').id);
        }
        break;
      case CallStateConst.CALL_STATUS_DIALING:
        if (isConferenceCall) {
          bannerContent = resourceManager.getStringSync($r('app.string.joining').id);
        } else {
          bannerContent = resourceManager.getStringSync($r('app.string.app_voip_dialing_banner').id, appName);
        }
        break;
      case CallStateConst.CALL_STATUS_ACTIVE:
        if (isConferenceCall) {
          bannerContent = resourceManager.getStringSync($r('app.string.inTheConference').id);
        }
        break;
    }
    return bannerContent;
  }


  getBarriText(iconNames: notificationManager.NotificationButton): string[] {
    if (!accessibility.isOpenAccessibilitySync()) {
      return [];
    }
    let readTextArray: string[] = [];
    if (iconNames?.names?.length === 2) {
      readTextArray = [StringUtil.formatResourceToString($r('app.string.hanging_up_voice_call')),
        StringUtil.formatResourceToString($r('app.string.voiceCall'))];
    } else if (iconNames?.names?.length === 3) {
      readTextArray = this.namesCountThree(iconNames, readTextArray);
    }
    return readTextArray;
  }

  private namesCountThree(iconNames: notificationManager.NotificationButton, readTextArray: string[]) {
    if (!iconNames || !iconNames.names) {
      return readTextArray;
    }
    if (iconNames.names[0] === CallStateConst.TEXT_IN_CALL_MUTE) {
      readTextArray = [StringUtil.formatResourceToString($r('app.string.call_mute_on')),
        StringUtil.formatResourceToString($r('app.string.hanging_up_voice_call')),
        StringUtil.formatResourceToString($r('app.string.switching_audio_channels'))];
    } else if (iconNames.names[0] === CallStateConst.TEXT_IN_CALL_UN_MUTE) {
      readTextArray = [StringUtil.formatResourceToString($r('app.string.unmute')),
        StringUtil.formatResourceToString($r('app.string.hanging_up_voice_call')),
        StringUtil.formatResourceToString($r('app.string.switching_audio_channels'))];
    } else if (iconNames.names[0] === CallStateConst.TEXT_INCOMING_CALL_REJECT) {
      readTextArray = [StringUtil.formatResourceToString($r('app.string.hangUp')),
        StringUtil.formatResourceToString($r('app.string.voiceCall')),
        StringUtil.formatResourceToString($r('app.string.video_answer'))];
    }
    return readTextArray;
  }

  private async getLargeIcon(callData: DefaultCallData): Promise<image.PixelMap> {
    if (callData.isVoiceMailNumber) {
      return await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.DEFAULT_CONTACTS) as image.PixelMap;
    }
    if (callData.contactSmallAvatar) {
      const contactSmallAvatarPixmapSize: number = callData.contactSmallAvatar.getPixelBytesNumber();
      if (contactSmallAvatarPixmapSize < BANNER_AVATAR_SIZE_LIMIT) {
        return callData.contactSmallAvatar;
      } else {
        LogUtils.w(TAG, `contactSmallAvatar exceed limit, size: ${contactSmallAvatarPixmapSize}`);
      }
    }
    return await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.DEFAULT_CONTACTS) as image.PixelMap;
  }

  private updateIconPriority(callData: DefaultCallData, request: notificationManager.NotificationRequest) {
    if (!request.extraInfo) {
      return;
    }
    let iconPriority = this.getIconPriority(callData);
    if (!iconPriority || iconPriority.length <= 0) {
      LogUtils.i(TAG, 'the icon priority is empty.')
      return;
    }
    request.extraInfo.hw_button_priority = iconPriority;
  }

  private getIconPriority(callData: DefaultCallData) {
    let iconPriority: number[] = [];
    if (callData.videoState === CallStateConst.VIDEO_STATE_VIDEO && !SystemMode.getInstance().isModePenglai()) {
      if (callData.callState === CallStateConst.CALL_STATUS_INCOMING) {
        // 区分voip视频来电不支持语音通话场景和其它场景锁屏下拉图标的优先级显示
        iconPriority = callData.callType === CallStateConst.TYPE_VOIP &&
          !callData.voipCallAttribute?.isVoiceAnswerSupported ? [1, 0] : [2, 0, 1];
      } else if (callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
        iconPriority = [1, 2, 0];
      }
    } else {
      switch (callData.callState) {
        case CallStateConst.CALL_STATUS_INCOMING:
        case CallStateConst.CALL_DIRECTION_OUTGOING:
        case CallStateConst.CALL_STATUS_DIALING:
        case CallStateConst.CALL_STATUS_ALERTING:
        case CallStateConst.TYPE_CS:
          iconPriority = [1, 2, 0];
          break;
        default:
          break;
      }
    }
    return iconPriority;
  }

  private bannerContent(callData: DefaultCallData): string {
    let bannerContentDisplay: string | undefined;
    if (callData.callState === CallStateConst.CALL_STATUS_ANSWER) {
      bannerContentDisplay = this.context?.resourceManager.getStringSync($r('app.string.connecting').id);
    } else if (callData.callState === CallStateConst.CALL_STATUS_DISCONNECTING) {
      bannerContentDisplay = this.context?.resourceManager.getStringSync($r('app.string.hangingUp').id);
    } else if (callData.callState === CallStateConst.CALL_STATUS_DIALING ||
      callData.callState === CallStateConst.CALL_STATUS_ALERTING) {
      bannerContentDisplay = this.context?.resourceManager.getStringSync($r('app.string.dialing_banner').id);
    } else if (callData.callState === CallStateConst.CALL_STATUS_HOLDING) {
      bannerContentDisplay = this.context?.resourceManager.getStringSync($r('app.string.hold_calling').id);
    } else {
      const callLabelThird = getCallLabelThird(callData);
      if (callLabelThird) {
        bannerContentDisplay = callLabelThird;
        if (callData.numberMarkInfo.markSource) {
          bannerContentDisplay = bannerContentDisplay + ' | ' + callData.numberMarkInfo.markSource;
        }
      } else {
        bannerContentDisplay = getCallLabelSecondary(callData);
      }
    }
    if (!bannerContentDisplay) {
      bannerContentDisplay = this.context?.resourceManager.getStringSync($r('app.string.incomingCall').id) || ' ';
    }
    return bannerContentDisplay;
  }

  private static isNeedFullScreen() {
    if (isScreenLocked()) {
      LogUtils.i(TAG, 'screen is locked')
      return true;
    }
    if (CallDataManager.getInstance().hasAnyAliveCall()) {
      LogUtils.i(TAG, 'hasAnyAliveCall')
      return true;
    }
    if (isTwoInOne()) {
      LogUtils.i(TAG, 'device not support banner notify， need full screen')
      return true;
    }
    return false;
  }

  private static async isBannerNotificationMeet(): Promise<boolean> {
    let result = false;
    if (await BannerNotificationProxy.hasImmersiveWindow() || await BannerNotificationProxy.isPanelShown()) {
      result = true;
    }
    LogUtils.i(TAG, 'isBannerNotificationMeet ' + result);
    return result;
  }

  private isNeedStartBannerForVoip(callState: number): boolean {
    return callState === CallStateConst.CALL_STATUS_INCOMING || callState === CallStateConst.CALL_STATUS_ANSWER ||
      callState === CallStateConst.CALL_STATUS_ACTIVE || callState === CallStateConst.CALL_STATUS_DIALING;
  }

  private getMuteState(callState: Number, isEcc: boolean = false, isVoipCall: boolean = false) {
    if (isEcc) {
      return Constants.MUTE_BUTTON_DISABLED;
    }
    let result: number | undefined = undefined;
    if (CallStateType.InCallNormal === callState || CallStateType.OutGoingCall === callState) {
      if (isVoipCall) {
        result = AppStorage.get('isVoipMute') as boolean ? 1 : 0;
      } else {
        result = AppStorage.get('isMute') as boolean ? 1 : 0;
      }
      LogUtils.i(TAG, 'current mute state is ' + result);
    }
    return result;
  }

  private getSpeakerState(callState: Number, isVoipCall: boolean = false) {
    if (isVoipCall && CallDataManager.getInstance().getForegroundLiveCall()) {
      return false;
    }
    let isSpeakerOn: boolean | undefined = undefined;
    if (CallStateType.InCallNormal === callState ||
      CallStateType.OutGoingCall === callState) {
      let audioDevice = this.mBottomViewModel.getCurrentAudioDeviceType();
      isSpeakerOn = audioDevice === DEVICE_SPEAKER;
      LogUtils.i(TAG, 'current audioDevice is ' + audioDevice + ' isSpeakerOn is ' + isSpeakerOn);
    }
    return isSpeakerOn;
  }

  private getCapsuleTitle(callState: Number, callType: Number) {
    let result: string = '';
    if (this.context) {
      if (callState === CallStateConst.CALL_STATUS_INCOMING || callState === CallStateConst.CALL_STATUS_WAITING ||
        callState === CallStateConst.CALL_STATUS_ANSWER) {
        result = this.context.resourceManager.getStringSync($r('app.string.incomingCall').id)
      } else if (callState === CallStateConst.CALL_STATUS_DIALING ||
        callState === CallStateConst.CALL_STATUS_ALERTING) {
        result = callType === CallStateConst.TYPE_VOIP ?
        this.context.resourceManager.getStringSync($r('app.string.voip_dialing_banner').id) :
        this.context.resourceManager.getStringSync($r('app.string.dialing').id)
      } else if (callState === CallStateConst.CALL_STATUS_ACTIVE) {
        result = '';
      } else if (callState === CallStateConst.CALL_STATUS_HOLDING) {
        result = this.context.resourceManager.getStringSync($r('app.string.callHold').id)
      }
    }
    return result;
  }

  private fixCapsuleTitleForVoipCall(callState: number, resourceManager: resourceManager.ResourceManager,
    capsuleTitle: string, isConferenceCall?: boolean): string {
    switch (callState) {
      case CallStateConst.CALL_STATUS_ANSWER:
        if (isConferenceCall) {
          capsuleTitle = resourceManager.getStringSync($r('app.string.joining').id);
        } else {
          capsuleTitle = resourceManager.getStringSync($r('app.string.connecting').id);
        }
        break;
      case CallStateConst.CALL_STATUS_DIALING:
        if (isConferenceCall) {
          capsuleTitle = resourceManager.getStringSync($r('app.string.joining').id);
        }
        break;
      case CallStateConst.CALL_STATUS_ACTIVE:
        if (isConferenceCall) {
          capsuleTitle = resourceManager.getStringSync($r('app.string.inTheConference').id);
        }
        break;
    }
    return capsuleTitle;
  }

  public isHeadUpEnabled(isVoip: boolean) {
    let onPageShow: boolean | undefined = AppStorage.get('onPageShow');
    let isFirstVoipCall: boolean | undefined = AppStorage.get('firstVoipCall');
    let isHeadsUp: boolean = true;
    // 第一次收到callservice的信息为true，后面再更新都需要给通知传参为false
    if (onPageShow || (isVoip && !isFirstVoipCall)) {
      isHeadsUp = false;
    } else {
      isHeadsUp = BannerNotificationManager.isHeadsUpEnabled;
      AppStorage.delete('firstVoipCall');
    }
    LogUtils.i(TAG, `isHeadsUp: ${isHeadsUp}`);
    return isHeadsUp;
  }

  private isSimIconDisplay(callData: DefaultCallData) {
    let simCount = AppStorage.get('simCount') || 0;
    return callData.callType === CallStateConst.TYPE_VOIP ? false : simCount > 1;
  }

  private async getCapsuleIconByState(callData: DefaultCallData) {
    let capsuleIcon = await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.CAPSULE_VOICE) as image.PixelMap;
    let isSimShouldDisplay = this.isSimIconDisplay(callData);
    LogUtils.i(TAG, `isSimIconDisplay: ${isSimShouldDisplay}, videoState: ${callData.videoState}`);
    LogUtils.i(TAG, `accountId: ${callData.accountId}, callId: ${callData.callId}`);
    if (isSimShouldDisplay) {
      if (callData.videoState === CallStateConst.VIDEO_STATE_VIDEO && !SystemMode.getInstance().isModePenglai()) {
        if (callData.accountId === 0) {
          capsuleIcon = await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.SIM1_VIDEO) as image.PixelMap;
        } else if (callData.accountId === 1) {
          capsuleIcon = await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.SIM2_VIDEO) as image.PixelMap;
        }
      } else {
        if (callData.accountId === 0) {
          capsuleIcon = await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.SIM1_VOICE) as image.PixelMap;
        } else if (callData.accountId === 1) {
          capsuleIcon = await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.SIM2_VOICE) as image.PixelMap;
        }
      }
    } else {
      if (callData.videoState === CallStateConst.VIDEO_STATE_VIDEO && !SystemMode.getInstance().isModePenglai()) {
        capsuleIcon = await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.CAPSULE_VIDEO) as image.PixelMap;
      } else if (callData.videoState === CallStateConst.VIDEO_STATE_VIDEO && SystemMode.getInstance().isModePenglai()) {
        capsuleIcon = await this.bannerResManager.getCorrespondingPixMap(DarkResIcons.CAPSULE_VOICE) as image.PixelMap;
      }
    }
    return capsuleIcon;
  }

  private getBannerStateByState(callData: DefaultCallData) {
    let isBannerSticky = false;
    switch (callData.callState) {
      case CallStateConst.CALL_STATUS_INCOMING:
      case CallStateConst.CALL_STATUS_WAITING:
      case CallStateConst.CALL_STATUS_ACTIVE:
        isBannerSticky = true;
        break;
      default:
        break;
    }
    return isBannerSticky;
  }

  private getCallTimeState(callData: DefaultCallData): notificationManager.NotificationTime {
    LogUtils.i(TAG, 'getCallTimeState');
    let initialTime = 0;
    let isPaused = false;
    let isInTitle = true;
    switch (callData.callState) {
      case CallStateConst.CALL_STATUS_INCOMING:
      case CallStateConst.CALL_STATUS_WAITING:
        initialTime = 0;
        isPaused = true;
        isInTitle = false;
        break;
      case CallStateConst.CALL_STATUS_DIALING:
      case CallStateConst.CALL_STATUS_ALERTING:
        initialTime = 0
        isPaused = true;
        isInTitle = true;
        break;
      case CallStateConst.CALL_STATUS_ACTIVE:
      case CallStateConst.CALL_STATUS_HOLDING:
        let callTime = this.getConnectTimeMillis(callData);
        if (callTime === undefined) {
          if (callData.callType === CallStateConst.TYPE_VOIP && callData.startTime > 0) {
            initialTime = new Date().valueOf() - (callData.startTime * 1000).valueOf();
            if (initialTime < 0) {
              initialTime = new Date().valueOf() - callData.startTime.valueOf();
            }
          } else {
            initialTime = 0
          }
        } else {
          initialTime = new Date().valueOf() - callTime.startTimestamp;
          if (initialTime < 0) {
            initialTime = 0;
          }
        }
        isPaused = false;
        isInTitle = false;
        break;
      default:
        break;
    }

    let result: notificationManager.NotificationTime = {
      initialTime: initialTime,
      isCountDown: false,
      isPaused: isPaused,
      isInTitle: isInTitle
    };
    LogUtils.i(TAG, 'getCallTimeState' + JSON.stringify(result));
    return result;
  }

  private getConnectTimeMillis(callData: DefaultCallData) {
    let callDataManager = CallDataManager.getInstance();
    let callTime = callDataManager.getCallTime(callData);
    LogUtils.i(TAG, 'getConnectTimeMillis' + JSON.stringify(callTime))
    return callTime;
  }

  private async publishNotification(callData: DefaultCallData, request: notificationManager.NotificationRequest,
    index = 0) {
    if (!isAliveCall(callData)) {
      LogUtils.w(TAG, `publish stop sending. No.${index}`);
      return;
    }
    if (this.mIsStartingAbility) {
      LogUtils.i(TAG, `publish the page is not show. No.${index}`);
      this.mNotificationInfoCache = undefined;
      return;
    }
    if (!getCallById(CallDataManager.getInstance().callList, callData.callId)) {
      LogUtils.w(TAG, `publish call does not exist. No.${index}`);
      return;
    }
    if (this.skip(index)) {
      this.mNotificationInfoCache = undefined;
      return;
    }
    if (this.mCancelList.includes(callData.callId)) {
      LogUtils.i(TAG, `publish canceled callId: ${callData.callId} No.${index}`);
      return;
    }
    LogUtils.i(TAG, `publish start callId: ${callData.callId} No.${index}` +
      ` title len: ${request?.content?.systemLiveView?.title?.length}` +
      ` text len: ${request?.content?.systemLiveView?.text?.length}` +
      ` sendWithInfo extraInfo: ${JSON.stringify(request.extraInfo)}`);
    let curTraceId = hiTraceChain.getId();
    let traceIdIsvalid = hiTraceChain.isValid(curTraceId);
    if (!traceIdIsvalid) {
      curTraceId = hiTraceChain.begin('CalluiNormalCall',
        hiTraceChain.HiTraceFlag.INCLUDE_ASYNC | hiTraceChain.HiTraceFlag.NO_BE_INFO |
        hiTraceChain.HiTraceFlag.DONOT_CREATE_SPAN);
    }

    try {
      await notificationManager.publish(request);
      CallUiEvent.getInstance().send(callData.callId, 'EVENT_NORMAL_CALL_SUCCESS');
      LogUtils.i(TAG, `publish success callId: ${callData.callId} No.${index}`);
    } catch (err) {
      ReportUtil.getInstance().reportIncomingDisplay(DisplayMode.BANNER,Constants.FAILURE);
      CallUiEvent.getInstance().send(callData.callId, 'EVENT_NORMAL_CALL_FAILED');
      this.handlePublishError(err, callData);
      LogUtils.e(TAG, `publish failed callId: ${callData.callId} No.${index}`);
      this.retryPublish(err, request, callData);
    }

    if (!traceIdIsvalid) {
      hiTraceChain.end(curTraceId);
    }
  }

  private async retryPublish(err: BusinessError, request: notificationManager.NotificationRequest,
    callData: DefaultCallData) {
    LogUtils.e(TAG, `retryPublish failed message: ${err?.message}, code: ${err?.code}`);
    // 若publish时若捕获到1600014异常，再执行一次subscribeSystemLiveView注册，再publish消息
    if (err?.code === 1600014) {
      CallManagerService.getInstance().clearNotifiesSubscribed();
      CallManagerService.getInstance().addNotifiesSubscriber();
    } else {
      return;
    }
    try {
      await notificationManager.publish(request);
    } catch (err) {
      LogUtils.e(TAG, `retryPublish failed code: ${err?.code} message:${err?.message}`);
      this.handlePublishError(err, callData);
    }
  }

  private handlePublishError(err: BusinessError, callData: DefaultCallData) {
    if (err.code === 1600009) {
      this.mNotificationInfoCache = undefined;
    }
    CallFaultEventUtil.getInstance().finishBannerNotificationCallEventFault(callData, err.code);
    LogUtils.e(TAG, 'publish failed err: ' + JSON.stringify(err));
  }

  private async publishVoipNotification(callData: DefaultCallData, request: notificationManager.NotificationRequest,
    index: number) {
    if (!isAliveCall(callData)) {
      LogUtils.w(TAG, 'publishVoipNotification: stop publishing');
      return;
    }
    LogUtils.i(TAG, `publishVoipNotification extraInfo: ${JSON.stringify(request.extraInfo)}`);
    if (callData.voipCallAttribute === undefined) {
      return;
    }
    if (!CallManagerService.getInstance().getCallDataByCallId(callData.callId)) {
      LogUtils.w(TAG, 'publish voip notification call does not exist');
      return;
    }
    this.voipBundleName = callData.voipCallAttribute.voipBundleName;
    this.uid = callData.voipCallAttribute.uid;
    request.representativeBundle = {
      bundle: this.voipBundleName
    }
    if (this.uid !== 0) {
      request.representativeBundle.uid = this.uid;
    }
    if (callData.voipCallAttribute.isExpired) {
      LogUtils.i(TAG, 'voip callData is expired, no need publish');
      return;
    }
    if (this.skipVoip(index, callData.callId)) {
      return;
    }
    if (this.mCancelList.includes(callData.callId)) {
      LogUtils.i(TAG, 'publish voip canceled callId : ' + callData.callId);
      return;
    }

    let curTraceId = hiTraceChain.getId();
    let traceIdIsvalid = hiTraceChain.isValid(curTraceId);
    if (!traceIdIsvalid) {
      curTraceId = hiTraceChain.begin('CalluiVoipCall',
        hiTraceChain.HiTraceFlag.INCLUDE_ASYNC | hiTraceChain.HiTraceFlag.NO_BE_INFO |
        hiTraceChain.HiTraceFlag.DONOT_CREATE_SPAN);
    }

    LogUtils.i(TAG, 'publish voip notification start req.id : ' + request.id);
    try {
      await notificationManager.publish(request, await CallUtils.getSysUserId());
      CallUiEvent.getInstance().send(callData.callId, 'EVENT_VOIP_CALL_SUCCESS');
      LogUtils.i(TAG, 'publish voip notification success req.id : ' + request.id);
    } catch (err) {
      CallUiEvent.getInstance().send(callData.callId, 'EVENT_VOIP_CALL_FAILED');
      CallFaultEventUtil.getInstance().finishBannerNotificationCallEventFault(callData, err.code);
      LogUtils.e(TAG, `publish voip notification failed because ${err.code}`);
      this.retryVoipPublish(err, request);
    }

    if (!traceIdIsvalid) {
      hiTraceChain.end(curTraceId);
    }
  }

  private async retryVoipPublish(err: BusinessError, request: notificationManager.NotificationRequest) {
    LogUtils.e(TAG, `retryVoipPublish failed message: ${err?.message}, code: ${err?.code}`);
    // 若publish时若捕获到1600014异常，再执行一次subscribeSystemLiveView注册，再publish消息
    if (err?.code === 1600014) {
      CallManagerService.getInstance().clearNotifiesSubscribed();
      CallManagerService.getInstance().addNotifiesSubscriber();
    } else {
      return;
    }
    try {
      await notificationManager.publish(request, await CallUtils.getSysUserId());
    } catch (err) {
      LogUtils.e(TAG, `retryVoipPublish failed code: ${err?.code} message:${err?.message}`);
    }
  }

  /**
   * get want agent
   *
   * @param { object } data - call data
   *
   * @param { number } operationType - type
   */
  private async getWantAgent(data: DefaultCallData) {
    LogUtils.i(TAG, `getWantAgent voipAbilityName callId: ${data.callId}, callType: ${data.callType}`);
    LogUtils.i(TAG, `voipAbilityName: ${data.voipCallAttribute?.abilityName}`);
    let want: Want = {
      deviceId: '',
      bundleName: Constants.CALL_BUNDLE_NAME,
      abilityName: Constants.CALL_ABILITY_NAME,
      uri: '',
      type: 'phone',
      action: 'callui.event.click',
      parameters: {
        'ability.params.backToOtherMissionStack': true
      },
      entities: []
    };
    if (data.callType === CallStateConst.TYPE_VOIP && want.parameters !== undefined) {
      if (data?.voipCallAttribute?.extensionId == '') {
        want.bundleName = data?.voipCallAttribute?.voipBundleName;
        want.abilityName = data?.voipCallAttribute?.abilityName;
        want.parameters.VoIPCallId = data?.voipCallAttribute?.voipCallId;
        want.parameters.isFromCallKit = true;
        if (data?.voipCallAttribute?.appIndex == undefined || data?.voipCallAttribute?.appIndex == -1) {
          let appIdentity = await bundleManager.getAppCloneIdentity(data?.voipCallAttribute?.uid);
          LogUtils.i(TAG, 'getAppCloneIdentity uid:' + data?.voipCallAttribute?.uid +
            ',appIndex:' + appIdentity?.appIndex);
          data.voipCallAttribute.appIndex = appIdentity?.appIndex;
        }
        want.parameters['ohos.extra.param.key.appCloneIndex'] = data?.voipCallAttribute?.appIndex;
      } else {
        want.abilityName = Constants.CALL_ABILITY_NAME_VOIP;
        want.parameters.callData = data;
      }
      GlobalContextHelper.getContext().set<Want>(Constants.VOIP_ABILITY_WANT, want);
    }

    return WantAgent.getWantAgent({
      wants: [want],
      requestCode: 0,
      actionType: WantAgent.OperationType.START_ABILITY,
      wantAgentFlags: [WantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    });
  }

  private getAppNameFromBundleName(bundleName: string): string {
    let bundleFlags = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_WITH_LABEL;
    let result = '';
    try {
      let bundleResourceInfo = bundleResourceManager.getBundleResourceInfo(bundleName, bundleFlags);
      result = bundleResourceInfo?.label;
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtils.e(TAG, 'getBundleResourceInfo failed: %{public}s' + message);
    }
    if (!result) {
      result = '';
    }
    return result;
  }

  async sendCallNotification(callData: DefaultCallData, forceRefresh: boolean = false, index = 0) {
    LogUtils.i(TAG, `sendCallNotification callData No.${index} : ${callDataToSafeString(callData)}`);
    let isNeedUpdate = this.isNeedUpdate(callData, forceRefresh);
    LogUtils.i(TAG, `sendCallNotification isNeedUpdate: ${isNeedUpdate}, forceRefresh: ${forceRefresh}`);
    if (isNeedUpdate && this.mNotificationInfoCache) {
      let requestBuilder = new NotificationRequestBuilder(ID);
      requestBuilder.setbackgrouncolor();
      requestBuilder.setWantAgent(await this.getWantAgent(callData));
      requestBuilder.setOverlayIcon(await this.getLargeIcon(callData));
      requestBuilder.setTitle(this.mNotificationInfoCache.primaryText);
      //requestBuilder.setSmallIcon(await this.bannerResManager?.getSmallIcon());
      requestBuilder.setText(this.mNotificationInfoCache.secondaryText);
      let callState = this.bannerResManager.getCallState(callData.callState);
      let iconNames = await this.bannerResManager.getIconNamesByState(callState, callData.videoState,
        this.getMuteState(callState, callData.isEcc), this.getSpeakerState(callState));
      requestBuilder.setButton(iconNames);
      requestBuilder.setCapsuleTitle(this.getCapsuleTitle(callData.callState, callData.callType));
      requestBuilder.setCapsuleIcon(await this.getCapsuleIconByState(callData));
      requestBuilder.setHeadsUpEnable(this.isHeadUpEnabled(false));
      requestBuilder.setKeepHeadsUpSticky(this.getBannerStateByState(callData));
      requestBuilder.setSimIconStatus(this.isSimIconDisplay(callData) ? (callData.accountId + 1) : 0);
      requestBuilder.setButtonAccessibilityText(this.getBarriText(iconNames));
      if (callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
        requestBuilder.setNotificationTime(this.getCallTimeState(callData));
      }
      let request = requestBuilder.build();
      this.updateIconPriority(callData, request);
      await this.publishNotification(callData, request, index);
    }
  }

  skip(index: number) {
    if (index && index < this.mNotificationIndex) {
      LogUtils.w(TAG, `callui notification skip No.${index}`);
      return true;
    }
    return false;
  }

  private skipVoip(index: number, callId: number): boolean {
    if (this.mVoipNotificationMap.get(callId) && index < this.mVoipNotificationMap.get(callId)) {
      LogUtils.w(TAG, `callui voip notification skip No.${index} callId:${callId}`);
      return true;
    }
    return false;
  }

  private isNeedUpdate(callData: DefaultCallData, forceRefresh: boolean = false) {
    if (!isAliveCall(callData)) {
      return false;
    }
    let info: NotificationInfo = {
      callId: callData.callId,
      callState: callData.callState,
      isSpeakerOn: AudioDeviceManager.getInstance().isCurSpeaker(),
      videoState: callData.videoState,
      primaryText: getFormatCallLabelPrimary(callData),
      secondaryText: this.bannerContent(callData),
      isDarkMode: this.bannerResManager.isDarkMode(),
      isMuted: AppStorage.get('isMute') as boolean,
      contactAvatar: callData.contactSmallAvatar,
      isHeadsUpEnable: this.isHeadUpEnabled(false)
    }
    if (!this.mNotificationInfoCache || forceRefresh || this.isObjectEqual(this.mNotificationInfoCache, info)) {
      this.mNotificationInfoCache = info;
      return true;
    }
    return false;
  }

  isObjectEqual(cache: NotificationInfo, newInfo: NotificationInfo) {
    if (cache.callId !== newInfo.callId) {
      return true;
    }
    if (cache.callState !== newInfo.callState && this.isValidCallState(newInfo.callState)) {
      return true;
    }
    if (cache.videoState !== newInfo.videoState) {
      return true;
    }
    if (cache.isSpeakerOn !== newInfo.isSpeakerOn) {
      return true;
    }
    if (cache.isMuted !== newInfo.isMuted) {
      return true;
    }
    if (cache.primaryText !== newInfo.primaryText) {
      return true;
    }
    if (cache.secondaryText !== newInfo.secondaryText) {
      return true;
    }
    if (cache.isDarkMode !== newInfo.isDarkMode) {
      return true;
    }
    if (cache.contactAvatar !== newInfo.contactAvatar) {
      return true;
    }
    if (cache.isHeadsUpEnable !== newInfo.isHeadsUpEnable) {
      return true;
    }
    return false;
  }

  isValidCallState(callState: number) {
    switch (callState) {
      case CallStateConst.CALL_STATUS_ACTIVE:
      case CallStateConst.CALL_STATUS_HOLDING:
      case CallStateConst.CALL_STATUS_DIALING:
      case CallStateConst.CALL_STATUS_INCOMING:
      case CallStateConst.CALL_STATUS_WAITING:
        return true;
      default:
        return false;
    }
  }

  setIsStartingAbility(isStartingAbility: boolean): void {
    this.mIsStartingAbility = isStartingAbility;
  }

  isStartingAbility() {
    return this.mIsStartingAbility;
  }

  setReady(isReady: boolean) {
    LogUtils.i(TAG, `setReady ${isReady}`);
    this.mIsNotificationReady = isReady;
  }
}