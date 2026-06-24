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

import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import LogUtils from '../LogUtils';
import BottomViewModel from '../../../viewmodel/BottomViewModel';
import bundleManager from '@ohos.bundle.bundleManager';
import CallStateConst from '../../constant/CallStateConst';
import CallTimeListStruct from '../../struct/CallTimeListStruct';
import CallDataManager from '../../../model/CallDataManager';
import DefaultCallData from '../../struct/TypeUtils';
import { DisplayUtil } from '../DisplayUtil';
import hiSysEvent from '@ohos.hiSysEvent';
import { isScreenLocked } from '../DeviceTypeUtils';
import { VibrationUtils } from '../VibrationUtils';
import CallUtils from '../CallUtils';
import { StringUtil } from '../StringUtil';
import audio from '@ohos.multimedia.audio';
import {
  getActiveCallId,
  getCallById,
  getFirstCallByState,
  getForegroundCall,
  getOtherAccountId,
  hasAliveCallForSlotId,
  isVideoCall
} from '../CallListHelper';
import { privacyManager } from '@kit.AbilityKit';
import * as Constants from '../Constants';
import { ReportDeviceType, ReportService } from './ReportService';
import { getVersionName } from '../DeviceTypeUtils';
import ScreenAdapterUtils from '../ScreenAdapterUtils';
import { VisionGlassConstants } from '../../constant/VisionGlassConstants';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { i18n } from '@kit.LocalizationKit';

const TAG = 'ReportUtil';
/** ue report call field domain */
const DOMAIN = 'PHONE_UE';
/** dft report call field domain */
const DOMAIN_DFT = 'PHONE';
const packageName = 'com.ohos.callui';
/** Outgoing calls, outgoing call type will be added later */
const CALL_EVENT_DIAL = 'CALL_EVENT_DIAL';
/** call disconnected,current audio status,volume,screen status,call duration,
 * call hangup type will be improved in the future. */
const CALL_EVENT_HANGUP_INFO = 'CALL_EVENT_HANGUP_INFO';
const MIC_PERMISSION = 'ohos.permission.MICROPHONE';
const SUMMARY_FAIL = 'INTELLIGENT_SUMMARY_ENABLE_FAIL';
const SUMMARY_CONFLICT = 'INTELLIGENT_SUMMARY_CONFLICT';
const ERR_EXCEPTIONTERMINATION = 0;
const ERR_AUDIOSTREAMFAILED = 1;
const ENABLE_NEW_FEATURE = 0;
const DISABLE_NEW_FEATURE = 1;

export const UE_CALLBACK_REMIND_CANCEL = 0;
export const HANGUP_WAKE_UP_SCREEN = 'hangupWakeUpScreen';

export class ReportUtil extends ReportService {
  private static sReportUtil: ReportUtil;
  private incomingCallId: number = -1;
  private activeCallId: number = -1;
  private incomingDialTimeData = new Map<string, number>();
  private isPressPowerToScreenOff: number = 0;
  private acceptRateCallId: number = -1;
  private hangUpCallId: number = -1;
  private callActiveTime: number = 0;
  private callAlertTime: number = 0;
  private callDialTime: number = 0;
  private tokenId = 0;
  private isStartPrivacyPermission: boolean = false;
  private currentCallIsConnect = new Map<string, boolean>();
  private eventSet = new Set<string>([
    'CALL_EVENT_ANSWER_EXTERNAL',
    'CALL_EVENT_AUDIO_SWITCH_EXTERNAL',
    'CALL_EVENT_REJECT_EXTERNAL',
    'CALL_EVENT_HANGUP_EXTERNAL']);

  public callAnswerTime: number = 0;
  public volumeValue: number = 0;

  public static getInstance(): ReportUtil {
    if (!ReportUtil.sReportUtil) {
      ReportUtil.sReportUtil = new ReportUtil();
    }
    return ReportUtil.sReportUtil;
  }

  domain(): string {
    return DOMAIN;
  }

  eventType(): hiSysEvent.EventType {
    return hiSysEvent.EventType.BEHAVIOR;
  }

  static reportDrawnCompleted(asyncTaskCount: number, context: Context) {
    if (asyncTaskCount !== 0) {
      return;
    }
    (context as common.UIAbilityContext).reportDrawnCompleted((err: BusinessError) => {
      if (err.code) {
        LogUtils.e(TAG, 'reportDrawnCompleted err' + JSON.stringify(err));
        return;
      }
      LogUtils.i(TAG, 'reportDrawnCompleted');
    });
  }

  public reportIncomingDisplay(displayMode: number, status: string) {

    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': 0,
      'DISPLAY_MODE': displayMode,
      'STATUS': status == Constants.SUCCESS ? 1 : 0
    }

