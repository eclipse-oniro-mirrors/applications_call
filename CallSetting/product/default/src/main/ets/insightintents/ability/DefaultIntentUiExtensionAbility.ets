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
 */

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG: string = 'DefaultIntentUiExtensionAbility';

/**
 * insight intent dependent UiExtensionAbility
 *
 * @since 2024-05-29
 */
export default class DefaultIntentUiExtensionAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    LogUtils.i(TAG, 'onCreate is called');
    AppStorage.setOrCreate('colorMode', this.context.config.colorMode);
    AppStorage.setOrCreate('pageContext', this.context);
  }

  onSessionDestroy(): void {
    LogUtils.i(TAG, 'onDestroy is called');
  }
}