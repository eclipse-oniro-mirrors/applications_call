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
 * @file: Call data management
 */
import CallStateManager from './CallStateManager';
import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import CallTimeListStruct from '../common/struct/CallTimeListStruct';
import DefaultCallData, { CallDataPatch, callDataPatcher, callDataToSafeString } from '../common/struct/TypeUtils';
import Utils from '../common/utils/utils';
import * as Constants from '../common/utils/Constants';
import Method from '../common/utils/Method';
import { power } from '@kit.BasicServicesKit';
import BannerNotificationManager from './BannerNotificationManager';
import {
  getForegroundCall,
  getForegroundLiveCall,
  isIncomingCall,
  isOutgoingCall,
  isAliveCall,
  getCallById
} from '../common/utils/CallListHelper';
import { ReportUtil, HANGUP_WAKE_UP_SCREEN } from '../common/utils/ReportUtils/ReportUtil';
import VideoCallManager from './VideoCallManager';
import { getFormatNumber } from './PhoneNumberFormatManager';
import { CRS_TONE_NUM, ImsCallMode, VideoStateType } from '../common/utils/VideoCallApi';
import { getContactInfo } from './ContactManager';
import CallUtils from '../common/utils/CallUtils';
import SatelliteCallManager from './SatelliteCallManager';
import AudioDeviceManager from './audio/AudioDeviceManager';
import { NumberMarkManager } from './NumberMarkService';
import sim from '@ohos.telephony.sim';
import { HiCarDeviceInfo, HiCarUtils } from '../common/utils/HiCarUtils';
import ConferenceConst from '../common/constant/ConferenceConst';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { removeWindowListener, terminateSelf } from './TerminateManager';
import { HiCarManager } from './HiCarManager';
import { BehaviorDotting } from '../common/utils/ReportUtils/BehaviorDotting';
import { getSimOperatorConfigsBySlotId } from '../model/SimManager';
import { VisionGlassConstants } from '../common/constant/VisionGlassConstants';
import { ProximityUtils } from '../common/utils/ProximityUtils';
import { emitter } from '@kit.BasicServicesKit';
import { VideoController } from '../controller/VideoController';

const TAG = 'CallDataManager';
const REMOTE_HANGUP = 'remote_hangup';
export enum DisconnectCauses {
  LOCAL_HANGUP,
  REMOTE_HANGUP,
  INCOMING_REJECT,
  REMOTE_CANCEL
}

/**
 * class CallDataManager
 */
export default class CallDataManager {
  public callList: Array<DefaultCallData> = [];
  public callTimeList: Array<CallTimeListStruct> = [];
  private mCallStateManager?: CallStateManager;
  private bannerNotificationManager?: BannerNotificationManager;
  private static sCallDataManager: CallDataManager;
  private mUtils: Utils;
  private callbacks: Function[] = [];
  private timeCount: number = 0;
  private timerToAvPlayer: number = 0;
  private normalBrightScreen: number = 1;
  private abnormalNotBrightScreen: number = 0;

  public static getInstance(): CallDataManager {
    if (!CallDataManager.sCallDataManager) {
      CallDataManager.sCallDataManager = new CallDataManager();
    }
    return CallDataManager.sCallDataManager;
  }

  constructor() {
    this.mUtils = Utils.getInstance();
    this.bannerNotificationManager = BannerNotificationManager.getInstance();
  }

  /**
   * Init data.
   */
  public init(callData: DefaultCallData, callList: DefaultCallData[], callTimeList: CallTimeListStruct[]) {
    LogUtils.i(TAG, 'initCallData');
    this.mCallStateManager = new CallStateManager(callData);
    if (this.callList.length === 0) {
      LogUtils.i(TAG, 'init callList: undefined');
      this.callList = callList;
    } else {
      let oldCallList = this.callList;
      this.callList = callList;
      Method.assign(this.callList, oldCallList);
    }
    this.mCallStateManager.update(getForegroundCall(this.callList));
    if (this.callTimeList.length === 0) {
      LogUtils.i(TAG, 'init callTimeList: undefined');
      this.callTimeList = callTimeList;
    } else {
      let oldCallTimeList = this.callTimeList;
      this.callTimeList = callTimeList;
      Method.assign(this.callTimeList, oldCallTimeList);
    }
  }

