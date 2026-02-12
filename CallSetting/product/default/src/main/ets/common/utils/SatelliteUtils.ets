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

import SatelliteSearchManager from '../../manager/SatelliteSearchManager';
import { LogUtils } from '@ohos/common/CommonIndex';
import Settings from '@ohos.settings';
import { isSupportCactus, isSupportDandelion, isSupportPalaceMuseum } from './Utils';
import { QUERY_SATELLITE_MODE_KEY } from './SateToggleStateManager';

const TAG = 'SatelliteUtils';

/**
 * number two
 */
const NUMBER_TWO: number = 2;

// azimuth
export const SAFE_AZIMUTH_DELTA: number = 15;

// Pitch
export const SAFE_PITCH_DELTA: number = 15;

//sector angle of star finding interface
export const DEFAULT_ANGLE = 60;

//center diameter of star finding interface
export const DEFAULT_CIRCLE = 60;

//center diameter of star finding interface
export const DEFAULT_FLOAT_CIRCLE = 38;

export const Y_MAX_DISTANCE: number = 90;

export const Y_MIN_DISTANCE: number = -90;

export const SPLIT: number = 60;

export const DEGREE: string = '°';

export const MINUTE: string = "'";

export const SECOND: string = '\"';

const SKYCOM_SATELLITE_SWITCH_ON = '1.0';

const SKYCOM_SATELLITE_SWITCH_OFF = '0.0';
// 定义引导方位角的常量
const NOT_GUIDE_AZIMUTH = 0; // 不引导方位角
// 定义引导俯仰角的常量
const NOT_GUIDE_PITCH = 0; // 不引导俯仰角

export default class SatelliteUtils {

  public static successAzimuthDelta: number = 0;
  public static successPitchDelta: number = 0;

  /**
   * checkAzimuthOk
   *
   * @param azimuthDelta int
   * @return boolean checkAzimuthOk
   */
  public static checkAzimuthOk(azimuthDelta: number): boolean {
    let safeAzimuthDelta: number = SatelliteUtils.getSuccessAzimuth();
    return azimuthDelta >= -safeAzimuthDelta && azimuthDelta <= safeAzimuthDelta;
  }

  /**
   * checkPitchOk
   *
   * @param pitchDelta int
   * @return boolean
   */
  public static checkPitchOk(pitchDelta: number): boolean {
    let safePitchDelta: number = SatelliteUtils.getSuccessPitch();
    return pitchDelta >= -safePitchDelta && pitchDelta <= safePitchDelta;
  }

  public static getDefaultAngles() {
    let successAzimuth = SatelliteUtils.getSuccessAzimuth();
    LogUtils.i(TAG, 'getDefaultAngles, successAzimuth = ' + successAzimuth);
    if (SatelliteSearchManager.getInstance().getIsFromMeetime() && SatelliteUtils.successAzimuthDelta === 0) {
      return DEFAULT_ANGLE;
    }
    if (successAzimuth == 15) {
      return DEFAULT_ANGLE;
    }
    if (successAzimuth > 15 && successAzimuth < 45) {
      return 90;
    }
    return successAzimuth * 2;
  }

  /**
   * Get sate rotation angles
   *
   * @param inputAzimuth
   * @param defaultAngle defaultAngle
   * @return Converted Value
   */
  public static getSateRotationAngles(inputAzimuth: number, defaultAngle: number): number {
    let safeAzimuthDelta: number = SatelliteUtils.getSuccessAzimuth();
    if (inputAzimuth >= -safeAzimuthDelta && inputAzimuth <= safeAzimuthDelta) {
      return inputAzimuth * (defaultAngle / (safeAzimuthDelta * 2));
    } else if (inputAzimuth > safeAzimuthDelta) {
      return defaultAngle / 2 + (inputAzimuth - safeAzimuthDelta) *
        (360 - defaultAngle) / (360 - safeAzimuthDelta * 2);
    }
    return -(defaultAngle / 2) + (inputAzimuth + safeAzimuthDelta) *
      (360 - defaultAngle) / (360 - safeAzimuthDelta * 2);
  }

  /**
   * Get dialog pitch translation
   *
   * @param inputPitch pitch
   * @return Converted Value
   */
  public static getPitchTranslationY(inputPitch: number) {
    let safePitchDelta: number = SatelliteUtils.getSuccessPitch();
    if (inputPitch >= -safePitchDelta && inputPitch <= safePitchDelta) {
      return inputPitch * DEFAULT_CIRCLE / (safePitchDelta * 2);
    } else if (inputPitch > safePitchDelta) {
      return DEFAULT_CIRCLE / 2 + (inputPitch - safePitchDelta) * 164 / (230 - (safePitchDelta * 2));
    }
    return -(DEFAULT_CIRCLE / 2) + (inputPitch + safePitchDelta) * 164 / (230 - (safePitchDelta * 2));
  }

  /**
   * Get dialog pitch translation
   *
   * @param inputPitch pitch
   * @return Converted Value
   */
  public static getFloatPitchTranslationY(inputPitch: number) {
    let safePitchDelta: number = SatelliteUtils.getSuccessPitch();
    if (inputPitch >= -safePitchDelta && inputPitch <= safePitchDelta) {
      return inputPitch * DEFAULT_FLOAT_CIRCLE / (safePitchDelta * 2);
    } else if (inputPitch > safePitchDelta) {
      return DEFAULT_FLOAT_CIRCLE / 2 + (inputPitch - safePitchDelta) * 104 / (230 - (safePitchDelta * 2));
    }
    return -(DEFAULT_FLOAT_CIRCLE / 2 ) + (inputPitch + safePitchDelta) * 104 / (230 - (safePitchDelta * 2));
  }

