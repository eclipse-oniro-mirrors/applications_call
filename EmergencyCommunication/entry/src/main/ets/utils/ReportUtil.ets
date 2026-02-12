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
import LogUtils from './HiLog';
import bundleManager from '@ohos.bundle.bundleManager';
import deviceInfo from '@ohos.deviceInfo';
import hiSysEvent from '@ohos.hiSysEvent';
import WantAgent, { WantAgent as _WantAgent } from '@ohos.app.ability.wantAgent';
import { SystemTimerUtils } from './SystemTimerUtils';
import { systemDateTime, systemTimer } from '@kit.BasicServicesKit';
import ReportPreferencesUtils from './ReportPreferencesUtils';
import { Utils } from './Utils';
import { WantUtils } from './WantUtils';
import ScreenAdapterUtils from './ScreenAdapterUtils';
import { DeviceLocation, RequestParameterStruct } from './ClassStruct';
import { geoLocationManager, } from '@kit.LocationKit';
import { EarthquakeType } from '../data/CommonData';

const TAG = 'ReportUtil';
/** ue report call field domain */
const DOMAIN = 'PHONE_UE';
const packageName = 'com.ohos.emergencycommunication';
const INVALID = 'invalidLocation'

/**
 * get app version
 *
 * @return string, app version
 */
export async function getVersionName(defaultValue: string, callback?: (version: string) => void): Promise<string> {
  let version: string = defaultValue;
  try {
    const bundleInfo: bundleManager.BundleInfo | null =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
        .catch((e: BusinessError) => {
          LogUtils.e(TAG, `getBundleInfoForSelf error: ${e.code} ${e.message}`);
          return null;
        });
    version = bundleInfo?.versionName || defaultValue;
  } catch (e) {
    LogUtils.e(TAG, `getVersionName error: ${JSON.stringify(e)}`);
  }
  if (callback) {
    callback(version);
  }
  return version;
}

/**
 * get current device Type
 *
 * @return {number}, 0: phone 1：pad 2：other
 */
