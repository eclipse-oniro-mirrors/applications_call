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

import { LogUtils, Constants, ReportUtil } from '@ohos/common/CommonIndex';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { call } from '@kit.TelephonyKit';

const TAG = 'SatelliteCallDialog';

@CustomDialog
export struct DialogContent {
  private session: UIExtensionContentSession | undefined = AppStorage.get('session');
  controller?: CustomDialogController;
  @Link disconnectCallTimer: number;
  @Link isShowTempLimitDialog: boolean;

  @Styles
  normalStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg_dark'))
  }

  build() {
    Column() {
      Column() {
        Row() {
          Text(this.isShowTempLimitDialog
            ? $r('app.plural.satellite_call_temp_limit_disconnect_tips', this.disconnectCallTimer,
            this.disconnectCallTimer.toString())
            : $r('app.plural.satellite_call_duration_limit_disconnect_tips', this.disconnectCallTimer, '5',
            this.disconnectCallTimer.toString()))
            .width('100%')
            .fontColor($r('sys.color.ohos_id_color_text_primary_dark'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .lineHeight(21)
            .maxLines(3)
        }
        .width('100%')
        .margin({ top:24, bottom: 8 })

        Row() {
          Button($r('app.string.gotIt'))
            .width('100%')
            .height(40)
            .fontColor($r('app.color.satellite_dialog_font_color'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .buttonStyle(ButtonStyleMode.NORMAL)
            .stateStyles({
              normal: this.normalStyles,
              pressed: this.pressedStyles
            })
            .onClick(() => {
              if (this.controller) {
                this.controller.close();
              }
              this.session?.terminateSelf();
              if (this.isShowTempLimitDialog) {
                ReportUtil.getInstance().reportSatelliteClickHighTempInCall();
              }
            })
        }
        .width('100%')
        .height(40)
        .margin({ bottom: $r('sys.float.padding_level8') })
        .justifyContent(FlexAlign.Center)
      }
      .padding({ left: $r('sys.float.padding_level12'), right: $r('sys.float.padding_level12') })
      .width('100%')
      .align(Alignment.Center)
    }
    .borderRadius($r('sys.float.corner_radius_level16'))
    .margin({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
    .backgroundColor($r('app.color.satellite_dialog_background_color'))
  }
}

@Entry
@Component
export default struct SatelliteCallDialog {
  private session: UIExtensionContentSession | undefined = AppStorage.get('session');
  @State satelliteCallDisconnectedTime: number = 30;
  @State isShowTempLimitDialog: boolean = false;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear.');
    let want: Want | undefined = AppStorage.get('want');
    switch (want?.parameters?.dialogReason) {
      case 'SATELLITE_CALL_NOT_SUPPORT_EARPIECE':
        this.openNotSupportEarpieceDialog();
        break;
      case 'SATELLITE_CALL_DURATION_LIMIT':
        this.isShowTempLimitDialog = false;
        this.disconnectSatelliteCallDialog();
        this.startTimer();
        break;
      case 'SATELLITE_CALL_DISCONNECT':
        this.disconnectSatelliteCallDialog();
        this.isShowTempLimitDialog = true;
        this.startTimer();
        break;
      case 'CANNOT_DIAL_SATELLITE_CALL':
        this.cannotDialSatelliteCallDialog();
        this.startTimer();
        break;
      default:
        break;
    }
  }

  startTimer() {
    if (this.satelliteCallDisconnectedTime >= 1) {
      let timeId = setTimeout(() => {
        if (timeId) {
          clearTimeout(timeId);
        }
        this.satelliteCallDisconnectedTime -= 1;
        this.startTimer();
      }, 1000);
    } else {
      LogUtils.i(TAG, 'hang up call');
      this.session?.terminateSelf();
      call.hangUpCall();
      ReportUtil.getInstance().reportSatelliteCallDisconnectWithCause(Constants.UE_SATELLITE_FIVE_MINUTE);
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    AppStorage.delete('want');
    AppStorage.delete('session');
  }

  build() {
  }

  openNotSupportEarpieceController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.satellite_call_not_support_earpiece'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          LogUtils.i(TAG, 'Not registered with call manager service. Unable to use call services.');
          this.session?.terminateSelf();
        }
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
  })

  openNotSupportEarpieceDialog() {
    LogUtils.i(TAG, 'openNotSupportEarpieceDialog.');
    this.openNotSupportEarpieceController.open();
  }

  cannotDialSatelliteCallController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.cannnot_dial_satellite_call_tips'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          LogUtils.i(TAG, 'Not registered with call manager service. Unable to use call services.');
          this.session?.terminateSelf();
          ReportUtil.getInstance().reportSatelliteHighTempDial();
        }
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
  })

  cannotDialSatelliteCallDialog() {
    LogUtils.i(TAG, 'openNotSupportEarpieceDialog.');
    this.cannotDialSatelliteCallController.open();
  }

  disconnectSatelliteCallController: CustomDialogController = new CustomDialogController({
    builder: DialogContent({
      disconnectCallTimer: $satelliteCallDisconnectedTime,
      isShowTempLimitDialog: $isShowTempLimitDialog
    }),
    customStyle: true,
    alignment: DialogAlignment.Center,
    autoCancel: false,
    cancel: () => {
      console.info('Closed callbacks');
    }
  })

  disconnectSatelliteCallDialog() {
    LogUtils.i(TAG, 'openNotSupportEarpieceDialog.');
    this.disconnectSatelliteCallController.open();
  }
}