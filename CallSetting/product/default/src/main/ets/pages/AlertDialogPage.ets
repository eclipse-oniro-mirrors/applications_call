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

import { window } from '@kit.ArkUI';
import { ALERT_DIALOG } from '../common/constant/SatelliteSearchConst';
import AlertDialogManager from '../manager/AlertDialogManager';
import SatelliteSearchManager from '../manager/SatelliteSearchManager';
import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import SatelliteAlertDialog from '../common/dialog/SatelliteAlertDialog';
import SatelliteErrorAlertDialog from '../common/dialog/SatelliteErrorAlertDialog';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { emitter } from '@kit.BasicServicesKit';
import { EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID } from '../common/constant/CallSettingsConstant';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { TrifoldManager } from '../manager/TrifoldManager';

const TAG = 'AlertDialogPage';

@Entry
@Component
struct AlertDialogPage {
  @State closeButtonTime: number = 5;

  private dialogCallback: Function | undefined;

  public satelliteSearchManager?: SatelliteSearchManager;

  private isNewFormFoldPhone = ScreenAdapterUtils.isNewFormFoldPhone();
  private isNewFoldPhoneScreen: boolean = false;

  @State dialogMessage: Resource = $r('app.string.ERROR_CODE_NOT_ACTIVATED_SIM');

  aboutToAppear() {
    SatelliteSearchManager.getInstance().hideWindow(ALERT_DIALOG);
    SatelliteSearchManager.getInstance().hideWindowForPenglai();
    window.findWindow(ALERT_DIALOG)?.setWindowBackgroundColor('#00000000'); //设置子窗口背景透明
    this.satelliteSearchManager = SatelliteSearchManager.getInstance();
    this.addDialogCallback();
    AlertDialogManager.getInstance().createDialogByType();
    if (this.isNewFormFoldPhone) {
      this.isNewFoldPhoneScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
      this.addEmitterListener();
    }
  }

  aboutToDisappear(): void {
    this.removeDialogCallback();
    if (this.isNewFormFoldPhone) {
      this.removeEmitterListener();
    }
  }

  private callback = (data: emitter.EventData): void => {
    this.isNewFoldPhoneScreen = data?.data?.isNewFoldPhoneExternalScreen;
    LogUtils.i(TAG, 'emitter.on, isNewFoldPhoneScreen = ' + this.isNewFoldPhoneScreen);
    this.newFoldPhoneChange();
  }

  addEmitterListener() {
    emitter.on({ eventId: EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID }, this.callback);
  }

  removeEmitterListener() {
    emitter.off(EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID, this.callback);
  }

  newFoldPhoneChange() {
    try {
      if (this.isNewFoldPhoneScreen) {
        window.findWindow(ALERT_DIALOG).hide();
        LogUtils.i(TAG, `hide window`);
      }
    } catch (err) {
      LogUtils.e(TAG, `newFoldPhoneChange error:${err?.code}:${err?.message}`);
    }
  }

  openExpandDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.contact_str_copysim_notification'),
      content: $r('app.string.fold_remind_tips_message'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        fontColor: $r('sys.color.font_emphasize'),
        action: () => {
          this.openExpandDialog.close();
          this.goToUse();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: true,
  })

  goToUse() {
    SatelliteSearchManager.getInstance().stopSatelliteSearchTimer();
    SatelliteSearchManager.getInstance().startSatelliteSearchTimer();
    AlertDialogManager.getInstance().closeAlertDialogWindow();
    ReportUtil.getInstance().reportSatelliteNotConnectedForOneMinute(1);
  }

  simCardDialogController: CustomDialogController = new CustomDialogController({
    builder: SatelliteAlertDialog({
      onCLickGoToUse: () => {
        if (ScreenAdapterUtils.isTrifoldPhone() && !TrifoldManager.getInstance().isTrifold()) {
          LogUtils.i(TAG, `ScreenAdapterUtils.isTrifoldPhone()`);
          this.openExpandDialog.open();
          this.simCardDialogController.close();
        } else {
          this.simCardDialogController.close();
          this.goToUse();
        }
      }
    }),
    autoCancel: false,
    cancel: () => {
      LogUtils.i(TAG, 'simCardDialogController cancel is called')
      this.simCardDialogController.close();
      SatelliteSearchManager.getInstance().stopSatelliteSearchTimer();
      SatelliteSearchManager.getInstance().startSatelliteSearchTimer();
      AlertDialogManager.getInstance().closeAlertDialogWindow();
    }
  })

  satelliteErrorAlertDialogController: CustomDialogController = new CustomDialogController({
    builder: SatelliteErrorAlertDialog({
      dialogMessage: this.dialogMessage
    }),
    customStyle: true,
    alignment: DialogAlignment.Center,
    autoCancel: false,
    cancel: () => {
      LogUtils.i(TAG, 'satelliteErrorAlertDialogController cancel is called')
      this.satelliteErrorAlertDialogController.close();
      AlertDialogManager.getInstance().closeAlertDialogWindow();
    }
  })

  //添加状态变化监听接口
  addDialogCallback() {
    if (this.dialogCallback != undefined) {
      LogUtils.i(TAG, 'addDialogCallback: dialogCallback has been added');
      return;
    }
    this.dialogCallback = ((dialogType: number) => {
      LogUtils.i(TAG, 'satelliteManager.addDialogCallback is called, dialogType = ' + dialogType);
      if (dialogType == AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_TIMEOUT) {
        this.simCardDialogController.open();
      } else if (dialogType == AlertDialogManager.ERROR_CODE_NOT_ACTIVATED_SIM) {
        this.dialogMessage = $r('app.string.ERROR_CODE_NOT_ACTIVATED_SIM');
        this.satelliteErrorAlertDialogController.open();
      } else if (dialogType == AlertDialogManager.ERROR_CODE_NOT_OPENED_ROAMING) {
        this.dialogMessage = $r('app.string.ERROR_CODE_NOT_OPENED_ROAMING');
        this.satelliteErrorAlertDialogController.open();
      } else if (dialogType == AlertDialogManager.ERROR_CODE_NOT_OPENED_TIANDIWINGCARD) {
        this.dialogMessage = $r('app.string.ERROR_CODE_NOT_OPENED_TIANDIWINGCARD');
        this.satelliteErrorAlertDialogController.open();
      } else if (dialogType == AlertDialogManager.ERROR_CODE_NOT_SUPPORT_CARD) {
        this.dialogMessage = $r('app.string.ERROR_CODE_NOT_SUPPORT_CARD');
        this.satelliteErrorAlertDialogController.open();
      } else if (dialogType == AlertDialogManager.ERROR_CODE_OTHERS) {
        this.dialogMessage = $r('app.string.ERROR_CODE_OTHERS');
        this.satelliteErrorAlertDialogController.open();
      }
    });
    AlertDialogManager.getInstance().addDialogCallback(this.dialogCallback)
  }

  //移除状态监听回调接口
  removeDialogCallback() {
    if (this.dialogCallback) {
      AlertDialogManager.getInstance().removeDialogCallback(this.dialogCallback);
      this.dialogCallback = undefined;
    }
  }

  build() {
    NavDestination()
      .width('100%')
      .height('100%')
      .backgroundColor('#00000000')
  }
}