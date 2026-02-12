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

import WantAgent from '@ohos.app.ability.wantAgent';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import { common } from '@kit.AbilityKit';
import LogUtils from '../common/utils/LogUtils';
import * as Constants from '../common/utils/Constants';
import { BusinessError } from '@kit.BasicServicesKit';

interface WantAgentInfo {
  wants: Array<Want>;
  actionType: WantAgent.OperationType;
  requestCode: number;
  wantAgentFlags?: Array<WantAgent.WantAgentFlags>;
}

const TAG = 'BackgroundTask';

export function startBackgroundRunning() {
  let want: Want = {
    bundleName: Constants.CALL_BUNDLE_NAME,
    abilityName: Constants.CALL_ABILITY_NAME,
  }
  let wantAgentInfo: WantAgentInfo = {
    wants: [want],
    requestCode: 0,
    actionType: WantAgent.OperationType.START_ABILITY,
    wantAgentFlags: [WantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
  };
  WantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj) => {
    backgroundTaskManager.startBackgroundRunning(GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT),
      backgroundTaskManager.BackgroundMode.VOIP, wantAgentObj).then(() => {
      LogUtils.i(TAG, 'startBackgroundRunning succeeded');
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'startBackgroundRunning failed cause:' + JSON.stringify(err));
    });
  }).catch((err: BusinessError) => {
    LogUtils.e(TAG, 'startBackgroundRunning getWantAgent cause:' + JSON.stringify(err));
  })
}

export function stopBackgroundRunning() {
  let context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT);
  if (context) {
    backgroundTaskManager.stopBackgroundRunning(GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT)).then(() => {
      LogUtils.i(TAG, 'stopBackgroundRunning succeeded');
    }).catch(() => {
      LogUtils.e(TAG, 'stopBackgroundRunning failed');
    });
  }
}