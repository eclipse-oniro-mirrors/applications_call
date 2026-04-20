/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
import { settings } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import LogUtils from '../common/utils/LogUtils';

const ANTIFRAUD_CENTER_SWITCH = 'settings.telephony.antifraud_center_switch';
const ANTIFRAUD_BESTMIND_SWITCH = 'settings.telephony.antifraud_bestmind_switch';
const NUMBER_IDENTITY_KEY = 'settings.telephony.number_identity_switch';
const BUNDLE_NAME = 'com.hicorenational.antifraud.hmy';
const APP_ID = '6917560993344198571';

const TAG = 'NumberMarkUtil';


export default class NumberMarkUtil {

  /**
   * Pre none phone des.
   * Mark content: none
   */
  public static readonly PRE_NONE_PHONE_DESC: string = '0';

  /**
   * Pre crank phone des.
   * Mark content: crank
   */
  public static readonly PRE_CRANK_PHONE_DESC: string = '1';

  /**
   * Pre fraud phone des.
   * Mark content: fraud
   */
  public static readonly PRE_FRAUD_PHONE_DESC: string = '2';

  /**
   * Pre express phone dest.
   * Mark content: express
   */
  public static readonly PRE_EXPRESS_PHONE_DESC: string = '3';

  /**
   * Pre promote sales phone dest.
   * Mark content: promote sales
   */
  public static readonly PRE_PROMOTE_SALES_PHONE_DESC: string = '4';

  /**
   * Pre house agent phone dest.
   * Mark content: house agent
   */
  public static readonly PRE_HOUSE_AGENT_PHONE_DESC: string = '5';

  /**
   * Pre insurance phone dest.
   * Mark content: insurance
   */
  public static readonly PRE_INSURANCE_PHONE_DESC: string = '6';

  /**
   * Custom taxi phone dest.
   * Mark content: taxi
   */
  public static readonly PRE_TAXI_PHONE_DESC: string = '7';

  /**
   * Custom custom phone dest.
   * Mark content: custom
   */
  public static readonly PRE_CUSTOM_PHONE_DESC: string = '8';

  /**
   * Others phone dest.
   * Mark content: others
   */
  public static readonly OTHER_PHONE_DESC: string = '9';

  /**
   * Yellow page phone dest.
   * Mark content: yellow page
   */
  public static readonly YELLOW_PAGE_PHONE_DESC: string = '10';

  /**
   * Enterprise phone dest.
   * Mark content: Enterprise
   */
  public static readonly MARK_TYPE_ENTERPRISE: string = '11';

  /**
   * Identify page phone dest.
   * Mark content: Identify
   */
  public static readonly IDENTIFY_PAGE_PHONE_DESC: string = '12';

  public static readonly A_MARK_SOURCE: string = '0';

  public static readonly B_MARK_SOURCE: string = '1';

  /**
   * PhoneNumber mark source phone_state.
   */
  public static readonly PHONE_STATE_MARK_SOURCE: string = '2';

  /**
   * PhoneNumber mark source anti-fraud_center.
   */
  public static readonly ANTIFRAUD_CENTER_MARK_SOURCE: string = '3';

  /**
   * PhoneNumber mark source anti-fraud_center.
   */
  public static readonly ANTI_FRAUD_CENTER: string = '5';


  public static getNumberMarkInfo(context: Context, markType: string): string {
    // 获取 ResourceManager
    const manager = context.resourceManager;

    let resourceId: Resource;

    switch (markType) {
      case '1':
        resourceId = $r('app.string.harassing_call');
        break;
      case '2':
        resourceId = $r('app.string.fraud_phone_call');
        break;
      case '3':
        resourceId = $r('app.string.courier_and_food_delivery');
        break;
      case '4':
        resourceId = $r('app.string.advertising_and_promotion');
        break;
      case '5':
        resourceId = $r('app.string.Real_Estate_Agency');
        break;
      case '6':
        resourceId = $r('app.string.financial_management_insurance');
        break;
      case '7':
        resourceId = $r('app.string.taxi');
        break;
      case '8':
        resourceId = $r('app.string.custom');
        break;
      default:
        LogUtils.e(TAG, `getNumberMarkInfo markType is not exist: ${markType}`);
        resourceId = $r('app.string.harassing_call');
        break;
    }

    try {
      // 核心：同步解析资源为字符串
      return manager.getStringSync(resourceId);
    } catch (error) {
      // 异常处理，防止资源未找到导致崩溃
      LogUtils.e(TAG,`getNumberMarkInfo error: ${error}`)
      return '';
    }
  }

