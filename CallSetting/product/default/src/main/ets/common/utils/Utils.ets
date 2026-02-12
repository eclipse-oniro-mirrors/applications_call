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

import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { abilityAccessCtrl, common,
  PermissionRequestResult,
  Permissions, UIExtensionContentSession } from '@kit.AbilityKit';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import * as Constants from '../constant/CallSettingsConstant';
import { BusinessError, settings, systemParameterEnhance } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { i18n, resourceManager } from '@kit.LocalizationKit';
import { SuperPrivacyEventUtil } from './SuperPrivacyEventUtil';
import { getSatelliteHardwareSupportInfo } from '../model/SatelliteServiceApi';
import { geoLocationManager } from '@kit.LocationKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { SystemMode } from '../../model/SystemMode';
import { HYACINTH_LOCATION_ALLOWED } from '../constant/SatelliteSearchConst';

const N0_SUPPORT = '0b00000000';
const PALACE_MUSEUM = 0b00000001;
const SUMMER_PALACE = 0b00000010;
const DANDELION = 0b00000100;
const CACTUS = 0b00001000;
const HYACINTH = 0b00100000;
const TAG = 'Utils';
const SATELLITE_KEY = 'const.telephony.satellite.support_type';
const CORRECTION_ENABLE_KEY = 'const.system.sensor_correction_enable';
const TYPE_CACTUS: number = 3;
const PERMISSION_LOCATION = 'ohos.permission.LOCATION';
const PERMISSION_APPROXIMATELY_LOCATION = 'ohos.permission.APPROXIMATELY_LOCATION';
const SUCCESS = 0;
const FAILED = -1;

export function isSupportDandelion(): boolean {
  let cactus = getProperEnhance(SATELLITE_KEY, '0');
  let isSupport = (Number(cactus) & DANDELION) === DANDELION;
  LogUtils.i(TAG, 'isSupportDandelion isSupport:' + JSON.stringify(isSupport));
  return isSupport;
}

export function isSupportCactus(): boolean {
  let cactus = getProperEnhance(SATELLITE_KEY, '0');
  let isSupport = (Number(cactus) & CACTUS) === CACTUS;
  LogUtils.i(TAG, 'isSupportCactus isSupport:' + JSON.stringify(isSupport));
  return isSupport;
}

export function isSupportHyacinth(): boolean {
  let cactus = getProperEnhance(SATELLITE_KEY, '0');
  let isSupport = (Number(cactus) & HYACINTH) === HYACINTH;
  LogUtils.i(TAG, `isSupportHyacinth support: ${isSupport}`);
  return isSupport;
}

/**
 * Is Support Palace Museum
 *
 * @returns true/false
 */
export function isSupportPalaceMuseum(): boolean {
  let cactus = getProperEnhance(SATELLITE_KEY, '0');
  let isSupport = (Number(cactus) & PALACE_MUSEUM) === PALACE_MUSEUM;
  LogUtils.i(TAG, 'isSupportPalaceMuseum isSupport:' + isSupport);

  let isSupportMessage = true;
  try {
    let isSupportMessageConfig = systemParameterEnhance.getSync('const.meetime.support.message', 'true');
    isSupportMessage = isSupportMessageConfig === 'true';
  } catch (err) {
    LogUtils.e(TAG, `getSupportMessageConfig error: ${err?.code} ${err?.message}`);
  }

  LogUtils.i(TAG, 'isSupportMessageConfig :' + isSupportMessage);
  return isSupport && isSupportMessage;
}

export function isSupportSummerPalace(): boolean {
  let cactus = getProperEnhance(SATELLITE_KEY, '0');
  let isSupport = (Number(cactus) & SUMMER_PALACE) === SUMMER_PALACE;
  LogUtils.i(TAG, 'isSupportSummerPalace isSupport:' + isSupport);
  return isSupport;
}

function getProperEnhance(key: string, value: string): string {
  return SystemParameterEnhance.getSync(key, `${value}`);
}

export function getString(value: Resource) {
  return CallSettingGlobalContextHelper.getContext().
    getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.
    resourceManager.getStringSync(value.id);
}

export function getPluralStringWithParam(resource: ResourceStr, param: number) {
  if (typeof resource === 'string') {
    return resource;
  }
  let res: resourceManager.Resource = {
    bundleName: resource.bundleName,
    moduleName: resource.moduleName,
    id: resource.id
  };
  return CallSettingGlobalContextHelper.getContext().
  getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.
  resourceManager.getPluralStringValueSync(res, param);
}

