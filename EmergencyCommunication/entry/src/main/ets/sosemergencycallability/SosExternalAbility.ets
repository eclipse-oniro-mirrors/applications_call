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
import { UIAbility } from '@kit.AbilityKit';
import LogUtils from '../utils/HiLog';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { display } from '@kit.ArkUI';

const TAG = 'SosExternalAbility';

export default class SosExternalAbility extends UIAbility {
  private foldChangeCallBack = (foldStatus: display.FoldStatus) => {
    LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
    try {
      if (foldStatus !== display.FoldStatus.FOLD_STATUS_FOLDED) {
        this.context?.terminateSelf().then(() => {
          LogUtils.i(TAG, 'SosExternalAbility terminateSelf');
        });
      }
    } catch (error) {
      LogUtils.e(TAG, 'SosExternalAbility terminateSelf fail');
    }
  };

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    LogUtils.i(TAG, 'onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtils.i(TAG, 'onWindowStageCreate');
    windowStage.setShowOnLockScreen(true);
    windowStage.loadContent('pages/SosExternalPage', (err, data) => {
      if (err.code) {
        LogUtils.e(TAG, 'Failed to load the content. Cause:' + JSON.stringify(err));
        return;
      }
      LogUtils.i(TAG, 'Succeeded in loading the content.');
    });

    // remove fold listener and then add fold listener, make sure only add one fold listener.
    this.removeFoldStatusListener();
    this.addFoldStatusListener();
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy');
    this.removeFoldStatusListener();
  }

  addFoldStatusListener(): void {
    try {
      display.on('foldStatusChange', this.foldChangeCallBack);
      LogUtils.i(TAG, 'addFoldStatusListener success');
    } catch (exception) {
      LogUtils.e(TAG, 'foldStatusChange exception = ' + JSON.stringify(exception));
    }
  }

  removeFoldStatusListener(): void {
    try {
      display.off('foldStatusChange', this.foldChangeCallBack);
      LogUtils.i(TAG, 'removeFoldStatusListener success');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
  }
};