  // public static getNumberMarkSourceInfo(markSource: string): Resource {
  //   switch (markSource) {
  //     case '0':
  //       return $r('app.string.number_mark_source_hw')
  //     case '1':
  //       return $r('app.string.number_mark_source_teddy_bear')
  //     case '2':
  //       return $r('app.string.number_mark_source_phone_state')
  //     case '3':
  //       return $r('app.string.number_mark_source_antifraud_center')
  //     case '5':
  //       return $r('app.string.national_anti_fraud_center')
  //     default:
  //       HiLog.e(TAG, `getNumberMarkInfo markSource is not exist: ${markSource}`);
  //       return $r('app.string.number_mark_source_hw')
  //   }
  // }

  public static getNumberMarkType(markInfo: string): string {
    switch (markInfo) {
      case 'none':
        return NumberMarkUtil.PRE_NONE_PHONE_DESC
      case 'crank':
        return NumberMarkUtil.PRE_CRANK_PHONE_DESC
      case 'fraud':
        return NumberMarkUtil.PRE_FRAUD_PHONE_DESC
      case 'express':
        return NumberMarkUtil.PRE_EXPRESS_PHONE_DESC
      case 'promote_sales':
        return NumberMarkUtil.PRE_PROMOTE_SALES_PHONE_DESC
      case 'house_agent':
        return NumberMarkUtil.PRE_HOUSE_AGENT_PHONE_DESC
      case 'insurance':
        return NumberMarkUtil.PRE_INSURANCE_PHONE_DESC
      case 'taxi':
        return NumberMarkUtil.PRE_TAXI_PHONE_DESC
      case 'custom':
        return NumberMarkUtil.PRE_CUSTOM_PHONE_DESC
      case 'others':
        return NumberMarkUtil.OTHER_PHONE_DESC
      case 'yellow_page':
        return NumberMarkUtil.YELLOW_PAGE_PHONE_DESC
      case 'enterprise':
        return NumberMarkUtil.MARK_TYPE_ENTERPRISE
      default:
        LogUtils.e(TAG, `getNumberMarkInfo markInfo is not exist: ${markInfo}`);
        return NumberMarkUtil.PRE_NONE_PHONE_DESC
    }
  }

  public static isFromNationalAntiFraudCenter(context: Context): boolean {
    // 反诈中心 诈骗电话
    try {
      if (!bundleManager.isApplicationEnabledSync(BUNDLE_NAME)) {
        LogUtils.w(TAG, `isFromNationalAntiFraudCenter isApplicationEnabledSync false`);
        return false;
      }
      const bundleInfo =
        bundleManager.getBundleInfoSync(BUNDLE_NAME, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO);
      if (bundleInfo.signatureInfo && bundleInfo.signatureInfo.appIdentifier !== APP_ID) {
        LogUtils.w(TAG, `isFromNationalAntiFraudCenter APP_ID false`);
        return false;
      }
      // 国家反诈中心开关
      let antifraudCenterSwitch = settings.getValueSync(context, ANTIFRAUD_CENTER_SWITCH, '');
      // 全民反诈中心开关
      let antifraudBestmindSwitch = settings.getValueSync(context, ANTIFRAUD_BESTMIND_SWITCH, '');
      // 陌生号码和信息识别开关
      let numberIdentityKey = settings.getValueSync(context, NUMBER_IDENTITY_KEY, '');
      LogUtils.w(TAG, `isFromNationalAntiFraudCenter antifraudCenterSwitch: ${antifraudCenterSwitch
      },numberIdentityKey: ${numberIdentityKey}`);

      if ((antifraudCenterSwitch === '1' || antifraudBestmindSwitch === '1') && numberIdentityKey === '1') {
        return true;
      } else {
        return false;
      }
    } catch (err) {
      LogUtils.e(TAG, `isFromNationalAntiFraudCenter err: ${err.message}`)
      return false;
    }
  }
}