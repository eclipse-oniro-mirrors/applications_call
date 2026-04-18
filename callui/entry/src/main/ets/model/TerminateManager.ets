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

import { window } from '@kit.ArkUI';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import { common } from '@kit.AbilityKit';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'TerminateManager';

export function removeWindowListener() {
  try {
    LogUtils.i(TAG, `removeWindowListener`);
    let windowStage = GlobalContextHelper.getContext().getValue<window.Window>(Constants.WINDOW);
    if (windowStage) {
      windowStage.off('windowSizeChange');
      windowStage.off('avoidAreaChange');
      windowStage.off('windowStatusChange');
      GlobalContextHelper.getContext().remove(Constants.WINDOW);
    }
  } catch (err) {
    LogUtils.e(TAG, 'removeWindowListener err :' + JSON.stringify(err));
  }
}

export function terminateSelf(context: string) {
  GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(context)?.
  terminateSelf().then(() => {
    LogUtils.i(TAG, `terminateSelfCallBack ${context}`);
    GlobalContextHelper.getContext().remove(context);
  });
}