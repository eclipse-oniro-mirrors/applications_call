/*
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
import LogUtils from './HiLog';
import settings from '@ohos.settings';
import { common } from '@kit.AbilityKit';
import { EmergencyGlobalContextHelper } from './EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import EmergencyWarningPreferencesUtils from './EmergencyWarningPreferencesUtils';
import EmergencyWarningController from '../control/EmergencyWarningControl';
import { PrivacyStatement } from './ClassStruct';
import CommonData from '../data/CommonData';
import bundleManager from '@ohos.bundle.bundleManager';
import configPolicy from '@ohos.configPolicy'
import fileIo from '@ohos.file.fs';
import xml from '@ohos.xml';
import util from '@ohos.util';
import { i18n } from '@kit.LocalizationKit';
import { window } from '@kit.ArkUI';
import { BusinessError, osAccount, systemParameterEnhance } from '@kit.BasicServicesKit';
import { CAR_ACCIDENT, FALL_DOWN } from '../utils/Constants'
import { PersonalSafetyAccidentType } from '../utils/ClassStruct'
import LocationUtils from './LocationUtils';

type WindowSystemBarNames = 'status' | 'navigation';

const TAG = 'Utils';
const EMERGENCY_POST_LOCATION_SWITCH = 'emergency_post_location_switch';
const EMERGENCY_POST_LOCATION_SWITCH_ON = '1';
const EMERGENCY_POST_LOCATION_SWITCH_OFF = '0';

export function stringToUint8Array(str: string) {
  let arr: number[] = [];
  for (let i = 0, j = str.length; i < j; ++i) {
    arr.push(str.charCodeAt(i));
  }
  let tmpUint8Array = new Uint8Array(arr);
  return tmpUint8Array;
}

/**
 * Get a random integer between -Math.pow (2, 31) and Math.pow (2, 31) - 1, including the maximum and minimum values
 * @returns
 */
