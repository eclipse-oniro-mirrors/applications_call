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

import BaseViewModel from './base/BaseViewModel';
import LogUtils from '../common/utils/LogUtils';
import calendarManager from '@ohos.calendarManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import common from '@ohos.app.ability.common';
import { StringUtil } from '../common/utils/StringUtil';
import sms from '@ohos.telephony.sms';
import { BusinessError } from '@ohos.base';
import DefaultCallData from '../common/struct/TypeUtils';
import CallStateConst from '../common/constant/CallStateConst';
import CallServiceProxy from '../model/CallServiceProxy';
import * as IncomingModel from '../model/configs/IncomingModel';
import { remindObj } from '../common/dialog/RemindObj';
import {
  getActualCallCount,
  getOutgoingCall,
  getSecondaryIncomingCall,
  getVideoCall,
  isActiveCall,
  isIncomingCall,
  isSecondaryCallWaiting,
  isVideoCall,
} from '../common/utils/CallListHelper';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import { CRS_TONE_NUM, setDisplayWindowApi } from '../common/utils/VideoCallApi';
import VideoCallManager from '../model/VideoCallManager';
import { CallFaultEventUtil } from '../common/utils/ReportUtils/CallFaultEventUtil';
import Utils from '../common/utils/utils';
import { removeWindowListener, terminateSelf } from '../model/TerminateManager';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import { display } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';
import { isScreenLocked } from '../common/utils/DeviceTypeUtils';
import { VideoController } from '../controller/VideoController';
import BannerNotificationManager from '../model/BannerNotificationManager';

const TAG = 'IncomingComVM';
/**
 * SMS sent successfully
 */
const SEND_SMS_SUCCESS = 0;

export default class IncomingComVM extends BaseViewModel<IncomingComVM> {
  private static sIncomingComVM: IncomingComVM;
  public isMuted: boolean = false;
  public mMuteEnabledListener: (boolean: boolean) => void = (arg) => arg;
  public primaryIncomingCall: DefaultCallData = new DefaultCallData();
  public callList: Array<DefaultCallData> = [];
  public remindList: Array<remindObj> = [];
  public btnList: IncomingModel.btn[] = [];

  public static getInstance(): IncomingComVM {
    if (!IncomingComVM.sIncomingComVM) {
      IncomingComVM.sIncomingComVM = new IncomingComVM();
    }
    return IncomingComVM.sIncomingComVM;
  }

  aboutToAppear() {
    this.btnList = IncomingModel.inComingBtnList;
    ReportUtil.getInstance().reportDualCallPoint(this.primaryIncomingCall);
  }

  initData(callData: DefaultCallData, callList: Array<DefaultCallData>) {
    // If we are entering into here, the callData should be the primary incoming call!
    this.primaryIncomingCall = callData;
    this.callList = callList;
    this.btnList =
      IncomingModel.getInComingBtnListByVideoState(isVideoCall(callData.videoState), callData.isInvalidNumber);
  }

