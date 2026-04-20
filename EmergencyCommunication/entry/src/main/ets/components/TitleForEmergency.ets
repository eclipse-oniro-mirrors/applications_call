/*
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

@Component
export default struct titleForEmergency {
  private value: string | Resource = '';
  backItemClick: () => void = () => {};
  @Consume('pathInfos') pathInfos: NavPathStack;

  build() {
    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize($r('app.float.emc_margin_level12'))
        .fontColor([$r('sys.color.icon_primary')])
        .margin({ right: 16 })
        .onClick(() => {
          this.backItemClick();
          this.pathInfos.pop();
        })
      Text(this.value)
        .fontSize($r('sys.float.Title_S'))
        .fontWeight(FontWeight.Medium)
        .flexGrow(1)
        .fontColor($r('sys.color.font_primary'))
    }
    .width('100%')
  }
}
