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
import { LogUtils } from '@ohos/common';
import { i18n } from '@kit.LocalizationKit';

const TAG = 'MoreMenu';

@Component
export struct MoreMenu {
    private menuImage: Resource = $r('sys.symbol.square_and_pencil');
    private defaultColor: Resource = $r('sys.color.ohos_id_color_dialog_bg');
    private curWidth: Length = 40;
    @Link isManage: boolean;

    @Styles
    iconNormalStyles(){
        .backgroundColor(this.defaultColor)
    }

    @Styles
    iconPressedStyles(){
        .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_clicked'))
    }

    @Styles
    buttonNormalStyles(){
        .backgroundColor(Color.Transparent)
    }

    @Builder
    multDivider() {
        Divider()
            .color($r('sys.color.ohos_id_color_list_separator'))
            .height('1px')
            .margin({ left: 12, right: 12 })
    }

    build() {
        Button({ type: ButtonType.Circle }) {
            Column() {
                SymbolGlyph(this.menuImage)
                    .width('24vp')
                    .height('24vp')
                    .draggable(false)
                    .id('settingMoreButton')
                    .fontSize('24vp')
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
                    .direction(Direction.Ltr)
            }
            .width(this.curWidth)
            .height('100%')
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
            .borderRadius(20)
        }
        .onClick(() => {
            LogUtils.i(TAG, 'isManage');
            this.isManage = true;
        })
        .width(this.curWidth)
        .height(40)
        .align(Alignment.Center)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor($r('sys.color.ohos_id_color_text_field_sub_bg'))
        .accessibilityText($r('app.string.InfoEdit_edits_info'))
        .stateEffect(false)
    }
}