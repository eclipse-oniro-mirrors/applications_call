/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

/**
 * DefaultCard component
 */
@Component
export default struct DefaultCard {
  @State cardTextBackgrounColor: string = " #0A59F7";
  @State cardName: any = "";
  @State cardTextColor: string = "#FFFFFF"

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Text(this.cardName)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontFamily("HarmonyHeiTi")
        .lineHeight(16)
        .fontColor(this.cardTextColor)
        .align(Alignment.Center)
    }
    .width(65)
    .height(28)
    .borderRadius(50)
    .backgroundColor(this.cardTextBackgrounColor)
  }
}