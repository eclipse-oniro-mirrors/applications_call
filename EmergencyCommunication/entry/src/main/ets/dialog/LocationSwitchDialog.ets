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
export default struct LocationSwitchDialog {
  controller?: CustomDialogController;
  confirmText?: Resource;
  cancelText?: Resource;
  image?: Resource;
  title?: Resource;
  text?: Resource;
  confirm: () => void = () => {
  };
  cancel: () => void = () => {
  };

  build() {
    Column() {
      Column() {
        Scroll() {
          Column() {
            Column() {
              Column() {
                Image(this.image)
              }.width(280).height(180)

              Text(this.title)
                .lineHeight(27)
                .fontWeight(FontWeight.Medium)
                .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .margin({ top: 16 })
              Column() {
                Text(this.text)
                  .lineHeight(19)
                  .fontWeight(FontWeight.Regular)
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .margin({ top: 8 })
              }.alignItems(HorizontalAlign.Start).width('100%')
            }.padding({ left: 8, right: 8 })

            Row() {
              Button(this.cancelText || '', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
                .layoutWeight(1)
                .height(40)
                .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_button'))
                .fontWeight(FontWeight.Medium)
                .onClick(this.cancel)
                .labelStyle({
                  maxLines: 1,
                  minFontSize: 1,
                  maxFontSize: 15,
                })
              Button(this.confirmText || '', { type: ButtonType.Normal })
                .layoutWeight(1)
                .height(40)
                .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_button'))
                .fontWeight(FontWeight.Medium)
                .onClick(this.confirm)
                .labelStyle({
                  maxLines: 1,
                  minFontSize: 1,
                  maxFontSize: 15,
                })
            }
            .width('100%')
            .margin({ top: 8 })
            .justifyContent(FlexAlign.Center)
          }
        }
      }
      .width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
      .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .borderRadius(20)
      .padding({
        top: 24,
        bottom: 16,
        left: 16,
        right: 16
      })
    }
  }
}
