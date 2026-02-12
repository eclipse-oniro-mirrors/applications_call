/*location
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { geoLocationManager } from '@kit.LocationKit';
//import { map, mapCommon, site } from '@kit.MapKit';
import { connection } from '@kit.NetworkKit';
import { rpc } from '@kit.IPCKit';
import commonEvent from '@ohos.commonEventManager';
import LogUtils from '../utils/HiLog';
import { hasCallSync, SosEmergencyCallController } from './SosEmergencyCallController';
import { call, sim, sms } from '@kit.TelephonyKit';
import { ContactListStruct } from '../utils/ClassStruct';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';
import { PermissionsUtils } from '../utils/PermissionsUtils';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { ReportUtil } from '../utils/ReportUtil';
import {
  AutoDialCallResult,
  AutoSendSosMessageResult,
  CommunicationNetworkType,
} from '../data/CommonData';
import { TelephoneUtil } from '../utils/TelephoneUtil';
import HashMap from '@ohos.util.HashMap';
import { SOS, CAR_ACCIDENT, FALL_DOWN } from '../utils/Constants';
import { SystemModeController } from './SystemModeController';
import { formatLocationDataOfTianTong, querySatelliteLocationData } from '../model/SatelliteModel';
import {
  TIAN_TONG_CONNECT_STATE_KEY,
  TIAN_TONG_SLOT_KEY
} from '../utils/SatelliteUtil';
import { StringUtil } from '../utils/StringUtil';
import { CryptoFrameworkUtils } from '../utils/CryptoFrameworkUtils';
import { COMMUNICATION_NETWORK_TYPE } from '../pages/SosEmergencyCall';
import LocationUtils, { AdaptedReverseGeocodeResult } from '../utils/LocationUtils';

const TAG = 'SosEmergencySmsController';

//The unit is m.
// The timer is invoked to send an SMS message when the distance exceeds the value of
// this parameter and the SMS message is sent within 2 or 10 minutes.
const DISTANCE_LIMIT = 500;
const COORDINATE_PRECISION = 6; // Longitude and latitude coordinate precision

//天通卫星短信内容所用字符串
const LEFT_BRACKETS: string = '【';
const RIGHT_BRACKETS: string = '】';
const SPLIT: string = '\n';
const DEGREE: string = '°';
const MINUTE: string = '\'';
const SECOND: string = '\"';

/**
 * 位置数据
 */
interface LocationData {
  latitude: number;
  longitude: number;
}

export const IS_RUNNING_OF_AUTO_SEND_SOS_MSG = 'isRunningOfAutoSendSosMsg';

export class SosEmergencySmsController {
  private static instance: SosEmergencySmsController | null;
  public static readonly IGNORE_LOCATION_SWITCH_KEY = 'SosEmergencyHelp_isOpenedLocationSwitch';
  public static readonly SOS_CAN_AUTO_SEND_SOS_MESSAGE_KEY = 'sosEmergencyCall_canAutoSendSosMessage';
  private static readonly MESSAGE_NUMBERS_LIMIT = 30;
  private timesOfAutoSendSosMessage: number = 0;
  private twoMinutesAlarmTimeoutId: number | null = null;
  private tenMinutesAlarmTimeoutId: number | null = null;
  private fifteenSecondsAlarmTimeoutId: number | null = null;
  private allowTwoMinTimerSendSms: boolean = false;
  public firstSendSuccess: boolean = false;
  private lastLocation: geoLocationManager.Location | null = null;
  private mContext: Context | null = null;
  private mUiContext: UIContext | null = null
  //天通网络下自动发送求助信息功能使用的变量
  /** 天通下自动发送求助信息的短时循环定时器id */
  private shortTimeAlarmTimerIdOfTianTong: number | null = null;
  /** 天通下自动发送求助信息的长时循环定时器id */
  private longTimeAlarmTimerIdOfTianTongNet: number | null = null;
  /** 天通下自动发送求助信息的'首次发送'循环定时器id 该定时器每30s回调一次知道成功发送求助信息为止 */
  private firstSendAlarmTimerIdOnTianTongNet: number | null = null;
  /** 天通下自动发送求助信息流程中位置是否变更DISTANCE_LIMIT的距离 */
  private isLocationChangeOnTianTongNet: boolean = false;
  /** 天通下当前的位置 */
  private currentLocationOfTianTong: LocationData | null = null;
  /** 天通下自动发送求助信息流程的格式化后的联系人号码列表 */
  private sendFormatNumbers: string[] = [];
  /** 天通下求助信息内容中的位置描述 */
  private tianTongLocationString: string = '';
  /** 定时器id 该定时器用在第一次自动发送求助信息后回调去开始自动拨打求助电话流程 */
  private sosMessageCallbackTimeoutIdOnTianTong: number | null = null;
  /** 定时器id 两分钟定时器续订位置开关*/
  private twoMinutesTimesTimeoutId: number | null = null;

  public static getInstance(): SosEmergencySmsController {
    if (SosEmergencySmsController.instance == null) {
      SosEmergencySmsController.instance = new SosEmergencySmsController();
    }
    return SosEmergencySmsController.instance;
  }

  public static destroyInstance() {
    SosEmergencySmsController.instance = null;
  }

  /**
   * 设置context和uiContext
   * @param context
   * @param uiContext
   */
  public setAbilityContextAndUiContext = (context: Context, uiContext: UIContext) => {
    this.mContext = context;
    this.mUiContext = uiContext;
  }