  public disconnectClearInfo() {
    ProximityUtils.unHoldProximityLock();
    LogUtils.i(TAG, 'abnormal disconnectClearInfo');
    // destroy page big folding screen
    terminateSelf(Constants.CALL_ABILITY_CONTEXT);
    this.clearData();
    // destroy page small folding screen
    terminateSelf(Constants.EXTERNAL_CALL_ABILITY_CONTEXT);
  }

  public findUnVoiceCall(targetObj: DefaultCallData) {
    const index = this.callList.findIndex((callData) => callData.videoState !== VideoStateType.TYPE_VOICE);
    if (index === -1) {
      VideoCallManager.getInstance().closeVideoMode(targetObj);
    }
  }

  /**
   * update callList and callData callTimeList
   *`
   * @param { object } callData
   */
  public update(patch: CallDataPatch) {
    const callId: number = patch.callId;
    let targetObj = this.callList.find((v: DefaultCallData) => v.callId === callId);
    let callState: number = callDataPatcher.getWithPriority(d => d.callState, patch, targetObj);
    let oldCallState = callState;
    if (targetObj) {
      oldCallState = targetObj.callState;
      let callData = callDataPatcher.merge(targetObj, patch, 'CallDataManager merge');
      if ((Utils.getInstance().isConferenceCall(targetObj)) &&
        targetObj.callState === CallStateConst.CALL_STATUS_DISCONNECTING) {
        callData.callState = CallStateConst.CALL_STATUS_DISCONNECTED;
        callState = CallStateConst.CALL_STATUS_DISCONNECTED;
        LogUtils.i(TAG, `callId:${callId} is already disconnecting, set to disconnected`);
      }
      LogUtils.i(TAG, 'Update existing call callId:' + targetObj.callId);
      BehaviorDotting.getInstance().incomingCallDotting(targetObj, callData);
      VideoCallManager.getInstance().compareOldAndNewCallData(targetObj, callData);
      SatelliteCallManager.getInstance().tryShowSatelliteCallAnswerToast(targetObj, callData);
      if (AppStorage.get<boolean>('isDistributeSink') && !targetObj.contactName && callData.distributedContactName) {
        callData.contactName = callData.distributedContactName;
      }
      this.callList[this.callList.findIndex((v) => v.callId === callId)] = callData;
      targetObj = callData;
    } else {
      if (this.isInvalidCall(callState)) {
        LogUtils.w(TAG, 'invalid call')
        return;
      }
      targetObj = new DefaultCallData();
      callDataPatcher.apply(targetObj, patch, 'create new call data');
      this.addCallList(targetObj);
      this.updateAppCallList();
      if (this.isOnlyIncoming(targetObj)) {
        this.bannerNotificationManager?.setReady(false);
      }
    }

    if (callState === CallStateConst.CALL_STATUS_ACTIVE || callState === CallStateConst.CALL_STATUS_HOLDING) {
      this.updateCallTimeList(targetObj);
    }

    LogUtils.i(TAG, `update callState: ${callState} old: ${oldCallState}`);
    // Drop disconnected call first
    if (callState === CallStateConst.CALL_STATUS_DISCONNECTED) {
      if (callState === oldCallState) {
        return;
      }
      if (targetObj.startTime > 0) {
        BehaviorDotting.getInstance().hungOutDotting(targetObj);
      }
      AppStorage.setOrCreate('hangUp', false);
      if (targetObj.callType !== CallStateConst.TYPE_SATELLITE) {
        AppStorage.setOrCreate('onIndexPage', AppStorage.get('onPageShow'));
        ReportUtil.getInstance().reportDisconnectInfo(targetObj);
        // 对端挂断亮屏
        this.remoteHangupWakeup(targetObj);
      } else if (AppStorage.get<boolean>('isHyacinthMode')) {
        ReportUtil.getInstance().reportHyacinthDisconnect(targetObj);
      }
      AppStorage.setOrCreate('hangUp', false);
      this.releasePixelMap(targetObj);
      LogUtils.i(TAG, `update callList.length : ${this.callList.length}`);
      if (this.callList.length === 1) {
        // For disconnected call, we should notify the latest status to pages before clear it.
        VideoCallManager.getInstance().closeVideoMode(targetObj);
        this.mCallStateManager?.update(targetObj);
        this.releaseUiAbility(targetObj);
        return;
      } else {
        ProximityUtils.wakeUpScreenByProximity();
        this.removeVideoCallDialog(callId);
        this.removeCallById(callId);
        this.findUnVoiceCall(targetObj);
        // 第一路通话结束后，还存在第二路通话，再把第二路的视频铃声恢复
        if (this.callList[0].callState === CallStateConst.CALL_STATUS_INCOMING) {
          this.timerToAvPlayer = setTimeout(() => {
            VideoController.getInstance().reRinging();
          }, 1000);
        }
      }
    }
    this.replacePrimaryCall();
  }

