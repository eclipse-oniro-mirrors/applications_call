/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import StaticSubscriberExtensionAbility from '@ohos.application.StaticSubscriberExtensionAbility';
import type commonEventManager from '@ohos.commonEventManager';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogUtil } from '../util/LogUtil';
import { JSON } from '@kit.ArkTS';

const TAG = 'StaticSubscriber';

export default class StaticSubscriber extends StaticSubscriberExtensionAbility {
  onReceiveEvent(event: commonEventManager.CommonEventData): void {
    if (event.event === 'usual.event.OPERATOR_CONFIG_CHANGED') {
      let want: Want = {
        bundleName: 'com.ohos.communicationsetting',
        abilityName: 'SettingsSearchServiceExtAbility'
      };
      this.context.startAbility(want).then(() => {
        LogUtil.info(TAG, 'start SettingsSearchServiceExtAbility succeed');
      }).catch((err: BusinessError) => {
        LogUtil.info(TAG, 'start SettingsSearchServiceExtAbility failed:' + JSON.stringify(err));
      });
    }
  }
}