  /**
   * 天通下获取天通求助信息的内容
   * @param bodyText 主体消息
   * @param address 位置描述
   * @param context Context
   * @returns Promise<string> 天通求助信息内容
   */
  private static async getMessage(bodyText: string, address: string, context: Context,
    countryIso: string): Promise<string> {
    let phoneNumber = address;
    if (!StringUtil.isEmpty(address)) {
      try {
        let data = await call.formatPhoneNumberToE164(address, countryIso).catch((error: BusinessError) => {
          LogUtils.e(TAG, `getMessage:formatPhoneNumberToE164 failed, error: ${error?.code} ${error?.message}`);
        });
        if (data) {
          phoneNumber = data;
        }
      } catch (e) {
        LogUtils.e(TAG, `getMessage: formatPhoneNumberToE164 error: ${e?.code} ${e?.message}`);
      }
    }

    if (phoneNumber.startsWith('+86')) {
      phoneNumber = phoneNumber.substring(3);
    }

    let messageString = '';
    if (context != null) {
      messageString = 'DANDELION_MESSAGE' + bodyText + phoneNumber;
    } else {
      messageString = bodyText + phoneNumber;
    }

    let stringSha256: string = await CryptoFrameworkUtils.stringToSha256(messageString);
    bodyText = bodyText + '\n' + '「' + stringSha256.substring(stringSha256.length - 6) + '」';
    return bodyText;
  }

  /**
   * 天通下发送求助信息
   * @param context Context
   * @param afterFirstSmsMessageSend 可选参数 用于在第一次发送自动求助消息后回调开始自动拨打求助电话流程
   */
  private sendSmsOnTianTongNet = (context: Context | null, afterFirstSmsMessageSend?: () => void) => {
    LogUtils.i(TAG, `sendSmsOnTianTongNet: already sent successfully for ${this.timesOfAutoSendSosMessage} times`);
    if (!context) {
      LogUtils.e(TAG, 'sendSmsOnTianTongNet: context empty');
      afterFirstSmsMessageSend?.();
      return;
    }

    if (!SosEmergencyCallController.getInstance().isDisplayCallUi) { // 若不因拉起通话界面而退到后台
      // 在非车祸或跌倒场景即主动拉起SOS求助界面场景下, 当前界面处于后台时不执行功能
      const isCheckPass = SosEmergencyCallController.checkSosEmergencyCallAbilityState(this.mUiContext);
      if (!isCheckPass) {
        LogUtils.w(TAG, 'sendSmsOnTianTongNet: current page on background, return');
        this.stopAutoSendSosMessage();
        return;
      }
    }

    //校验当前自动发送求助信息流程发送成功次数是否超过最大值
    if (this.timesOfAutoSendSosMessage > SosEmergencySmsController.MESSAGE_NUMBERS_LIMIT) {
      LogUtils.w(TAG, `sendSmsOnTianTongNet: The number of sending times exceeds ${
      SosEmergencySmsController.MESSAGE_NUMBERS_LIMIT}.`);
      this.stopAutoSendSosMessage();
      return;
    }
    const contacts = AppStorage.get<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY);
    if (!contacts || contacts.length === 0) {
      LogUtils.w(TAG, 'sendSmsOnTianTongNet: no contacts');
      return;
    }

    //检查天通卫星网络连接状态，断连返回
    let isTianTongSatelliteConnected = AppStorage.get<boolean>(TIAN_TONG_CONNECT_STATE_KEY) ?? false;
    if (!isTianTongSatelliteConnected) {
      LogUtils.w(TAG, 'sendSmsOnTianTongNet: TianTong satellite network disconnected');
      afterFirstSmsMessageSend?.();
      return;
    }

    // 若连接上但当前有卫星通话，提示后返回。
    if (hasCallSync()) {
      LogUtils.w(TAG, 'sendSmsOnTianTongNet: current has call');
      this.mUiContext?.getPromptAction().showToast({
        message: $r('app.string.unsupport_satellite_card_content'),
        duration: 3000,
      });
      afterFirstSmsMessageSend?.();
      return;
    }
    //使用卫星设置里的SIM卡的slotId
    let slotId: number = Number(settings.getValueSync(context, TIAN_TONG_SLOT_KEY, '0'));
    LogUtils.i(TAG, 'sendSmsOnTianTongNet: slotId ' + slotId);

    let originContent: string = this.getTianTongShortMessageContent(context);

    //给紧急联系人列表里的所有紧急联系人发送求助信息，一轮中有一个发送成功时发送次数+1
    let sendResults: (boolean | null)[] = new Array(contacts.length).fill(null);
    /**
     * 在消息发送后处理发送结果
     * @param err 发送报错
     * @param data 回调实例数据。返回短信发送结果、存储已发送短信的URI和是否为长短信的最后一部分。
     * @param index 紧急联系人列表的索引值，表示给第几个紧急联系人发送求助信息
     */
    const sendCallback = (err: BusinessError, data: sms.ISendShortMessageCallback, index: number) => {
      const isSentSuccessInThisRound = sendResults.some(v => (v === true));
      sendResults[index] = this.sendSmsCallBack(err, data);
      if (sendResults[index] === true) {
        this.mUiContext?.getPromptAction().showToast({
          message: $r('app.string.sendSmsSuccess'),
          duration: 3000
        });
      }
      //第一次发送求助信息且给最后一个紧急联系人发送结束后回调开始自动拨打求助电话流程
      if (afterFirstSmsMessageSend && index === (this.sendFormatNumbers.length - 1) &&
        this.timesOfAutoSendSosMessage === 0) {
        if (this.sosMessageCallbackTimeoutIdOnTianTong) {
          clearTimeout(this.sosMessageCallbackTimeoutIdOnTianTong);
          this.sosMessageCallbackTimeoutIdOnTianTong = null;
        }
        afterFirstSmsMessageSend();
      }
      //一批给最多三个紧急联系人发送求助信息，只有一条发送成功，发送成功成功次数就加1
      if (!isSentSuccessInThisRound && sendResults[index] === true) {
        this.timesOfAutoSendSosMessage++;
      }
    }

