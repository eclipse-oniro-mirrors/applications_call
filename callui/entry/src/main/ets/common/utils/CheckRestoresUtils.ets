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

import LogUtils from './LogUtils';
import { commonEventManager } from '@kit.BasicServicesKit';
import { BusinessError } from '@ohos.base';
import { storageStatistics } from '@kit.CoreFileKit';
import { CALL_BUNDLE_NAME } from './Constants';
import { bundleManager, common, dialogRequest } from '@kit.AbilityKit';

const TAG = 'CheckRestoresUtils'
// 700MB
const FREE_SIZE = 700 * 1024 * 1024;
const FREE_SIZE_700M = '700M';
// 提醒对应的错误码
const DESCRIPTION = '845010023';
const SUGGESTION = '545010023';
const HIVIECARE_BUNDLE_NAME = 'com.ohos.hiviewcare';

const BUNDLE_NAME_RESTORE = 'com.ohos.restores';
const ABILITY_NAME_RESTORE = 'RestoresDialogServiceAbility';
const BUNDLE_NAME_NOTEPAD = 'com.ohos.notepad';
export const NOTEPAD_DISABLE_NOT_SUMMARY = 'NOTEPAD_DISABLE_NOT_SUMMARY';

enum PopupStatus {
  /**
   * 描述：成功状态码
   * 原因：弹窗弹出，用户点击恢复且恢复成功
   * */
  RestoreSuccess = 1,

  /**
   * 描述：错误状态码
   * 原因：弹窗弹出，用户点击恢复但是恢复失败
   * */
  RestoreFailure = 2,

  /**
   * 描述：默认状态码
   * 原因：弹窗弹出，用户取消
   * */
  UserCancelled = 0,

  /**
   * 描述：参数错误状态码
   * 原因：弹窗未弹出，参数错误
   * */
  ParameterError = -1,

  /**
   * 描述：应用未卸载或不在可恢复列表状态码
   * 原因：弹窗未弹出，所传包名对应应用未被卸载或不在预装可恢复列表内
   * */
  AppNotUninstalledOrNotInList = -2,

  /**
   * 描述：功能异常状态码
   * 原因： 功能异常，出现此项需预置应用管理方定位
   * */
  FunctionError = -3,

  /**
   * 描述：权限异常状态码
   * 原因：权限异常
   * */
  PermissionError = -4
}

export function isNotePadEnable(): boolean {
  try {
    let enabled = bundleManager.isApplicationEnabledSync(BUNDLE_NAME_NOTEPAD);
    LogUtils.i(TAG, `isNotePadEnable: ${enabled}`);
    return enabled;
  } catch (err) {
    LogUtils.e(TAG, `isNotePadEnable error, ${err?.code}, ${err?.message}`);
    return false;
  }
}

export async function isNeedNotePadRestore(context: common.UIAbilityContext): Promise<boolean> {
  if(!context) {
    return false;
  }
  let want: Want = {
    bundleName: BUNDLE_NAME_RESTORE,
    abilityName: ABILITY_NAME_RESTORE,
    parameters: {
      restoresBundleName: BUNDLE_NAME_NOTEPAD
    }
  }
  let ret: number = PopupStatus.UserCancelled;
  try {
    await context.requestDialogService(want).then((result: dialogRequest.RequestResult) => {
      LogUtils.i(TAG, `requestDialogService succeed, result = ${result?.want?.parameters?.resultCode}`);
      ret = Number(result?.want?.parameters?.resultCode);
    });
  } catch (err) {
    LogUtils.e(TAG, `requestDialogService fail. Cause: ${err?.code}, ${err?.message}`);
  }
  return ret !== PopupStatus.RestoreSuccess && ret !== PopupStatus.AppNotUninstalledOrNotInList;
}

export function hasLimFreeSize(): boolean {
  try {
    let freeSize: number = storageStatistics.getFreeSizeSync();
    LogUtils.i(TAG, `get free size is: ${freeSize}`);
    if (freeSize < FREE_SIZE) {
      return true;
    }
  } catch (err) {
    LogUtils.e(TAG, `getFreeSizeSync failed: code: ${err?.code}, message: ${err?.message}`);
    return false;
  }
  return false;
}

// 智能检测需要开启弹窗 找到我的华为->服务->检测与帮助->右上角->设置->智能提醒通知
export function sendStorageClearPopup(): void {
  let eventData: GeneratedObjectLiteralInterface = {
    'faultDescription': DESCRIPTION,
    'faultSuggestion': SUGGESTION,
    'faultSuggestionParams': [FREE_SIZE_700M],
    'publisherBundleName': CALL_BUNDLE_NAME
  };
  let options: commonEventManager.CommonEventPublishData = {
    bundleName: HIVIECARE_BUNDLE_NAME,
    data: JSON.stringify(eventData)
  };
  commonEventManager.publish('hicare.event.SMART_NOTIFICATION', options, publishCB);
  LogUtils.i(TAG, 'publish commonEvent to com.ohos.hiviewcare');
}

function publishCB(err: BusinessError) {
  if (err) {
    LogUtils.e(TAG, `Event publish failed: code: ${err?.code}, message: ${err?.message}`);
  } else {
    LogUtils.i(TAG, 'Event published successfully');
  }
}

interface GeneratedObjectLiteralInterface {
  'faultDescription': string;
  'faultSuggestion': string;
  'faultSuggestionParams': string[];
  'publisherBundleName': string;
}