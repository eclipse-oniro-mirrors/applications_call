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

import { LogUtils } from '@ohos/common/CommonIndex';
import { getSystemRingtoneApi } from '../model/SystemSoundManagerApi';
import common from '@ohos.app.ability.common';
import { systemSoundManager } from '@kit.AudioKit';
import { BusinessError, commonEventManager} from '@kit.BasicServicesKit';

const TAG = 'CommonFun';

export const CALL_UI_BUNDLE_NAME = 'com.ohos.callui';
const EVENT_SATELLITE_CALL_HANGUP = 'usual.event.satellite.call.hangup';

function changeFormat(item: string): string {
  let newStr: string = item.substring(0, item.lastIndexOf('.'));
  let lastSlashIndex: number = newStr.lastIndexOf('/');
  let result: string = newStr.substring(lastSlashIndex + 1);
  let newResult: string = result.split('_').join(' ');
  return newResult;
}

export function getSystemRingtone(context: common.UIAbilityContext, slotId: number,
  callBack: (ringName: string) => void) {
  LogUtils.i(TAG, `do getSystemRingtone start`);

  getSystemRingtoneApi(context, slotId, (data: string) => {
    LogUtils.i(TAG, `getSystemRingtoneApi back, slotId: ${slotId}`);
    if (callBack) {
      callBack(data);
    }
  })
}

export async function getRingToneAttrsArray(context: common.UIAbilityContext, callBack: (attrsArray:
  systemSoundManager.ToneAttrsArray) => void) {
  let sysIns: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
  try {
    sysIns.getRingtoneAttrList(context,
      systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_0).then((arrs: systemSoundManager.ToneAttrsArray) => {
      callBack(arrs);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getRingToneAttrsArray err->${JSON.stringify(err)}`);
      callBack([]);
    });
  } catch (error) {
    LogUtils.e(TAG, 'getRingToneAttrsArray catch error: ' + (error as BusinessError).message);
    callBack([]);
  }
}

export async function getRingToneName(context: common.UIAbilityContext, slotId: number,
  toneAttrsArray: systemSoundManager.ToneAttrsArray): Promise<string> {
  let ringtoneValue: string = '';
  if (toneAttrsArray !== undefined && toneAttrsArray.length > 0) {
    let ringToneType: systemSoundManager.RingtoneType = slotId === 0 ?
    systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_0 : systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_1;
    try {
      let ringToneUri: string | undefined = await systemSoundManager.getSystemSoundManager()?.getRingtoneUri(context,
        ringToneType);
      let isCheckedIndex = toneAttrsArray.findIndex((item) => {
        return item.getUri() === ringToneUri;
      })
      if (isCheckedIndex !== undefined && isCheckedIndex !== -1) {
        ringtoneValue = toneAttrsArray && toneAttrsArray[isCheckedIndex].getTitle();
        LogUtils.i(TAG, 'getRingToneName success, slotId: ' + slotId);
      } else {
        if (ringToneUri === 'no_ring_sound') {
          ringtoneValue = await context.resourceManager.getStringSync($r('app.string.Apn_enum_None'));
        }
      }
    } catch (err) {
      LogUtils.e(TAG, `getRingtoneUri error, code:${err?.code} message:${err?.message}`);
    }
    return ringtoneValue;
  } else {
    LogUtils.e(TAG, `toneAttrsArray is empty.`)
    return ringtoneValue;
  }
}

export async function createSubscriber(
  events: Array<string>): Promise<commonEventManager.CommonEventSubscriber | undefined> {
  let CONFIG_CHANGE_EVENT: commonEventManager.CommonEventSubscribeInfo = {
    events: events,
  }
  let subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined
  try {
    subscriber = await commonEventManager.createSubscriber(CONFIG_CHANGE_EVENT);
  } catch (err) {
    LogUtils.e(TAG, `createSubscriber err: code is ${err.code}, message is ${err.message}`);
  }
  return subscriber;
}

export function subscribeEvent(callBack: Function, subscriber?: commonEventManager.CommonEventSubscriber) {
  try {
    if (!subscriber) {
      LogUtils.w(TAG, 'subscribe fail with invalid subscriber');
      return;
    }
    commonEventManager.subscribe(subscriber, (err, eventData: commonEventManager.CommonEventData) => {
      if (err) {
        LogUtils.e(TAG, `subscribe receve err: code is ${err?.code}, message is ${err?.message}`);
      } else {
        LogUtils.i(TAG, `{ ${eventData?.event}, ${eventData?.bundleName}, ${eventData?.data}, ${eventData?.code} }`);
        callBack(eventData?.data);
      }
    });
  } catch (err) {
    LogUtils.e(TAG, `subscribe err: code is ${err.code}, message is ${err.message}`);
  }
}

export function unSubscribeEvent(subscriber?: commonEventManager.CommonEventSubscriber): void {
  if (!subscriber) {
    LogUtils.w(TAG, 'unSubscribeConfigChange fail with invalid subscriber');
    return;
  }
  try {
    commonEventManager.unsubscribe(subscriber);
  } catch (err) {
    LogUtils.e(TAG, `unsubscribe err: code is ${err.code}, message is ${err.message}`);
  }
}

export function publishEvent(packageName: string, event: string, value: string): void {
  LogUtils.i(TAG, `publishEvent `);
  let options: commonEventManager.CommonEventPublishData = {
    code: 0,
    bundleName: packageName,
    data: value
  }
  commonEventManager.publish(event, options, (err) => {
    if (err) {
      LogUtils.e(TAG, `publish failed, code is ${err.code}.`);
    } else {
      LogUtils.i(TAG, `publish success`);
    }
  })
}

export function publishSatelliteCallHangupEvent() {
  publishEvent(CALL_UI_BUNDLE_NAME, EVENT_SATELLITE_CALL_HANGUP, '');
}