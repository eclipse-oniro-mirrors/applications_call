/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import { LogUtils } from './LogUtils';
import bundleManager from '@ohos.bundle.bundleManager';
import deviceInfo from '@ohos.deviceInfo';
import hiSysEvent from '@ohos.hiSysEvent';
import { SatelliteSimCardInfoStruct } from '../data/SimCardInfoStruct';
import SystemModeUtils from './SystemModeUtils';
import { getFoldStatus } from './CommonUtil';

const TAG = 'ReportUtil';
/** ue report call field domain */
const DOMAIN = 'PHONE_UE';
const packageName = 'com.ohos.callsetting';

export interface PrivacyStatement {
  isStartService: boolean
  agreeTime: number
  privacyVersion: string
  appVersion: string
}

/**
 * get app version
 *
 * @return string, app version
 */
export async function getVersionName(callback: Function): Promise<void> {
  let version: string;
  let bundleInfo: bundleManager.BundleInfo =
    await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  version = bundleInfo.versionName;
  callback(version);
}

/**
 * get current device Type
 *
 * @return {number}, 0: phone 1：pad 2：other
 */
function getDeviceType(): number {
  const deviceTypeInfo = deviceInfo.deviceType;
  if (deviceTypeInfo === 'phone') {
    return 0;
  } else if (deviceTypeInfo === 'tablet') {
    return 1;
  } else {
    return 2;
  }
}

export class ReportUtil {
  private static sReportUtil: ReportUtil;
  public versionName: string = '1.0'; // app version
  public modeName: string = ''; // mode name
  private currentDeviceType: number = -1;
  public satelliteUseStartTime: number = 0;

  constructor() {
    getVersionName((verison: string) => {
      this.versionName = verison;
    });
    this.currentDeviceType = getDeviceType();
    this.modeName = SystemModeUtils.getInstance().getName();
  }