    let countryIso: string = SosEmergencySmsController.getCountryIsoBySlotId(slotId);
    this.sendFormatNumbers.forEach((number: string, index: number) => {
      SosEmergencySmsController.getMessage(originContent, number, context, countryIso)
        .then((message: string) => {
          sms.sendShortMessage({
            slotId: slotId,
            destinationHost: number,
            content: message,
            sendCallback: (err: BusinessError, data: sms.ISendShortMessageCallback) => {
              sendCallback(err, data, index);
            }
          });
        });
    })

    if (afterFirstSmsMessageSend) { //超时两分钟开始自动拨打求助电话流程
      this.sosMessageCallbackTimeoutIdOnTianTong = setTimeout(() => {
        this.sosMessageCallbackTimeoutIdOnTianTong = null;
        afterFirstSmsMessageSend();
      }, 2 * 60 * 1000);
    }
  }
  /**
   * 取消天通下自动发送求助信息的短时循环定时器
   */
  private cancelShortTimeAlarmOnTianTongNet = () => {
    try {
      if (this.shortTimeAlarmTimerIdOfTianTong) {
        LogUtils.i(TAG, 'cancelShortTimeAlarmOnTianTongNet: timer clear');
        clearTimeout(this.shortTimeAlarmTimerIdOfTianTong);
        this.shortTimeAlarmTimerIdOfTianTong = null;
      }
    } catch (e) {
      LogUtils.e(TAG, `cancelShortTimeAlarmOnTianTongNet: timer clear failed, error: ${e?.code} ${e?.message}`);
    }
  }
  /**
   * 天通卫星网络下的5分钟的短时循环定时器, 第一次发送求助信息成功且设备位置变更时发送一轮求助短信
   */
  private startShortTimeAlarmOnTianTongNet = () => {
    this.cancelShortTimeAlarmOnTianTongNet();
    LogUtils.i(TAG, 'startShortTimeAlarmOnTianTongNet');
    this.shortTimeAlarmTimerIdOfTianTong = setTimeout(async () => {
      LogUtils.i(TAG, 'startShortTimeAlarmOnTianTongNet: short time timer trigger');
      if (this.firstSendSuccess && this.isLocationChangeOnTianTongNet) {
        this.isLocationChangeOnTianTongNet = false;
        this.sendSmsOnTianTongNet(this.mContext);
      }
      this.startShortTimeAlarmOnTianTongNet();
    }, 5 * 60 * 1000);
  }
  /**
   * 取消天通下自动发送求助信息的长时循环定时器
   */
  private cancelLongTimeAlarmOnTianTongNet = () => {
    try {
      if (this.longTimeAlarmTimerIdOfTianTongNet) {
        LogUtils.i(TAG, 'cancelLongTimeAlarmOnTianTongNet: timer clear');
        clearTimeout(this.longTimeAlarmTimerIdOfTianTongNet);
        this.longTimeAlarmTimerIdOfTianTongNet = null;
      }
    } catch (e) {
      LogUtils.e(TAG, `cancelLongTimeAlarmOnTianTongNet: timer clear failed, error: ${e?.code} ${e?.message}`);
    }
  }
  /**
   * 天通卫星网络下的30分钟的长时循环定时器, 在第一次发送求助信息成功后每隔30分钟固定发送一轮求助短信
   */
  private startLongTimeAlarmOnTianTongNet = () => {
    this.cancelLongTimeAlarmOnTianTongNet();
    LogUtils.i(TAG, 'startLongTimeAlarmOnTianTongNet');
    this.longTimeAlarmTimerIdOfTianTongNet = setTimeout(async () => {
      LogUtils.i(TAG, 'startLongTimeAlarmOnTianTongNet: timer trigger');
      if (this.firstSendSuccess) {
        this.sendSmsOnTianTongNet(this.mContext);
      }
      this.startLongTimeAlarmOnTianTongNet();
    }, 30 * 60 * 1000);
  }
  /** 取消天通下自动发送求助信息的'首次发送'循环定时器 */
  private cancelFirstSendAlarmOnTianTongNet = () => {
    try {
      if (this.firstSendAlarmTimerIdOnTianTongNet) {
        LogUtils.i(TAG, 'cancelFirstSendAlarmOnTianTongNet: timer clear');
        clearTimeout(this.firstSendAlarmTimerIdOnTianTongNet);
        this.firstSendAlarmTimerIdOnTianTongNet = null;
      }
    } catch (e) {
      LogUtils.e(TAG, `cancelFirstSendAlarmOnTianTongNet: timer clear failed, error: ${e?.code} ${e?.message}`);
    }
  }
  /**
   * 将数字的经纬度转成度分秒的形式
   */
  private getConvertDegreeString = (digitalDegree: number): string => {
    const DOUBLE: number = 60;
    let degree: number = Math.trunc(digitalDegree);
    let tmp: number = (digitalDegree - degree) * DOUBLE;
    let minute: number = Math.trunc(tmp);
    let second: number = Math.trunc((tmp - minute) * DOUBLE);
    return Math.abs(degree) + DEGREE + Math.abs(minute) + MINUTE + Math.abs(second) + SECOND;
  }
  /**
   * 获取当前系统语言的经纬度描述
   * @param context Context | null
   * @param convertLongitude 数字格式的待转换的经度
   * @param convertLatitude 数字格式的待转换的纬度
   * @returns 当前系统语言的经纬度描述
   */
  private getLocationInfo = (context: Context | null, convertLongitude: number, convertLatitude: number): string => {
    if (!context) {
      LogUtils.e(TAG, 'getLocationInfo: context empty');
      return '';
    }
    if (convertLatitude >= 0) {
      if (convertLongitude >= 0) {
        return context.resourceManager.getStringSync($r('app.string.location_north_east'),
          this.getConvertDegreeString(convertLatitude),
          this.getConvertDegreeString(convertLongitude));
      } else {
        return context.resourceManager.getStringSync($r('app.string.location_north_west'),
          this.getConvertDegreeString(convertLatitude),
          this.getConvertDegreeString(convertLongitude));
      }
    } else {
      if (convertLongitude >= 0) {
        return context.resourceManager.getStringSync($r('app.string.location_south_east'),
          this.getConvertDegreeString(convertLatitude),
          this.getConvertDegreeString(convertLongitude));
      } else {
        return context.resourceManager.getStringSync($r('app.string.location_south_west'),
          this.getConvertDegreeString(convertLatitude),
          this.getConvertDegreeString(convertLongitude));
      }
    }
  }
  /**
   * 天通卫星网络下的30s定时器
   * 回调里判断是否第一次发送求助短信成功。是则取消定时器, 否则调用自动发送求助信息流程
   */
  private startFirstSendAlarmOnTianTongNet = () => {
    this.cancelFirstSendAlarmOnTianTongNet();
    this.firstSendAlarmTimerIdOnTianTongNet = setTimeout(async () => {
      LogUtils.i(TAG, 'startFirstSendAlarmOnTianTongNet: timer trigger');
      if (!this.firstSendSuccess) {
        this.sendSmsOnTianTongNet(this.mContext);
        this.startFirstSendAlarmOnTianTongNet();
      } else {
        this.cancelFirstSendAlarmOnTianTongNet();
      }
    }, 30 * 1000);
  }
  /**
   * 在天通网络下开始自动发送求助信息流程
   * @param context Context
   * @param uiContext UIContext
   * @param afterFirstSmsMessageSend 用于在第一次发送自动求助消息后回调开始自动拨打求助电话流程
   */
  public startAutoSendSosMessageOnTianTongNet = async (context: Context, uiContext: UIContext,
    afterFirstSmsMessageSend: () => void) => {
    this.mContext = context;
    this.mUiContext = uiContext;
    let mapPermissionsToGrantStatus = await PermissionsUtils.checkPermissionOfSOSAutoSendSMS();
    if (!mapPermissionsToGrantStatus || mapPermissionsToGrantStatus.get('ohos.permission.SEND_MESSAGES') !==
    abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      LogUtils.e(TAG, 'startAutoSendSosMessageOnTianTongNet: auto send SosMessage failed, permission denied');
      this.mUiContext?.getPromptAction().showToast({
        message: this.getStringByResource($r('app.string.Permission_denied_to_send_sms')),
        duration: 3000
      });
      afterFirstSmsMessageSend();
      return;
    }
    const isHasLocationPermission = this.getIsHasLocationPermission(mapPermissionsToGrantStatus);
    LogUtils.i(TAG, `startAutoSendSosMessageOnTianTongNet: isHasLocationPermission ${isHasLocationPermission}`);
    if (isHasLocationPermission) {
      if (!LocationUtils.getInstance().getLocationEnable()) {
        AppStorage.setOrCreate<boolean>(SosEmergencySmsController.IGNORE_LOCATION_SWITCH_KEY, true);
        LocationUtils.getInstance().setLocationSwitchIgnored(true);
      }
    }
    const contacts = AppStorage.get<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY);
    if (!contacts || contacts.length === 0) {
      LogUtils.w(TAG, 'startAutoSendSosMessageOnTianTongNet: no contacts');
      return;
    }
    // 在非车祸或跌倒场景即主动拉起SOS求助界面场景下, 当前界面处于后台时不执行功能
    const isCheckPass = SosEmergencyCallController.checkSosEmergencyCallAbilityState(uiContext);
    if (!isCheckPass) {
      LogUtils.w(TAG, 'startAutoSendSosMessageOnTianTongNet: current page on background, return');
      return;
    }

    AppStorage.setOrCreate(IS_RUNNING_OF_AUTO_SEND_SOS_MSG, true);
    this.sendFormatNumbers = contacts.map(contact => {
      return TelephoneUtil.formatDisplayPhoneNum(contact.value);
    });

    this.currentLocationOfTianTong = await this.getCurrentLocationData(context);
    if (this.currentLocationOfTianTong) {
      this.tianTongLocationString = this.getLocationInfo(context, this.currentLocationOfTianTong.longitude,
        this.currentLocationOfTianTong.latitude);
    }

    this.sendSmsOnTianTongNet(context, afterFirstSmsMessageSend);
    //分别设置一个5分钟的短时循环定时器和 卫星网络下30分钟的长时循环定时器
    this.startShortTimeAlarmOnTianTongNet();
    this.startLongTimeAlarmOnTianTongNet();
    //设置30s的定时器，回调里判断 是否第一次发送求助短信成功，是则取消定时器，否则进行发送短信流程
    this.startFirstSendAlarmOnTianTongNet();
    this.startTwoMinutesTimer();
    this.setLocationListener();
  }
  /**
   * 从callSetting获取当前位置数据
   */
  private getCurrentLocationData = async (context: Context | null) => {
    if (!context) {
      LogUtils.e(TAG, 'getCurrentLocationData: context empty');
      return null;
    }
    let locationString: string | null = await querySatelliteLocationData(context);
    if (!locationString) {
      LogUtils.e(TAG, 'getCurrentLocationData: locationString empty');
      return null;
    }
    const tempArray = locationString.split('_');
    if (!tempArray || tempArray.length !== 2) {
      LogUtils.e(TAG, 'getCurrentLocationData: tempArray abnormal');
      return null;
    }
    let newLocationData: LocationData = {
      latitude: Number(formatLocationDataOfTianTong(tempArray[1])),
      longitude: Number(formatLocationDataOfTianTong(tempArray[0]))
    };
    return newLocationData;
  }

  /**
   * 获取当前应用是否有精确位置权限和模糊位置权限
   * @param mapPermissionsToGrantStatus 当前应用权限状态，key权限名，value为授权状态
   * @returns boolean
   */
  private getIsHasLocationPermission(mapPermissionsToGrantStatus: HashMap<Permissions, abilityAccessCtrl.GrantStatus>) {
    return mapPermissionsToGrantStatus &&
      (mapPermissionsToGrantStatus.get('ohos.permission.APPROXIMATELY_LOCATION') ===
      abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) &&
      (mapPermissionsToGrantStatus.get('ohos.permission.LOCATION') ===
      abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
  }

  /**
   * 获取指定卡槽SIM卡的ISO国家码
   * @param slotId 卡槽ID
   * @returns 返回获取指定卡槽SIM卡的ISO国家码，例如：CN（中国）
   */
  private static getCountryIsoBySlotId(slotId: number) {
    let countryIso: string = '';
    try {
      countryIso = sim.getISOCountryCodeForSimSync(slotId);
    } catch (e) {
      LogUtils.e(TAG, `getCountryIsoBySlotId error: ${e?.code} ${e?.message}`);
    }
    return countryIso;
  }

  /**
   * 获取天通求助短信内容
   * @param context Context
   * @returns string
   */
  private getTianTongShortMessageContent(context: Context) {
    let content = '';
    try {
      content = LEFT_BRACKETS + context.resourceManager.getStringSync($r('app.string.satellite').id) + RIGHT_BRACKETS;
      content += SPLIT + context.resourceManager.getStringSync($r('app.string.Emergency_message_without_location').id);
    } catch (e) {
      LogUtils.e(TAG, `getTianTongShortMessageContent error: ${e?.code} ${e?.message}`);
    }

    try {
      if (this.currentLocationOfTianTong) {
          //转换坐标系 WGS84 -> GCJ02 暂不支持
  /*      let locationData: mapCommon.LatLng = map.convertCoordinateSync(mapCommon.CoordinateType.WGS84,
          mapCommon.CoordinateType.GCJ02, this.currentLocationOfTianTong);
*/
        if (this.tianTongLocationString) {
          content += SPLIT + context.resourceManager.getStringSync($r('app.string.position'),
            this.tianTongLocationString);
        }

        content += SPLIT + context.resourceManager.getStringSync($r('app.string.address_details'),
          context.resourceManager.getStringSync($r('app.string.map_url')))
            //+ locationData.longitude + ',' + locationData.latitude);
      }
    } catch (e) {
      LogUtils.e(TAG, `getTianTongShortMessageContent location error: ${e?.code} ${e?.message}`);
    }
    return content;
  }

  /**
   * 在蜂窝网络下开始自动发送求助信息流程
   * @param sosType 自动发送求助信息的场景 'sos' 主动拉起SOS求助界面 | 'carAccident' 车祸 | 'fallDown' 跌倒
   * @param uiContext UIContext
   */
  public async startAutoSendSosMessage(sosType: 'sos' | 'carAccident' | 'fallDown', uiContext: UIContext) {
    LogUtils.i(TAG, `start auto send SosMessage to ${sosType}`);
    this.mUiContext = uiContext;
    if (sosType !== SOS && sosType !== CAR_ACCIDENT && sosType !== FALL_DOWN) {
      return;
    }

    let mapPermissionsToGrantStatus: HashMap<Permissions, abilityAccessCtrl.GrantStatus> = null!
    if (sosType === SOS) {
      mapPermissionsToGrantStatus = await PermissionsUtils.checkPermissionOfSOSAutoSendSMS();
    } else if (sosType === CAR_ACCIDENT || sosType === FALL_DOWN) {
      mapPermissionsToGrantStatus = await PermissionsUtils.checkPermissionOfPersonalSafetyAutoCallAndSendSMS();
    }
    if (!mapPermissionsToGrantStatus || mapPermissionsToGrantStatus.get('ohos.permission.SEND_MESSAGES') !==
    abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      LogUtils.e(TAG, 'auto send SosMessage failed, permission denied');
      this.mUiContext?.getPromptAction().showToast({
        message: this.getStringByResource($r('app.string.Permission_denied_to_send_sms')),
        duration: 3000
      });
      return;
    }

    // 在非车祸或跌倒场景即主动拉起SOS求助界面场景下, 当前界面处于后台时不执行功能
    const isCheckPass = SosEmergencyCallController.checkSosEmergencyCallAbilityState(uiContext);
    if (!isCheckPass) {
      LogUtils.w(TAG, 'startAutoSendSosMessage: current page on background, return');
      return;
    }

    AppStorage.setOrCreate(IS_RUNNING_OF_AUTO_SEND_SOS_MSG, true);
    const isHasLocationPermission = mapPermissionsToGrantStatus &&
      (mapPermissionsToGrantStatus.get('ohos.permission.APPROXIMATELY_LOCATION') ===
      abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) &&
      (mapPermissionsToGrantStatus.get('ohos.permission.LOCATION') ===
      abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);

    if (isHasLocationPermission) {
      if (!LocationUtils.getInstance().getLocationEnable()) {
        AppStorage.setOrCreate<boolean>(SosEmergencySmsController.IGNORE_LOCATION_SWITCH_KEY, true);
        LocationUtils.getInstance().setLocationSwitchIgnored(true);
      }
    }

    //Sending an SMS message for the first time
    if (sosType === CAR_ACCIDENT || sosType === FALL_DOWN) {
      await this.sendSms(sosType);
    } else {
      await this.sendSms(SOS);

      this.startTwoMinutesAlarm();
      this.startTenMinutesAlarm();
      this.startFifteenSecAlarm();
    }
    this.startTwoMinutesTimer();
    this.setLocationListener();
  }

  /**
   * 在蜂窝网络下发送求助信息
   * @param sosType 自动发送求助信息的场景 'sos' 主动拉起SOS求助界面 | 'carAccident' 车祸 | 'fallDown' 跌倒
   */
  public async sendSms(sosType: 'sos' | 'carAccident' | 'fallDown') {
    LogUtils.i(TAG, `start to send sms, already sent successfully for ${this.timesOfAutoSendSosMessage} times`);
    if (!SosEmergencyCallController.getInstance().isDisplayCallUi) { //若不因拉起通话界面而退到后台
      // 在非车祸或跌倒场景即主动拉起SOS求助界面场景下, 当前界面处于后台时不执行功能
      const isCheckPass = SosEmergencyCallController.checkSosEmergencyCallAbilityState(this.mUiContext);
      if (!isCheckPass) {
        LogUtils.w(TAG, 'sendSms: current page on background, return');
        this.stopAutoSendSosMessage();
        return;
      }
    }

    if (sosType === SOS && this.timesOfAutoSendSosMessage > SosEmergencySmsController.MESSAGE_NUMBERS_LIMIT) {
      LogUtils.w(TAG, `The number of times that the SOS SMS message is sent exceeds ${
      SosEmergencySmsController.MESSAGE_NUMBERS_LIMIT}.`);
      this.stopAutoSendSosMessage();
      return;
    }

    let slotId = await SosEmergencyCallController.getNormalWorkSimCard();
    if (slotId === null) {
      LogUtils.e(TAG, 'slotId is null');
      return;
    }

    const contacts = AppStorage.get<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY);
    if (!contacts || contacts.length === 0) {
      return;
    }

    LogUtils.i(TAG, 'start to get current location');
    let request: geoLocationManager.SingleLocationRequest =
      {
        'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_ACCURACY,
        'locatingTimeoutMs': 5000
      };
    let message: string = '';
    if (sosType === SOS) {
      message = this.getStringByResource($r('app.string.Emergency_message_without_location'));
    } else if (sosType === CAR_ACCIDENT) {
      message = this.getStringByResource($r('app.string.car_accident_sos_message_without_location'));
    } else if (sosType === FALL_DOWN) {
      message = this.getStringByResource($r('app.string.fall_down_message_without_location'));
    }
    try {
      LocationUtils.getInstance().setLocationSwitchIgnored(true);
      const currentLocation = await geoLocationManager.getCurrentLocation(request);
      const address:AdaptedReverseGeocodeResult|null = await this.getAddressFromLocation(currentLocation);
      if (sosType === SOS) {
        if (address) {
          const addressStr: string = `${address.formatAddress}${this.getLngLatLocationStr(currentLocation)}`;
          const msgResource: Resource = $r('app.string.Emergency_message', addressStr);
          message = this.getStringByResource(msgResource);
        }
      } else {
        if (currentLocation) {
          let addressStr: string = ''
          if (address) {
            addressStr = `${address.formatAddress}${this.getLngLatLocationStr(currentLocation)}`;
          } else {
            addressStr = `${this.getLngLatLocationStr(currentLocation)}`;
          }
          let msgResource: Resource = null!
          if (sosType === CAR_ACCIDENT) {
            msgResource = $r('app.string.car_accident_sos_message', addressStr);
          } else if (sosType === FALL_DOWN) {
            msgResource = $r('app.string.fall_down_message', addressStr);
          }
          message = this.getStringByResource(msgResource);
        }
      }
    } catch (e) {
      LogUtils.e(TAG, `get current location failed: ${JSON.stringify(e)}`);
      if (sosType === SOS) {
        ReportUtil.getInstance().reportSosMmsSuccessOrFail(AutoSendSosMessageResult.FAIL_TO_GET_LOCATION);
        ReportUtil.getInstance().reportSosCallSuccessOrFail(AutoDialCallResult.FAIL_TO_GET_LOCATION);
      } else if (sosType === CAR_ACCIDENT) {
        ReportUtil.getInstance().reportCrashSMSResult('LocationGet', AutoSendSosMessageResult.FAIL_TO_GET_LOCATION);
      } else if (sosType === FALL_DOWN) {
        ReportUtil.getInstance().reportFallSMSResult('LocationGet', AutoSendSosMessageResult.FAIL_TO_GET_LOCATION);
      }
    }

    let sendResults: (boolean | null)[] = new Array(contacts.length).fill(null);
    contacts.forEach((contact: ContactListStruct, index: number) => {
      sms.sendShortMessage({
        slotId: slotId,
        destinationHost: TelephoneUtil.formatDisplayPhoneNum(contact.value),
        content: message,
        sendCallback: (err: BusinessError, data: sms.ISendShortMessageCallback) => {
          const isSentSuccessInThisRound = sendResults.some(v => (v === true));
          sendResults[index] = this.sendSmsCallBack(err, data);
          if (sendResults[index] === true) {
            this.mUiContext?.getPromptAction().showToast({
              message: $r('app.string.sendSmsSuccess'),
              duration: 3000
            });
            if (sosType === SOS) {
              ReportUtil.getInstance().reportSosMmsSuccessOrFail(AutoSendSosMessageResult.SUCCESS);
            } else if (sosType === CAR_ACCIDENT) {
              ReportUtil.getInstance().reportCrashSMSResult('Contact_' + index, AutoSendSosMessageResult.SUCCESS);
            } else if (sosType === FALL_DOWN) {
              ReportUtil.getInstance().reportFallSMSResult('Contact_' + index, AutoSendSosMessageResult.SUCCESS);
            }
          }
          if (!isSentSuccessInThisRound && sendResults[index] === true) {
            this.timesOfAutoSendSosMessage++;
          }
        }
      });
    })
    LogUtils.i(TAG, `send sms to ${contacts.length} contacts`);
  }

  private getLngLatLocationStr(location: geoLocationManager.Location): string {
    let convertLoc: Resource;
    const latitude: number = location.latitude;
    const longitude: number = location.longitude;
    const latitudeStr: string = location.latitude.toFixed(COORDINATE_PRECISION).toString();
    const longitudeStr: string = location.longitude.toFixed(COORDINATE_PRECISION).toLocaleString();
    if (latitude >= 0 && longitude >= 0) {
      convertLoc = $r('app.string.EarthquakeLocationLatitudeNorth', longitudeStr, latitudeStr);
    } else if (latitude >= 0 && longitude < 0) {
      convertLoc = $r('app.string.EarthquakeLocationLongitudeWest', longitudeStr, latitudeStr);
    } else if (latitude < 0 && longitude >= 0) {
      convertLoc = $r('app.string.EarthquakeLocationLongitudeEast', longitudeStr, latitudeStr);
    } else {
      convertLoc = $r('app.string.EarthquakeLocationLatitudeSouth', longitudeStr, latitudeStr);
    }
    return this.getStringByResource(convertLoc);
  }

  /**
   * 处理求助信息的发送结果
   */
  private sendSmsCallBack = (err: BusinessError, data: sms.ISendShortMessageCallback,
    communicationNetworkType?: CommunicationNetworkType): boolean => {
    if (data.result === sms.SendSmsResult.SEND_SMS_SUCCESS) {
      if (!this.firstSendSuccess) {
        if (communicationNetworkType === CommunicationNetworkType.TIAN_TONG) {
          this.cancelFirstSendAlarmOnTianTongNet();
        } else {
          this.cancelFifteenSecAlarm();
        }
      }
      this.firstSendSuccess = true;
      LogUtils.i(TAG, `send sms success`);
      return true;
    }
    LogUtils.e(TAG, `send sms faild, result: ${data.result}`);
    return false;
  }

  private cancelTwoMinutesAlarm() {
    if (this.twoMinutesAlarmTimeoutId) {
      LogUtils.i(TAG, 'two min timer clear');
      clearTimeout(this.twoMinutesAlarmTimeoutId);
      this.twoMinutesAlarmTimeoutId = null;
    }
  }

  private startTwoMinutesAlarm = () => {
    this.cancelTwoMinutesAlarm();
    LogUtils.i(TAG, 'two min timer start');
    this.twoMinutesAlarmTimeoutId = setTimeout(async () => {
      LogUtils.i(TAG, 'two min timer trigger');
      if (this.firstSendSuccess && this.allowTwoMinTimerSendSms) {
        await this.sendSms(SOS);
        this.allowTwoMinTimerSendSms = false;
      }
      this.startTwoMinutesAlarm();
    }, 2 * 60 * 1000);
  }

  private cancelTwoMinutesTimer() {
    if (this.twoMinutesTimesTimeoutId) {
      LogUtils.i(TAG, 'two minutes timer clear');
      clearTimeout(this.twoMinutesTimesTimeoutId);
      this.twoMinutesTimesTimeoutId = null;
    }
  }

  private startTwoMinutesTimer = () => {
    this.cancelTwoMinutesTimer();
    LogUtils.i(TAG, 'two minutes timer start');
    // 每两分钟续订一下开关，保证位置监听可以生效，设置一次两分钟有效
    LocationUtils.getInstance().setLocationSwitchIgnored(true);
    this.twoMinutesTimesTimeoutId = setTimeout(async () => {
      LogUtils.i(TAG, 'two minutes timer trigger');
      this.startTwoMinutesTimer();
    }, 2 * 60 * 1000);
  }

  private cancelTenMinutesAlarm = () => {
    if (this.tenMinutesAlarmTimeoutId) {
      LogUtils.i(TAG, 'ten min timer clear');
      clearTimeout(this.tenMinutesAlarmTimeoutId);
      this.tenMinutesAlarmTimeoutId = null;
    }
  }
  private startTenMinutesAlarm = () => {
    this.cancelTenMinutesAlarm();
    LogUtils.i(TAG, 'ten min timer start');
    this.tenMinutesAlarmTimeoutId = setTimeout(async () => {
      LogUtils.i(TAG, 'ten min timer trigger');
      if (this.firstSendSuccess) {
        await this.sendSms(SOS);
      }
      this.startTenMinutesAlarm();
    }, 10 * 60 * 1000);
  }
  private startFifteenSecAlarm = () => {
    this.cancelFifteenSecAlarm();
    LogUtils.i(TAG, 'fifteen sec timer start');
    this.fifteenSecondsAlarmTimeoutId = setTimeout(async () => {
      LogUtils.i(TAG, 'fifteen sec timer trigger');
      if (!this.firstSendSuccess) {
        await this.sendSms(SOS);
        this.startFifteenSecAlarm();
      } else {
        this.cancelFifteenSecAlarm();
      }
    }, 15 * 1000);
  }
  private cancelFifteenSecAlarm = () => {
    if (this.fifteenSecondsAlarmTimeoutId) {
      LogUtils.i(TAG, 'fifteen sec timer clear');
      clearTimeout(this.fifteenSecondsAlarmTimeoutId);
      this.fifteenSecondsAlarmTimeoutId = null;
    }
  }
  /**
   * 监听位置变更的回调函数
   */
  private onLocationChange = (location: geoLocationManager.Location) => {
    LogUtils.i(TAG, `onLocationChange: displacement detected over ${DISTANCE_LIMIT} m`);
    if (SystemModeController.getInstance().getIsEnableSosOnSatelliteNet()) {
      const networkType = AppStorage.get<CommunicationNetworkType>(COMMUNICATION_NETWORK_TYPE);
      if (networkType === CommunicationNetworkType.TIAN_TONG) {
        this.handleLocationChangeOnTianTongNet(this.mContext, location);
      } else {
        this.handleLocationChangeOnCellarNet(location);
      }
    } else {
      this.handleLocationChangeOnCellarNet(location);
    }
  }
  /**
   * 蜂窝网络下发送求助信息时设置设备位置变更监听
   * 初始化设置时就会回调一次
   */
  private setLocationListener = () => {
    if (!AppStorage.get<boolean>(SosEmergencySmsController.IGNORE_LOCATION_SWITCH_KEY)) {
      return;
    }
    // Callback triggered when the specified distance is exceeded
    let request: geoLocationManager.LocationRequest =
      {
        'priority': geoLocationManager.LocationRequestPriority.ACCURACY,
        'scenario': geoLocationManager.LocationRequestScenario.UNSET,
        'timeInterval': 0,
        'distanceInterval': DISTANCE_LIMIT
      };
    LogUtils.i(TAG, 'subscribe location change');
    try {
      geoLocationManager.on('locationChange', request, this.onLocationChange)
    } catch (e) {
      LogUtils.e(TAG, 'subscribe location change error: ' + JSON.stringify(e));
    }
  }
  /**
   * 取消蜂窝网络下的设备位置变更监听
   */
  private removeLocationListener = () => {
    try {
      geoLocationManager.off('locationChange', this.onLocationChange);
      LogUtils.i(TAG, `unsubscibe location change`);
    } catch (e) {
      LogUtils.e(TAG, `removeLocationListener error: ${e?.code} ${e?.message}`);
    }
  }
  private getAddressFromLocation = async (location: geoLocationManager.Location) => {
    // let data: site.ReverseGeocodeResult | undefined = await LocationUtils.getInstance()
    //   .reverseGeocode(i18n.System.getSystemLocale(), location.latitude, location.longitude);
    let data: AdaptedReverseGeocodeResult | undefined = await LocationUtils.getInstance()
      .reverseGeocode(i18n.System.getSystemLocale(), location.latitude, location.longitude);
    if (data != undefined) {
      return data;
    }
    LogUtils.i(TAG, `get address error, addresses is empty`);
    return null;
  }

  /**
   * 处理天通卫星通信网络下位置变更事件
   * @param context
   * @param location
   */
  private async handleLocationChangeOnTianTongNet(context: Context | null,
    location: geoLocationManager.Location) {
    LogUtils.i(TAG, `handleLocationChangeOnTianTongNet`);
    if (this.lastLocation !== null) { // 初始化设置位置监听时会立刻回调一次，此时位置没有变更，过滤此时的回调
      this.isLocationChangeOnTianTongNet = true;
    }
    this.lastLocation = location;
    let newLocationData: LocationData = {
      latitude: Number(formatLocationDataOfTianTong(String(location.latitude))),
      longitude: Number(formatLocationDataOfTianTong(String(location.longitude)))
    };
    this.currentLocationOfTianTong = newLocationData;
    this.tianTongLocationString = this.getLocationInfo(context, this.currentLocationOfTianTong.longitude,
      this.currentLocationOfTianTong.latitude);
  }

  /**
   * 处理蜂窝通信网络下位置变更事件
   * @param context
   * @param location
   */
  private handleLocationChangeOnCellarNet(location: geoLocationManager.Location) {
    LogUtils.i(TAG, `handleLocationChangeOnCellarNet`);
    if (this.lastLocation !== null) { // 初始化设置位置监听时会立刻回调一次，此时位置没有变更，过滤此时的回调
      this.allowTwoMinTimerSendSms = true;
    }
    this.lastLocation = location;
  }

  private getStringByResource(resource: Resource): string {
    try {
      return getContext(this).resourceManager.getStringSync(resource.id, ...resource.params ?? []);
    } catch (e) {
      LogUtils.e(TAG, `getStringByResource error: ${JSON.stringify(e)}`);
      return '';
    }
  }

  /**
   * Stop auto send sos messages and clear all statuses.
   */
  public stopAutoSendSosMessage(): void {
    LogUtils.i(TAG, 'stopAutoSendSosMessage');
    this.timesOfAutoSendSosMessage = 0;
    this.firstSendSuccess = false;
    AppStorage.setOrCreate(IS_RUNNING_OF_AUTO_SEND_SOS_MSG, false);
    if (SystemModeController.getInstance().getIsEnableSosOnSatelliteNet()) {
      const networkType = AppStorage.get<CommunicationNetworkType>(COMMUNICATION_NETWORK_TYPE);
      switch (networkType) {
        case CommunicationNetworkType.CELLULAR:
          this.abortAutoSendSosMessageOnCellarNet();
          break;
        case CommunicationNetworkType.TIAN_TONG:
          this.abortAutoSendSosMessageOnTianTongNet();
          break;
      }
    } else {
      this.abortAutoSendSosMessageOnCellarNet();
    }
  }

  /**
   * 中止天通卫星下自动发送求助信息流程
   */
  private abortAutoSendSosMessageOnTianTongNet = () => {
    this.cancelShortTimeAlarmOnTianTongNet();
    this.cancelLongTimeAlarmOnTianTongNet();
    this.cancelFirstSendAlarmOnTianTongNet();
    this.cancelTwoMinutesTimer();
    this.removeLocationListener();
  }
  /**
   * 中止蜂窝通信网络下自动发送求助信息流程
   */
  private abortAutoSendSosMessageOnCellarNet = () => {
    this.cancelTwoMinutesAlarm();
    this.cancelTenMinutesAlarm();
    this.cancelFifteenSecAlarm();
    this.cancelTwoMinutesTimer();
    this.removeLocationListener();
  }
}