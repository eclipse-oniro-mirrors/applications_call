/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../common/utils/LogUtils';
import CallDataManager from '../model/CallDataManager';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import DefaultCallData from '../common/struct/TypeUtils';
import { HiCarManager } from '../model/HiCarManager';

const TAG = 'CallUIHiCarMainAbility';

export default class HiCarMainAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'onCreate');
    if (CallDataManager.getInstance().callList.length === 0) {
      LogUtils.i(TAG, 'no calls. shut down.');
      // this.context.terminateSelf().then(() => {
      //   LogUtils.i(TAG, 'terminateSelf success');
      // }, (err: BusinessError) => {
      //   LogUtils.i(TAG, `terminateSelf failed, code is ${err.code}, message is ${err.message}`);
      // });
      return;
    }
    GlobalContextHelper.getContext().set<common.UIAbilityContext>(Constants.HICAR_CALL_ABILITY_CONTEXT, this.context);
    AppStorage.setOrCreate<Array<DefaultCallData>>(Constants.CALL_LIST, CallDataManager.getInstance().callList);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    GlobalContextHelper.getContext().set<window.Window>(Constants.HICAR_WINDOW, windowStage.getMainWindowSync());
    windowStage.loadContent('pages/indexInHiCar', (err, data) => {
      if (err && err.code) {
        LogUtils.e(TAG, `Failed to load the content. Cause: ${err.message}`);
        return;
      }
    });
  }

  onWindowStageDestroy(): void {
    LogUtils.i(TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    LogUtils.i(TAG, 'onForeground');
  }

  onBackground(): void {
    LogUtils.i(TAG, 'onBackground');
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy');
    HiCarManager.release();
  }
}