/*
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

import { BusinessError } from '@ohos.base';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import LogUtils from '../utils/HiLog';
import CommonEventManager from '@ohos.commonEventManager';

const TAG = 'OnScreenOff';
export const SCREEN_OFF_EVENT = 'usual.event.SCREEN_OFF'; // 设备屏幕关闭且设备处于睡眠状态
export const SCREEN_UNLOCKED_EVENT = 'usual.event.SCREEN_UNLOCKED'; // 屏幕解锁的公共事件

export default class OnScreenOff {
  public static subscriber: CommonEventManager.CommonEventSubscriber | null = null;

  public static aboveScreen(isShow: boolean) {
    try {
      let getCtx = EmergencyGlobalContextHelper.getContext();
      let windowStage = getCtx.getValue<window.WindowStage>(Constants.EMERGENCY_CALL_WINDOW_STAGE);
      if (windowStage) {
        let window = windowStage.getMainWindowSync();
        if (window) {
          LogUtils.i(TAG, 'setShowOnLockScreen, isShow: ' + isShow);
          windowStage.setShowOnLockScreen(isShow);
        }
      }
    } catch (e) {
      LogUtils.e(TAG, 'aboveScreen: ' + JSON.stringify(e));
    }
  }

  public static terminateSelf(callBack?: Function) {
    try {
      let getCtx = EmergencyGlobalContextHelper.getContext();
      let uiAbCtx = getCtx.getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT);
      uiAbCtx?.terminateSelf().then(() => {
        LogUtils.i(TAG, 'terminateSelf success');
        if (callBack) {
          callBack();
        }
      }, (err: BusinessError) => {
        if (callBack) {
          callBack();
        }
        LogUtils.i(TAG, `terminateSelf failed: ${err.message}`);
      });
    } catch (error) {
      LogUtils.i(TAG, `terminateSelf failed: ${error.message}`);
    }
  }

  public static async createSubscriber() {
    let subscribeInfo: CommonEventManager.CommonEventSubscribeInfo = {
      events: [SCREEN_OFF_EVENT, SCREEN_UNLOCKED_EVENT]
    };
    try {
      OnScreenOff.subscriber = await CommonEventManager.createSubscriber(subscribeInfo);
    } catch (err) {
      LogUtils.i(TAG, `createSubscriberFail: ${JSON.stringify(err.message)}`);
    }

  }

  public static subscribeEvent(callback?: Function) {
    CommonEventManager.subscribe(OnScreenOff.subscriber,
      (error: BusinessError, commonEventData: CommonEventManager.CommonEventData) => {
        if (commonEventData.event === SCREEN_OFF_EVENT) {
          if (callback) {
            callback(SCREEN_OFF_EVENT);
          }
        } else if (commonEventData.event === SCREEN_UNLOCKED_EVENT) {
          if (callback) {
            callback(SCREEN_UNLOCKED_EVENT);
          }
        }
      })
  }

  public static subscribe(callback?: Function) {
    if (OnScreenOff.subscriber) {
      OnScreenOff.subscribeEvent(callback)
    }
  }

  public static unsubscribe() {
    if (!OnScreenOff.subscriber) {
      return;
    }
    CommonEventManager.unsubscribe(OnScreenOff.subscriber, (err: BusinessError, res) => {
      if (err?.code != null) {
        LogUtils.w(TAG, 'CommonEventManager.unsubscribe err: %s' + JSON.stringify(err));
      } else {
        OnScreenOff.subscriber = null;
        LogUtils.i(TAG, 'CommonEventManager.unsubscribe success!!');
      }
    });
  }

  public static initSubscriber(callback?: Function) {
    OnScreenOff.createSubscriber().then(() => {
      LogUtils.i(TAG, 'createSubscriberThen');
      OnScreenOff.subscribe(callback);
    })
  }
}