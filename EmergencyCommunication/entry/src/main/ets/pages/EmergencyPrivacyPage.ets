/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import LogUtils from '../utils/HiLog';
import EmergencyPrivacyStatementOobe from './EmergencyPrivacyStatementOobe';

const storage: LocalStorage = LocalStorage.getShared();
const TAG = 'EmergencyPrivacyPage';

@Entry
@Component
struct EmergencyPrivacyPage {
  public static readonly ECC_PRIVACY_OOBE = 'privacyStatementOobe'
  build() {
    Column() {
      PrivacyDefault()
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct PrivacyDefault {
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  private session: UIExtensionContentSession | undefined = storage.get<UIExtensionContentSession>('session');

  @Builder
  myRouter(name: string) {
    if (name === EmergencyPrivacyPage.ECC_PRIVACY_OOBE) {
      EmergencyPrivacyStatementOobe();
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.pathInfos.pushPath({ name: EmergencyPrivacyPage.ECC_PRIVACY_OOBE }, false);
  }

  build() {
    Navigation(this.pathInfos)
      .hideTitleBar(true)
      .navDestination(this.myRouter)
      .mode(NavigationMode.Stack)
  }
}
