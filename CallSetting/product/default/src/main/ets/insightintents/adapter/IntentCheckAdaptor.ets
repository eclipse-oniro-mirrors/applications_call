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

import insightIntent from '@ohos.app.ability.insightIntent';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import { IntentCodeConstants } from '../constant/IntentCodeConstant';
import { LogUtils } from '@ohos/common/CommonIndex';
import { StringUtil } from '../../common/utils/StringUtil';
import { MobileDataUtil } from '../util/MobileDataUtil';
import SatelliteUtils from '../../common/utils/SatelliteUtils';
import { IntentEntryKeyName } from '../constant/IntentConstant';
import { isSupportMobileData } from '../../common/utils/Utils';


const TAG: string = 'IntentCheckAdaptor: '

/**
 * Check the method mapping of the configuration item switch.
 */
const checkSwitchFunRecord: Record<string, Function> = {
  'mobile_data': MobileDataUtil.checkCellularDataIsActive,
  'skycom_satellite_communications': SatelliteUtils.isSupportSkycomSatellite,
  'changlian_beidou_satellite_news': SatelliteUtils.isSupportBeidouSatellite
}

const checkSwitchUnSupportValue: Record<string, number> = {
  'mobile_data': IntentCodeConstants.NO_SIM_CARD,
  'skycom_satellite_communications': IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
  'changlian_beidou_satellite_news': IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED
}

/**
 * Intention Framework Operation Setting Validation Setting Item Transfer Class
 *
 * @since 2024-05-29
 */
export class IntentCheckAdaptor {
  private constructor() {
  }

  /**
   * Check whether the setting page are exist.
   *
   * @param entryKey settings page entry key
   * @param appBundleName app bundle name
   * @returns
   */
  static async checkSettingPage(entryKey: string, appBundleName: string): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `checkSettingPage intent entryKey is ${entryKey}, appBundleName is ${appBundleName}`);
    let code: number = IntentCodeConstants.DEFAULT_CODE_SUCCESS;
    let isSupport: boolean = false;
    let isPageExist: boolean = await IntentCheckAdaptor.checkSettingPageIsExist(entryKey);
    if (isPageExist) {
      if (StringUtil.isEmpty(appBundleName) || IntentCheckAdaptor.checkBundleNameIsValid(appBundleName)) {
        isSupport = true;
      }
    }
    LogUtils.i(TAG, `checkSettingPage isSupport is ${isSupport}`);
    let rsp: insightIntent.ExecuteResult = {
      code: code,
      result: {
        'entryKey': entryKey,
        'appBundleName': appBundleName,
        'isSupport': isSupport
      }
    }
    return rsp;
  }

  /**
   * Check whether the settings are available.
   *
   * @param itemName settings item name
   * @param appBundleName app bundle name
   * @returns
   */
  static async checkSettingItem(itemName: string, appBundleName: string): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `checkSettingItem intent itemName is ${itemName}, appBundleName is ${appBundleName}`);
    let code: number = IntentCodeConstants.DEFAULT_CODE_SUCCESS;
    let isSupport: boolean = isSupportMobileData();
    if (!isSupport) {
      return IntentCheckAdaptor.buildExecuteResult(IntentCodeConstants.MOBILE_DATA_CODE_UNSUPPORT, isSupport, itemName,
        appBundleName);
    }
    let isActive: boolean = await IntentCheckAdaptor.checkSwitchStatusIsActive(itemName);
    if (!isActive) {
      code = checkSwitchUnSupportValue[itemName];
      isSupport = false;
      return IntentCheckAdaptor.buildExecuteResult(code, isSupport, itemName, appBundleName);
    }
    let isAirPlaneActive: boolean = MobileDataUtil.isAirplaneActive();
    if (isAirPlaneActive) {
      code = IntentCodeConstants.LIMITED_BY_AIRPLANE_MODE;
      isSupport = false;
      return IntentCheckAdaptor.buildExecuteResult(code, isSupport, itemName, appBundleName);
    }

    if (StringUtil.isEmpty(appBundleName) || IntentCheckAdaptor.checkBundleNameIsValid(appBundleName)) {
      isSupport = isSupport && true;
    }
    return IntentCheckAdaptor.buildExecuteResult(code, isSupport, itemName, appBundleName);
  }

  private static buildExecuteResult(code: number, isSupport: boolean, itemName: string,
    appBundleName: string): insightIntent.ExecuteResult {
    let rsp: insightIntent.ExecuteResult = {
      code: code,
      result: {
        'itemName': itemName,
        'appBundleName': appBundleName,
        'isSupport': isSupport
      }
    }
    return rsp;
  }

  private static checkBundleNameIsValid(appBundleName: string) {
    try {
      return bundleManager.isApplicationEnabledSync(appBundleName);
    } catch (e) {
      LogUtils.e(TAG,
        `Failed to startAbility. Code: ${(e as BusinessError).code}, message: ${(e as BusinessError).message}`);
    }
    return false;
  }

  /**
   * Check whether the settings switch is available
   */
  static async checkSwitchStatusIsActive(itemName: string): Promise<boolean> {
    let isActive: boolean = await checkSwitchFunRecord[itemName]()
    LogUtils.i(TAG,
      ` Check setting switch status is active, itemName: ${itemName}, status: ${JSON.stringify(isActive)}`);
    return isActive;
  }

  /**
   * Check whether the settings page is exist
   */
  static async checkSettingPageIsExist(entryKey: string): Promise<boolean> {
    let isPageExist: boolean = false;
    if (StringUtil.isEmpty(entryKey)) {
      LogUtils.e(TAG, 'entryKey is empty');
      return isPageExist;
    }
    switch (entryKey) {
      case IntentEntryKeyName.MOBILE_DATA:
        isPageExist = isSupportMobileData();
        break;
      case IntentEntryKeyName.SATELLITE_NETWORK:
        let isSupportSkycom: boolean = await SatelliteUtils.isSupportSkycomSatellite();
        let isSupportBeidou: boolean = await SatelliteUtils.isSupportBeidouSatellite();
        isPageExist = isSupportSkycom || isSupportBeidou;
        break;
      default:
        LogUtils.e(TAG, 'other entryKey');
        break
    }
    LogUtils.i(TAG,
      ` Check setting page status is exist, entryKey: ${entryKey}, status: ${JSON.stringify(isPageExist)}`);
    return isPageExist;
  }
}
