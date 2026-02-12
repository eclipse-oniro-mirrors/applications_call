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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import { Configuration } from '@ohos.app.ability.Configuration';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import { LogUtil } from '../util/LogUtil';
import { PAGE_CONTEXT } from '../constants/Constants';

const TAG: string = 'TrafficStatisticsAbility : ';

export default class TrafficStatisticsAbility extends UIExtensionAbility {
  private systemLanguage: string | undefined;

  onCreate(): void {
    LogUtil.info(`${TAG} Ability onCreate`);
    this.systemLanguage = this.context?.config?.language;
    AppStorage.setOrCreate(PAGE_CONTEXT, this.context);
  }

  onDestroy(): void {
    LogUtil.info(`${TAG} Ability onDestroy`);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtil.info(`${TAG} onSessionCreate, want: ${want}`);
    const storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('session', session);
    session.loadContent('pages/ApplicationTrafficPage', storage);
  }

  onWindowStageDestroy(): void {
    LogUtil.info(`${TAG} Ability onWindowStageDestroy`);
  }

  onForeground(): void {
    LogUtil.info(`${TAG} Ability onForeground`);
  }

  onBackground(): void {
    LogUtil.info(`${TAG} Ability onBackground`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtil.info(`${TAG} onConfigurationUpdate`);
    if (this.systemLanguage !== newConfig.language) {
      this.systemLanguage = newConfig.language;
      this.context?.eventHub?.emit('LANGUAGE_CHANGE_EVENT');
    }
  }
}
