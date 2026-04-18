/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
@CustomDialog
export default struct LocationTurnOnNoticeDialog {
  controller?: CustomDialogController;
  confirmText?: Resource;
  cancelText?: Resource;
  title?: Resource;
  text?: Resource;
  confirm: () => void = () => {
  };
  cancel: () => void = () => {
  };

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            Text(this.title)
              .lineHeight(27)
              .fontWeight(FontWeight.Bold)
              .fontSize($r('sys.float.ohos_id_text_size_headline8'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
          }.height(56).justifyContent(FlexAlign.Center)

          Column() {
            Text(this.text)
              .lineHeight(19)
              .fontWeight(FontWeight.Regular)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
          }.height(42).justifyContent(FlexAlign.Center)
        }

        Row() {
          Button(this.cancelText || '', { type: ButtonType.Normal })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('rgba(0,0,0,0)')
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_button'))
            .fontWeight(FontWeight.Medium)
            .onClick(this.cancel)
          Button(this.confirmText || '', { type: ButtonType.Normal })
            .layoutWeight(1)
            .height(40)
            .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_button'))
            .fontWeight(FontWeight.Medium)
            .onClick(this.confirm)
        }
        .alignItems(VerticalAlign.Top)
        .width('100%')
        .height(56)
        .margin({ top: 8 })
        .padding({})
      }
      .height(162)
      .width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
      .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 24, right: 24, bottom: 16 })
      .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
    }.padding({ left: $r('sys.float.margin_left'), right: $r('sys.float.margin_right') })
  }
}