export function setExpandAutoAnswer(isEnable: boolean) {
  let context = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.CALL_SETTING_ABILITY_CONTEXT);
  try {
    settings.setValueSync(context, 'open_phone_to_answer', isEnable ? '1' : '0', settings.domainName.USER_PROPERTY);
  } catch (err) {
    LogUtils.e(TAG, `setExpandAutoAnswer error: ${err?.code} ${err?.message}`);
  }
}

export function getExpandAutoAnswer(): boolean {
  let context = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.CALL_SETTING_ABILITY_CONTEXT);
  return settings.getValueSync(context, 'open_phone_to_answer', '1', settings.domainName.USER_PROPERTY) === '1';
}

export function getPaddingByDevice(): Resource {
  if (isTablet() || isTwoInOne()) {
    return $r('sys.float.padding_level12');
  }
  return $r('sys.float.padding_level8');
}

export function isTablet(): boolean {
  let deviceTypeInfo: string = deviceInfo.deviceType;
  if (deviceTypeInfo != undefined && deviceTypeInfo === 'tablet') {
    return true;
  }
  return false;
}

export function isTwoInOne(): boolean {
  let deviceTypeInfo: string = deviceInfo.deviceType;
  if (deviceTypeInfo != undefined && deviceTypeInfo === '2in1') {
    return true;
  }
  return false;
}

export function isFusionCallEnabled(): boolean {
  return getProperEnhance('const.telephony.fusioncall.supported', 'false') === 'true';
}

export function isSupportMultiDeviceCommunicationSharing(): boolean {
  let proper: boolean = getProperEnhance('const.booster.virtual_modem_switch', 'false') === 'true';
  return proper;
}

/**
 * Is Phone
 *
 * @returns true/false
 */
export function isPhone(): boolean {
  if (deviceInfo.deviceType === 'phone') {
    return true;
  }
  return false;
}

/**
 * Terminal dialog ability.
 */
export function terminalDialogAbility(): void {
  let session: UIExtensionContentSession | undefined = AppStorage.get('session');
  session?.terminateSelf();
  let externalContext: common.UIAbilityContext | undefined = AppStorage.get('externalContext');
  externalContext?.terminateSelf();
}

/**
 * Confirm super privacy dialog.
 */
export function confirmSuperPrivacyDialog(): void {
  let want: Want | undefined = AppStorage.get('want');
  if (!want || !want.parameters) {
    return;
  }
  let isAnswer = want.parameters.isAnswer as boolean;
  let videoState = want.parameters.videoState as number;
  if (isAnswer) {
    let callId = want.parameters.callId as number;
    SuperPrivacyEventUtil.sendSuperPrivacyModeEvent(SuperPrivacyEventUtil
      .getAnswerSuperPrivacyModeEventOptions(videoState, callId, isAnswer));
  } else {
    let phoneNumber = want.parameters.number as string;
    let accountId = want.parameters.accountId as number;
    let dialScene = want.parameters.dialScene as number;
    let dialType = want.parameters.dialType as number;
    let callType = want.parameters.callType as number;
    SuperPrivacyEventUtil.sendSuperPrivacyModeEvent(SuperPrivacyEventUtil
      .getSuperPrivacyModeEventOptions(phoneNumber, accountId, videoState, dialScene, dialType, callType, isAnswer));
  }
}

export function isSupportMobileData(): boolean {
  let ret: boolean = getProperEnhance('const.telephony.voice.capable', 'true') === 'true';
  return ret;
}

export function getPushString(stringParams: string): string {
  if (!stringParams || (stringParams && stringParams.length === 0)) {
    LogUtils.e(TAG, 'getPushString stringParams is null');
    return '';
  }
  let paramArr: string[] = stringParams.split(',');
  return paramArr?.[0] ? paramArr?.[0] : '';
}

export function getVisibilityByTextOp(statusTextOp: boolean): Visibility {
  return statusTextOp ? Visibility.Visible : Visibility.Hidden;
}

