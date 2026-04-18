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

import AbilityStage from '@ohos.app.ability.AbilityStage';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { LogUtil } from '../util/LogUtil';
import { IsWiFiOnly } from '../util/DeviceUtil';

const TAG = 'MyAbilityStage';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    LogUtil.info(TAG, 'onCreate');
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (e) {
      LogUtil.error(TAG, `set color mode error code: ${e?.code}, error message:${e?.message}`);
    }
    let showNetworkChoice = !IsWiFiOnly();
    AppStorage.setOrCreate<boolean>('showNetworkChoice', showNetworkChoice);
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'onDestroy');
  }
}