export function getDeviceType(): number {
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
  public static sReportUtil: ReportUtil | null;
  public static VERSION_NAME_EMPTY_VALUE = '1.0';
  private versionName: string = ReportUtil.VERSION_NAME_EMPTY_VALUE; // app version
  private currentDeviceType: number = -1;
  private reportPreferencesUtils: ReportPreferencesUtils = ReportPreferencesUtils.getInstance();

  constructor() {
    getVersionName(ReportUtil.VERSION_NAME_EMPTY_VALUE, (version: string) => {
      this.versionName = version;
    });
    this.currentDeviceType = getDeviceType();
  }

  public static getInstance(): ReportUtil {
    if (!ReportUtil.sReportUtil) {
      ReportUtil.sReportUtil = new ReportUtil();
    }
    return ReportUtil.sReportUtil;
  }

  public static reportDrawnCompleted(asyncTaskCount: number, context: Context) {
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

  public setVersionName(versionName: string) {
    this.versionName = versionName;
  }

  private report(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>) {
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'DEVICE_TYPE': this.currentDeviceType,
          'CALL_TYPE': 0,
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
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  public reportShowEmergencyPage() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos('CALL_CLICK_EMERGENCY', params);
  }

  public reportClickPersonEmergencyInfo() {
    this.report('CALL_CLICK_EMERGENCYINFO');
  }

  private reportDial(numberLength: number, eventName: string) {
    let isSatellite: boolean | undefined = AppStorage.get('isSatelliteModeOn');
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': isSatellite ? 1 : 0,
      'NUMBER_LENGTH': numberLength
    };
    this.report(eventName, params);
  }

  public reportEmergencyDial(numberLength: number) {
    let isSatellite: boolean | undefined = AppStorage.get('isSatelliteModeOn');
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'DEVICE_TYPE': this.currentDeviceType,
      'CALL_TYPE': isSatellite ? 1 : 0,
      'NUMBER_LENGTH': numberLength,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.report('CALL_EMERGENCY_NUMBER', params);
  }

  public reportEmergencyContactListDial(numberLength: number) {
    this.reportDial(numberLength, 'CALL_EMERGENCY_CONTACT');
  }

  public reportClickAddEmergencyContact() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_CLICK_ADD_EMERGENCYCONTACT', params);
  }

  public reportAddEmergencyContactSuccess() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_ADD_EMERGENCYCONTACT_OK', params);
  }

  public reportClickEditEmergencyInfo() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_CLICK_EDIT_EMERGENCYINFO', params);
  }

  public reportClickAddEmergencyInfo() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_CLICK_ADD_EMERGENCYINFO', params);
  }

  public reportClickGEOLocation() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_CLICK_GEO_LOCATION_INFO', params);
  }

  public reportEntryEmergencyContact() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report('CALL_CLICK_EMERGENCYCONTACT', params);
  }

  public reportContinueClickToEmergency() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.report('CALL_CONTINUECLICK_TO_EMERGENCY', params);
  }

  public reportEmergencyRescueSwitch(isOn: boolean) {
    let params: Record<string, string | number | boolean | undefined> = {
      'FUNC_ON': isOn,
    };
    this.reportOfEmergencyRescue('EMERGENCY_RESCUE_CHANGE_SWITCH', params)
  }

  public reportEmergencyMessage(battery: number, distressSituation: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'BATTERY': battery,
      'DISTRESS_SITUATION': distressSituation,
    };
    this.reportOfEmergencyRescue('EMERGENCY_RESCUE_MESSAGE', params)
  }

  public reportRescueMessageCount(receiveCount: number, sendCount: number, failedCount: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'RECEIVE_COUNT': receiveCount,
      'SEND_COUNT': sendCount,
      'FAILED_COUNT': failedCount,
    };
    this.reportOfEmergencyRescue('EMERGENCY_RESCUE_MESSAGE_COUNT', params)
  }

  public reportEmergencyRescueNetworkConnect(connectTimes: number, disconnectTimes: number, costTime: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'CONNECT_TIMES': connectTimes,
      'DISCONNECT_TIMES': disconnectTimes,
      'COST_TIME': costTime,
    };
    this.reportOfEmergencyRescue('EMERGENCY_RESCUE_NETWORK_CONNECT', params)
  }

  public reportRescueKeepTime(time: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'TIME': time,
    };
    this.reportOfEmergencyRescue('EMERGENCY_RESCUE_KEEP_TIME', params)
  }

  private async reportOfEmergencyRescue(eventName: string,
    customizedParams?: Record<string, string | number | boolean | undefined>, eventType?: hiSysEvent.EventType) {
    LogUtils.i(TAG, `reportOfEmergencyRescue`);
    if (customizedParams === null || customizedParams === undefined) {
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName
      };
      customizedParams = params;
    } else {
      if (customizedParams['PNAMEID'] === undefined) {
        customizedParams['PNAMEID'] = packageName;
      }
      if (customizedParams['PVERSIONID'] === undefined) {
        customizedParams['PVERSIONID'] = this.versionName;
      }
      if (customizedParams['SCREEN_FORM'] === undefined) {
        customizedParams['SCREEN_FORM'] = ScreenAdapterUtils.getInstance().getScreenForm();
      }
      if (customizedParams['PRODUCT_MODEL'] === undefined) {
        customizedParams['PRODUCT_MODEL'] = ScreenAdapterUtils.getProductType();
      }
    }
    let eventInfo: hiSysEvent.SysEventInfo = {
      domain: DOMAIN,
      name: eventName,
      eventType: eventType ?? hiSysEvent.EventType.BEHAVIOR,
      params: customizedParams
    };
    await hiSysEvent.write(eventInfo).then(() => {
      LogUtils.i(TAG, `hiSys write eventName:${eventName}, params:${JSON.stringify(customizedParams)}, success`);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
    });
  }

  private async reportOfEarthquakeAndSos(eventName: string,
    customizedParams?: Record<string, string | number | boolean | undefined>, eventType?: hiSysEvent.EventType) {
    LogUtils.i(TAG, `reportOfEarthquakeAndSos`);
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName
        };
        customizedParams = params;
      }
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: DOMAIN,
        name: eventName,
        eventType: eventType ?? hiSysEvent.EventType.BEHAVIOR,
        params: customizedParams
      };
      await hiSysEvent.write(eventInfo).then(
        () => {
          LogUtils.i(TAG, `hiSys write eventName:${eventName}, params:${JSON.stringify(customizedParams)}, success`);
        }
      ).catch(
        (err: BusinessError) => {
          LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
        }
      );
    } catch (err) {
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  private reportWarnSosWarningSwitchDial(switchStatus: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'EARTHQUAKEWARNINGSWITCH': switchStatus
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }


  private reportWarnSosWarningSwitchReportingPositionDial(positionResult: number,
    administrativeArea: string | undefined,
    subAdministrativeArea: string | undefined, locality: string | undefined, includeGeo: number,
    includeLonLat: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'RESULT': positionResult,
      'ADMINISTRATIVEAREA': administrativeArea,
      'SUBADMINISTRATIVEAREA': subAdministrativeArea,
      'LOCALITY': locality,
      'INCLUDEGEO': includeGeo,
      'INCLUDELONLAT': includeLonLat,
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosEarthquakePushMsgDial(syncTime: number, eventId: number, administrativeArea: string,
    subAdministrativeArea: string, locality: string, includeLonLat: number,
    eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'PUSHMSGTIME': syncTime,
      'EARTHQUAKEEVENTID': String(eventId),
      'ADMINISTRATIVEAREA': administrativeArea,
      'SUBADMINISTRATIVEAREA': subAdministrativeArea,
      'LOCALITY': locality,
      'INCLUDELONLAT': includeLonLat,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosEarthquakePushMsgAlertRes(syncTime: number, eventId: string, levelTotal: number,
    receiveTime: number, reminderType: number, administrativeAreaGeoCode: string, isReportTimeout: number,
    eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'PUSHMSGTIME': syncTime,
      'EARTHQUAKEEVENTID': eventId,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm(),
      'LEVELTOTAL': levelTotal,
      'RECEIVINGTIME': receiveTime,
      'REMINDERTYPE': reminderType,
      'ADMINISTRATIVEAREAGEOCODE': administrativeAreaGeoCode,
      'ISREPORTTIMEOUT': isReportTimeout
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosEarthquakePushMsgInfoDial(startAt: number, epicenter: string, magnitude: number,
    intensity: number, eventId: number, source: number, pushMsgType: string, pushMsgMsgType: string, longitude: number,
    latitude: number,
    depth: number, provinceCode: string, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'PUSHMSGSARTAT': startAt,
      'PUSHMSGEPICENTER': epicenter,
      'PUSHMSGMAGNITUDE': magnitude,
      'PUSHMSGINTENSITY': intensity,
      'EARTHQUAKEEVENTID': String(eventId),
      'PUSHMSGSOURCE': source,
      'PUSHMSGTYPE': pushMsgType,
      'PUSHMSGMSGTYPE': pushMsgMsgType,
      'PUSHMSGEPILON': longitude,
      'PUSHMSGEPILAT': latitude,
      'PUSHMSGFOCDEPTH': depth,
      'PUSHMSGPROVINCECODES': provinceCode
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  public reportClickViewEmergencyTutorial() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_VIEW_DEMO_TUTORIAL');
  }

  public reportClickHistoricalWarning() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_CLICK_HISTRY_INFO');
  }

  public reportClickCloseButtonBeforeCountdown() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos('EARTHQUAKE_CLOSE_COUNTDOWN_PAGE', params);
  }

  public reportClickCloseButtonStatic() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos('EARTHQUAKE_CLOSE_STATIC_PAGE', params);
  }

  public reportClickEmergencyShelters() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_CLICK_EMERG_SHELTER');
  }

  public reportClickEmergencyContacts() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_CLICK_EMERG_CONTACT');
  }

  public reportClickPersonalInfo() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_CLICK_EMERG_MSG');
  }

  public reportSetEmergencyShelters() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_SET_EMERG_SHELTER');
  }

  public reportSetEmergencyContacts() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_SET_EMERG_CONTACT');
  }

  public reportSetPersonalInfo() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_SET_EMERG_MSG');
  }

  public reportGetLocationFailed(result: string) {
    this.reportGetLocationFailedDial(result, 'EARTHQUAKE_GET_LOCATION_FAILED');
  }

  public reportInterceptEarthquakeInfo(result: string) {
    this.reportInterceptEarthquakeInfoDial(result, 'EARTHQUAKE_INFORMATION_INTERCEPT');
  }

  public reportGetInformationFailed(result: string) {
    this.reportGetInformationFailedDial(result, 'EARTHQUAKE_GET_INFORMATION_FAILED');
  }

  private reportGetLocationFailedDial(result: string, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'EARTHQUAKEGETLOCATIONFAILED': result
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportInterceptEarthquakeInfoDial(result: string, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'EARTHQUAKEINFORMATIONINTERCEPT': result
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportGetInformationFailedDial(result: string, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'EARTHQUAKEGETINFORMATIONFAILED': result
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  public reportFunctionDescription() {
    this.reportOfEarthquakeAndSos('EARTHQUAKE_DESC_AREA_FUNC_DESC');
  }

  public reportIsClickSwitch(switchStatus: number) {
    this.reportWarnSosWarningSwitchDial(switchStatus, 'EARTHQUAKE_OPEN_OR_CLOSE_SWITCH');
  }

  public async reportWarnSwitchPosition(positionResult: number,
    reportLocationDate: DeviceLocation | undefined): Promise<void> {
    const includeGeo: number = reportLocationDate?.geocode ? 1 : 0;
    const includeLonLat: number = (reportLocationDate?.longitude && reportLocationDate?.latitude) ? 1 : 0;
    if (!reportLocationDate || !reportLocationDate.latitude || !reportLocationDate.longitude) {
      LogUtils.w(TAG, 'reportWarnSwitchPosition: Invalid location data');
      this.reportWarnSosWarningSwitchReportingPositionDial(positionResult, INVALID, INVALID, INVALID, includeGeo,
        includeLonLat, 'EARTHQUAKE_REPORT_LOCATION');
      return;
    }
    try {
      const geoAddresses: geoLocationManager.GeoAddress[] = await geoLocationManager.getAddressesFromLocation({
        latitude: reportLocationDate.latitude,
        longitude: reportLocationDate.longitude,
        maxItems: 1
      });
      this.reportWarnSosWarningSwitchReportingPositionDial(
        positionResult,
        geoAddresses?.[0]?.administrativeArea || INVALID,
        geoAddresses?.[0]?.subAdministrativeArea || INVALID,
        geoAddresses?.[0]?.locality || INVALID,
        includeGeo,
        includeLonLat,
        'EARTHQUAKE_REPORT_LOCATION'
      );
    } catch (error) {
      LogUtils.e(TAG, `reportWarnSwitchPosition getAddressesFromLocation error`);
    }
  }

  public async reportReceivedEarthquakePushMessage(syncTime: number, eventId: number, longitude: number,
    latitude: number, includeLonLat: number): Promise<void> {
    if (!longitude || !latitude) {
      LogUtils.w(TAG, 'reportReceivedEarthquakePushMessage: Invalid location data');
      this.reportWarnSosEarthquakePushMsgDial(syncTime, eventId, INVALID, INVALID, INVALID, includeLonLat,
        'EARTHQUAKE_PUSH_RECEIVED');
      return;
    }
    try {
      const geoAddresses: geoLocationManager.GeoAddress[] = await geoLocationManager.getAddressesFromLocation({
        latitude: latitude,
        longitude: longitude,
        maxItems: 1
      });
      this.reportWarnSosEarthquakePushMsgDial(syncTime, eventId, geoAddresses?.[0]?.administrativeArea || INVALID,
        geoAddresses?.[0]?.subAdministrativeArea || INVALID, geoAddresses?.[0]?.locality || INVALID,
        includeLonLat, 'EARTHQUAKE_PUSH_RECEIVED'
      );
    } catch (error) {
      LogUtils.e(TAG, `reportReceivedEarthquakePushMessage getAddressesFromLocation error`);
      this.reportWarnSosEarthquakePushMsgDial(syncTime, eventId, INVALID, INVALID, INVALID, includeLonLat,
        'EARTHQUAKE_PUSH_RECEIVED');
    }
  }

  public reportReceivedEarthquakeAlertRes(syncTime: number, eventId: string, levelTotal: number, receiveTime: number,
    reminderType: number, administrativeAreaGeoCode: string, isReportTimeout: number) {
    this.reportWarnSosEarthquakePushMsgAlertRes(syncTime, eventId, levelTotal, receiveTime, reminderType,
      administrativeAreaGeoCode, isReportTimeout, 'EARTHQUAKE_REPORT_DATA');
  }

  public reportEarthquakePushMsgInfo(startAt: number, epicenter: string, magnitude: number,
    intensity: number, eventId: number, source: number, type: string, longitude: number, latitude: number,
    depth: number, provinceCode: string) {
    let pushMsgType: string = '';
    let pushMsgMsgType: string = '';
    switch (type) {
      case EarthquakeType.EARTHQUAKE_NORMAL_TYPE:
        pushMsgType = '0';
        pushMsgMsgType = '0101';
        break;
      case EarthquakeType.EARTHQUAKE_TEST_TYPE:
        pushMsgType = '1';
        pushMsgMsgType = '0101';
        break;
      case EarthquakeType.EARTHQUAKE_CANCEL_TYPE:
        pushMsgType = '0';
        pushMsgMsgType = '0199';
        break;
      case EarthquakeType.EARTHQUAKE_CANCEL_TEST_TYPE:
        pushMsgType = '1';
        pushMsgMsgType = '0199';
        break;
      default:
        break;
    }
    this.reportWarnSosEarthquakePushMsgInfoDial(startAt, epicenter, magnitude, intensity, eventId, source, pushMsgType,
      pushMsgMsgType, longitude, latitude, depth, provinceCode, 'EARTHQUAKE_PUSH_INFO');
  }

  private reportWarnSosAutoSendsMmsSwitchDial(switchStatus: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'AUTOSENDSMSSWITCH': switchStatus
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosAutoCallSwitchDial(switchStatus: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'AUTOCALLSWITCH': switchStatus
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosLocationSwitchDial(switchStatus: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'REPORTLOCATIONSWITCH': switchStatus
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosHelpingMmsSuccessOrFailDial(resultStatus: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SENDRESULT': resultStatus,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosCallHelpSuccessOrFailDial(resultStatus: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CALLRESULT': resultStatus,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnSosMakeCallTriggerLocationDial(resultReport: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'REPORTRESULT': resultReport,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  private reportWarnEpsMakeCallTriggerLocationDial(resultReport: number, eventName: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'REPORTRESULT': resultReport
    };
    this.reportOfEarthquakeAndSos(eventName, params);
  }

  public reportSosClickPersonalInfo() {
    this.reportOfEarthquakeAndSos('SOS_CLICK_EMERG_MSG');
  }

  public reportSosClickEmergencyContacts() {
    this.reportOfEarthquakeAndSos('SOS_CLICK_EMERG_CONTACT');
  }

  public reportSosMmsSwitch(switchStatus: number) {
    this.reportWarnSosAutoSendsMmsSwitchDial(switchStatus, 'SOS_CLICK_SEND_SMS_SWITCH');
  }

  public reportPersonalSafetyEnter(enterType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'PERSONALSAFETYSOSENTERTYPE': enterType
    };
    this.reportOfEarthquakeAndSos('SOS_PERSONAL_SAFETY_ENTER', params);
  }

  public reportCrashSwitchClick(switchStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHSWITCHCLICK': switchStatus
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_SWITCH_CLICK', params);
  }

  public reportCrashAudioRecordClick(playStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHAUDIORECORDCLICK': playStatus
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_AUDIO_RECORD_CLICK', params);
  }

  public reportCrashDisclaimerClick(clickStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHDISCLAIMERCLICK': clickStatus
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_DISCLAIMER_CLICK', params);
  }

  public reportCrashPrivacyClick(clickStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHPRIVACYCLICK': clickStatus
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_PRIVACY_CLICK', params);
  }

  public reportCrashPermissionClick(clickStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHPERMISSIONCLICK': clickStatus
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_PERMISSION_CLICK', params);
  }

  public reportCrashCannotEnable(status: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHCANNOTENABLE': status
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_CANNOT_ENABLE', params);
  }

  public reportCrashTrigger(triggerType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHTRIGGERTYPE': triggerType
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_TRIGGER_TYPE', params);
  }

  public reportCrashSMSResult(contact: string, resultStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CONTACT': contact,
      'CRASHSMSRESULT': resultStatus
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_SMS_RESULT', params);
  }

  public reportCrashDialResult(contact: string, triggerType: number, resultStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CONTACT': contact,
      'CRASHDIALTRIGGERTYPE': triggerType,
      'CRASHDIALRESULT': resultStatus
    };
    this.reportOfEarthquakeAndSos('SOS_CRASH_DIAL_RESULT', params);
  }

  public reportFallSwitchClick(switchStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLSWITCHCLICK': switchStatus
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_SWITCH_CLICK', params);
  }

  public reportFallAudioRecordClick(playStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLAUDIORECORDCLICK': playStatus
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_AUDIO_RECORD_CLICK', params);
  }

  public reportFallDisclaimerClick(clickStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLDISCLAIMERCLICK': clickStatus
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_DISCLAIMER_CLICK', params);
  }

  public reportFallPrivacyClick(clickStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLPRIVACYCLICK': clickStatus
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_PRIVACY_CLICK', params);
  }

  public reportFallPermissionClick(clickStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLPERMISSIONCLICK': clickStatus
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_PERMISSION_CLICK', params);
  }

  public reportFallCannotEnable(status: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLCANNOTENABLE': status
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_CANNOT_ENABLE', params);
  }

  public reportFallTrigger(triggerType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLTRIGGERTYPE': triggerType
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_TRIGGER_TYPE', params);
  }

  public reportFallSMSResult(contact: string, resultStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CONTACT': contact,
      'FALLSMSRESULT': resultStatus
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_SMS_RESULT', params);
  }

  public reportFallDialResult(contact: string, triggerType: number, resultStatus: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CONTACT': contact,
      'FALLDIALTRIGGERTYPE': triggerType,
      'FALLDIALRESULT': resultStatus
    };
    this.reportOfEarthquakeAndSos('SOS_FALL_DIAL_RESULT', params);
  }

  public reportSosTelephoneSwitch(switchStatus: number) {
    this.reportWarnSosAutoCallSwitchDial(switchStatus, 'SOS_CLICK_EMEGE_CALL_SWITCH');
  }

  public reportSosClickLocationsSwitch(switchStatus: number) {
    this.reportWarnSosLocationSwitchDial(switchStatus, 'SOS_CLICK_LOCATION_SWITCH');
  }

  public reportSosClick5Power() {
    this.reportOfEarthquakeAndSos('SOS_CLICK_5_POWER');
  }

  public reportSosClickAuditionRecording() {
    this.reportOfEarthquakeAndSos('SOS_LISTEN_HELP_SEEKING_RECORD');
  }

  public reportSosMmsSuccessOrFail(resultStatus: number) {
    this.reportWarnSosHelpingMmsSuccessOrFailDial(resultStatus, 'SOS_RECORD_SEND_SMS_REST');
  }

  public reportSosCallSuccessOrFail(resultStatus: number) {
    this.reportWarnSosCallHelpSuccessOrFailDial(resultStatus, 'SOS_RECORD_CALL_REST');
  }

  public reportSosMakeCallTriggerLocation(resultReport: number) {
    this.reportWarnSosMakeCallTriggerLocationDial(resultReport, 'SOS_REPORT_LOCATION');
  }

  public reportEpsMakeCallTriggerLocation(resultReport: number) {
    this.reportWarnEpsMakeCallTriggerLocationDial(resultReport, 'EPS_REPORT_LOCATION');
  }

  public async reportCrashSwitchStatus(context: Context) {
    const switchStatus: number = Number(Utils.isCarAccidentAutoCallSwitchOn(context));
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'CRASHSWITCHSTATUS': switchStatus
    };
    await this.reportOfEarthquakeAndSos('SOS_CRASH_SWITCH_STATUS', params, hiSysEvent.EventType.STATISTIC);
  }

  public async reportFallSwitchStatus(context: Context) {
    const switchStatus: number = Number(Utils.isFallDownAutoCallSwitchOn(context));
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'FALLSWITCHSTATUS': switchStatus
    };
    await this.reportOfEarthquakeAndSos('SOS_FALL_SWITCH_STATUS', params, hiSysEvent.EventType.STATISTIC);
  }

  async clearWeeklyReportSystemTimer() {
    await SystemTimerUtils.clearSystemTimerOfReport(SystemTimerUtils.SYSTEM_TIMER_WEEKLY_REPORT_TIMER_ID_KEY);
  }

  public reportSosClickCancelBtn(exitType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'EXITTYPE': exitType,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos('SOS_CLICK_EXIT', params);
  }

  public reportSosBeeBuzzAlarmBtn(isBeeBuzzAlarmActive: boolean) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION': isBeeBuzzAlarmActive ? 1 : 0,
      'SCREEN_FORM': ScreenAdapterUtils.getInstance().getScreenForm()
    };
    this.reportOfEarthquakeAndSos('SOS_CLICK_BEE_BUZZ_ALARM', params);
  }

  public reportEmcRescueCallCount(answerCount: number, callDurationAverage: number, exceptionCount: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'ANSWER_COUNT': answerCount,
      'CALL_DURATION_AVERAGE': callDurationAverage,
      'CALL_EXCEPTION_COUNT': exceptionCount,
    };
    this.reportOfEmergencyRescue('EMERGENCY_RESCUE_CALL_COUNT', params);
  }
}