  public isInvalidCall(callState: number): boolean {
    return callState === CallStateConst.CALL_STATUS_DISCONNECTED ||
      callState === CallStateConst.CALL_STATUS_DISCONNECTING;
  }

  private remoteHangupWakeup(callData: DefaultCallData): void {
    let callTime: CallTimeListStruct | undefined =
      CallDataManager.getInstance().getCallTimeObjByCallId(callData.callId);
    let callDuration: number = callTime !== undefined ? callTime.endTimestamp - callTime.startTimestamp : 0;
    let disconnectCause: number = ReportUtil.getInstance().getCallDisconnectCause(callDuration);
    if (disconnectCause === DisconnectCauses.REMOTE_HANGUP) {
      try {
        power.wakeup(REMOTE_HANGUP);
        AppStorage.setOrCreate(HANGUP_WAKE_UP_SCREEN, this.normalBrightScreen);
        LogUtils.i(TAG, `wakeup success, disconnectCause: ${disconnectCause}`);
      } catch (err) {
        AppStorage.setOrCreate(HANGUP_WAKE_UP_SCREEN, this.abnormalNotBrightScreen);
        LogUtils.e(TAG, `wakeup failed, err: ${err?.code}`);
      }
    }
  }

  private releaseUiAbility(targetObj: DefaultCallData) {
    const reason = CallUtils.getDisconnectedReason(targetObj);
    const isNativeHangUp = AppStorage.get<boolean>('nativeHangUp');
    let delay = 0;
    switch (reason) {
      case Constants.CALL_DISCONNECTED_BY_REMOTE:
        delay = 1000;
        break;
      default:
        LogUtils.e(TAG, `releaseUiAbility reason is ${reason}`);
        break;
    }
    LogUtils.i(TAG, `releaseUiAbility callId: ${targetObj.callId}, length: ${this.callList.length}`);
    this.bannerNotificationManager?.cancelNotification(targetObj.callId);
    // remove Proximity Listener
    ProximityUtils.unHoldProximityLock();
    if (isNativeHangUp) {
      delay = 180;
    }
    if (delay === 0) {
      this.clearCall(targetObj);
      return;
    }
    setTimeout(() => {
      LogUtils.i(TAG, `releaseUiAbility execute callId: ${targetObj.callId}, length: ${this.callList.length}`);
      if (getCallById(this.callList, targetObj.callId)) {
        if (this.callList.length > 1) {
          this.removeCallById(targetObj.callId);
        } else {
          this.clearCall(targetObj);
        }
      }
    }, delay);
  }

  private releasePixelMap(callData: DefaultCallData): void {
    if (callData.contactAvatar) {
      LogUtils.i(TAG, 'contactAvatar is release');
      callData.contactAvatar.release();
    }
    if (callData.contactSmallAvatar) {
      LogUtils.i(TAG, 'contactSmallAvatar is release');
      callData.contactSmallAvatar.release();
    }
  }