  /**
   * ConvertDigitalToLongitude
   *
   * @param digitalDegree double
   * @param context context
   * @return result
   */
  public static convertDigitalToLongitude(digitalDegree: number) {
    let degree: number = Math.trunc(digitalDegree);
    let tmp: number = (digitalDegree - degree) * SPLIT;
    let minute: number = Math.trunc(tmp);
    let second: number = Math.trunc((tmp - minute) * SPLIT);
    let longitudeStr: string = degree + DEGREE + minute + MINUTE + second + SECOND;
    return longitudeStr;
  }

  /**
   * ConvertDigitalToLatitude
   *
   * @param digitalDegree double
   * @param context context
   * @return latitudeFlag
   */
  public static convertDigitalToLatitude(digitalDegree: number) {
    let degree: number = Math.trunc(digitalDegree);
    let tmp: number = (digitalDegree - degree) * SPLIT;
    let minute: number = Math.trunc(tmp);
    let second: number = Math.trunc((tmp - minute) * SPLIT);
    let latitudeStr: string = degree + DEGREE + minute + MINUTE + second + SECOND;
    return latitudeStr;
  }

  public static getSuccessPitch() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime() && SatelliteUtils.successPitchDelta === 0) {
      return SAFE_PITCH_DELTA;
    }
    return SatelliteUtils.successPitchDelta;
  }

  public static getSuccessAzimuth() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime() && SatelliteUtils.successAzimuthDelta === 0) {
      return SAFE_AZIMUTH_DELTA;
    }
    return SatelliteUtils.successAzimuthDelta;
  }

  /**
   * Whether the device supports the Skycom satellite
   */
  static async isSupportSkycomSatellite(): Promise<boolean> {
    LogUtils.i(TAG, 'isSupportSkycomSatellite');
    let isMainOsAccount: boolean = await SatelliteUtils.isMainOsAccount();
    return isMainOsAccount && (isSupportDandelion() || isSupportCactus());
  }

  /**
   * Whether the device supports the BeiDou satellite
   */
  static async isSupportBeidouSatellite(): Promise<boolean> {
    LogUtils.i(TAG, 'isSupportBeidouSatellite.');
    let isMainOsAccount: boolean = await SatelliteUtils.isMainOsAccount();
    return isMainOsAccount && isSupportPalaceMuseum();
  }

  /**
   * Obtaining the Status of the Skycom Satellite Switch
   *
   * @returns satellite switch state 0.0 is off, 1.0 is on
   */
  static getSkycomSatelliteState(): boolean {
    LogUtils.i(TAG, 'getSkycomSatelliteState');
    let context = AppStorage.get('pageContext') as Context;
    if (!context) {
      LogUtils.e(TAG, 'getSkycomSatelliteState context is undefined');
      throw new Error('getSkycomSatelliteState context error');
    }
    let settingsValue = Settings.getValueSync(context, QUERY_SATELLITE_MODE_KEY, SKYCOM_SATELLITE_SWITCH_OFF);
    return settingsValue === SKYCOM_SATELLITE_SWITCH_ON;
  }

  /**
   * Obtaining the BeiDou Satellite Switch Status
   *
   * @returns satellite switch state 0.0 is off, 1.0 is on
   */
  static getBeidouSatelliteState(): string {
    LogUtils.i(TAG, 'getBeidouSatelliteState');
    throw new Error('getBeidouSatelliteState unSupport');
  }

  static updateSuccessDelta(successPitchDelta: number, successAzimuthDelta: number): boolean {
    if (SatelliteUtils.successPitchDelta === 0 || SatelliteUtils.successAzimuthDelta === 0) {
      SatelliteUtils.successPitchDelta = successPitchDelta;
      SatelliteUtils.successAzimuthDelta = successAzimuthDelta;
      return false;
    }
    if (SatelliteUtils.successPitchDelta !== successPitchDelta ||
      SatelliteUtils.successAzimuthDelta !== successAzimuthDelta) {
      SatelliteUtils.successPitchDelta = successPitchDelta;
      SatelliteUtils.successAzimuthDelta = successAzimuthDelta;
      return true;
    }
    return false;
  }

  /**
   * Indicates whether the account is the primary account.
   *
   * @returns true/false
   */
  static async isMainOsAccount(): Promise<boolean> {
    LogUtils.i(TAG, `isMainOsAccount start.`);
    try {
      let ns = await import('@ohos.account.osAccount');
      let isMainOsAccount: boolean = await ns.default.getAccountManager().isMainOsAccount() as boolean;
      LogUtils.i(TAG, `isMainOsAccount end isMainOsAccount: ${isMainOsAccount} .`);
      return isMainOsAccount;
    } catch (err) {
      LogUtils.e(TAG, `get isMainOsAccount result error, code: ${err?.code}, message: ${err?.message}`);
    }
    return false;
  }

  /**
   * isGuideAzimuth
   *
   * @param guideAzimuth int
   * @return boolean
   */
  public static isGuideAzimuth(guideAzimuth: number | undefined): boolean {
    LogUtils.i(TAG, `guideAzimuth : ${guideAzimuth}`);
    return guideAzimuth === NOT_GUIDE_AZIMUTH;
  }

  /**
   * isGuidePitch
   *
   * @param guidePitch int
   * @return boolean
   */
  public static isGuidePitch(guidePitch: number | undefined): boolean {
    LogUtils.i(TAG, `guidePitch : ${guidePitch}`);
    return guidePitch === NOT_GUIDE_PITCH;
  }
}

