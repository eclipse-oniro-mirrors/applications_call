/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import LogUtils from './LogUtils';
import { GlobalContextHelper } from './GlobalContextHelper';
import common from '@ohos.app.ability.common';
import * as Constants from './Constants';
import settings from '@ohos.settings';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import systemparameter from '@ohos.systemParameterEnhance';
import { promptAction } from '@kit.ArkUI';
import ConferenceConst from '../constant/ConferenceConst';
import DefaultCallData from '../struct/TypeUtils';
import { StringUtil } from './StringUtil';
import { BusinessError } from '@ohos.base';
import abilityManager from '@ohos.app.ability.abilityManager';
import { bundleManager } from '@kit.AbilityKit';
import { SystemMode } from './SystemMode';
import Intl from '@ohos.intl';
import I18n from '@ohos.i18n';

const TAG = 'utils';
const SETTINGSDATA_KEY: string = 'settings.telephony.callnotifytype';

/**
 * @file: Tools
 */

/**
 * Carry when the time is greater than 9 seconds
 */
const NINE_MAX = 9;

/**
 * Divide by 60 to get minutes and seconds
 */
const SIXTY_SECONDS = 60;
const SEC_VAL = 1000;
const MIN_VAL = SIXTY_SECONDS * SEC_VAL;
let phoneNumberFormatter: I18n.PhoneNumberFormat;
let numberFormatter: Intl.NumberFormat;
let dateTimeFormatter: Intl.DateTimeFormat;

export default class Utils {
  private static sUtils: Utils;
  private is2DProduct: boolean = false;

  public static getInstance(): Utils {
    if (Utils.sUtils == null) {
      Utils.sUtils = new Utils();
    }
    return Utils.sUtils;
  }

  /**
   * format time
   *
   * @param { number } count
   */
  public formatTime(count: number) {
    const second = Math.floor((count % MIN_VAL) / SEC_VAL);
    const minute = Math.floor((count / MIN_VAL) % SIXTY_SECONDS);
    const hour = Math.floor(count / (SIXTY_SECONDS * MIN_VAL));
    const secondStr = second <= NINE_MAX ? '0' + second : second;
    const minuteStr = minute <= NINE_MAX ? '0' + minute : minute;
    return hour > 0 ? `${hour}:${minuteStr}:${secondStr}` : `${minuteStr}:${secondStr}`;
  }