  public static getInstance(): ReportUtil {
    if (!ReportUtil.sReportUtil) {
      ReportUtil.sReportUtil = new ReportUtil();
    }
    return ReportUtil.sReportUtil;
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

  private report(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>) {
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'DEVICE_TYPE': this.currentDeviceType,
          'MODE_NAME': this.modeName
        };
        customizedParams = params;
      }
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: DOMAIN,
        name: eventName,
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: customizedParams
      };
      hiSysEvent.write(eventInfo).then(
        () => {
          LogUtils.i(TAG, `hiSys write eventName:${eventName}, params:${JSON.stringify(customizedParams)}, success`);
        }
      ).catch(
        (err: BusinessError) => {
          LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
        }
      );
    } catch (err) {
      LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
    }
  }

  private reportSwitchButtonStatus(eventName: string, params: Record<string, string | number | boolean | undefined>) {
    try {
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: DOMAIN,
        name: eventName,
        eventType: hiSysEvent.EventType.STATISTIC,
        params: params
      };
      hiSysEvent.write(eventInfo).then(
        () => {
          LogUtils.i(TAG, `hiSys write eventName:${eventName}, params:${JSON.stringify(params)}, success`);
        }
      ).catch(
        (err: BusinessError) => {
          LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
        }
      );
    } catch (err) {
      LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
    }
  }

  public reportClickCallHistoryMerge() {
    this.report('CALL_SET_CLICK_HISTORYMERGE');
  }

  public reportHistoryMergeAction(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'MERGE_TYPE': action
    };
    this.report('CALL_SET_HISTORYMERGE_ACTION', params);
}

  public reportClickAutoRecord() {
    this.report('CALL_SET_CLICK_AUTO_RECORD');
  }

  public reportClickUnLockNotify() {
    this.report('CALL_SET_CLICK_NOTIFYTYPE');
  }

  public reportNotifyTypeAction(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'TYPE': action
    };
    this.report('CALL_SET_NOTIFYTYPE_ACTION', params);
  }

 public reportClickIncomingRingTone(sim1Tone?: string, sim2Tone?: string) {
   let params: Record<string, string | number | boolean | undefined> = {
     'PNAMEID': packageName,
     'PVERSIONID': this.versionName,
     'DEVICE_TYPE': this.currentDeviceType,
     'RINGTONE_ONE': sim1Tone,
     'RINGTONE_TWO': sim2Tone,
   };
   this.report('CALL_SET_CLICK_INCOMING_RING', params);
 }

  public reportClickMore(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SLOTID': slotId + 1,
    };
    this.report('CALL_SET_CLICK_MORE', params);
  }

  public reportCallWaitingState(state: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_WAITING': state,
    };
    this.report('CALL_SET_CLICK_HOLDSTATE', params);
  }

  public reportClickVoiceMail(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SLOTID': slotId + 1,
    };
    this.report('CALL_SET_CLICK_VOICEMAIL', params);
  }

  public reportCallBarringAction(setType: number, action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SET_TYPE': setType,
      'ACTION': action
    };
    this.report('CALL_SET_BARRING_ACTION', params);
  }

  public reportClickForwarding(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SLOTID': slotId + 1,
    };
    this.report('CALL_SET_CLICK_FORWARDING', params);
  }

  public reportCallForwardingSetAction(type: number, action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SET_TYPE': type,
      'ALERT': action
    };
    this.report('CALL_SET_FORWARDING_ACTION', params);
  }

  public reportClickIncomingRejectSms() {
    this.report('CALL_SET_CLICK_REJECTSMS');
  }

  public reportClickSpeedDial() {
    this.report('CALL_SET_CLICKSPEEDDIAL');
  }

  public reportSpeedDialSetSerialNum(index: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SERIAL_NUMBER': index,
    };
    this.report('CALL_SET_SPEEDDIAL_CHOOSE', params);
  }

  public reportClickAbout() {
    this.report('CALL_SET_CLICK_ABOUT');
  }

  public reportClickCeliaSwitch(value: string) {
    let params = this.getReportParams();
    params['IS_ENABLE_INTELLIGENCE'] = value;
    this.report('INTELLIGENT_ENABLE_CELIA_CALL', params);
  }

  public reportSetMobileNetworkSwitch(isOpen: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SWITCH': isOpen,
    };
    this.report('CALL_MOBILENET_SWITCH', params);
  }

  public reportCheckApnList(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SLOTID': slotId,
    };
    this.report('CALL_MOBILENET_APNLIST', params);
  }

  public reportClickMobileRoamingButton(slotId: number, btnState: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SWITCH': btnState,
      'SLOTID': slotId
    };
    this.report('CALL_MOBILENET_ROAMING', params);
  }

  public reportNewCallingStateChange(btnState: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'NEW_CALLING_SWITCH_STATE': btnState,
    };
    this.report('NEW_CALLING_SWITCH_CHANGE', params);
  }

  public delayReportNewCallingState(eventName: string, btnState: number, slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'NEW_CALLING_SWITCH_STATE': btnState,
      'SLOTID': slotId
    };
    if (this.versionName === '1.0') {
      this.currentDeviceType = getDeviceType();
      getVersionName((verison: string) => {
        this.versionName = verison;
        params['PVERSIONID'] = this.versionName;
        this.reportSwitchButtonStatus(eventName, params);
      });
    } else {
      this.reportSwitchButtonStatus(eventName, params);
    }
  }

  /**
   * open Satellite Call
   *
   * @return {number}, operationType - 1 : open, 2 : close
   */
  public reportEnterSatelliteCall(operationType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': operationType,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_ENTER', params);
  }

  /**
   * satellite Call select sim card alert dialog use action
   *
   * @return {number}, action - 1 : select sim1, 2 : select sim2, 3: click cancel
   */
  public reportSatelliteCallSelectSimCardAlert(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': action,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_SELECT_SIM', params);
  }

  /**
   * Open Satellite Call Issue
   *
   * @return {number}, type - 1 : not have CTCard, 3 : in airplane, 4 : tianjitong opend  6: has active call
   */
  public reportOpenSatelliteCallIssue(type: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ERR_TYPE': type,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_OPEN_ISSUE', params);
  }

  public reportClickUserProtocol() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_PROTOCOL', params);
  }

  public reportClickDisableProtocolBtn(operation: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'OPERATION_TYPE': operation,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_DISABLE_PROTOCOL', params);
  }

  public reportClickUserPrivacy() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_PRIVACY', params);
  }

  public reportClickDisablePrivacyBtn(operation: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'OPERATION_TYPE': operation,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_DISABLE_PRIVACY', params);
  }

  public reportClickUserPermissions() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_PERMISSIONS', params);
  }

  /**
   * Open Satellite Call Issue
   *
   * @return {number}, isCalibration - 0 :no calibration required, 1 : calibration required
   */
  public reportEnterSatelliteIsNeedCalibration(isCalibration: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ISNEED_CALIBRATION': isCalibration,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_IS_CALIBRATION', params);
  }

  public reportSatelliteCalibrationInfo(duration: number, result: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CALIBRATION_RESULT': result,
      'CALIBRATION_TIME': duration,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CALIBRATION', params);
  }

  public reportSatelliteLoadingInfo(duration: number, result: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'LOADING_RESULT': result,
      'LOADING_TIME': duration,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_LOADING', params);
  }

  public reportSatelliteConnectInfo(duration: number, result: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CONNECT_RESULT': result,
      'CONNECT_TIME': duration,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CONNECT', params);
  }

  public reportSatelliteSignalChange(currentState: number, level: number, strength: number) {
    if (currentState === 4) {
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'LEVEL': level,
        'STRENGTH': strength,
        'MODE_NAME': this.modeName
      };
      this.report('SATELLITE_CALL_SIGNAL', params);
    }
  }

  public reportSatelliteConnectedClickMessage() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_MMS', params);
  }

  public reportSatelliteConnectedClickPhone() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_PHONE', params);
  }

  public reportSatelliteClickReConnectingBtn() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_RECONNECT', params);
  }

  public reportSatelliteClickReSearchBtn() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_RELOADING', params);
  }

  public reportOpenSatelliteSimCardInfo(simCardInfoList: SatelliteSimCardInfoStruct[] | undefined) {
    let sim1Type: number = 0;
    let sim2Type: number = 0;
    let sim1State: number = 1;
    let sim2State: number = 1;
    if (simCardInfoList !== undefined && simCardInfoList.length > 0) {
      for (let i = 0; i < simCardInfoList.length; i++) {
        let simInfo: SatelliteSimCardInfoStruct = simCardInfoList[i];
        if (simInfo.slotId == 0) {
          sim1Type = 1;
          sim1State = 0;
        } else if (simInfo.slotId == 1) {
          sim2Type = 1;
          sim2State = 0;
        }
      }
    }
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SIM1_TYPE': sim1Type,
      'SIM2_TYPE': sim2Type,
      'SERVICE_SIM1': sim1State,
      'SERVICE_SIM2': sim2State
    };
    this.report('SATELLITE_CALL_SIM_INFO', params);
  }

  public reportSatelliteHighTempDial() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_HIGH_TEMP_DIAL', params);
  }

  public reportSatelliteClickHighTempInCall() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_HIGH_TEMP_INCALL', params);
  }

  /**
   * satellite call quit
   *
   * @return {number}, quit reason - 1: initiative to exit, 3: in airplan, 5: plug and unplug sim card
   */
  public reportSatelliteCallQuit(reason: number) {
    let duration: number = new Date().valueOf() - this.satelliteUseStartTime;
    if (this.satelliteUseStartTime > 0 && duration > 0) {
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'EXITREASON': reason,
        'USE_TIME': duration,
        'MODE_NAME': this.modeName
      };
      this.report('SATELLITE_CALL_QUIT', params);
      this.satelliteUseStartTime = 0;
    }
  }

  public reportSatelliteErrorCode(code: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ERR_CODE': code,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_ERROR_CODE', params);
  }

  public reportHyacinthEntrance() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType
    };
    this.report('HYACINTH_CLICK_ENTRANCE', params);
  }

  public reportHyacinthActivate() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType
    };
    this.report('HYACINTH_ACTIVATE', params);
  }

  public reportHyacinthSwitch(status: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'STATUS': status
    };
    this.report('HYACINTH_SWITCH', params);
  }

  public reportHyacinthUncertain() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType
    };
    this.report('HYACINTH_UNCERTAIN_AVAILABLE', params);
  }

  public reportHyacinthConnectFail(status: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'STATUS': status
    };
    this.report('HYACINTH_CONNECT_FAIL', params);
  }

  public reportHyacinthConnectTime() {
    let duration: number = new Date().valueOf() - this.satelliteUseStartTime;
    if (this.satelliteUseStartTime > 0 && duration > 0) {
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'DEVICE_TYPE': this.currentDeviceType,
        'TIME': duration
      };
      this.report('HYACINTH_SATELLITE_CONNECT_TIME', params);
    }
  }

  public reportHyacinthUseTime() {
    let duration: number = new Date().valueOf() - this.satelliteUseStartTime;
    if (this.satelliteUseStartTime > 0 && duration > 0) {
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'DEVICE_TYPE': this.currentDeviceType,
        'TIME': duration
      };
      this.report('HYACINTH_SATELLITE_USE_TIME', params);
    }
  }

  public reportClickCreateApn() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_MOBILENET_CREATE_APN', params);
  }

  public reportClickResetDefaultApn() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_MOBILENET_RESET_APN', params);
  }

  public reportClickAvailableNetSwitch(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'OPERATE': action
    };
    this.report('CALL_MOBILENET_AVAILABLE_NET', params);
  }

  public reportClickCommonQuestion() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_COMMON', params);
  }

  public reportSatelliteChangeFloatWindow() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CHANGE_FLOAT_WIN', params);
  }

  /**
   * open Satellite Call
   *
   * @param {action}, actionType - 0 : click exit button, 1 : don't exit, 2 : auto exit
   */
  public reportSatelliteNotConnectedForOneMinute(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': action,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_NOT_CONNECT_LONG', params);
  }

  public reportClickSatelliteRecalibrateBtn() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_CLICK_RECALIBRATE', params);
  }

  public reportSatelliteCallDisconnectWithCause(cause: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DISCONNECTCAUSE': cause,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_HANGUP_INFO', params);
  }

  public reportCellularNetworkNotification(position: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'NOTIFICATIONPOSITION': position
    };
    this.report('CELLULAR_NETWORK_NOTIFICATION', params);
  }

  public reportDetectCellularNetwork(isExist: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ISEXIST': isExist
    };
    this.report('DETECT_CELLULAR_NETWORK', params);
  }

  public delayReportSwitchButtonStateEvent(eventName: string, stateValue: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'VALUE': stateValue
    };
    if (this.versionName === '1.0') {
      this.currentDeviceType = getDeviceType();
      getVersionName((verison: string) => {
        this.versionName = verison;
        params['PVERSIONID'] = this.versionName;
        this.reportSwitchButtonStatus(eventName, params);
      });
    } else {
      this.reportSwitchButtonStatus(eventName, params);
    }
  }

  public reportSatelliteOpenDialog() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_OPEN_DIALOG', params);
  }

  public reportOpenSatelliteDialogAction(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': action,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_OPEN_ACTION', params);
  }

  public reportClickAdvance() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_SET_CLICK_ADVANCE', params);
  }

  public reportImproveCallQualityStatus(isOn: boolean) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': isOn ? 1 : 0,
    };
    this.report('CALL_SET_IMPROVEQUALITY_STATUS', params);
  }

  public reportTrafficSwitch(isSwitch: boolean) {
    LogUtils.i(TAG, `TRAFFIC_SWITCH isSwitch: ${isSwitch} `);
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'IS_SWTICH': isSwitch
    };
    this.report('TRAFFIC_SWITCH', params);
  }

  public reportRoamingSwitch(isSwitch: boolean) {
    LogUtils.i(TAG, `ROAMING_SWITCH isSwitch: ${isSwitch} `);
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'IS_SWTICH': isSwitch
    };
    if (!!isSwitch) {
      this.report('ROAMING_SWITCH', params);
    }
  }

  public reportAccessPointSelect(accessName: string, accessTotal: number) {
    LogUtils.i(TAG, `ACCESS_POINT_SELECT accessName: ${accessName} - accessTotal:${accessTotal}`);
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'ACCESS_POIN': accessName,
      'ACCESS_POIN_TOTAL': accessTotal,
    };
    this.report('ACCESS_POINT_SELECT', params);
  }

  public reportEndCallSwitch(isOn: boolean) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': isOn ? 1 : 0
    };
    this.report('CALL_SET_POWER_END_CALL_SWTICH', params);
  }

  public reportVideoRingToneSwitch(isOn: boolean) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': isOn ? 1 : 0
    };
    this.report('CALL_SET_VIDEO_RBT_SWTICH', params);
  }

  public reportSelectApn(selectCommon: number, slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SELECTID': selectCommon,
      'SLOTID': slotId
    };
    this.report('MOBILENET_SELECT_APN', params);
  }

  public reportPhoneShareSwitch(isOn: boolean) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': isOn ? 1 : 0
    };
    this.report('SHARE_PHONE_SHARING_SWITCH', params);
  }

  public reportClickNetConnect() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('SHARE_NET_CONNECT_CLICK_PAD', params);
  }

  public reportSatelliteExpandToUseToast() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_CALL_EXPAND_USING', params);
  }

  public reportClickWifiCalling() {
    this.report('CALL_SET_CLICK_WIFI_CALLING');
  }

  public reportWifiCallingSwitchState(isOn: boolean) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': isOn ? 1 : 0,
    };
    this.report('CALL_SET_WIFI_CALLING_STATUS', params);
  }

  public reportGetSimNameWithSlotId(slotId: number, simInfo: [boolean, string][]) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': slotId,
      'SIMTYPE': simInfo[slotId][0] ? 'PSIM' : 'ESIM',
      'CARDNAME': simInfo[slotId][1]
    };
    this.report('CALL_SET_GET_SIMLABEL', params);
  }

  /**
   * open Satellite Network Enter
   *
   * @return {number}, operationType - desktop : 桌面, settings : 设置
   */
  public reportEnterSatelliteNetwork(operationType: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': operationType,
      'MODE_NAME': this.modeName
    };
    this.report('SATELLITE_NETWORK_ENTER', params);
  }

  private getReportParams(): Record<string, string | number | boolean | undefined> {
    return {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SCREEN_FORM': getFoldStatus(),
    };
  }
}