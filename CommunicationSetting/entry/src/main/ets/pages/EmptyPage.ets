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
export struct EmptyPage {
  private paddingNum: number = 0;
  build() {
    Column() {
      Column() {
        Image($r('app.media.search_no_result'))
          .width(120)
          .height(120)
          .draggable(false)

        Text($r('app.string.no_match_result'))
          .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .width('100%')
    .padding({ bottom: this.paddingNum })
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct WaitingPage {
  private paddingNum: number = 0;
  build() {
    Column() {
      Column() {
        LoadingProgress()
          .width(72)
          .height(72)

        Text($r('app.string.loading'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .margin({ top: 16 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .width('100%')
    .padding({ bottom: this.paddingNum })
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct EmptyAPPRank {
  private paddingNum: number = 0;
  build() {
    Column() {
      Column() {
        Image($r('app.media.no_network_app'))
          .width(120)
          .height(120)
          .draggable(false)

        Text($r('app.string.no_networked_apps'))
          .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .width('100%')
    .padding({ bottom: this.paddingNum })
    .justifyContent(FlexAlign.Center)
  }
}