/*
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
import LogUtils from './HiLog';
import HashMap from '@ohos.util.HashMap';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@kit.BasicServicesKit';


const TAG = 'PermissionsUtils';
const GET_TOKEN_ID_FAILED = -1;

export class PermissionsUtils {
  public static readonly permissionsOfEmergencyWarning: Array<Permissions> = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION',
    'ohos.permission.LOCATION_IN_BACKGROUND'
  ];
  public static readonly permissionsOfEmergencyRescue: Array<Permissions> = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION'
  ];
  public static readonly permissionsOfSOSAutoSendSMS: Array<Permissions> = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION',
    'ohos.permission.SEND_MESSAGES'
  ];
  public static readonly permissionsOfSOSPersonalSafetyAutoCallAndSendSMS: Array<Permissions> = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION',
    'ohos.permission.SEND_MESSAGES',
    'ohos.permission.PLACE_CALL',
    'ohos.permission.MODIFY_AUDIO_SETTINGS'
  ];
  public static readonly permissionsReadContacts: Array<Permissions> = [
    'ohos.permission.READ_CONTACTS'
  ];
  public static checkPermissions = async (permissions: Array<Permissions>) => {
    let mapPermissionsToGrantStatus: HashMap<Permissions, abilityAccessCtrl.GrantStatus> =
      new HashMap<Permissions, abilityAccessCtrl.GrantStatus>();
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus;
    let tokenId: number;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (err) {
      LogUtils.e(TAG, `Failed to get bundle info for self. Code is ${err?.code}` +
        `, message is ${err?.message}`);
      return mapPermissionsToGrantStatus;
    }

    try {
      if (tokenId !== GET_TOKEN_ID_FAILED) {
        permissions.forEach((v) => {
          grantStatus = atManager.verifyAccessTokenSync(tokenId, v);
          mapPermissionsToGrantStatus.set(v, grantStatus)
        })
      }
      return mapPermissionsToGrantStatus;
    } catch (err) {
      LogUtils.e(TAG, 'getTokenId failed, errCode:' + (err as BusinessError).code + ',errMessage:' +
      (err as BusinessError).message);
      return mapPermissionsToGrantStatus;
    }
  }
  /**
   * check location permission state of EmergencyWarning
   */
  public static checkLocationPermissionOfEmergencyWarning = async () => {
    return await PermissionsUtils.checkPermissions(PermissionsUtils.permissionsOfEmergencyWarning);
  }
  /**
   * check permission state of SOS Auto Send SMS Function
   */
  public static checkPermissionOfSOSAutoSendSMS = async () => {
    return await PermissionsUtils.checkPermissions(PermissionsUtils.permissionsOfSOSAutoSendSMS);
  }
  /**
   * check permission state of SOS Car Accident Auto Call Function
   */
  public static checkPermissionOfPersonalSafetyAutoCallAndSendSMS = async () => {
    return await PermissionsUtils.checkPermissions(PermissionsUtils.permissionsOfSOSPersonalSafetyAutoCallAndSendSMS);
  }
  /**
   * check the permission status of the SOS adding contact function
   */
  public static checkPermissionsReadContacts = async () => {
    return await PermissionsUtils.checkPermissions(PermissionsUtils.permissionsReadContacts);
  }
  /**
   * check permission state of send message
   */
  public static checkPermissionOfSendMessage = async () => {
    return await PermissionsUtils.checkPermissions(['ohos.permission.SEND_MESSAGES']);
  }
}