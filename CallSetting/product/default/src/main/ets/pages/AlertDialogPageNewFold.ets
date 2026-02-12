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

import NewFoldScreenAlertDialogManager from '../manager/NewFoldScreenAlertDialogManager';
import { promptAction, window } from '@kit.ArkUI';
import { NEW_FOLD_ALERT_DIALOG, SATELLITE_TOAST_DURATION_NEW_FOLD } from '../common/constant/SatelliteSearchConst';
import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';

const TAG = 'AlertDialogPageNewFold';

@Entry
@Component
struct AlertDialogPageNewFold {
  private mNewFoldScreenAlertDialogManager = NewFoldScreenAlertDialogManager.getInstance();

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    try {
      window.findWindow(NEW_FOLD_ALERT_DIALOG)?.setWakeUpScreen(true);
      this.showToast();
    } catch (e) {
      LogUtils.e(TAG, `aboutToAppear error:${e}`);
    }
  }

  private showToast() {
    promptAction.showToast({
      message: $r('app.string.satellite_new_fold_un_support_toast'),
      duration: SATELLITE_TOAST_DURATION_NEW_FOLD
    });
    // 请展开手机使用卫星通信打点
    ReportUtil.getInstance().reportSatelliteExpandToUseToast();

    // 自动关闭窗口-5s后
    this.mNewFoldScreenAlertDialogManager.closeNewFoldAlertDialogWindowDelay(SATELLITE_TOAST_DURATION_NEW_FOLD);
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  build() {
    Row() {
    }
    .visibility(Visibility.None)
    .width('100%')
    .height('100%')
  }
}