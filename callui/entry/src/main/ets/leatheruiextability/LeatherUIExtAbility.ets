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
import { common, UIExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration';

const TAG: string = 'LeatherUIExtAbility';

export default class LeatherUIExtAbility extends UIExtensionAbility {
  onCreate(): void {
    console.info(TAG, 'UIExtensionAbility onCreate');
  }

  onDestroy(): void {
    console.info(TAG, 'UIExtensionAbility onDestroy');
  }

  onForeground(): void {
    console.info(TAG, 'UIExtensionAbility onForeground');
  }

  onBackground(): void {
    console.info(TAG, 'UIExtensionAbility onBackground');
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    let param: Record<string, UIExtensionContentSession> = {
      'session': session
    };
    let storage: LocalStorage = new LocalStorage(param);

    try {
      session.loadContent('pages/LeatherPage', storage);
    } catch (e) {
      console.info(TAG, `UI Extension Content Session Failed: ${e}`);
    }
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    console.info(TAG, 'UIExtensionAbility onSessionDestroy');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
  }
}