export function getRandomIntInRange() {
  const min = -Math.pow(2, 31);
  const max = Math.pow(2, 31) - 1;
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Get a random integer between two integers, including the two integers
 * @param minInt
 * @param maxInt
 * @returns
 */
export function getRandomIntInclusive(minInt: number, maxInt: number) {
  const min = Math.ceil(minInt);
  const max = Math.floor(maxInt);
  return Math.floor(Math.random() * (max - min + 1) + min);
}

/**
 * Decimal to hexadecimal
 * @param {*} val  decimal integer
 * @param {*} byteNum  How many bytes of hexadecimal,1 byte = 2 hexadecimal characters
 */
export function parseHex(val: number, byteNum: number): string {
  let num = BigInt(Number.parseInt(String(val)));
  let hexStr = '';
  let hexStrLength = byteNum * 2;
  let min = BigInt(-1 * Math.pow(2, 8 * byteNum - 1));
  let max = BigInt(Math.pow(2, 8 * byteNum - 1) - 1);
  if (num < min || num > max) {
    LogUtils.w(TAG, `out of range,min is ${min},max is ${max},but val is ${num}.`);
    return '';
  } else if (num < 0) { //legal negative number
    //two's complement
    hexStr = (BigInt(Math.pow(2, 8 * byteNum)) + num).toString(16);
    if (hexStr.length < hexStrLength) {
      hexStr = 'f'.repeat(hexStrLength - hexStr.length) + hexStr;
    }
  } else { //legal positive number
    hexStr = num.toString(16);
    if (hexStr.length < hexStrLength) {
      hexStr = '0'.repeat(hexStrLength - hexStr.length) + hexStr;
    }
  }
  return hexStr;
}

export enum EarthquakeWarningSwitchOpenType {
  DoubleUpToSingle = 'DoubleUpToSingle',
  /** OOBE */
  OutOfBoxExperience = 'OutOfBoxExperience'
}

export class AmlUtils {
  public static readonly SETTINGS_SECURE_PREFIX_URI: string =
    'datashare:///com.ohos.settingsdata/entry/settingsdata/USER_SETTINGSDATA_SECURE_100?Proxy=true&key=';
  public static readonly IS_SHOW_AML_KEY: string = 'is_oversea_show_aml';
  public static readonly SWITCH_KEY: string = 'hwaml_switch';
  public static readonly SWITCH_USER_HANDLED_KEY: string = 'hwaml_switch_user_handled';
  public static readonly SWITCH_ON: string = '1';
  public static readonly SWITCH_OFF: string = '0';
  public static readonly AML_CFG_FILE: string = 'etc/aml/aml_config.json';
  public static readonly AML_CFG_DIR: string = 'etc/carrier/network';
  public static readonly MCC_LEN_INDEX:number = 3;

  public static getIsOverseaShowAml(context: Context): boolean {
    let isShow = AmlUtils.getSecSettingsSync(context, AmlUtils.IS_SHOW_AML_KEY, AmlUtils.SWITCH_OFF);
    LogUtils.i(TAG, `get isOversea show aml ${isShow}`);
    return isShow === AmlUtils.SWITCH_ON;
  }

  public static isAmlSwitchEnabled(context: Context) {
    let amlSwitchStatus = AmlUtils.getSecSettingsSync(context, AmlUtils.SWITCH_KEY, AmlUtils.SWITCH_OFF);
    LogUtils.i(TAG, `get aml switch status ${amlSwitchStatus}`);
    return amlSwitchStatus === AmlUtils.SWITCH_ON;
  }

  public static isAmlEnabled(context: Context, simMccmnc0: string, simMccmnc1: string): boolean {
    let amlUserHandledValue = AmlUtils.getSecSettingsSync(context, AmlUtils.SWITCH_USER_HANDLED_KEY, '');
    LogUtils.i(TAG, `get user handled status ${amlUserHandledValue}`);
    const amlValue = AmlUtils.getSecSettingsSync(context, AmlUtils.SWITCH_KEY, AmlUtils.SWITCH_OFF);
    const isEnabled = (amlValue === AmlUtils.SWITCH_ON);
    LogUtils.i(TAG, `get status ${amlValue} ${isEnabled}`);
    if (amlUserHandledValue === AmlUtils.SWITCH_ON) {
      return isEnabled;
    }
    return AmlUtils.isAmlDefEnabled(context, isEnabled, simMccmnc0, simMccmnc1);
  }

  static isAmlDefEnabled(context: Context, isDefEnabled: boolean, simMccmnc0: string, simMccmnc1: string): boolean {
    if (isDefEnabled) {
      return true;
    }
    let amlCfgContent: string = AmlUtils.getAmlCfgContent();
    let isAmlDefEnabledByCard = AmlUtils.isAmlTargetMcc(simMccmnc0, amlCfgContent);
    LogUtils.i(TAG, `aml def enabled0 ${isAmlDefEnabledByCard}`);
    if (!isAmlDefEnabledByCard) {
      isAmlDefEnabledByCard = AmlUtils.isAmlTargetMcc(simMccmnc1, amlCfgContent);
    }
    LogUtils.i(TAG, `aml def enabled ${isAmlDefEnabledByCard}`);
    if (isAmlDefEnabledByCard) {
      AmlUtils.setSecSettingsSync(context, AmlUtils.SWITCH_KEY, AmlUtils.SWITCH_ON);
    }
    return isAmlDefEnabledByCard;
  }

  public static setSecSettingsSync(context: Context, settingsKey: string, value: string): void {
    try {
      settings.setValueSync(context, settingsKey, value, settings.domainName.USER_SECURITY);
    } catch (e) {
      LogUtils.e(TAG, 'setSecSettingsSync error:' + JSON.stringify(e));
    }
  }

  public static getSecSettingsSync(context: Context, settingsKey: string, defValue: string): string {
    try {
      return settings.getValueSync(context, settingsKey, defValue, settings.domainName.USER_SECURITY);
    } catch (e) {
      LogUtils.e(TAG, 'getSecSettingsSync error:' + JSON.stringify(e));
      return defValue;
    }
  }

  public static isAmlTargetMcc(mccmnc: string, amlCgfContent: string): boolean {
    return amlCgfContent.indexOf(`\"mcc\":\"${mccmnc.substring(0, AmlUtils.MCC_LEN_INDEX)}\"`) > 0;
  }

  public static getAmlCfgContent(): string {
    let amlCfgContent: string = '';
    try {
      let filePath:ESObject = configPolicy.getOneCfgFileSync(AmlUtils.AML_CFG_FILE, configPolicy.FollowXMode.USER_DEFINED,
        AmlUtils.AML_CFG_DIR);
      let stat = fileIo.statSync(filePath);
      amlCfgContent = fileIo.readTextSync(filePath, { length: stat.size, encoding: 'utf-8' });
      LogUtils.i(TAG, 'getAmlCfgContent amlCfgContent size ' + amlCfgContent.length);
    } catch (err) {
      LogUtils.e(TAG, 'getAmlCfgContent failed:' + err?.code + ',' + err?.message);
    }
    return amlCfgContent;
  }
}

export class SpanNodeInfo {
  public content: string = '';
  public textStyle: string = '';
}

export class ParseXmlUtil {
  private static readonly CONTENT_DEPTH = 2;
  private spanNodeArray: SpanNodeInfo[] = [];
  private currentNode?: SpanNodeInfo;

  parseXml(src: string, spanNodeArray: SpanNodeInfo[]) {
    LogUtils.i(TAG, `parseXml len:${src.length}`);
    this.spanNodeArray = spanNodeArray;
    try {
      let arrbuffer = new util.TextEncoder().encodeInto(src);
      let that = new xml.XmlPullParser(arrbuffer.buffer.slice(0), 'UTF-8');
      that.parse({
        supportDoctype: true,
        ignoreNameSpace: true,
        attributeValueCallbackFunction: this.onAttributeValue,
        tokenValueCallbackFunction: this.onTokenValue
      });
    } catch (err) {
      LogUtils.i(TAG, `parseXml err:${err?.code} ${err?.message}`);
    }
  }

  private onAttributeValue = (name: string, value: string) => {
    if (name === 'style' && this.currentNode !== undefined) {
      this.currentNode.textStyle = value;
    }
    return true;
  }

  private onTokenValue = (eventType: xml.EventType, value: xml.ParseInfo) => {
    if (value.getDepth() !== ParseXmlUtil.CONTENT_DEPTH) {
      return true;
    }
    switch (eventType) {
      case xml.EventType.START_TAG:
        this.currentNode = new SpanNodeInfo();
        break;
      case xml.EventType.TEXT:
        if (this.currentNode) {
          this.currentNode.content = value.getText();
        }
        break;
      case xml.EventType.END_TAG:
        if (this.currentNode) {
          this.spanNodeArray.push(this.currentNode);
        }
        break;
      default:
        break;
    }
    return true;
  }
}

export class Utils {
  public static readonly IS_FIRST_REQUEST_ENABLE_NOTIFICATION = 'is_First_Request_Enable_Notification';
  public static readonly EMERGENCY_WARNING_CURRENT_CONTEXT = 'emergencyWarningCurrentLoadFilesAbilityContextName';
  /**
   * Sos sms switch.
   */
  public static readonly AUTO_SEND_SOS_SMS_SWITCH = 'auto_send_sos_sms_switch';
  public static readonly AUTO_SEND_SOS_SMS_SWITCH_ON = '1';
  public static readonly AUTO_SEND_SOS_SMS_SWITCH_OFF = '0';
  /**
   * Dial sos number switch.
   */
  public static readonly AUTO_DIAL_SOS_NUMBER_SWITCH = 'auto_dial_sos_number_switch';
  public static readonly AUTO_DIAL_SOS_NUMBER_SWITCH_ON = '1';
  public static readonly AUTO_DIAL_SOS_NUMBER_SWITCH_OFF = '0';
  public static readonly PRIVACY_STATEMENT_KEY_OF_EARTHQUAKE_WARNING = 'privacyStatementOfEarthquakeWarning';
  public static readonly PRIVACY_STATEMENT_KEY_OF_AUTO_SEND_SOS_MESSAGE = 'privacyStatementOfAutoSendSosMessage';

  /**
   * Car accident auto sos switch.
   */
  public static readonly CAR_ACCIDENT_AUTO_SOS_SWITCH = 'car_accident_auto_sos_switch';
  public static readonly CAR_ACCIDENT_AUTO_SOS_SWITCH_ON = '1';
  public static readonly CAR_ACCIDENT_AUTO_SOS_SWITCH_OFF = '0';
  public static readonly PRIVACY_STATEMENT_KEY_OF_AUTO_CAR_ACCIDENT_SEND_SOS_MESSAGE =
    'privacyStatementOfAutoCarAccidentSendSosMessage';

  /**
   * Fall down auto sos switch.
   */
  public static readonly FALL_DOWN_AUTO_SOS_SWITCH = 'fall_down_auto_sos_switch';
  public static readonly FALL_DOWN_AUTO_SOS_SWITCH_ON = '1';
  public static readonly FALL_DOWN_AUTO_SOS_SWITCH_OFF = '0';
  public static readonly PRIVACY_STATEMENT_KEY_OF_AUTO_FALL_DOWN_SEND_SOS_MESSAGE =
    'privacyStatementOfAutoFallDownSendSosMessage';

  public static getEmergencyWarningCurrentLoadFilesContext() {
    let currentLoadFilesContextName: string | undefined = AppStorage.get(Utils.EMERGENCY_WARNING_CURRENT_CONTEXT);
    if (!currentLoadFilesContextName) {
      return getContext();
    }
    let context = EmergencyGlobalContextHelper.getContext().getValue<common.Context>(currentLoadFilesContextName);
    return context || getContext();
  }

  static formatPhoneNumberInMultiLanguage(phoneNum: string): string {
    return Utils.isEmpty(phoneNum) ? phoneNum : ' \u202D(' + phoneNum + ')\u202C';
  }

  public static isSosLocationUpdateSwitchOn(context: Context): boolean {
    if (!context) {
      return false;
    }
    try {
      return settings.getValueSync(context,
        EMERGENCY_POST_LOCATION_SWITCH,
        EMERGENCY_POST_LOCATION_SWITCH_OFF
      ) === EMERGENCY_POST_LOCATION_SWITCH_ON;
    } catch (e) {
      LogUtils.e(TAG, `isSosLocationUpdateSwitchOn settings getValueSync error: ${JSON.stringify(e)}`)
      return false;
    }
  }

  public static getSettingsState(context: Context, key: string, value: string) {
    LogUtils.i(TAG, 'getSettingsState start');
    if (!context) {
      LogUtils.e(TAG, 'getSettingsState context is undefined');
      return value;
    }
    let ans = value
    try {
      ans = settings.getValueSync(context, key, value)
    } catch (e) {
      LogUtils.e(TAG, 'getSettingsState err: ' + JSON.stringify(e));
    }
    return ans
  }

  public static setSettingsState(context: Context, key: string, value: string) {
    LogUtils.i(TAG, 'setSettingsState start');
    if (!context) {
      LogUtils.e(TAG, 'setSettingsState context is undefined');
      return;
    }
    try {
      settings.setValueSync(context, key, value)
    } catch (e) {
      LogUtils.e(TAG, 'setSettingsState err: ' + JSON.stringify(e));
    }
  }

  static isEmpty(str?: string): boolean {
    return str === 'undefined' || !str || !new RegExp('[^\\s]').test(str);
  }

  static removeSpace(str: string): string {
    if (Utils.isEmpty(str)) {
      return '';
    }
    return str.replace(new RegExp('[\\s]', 'g'), '');
  }

  /**
   * Is auto send sos switch on.
   *
   * @param context  Context of the current environment
   * @return true sos switch is on.
   */
  public static isAutoSendSosSmsSwitchOn(context: Context = getContext()): boolean {
    if (!context) {
      return false;
    }
    try {
      return settings.getValueSync(context,
        Utils.AUTO_SEND_SOS_SMS_SWITCH,
        Utils.AUTO_SEND_SOS_SMS_SWITCH_OFF
      ) === Utils.AUTO_SEND_SOS_SMS_SWITCH_ON;
    } catch (e) {
      LogUtils.e(TAG, `isAutoSendSosSmsSwitchOn settings getValueSync error: ${JSON.stringify(e)}`)
      return false;
    }
  }

  /**
   * Set the auto send sos sms switch on or off.
   *
   * @param context  Context of the current environment
   * @param isSwitchOn switch on or off
   */
  public static async setAutoSendSosSmsSwitch(context: Context = getContext(), isSwitchOn: boolean) {
    if (!context) {
      return;
    }
    try {
      settings.setValueSync(context,
        Utils.AUTO_SEND_SOS_SMS_SWITCH,
        isSwitchOn ? Utils.AUTO_SEND_SOS_SMS_SWITCH_ON :
        Utils.AUTO_SEND_SOS_SMS_SWITCH_OFF
      );
    } catch (e) {
      LogUtils.e(TAG, `setAutoSendSosSmsSwitch settings setValueSync error: ${JSON.stringify(e)}`)
      return;
    }

    let appVersion: string = '';
    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      appVersion = bundleInfo.versionName;
    } catch (e) {
      LogUtils.e(TAG, `setAutoSendSosSmsSwitch: getBundleInfoForSelfSync error: ${JSON.stringify(e)}`);
    }

    const privacyStatement: PrivacyStatement = {
      isAgree: isSwitchOn,
      agreeTime: Date.now(),
      privacyVersion: CommonData.PRIVACY_STATEMENT_VERSION_OF_AUTO_SEND_SOS_MESSAGE,
      appVersion: appVersion,
      accountId: ''
    }
    EmergencyWarningPreferencesUtils.getInstance()
      .putAndFlushInPreferences(Utils.PRIVACY_STATEMENT_KEY_OF_AUTO_SEND_SOS_MESSAGE, privacyStatement);
  }

  /**
   * Is auto car accident call for help switch on.
   *
   * @param context  Context of the current environment
   * @return true if car accident sos switch is on.
   */
  public static isCarAccidentAutoCallSwitchOn(context: Context = getContext()): boolean {
    if (!context) {
      return false;
    }
    try {
      return settings.getValueSync(context, Utils.CAR_ACCIDENT_AUTO_SOS_SWITCH,
        Utils.CAR_ACCIDENT_AUTO_SOS_SWITCH_OFF) === Utils.CAR_ACCIDENT_AUTO_SOS_SWITCH_ON;
    } catch (e) {
      LogUtils.e(TAG, `isCarAccidentAutoCallSwitchOn getValueSync error: ${JSON.stringify(e)}`)
      return false;
    }
  }

  /**
   * Is auto fall down call for help switch on.
   *
   * @param context  Context of the current environment
   * @return true if fall down sos switch is on.
   */
  public static isFallDownAutoCallSwitchOn(context: Context = getContext()): boolean {
    if (!context) {
      return false;
    }
    try {
      return settings.getValueSync(context, Utils.FALL_DOWN_AUTO_SOS_SWITCH,
        Utils.FALL_DOWN_AUTO_SOS_SWITCH_OFF) === Utils.FALL_DOWN_AUTO_SOS_SWITCH_ON;
    } catch (e) {
      LogUtils.e(TAG, `isFallDownAutoCallSwitchOn getValueSync error: ${JSON.stringify(e)}`)
      return false;
    }
  }

  /**
   * Set the auto car accident call or auto fall down call switch on or off.
   *
   * @param context  Context of the current environment
   * @param isSwitchOn switch on or off
   */
  public static async setPersonalSafetyAutoCallSwitch(context: Context = getContext(), type: PersonalSafetyAccidentType,
    isSwitchOn: boolean): Promise<boolean> {
    if (!context || (type !== CAR_ACCIDENT && type !== FALL_DOWN)) {
      return false;
    }
    try {
      if (type === CAR_ACCIDENT) {
        settings.setValueSync(context, Utils.CAR_ACCIDENT_AUTO_SOS_SWITCH,
          isSwitchOn ? Utils.CAR_ACCIDENT_AUTO_SOS_SWITCH_ON : Utils.CAR_ACCIDENT_AUTO_SOS_SWITCH_OFF
        );
      } else if (type === FALL_DOWN) {
        settings.setValueSync(context, Utils.FALL_DOWN_AUTO_SOS_SWITCH,
          isSwitchOn ? Utils.FALL_DOWN_AUTO_SOS_SWITCH_ON : Utils.FALL_DOWN_AUTO_SOS_SWITCH_OFF
        );
      }

    } catch (e) {
      LogUtils.e(TAG, `setPersonalSafetyAutoCallSwitch setValueSync error: ${JSON.stringify(e)}`)
      return false;
    }

    let appVersion: string = '';
    try {
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      appVersion = bundleInfo.versionName;
    } catch (e) {
      LogUtils.e(TAG, `setPersonalSafetyAutoCallSwitch: getBundleInfoForSelfSync error: ${JSON.stringify(e)}`);
    }

    if (type === CAR_ACCIDENT) {
      const privacyStatement: PrivacyStatement = {
        isAgree: isSwitchOn,
        agreeTime: Date.now(),
        privacyVersion: CommonData.PRIVACY_STATEMENT_VERSION_OF_AUTO_CAR_ACCIDENT_SEND_SOS_MESSAGE,
        appVersion: appVersion,
        accountId: ''
      }
      EmergencyWarningPreferencesUtils.getInstance()
        .putAndFlushInPreferences(Utils.PRIVACY_STATEMENT_KEY_OF_AUTO_CAR_ACCIDENT_SEND_SOS_MESSAGE, privacyStatement);
    } else if (type === FALL_DOWN) {
      const privacyStatement: PrivacyStatement = {
        isAgree: isSwitchOn,
        agreeTime: Date.now(),
        privacyVersion: CommonData.PRIVACY_STATEMENT_VERSION_OF_AUTO_FALL_DOWN_SEND_SOS_MESSAGE,
        appVersion: appVersion,
        accountId: ''
      }
      EmergencyWarningPreferencesUtils.getInstance()
        .putAndFlushInPreferences(Utils.PRIVACY_STATEMENT_KEY_OF_AUTO_FALL_DOWN_SEND_SOS_MESSAGE, privacyStatement);
    }

    return true;
  }

  /**
   * Whether is auto dial sos number switch on.
   *
   * @param context Context of the current environment
   * @return true is on, false is off.
   */
  public static isAutoDialSosNumberSwitchOn(context: Context = getContext()): boolean {
    if (!context) {
      return false;
    }
    try {
      return settings.getValueSync(context, Utils.AUTO_DIAL_SOS_NUMBER_SWITCH,
        Utils.AUTO_DIAL_SOS_NUMBER_SWITCH_OFF) === Utils.AUTO_DIAL_SOS_NUMBER_SWITCH_ON;
    } catch (e) {
      LogUtils.e(TAG, `isAutoDialSosNumberSwitchOn settings getValueSync error: ${JSON.stringify(e)}`)
      return false;
    }
  }

  /**
   * Set the auto dial sos number switch on or off.
   *
   * @param context Context of the current environment
   * @param isSwitchOn switch on or off.
   */
  public static setAutoDialSosNumberSwitch(context: Context = getContext(), isSwitchOn: boolean) {
    if (!context) {
      return;
    }
    try {
      settings.setValueSync(context, Utils.AUTO_DIAL_SOS_NUMBER_SWITCH,
        isSwitchOn ? Utils.AUTO_DIAL_SOS_NUMBER_SWITCH_ON : Utils.AUTO_DIAL_SOS_NUMBER_SWITCH_OFF
      );
    } catch (e) {
      LogUtils.e(TAG, `setAutoDialSosNumberSwitch settings setValueSync error: ${JSON.stringify(e)}`)
      return;
    }
  }

  public static async getStringByNameSync(context: Context, key: string) {
    if (!context || !key) {
      return;
    }
    try {
      return context.resourceManager.getStringByNameSync(key);
    } catch (e) {
      LogUtils.e(TAG, `getStringValueFormResource failed, error: ${JSON.stringify(e)}`);
      return;
    }
  }

  public static async enableLocationSwitchOfEmergencyWarning() {
    if (LocationUtils.getInstance().getLocationEnable()) {
      return;
    }
    try {
      const result: boolean = LocationUtils.getInstance().setLocationSwitchIgnored(true);
      if (result) {
        await EmergencyWarningPreferencesUtils.getInstance()
          .putAndFlushInPreferences(EmergencyWarningController.IGNORE_LOCATION_SWITCH_KEY, true);
      }
    } catch (e) {
      LogUtils.e(TAG, 'enableLocationSwitchOfEmergencyWarning failed: error=' + JSON.stringify(e));
    }
  }

  public static getSosAudioFileName() {
    let systemLanguage = '';
    try {
      systemLanguage = i18n.System.getSystemLanguage();
    } catch (e) {
      LogUtils.e(TAG, 'getSosAudioFileName: getSystemLanguage error: ' + JSON.stringify(e));
    }
    if (systemLanguage && ['zh-Hans', 'zh-Hant', 'ug', 'bo'].includes(systemLanguage)) {
      return 'chinese.amr';
    } else {
      return 'english.amr';
    }
  }

  /**
   * get personal safety accident detected sos audio.
   */
  public static getPersonalSafetySosAudioFileName(type: PersonalSafetyAccidentType) {
    let systemLanguage = '';
    try {
      systemLanguage = i18n.System.getSystemLanguage();
    } catch (e) {
      LogUtils.e(TAG, 'getSosAudioFileName: getSystemLanguage error: ' + JSON.stringify(e));
      return '';
    }

    let retFileName: string = ''
    if (type === CAR_ACCIDENT) {
      retFileName += 'CarAccidentSos'
    } else if (type === FALL_DOWN) {
      retFileName += 'FallDownSos'
    }

    if (systemLanguage && ['zh-Hans', 'zh-Hant', 'ug', 'bo'].includes(systemLanguage)) {
      retFileName += 'Zh.amr'
    } else {
      retFileName += 'En.amr'
    }
    return retFileName;
  }

  /**
   * get personal safety accident detected notice audio.
   */
  public static getPersonalSafetySosNoticeAudioFileName(type: PersonalSafetyAccidentType) {
    let systemLanguage = '';
    try {
      systemLanguage = i18n.System.getSystemLanguage();
    } catch (e) {
      LogUtils.e(TAG, 'getSosAudioFileName: getSystemLanguage error: ' + JSON.stringify(e));
      return '';
    }

    let retFileName: string = ''
    if (type === CAR_ACCIDENT) {
      retFileName += 'CarAccidentNotice'
    } else if (type === FALL_DOWN) {
      retFileName += 'FallDownNotice'
    }
    if (systemLanguage && ['zh-Hans', 'zh-Hant', 'ug', 'bo'].includes(systemLanguage)) {
      retFileName += 'Zh.amr';
    } else {
      retFileName += 'En.amr';
    }

    return retFileName;
  }

  public static setWindowLayoutFullScreenApi(windowObj: window.Window, isLayoutFullScreen: boolean) {
    try {
      let promise = windowObj.setWindowLayoutFullScreen(isLayoutFullScreen);
      promise.then(() => {
        LogUtils.i(TAG, 'Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
      });
    } catch (error) {
      LogUtils.e(TAG, 'Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(error));
    }
  }

  public static setSystemBarEnable(windowObj: window.Window, isSystemBarEnable: boolean) {
    let names: WindowSystemBarNames[] = [];
    if (isSystemBarEnable) {
      names = ['status', 'navigation'];
    } else {
      names = [];
    }
    try {
      let promise = windowObj.setWindowSystemBarEnable(names);
      promise.then(() => {
        LogUtils.i(TAG, 'setWindowSystemBarEnable success.');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `setWindowSystemBarEnable failed. err code: ${err.code}, err message: ${err.message}`);
      });
    } catch (exception) {
      LogUtils.e(TAG,
        `setWindowSystemBarEnable failed. err code: ${exception.code}, err message: ${exception.message}`);
    }
  }

  public static getIsAccountUnlocked = async () => {
    let isAccountUnlocked = false;
    try {
      let accountManager: osAccount.AccountManager = osAccount.getAccountManager();
      isAccountUnlocked = await accountManager.isOsAccountUnlocked()
        .catch((e: BusinessError) => {
          LogUtils.e(TAG, 'getIsAccountUnlocked: accountManager.isOsAccountUnlocked error: ' + JSON.stringify(e));
          return false;
        });
    } catch (e) {
      LogUtils.e(TAG, 'getIsAccountUnlocked accountManager.isOsAccountUnlocked error: ' + JSON.stringify(e));
    }
    LogUtils.i(TAG, 'isAccountUnlocked ' + isAccountUnlocked);
    return isAccountUnlocked;
  }

  public static isProductHide(): boolean {
    let isProductHide: boolean = false;
    try {
      let info: string = systemParameterEnhance.getSync('const.product.hide', '');
      if (info === 'true') {
        isProductHide = true;
      }
    } catch (e) {
      LogUtils.e(TAG, `isProductHide error:${e}`);
    }
    LogUtils.i(TAG, `isProductHide result:${isProductHide}`);
    return isProductHide;
  }

  public static getNumberFromAppStorage(key: string, value: number): number {
    let result = AppStorage.get<number>(key);

    return result === undefined || result === null ? value : result;
  }

  public static getResourceFromAppStorage(key: string, value: Resource): Resource {
    let result = AppStorage.get<Resource>(key);

    return result === undefined || result === null ? value : result;
  }
}