  /**
   * Solve conflicts when incoming
   * These logics are only could apply to DUAL SIM device, TRIPLE SIM is not supported!
   *
   * Basic concepts:
   * - Primary incoming call: the call will display inside this component (must non-null)
   * - Secondary incoming call: the call will display in CallList component (might be null)
   * - Primary call list: the calls list for only belong to primary incoming call's account id
   * - Secondary call list: the calls list for only belong to secondary incoming call's account id (might be empty)
   * - Connected calls: the calls was once connected, its state could be ACTIVE or HOLD
   *
   * Basic rules:
   * - For every SIM card, could only have one incoming call, so we could contains up to 2 incoming calls
   * - Priority for multi incoming calls: The larger call id to have the higher priority (later-higher)
   * - We could only contains 1 active call
   * - We could only contains 1 conference call
   * - We could only contains up to 2 connected calls
   * - Due to the modem limitation, the secondary call waiting should be a conflicts
   *   (SecondarySIM: ACTIVE & INCOMING; Primary-SIM: INCOMING)
   * - Call priority when conflicts: INCOMING (WAITING) > ACTIVE > HOLD > DIALING
   *
   * @returns solved conflicts label
   */
  public getDsdaConflictsLabel(): Resource {
    if (this.callList.length <= 1) {
      return $r('app.string.emptyStr');
    }

    const simCount: number | undefined = AppStorage.get('simCount');
    if (!simCount || simCount <= 1) {
      return this.oneSimReminderString();
    }

    // Basically, if we entering into this components, we are under incoming call case.
    if (!isIncomingCall(this.primaryIncomingCall.callState)) {
      LogUtils.e(TAG, 'getDsdaConflictsLabel: Invalid call state: no incoming call exists!');
      return $r('app.string.emptyStr');
    }

    // Step 1: Check dialing call.
    // If any dialing call exists, conflicts! (Only DSDA will met this situation)
    // In the same way, if video outgoing call exits, also conflicts!
    let outgoingCall = getOutgoingCall(this.callList);
    if (outgoingCall) {
      return this.outgoingCallFunc(outgoingCall);
    }

    let videoCall = getVideoCall(this.callList);
    if (videoCall && !isIncomingCall(videoCall.callState)) {
      // Conflicts, active video call!
      // For incoming video call, we should process it as a normal call.
      LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - active video call exists, callId = ' + videoCall.callId +
        ', callState = ' + videoCall.callState);
      return $r('app.string.incoming_conflicts_drop_existing_call');
    }

    // Beside dialing cases, we should check the ACTUAL call count next
    let actualCallCount = getActualCallCount(this.callList);

    // Step 3: Double-check 1-way call for conference case
    if (actualCallCount <= 1) {
      LogUtils.i(TAG, 'getDsdaConflictsLabel: PASS - 1-way call');
      return $r('app.string.emptyStr');
    }

    let secondaryIncoming = getSecondaryIncomingCall(this.callList);

    // Step 4: Check 2-way call
    if (actualCallCount === 2) {
      return this.getDsdaConflictsLabelForTwoWayCall(secondaryIncoming);
    }

    if (actualCallCount == 3) {
      return this.getDsdaConflictsLabelForThreeWayCall(secondaryIncoming);
    }

