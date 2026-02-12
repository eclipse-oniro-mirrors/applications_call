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

import AlertDialogManager from '../../manager/AlertDialogManager';
import SatelliteSearchManager from '../../manager/SatelliteSearchManager';
import { ReportUtil, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { WAIT_STATE_TIME } from '../constant/SatelliteSearchConst';
import { SATELLITE_SERVICE_CONTEXT } from '../../common/constant/CallSettingsConstant';
import { common } from '@kit.AbilityKit';

const TAG = 'SatelliteAlertDialog';
const MAX_FONT_SCALE_BUTTON: number = 2;
const MAX_FONT_SCALE_TEXT: number = 3.2;

@CustomDialog
export default struct SatelliteAlertDialog {
  simCardSelectedDialog: CustomDialogController;
  @State closeButtonTime: number = 5;
  private closeButtonTimerId: number = -1;
  private hyacinthContext = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(SATELLITE_SERVICE_CONTEXT);
  onCLickGoToUse: () => void = () => {
  };
  private fontScale: number | undefined = this.hyacinthContext.config?.fontSizeScale;

  aboutToAppear(): void {
    this.startCloseButtonTimer();
  }

  aboutToDisappear(): void {
    this.stopCloseButtonTimer();
  }

  cancel() {
    this.simCardSelectedDialog.close();
  }

  startCloseButtonTimer() {
    this.closeButtonTimerId = setInterval(() => {
      this.closeButtonTime = this.closeButtonTime - 1;
      if (this.closeButtonTime == 0) {
        this.stopCloseButtonTimer();
        AlertDialogManager.getInstance().pushSatelliteSearchTimeoutNotification(() => {
          SatelliteSearchManager.getInstance().finishSatellite(false);
          ReportUtil.getInstance().reportSatelliteNotConnectedForOneMinute(2);
          if (SatelliteSearchManager.getInstance().isHyacinth()){
            ReportUtil.getInstance().reportHyacinthConnectFail(1)
          }
        });
      }
    }, 1 * 1000);
  }

  stopCloseButtonTimer() {
    clearInterval(this.closeButtonTimerId);
    this.closeButtonTime = 5;
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
        Text(this.getNotLinkSatelliteText())
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontSize(16)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(5)
          .fontWeight(FontWeight.Medium)
          .maxFontScale(MAX_FONT_SCALE_TEXT)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8, top: 24, left:24, right:24 })

      Flex({
        direction: this.fontScale && this.fontScale >= 3.2 ? FlexDirection.Column : FlexDirection.Row,
        justifyContent: FlexAlign.Center,
        alignItems: ItemAlign.Center
      }) {
        Flex({
          direction: FlexDirection.Column,
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Center
        }) {
          Text( $r('app.string.not_link_satellite_dialog_positive'))
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Medium)
            .maxFontScale(MAX_FONT_SCALE_BUTTON)
        }
        .layoutWeight(1)
        .height('100%')
        .onClick(() => {
          this.onCLickGoToUse();
        })

        Line().width(1).height(24).backgroundColor($r('sys.color.ohos_id_color_list_separator'))
          .visibility(this.fontScale && this.fontScale >= 3.2 ? Visibility.None : Visibility.Visible)

        Flex({
          direction: FlexDirection.Column,
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Center
        }) {
          Text($r('app.plural.not_link_satellite_dialog_negative', this.closeButtonTime, this.closeButtonTime))
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Medium)
            .maxFontScale(MAX_FONT_SCALE_BUTTON)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .height('100%')
        .onClick(() => {
          this.stopCloseButtonTimer();
          this.cancel();
          SatelliteSearchManager.getInstance().finishSatellite(false);
          ReportUtil.getInstance().reportSatelliteNotConnectedForOneMinute(0);
        })
      }
      .height(this.fontScale && this.fontScale >= 3.2 ? 80 : 40)
      .margin({bottom: 16})
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({
      right: $r('sys.float.ohos_id_notification_margin_start'),
      left: $r('sys.float.ohos_id_notification_margin_end')
    })
  }

  private getNotLinkSatelliteText() {
    if (SatelliteSearchManager.getInstance().isHyacinth()) {
      return this.hyacinthContext.resourceManager
        .getPluralStringValueSync($r('app.plural.hyacinth_not_link_satellite_dialog_message').id, WAIT_STATE_TIME);
    } else {
      return $r('app.string.not_link_satellite_dialog_message', WAIT_STATE_TIME);
    }
  }
}