  replacePrimaryCall() {
    // Then, find the foreground call and notify
    let call = getForegroundCall(this.callList);
    if (!call) {
      LogUtils.e(TAG, 'Invalid call state! cannot find foreground call! callList size = ' + this.callList.length);
      return;
    }
    if (call.callState === CallStateConst.CALL_STATUS_HOLDING) {
      if (this.callList.length > 1 && (call.conferenceState === ConferenceConst.TEL_CONFERENCE_IDLE ||
        call.conferenceState === ConferenceConst.TEL_CONFERENCE_DISCONNECTED)) {
        return;
      }
    }
    // update video call.
    VideoCallManager.getInstance().videoCallStateUpdate(call, this.callList);

    // update External call.
    AppStorage.setOrCreate<DefaultCallData>(Constants.CALL_DATA, call);
    this.mCallStateManager?.update(call);
    emitter.emit(Constants.UPDATE_VIDEO_RINGTONE_EVENT);
    if (this.sendNotification) {
      this.sendNotification(call);
    }
    ProximityUtils.updateProximityLock(call);
  }

  public getForegroundCall() {
    return getForegroundCall(this.callList);
  }

  public getForegroundLiveCall() {
    return getForegroundLiveCall(this.callList);
  }

  public async clearCall(callData: DefaultCallData) {
    LogUtils.i(TAG, 'clearCall');
    terminateSelf(Constants.EXTERNAL_CALL_ABILITY_CONTEXT);
    terminateSelf(Constants.HICAR_CALL_ABILITY_CONTEXT);
    const numberMarkManager = NumberMarkManager.getInstance();
    await numberMarkManager.beginNumberMarkSteps(callData);
    this.removeCallById(callData.callId);
    removeWindowListener();
    terminateSelf(Constants.CALL_ABILITY_CONTEXT);
    this.clearData();
  }

  public sendNotification(callData: DefaultCallData): void {
    if (callData) {
      this.bannerNotificationManager?.sendBannerNotification(callData);
    }
  }

  public getCallTime(callData: DefaultCallData) {
    let callTimeList = this.callTimeList;
    const callTime = callTimeList.find((item: CallTimeListStruct) => {
      return item.callId === callData.callId && this.isActiveCall(item.callId)
    });
    return callTime;
  }

  public getCallTimeObjByCallId(callId: number) {
    let callTimeList = this.callTimeList;
    let callTime = callTimeList.find((item: CallTimeListStruct) => {
      return item.callId === callId;
    });
    return callTime;
  }

  public getCallByCallId(callId: number) {
    let callDataList = this.callList;
    let callData = callDataList.find((call: DefaultCallData) => (
      call.callId === callId));
    return callData;
  }

  /**
   * Judge whether the call exists.
   */
  public hasAliveCall() {
    const callData = this.callList.find((call: DefaultCallData) => call.callState !==
    CallStateConst.CALL_STATUS_DISCONNECTED && call.callState !== CallStateConst.CALL_STATUS_DISCONNECTING);
    LogUtils.i(TAG, 'hasAliveCall:' + JSON.stringify(callData !== undefined));
    return callData !== undefined;
  }

  /**
   * Judge whether the incoming call exists.
   */
  public hasIncomingCall() {
    const callData = this.callList.find((call: DefaultCallData) => call.callState ===
    CallStateConst.CALL_STATUS_INCOMING || call.callState === CallStateConst.CALL_STATUS_WAITING);
    LogUtils.i(TAG, 'hasIncomingCall:' + JSON.stringify(callData !== undefined));
    return callData !== undefined;
  }

  /**
   * 判断是否存在呼出的通话
   */
  public existDialingCall() {
    return this.callList.some((call: DefaultCallData) => call.callState ===
    CallStateConst.CALL_STATUS_DIALING || call.callState === CallStateConst.CALL_STATUS_ALERTING);
  }

  public hasCrsCall(): boolean {
    const callData = this.callList.find((call: DefaultCallData) => call.crsType === CRS_TONE_NUM && (call.callState ===
    CallStateConst.CALL_STATUS_INCOMING || call.callState === CallStateConst.CALL_STATUS_WAITING));
    LogUtils.i(TAG, 'hasCrsCall:' + JSON.stringify(callData !== undefined));
    return callData !== undefined;
  }

  public hasAnyAliveCall() {
    let size = this.callList.filter((callData): boolean => isAliveCall(callData)).length;
    return size > 1;
  }

  /**
   * Judge whether the call exists.
   */
  public hasActiveCall(): boolean {
    const callData = this.callList.find((call: DefaultCallData) => (call.callState ===
    CallStateConst.CALL_STATUS_ACTIVE || call.callState === CallStateConst.CALL_STATUS_HOLDING));
    return callData !== undefined;
  }

