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
import { display } from '@kit.ArkUI';
import AlertDialogManager from '../../manager/AlertDialogManager';
import { isDevicePortrait, isTablet } from '../utils/DeviceTypeUtils';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'SatelliteErrorAlertDialog';

@CustomDialog
export default struct SatelliteErrorAlertDialog {
  simCardSelectedDialog: CustomDialogController;
  @State closeButtonTime: number = 5;
  private closeButtonTimerId: number = -1;
  @Link dialogMessage: Resource;
  @State displayWidth: number = 0;

  aboutToAppear(): void {
    try {
      this.displayWidth = display.getDefaultDisplaySync().width;
    } catch (err) {
      LogUtils.e(TAG, `aboutToAppear error: ${err?.code} ${err?.message}`);
    }
  }

  getTabletMargin(): number {
    if (isDevicePortrait()) {
      return px2vp(this.displayWidth) * 390 / 1280;
    } else {
      return px2vp(this.displayWidth) * 467 / 1280;
    }
  }

  cancel() {
    this.simCardSelectedDialog.close();
  }

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
        Row() {
          Text(this.dialogMessage)
            .fontColor($r('sys.color.ohos_id_color_text_primary_dark'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .lineHeight(21)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .padding({
          bottom: 16,
          top: 24,
          left: 24,
          right: 24
        })

        Row() {
          Text($r('app.string.gotIt'))
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated_dark'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.cancel();
              AlertDialogManager.getInstance().closeAlertDialogWindow();
            })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .padding({
          right: $r('sys.float.ohos_id_notification_margin_start'),
          left: $r('sys.float.ohos_id_notification_margin_end')
        })
        .height(40)
        .margin({ bottom: 16 })
      }
    .align(Alignment.Center)
    .margin({ left: isTablet() ? this.getTabletMargin() : $r('sys.float.padding_level8'),
      right: isTablet() ? this.getTabletMargin() : $r('sys.float.padding_level8') })
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg_dark'))
    .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    .borderRadius($r('sys.float.corner_radius_level16'))
  }
}