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
 *
 * A common util class for all
 */

import sim from '@ohos.telephony.sim';
import { LogUtils } from '../../../../CommonIndex';
import { observer } from '@kit.TelephonyKit';
import { commonEventManager, systemParameterEnhance } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';

const TAG: string = 'CommonUtil';
const SIM_ID_INVALID_VALUE: number = -1;
const EVENT_OPERATOR_CONFIG_CHANGED: string = 'usual.event.OPERATOR_CONFIG_CHANGED';

/**
 * get Sim Card SubID for the slotId
 * Max sim Count is ${sim.getMaxSimCount()}
 * @returns SIM ID number , non is -1
 */
export async function getSubId(slotId: number): Promise<number> {
  try {
    if (slotId < 0 || slotId > sim.getMaxSimCount()) {
      LogUtils.e(TAG, `getSubId slotId is :${slotId}, Max sim Count is ${sim.getMaxSimCount()}`);
      return SIM_ID_INVALID_VALUE;
    }
    let info = await sim.getSimAccountInfo(slotId);
    if (info) {
      LogUtils.i(TAG, `getSubId result is success`)
      return info.simId;
    }
  } catch (error) {
    LogUtils.e(TAG, 'getSubId catch:' + JSON.stringify(error));
  }
  return SIM_ID_INVALID_VALUE;
}

export function registerCallStateChange(slotId: number = 0, callBack: Function) {
  let option: observer.ObserverOptions = {
    slotId: slotId
  };
  try {
    return observer.on('callStateChange', option, (data: observer.CallStateInfo) => {
      callBack(data);
    });
  } catch (err) {
    LogUtils.e(TAG, 'registerCallStateChange err' + err?.code);
  }
}

export function unRegisterCallStateChange() {
  try {
    return observer.off('callStateChange', () => {
      LogUtils.i(TAG, 'unRegisterCallStateChange');
    });
  } catch (err) {
    LogUtils.e(TAG, 'unRegisterCallStateChange err' + err?.code);
  }
}

export async function createSubscriber(): Promise<commonEventManager.CommonEventSubscriber | undefined> {
  let CONFIG_CHANGE_EVENT: commonEventManager.CommonEventSubscribeInfo = {
    events: [EVENT_OPERATOR_CONFIG_CHANGED],
  }
  let subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined
  try {
    subscriber = await commonEventManager.createSubscriber(CONFIG_CHANGE_EVENT);
  } catch (err) {
    LogUtils.e(TAG, `createSubscriber err:${JSON.stringify(err)}`);
  }
  return subscriber
}

export function subscribeConfigChange(callBack: Function, subscriber?: commonEventManager.CommonEventSubscriber) {
  try {
    if (!subscriber) {
      LogUtils.w(TAG, 'subscribe fail with invalid subscriber');
      return;
    }
    commonEventManager.subscribe(subscriber, (err, eventData: commonEventManager.CommonEventData) => {
      LogUtils.i(TAG, `subscribe receve`);
      callBack(eventData);
    });
  } catch (err) {
    LogUtils.e(TAG, `subscribe err:${JSON.stringify(err)}`);
  }
}

export function unSubscribeConfigChange(subscriber?: commonEventManager.CommonEventSubscriber): void {
  if (!subscriber) {
    LogUtils.w(TAG, 'unSubscribeConfigChange fail with invalid subscriber');
    return;
  }
  try {
    commonEventManager.unsubscribe(subscriber);
  } catch (err) {
    LogUtils.e(TAG, `unsubscribe err:${JSON.stringify(err)}`);
  }
}

export function registerSimStateChange(slotId: number = 0, callBack: Function): void {
  LogUtils.i(TAG, 'registerSimStateChange on slot ' + slotId);
  try {
    observer.on('simStateChange', {
      slotId: slotId
    }, (data: observer.SimStateData) => {
      LogUtils.i(TAG, 'recv new sim state:' + JSON.stringify(data))
      callBack(data);
    });
  } catch (err) {
    LogUtils.e(TAG, `on simStateChange err:${JSON.stringify(err)}`);
  }
}

export function unRegisterSimStateChange(): void {
  try {
    observer.off('simStateChange', () => {
      LogUtils.i(TAG, 'unRegisterSimStateChange ok');
    });
  } catch (err) {
    LogUtils.e(TAG, `off simStateChange err:${JSON.stringify(err)}`);
  }
}

export function getSystemParam(parameter: string, defaultValue: string): string {
  try {
    return systemParameterEnhance.getSync(parameter, defaultValue);
  } catch (err) {
    LogUtils.e(TAG, 'getSystemParam failed');
    return defaultValue;
  }
}

/**
 * get fold status
 *
 * @return {FoldStatus}
 */
export function getFoldStatus(): display.FoldStatus {
  let result: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  try {
    result = display.getFoldStatus();
  } catch (err) {
    LogUtils.e(TAG, `getFoldStatus failed. code: ${err?.code}, message: ${err?.message}`);
  }
  LogUtils.i(TAG, `getFoldStatus result: ${result}`);
  return result;
}