    this.report('INCOMING_DISPLAY', params);
  }

  public reportOutgoingDisplay(displayMode: number, status: string) {

    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': 0,
      'DISPLAY_MODE': displayMode,
      'STATUS': status == Constants.SUCCESS ? 1 : 0
    }

    this.report('OUTGOING_DISPLAY', params);
  }

  public reportHangupCallSuccess(displayMode: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': 0,
      'DISPLAY_MODE': displayMode,
    }

    this.report('HANGUP_CALL_SUCCESS', params);
  }

  public reportHangupCallCount(displayMode: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': 0,
      'DISPLAY_MODE': displayMode
    }

    this.report('HANGUP_CALL', params);
  }

  public report(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>,
    deviceType?: ReportDeviceType, eventType: hiSysEvent.EventType = hiSysEvent.EventType.BEHAVIOR) {
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'DEVICE_TYPE': deviceType === undefined ? this.currentDeviceType : deviceType,
          'CALL_TYPE': 0,
        };
        customizedParams = params;
      }
      // 增加屏幕类型
      this.addScreenFormParam(eventName, customizedParams);
      let type: hiSysEvent.EventType = eventType;
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: DOMAIN,
        name: eventName,
        eventType: type,
        params: customizedParams
      };
      this.write(eventInfo);
    } catch (err) {
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  private getEventType(eventName: string): hiSysEvent.EventType {
    if (eventName === 'CALL_EVENT_INCOMING_RATE' || eventName === 'INTELLIGENT_LOW_STORAGE_REPORT') {
      return hiSysEvent.EventType.STATISTIC;
    }
    return hiSysEvent.EventType.BEHAVIOR;
  }

  addScreenFormParam(eventName: string, customizedParams: Record<string, string | number | boolean | undefined>) {
    if (this.eventSet.has(eventName)) {
      LogUtils.i(TAG, `eventName:${eventName} no need addScreenFormParam`);
      return;
    }
    // 统一新增屏幕形态参数SCREEN_FORM
    customizedParams['SCREEN_FORM'] = ScreenAdapterUtils.getInstance().getScreenForm();
  }

  /**
   * report call In Active Info
   *
   * @param {callData}, DefaultCallData
   * @param {callDirection}, 0 - incoming ，1 - outgoing
   */
  private reportCallInActiveInfo(callData: DefaultCallData, callDirection: number) {
    if (callData.callId === this.activeCallId) {
      LogUtils.i(TAG, 'reportCallInActiveInfo repeat report return');
      return;
    } else {
      let audioRute: number = BottomViewModel.getInstance().getCurrentAudioDeviceType();
      VibrationUtils.getInstance().getCallVolume((value: number) => {
        this.volumeValue = value;
        let data: number = new Date().valueOf();
        let incomingCallTime: number | undefined = this.incomingDialTimeData.get(callData.callId.toString());
        let isConnect: boolean | undefined = this.currentCallIsConnect.get(callData.callId.toString());
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'DEVICE_TYPE': this.currentDeviceType,
          'CALL_TYPE': callData.callType,
          'AUDIO_ROUT': audioRute,
          'CALL_VOLUME': value,
          'CALL_WAIT_TIME': incomingCallTime !== undefined ? data - incomingCallTime : 0,
          'SCREEN_STATE': DisplayUtil.isFoldable() ? DisplayUtil.getScreenFoldStatus() : 0,
          'CALL_DIRECTION': callDirection,
          'ISCONTACT': isConnect !== undefined ? isConnect : false,
          'MEDIA_TYPE': isVideoCall(callData.videoState) ? 1 : 0,
          'IS_ENABLE_NEW_FEATURE': i18n.System.getSystemRegion() === 'CN' ? 1 : 0
        };
        this.activeCallId = callData.callId;
        let isOnVisionGlass = AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS);
        if (isOnVisionGlass) {
          this.report('CALL_EVENT_GLASS_ACTIVE_INFO', params);
        } else {
          this.report('CALL_EVENT_ACTIVE_INFO', params);
        }
      });
    }
  }

  private reportCallDisconnectedInfo(callType: number, audioRute: number | undefined, callDuration: number,
    disconnectCause: number, callId: number, mediaType: number, isContact: boolean) {
    if (this.volumeValue !== 0) {
      VibrationUtils.getInstance().getCallVolume((value: number) => {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'DEVICE_TYPE': this.currentDeviceType,
          'CALL_TYPE': callType,
          'AUDIO_ROUT': audioRute,
          'VOLUME_LEVEL': value,
          'CALL_ACTIVE_TIME': callDuration,
          'SCREEN_STATE': DisplayUtil.isFoldable() ? DisplayUtil.getScreenFoldStatus() : 0,
          'HANGUP_TYPE': disconnectCause,
          'ISCONTACT' : isContact,
          'MEDIA_TYPE' : mediaType,
          'HANGUP_WAKE_UP_SCREEN': AppStorage.get(HANGUP_WAKE_UP_SCREEN)
        };
        this.volumeValue = 0;
        let isOnVisionGlass = AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS);
        if (isOnVisionGlass) {
          this.report('CALL_EVENT_GLASS_HANGUP_INFO', params);
        } else {
          this.report(CALL_EVENT_HANGUP_INFO, params);
        }
      });
    } else {
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'DEVICE_TYPE': this.currentDeviceType,
        'CALL_TYPE': callType,
        'AUDIO_ROUT': audioRute,
        'VOLUME_LEVEL': 0,
        'CALL_ACTIVE_TIME': callDuration,
        'SCREEN_STATE': DisplayUtil.isFoldable() ? DisplayUtil.getScreenFoldStatus() : 0,
        'HANGUP_TYPE': disconnectCause,
        'ISCONTACT' : isContact,
        'MEDIA_TYPE' : mediaType,
        'HANGUP_WAKE_UP_SCREEN': AppStorage.get(HANGUP_WAKE_UP_SCREEN)
      };
      this.report(CALL_EVENT_HANGUP_INFO, params);
    }
    this.incomingDialTimeData.delete(callId.toString());
    this.currentCallIsConnect.delete(callId.toString());
  }

  /**
   * report incoming Call Info
   *
   * @param callType, 0:operator all  1：voip
   * @param numberLength, incoming call number length
   * @param remindType, 0：incoming audio remind  1：incoming video remind
   * @param isContact, incoming is contacts
   * @param slotId, sim index
   */
  public reportHasIncomingCall(callType: number, numberLength: number, isContact: boolean, callId: number,
    slotId: number, mediaType: number) {
    if (this.incomingCallId === callId) {
      LogUtils.i(TAG, 'reportHasIncomingCall repeat report, callId:' + callId);
      return;
    }
    this.incomingDialTimeData.set(callId.toString(), new Date().valueOf());
    this.currentCallIsConnect.set(callId.toString(), isContact);
    this.incomingCallId = callId;
    CallUtils.getCallISRoaming(slotId, (isRoaming: boolean) => {
      this.reportIncomingCallEvent(callType, numberLength, isContact, isRoaming, slotId, mediaType);
    });
  }

  public reportIncomingCallEvent(callType: number, numberLength: number, isContact: boolean, isRoaming: boolean,
    slotId: number, mediaType: number) {
    // 0-not Roaming, 1-domestic Roaming, 2-international Roaming
    let roamingValue: number = 0;
    if (isRoaming) {
      let operator: string = CallUtils.getNetworkOperatorName(slotId);
      LogUtils.i(TAG, 'getNetworkOperatorName: ' + operator);
      if (!StringUtil.isEmpty(operator)) {
        roamingValue = operator.substring(0, 3) === '460' ? 1 : 2;
      } else {
        roamingValue = 0
      }
    }
    VibrationUtils.getInstance().getRingerMode((value: audio.AudioRingMode) => {
      let ringMode: number = value === audio.AudioRingMode.RINGER_MODE_SILENT ? 0 : 1;
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'DEVICE_TYPE': this.currentDeviceType,
        'CALL_TYPE': callType,
        'NUMBER_LENGTH': numberLength,
        'ISCONTACT': isContact,
        'ROAMING_TYPE': roamingValue,
        'ISLOCK': isScreenLocked(),
        'RING_MODE': ringMode,
        'MEDIA_TYPE': mediaType
      };
      this.report('CALL_EVENT_INCOMING', params);
    })
  }

  public reportIncomingRemindButton(type: number, callType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType,
      'REMIND_TYPE': type
    };
    this.report('CALL_EVENT_CLICK_REMIND', params);
  }

  /**
   * Incoming call, click the power button to screen off
   *
   * @param {number}, 0:operator all  1：voip
   */
  public reportClickPowerToScreenOff(callType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType,
    };
    this.report('CALL_EVENT_CLICKPOWER_MUTE', params);
    this.isPressPowerToScreenOff = 1;
  }

  /**
   * incoming call, click answer button
   */
  public reportIncomingAudioAccept(mediaType: number, callData: DefaultCallData) {
    if (callData.callType === CallStateConst.TYPE_SATELLITE) {
      this.reportSatelliteCallClickAnswer();
      return;
    }
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': 0,
      'ISCONTACT': !!callData.contactName,
      'MEDIA_TYPE' : mediaType
    };
    this.report('CALL_EVENT_VOICE_ANSWER', params);
  }

  /**
   * external incoming call, click answer button
   */
  public reportExternalIncomingCallAccept() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_EVENT_ANSWER_EXTERNAL', params);
  }

  /**
   * Trigger call risk detection. In the displayed dialog box, click the corresponding button.
   */
  public reportAntiFraudEvent(eventType : number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'TYPE': eventType
    };
    this.report('ANTI_FRAUD_EVENT', params);
  }

  /**
   * Outgoing calls, outgoing call type will be added later
   */
  public reportDialOutgoing(callData: DefaultCallData) {
    if (this.versionName !== '1.0') {
      this.incomingDialTimeData.set(callData.callId.toString(), new Date().valueOf());
      this.reportOutgoingCall(callData);
    } else {
      getVersionName((verison: string) => {
        this.incomingDialTimeData.set(callData.callId.toString(), new Date().valueOf());
        this.versionName = verison;
        this.reportOutgoingCall(callData);
      });
    }
  }

  private reportOutgoingCall(callData: DefaultCallData) {
    if (callData.callType === CallStateConst.TYPE_SATELLITE) {
      this.reportSatelliteCallDial();
      return;
    }
    this.currentCallIsConnect.set(callData.callId.toString(), !!callData.contactName);
    CallUtils.getCallISRoaming(callData.accountId, (isRoaming: boolean) => {
      // 0-not Roaming, 1-domestic Roaming, 2-international Roaming
      let roamingValue: number = 0;
      if (isRoaming) {
        let operator: string = CallUtils.getNetworkOperatorName(callData.accountId);
        LogUtils.i(TAG, 'getNetworkOperatorName: ' + operator);
        if (!StringUtil.isEmpty(operator)) {
          roamingValue = operator.substring(0, 3) === '460' ? 1 : 2;
        } else {
          roamingValue = 0
        }
      }
      VibrationUtils.getInstance().getRingerMode((value: audio.AudioRingMode) => {
        let ringMode: number = value === audio.AudioRingMode.RINGER_MODE_SILENT ? 0 : 1;
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'DEVICE_TYPE': this.currentDeviceType,
          'CALL_TYPE': callData.callType == CallStateConst.TYPE_VOIP ? 1 : 0,
          'NUMBER_LENGTH': callData.accountNumber?.length ?? 0,
          'ISCONTACT': !!callData.contactName,
          'ROAMING_TYPE': roamingValue,
          'RING_MODE': ringMode,
          'MEDIA_TYPE': isVideoCall(callData.videoState) ? 1 : 0
        };
        this.report(CALL_EVENT_DIAL, params);
      })
    });
  }

  /**
   * user switch audio devices on the call interface
   *
   * @param {number}, audio channel
   */
  public reportSwitchAudioRuteInCall(audioRute: number, deviceType?: ReportDeviceType) {
    let parms: Record<string, string | number | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': deviceType === undefined ? this.currentDeviceType : deviceType,
      'CALL_TYPE': 0,
      'AUDIO_CHANNEL': audioRute
    };
    let isOnVisionGlass = AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS);
    if (isOnVisionGlass) {
      this.report('CALL_EVENT_GLASS_AUDIO_SWITCH', parms);
    } else {
      this.report('CALL_EVENT_AUDIO_SWITCH', parms);
    }
  }

  /**
   * user switch audio devices on the external call interface
   *
   * @param {number}, audio channel
   */
  public reportSwitchAudioRuteExternalCall(audioRute: number) {
    let parms: Record<string, string | number | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'AUDIO_CHANNEL': audioRute
    };
    this.report('CALL_EVENT_AUDIO_SWITCH_EXTERNAL', parms);
  }

  public reportVisionGlassClickBtn(btnName: string, isSelected?: boolean, deviceType?: ReportDeviceType) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': deviceType === undefined ? this.currentDeviceType : deviceType,
      'CALL_TYPE': 0
    };
    switch (btnName) {
      case 'record': {
        params['ISRECORD'] = isSelected;
        this.report('CALL_EVENT_GLASS_CLICK_RECORD', params);
      }
        break;
      case 'wait': {
        params['ISHOLD'] = isSelected;
        this.report('CALL_EVENT_GLASS_CLICK_WAIT', params);
      }
        break;
      case 'add':
        this.report('CALL_EVENT_GLASS_ADDCALL', undefined);
        break;
      case 'memorandum':
        this.report('CALL_EVENT_GLASS_CLICKMEMORANDUM', undefined);
        break;
      case 'mute': {
        params['ISMUTE'] = isSelected;
        this.report('CALL_EVENT_GLASS_CLICK_MUTE', params);
      }
        break;
      case 'contact':
        this.report('CALL_EVENT_GLASS_CLICK_CONTACT', undefined);
        break;
      case 'keyboard': {
        params['ISSHOW'] = isSelected ? 1 : 0;
        this.report('CALL_EVENT_GLASS_CLICKDTMF_BTN', params);
      }
        break;
      default:
        break;
    }
  }

  /**
   * user click button event on the call interface
   *
   * @param {string}, button name
   * @param {boolean}, button selected state
   */
  public reportCallInterfaceClickBtn(btnName: string, isSelected?: boolean, deviceType?: ReportDeviceType) {
    let isOnVisionGlass = AppStorage.get<boolean>(VisionGlassConstants.CONNECT_VISION_GLASS);
    if (isOnVisionGlass) {
      this.reportVisionGlassClickBtn(btnName, isSelected, deviceType)
      return;
    }
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': deviceType === undefined ? this.currentDeviceType : deviceType,
      'CALL_TYPE': 0
    };
    switch (btnName) {
      case 'record': {
        params['ISRECORD'] = isSelected;
        this.report('CALL_EVENT_CLICK_RECORD', params);
      }
        break;
      case 'wait': {
        params['ISHOLD'] = isSelected;
        this.report('CALL_EVENT_CLICK_WAIT', params);
      }
        break;
      case 'add':
        this.report('CALL_EVENT_ADDCALL', undefined);
        break;
      case 'memorandum':
        this.report('CALL_EVENT_CLICKMEMORANDUM', undefined);
        break;
      case 'mute': {
        params['ISMUTE'] = isSelected;
        this.report('CALL_EVENT_CLICK_MUTE', params);
      }
        break;
      case 'contact':
        this.report('CALL_EVENT_CLICK_CONTACT', undefined);
        break;
      case 'keyboard': {
        params['ISSHOW'] = isSelected ? 1 : 0;
        this.report('CALL_EVENT_CLICKDTMF_BTN', params);
      }
        break;
      case 'video': {
        params['ISVOICETOVIDEO'] = isSelected ? 1 : 0;
        this.report('CALL_EVENT_CLICK_VIDEO', params);
        if (isSelected) {
          this.reportVoiceToVideo();
        }
      }
        break;
      case 'summarize': {
        params['ISABSTRACT'] = isSelected;
        this.report('ABSTRACT_BTN', params);
      }
        break;
      default:
        break;
    }
  }

  /**
   * report call in Background
   *
   * @param callType, 0:Operator call  1：voip
   */
  public reportCallInBackground(callType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType,
    };
    this.report('CALL_EVENT_INBACKGROUND', params);
  }

  /**
   * report call In Active Info
   *
   * @param {callData}, DefaultCallData
   * @param {number}, call old state
   * @param {number}, call new state
   */
  public reportCallInActive(callData: DefaultCallData, oldState: number, newState: number) {
    if (newState === CallStateConst.CALL_STATUS_ACTIVE) {
      if (oldState === CallStateConst.CALL_STATUS_INCOMING || oldState === CallStateConst.CALL_STATUS_ANSWER) {
        this.reportCallInActiveInfo(callData, 0);
        this.reportIncomingCallVibrateAndAnswerRate(callData, 1, CallStateConst.CALL_STATUS_ACTIVE);
      } else if (oldState === CallStateConst.CALL_STATUS_DIALING || oldState === CallStateConst.CALL_STATUS_ALERTING) {
        this.reportCallInActiveInfo(callData, 1);
      }
      let anotherSlotId: number = getOtherAccountId(callData.accountId);
      if (hasAliveCallForSlotId(anotherSlotId, CallDataManager.getInstance().callList)) {
        this.reportDualCardOneInCallAndAnotherActive();
      }
      if (CallDataManager.getInstance().callList.length >= 2) {
        this.reportMultipleCallsConnected();
      }
    }
    if ((newState === CallStateConst.CALL_STATUS_DISCONNECTED ||
      newState === CallStateConst.CALL_STATUS_DISCONNECTING) && oldState === CallStateConst.CALL_STATUS_ANSWER) {
      let anotherSlotId: number = getOtherAccountId(callData.accountId);
      if (hasAliveCallForSlotId(anotherSlotId, CallDataManager.getInstance().callList)) {
        CallUtils.reportHangupCount();
        this.reportDualcardAnswerFailed();
      }
    }
  }

  /**
   * report Disconnected Call Info
   *
   * @param { DefaultCallData } callData
   */
  public reportDisconnectInfo(callData: DefaultCallData) {
    if (callData.callId === this.hangUpCallId) {
      return;
    }
    let callTime: CallTimeListStruct | undefined =
      CallDataManager.getInstance().getCallTimeObjByCallId(callData.callId);
    let callDuration: number = callTime !== undefined ? callTime.endTimestamp - callTime.startTimestamp : 0;
    let callType: number = callData.callType === CallStateConst.TYPE_VOIP ? 1 : 0;
    let disconnectCause: number = this.getCallDisconnectCause(callDuration);
    let currentDeviceType: number = BottomViewModel.getInstance().getCurrentAudioDeviceType();
    CallUtils.reportHangupCount();
    if (callType === CallStateConst.TYPE_SATELLITE) {
      this.reportSatelliteCallDisconnected(disconnectCause);
    } else {
      this.reportCallDisconnectedInfo(callType, currentDeviceType, callDuration, disconnectCause, callData.callId,
        isVideoCall(callData.videoState) ? 1 : 0, !!callData.contactName);
    }
    this.hangUpCallId = callData.callId;
    this.isPressPowerToScreenOff = 0;
    if (callDuration === 0) {
      let incomingEndCause: number = -1;
      let isLocalUp: boolean | undefined = AppStorage.get('hangUp');
      if (isLocalUp !== undefined) {
        // 0-local reject, 2-remote cancel
        incomingEndCause = isLocalUp ? 0 : 2;
      }
      this.reportIncomingCallVibrateAndAnswerRate(callData, incomingEndCause, CallStateConst.CALL_STATUS_DISCONNECTED);
    }
  }

  public reportHyacinthDisconnect(callData: DefaultCallData){
    let callTime: CallTimeListStruct | undefined =
      CallDataManager.getInstance().getCallTimeObjByCallId(callData.callId);
    let callDuration: number = callTime !== undefined ? callTime.endTimestamp - callTime.startTimestamp : 0;
    let dailDuration: number = this.callAlertTime - this.callDialTime;
    this.callAlertTime = 0;
    this.callDialTime = 0;
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'DAIL_TIME': dailDuration,
      'CALL_TIME': callDuration
    };
    this.report('HYACINTH_CALL', param);
  }

  /**
   * get Call DisconnectCause
   *
   * @param { number } call Duration
   * @return { number } 0: local hangup, 1: remote hangUp 2: incoming reject, 3：remote cancel
   */
  public getCallDisconnectCause(callDuration: number | undefined): number {
    let disconnectCause: number = -1;
    let isLocalUp: boolean | undefined = AppStorage.get('hangUp');
    if (callDuration !== undefined && callDuration > 0) {
      if (isLocalUp !== undefined) {
        disconnectCause = isLocalUp ? 0 : 1;
      }
    } else {
      disconnectCause = isLocalUp ? 2 : 3;
    }
    return disconnectCause;
  }

  public reportNotifyBarAnswered(callType: number) {
    if (callType === CallStateConst.TYPE_SATELLITE) {
      this.reportSatelliteCallClickAnswer();
      return;
    }
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType
    };
    this.report('CALL_EVENT_NOTIFY_ANSWER', params);
  }

  public reportNotifyBarReject(callType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType
    };
    this.report('CALL_EVENT_NOTIFY_REJECT', params);
  }

  public reportNotifyBarHangUp(callType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType
    };
    this.report('CALL_EVENT_NOTIFY_HANGUP', params);
  }

  public reportNotifyBarMuteOrNot(isMute: number, callType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType,
      'ISMUTE': isMute
    };
    this.report('CALL_EVENT_NOTIFY_MUTE', params);
  }

  public reportNotifyBarAnswerAudioRute(audioDeviceType: number, callType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType,
      'RUTE': audioDeviceType
    };
    this.report('CALL_EVENT_NOTIFY_SPEAKER', params);
  }

  public reportMapNavigationBarAnswerAudioRute(audioDeviceType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': 0,
      'RUTE': audioDeviceType
    };
    this.report('CALL_EVENT_MAP_NAVIGATION_ANSWER', params);
  }

  public reportRejectSmsChange() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
    };
    this.report('CALL_SET_REJECTSMS_CHOOSE', params);
  }

  public isCallAnswerResponseTimeout(callType: number) {
    this.callActiveTime = new Date().valueOf();
    if (callType !== CallStateConst.TYPE_SATELLITE) {
      if (this.callActiveTime - this.callAnswerTime > 1200) {
        this.reportCallAcceptTimeout(callType);
      }
    } else {
      this.reportSatelliteCallAcceptTime(this.callActiveTime - this.callAnswerTime, 1);
    }
    this.callActiveTime = this.callAnswerTime = 0;
  }

  public recordAlertTime(){
    if(this.callAlertTime == 0){
      this.callAlertTime = new Date().valueOf();
    }
  }

  public recordDialTime(){
    this.callDialTime = new Date().valueOf();
  }

  public reportCallAcceptTimeout(callType: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': callType,
    };
    let eventInfo: hiSysEvent.SysEventInfo = {
      domain: DOMAIN,
      name: 'CALL_EVENT_ACCEPT_TIMEOUT',
      eventType: hiSysEvent.EventType.FAULT,
      params: param
    };
    this.write(eventInfo);
  }

  /**
   * report incoming call completion rate
   *
   * @param { DefaultCallData } callData
   * @param { disconnectCause } disconnect cause, -1-unknown, 0-local reject, 1-in active, 2-remote cancel
   * @param { newState } call state
   */
  private reportIncomingCallVibrateAndAnswerRate(callData: DefaultCallData, disconnectCause: number, newState: number) {
    if (callData.callId === this.acceptRateCallId) {
      return;
    } else {
      let audioRute: number = BottomViewModel.getInstance().getCurrentAudioDeviceType();
      VibrationUtils.getInstance().getCallVolume((value: number) => {
        let incomingCallTime: number = 0;
        if (newState === CallStateConst.CALL_STATUS_ACTIVE) {
          let data: number = new Date().valueOf();
          let incomingTime: number | undefined = this.incomingDialTimeData.get(callData.callId.toString());
          incomingCallTime = incomingTime !== undefined ? data - incomingTime : 0;
          this.acceptRateCallId = callData.callId;
        }
        VibrationUtils.getInstance().getRingerMode((mode: audio.AudioRingMode) => {
          let ringMode: number = mode === audio.AudioRingMode.RINGER_MODE_SILENT ? 0 : 1;
          let params: Record<string, string | number | boolean | undefined> = {
            'PNAMEID': packageName,
            'PVERSIONID': this.versionName,
            'DEVICE_TYPE': this.currentDeviceType,
            'CALL_TYPE': callData.callType === CallStateConst.TYPE_VOIP ? 1 : 0,
            'RINGTONE_VOLUME': value,
            'VIBRATOR_STATE': ringMode,
            'WAITTING_CALLTIME': incomingCallTime,
            'AUDIO_ROUT': audioRute,
            'PRESSPOWER_MUTE': this.isPressPowerToScreenOff,
            'DISCONNECT_CAUSE': disconnectCause
          };
          this.report('CALL_EVENT_INCOMING_RATE', params, this.currentDeviceType, hiSysEvent.EventType.STATISTIC);
        })
      });
    }
  }

  public reportDualCardIncomingCall(secondCallId: number) {
    if (this.incomingCallId === secondCallId) {
      return;
    } else {
      this.report('DUALCARD_TWO_INCOMING');
      this.incomingCallId = secondCallId;
    }
  }

  public reportMultiCallClickExchange(callList: number) {
    this.report('MULTI_CALL_CLICK_EXCHANGE');
    if (callList === 2) {
      this.reportIsDualCardClickExchangeButton();
    }
  }

  public reportMultiCallClickMerge() {
    this.report('MULTI_CALL_CLICK_MERGE');
  }

  public reportMultiCallClickSeparation() {
    this.report('MULTI_CALL_SEPARATION');
  }

  public reportMultiCallEnterParticipantList() {
    this.report('MULTI_CALL_PARTICIPANT_LIST');
  }

  /**
   * report incoming call completion rate
   *
   * @param { number } call action, 0-reject，1-answer，2-hangup
   */
  public reportMultiCallAction(action: number, deviceType?: ReportDeviceType) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': deviceType === undefined ? this.currentDeviceType : deviceType,
      'CALL_TYPE': 0,
      'ACTION': action
    };
    CallUtils.reportHangupCount();
    this.report('MULTI_CALL_ACTION', param);
  }

  public reportMultiCallHangUpOne(deviceType?: ReportDeviceType) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': deviceType === undefined ? this.currentDeviceType : deviceType,
      'CALL_TYPE': 0
    };
    this.report('MULTI_CALL_HANGUP_ONE', param);
  }

  public reportDualCardAnotherIncoming(secondryCallId: number) {
    if (this.incomingCallId === secondryCallId) {
      LogUtils.i(TAG, 'reportDualCardAnotherIncoming repeat report, callId:' + secondryCallId);
      return;
    } else {
      this.report('DUALCARD_ONE_INCOMING');
      this.incomingCallId = secondryCallId;
    }
  }

  public reportDualCallPoint(callData: DefaultCallData) {
    if (callData.callState === CallStateConst.CALL_STATUS_DIALING) {
      let anotherSlotId: number = getOtherAccountId(callData.accountId);
      if (hasAliveCallForSlotId(anotherSlotId, CallDataManager.getInstance().callList)) {
        this.reportDualCardOneInCallAndAnotherDial();
      }
    } else if (callData.callState === CallStateConst.CALL_STATUS_INCOMING) {
      let anotherSlotId: number = getOtherAccountId(callData.accountId);
      if (hasAliveCallForSlotId(anotherSlotId, CallDataManager.getInstance().callList)) {
        this.reportDualCardAnotherIncoming(callData.callId);
      }
    }
  }

  public reportIsDualCardAnotherAnswer(accountId: number) {
    let anotherSlotId: number = getOtherAccountId(accountId);
    if (hasAliveCallForSlotId(anotherSlotId, CallDataManager.getInstance().callList)) {
      this.report('DUALCARD_ONE_ANSWER');
    }
  }

  public reportDualCardOneInCallAndAnotherDial() {
    this.report('DUALCARD_ONE_DIAL');
  }

  public reportIsDualCardOneInCallAndAnotherDialCancel(callNum: number, accountId: number, callState: number,
    deviceType?: ReportDeviceType) {
    if (callNum > 1) {
      let anotherSlotId: number = getOtherAccountId(accountId);
      if (hasAliveCallForSlotId(anotherSlotId, CallDataManager.getInstance().callList) && callState ===
      CallStateConst.CALL_STATUS_DIALING) {
        this.report('DUALCARD_ONE_DIAL_CANCEL', undefined, deviceType);
      }
    }
  }

  public reportDualCardOneInCallAndAnotherActive() {
    this.report('DUALCARD_ONE_ACTIVE');
  }

  public reportDualCardClickExchangeList(deviceType?: ReportDeviceType) {
    this.report('DUALCARD_LIST_EXCHANGE', undefined, deviceType);
  }

  public reportIsDualCardClickExchangeButton() {
    let callList: DefaultCallData[] = CallDataManager.getInstance().callList;
    let sim1HasAliveCall: boolean = hasAliveCallForSlotId(0, callList);
    let sim2HasAliveCall: boolean = hasAliveCallForSlotId(1, callList);
    if (sim1HasAliveCall && sim2HasAliveCall) {
      this.report('DUALCARD_BTN_EXCHANGE');
    }
  }

  public reportIsDualCardClickListReject(callNum: number, deviceType?: ReportDeviceType) {
    if (callNum === 2) {
      let callList: DefaultCallData[] = CallDataManager.getInstance().callList;
      let sim1HasAliveCall: boolean = hasAliveCallForSlotId(0, callList);
      let sim2HasAliveCall: boolean = hasAliveCallForSlotId(1, callList);
      if (sim1HasAliveCall && sim2HasAliveCall) {
        this.report('DUALCARD_LIST_REJECT', undefined, deviceType);
      }
    }
  }

  public reportIsDualCardClickListToAnswer(callNum: number, deviceType?: ReportDeviceType) {
    if (callNum === 2) {
      let callList: DefaultCallData[] = CallDataManager.getInstance().callList;
      let sim1HasAliveCall: boolean = hasAliveCallForSlotId(0, callList);
      let sim2HasAliveCall: boolean = hasAliveCallForSlotId(1, callList);
      if (sim1HasAliveCall && sim2HasAliveCall) {
        this.report('DUALCARD_LIST_ACCEPT', undefined, deviceType);
      }
    }
    this.report('DUALCARD_LIST_ACCEPT', undefined, deviceType);
  }

  public reportMultipleCallsConnected() {
    this.report('MULTI_CALL_CONNECTED');
  }

  public reportIncomingCallInSatelliteConnected() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_INCOMING', param);
  }

  /**
   * report reject Satellite Call
   *
   * @param { number } rejectType, 1-click reject button，2-sendMessage to reject
   */
  public reportSatelliteCallReject(rejectType: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'REJECT_TYPE': rejectType,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_REJECT', param);
  }

  /**
   * report satellite Call answer time
   *
   * @param { number } duration, time taken to successfully answer the call, unit millisecond
   * @param { number } result, 0 - fail, 1 - success
   */
  public reportSatelliteCallAcceptTime(duration: number, result: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ANSWER_RESULT': result,
      'DURATION': duration,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_ACCEPT_TIME', param);
  }

  /**
   * reportPrivacyIndicator
   */
  public reportPrivacyIndicator() {
    if (this.isStartPrivacyPermission) {
      return;
    }
    let call = getForegroundCall(CallDataManager.getInstance().callList);
    if (!call) {
      LogUtils.e(TAG, 'reportPrivacyIndicator callData undefined or voip type');
      return;
    }
    if ((call.callState === CallStateConst.CALL_STATUS_INCOMING ||
      call.callState === CallStateConst.CALL_STATUS_WAITING)) {
      return;
    }
    try {
      let options: privacyManager.AddPermissionUsedRecordOptions = {
        usedType: privacyManager.PermissionUsedType.NORMAL_TYPE
      };
      if (!this.tokenId) {
        let bundleName = Constants.CALL_BUNDLE_NAME;
        let appFlags = bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT;
        let applicationInfo = bundleManager.getApplicationInfoSync(bundleName, appFlags);
        this.tokenId = applicationInfo?.accessTokenId;
      }
      privacyManager.addPermissionUsedRecord(this.tokenId, MIC_PERMISSION,
        1, 0, options);
      privacyManager.startUsingPermission(this.tokenId, MIC_PERMISSION);
      this.isStartPrivacyPermission = true;
      LogUtils.i(TAG, 'reportPrivacyIndicator: getApplicationInfo success');
    } catch (err) {
      LogUtils.e(TAG, 'reportPrivacyIndicator err: ' + JSON.stringify(err));
    }
  }

  public stopPrivacyPermission() {
    try {
      if (!this.isStartPrivacyPermission) {
        return;
      }
      LogUtils.i(TAG, 'stopPrivacyPermission');
      privacyManager.stopUsingPermission(this.tokenId, MIC_PERMISSION);
      this.isStartPrivacyPermission = false;
    } catch (err) {
      LogUtils.e(TAG, 'stopPrivacyPermission err: ' + JSON.stringify(err));
    }
  }

  private reportUniversalFunc(eventName: string) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report(eventName, param);
  }

  public reportPlayVoiveColor() {
    this.reportUniversalFunc('CALL_EVENT_VOICE_COLOR');
  }

  public reportPlayVideoColor() {
    this.reportUniversalFunc('CALL_EVENT_VIDEO_COLOR');
  }

  public reportNotifyBannerClickVideoAnswer(callType: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CALL_TYPE': callType
    };
    this.report('CALL_EVENT_NOTIFY_VIDEOCALL', param);
  }

  public reportVideoIncomingPageClickHangUp() {
    this.reportUniversalFunc('CALL_EVENT_VIDEO_HANGUP');
  }

  /**
   * report click call back when incoming
   *
   * @param { number } type, 0-cancel, 1-half an hour, 2-one hour, 3-two hour
   */
  public reportCallBackRemindAction(type: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': type
    };
    this.report('CALL_EVENT_CALL_BACK', param);
  }

  public reportIncomingMMSReject(mediaType: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MEDIA_TYPE': mediaType
    };
    this.report('CALL_EVENT_CLICK_MMS_REJECT', param);
  }

  public reportIncomingSendCustomMessageReject(mediaType: number, action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MEDIA_TYPE': mediaType,
      'ACTION': action
    };
    this.report('CALL_EVENT_CUSTOM_MMS_REJECT', param);
  }

  private reportVoiceToVideo() {
    this.reportUniversalFunc('CALL_EVENT_VOICE_TO_VIDEO');
  }

  public reportVideoToVoice() {
    this.reportUniversalFunc('CALL_EVENT_VIDEO_TO_VOICE');
  }

  public reportVideoCallSwitchCamera() {
    this.reportUniversalFunc('CALL_EVENT_SWITCH_CAMERA');
  }

  public reportVideoCallClickMute(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': action
    };
    this.report('CALL_EVENT_VIDEO_MUTE', param);
  }

  public reportVideoCallClickLocalCamera(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': action
    };
    this.report('CALL_EVENT_VIDEO_CAMERA', param);
  }

  public reportVideoCallClickDTMF(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': action
    };
    this.report('CALL_EVENT_VIDEO_DTMF', param);
  }

  public reportVideoCallClickSpeaker(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': action
    };
    this.report('CALL_EVENT_VIDEO_SPEAKER', param);
  }

  public reportIncomingClickReject(mediaType: number, isContact: boolean) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MEDIA_TYPE': mediaType,
      'ISCONTACT' : isContact
    };
    this.report('CALL_EVENT_REJECT_ACTION', param);
  }

  public reportExternalIncomingClickReject() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_EVENT_REJECT_EXTERNAL', param);
  }

  public reportHangupExternal() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_EVENT_HANGUP_EXTERNAL', param);
  }

  public reportSatelliteCallDial() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_DIAL', param);
  }

  public reportSatelliteCallClickAnswer() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_ANSWER', param);
  }

  private reportSatelliteCallDisconnected(cause: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DISCONNECTCAUSE': cause,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_ANSWER', param);
  }

  public reportCallEndSaveUnknownNumber(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'TYPE' : action
    };
    this.report('CALL_EVENT_SAVE_UNKNOW_NUM', param);
  }

  private getPhoneNumberMarkValue(value : number): number {
    let type: number = -1;
    switch (value) {
      case $r('app.string.advertising_and_promotion').id:
        type = 0;
        break;
      case $r('app.string.Real_Estate_Agency').id:
        type = 1;
        break;
      case $r('app.string.harassing_call').id:
        type = 2;
        break;
      case $r('app.string.fraud_phone_call').id:
        type = 3;
        break;
      case $r('app.string.courier_and_food_delivery').id:
        type = 4;
        break;
      case $r('app.string.financial_management_insurance').id:
        type = 5;
        break;
      case $r('app.string.taxi').id:
        type = 6;
        break;
      case $r('app.string.custom').id:
        type = 7;
        break;
      default:
        break;
    }
    return type;
  }

  public reportCallEndMarkNumber(type: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'TYPE' : this.getPhoneNumberMarkValue(type)
    };
    this.report('CALL_EVENT_END_MARK_NUM', param);
  }

  public reportCallEndClickAddBlackListDialogAction(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION' : action
    };
    this.report('CALL_EVENT_END_ADD_BLACK', param);
  }

  public reportEndCallClickCloseBtn() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_EVENT_END_CLICK_CLOSE', param);
  }

  public reportUseVoiceBroadCast() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_INCOMING_USE_VOICEBROADCAST', param);
  }

  public reportDualcardAnswerFailed() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('DUALCARD_ANSWER_FAILED', param);
  }

  public reportDualcardHoldFailed() {
    let callList: DefaultCallData[] = CallDataManager.getInstance().callList;
    let activeCallId = getActiveCallId(callList);
    if (activeCallId === -1) {
      return;
    }
    let activeCall = getCallById(callList, activeCallId);
    if (!activeCall) {
      return;
    }
    let anotherSlotId: number = getOtherAccountId(activeCall.accountId);
    let incomCall = getFirstCallByState(callList, CallStateConst.CALL_STATUS_INCOMING);
    if (incomCall && incomCall.accountId === anotherSlotId) {
      let param: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName
      };
      this.report('DUALCARD_HOLD_FAILED', param);
    }
  }

  public reportAnswerCallInLeatherMode() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_LEATHER_ANSWER', param);
  }

  public reportRejectCallInLeatherMode() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_LEATHER_REJECT', param);
  }

  public reportHangUpCallInLeatherMode() {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_LEATHER_HANGUP', param);
  }

  public reportCallBlockReason(blockReason: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'BLOCKREASON': blockReason
    };
    this.report('CALL_BLOCK_REASON', param);
  }

  public reportOpenSummaryFail(errorType: string, isAutoSummary: boolean = false) {
    let param: Record<string, string | number | boolean | undefined> = {
      'IS_AUTO_SUMMARY': isAutoSummary,
      'ERROR_TYPE': errorType
    };
    this.reportDftEvent(SUMMARY_FAIL, hiSysEvent.EventType.FAULT, param);
  }

  public reportSummaryConflict(sceneName: string, resolution: string) {
    let param: Record<string, string | number | boolean | undefined> = {
      'SCENE_NAME': sceneName,
      'RESOLUTION': resolution
    };
    this.reportDftEvent(SUMMARY_CONFLICT, hiSysEvent.EventType.STATISTIC, param);
  }

  public reportFlowingLight(eventName: string, eventType: hiSysEvent.EventType) {
    this.reportUeEvent(eventName, eventType);
  }

  public reportClickCeliaAnswer(eventName: string, eventType: hiSysEvent.EventType) {
    this.reportUeEvent(eventName, eventType);
  }

  public reportIsAutoSummary(eventName: string, eventType: hiSysEvent.EventType, isAutoSummary: boolean) {
    let customizedParams: Record<string, string | number | boolean | undefined> = {
      'IS_AUTO_SUMMARY': isAutoSummary ? 0 : 1
    };
    this.reportUeEvent(eventName, eventType, customizedParams);
  }

  private reportIsEnableNewFeature(eventName: string, eventType: hiSysEvent.EventType,
    customizedParams: Record<string, string | number | boolean | undefined>) {
    this.reportUeEvent(eventName, eventType, customizedParams);
  }

  public reportNewFeatureEvent(eventName: string) {
    const lastReportTime: number = AppStorage.get<number>('reportEnableFeatureTime') ?? 0;
    /** 以毫秒为单位，一月上报一次 */
    if ((Date.now() - lastReportTime) >= 1000 * 60 * 60 * 24 * 30) {
      AppStorage.setOrCreate('reportEnableFeatureTime', Date.now());
      let customizedParams: Record<string, string | number | boolean | undefined> = {
        'IS_ENABLE_NEW_FEATURES' : DISABLE_NEW_FEATURE
      };
      this.reportIsEnableNewFeature(eventName, hiSysEvent.EventType.STATISTIC, customizedParams);
    }
  }
  
  public reportAgreePolicy(eventName: string, eventType: hiSysEvent.EventType) {
    this.reportUeEvent(eventName, eventType);
  }

  public reportIntelligentDuration(eventName: string, duration: number) {
    let customizedParams: Record<string, string | number | boolean | undefined> = {
      'DURATION_TIME' : duration
    };
    this.reportUeEvent(eventName, hiSysEvent.EventType.BEHAVIOR, customizedParams);
  }

  private reportDftEvent(eventName: string, eventType: hiSysEvent.EventType,
    customizedParams: Record<string, string | number | boolean | undefined>) {
    try {
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: DOMAIN_DFT,
        name: eventName,
        eventType: eventType,
        params: customizedParams
      };
      this.write(eventInfo);
    } catch (err) {
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  private reportUeEvent(eventName: string, eventType: hiSysEvent.EventType,
    customizedParams?: Record<string, string | number | boolean | undefined>) {
    let param: Record<string, string | number | boolean | undefined> = customizedParams || {};
    param['PNAMEID'] = packageName;
    param['PVERSIONID'] = this.versionName;
    param['DEVICE_TYPE'] = this.currentDeviceType;
    param['SCREEN_FORM'] = ScreenAdapterUtils.getInstance().getScreenForm();
    this.report(eventName, param, this.currentDeviceType, eventType);
  }
}
