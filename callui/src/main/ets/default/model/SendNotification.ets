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
 * @file: send notification
 */

import wantAgent from '@ohos.wantAgent';
import notify from '@ohos.notification';
import HiLog from '../common/utils/Hilog.ets';

const TAG = "SendNotification";

export default class SendNotification {
  private id: number = 1;
  private static sSendNotification: SendNotification = null;
  private notificationRequest: any = {
    content: {
      contentType: notify.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: 'voice call',
        text: '',
      },
    },
    slotType: notify.SlotType.OTHER_TYPES,
    deliveryTime: new Date().getTime()
  };

  public static getInstance(): SendNotification {
    if (SendNotification.sSendNotification == null) {
      SendNotification.sSendNotification = new SendNotification()
    }
    return SendNotification.sSendNotification;
  }

  public async sendNotification(text) {
    const res = await wantAgent.getWantAgent({
      wants: [{
                bundleName: 'com.ohos.callui',
                abilityName: 'com.ohos.callui.MainAbility',
              }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.ONE_TIME_FLAG],
    });
    Object.assign(this.notificationRequest, {wantAgent: res});
    this.notificationRequest.content.normal.title = text;
    notify.publish(this.notificationRequest);
  }

  public cancelNotification() {
    notify.cancel(this.id).then((res) => {
      HiLog.i(TAG, "notify.cancel res data : %s");
    }).catch((err) => {
      HiLog.i(TAG, "notify.cancel err data : %s" + JSON.stringify(err))
    });
  }
}
