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
@Component
export struct FunctionSettingItem {
  title?: Resource;
  contentText?: Resource;
  imageUrl?: Resource;
  imagefillColor?: Resource;
  imageBackgroundColor?: Resource;

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: 12, top: 14, bottom: 14 })
    .borderRadius(14)
    .constraintSize({ minHeight: 64 })
    .opacity(1)
  }

  build() {
    Column() {
      Flex({ alignItems: ItemAlign.Center }) {
        Column() {
          Image(this.imageUrl ? this.imageUrl : $r('app.string.emptyStr'))
            .width(24)
            .height(24)
            .fillColor(this.imagefillColor ? this.imagefillColor : '')
        }
        .width(40)
        .height(40)
        .backgroundColor(this.imageBackgroundColor ? this.imageBackgroundColor : '')
        .margin({ right: 16 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .clipShape(new Circle({ width: 40, height: 40 }))

        Column() {
          Text(this.title)
            .width('100%')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontWeight(FontWeight.Medium)
          Row() {
            Text(this.contentText)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontWeight(FontWeight.Regular)
          }
          .width('100%')
          .margin({ top: 2 })
        }
        .margin({ right: 12 })
        .layoutWeight(1)

        Image($r('app.media.ic_next'))
          .fillColor($r('sys.color.ohos_id_color_fourth'))
          .height(24)
          .width(12)
      }
      .padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: 12, top: 14, bottom: 14 })
      .constraintSize({ minHeight: 63 })
      .width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(20)
      .stateStyles({
        pressed: this.pressedStyles,
      })
    }
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }
}