  /**
   * Judge whether the call is active or holding.
   */
  public isActiveCall(callId: number): boolean {
    const callData = this.callList.find((call: DefaultCallData) => call.callId === callId && (call.callState ===
    CallStateConst.CALL_STATUS_ACTIVE || call.callState === CallStateConst.CALL_STATUS_HOLDING));
    return callData !== undefined;
  }

  public isOnlyIncoming(callData: DefaultCallData) {
    return this.callList.length === 1 && callData.callState === CallStateConst.CALL_STATUS_INCOMING;
  }

  /**
   * addCallList
   *
   * @param { object } callData
   */
  private addCallList(targetObj: DefaultCallData) {
    if (isOutgoingCall(targetObj.callState)) {
      targetObj.callDirection = CallStateConst.CALL_DIRECTION_OUTGOING;
    } else if (isIncomingCall(targetObj.callState)) {
      targetObj.callDirection = CallStateConst.CALL_DIRECTION_INCOMING;
    }

    LogUtils.i(TAG, 'addCallList');
    this.callList.push(targetObj);

    getSimOperatorConfigsBySlotId(targetObj.accountId);
    if (CallUtils.isInvalidNumber(targetObj.accountNumber)) {
      targetObj.isInvalidNumber = true;
    } else {
      sim.getVoiceMailNumber(targetObj.accountId).then((voiceMailNumber) => {
        const isVoiceMailNumber = voiceMailNumber === targetObj.accountNumber;
        LogUtils.i(TAG, `current number isVoiceMailNumber: ${isVoiceMailNumber}`);
        if (!isVoiceMailNumber) {
          return;
        }
        const patch: CallDataPatch = callDataPatcher.createPatch({
          callId: targetObj.callId,
          isVoiceMailNumber: true,
        });
        CallDataManager.getInstance().updateCallerInfo(patch);
      }).catch((err: object) => {
        LogUtils.e(TAG, `getVoiceMailNumber failed, error: ${JSON.stringify(err)}`);
      });
      getContactInfo(targetObj).then((callData) => {
        NumberMarkManager.getInstance().addCallLogCheckTask(callData);
      }).catch((err: object) => {
        LogUtils.e(TAG, 'getContactInfo error');
      })
      getFormatNumber(targetObj);
    }
  }

  public updateCallerInfo(callData: CallDataPatch) {
    let targetObj = this.callList.find((v: DefaultCallData) => v.callId === callData.callId);
    if (targetObj) {
      this.update(callData);
    } else {
      LogUtils.w(TAG, 'updateCallerInfo, no call');
    }
  }

  /**
   * remove call by call id
   *
   * @param { object } callId - call id
   */
  public removeCallById(callId: number) {
    const index = this.callList.findIndex((v: DefaultCallData) => v.callId === callId);
    if (index === -1) {
      LogUtils.e(TAG, 'removeCallById: invalid callId');
      return;
    }
    LogUtils.i(TAG, 'Remove from callList ' + callId);
    this.callList.splice(index, 1);
    this.updateAppCallList();

    const timeListIndex = this.callTimeList.findIndex((v: CallTimeListStruct) => v.callId === callId);
    if (timeListIndex !== -1) {
      LogUtils.i(TAG, 'Remove from callTimeList ' + callId);
      this.callTimeList.splice(timeListIndex, 1);
    }

    let callDataIndex = this.callList.findIndex((v: DefaultCallData) => v.callState !==
    CallStateConst.CALL_STATUS_INCOMING && v.callState !== CallStateConst.CALL_STATUS_WAITING);
    if (callDataIndex === -1) {
      ReportUtil.getInstance().stopPrivacyPermission();
    }
  }

  private removeVideoCallDialog(callId: number) {
    if (!AppStorage.get('acceptVideoCallDialog')) {
      return;
    }
    const index = this.callList.findIndex((v: DefaultCallData) => v.callId === callId);
    if (index === -1) {
      return;
    }
    if (this.callList[index]?.imsCallMode === ImsCallMode.CALL_MODE_SEND_RECEIVE) {
      LogUtils.i(TAG, `remove video call dialog`);
      AppStorage.setOrCreate('acceptVideoCallDialog', false);
    }
  }

