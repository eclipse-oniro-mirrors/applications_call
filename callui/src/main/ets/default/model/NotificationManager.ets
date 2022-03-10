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

/**
 * @file: notification manager
 */

import wantAgent from '@ohos.wantAgent';
import notification from '@ohos.notification';
import commonEvent from '@ohos.commonevent';
import callStateConst from '../common/constant/CallStateConst.ets';
import HiLog from '../common/utils/Hilog.ets';
import resourceManager from '@ohos.resourceManager';

const TAG = "NotificationManager";
const ID = 0;
const CALL_BUNDLE_NAME = 'com.ohos.callui';
const CALL_ABILITY_NAME = 'com.ohos.callui.MainAbility';

//const wantAgent = {
//  getWantAgent: (obj) => Promise.resolve(obj),
//};

const notificationRequest = {
  content: {
    contentType: notification.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
    longText: {
      title: '',
      text: '',
      longText: '',
      briefText: '',
      expandedTitle: ''
    }
  },
  id: ID,
  wantAgent: null,
  actionButtons: [],
  slotType: notification.SlotType.OTHER_TYPES,
  deliveryTime: new Date().getTime()
};

const textMap =
  {
    'answer': $r('app.string.answer'),
    'reject': $r('app.string.reject'),
    'hangUp': $r('app.string.hangUp'),
    'mute': $r('app.string.mute'),
    'callHold': $r('app.string.callHold'),
  };

export default class NotificationManager {
  /**
   * Send notification
   *
   * @param { Object } text - text info
   *
   * @param { Object } callData - call data
   *
   * @param { FUnction } $t - i18n format
   */
  async sendNotification(text, callData) {
    const {callState, callId} = callData;
//    const mapObj = new Map([
//      [callStateConst.CALL_STATUS_INCOMING, ['answer', 'reject']],
//      [callStateConst.CALL_STATUS_ACTIVE, ['hangUp', 'mute']],
//      [callStateConst.CALL_STATUS_HOLDING, ['hangUp', 'callHold']],
//      [callStateConst.CALL_STATUS_ALERTING, ['hangUp']],
//      [callStateConst.CALL_STATUS_DIALING, ['hangUp']],
//      [callStateConst.CALL_STATUS_WAITING, ['answer', 'reject']]
//    ]);
    const actionBtnKeys = this.getMapObj(callState) || [];
    const {START_ABILITY, SEND_COMMON_EVENT} = wantAgent.OperationType;
    const wantAgentObj = await this.getWantAgent(callData, START_ABILITY);
    notificationRequest.wantAgent = wantAgentObj;
    notificationRequest.actionButtons = [];
    if (actionBtnKeys.length) {
      for (const key of actionBtnKeys) {
        const data = {
          callId, btnType: key
        };
        const wantAgentObj = await this.getWantAgent(data, SEND_COMMON_EVENT);
        resourceManager.getResourceManager((error, mgr) => {
          if (error != null) {
            return;
          }
          mgr.getString(textMap[key].id, (error, value) => {
            if (error != null) {
            } else {
              notificationRequest.actionButtons.push({
                title: value,
                wantAgent: wantAgentObj
              });
            }
          });
        });
      }
    }
    Object.assign(notificationRequest.content.longText, {
      title: text,
      expandedTitle: text
    });
    notification.publish(notificationRequest);
    HiLog.i(TAG, "sendNotification end : ")
  }

  //todo
  getMapObj(callState) {
    if (callState===callStateConst.CALL_STATUS_INCOMING) {
      return ['answer', 'reject']
    }
    if (callState===callStateConst.CALL_STATUS_ACTIVE) {
      return ['hangUp', 'mute']
    }
    if (callState===callStateConst.CALL_STATUS_HOLDING) {
      return ['hangUp', 'callHold']
    }
    if (callState===callStateConst.CALL_STATUS_ALERTING) {
      return ['hangUp']
    }
    if (callState===callStateConst.CALL_STATUS_DIALING) {
      return ['hangUp']
    }
    if (callState===callStateConst.CALL_STATUS_WAITING) {
      return ['answer', 'reject']
    }
  }

  /**
   * get want agent
   *
   * @param { object } data - call data
   *
   * @param { number } operationType - type
   */
  getWantAgent(data, operationTypes) {
    return wantAgent.getWantAgent({
      wants: [{
                deviceId: 'receive',
                bundleName: CALL_BUNDLE_NAME,
                abilityName: CALL_ABILITY_NAME,
                uri: '',
                type: 'phone',
                action: 'callui.event.click',
                parameters: data,
                entities: []
              }],
      requestCode: 0,
      operationType: operationTypes,
      wantAgentFlags: [wantAgent.WantAgentFlags.ONE_TIME_FLAG]
    });
  }

  /**
   * Cancel notice
   */
  cancelNotification() {
    HiLog.i(TAG, "cancelNotification : %s")
    notification.cancel(ID).then((res) => {
      HiLog.i(TAG, "notify.cancel res data : %s")
    }).catch((err) => {
      HiLog.i(TAG, "notify.cancel err data : %s" + JSON.stringify(err))
    });
  }

  /**
   * send capsule notification
   *
   * @param {Object} callData - call data
   *
   * @param {boolean} isBackground - is background
   */
  sendCapsuleNotification(callData, isBackground) {
    HiLog.i(TAG, "sendCapsuleNotification isBackground : %s"  + JSON.stringify(isBackground))
    callData.startTime = (callData.startTime)*1000
    HiLog.i(TAG, "sendCapsuleNotification callData.startTime  : ")
    const {callState, startTime} = callData;
    commonEvent.publish('CAPSULE_EVENT_CALL_UI', {
      bundleName: 'com.ohos.callui',
      isOrdered: false,
      data: JSON.stringify({
        callState,
        startTime,
        isBackground,
        wantBundleName: CALL_BUNDLE_NAME,
        wantAbilityName: CALL_ABILITY_NAME
      })
    }, (res) => {
      HiLog.i(TAG, "callUI app commonEvent.publish CAPSULE_EVENT_CALL_UI callback res  : %s")
    });
  }
}