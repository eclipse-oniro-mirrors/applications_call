/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

@Preview
@Component
export default struct ApnInfoItem {
  @Link networkMode: number;
  title: ResourceStr = '';
  thisNetworkMode: number = 5

  build() {
    Column() {
      Row() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text(this.title)
              .fontFamily('HarmonyHeiTi')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .opacity(this.networkMode == this.thisNetworkMode ? 0.9 : 0.6)
              .letterSpacing(1)
              .lineHeight(22)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 26 })

          Image(this.networkMode == this.thisNetworkMode ? $r('app.media.ic_redio_check') : '')
            .width(24)
            .height(24)
        }
      }
    }
    .height(50)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .margin({ top: 5, left: 10, right: 10, bottom: 5 })
    .padding({ left: 10, right: 10 })
    .onClick(() => {
      this.networkMode = this.thisNetworkMode
    })
  }
}