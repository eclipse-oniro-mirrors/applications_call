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

import { LogUtils } from '@ohos/common/CommonIndex';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import Want from '@ohos.app.ability.Want';
import { Configuration, UIExtensionContentSession } from '@kit.AbilityKit';
import { extensionProperties } from './VideoRingtoneSettingsAbility';
import { pathParams } from '../pages/videoRingtone/VideoRingtonePage';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import SplitScreenManager from '../model/SplitScreenManager';
import { display } from '@kit.ArkUI';

const TAG = 'VideoRingtoneViewAbility';

export default class VideoRingtoneViewAbility extends UIExtensionAbility {
  public storage?: LocalStorage;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    LogUtils.i(TAG, 'onSessionCreate');
    if (want?.parameters && want?.parameters['wantParameters']) {
      let wantParameters = want?.parameters['wantParameters'] as Record<string, Object> ?? '';
      let pathParams = wantParameters['pathParams'] as pathParams ?? undefined;
      let simCard = wantParameters['simCard'] as string ?? '';
      this.storage = new LocalStorage({
        session: session,
        pathParams: pathParams,
        simCard: simCard,
        isFullScreen: true
      } as extensionProperties);
    }
    session.sendData({ 'hideStatusBar': false });
    session.loadContent('pages/videoRingtone/VideoFullScreenPreview', this.storage);
    this.addWindowSizeChangeListener(session);
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'Ability onDestroy');
    AppStorage.delete('VideoOnBackground');
  }

  onForeground(): void {
    LogUtils.i(TAG, 'Ability onForeground');
    AppStorage.setOrCreate('VideoOnBackground', false);
  }

  onBackground(): void {
    LogUtils.i(TAG, 'Ability onBackground');
    AppStorage.setOrCreate('VideoOnBackground', true);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtils.i(TAG, 'Ability onConfigurationUpdate, config');
  }

  private addWindowSizeChangeListener(session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'addWindowSizeChangeListener is called');
    try {
      let extensionWindow = session?.getUIExtensionHostWindowProxy();
      this.mCallColumnUtils.updateBreakpoint(-1);
      SplitScreenManager.getInstance()
        .updateScreenSize(display.getDefaultDisplaySync().width, display.getDefaultDisplaySync().height);
      extensionWindow.on('windowSizeChange', (windowSize) => {
        try {
          SplitScreenManager.getInstance()
            .updateScreenSize(display.getDefaultDisplaySync().width, display.getDefaultDisplaySync().height);
          this.mCallColumnUtils.updateBreakpoint(-1);
        } catch (err) {
          LogUtils.e(TAG, `onWindowStageCreate err = ${err?.code}`);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `onSessionCreate err = ${err?.code}`);
    }
  }
}