    // Step 6: 4-calls situation, always conflicts!
    LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - 4-calls!');
    return $r('app.string.incoming_conflicts_drop_existing_call');
  }

  private outgoingCallFunc(outgoingCall: DefaultCallData): Resource {
    if (isVideoCall(outgoingCall.videoState) || isVideoCall(this.primaryIncomingCall.videoState)) {
      LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - dialing call exists with video');
      return $r('app.string.incoming_conflicts_drop_existing_call');
    } else {
      LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - dialing call exists');
      return $r('app.string.incoming_conflicts_drop_current_call');
    }
  }

  private oneSimReminderString(): Resource {
    let CALL_STATUS_ACTIVE: boolean = false;
    let CALL_STATUS_HOLDING: boolean = false;
    for (let call of this.callList) {
      if (call.callState === CallStateConst.callStateObj.CALL_STATUS_ACTIVE) {
        CALL_STATUS_ACTIVE = true;
      }
      if (call.callState === CallStateConst.callStateObj.CALL_STATUS_HOLDING) {
        CALL_STATUS_HOLDING = true;
      }
    }
    LogUtils.i(TAG, `STATUS_ACTIVE value' ${CALL_STATUS_ACTIVE}, STATUS_HOLDING value' ${CALL_STATUS_HOLDING}`);
    if (CALL_STATUS_ACTIVE && CALL_STATUS_HOLDING) {
      LogUtils.i(TAG, 'one sim three alert message');
      return $r('app.string.incoming_conflicts_drop_holding_call');
    }
    LogUtils.i(TAG, 'getDsdaConflictsLabel: PASS - not DSDA');
    return $r('app.string.emptyStr');
  }

  private getDsdaConflictsLabelForThreeWayCall(secondaryIncoming: DefaultCallData | undefined): Resource {
    if (isVideoCall(this.primaryIncomingCall.videoState)) {
      // Conflicts if video incoming for 3-way call case!
      LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - 3-way with video incoming!');
      return $r('app.string.incoming_conflicts_drop_existing_call');
    }

    if (secondaryIncoming) {
      if (isSecondaryCallWaiting(this.callList, this.primaryIncomingCall)) {
        LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - secondary call waiting!');
        return $r('app.string.incoming_conflicts_drop_current_call');
      }

      // No conflicts for other 2-incoming cases
      LogUtils.i(TAG, 'getDsdaConflictsLabel: PASS - 3-calls with 2-incoming');
      return $r('app.string.emptyStr');
    }

    // Conflicts if only one incoming call
    LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - 3-calls with 1-incoming');
    return $r('app.string.incoming_conflicts_drop_holding_call');
  }

  private getDsdaConflictsLabelForTwoWayCall(secondaryIncoming: DefaultCallData | undefined): Resource {
    if (secondaryIncoming !== undefined) {
      ReportUtil.getInstance().reportDualCardIncomingCall(secondaryIncoming.callId);
    }
    if (isVideoCall(this.primaryIncomingCall.videoState) && secondaryIncoming === undefined) {
      // Conflicts if video incoming!
      LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - video incoming!');
      const otherCall: DefaultCallData | undefined = this.callList.find((val) => val.callId !==
      this.primaryIncomingCall.callId);
      if (otherCall && isVideoCall(otherCall.videoState) && isActiveCall(otherCall.callState)) {
        return $r('app.string.incoming_conflicts_drop_existing_call');
      }
      return $r('app.string.incoming_conflicts_video_call');
    } else if (secondaryIncoming && secondaryIncoming.crsType === CRS_TONE_NUM) {
      // Conflicts if secondary incoming is CRS!
      LogUtils.i(TAG, 'getDsdaConflictsLabel: CONFLICTS - secondary CRS incoming!');
      return $r('app.string.incoming_conflicts_drop_current_call');
    } else {
      LogUtils.i(TAG, 'getDsdaConflictsLabel: PASS - call count = 2');
      return $r('app.string.emptyStr');
    }
  }

  public hasSecondaryIncoming(): boolean {
    return !!getSecondaryIncomingCall(this.callList);
  }

  public getRemindList() {
    this.remindList = IncomingModel.remindList;
  }

  public sendRemind(obj: remindObj): void {
    if (isScreenLocked()) {
      this.lockScreenSendRemind(obj);
    } else {
      this.unlockScreenSendRemind(obj);
    }
  }

  // instrument ignore next
  private unlockScreenSendRemind(obj: remindObj): void {
    const array: Permissions [] = ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'];
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.requestPermissionsFromUser(GlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT), array).then((data) => {
        LogUtils.i(TAG, 'sendRemind requestPermissionsFromUser');
        let grantStatus: number[] = data.authResults;
        if (grantStatus[0] === 0 && grantStatus[1] === 0) {
          this.getCalendar(true, obj);
          return;
        }
        let dialogShownResults: boolean[] | undefined = data.dialogShownResults;
        if (dialogShownResults && (!dialogShownResults[0] || !dialogShownResults[1])) {
          atManager.requestPermissionOnSetting(GlobalContextHelper.getContext()
            .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT), array).then((data) => {
            LogUtils.i(TAG, 'sendRemind requestPermissionOnSetting');
            let isSetAuth = (data.length > 1 && data[0] === 0 && data[1] === 0);
            this.getCalendar(isSetAuth, obj);
          })
        } else {
          this.getCalendar(false, obj);
        }
      })
    } catch (err) {
      LogUtils.e(TAG, `requestPermissions err. message:${err?.message}`);
    }
  }

  // instrument ignore next
  private lockScreenSendRemind(obj: remindObj) {
    let bundleName = Constants.CALL_BUNDLE_NAME;
    let appFlags = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
    let applicationInfo = bundleManager.getApplicationInfoSync(bundleName, appFlags);
    let tokenId = applicationInfo?.accessTokenId;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.checkAccessToken(tokenId, 'ohos.permission.READ_CALENDAR')
        .then((readData: abilityAccessCtrl.GrantStatus) => {
          LogUtils.i(TAG, `sendRemind checkAccessToken read success`);
          atManager.checkAccessToken(tokenId, 'ohos.permission.WRITE_CALENDAR')
            .then((writeData: abilityAccessCtrl.GrantStatus) => {
              LogUtils.i(TAG, `sendRemind checkAccessToken write success`);
              if (readData === 0 && writeData === 0) {
                this.getCalendar(true, obj)
              } else {
                Utils.getInstance().showToast($r('app.string.unlock_try_again'));
              }
            }).catch((err: BusinessError) => {
              LogUtils.e(TAG, `sendRemind checkAccessToken write fail. message:${err?.message}`);
              Utils.getInstance().showToast($r('app.string.unlock_try_again'));
            });
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `sendRemind checkAccessToken read fail. message:${err?.message}`);
          Utils.getInstance().showToast($r('app.string.unlock_try_again'));
        });
    } catch (err) {
      LogUtils.e(TAG, `checkAccessToken err. message:${err?.message}`);
    }
  }

  // instrument ignore next
  private getCalendar(isAuth: boolean, obj: remindObj) {
    if (!isAuth) {
      Utils.getInstance().showToast($r('app.string.CALENDAR_ACCESS_TOAST'));
      return;
    }
    let callBackTitle: string = this.primaryIncomingCall?.contactName + this.primaryIncomingCall?.accountNumber;
    let calendar: calendarManager.Calendar | undefined = undefined;
    let currentCalendarManager: calendarManager.CalendarManager =
      calendarManager.getCalendarManager(GlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT));
    try {
      currentCalendarManager.getCalendar().then((data) => {
        LogUtils.i(TAG, `sendRemind succeeded in get calendar. callId = ${this.primaryIncomingCall?.callId}`);
        calendar = data;
        const date = new Date();
        const event: calendarManager.Event = {
          type: calendarManager.EventType.NORMAL,
          startTime: date.getTime() + obj.value * 60 * 1000,
          endTime: date.getTime() + (obj.value + 12 * 60) * 60 * 1000,
          title: StringUtil.formatResourceToString($r('app.string.callBack'), callBackTitle),
          reminderTime: [0],
        };
        calendar.addEvent(event, (err: BusinessError, data: number): void => {
          LogUtils.i(TAG, `sendRemind Succeeded in adding calendar event ${data}`);
          this.onReject();
        });
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `failed in get calendar, message:${err?.message}`);
        this.onReject();
      })
    } catch (err) {
      LogUtils.e(TAG, `getCalendar err. message:${err?.message}`);
    }
  }

  /**
   * send Message   slotId : card slot, destinationHost : accountNumber ,content: content
   *
   * @param msg
   */
  public sendMessageAndRejectCall(msg: string) {
    let slotId = this.primaryIncomingCall.accountId;
    let destinationHost = this.primaryIncomingCall.accountNumber
    let contactName = this.primaryIncomingCall.contactName
    LogUtils.i(TAG, 'sendMessage slotId ' + slotId);
    try {
      sms.sendShortMessage({
        slotId: slotId,
        destinationHost: destinationHost,
        content: msg,
        sendCallback: (err: BusinessError, sendResult: sms.ISendShortMessageCallback) => {
          if (err) {
            LogUtils.e(TAG, `sendMessage fail: ${err?.message}`);
            return;
          }
          let message: Resource;
          if (sendResult.result === SEND_SMS_SUCCESS) {
            message = contactName ? $r('app.string.SMS_Sent', contactName) :
            $r('app.string.SMS_Sent', destinationHost);
          } else {
            message = $r('app.string.message_Failed');
          }
          Utils.getInstance().showToast(message, 2000);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `sendShortMessage failed, err: ${JSON.stringify(err)}`);
    }
    CallServiceProxy.getInstance().rejectCall(this.primaryIncomingCall.callId, false, msg);
    if (this.primaryIncomingCall.callType === CallStateConst.TYPE_SATELLITE) {
      ReportUtil.getInstance().reportSatelliteCallReject(2);
    }
    ReportUtil.getInstance().reportIncomingMMSReject(isVideoCall(this.primaryIncomingCall.videoState) ? 1 : 0);
  }

  /**
   * Handling interface call hangup and rejection
   */
  public onReject() {
    LogUtils.i(TAG, 'onReject call:' + JSON.stringify(this.primaryIncomingCall.callId));
    if (this.callList.length <= 1) {
      AppStorage.setOrCreate('hasBeenToFrontOrBackend', AppStorage.get('onPageShow'));
      AppStorage.setOrCreate('hangUp', true);
      removeWindowListener();
      terminateSelf(Constants.CALL_ABILITY_CONTEXT);
      terminateSelf(Constants.HICAR_CALL_ABILITY_CONTEXT);
      CallFaultEventUtil.getInstance().disconnectedFinishCallEventFault();
    }
    const callId = this.primaryIncomingCall.callId;
    CallServiceProxy.getInstance()?.rejectCall(callId);
    let playVideoModel: VideoController = VideoController.getInstance();
    playVideoModel?.releasePlay();
    LogUtils.i(TAG, 'onReject CallServiceProxy.getInstance().rejectCall :');
    if (this.callList.length >= 2) {
      ReportUtil.getInstance().reportMultiCallAction(0);
    }
    if (this.primaryIncomingCall.callType === CallStateConst.TYPE_SATELLITE) {
      ReportUtil.getInstance().reportSatelliteCallReject(1);
    }
    ReportUtil.getInstance().reportIncomingClickReject(isVideoCall(this.primaryIncomingCall.videoState) ? 1 : 0,
      this.primaryIncomingCall.contactName.length > 0 ? true : false);
    BannerNotificationManager.getInstance().cancelNotification(callId);
  }

  /**
   * Answer the phone interface
   */
  public async onAnswer(videoCall: boolean) {
    LogUtils.i(TAG, 'onAnswer  isVideoCall :' + videoCall);
    let isSuperPrivacy: boolean | undefined = AppStorage.get('isSuperPrivacy');
    let isFold: boolean = DisplayUtil.getScreenFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
    if (!isSuperPrivacy) {
      this.answerWhenIsNotSuperPrivacy(videoCall);
    } else if (isFold || !videoCall) {
      AppStorage.setOrCreate('isSupportAnswerStatus', true);
    }
    CallServiceProxy.getInstance()?.acceptCall(this.primaryIncomingCall.callId, videoCall);
    ReportUtil.getInstance().reportIncomingAudioAccept(videoCall ? 1 : 0, this.primaryIncomingCall);
    if (this.callList.length >= 2) {
      ReportUtil.getInstance().reportMultiCallAction(1);
      ReportUtil.getInstance().reportIsDualCardAnotherAnswer(this.primaryIncomingCall.accountId);
    }
  }

  answerWhenIsNotSuperPrivacy(videoCall: boolean): void {
    if (!isVideoCall(this.primaryIncomingCall.videoState) && this.callList.length === 1) {
      setTimeout(() => {
        this.primaryIncomingCall.callState = CallStateConst.callStateObj.CALL_STATUS_ANSWER;
        let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
        if (callData !== undefined) {
          callData.callState = CallStateConst.callStateObj.CALL_STATUS_ANSWER;
        }
      }, 20);
      AppStorage.setOrCreate('onAnswer', true);
    } else if (this.callList.length === 2 && !videoCall) {
      CallServiceProxy.getInstance()?.hangUpActiveCallWhenVoiceToVideoCall(this.callList);
    }
    if ((this.primaryIncomingCall.crsType === CRS_TONE_NUM && !videoCall) ||
      (isVideoCall(this.primaryIncomingCall.videoState) && !videoCall)) {
      VideoCallManager.getInstance().controlCamera(this.primaryIncomingCall.callId, '');
      setDisplayWindowApi(this.primaryIncomingCall.callId, '');
    }
    AppStorage.setOrCreate('isOnAnswerForMulti', this.callList.length > 1);
    LogUtils.e(TAG, `onAnswer primaryIncomingCall ${JSON.stringify(this.primaryIncomingCall.callId)} `);
  }
}