export async function getLocation(context: Context): Promise<LocationInter | null> {
  let grantStatus1: boolean = await requestPermissions(context, [PERMISSION_LOCATION]);
  let grantStatus2: boolean = await requestPermissions(context, [PERMISSION_APPROXIMATELY_LOCATION]);
  let permission: Permissions[] = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
  // 精确定位权限只能跟模糊定位权限一起申请，或者已经有模糊定位权限才能申请精确定位权限
  if (grantStatus2 && !grantStatus1) {
    // 申请精确定位权限
    permission = ['ohos.permission.APPROXIMATELY_LOCATION'];
  } else if (!grantStatus1 && !grantStatus2) {
    // 申请模糊定位权限与精确定位权限或单独申请模糊定位权限
    permission = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
  } else {
    // 已经授权，可以继续访问目标操作
    LogUtils.i(TAG, 'getLocation permission ready');
  }
  let atManager = abilityAccessCtrl.createAtManager();
  AppStorage.setOrCreate<boolean>(HYACINTH_LOCATION_ALLOWED, true);
  atManager.requestPermissionsFromUser(context, permission).then((result: PermissionRequestResult) => {
    if (result.authResults[0] === FAILED || result.authResults[1] === FAILED) {
      LogUtils.i(TAG, 'request location permission success.');
      AppStorage.setOrCreate<boolean>(HYACINTH_LOCATION_ALLOWED, false);
    }
  }).catch((err: BusinessError) => {
    LogUtils.e(TAG, `requestPermissionsFromUser error: code: ${err.code}, message: ${err.message} `);
    AppStorage.setOrCreate<boolean>(HYACINTH_LOCATION_ALLOWED, false);
  });
  let location: geoLocationManager.Location | undefined = undefined;
  try {
    location = await geoLocationManager.getCurrentLocation();
  } catch (e) {
    LogUtils.e(TAG, `getLocation failed. Msg=${e.message}`);
    return null;
  }
  let res : LocationInter = {
    latitude: location ? location.latitude : 0,
    longitude: location ?location.longitude : 0
  }
  LogUtils.i(TAG, `getLocation end`);
  return res;
}

export async function reRequestLocation(context: Context): Promise<boolean> {
  return new Promise(async (resolve, reject) => {
    let grantStatus1: boolean = await requestPermissions(context, [PERMISSION_LOCATION]);
    let grantStatus2: boolean = await requestPermissions(context, [PERMISSION_APPROXIMATELY_LOCATION]);
    let permission: Permissions[] = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
    // 精确定位权限只能跟模糊定位权限一起申请，或者已经有模糊定位权限才能申请精确定位权限
    if (grantStatus2 && !grantStatus1) {
      // 申请精确定位权限
      permission = ['ohos.permission.APPROXIMATELY_LOCATION'];
    } else if (!grantStatus1 && !grantStatus2) {
      // 申请模糊定位权限与精确定位权限或单独申请模糊定位权限
      permission = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
    } else {
      // 已经授权，可以继续访问目标操作
      LogUtils.i(TAG, 'getLocation success');
    }
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionOnSetting(context, permission)
      .then((result) => {
        if (!result) {
          LogUtils.e(TAG, 'requestPermissionOnSetting result is null');
          resolve(false);
        }
        // 处理授权结果
        if (result[0] === SUCCESS || (result.length > 1 && result[1] === SUCCESS)) {
          AppStorage.setOrCreate<boolean>(HYACINTH_LOCATION_ALLOWED, true);
          LogUtils.i(TAG, 'reRequestLocation success.');
          resolve(true);
        } else {
          resolve(false);
          LogUtils.i(TAG, 'reRequestLocation failed.');
        }
      })
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, `reRequestLocation error: code: ${err.code}, message: ${err.message} `);
        resolve(false);
      })
  });
}

export async function requestPermissions(context: Context, permissionList: Array<Permissions>): Promise<boolean> {
  let atManager = abilityAccessCtrl.createAtManager();
  return new Promise<boolean>(async (resolve, reject) => {
    LogUtils.i(TAG, 'requestPermission begin');
    let data = await atManager.requestPermissionsFromUser(context, permissionList);
    if (data && data.authResults) {
      let result = 0;
      for (let i = 0; i < data.authResults.length; i++) {
        result += data.authResults[i];
      }
      if (result === 0) {
        resolve(true);
      } else {
        LogUtils.e(TAG, 'requestPermission user rejected');
        resolve(false);
      }
    } else {
      LogUtils.e(TAG, 'requestPermission failed');
      resolve(false);
    }
    LogUtils.i(TAG, 'requestPermission end');
  });
}

export class LocationInter {
  public latitude: number = -1;
  public longitude: number = -1;
}

/**
 * 是否开启Correction的CCM开关，仅grlb支持
 *
 * @returns
 */
export function isCorrectionEnable(): boolean {
  let ret: boolean = getProperEnhance(CORRECTION_ENABLE_KEY, '0') === '1';
  LogUtils.i(TAG, `isCorrectionEnable ${ret}`);
  return ret;
}
