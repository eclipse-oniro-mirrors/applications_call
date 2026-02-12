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
import { Event } from '@kit.ArkTS';

@Component
export struct DisplayItem2 {
  displayName?: Resource;
  subtitle?: Resource;
  onClickCallBack: ((event: ClickEvent) => void) | undefined = undefined;

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .padding({ left: 8, right: 8 })
    .borderRadius(16)
    .constraintSize({ minHeight: '64vp' })
    .opacity(1)
  }

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text(this.displayName)
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
          Flex() {
            Text(this.subtitle)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
          }
          .margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start)

        Image($r('app.media.ic_next'))
          .fillColor($r('sys.color.ohos_id_color_fourth'))
          .height('24vp')
          .width('12vp')
          .matchTextDirection(true)
          .draggable(false)
      }
      .constraintSize({minHeight:'64vp'})
      .width('100%')
      .padding({ left: 8, right: 8 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .hoverEffect(HoverEffect.Highlight)
      .borderRadius(20)
      .stateStyles({
        pressed: this.pressedStyles,
      })
    }
    .constraintSize({minHeight:'calc(64vp + 1px)'})
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .onClick((event: ClickEvent) => {
      if (this.onClickCallBack) {
        this.onClickCallBack(event);
      }
    })
  }
}