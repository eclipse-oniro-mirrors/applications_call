/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { common, Want } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { LogUtils } from '@ohos/common/CommonIndex';

const MODULE_NAME_PHONE = 'phone_widget';
const FUN_NUM_HOME_SATELLITE = 'SF-10056664_f101';
const FUN_NUM_HOME_DISTRIBUTED = 'SF-10044640_f115';
const FUN_NUM_HOME_BEIDOU_MESSAGE = 'SF-10279835_f107';
const FUN_NUM_HOME_HYACINTH = 'SF-20014651_f101';
const URI_FORMATTER_APPEND = '?funNum=%s&type=%s'
const APP_BUNDLE_NAME = 'com.ohos.tips';
const MODULE_NAME_PC = 'pc_widget';
const CODE_BUNDLE_NAME_NOT_FOUND = 17700001;
const TAG = 'TipsJumpUtils';
const TIPS_APP_ID = 'com.ohos.tips_BB4oLXt8JLOw5d' +
  'jd42S0oLOGzO6kOnT8hZfFRAAel2gbcQBG5jIsO4genni5cn2SQpKpKvkwOA7Ajsc7qf+MZgM=';
const URI_APPGALLERY_ID = '?id=com.ohos.tips';

export const FUN_NAME_SATELLITE = 'satellite';

export const FUN_NAME_DISTRIBUTED = 'distributed';

export const FUN_NAME_BEIDOU_MESSAGE = 'beidou_satellite_message';

export const FUN_NAME_HYACINTH = 'hyacinth';

const TYPE = '100';

export default class TipsJumpUtils {
  /**
   * Jump to the home page of game skills
   *
   * @param startAbleContext Requested：common.UIAbilityContext |
   common.ServiceExtensionContext
   * @param type Entry type ID, which is used for dotting.
   * @param funcName function name
   * @param moduleName phone_widget:Jump Phone，pc_widget：Jump to PC
   */
  public static jumpHome(context: common.UIAbilityContext, type: string = TYPE, funcName: string, moduleName: string =
  MODULE_NAME_PHONE) {
    if (funcName === FUN_NAME_SATELLITE) {
      TipsJumpUtils.jumpTips(context, FUN_NUM_HOME_SATELLITE, type, moduleName ?? MODULE_NAME_PHONE);
    } else if (funcName === FUN_NAME_DISTRIBUTED) {
      TipsJumpUtils.jumpTips(context, FUN_NUM_HOME_DISTRIBUTED, type, moduleName ?? MODULE_NAME_PHONE);
    } else if (funcName === FUN_NAME_BEIDOU_MESSAGE) {
      TipsJumpUtils.jumpTips(context, FUN_NUM_HOME_BEIDOU_MESSAGE, type, moduleName ?? MODULE_NAME_PHONE);
    } else if (funcName === FUN_NAME_HYACINTH) {
      TipsJumpUtils.jumpTips(context, FUN_NUM_HOME_HYACINTH, type, moduleName ?? MODULE_NAME_PHONE);
    }
  }

  public static jumpTips(context: common.UIAbilityContext, funNum: string, type: string,
    moduleName: string = MODULE_NAME_PHONE) {
    let uriFormatter = '';
    try {
      uriFormatter = context.resourceManager.getStringSync($r('app.string.play_skills_uri_formatter'));
    } catch (error) {
      console.error(`getStringSync failed, error code: ${error?.code}, message: ${error?.message}.`);
    }
    uriFormatter = uriFormatter + URI_FORMATTER_APPEND;
    let uri = util.format(uriFormatter, funNum, type);
    TipsJumpUtils.jumpTipsByUri(context, uri, moduleName ?? MODULE_NAME_PHONE);
  }

  public static jumpTipsByUri(context: common.UIAbilityContext, uri: string, moduleName:
    string = MODULE_NAME_PHONE) {
    if (moduleName !== MODULE_NAME_PHONE && moduleName !== MODULE_NAME_PC) {
      LogUtils.i(TAG, `unknown moduleName, supported value:`);
      return;
    }
    TipsJumpUtils.isAppInstalled().then((isAppInstalled: boolean) => {
      if (isAppInstalled) {
        TipsJumpUtils.jumpAppByUri(context, uri);
      } else {
        TipsJumpUtils.jumpAppGallery(context);
      }
    })
  }

  private static jumpAppGallery(context: common.UIAbilityContext) {
    LogUtils.i(TAG, 'try jump to AppGallery');
    let uriAppgallery = '';
    try {
      uriAppgallery = context.resourceManager.getStringSync($r('app.string.play_skills_uri_appgallery'));
    } catch (error) {
      console.error(`getStringSync failed, error code: ${error?.code}, message: ${error?.message}.`);
    }
    uriAppgallery = uriAppgallery + URI_APPGALLERY_ID;
    const want: Want = {
      uri: uriAppgallery
    };
    context.startAbility(want).then(() => {
      LogUtils.e(TAG, 'jump AppGallery success');
    }).catch(() => {
      LogUtils.e(TAG, 'jump AppGallery error');
    })
  }

  private static isAppInstalled(): Promise<boolean> {
    return bundleManager.getBundleInfo(APP_BUNDLE_NAME,
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO).then((info) => {
      if (TIPS_APP_ID === info.signatureInfo.appId) {
        LogUtils.i(TAG, 'tips app is installed');
        return true;
      } else {
        LogUtils.i(TAG, 'tips app is forged');
        return false;
      }
    }).catch((err: BusinessError) => {
      if (err.code === CODE_BUNDLE_NAME_NOT_FOUND) {
        LogUtils.e(TAG, 'tips app is not installed');
      } else {
        LogUtils.e('TipsJumpUtils: failed to check if tips app is installed, err: %{private}s', JSON.stringify(err));
      }
      return false;
    })
  }

  private static jumpAppByUri(context: common.UIAbilityContext, uri: string) {
    LogUtils.i(TAG, 'try jump to app');
    let want: Want = {
      bundleName: APP_BUNDLE_NAME,
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri
    };
    context.startAbility(want, (err: BusinessError) => {
      if (err !== undefined) {
        LogUtils.e(TAG, 'jump to [tips atomic app] success err :' + JSON.stringify(err));
      } else {
        LogUtils.e(TAG, 'jump to [tips atomic app] success');
      }
    });
  }
}