  /**
   * update callTimeList
   *
   * @param { object } callData
   */
  private updateCallTimeList(callData: DefaultCallData) {
    const callTimeObj = this.callTimeList.find((v: CallTimeListStruct) => v.callId === callData.callId);
    LogUtils.i(TAG, 'updateCallTimeList : ' + JSON.stringify(callTimeObj));
    if (!callTimeObj && callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      const obj: CallTimeListStruct = {
        callId: callData.callId,
        callTime: '00:00',
        startTimestamp: (callData.startTime * 1000).valueOf() || new Date().valueOf(),
        endTimestamp: 0,
      };
      this.callTimeList.push(obj);
      this.refreshCallTime();
    }
  }

  public refreshCallTime() {
    if (!this.hasActiveCall()) {
      LogUtils.i(TAG, 'no active calls to update');
      return;
    }
    let timer: number = 0;
    let diffSecondss: number = 0;
    let callTimeListt = this.callTimeList;
    callTimeListt.forEach((item: CallTimeListStruct, i: number) => {
      if (this.isActiveCall(item.callId)) {
        item.endTimestamp = new Date().valueOf();
        let diffSeconds = item.endTimestamp - item.startTimestamp;
        diffSecondss = diffSeconds;
        item.callTime = this.mUtils.formatTime(diffSeconds);
        this.callTimeList.splice(i, 1, JSON.parse(JSON.stringify(item)));
        this.callbacks.forEach((fn: Function) => {
          fn(this.callTimeList);
        });
      }
    });
    timer = setTimeout(() => {
      this.refreshCallTime();
      clearTimeout(timer);
    }, 1000 - diffSecondss % 1000);
    let powerClickFlag: boolean | undefined = AppStorage.get('screenOff');
    let onPageShow: boolean | undefined = AppStorage.get('onPageShow');
    let onExternalPageShow: boolean | undefined = AppStorage.get('onExternalPageShow');
    const onHiCarPageShow: boolean = HiCarManager.getInstance().getIsHiCarPageShow();
    LogUtils.i(TAG, `refreshCallTime: powerClickFlag: ${powerClickFlag}, onPageShow: ${onPageShow}`);
    LogUtils.i(TAG, `refreshCallTime: onExternalPageShow: ${onExternalPageShow}, onHiCarPageShow: ${onHiCarPageShow}`);
    if (!onHiCarPageShow && (powerClickFlag || (!onPageShow && !onExternalPageShow))) {
      this.timeCount++;
      if (this.timeCount >= 6) {
        LogUtils.i(TAG, 'callTimeList: clearTimeout: ' + JSON.stringify(timer));
        clearTimeout(timer);
        this.timeCount = 0;
      }
    }
    diffSecondss = 0;
    callTimeListt = [];
  }

  addTimeUpdateCallback(fn: Function): void {
    this.callbacks.push(fn);
  }

  removeTimeUpdateListener(): void {
    this.callbacks = [];
  }

  removeTimeUpdateCallback(fn: Function): void {
    let index: number = this.callbacks.indexOf(fn);
    if (index < 0 || index >= this.callbacks.length) {
      return;
    }
    this.callbacks.splice(index, 1);
    LogUtils.i(TAG, `removeTimeUpdateCallback index=${index}`);
  }

  hasTimeUpdateCallback(fn: Function): boolean {
    return this.callbacks.find(item => item === fn) !== undefined;
  }

  async clearData() {
    LogUtils.i(TAG, 'clearData');
    this.mCallStateManager = undefined;
    this.callList = [];
    this.callTimeList = [];
    CallColumnUtils.getInstance().clearFontCollection();
    AudioDeviceManager.getInstance().release();
    if (AppStorage.has('clearStorage')) {
      CallDataManager.getInstance().clearStorage();
    } else {
      AppStorage.setOrCreate('clearStorage', true);
    }
    clearTimeout(this.timerToAvPlayer);
  }

