/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

import videoPreview from './videoPreview';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { LogUtils } from '@ohos/common';

const TAG = 'VideoFullScreenPreview';

@Entry
@Component
export struct VideoFullScreenPreview {
  @Provide('pathInfos') pathInfos?: NavPathStack = new NavPathStack();
  public storage = LocalStorage.getShared();
  private isFullScreen = this.storage?.get('isFullScreen') ?? false;
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;

  build() {
    Column() {
      videoPreview();
    }
  }

  onBackPress(): boolean | void {
    LogUtils.i(TAG, `onBackPressed isFullScreen: ${this.isFullScreen}`);
    if (this.isFullScreen) {
      this.session.sendData({ 'back': 'pop' });
      AppStorage.setOrCreate('isFullScreenCancel', true);
      return true;
    }
  }
}