  public getContext(isPreferServiceContext?: boolean) {
    let context: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT);
    if (!context || isPreferServiceContext) {
      LogUtils.d(TAG, 'ui context is empty, try to use the service context');
      let serviceContext =
        GlobalContextHelper.getContext().getValue<common.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
      LogUtils.d(TAG, 'service context is valid ' + (serviceContext !== undefined));
      context = serviceContext;
    }
    return context;
  }

  public async getCallNotifiesFromSettingsData(callback: (data: string) => void) {
    try {
      let context = this.getContext();
      let result: string = settings.getValueSync(context, SETTINGSDATA_KEY, '');
      if (SystemMode.getInstance().isModePenglai()) {
        result = 'fullScreen'
      }
      LogUtils.i(TAG, `settingsData value: ${result}`);
      if (result === '') {
        callback(Constants.DEFAULT_CONFIG);
        return;
      }
      callback(result);
    } catch (err) {
      LogUtils.e(TAG, `queryCallNotifiesType fail, error code: ${err.code}`);
      callback(Constants.DEFAULT_CONFIG);
    }
  }
  
  public static async isMapNavigation() {
    let isMapTop: boolean = false;
    try {
      let elementName = await abilityManager.getTopAbility();
      if (elementName?.bundleName === Constants.PETAL_MAP_BUNDLE_NAME ||
        elementName?.bundleName === Constants.A_MAP_BUNDLE_NAME ||
        elementName?.bundleName === Constants.BAIDU_MAP_BUNDLE_NAME) {
        isMapTop = true;
        LogUtils.i(TAG, 'isMapNavigation ' + isMapTop);
      }
    } catch (err) {
      LogUtils.e(TAG, 'isMapNavigation error: ' + err);
    };
    return isMapTop;
  }

  /**
   * @description To determine whether the current product is a 2D product, certain functions need to be turned off.
   * @returns true: To D products, turn off and hide features; false: non-2D products, turn on and display features.
   */
  public isHddProduct() {
    try {
      Utils.sUtils.is2DProduct =
        systemParameterEnhance.getSync('const.scene_board.off_personalization_feature', 'false') === 'true';
    } catch (e) {
      LogUtils.e(TAG, 'Get Hdd Product Param Error');
    }
  }

  public getIs2DProduct() {
    return Utils.sUtils.is2DProduct;
  }

  public isEnabledSystemUiLive2(): boolean {
    try {
      let isEnabledLive2: boolean = systemParameterEnhance.getSync('persist.systemui.live2', 'false') === 'true';
      LogUtils.i(TAG, 'get persist systemui live2 param result is: ' + isEnabledLive2);
      return isEnabledLive2;
    } catch (err) {
      LogUtils.e(TAG, 'get persist systemui live2 param failed, error code: ' + err.code);
      return false;
    }
  }

  public isPrivacyScreenCast(): boolean {
    try {
      let context = this.getContext();
      let result: string = settings.getValueSync(context, Constants.SCREEN_CAST_PRIVACY_PROJECTION_STATE, 'false');
      LogUtils.i(TAG, `screenCastPrivacyState: ${result}`);
      return result === 'true';
    } catch (err) {
      LogUtils.e(TAG, 'queryScreenCastPrivacyState failed, error code: ' + err.code);
      return false;
    }
  }

  public async isMaintenanceMode(): Promise<boolean> {
    try {
      let value: string = await systemparameter.get(Constants.PERSIST_HIVIEWCARE_MAINTENANCEMODE);
      LogUtils.i(TAG, `maintenancemode: ${value}`)
      return value === Constants.STRING_TRUE;
    } catch (err) {
      LogUtils.e(TAG, `query isMaintenanceMode failed, err: ${JSON.stringify(err)}`);
      return false;
    }
  }

  public showToast(message: string | Resource, duration?: number): void {
    try {
      promptAction.showToast({
        message,
        duration: duration ?? 1500
      });
    } catch (err) {
      LogUtils.e(TAG, `showToast failed, err: ${(err as BusinessError)?.code}`);
    }
  }

  public isConferenceCall(curCallData: DefaultCallData): boolean {
    if (!curCallData) {
      return false;
    }
    if (curCallData.conferenceState === ConferenceConst.TEL_CONFERENCE_ACTIVE ||
      curCallData.conferenceState === ConferenceConst.TEL_CONFERENCE_HOLDING ||
      curCallData.conferenceState === ConferenceConst.TEL_CONFERENCE_DISCONNECTING) {
      return true;
    } else {
      return false;
    }
  }

  public getAccessibilityTextOfTime(time: string): string {
    if (time === undefined) {
      return '';
    }
    let timeTmpList = time.split(':');
    let accessibilityText = '';
    if (timeTmpList.length < 3) {
      let sec = Number(timeTmpList[1]);
      let min = Number(timeTmpList[0]);
      if (sec >= 1) {
        accessibilityText = sec > 1 ? StringUtil.formatPluralResourceToString($r('app.plural.call_time_sec'), sec) :
        StringUtil.formatPluralResourceToString($r('app.plural.call_time_sec'), sec);
      }
      if (min >= 1) {
        accessibilityText = (min > 1 ? StringUtil.formatPluralResourceToString($r('app.plural.call_time_min'), min) :
        StringUtil.formatPluralResourceToString($r('app.plural.call_time_min'), min)) + accessibilityText;
      }
    } else {
      let sec = Number(timeTmpList[2]);
      let min = Number(timeTmpList[1]);
      let hour = Number(timeTmpList[0]);
      if (sec >= 1) {
        accessibilityText = sec > 1 ? StringUtil.formatPluralResourceToString($r('app.plural.call_time_sec'), sec) :
        StringUtil.formatPluralResourceToString($r('app.plural.call_time_sec'), sec);
      }
      if (min >= 1) {
        accessibilityText = (min > 1 ? StringUtil.formatPluralResourceToString($r('app.plural.call_time_min'), min) :
        StringUtil.formatPluralResourceToString($r('app.plural.call_time_min'), min)) + accessibilityText;
      }
      if (hour >= 1) {
        accessibilityText = (hour > 1 ? StringUtil.formatPluralResourceToString($r('app.plural.call_time_hour'), hour) :
        StringUtil.formatPluralResourceToString($r('app.plural.call_time_hour'), hour)) + accessibilityText;
      }
    }
    return accessibilityText;
  }

  public static isDigitRegex(char: string) {
    return /^\d$/.test(char);
  }

  public static phoneFormat(phoneNumber: string) {
    try {
      let phoneFormatter: (string | number)[] = [];
      for (let i = 0; i < phoneNumber.length; i++) {
        if (Utils.isDigitRegex(phoneNumber[i])) {
          const num = Number(phoneNumber[i]);
          phoneFormatter.push(Utils.transFormNum(num));
        } else {
          phoneFormatter.push(phoneNumber[i]);
        }
      }
      return phoneFormatter.join('');
    } catch (error) {
      return phoneNumber;
    }
  }

  public static transFormNum(formatNum: number) {
    try {
      if (!numberFormatter) {
        numberFormatter = new Intl.NumberFormat();
      }
      return numberFormatter.format(formatNum);
    } catch (error) {
      return formatNum;
    }
  }


  public static dateTime(callTimeDuration: string) {
    try {
      let dateTimeFormatter = '';
      for (let i = 0; i < callTimeDuration.length; i++) {
        dateTimeFormatter += callTimeDuration[i] === ':' ? callTimeDuration[i] :
        Utils.transFormNum(Number(callTimeDuration[i]));
      }
      return dateTimeFormatter;
    } catch (error) {
      return '00:00';
    }
  }
}