/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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
import { EDIT_SYMBOL_ICON } from '../control/EmergencyContactsInfoController'

@Component
export struct EditMenu {
  onClickCallBack: ((event: ClickEvent) => void) | undefined = undefined;

  build() {
    Button() {
      Column() {
        SymbolGlyph($r(EDIT_SYMBOL_ICON))
          .width('24vp')
          .height('24vp')
          .draggable(false)
          .fontSize('24vp')
          .fontColor([$r('sys.color.ohos_id_color_primary')])
          .direction(Direction.Ltr)
      }
      .width(40)
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .borderRadius(20)
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
    }
    .onClick((event) => {
      if (this.onClickCallBack) {
        this.onClickCallBack(event);
      }
    })
    .width(40)
    .height(40)
    .align(Alignment.Center)
    .buttonStyle(ButtonStyleMode.TEXTUAL)
    .accessibilityText($r('app.string.InfoEdit_edits_info'))
    .stateEffect(false)
  }
}