  clearStorage() {
    LogUtils.i(TAG, 'clearStorage');
    AppStorage.delete('TextInput');
    AppStorage.delete('TextInputValue');
    AppStorage.delete('isShowVideoKeyBoard');
    AppStorage.delete('onAnswer');
    AppStorage.delete('notificationManager');
    AppStorage.delete(Constants.BANNER_TAG);
    AppStorage.delete('callEventChange');
    AppStorage.delete('incomingCenterPoint');
    AppStorage.delete('dataList');
    AppStorage.delete('currentAudioDeviceIcon');
    AppStorage.delete('curBp');
    AppStorage.delete('animationFinish');
    AppStorage.delete('isOnAnswerForMulti');
    AppStorage.delete('powerClickFlag');
    AppStorage.setOrCreate('hangUp', false);
    AppStorage.delete('hangUp');
    AppStorage.delete('nativeHangUp');
    AppStorage.delete('isMute');
    AppStorage.delete('isVoipMute');
    AppStorage.delete('LockIncomingCenterPoint');
    AppStorage.delete('lockAnswerOn');
    AppStorage.delete('LockIncomingTranslate');
    AppStorage.delete('speakerSelected');
    AppStorage.delete('onPageShow');
    AppStorage.delete('screenOff');
    AppStorage.delete('clearStorage');
    AppStorage.delete('recorderStatus');
    AppStorage.delete('autoRecordCall');
    AppStorage.delete('recorderFirstInit');
    AppStorage.delete('isAutoOpenSpeaker');
    AppStorage.delete('audioDeviceList');
    AppStorage.delete('clickMergeAction');
    AppStorage.delete(Constants.STRANGE_NUMBER_CALL_DATA);
    AppStorage.delete('Density');
    AppStorage.delete(Constants.WINDOW);
    AppStorage.delete('strangeNumberCallData');
    AppStorage.delete('isSupportAnswerStatus');
    AppStorage.delete('simOperatorNameFirst');
    AppStorage.delete('simOperatorNameSecond');
    AppStorage.delete(VisionGlassConstants.SHOW_IN_VISION_GLASS);
    AppStorage.delete('isStartAutoAnswerService');
    AppStorage.delete('TwoWayPrivacyEnhancedCall');
    AppStorage.delete('cover_window_showing');
    AppStorage.delete('isPickup');
    this.clearVideoStorage();
    this.clearExternalStorage();
  }

  clearVideoStorage() {
    AppStorage.delete('videoCameraInfo');
    AppStorage.delete('cameraState');
    AppStorage.delete('statusBarHeight');
    AppStorage.delete('navigationHeight');
    AppStorage.delete('hidePeerVideoScreen');
    LogUtils.i(TAG, `clear accept video call dialog key`);
    AppStorage.delete('acceptVideoCallDialog');
    AppStorage.delete('currentScreenAspectRatio');
    AppStorage.delete('surfaceId');
    AppStorage.delete('peerSurfaceId');
    AppStorage.delete('LandscapeOrPortrait');
    AppStorage.delete('FoldStatus');
    AppStorage.delete('windowSizeChangeMd');
    AppStorage.delete('CurrentOrientation');
    AppStorage.delete('peerScreenAspectRatio');
    AppStorage.delete('isRbtError');
    AppStorage.delete('currentCameraState');
    AppStorage.delete(Constants.CALL_LIST);
  }

  clearExternalStorage() {
    AppStorage.delete(Constants.CALL_DATA);
    AppStorage.delete(Constants.EXTERNAL_LEFT_ICON);
    AppStorage.delete(Constants.EXTERNAL_RIGHT_ICON);
    AppStorage.delete(Constants.EXTERNAL_BOTTOM_ICON);
    AppStorage.delete(Constants.EXTERNAL_CALL_ABILITY_CONTEXT);
    AppStorage.delete(Constants.IS_MULTI_DEVICE);
    AppStorage.delete(Constants.VOICE_CONTROL_SWITCH);
    AppStorage.delete(Constants.VOICE_BROADCAST_SWITCH);
  }

  private updateAppCallList(): void {
    // HiCarUtils.getHiCarDeviceInfo().then((deviceInfo: HiCarDeviceInfo | undefined) => {
    //   if (deviceInfo?.connectStatus) {
    //     AppStorage.setOrCreate<Array<DefaultCallData>>(Constants.CALL_LIST, this.callList);
    //   }
    // });
  }
}
