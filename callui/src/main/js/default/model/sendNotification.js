/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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

let id = 1;
const notificationRequest = {
    content:{
        contentType: notify.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
            title: 'voice call',
            text: '',
        },
    },
    id,
    slotType: notify.SlotType.OTHER_TYPES,
    deliveryTime: new Date().getTime()
};

export async function sendNotification(text) {
    const res = await wantAgent.getWantAgent({
        wants: [{
            bundleName: 'com.ohos.callui',
            abilityName: 'com.ohos.callui.MainAbility',
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.Flags.ONE_TIME_FLAG],
    });
    Object.assign(notificationRequest, {wantAgent: res});
    notificationRequest.content.normal.title = text;
    notify.publish(notificationRequest);
}

export function cancelNotification() {
    notify.cancel(id).then((res) => {
        console.log('notify.cancel res data: ' + JSON.stringify(res));
    }).catch((err) => {
        console.log('notify.cancel err data: ' + JSON.stringify(err));
    });
}